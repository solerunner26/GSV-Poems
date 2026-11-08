import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/text/text_tools.dart';

/// One poem found inside a Google Keep note.
class ImportedPoem {
  ImportedPoem({
    required this.number,
    required this.title,
    required this.body,
    required this.lang,
    required this.createdAt,
    required this.updatedAt,
    required this.collection,
    required this.sourceKey,
    required this.fileName,
    this.problem,
    this.kind = 'poem',
  });

  final int? number;
  final String title;
  final String body;
  final PoemLang lang;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Collection (category) name taken from the note's title, e.g. "જીવન મંથન".
  String collection;

  /// Stable fingerprint, so importing the same export twice adds nothing.
  final String sourceKey;
  final String fileName;
  final String? problem;

  /// 'poem' or 'prose'.
  final String kind;
}

/// What one note (file) produced, for the preview screen.
class NoteSummary {
  NoteSummary(this.fileName, this.collection, this.poems, this.listed, this.missing);
  final String fileName;
  String collection;
  final int poems;

  /// Entries in the note's table of contents (0 when the note has none).
  final int listed;

  /// Numbers listed in the table of contents but not found as poems.
  final List<int> missing;
}

class KeepParseResult {
  KeepParseResult(this.poems, this.notes, this.skippedNotes);
  final List<ImportedPoem> poems;
  final List<NoteSummary> notes;

  /// Files that were trashed, empty or not Keep notes.
  final List<String> skippedNotes;
  List<ImportedPoem> get problems => poems.where((p) => p.problem != null).toList();
  Set<String> get collections => {for (final p in poems) p.collection};
}

/// "૧૯:-  ને માટે." / "१૬:- बच्चों को सीख।" / "12. Title" / "३'- title"
final _heading = RegExp(r"^\s*([0-9૦-૯०-९]{1,4})\s*(?::+\s*-|:+|;|'\s*-|-|\.|\))\s*(.*)$");

/// A line made only of marks: ****, ++++, ####, :::---:::, ****†****
final _separator = RegExp(r'^[\s*+#:\-_=~†.।|]{3,}$');
final _endWords = RegExp(r'^\s*(સમાપ્ત|समाप्त|the end)[.\s]*$', caseSensitive: false);

/// "૨૬/૭/૨૬.." → 26 Jul 2026 (the date the poet wrote under a poem).
final _dateLine = RegExp(r'([0-9૦-૯०-९]{1,2})\s*/\s*([0-9૦-૯०-९]{1,2})\s*/\s*([0-9૦-૯०-९]{2,4})');

bool _isSeparator(String l) => _separator.hasMatch(l) || _endWords.hasMatch(l);

DateTime? _writtenOn(List<String> lines, DateTime now) {
  for (final l in lines.reversed.take(3)) {
    final m = _dateLine.firstMatch(l);
    if (m == null) continue;
    final d = parseAnyDigits(m[1]!), mo = parseAnyDigits(m[2]!);
    var y = parseAnyDigits(m[3]!);
    if (d == null || mo == null || y == null || d < 1 || d > 31 || mo < 1 || mo > 12) continue;
    if (y < 100) y += 2000;
    final date = DateTime(y, mo, d, 12);
    if (date.isAfter(now) || y < 1950) continue;
    return date;
  }
  return null;
}

/// Titles match when their first letters agree, ignoring spaces and marks
/// ("હે મન!" in the contents vs "હે મન." above the poem).
bool _similar(String a, String b, {bool strict = false}) {
  String norm(String s) => s.replaceAll(RegExp(r'''[\s.,:;!?।()"'\-]'''), '');
  final x = norm(a), y = norm(b);
  if (x.isEmpty || y.isEmpty) return !strict;
  final n = [x.runes.length, y.runes.length, 4].reduce((p, q) => p < q ? p : q);
  return String.fromCharCodes(x.runes.take(n)) == String.fromCharCodes(y.runes.take(n));
}

/// A title with the poet's working marks removed:
/// "ગુરુ જ્ઞાન.. .(વિદ્યાપીઠ).  ૬" → "ગુરુ જ્ઞાન (વિદ્યાપીઠ)", "औरत। :१::२::" → "औरत",
/// "યુવા શક્તિ.   ૨૮/૨/૨૫." → "યુવા શક્તિ".
String tidyTitle(String s) {
  var t = s.replaceAll(_dateLine, ' ');
  // Part of a date ("૫/૮/") and a leading poem number ("૩૨:- …").
  t = t.replaceAll(RegExp(r'[0-9૦-૯०-९]{1,2}\s*/\s*[0-9૦-૯०-९]{1,2}\s*/?'), ' ');
  t = t.replaceFirst(RegExp(r'^\s*[0-9૦-૯०-९]{1,4}\s*:+\s*-?\s*'), '');
  // A cross-reference to another collection: "સંતોષ ૧:- જીવન મંથન" → "સંતોષ".
  t = t.replaceFirst(RegExp(r'[\s.]+[0-9૦-૯०-९]{1,4}\s*:+\s*-\s*.*$'), '');
  t = t.replaceAll(RegExp(r'(:+\s*[0-9૦-૯०-९]+\s*)+:+'), ' ');
  t = t.replaceAll(RegExp(r'\(\s*[0-9૦-૯०-९\s:.,]*\)'), ' ');
  t = t.replaceAll(RegExp(r'[\s.:;।,\-]*[0-9૦-૯०-९]+[\s.:;।,\-]*$'), '');
  t = t.replaceAll(RegExp(r'(\s*\.){2,}\s*'), ' ');
  t = t.replaceAll(RegExp(r'\s+'), ' ');
  t = t.replaceAll(RegExp(r'^[\s:;.\-।]+'), '').replaceAll(RegExp(r'[\s.:;।,\-]+$'), '');
  return t.trim();
}

/// Drops everything that is not part of the poem itself: date/place lines
/// ("૨૬/૭/૨૬.. ઓકલેન્ડ.."), lines with no letters ("૭૪:-", "(૫૨)", "..."),
/// leading spaces and runs of blank lines. Only the stanzas remain.
List<String> tidyBody(List<String> lines) {
  final out = <String>[];
  for (final raw in lines) {
    final l = raw.trim();
    if (l.isEmpty) {
      if (out.isNotEmpty && out.last.isNotEmpty) out.add('');
      continue;
    }
    if (_isSeparator(l) || !hasLetter(l)) continue;
    if (_dateLine.hasMatch(l)) {
      final rest = l.replaceAll(_dateLine, ' ').replaceAll(RegExp(r'[.,:;।\-]'), ' ').trim();
      if (rest.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length <= 5) continue;
    }
    out.add(l);
  }
  while (out.isNotEmpty && out.first.isEmpty) {
    out.removeAt(0);
  }
  while (out.isNotEmpty && out.last.isEmpty) {
    out.removeLast();
  }
  return out;
}

String _cleanTitle(String s) => s.trim().replaceAll(RegExp(r'[\s.:।]+$'), '').replaceAll(RegExp(r'^[\s:;\-]+'), '').trim();

/// The collection name from a note title or file name:
/// "૧): જીવન મંથન : ૧૯ થી ૩૬:" → "જીવન મંથન", "परिवार। ३:- " → "परिवार".
String collectionName(String raw) {
  var s = raw.replaceAll(RegExp(r'\.json$', caseSensitive: false), '').replaceAll('_', ' ');
  s = s.replaceFirst(RegExp(r'^\s*[0-9૦-૯०-९]+\s*\)\s*:?'), '');
  s = s.replaceAll(RegExp(r'[0-9૦-૯०-९]+\s*[\s:;.\-]*(થી[ંઁ]?|से|तक|to|-)\s*([0-9૦-૯०-९]+)?'), '');
  s = s.replaceAll(RegExp(r'[0-9૦-૯०-९]+'), '');
  s = s.replaceAll(RegExp(r'[:;।॥.\-()"]+'), ' ');
  // Drop leftovers that are only vowel signs or marks (e.g. the "ં" of "થીં").
  final words = s
      .split(RegExp(r'\s+'))
      .where(
        (w) => w.runes.any((c) {
          final off = c >= 0x0A80 && c <= 0x0AFF ? c - 0x0A80 : (c >= 0x0900 && c <= 0x097F ? c - 0x0900 : null);
          return off == null ? RegExp(r'[A-Za-z]').hasMatch(String.fromCharCode(c)) : off >= 0x05 && off <= 0x39;
        }),
      );
  return words.join(' ').trim();
}

typedef SplitPoem = ({int? number, String title, String body, String? problem, DateTime? written});

/// Splits one note into poems.
///
/// A note opens with a list of contents ("૧:- title" lines with nothing in
/// between). Each poem then starts with its numbered title line and ends at a
/// line of marks (****, ++++, ####…) or at the next poem's title. When there is
/// a list of contents, only numbers from that list (in rising order) start a
/// poem, so a numbered line inside a poem is never mistaken for a new one.
({List<SplitPoem> poems, List<int> listed}) splitNote(String text, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final lines = text.replaceAll('\r\n', '\n').split('\n');
  final cands = <int>[];
  for (var i = 0; i < lines.length; i++) {
    final m = _heading.firstMatch(lines[i]);
    if (m != null && parseAnyDigits(m[1]!) != null) cands.add(i);
  }
  int numAt(int k) => parseAnyDigits(_heading.firstMatch(lines[cands[k]])![1]!)!;
  String titleAt(int k) => _heading.firstMatch(lines[cands[k]])![2]!;

  // The contents list is the first run of rising numbers near the top that the
  // poems then repeat ("1…18" listed, then poem 1 starts again). A title line
  // such as "४:- समाज संग। ४" may come first, so the run may start at any of
  // the first three numbered lines.
  final listed = <int>[];
  // How many times each number is listed (a typo can list "5" twice), and the titles listed for it.
  final toc = <int, int>{};
  final tocTitles = <int, List<String>>{};
  var k = 0;
  // Where does the first listed poem come back (same number and title)?
  // Everything before that is the contents list, even if slightly out of order.
  int? contentsEnd(int s) {
    for (var e = s + 2; e < cands.length; e++) {
      if (numAt(e) == numAt(s) && _similar(titleAt(e), titleAt(s), strict: true)) return e;
    }
    // Fallback: a rising run of numbers, then the first number again.
    var e = s + 1;
    while (e < cands.length && numAt(e) >= numAt(e - 1)) {
      e++;
    }
    return e - s >= 2 && e < cands.length && numAt(e) == numAt(s) ? e : null;
  }

  for (var s = 0; s < cands.length && s < 3; s++) {
    final e = contentsEnd(s);
    if (e != null) {
      for (var i = s; i < e; i++) {
        final t = titleAt(i);
        if (_cleanTitle(t).replaceAll('-', '').trim().isEmpty) continue;
        listed.add(numAt(i));
        toc[numAt(i)] = (toc[numAt(i)] ?? 0) + 1;
        (tocTitles[numAt(i)] ??= []).add(t);
      }
      k = e;
      break;
    }
  }
  bool sameTitle(int n, String t) => (tocTitles[n] ?? const []).any((x) => _similar(x, t));
  final used = <int, int>{};

  final starts = <int>[];
  var last = -1;
  for (; k < cands.length; k++) {
    final n = numAt(k);
    final emptyTitle = _cleanTitle(titleAt(k)).replaceAll('-', '').trim().isEmpty;
    var fits = toc.isEmpty ? n > last : n >= last && (used[n] ?? 0) < (toc[n] ?? 0);
    // Poems written after the contents list was made carry on the numbering
    // (contents 134–141, then 142, 143…).
    if (!fits && toc.isNotEmpty && n == last + 1 && !toc.containsKey(n) && hasLetter(titleAt(k))) fits = true;
    // A numbered line inside a poem ("૨. …") is not the next poem when its text
    // differs from the listed title and the real one still comes later.
    if (fits && toc.isNotEmpty && !sameTitle(n, titleAt(k))) {
      for (var j = k + 1; j < cands.length; j++) {
        if (numAt(j) == n && sameTitle(n, titleAt(j))) {
          fits = false;
          break;
        }
      }
    }
    if (fits) {
      starts.add(cands[k]);
      used[n] = (used[n] ?? 0) + 1;
      last = n;
    } else if (emptyTitle) {
      lines[cands[k]] = ''; // an empty "૭૪:- " placeholder for a poem not written yet
    }
  }

  final poems = <SplitPoem>[];
  for (var s = 0; s < starts.length; s++) {
    final m = _heading.firstMatch(lines[starts[s]])!;
    final end = s + 1 < starts.length ? starts[s + 1] : lines.length;
    final raw = <String>[];
    for (var i = starts[s] + 1; i < end; i++) {
      if (!_isSeparator(lines[i].trim())) raw.add(lines[i]);
    }
    final written = _writtenOn(raw, today) ?? _writtenOn([m[2]!], today);
    final body = tidyBody(raw);
    var title = tidyTitle(m[2]!);
    if (!hasLetter(title)) title = '';
    if (body.isEmpty && title.isEmpty) continue;
    String? problem;
    if (body.isEmpty) problem = 'Only a title, no poem text';
    if (title.isEmpty) title = tidyTitle(body.first);
    poems.add((number: parseAnyDigits(m[1]!), title: title, body: body.join('\n'), problem: problem, written: written));
  }
  return (poems: poems, listed: listed);
}

DateTime _fromUsec(Object? v, DateTime fallback) {
  final n = v is int ? v : int.tryParse('$v');
  return n == null ? fallback : DateTime.fromMicrosecondsSinceEpoch(n);
}

/// Parses `.json` files from a Google Takeout "Keep" folder ([files]: name → contents).
/// Each note becomes a collection named after its title.
KeepParseResult parseKeepTakeout(Map<String, String> files, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final poems = <ImportedPoem>[];
  final notes = <NoteSummary>[];
  final skipped = <String>[];
  final names = files.keys.where((n) => n.toLowerCase().endsWith('.json')).toList()..sort();
  for (final name in names) {
    Map<String, dynamic>? note;
    try {
      final decoded = jsonDecode(files[name]!);
      if (decoded is Map<String, dynamic> && decoded.containsKey('textContent')) note = decoded;
    } on FormatException {
      note = null;
    }
    final text = (note?['textContent'] as String?) ?? '';
    if (note == null || note['isTrashed'] == true || text.trim().isEmpty) {
      skipped.add(name);
      continue;
    }
    final created = _fromUsec(note['createdTimestampUsec'], today);
    final edited = _fromUsec(note['userEditedTimestampUsec'], created);
    final title = '${note['title'] ?? ''}'.trim();
    var collection = collectionName(title);
    if (collection.isEmpty) collection = collectionName(name.split(RegExp(r'[\\/]')).last);
    if (collection.isEmpty) collection = 'Google Keep';

    final split = splitNote(text, now: today);
    final found = <int>{};
    for (final p in split.poems) {
      if (p.number != null) found.add(p.number!);
      final written = p.written;
      // File + number + text: importing the same files again adds nothing, while the same
      // poem in two different notes is kept and shown as a duplicate for review.
      final key = sha1.convert(utf8.encode('$name|${p.number ?? ''}|${lettersOnly(p.title)}|${lettersOnly(p.body)}')).toString();
      poems.add(
        ImportedPoem(
          number: p.number,
          title: p.title,
          body: p.body,
          lang: detectLang('${p.title}\n${p.body}'),
          createdAt: written ?? created,
          updatedAt: edited,
          collection: collection,
          sourceKey: 'keep:$key',
          fileName: name,
          problem: p.problem,
        ),
      );
    }
    final missing = [
      for (final n in split.listed)
        if (!found.contains(n)) n,
    ];
    notes.add(NoteSummary(name, collection, split.poems.length, split.listed.length, missing));
  }
  _mergeContinuations(poems, notes);
  return KeepParseResult(poems, notes, skipped);
}

/// A first volume is sometimes titled shorter than the rest ("પ્રકૃતિ" 1–19,
/// then "પ્રકૃતિ સંગ" 20 onward). When a collection's name is the first words
/// of another one in the same script and its numbers end just before the other
/// begins, both are one collection under the longer name.
void _mergeContinuations(List<ImportedPoem> poems, List<NoteSummary> notes) {
  final nums = <String, List<int>>{};
  for (final p in poems) {
    if (p.number != null) (nums[p.collection] ??= []).add(p.number!);
  }
  final rename = <String, String>{};
  for (final a in nums.keys) {
    for (final b in nums.keys) {
      if (a == b || !b.startsWith('$a ') || detectLang(a) != detectLang(b)) continue;
      final aMax = nums[a]!.reduce((x, y) => x > y ? x : y);
      final bMin = nums[b]!.reduce((x, y) => x < y ? x : y);
      if (bMin == aMax + 1) rename[a] = b;
    }
  }
  if (rename.isEmpty) return;
  for (final p in poems) {
    p.collection = rename[p.collection] ?? p.collection;
  }
  for (final n in notes) {
    n.collection = rename[n.collection] ?? n.collection;
  }
}

// ---------- text copied straight out of Google Keep ----------

/// Lines Keep or the copy adds that are not part of any poem: "Edited 7 Nov",
/// "છેલ્લે ફેરફાર…", labels, the poet's own name or pen name on its own line,
/// and stray dates or times.
final _keepNoise = RegExp(
  r'^\s*(edited|last edited|modified|created|reminder|labels?|સંપાદિત|છેલ્લ[ેા] ફેરફાર|ફેરફાર કર્યો|संपादित|अंतिम बदलाव)\b.*$',
  caseSensitive: false,
);
final _timeOnly = RegExp(r'^\s*\d{1,2}[:.]\d{2}\s*(am|pm)?\s*$', caseSensitive: false);
final _monthDate = RegExp(
  r'^\s*([0-9૦-૯०-९]{1,2}\s+)?(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?(\s+[0-9૦-૯०-९]{1,4})?(,?\s+[0-9૦-૯०-९]{2,4})?\s*$',
  caseSensitive: false,
);

/// The poet's name or pen name alone on a line ("— ગૌરવ", "ગીગાભાઈ સનાભાઈ વાળા", "Gaurav").
bool _isSignature(String line) {
  final l = lettersOnly(line).toLowerCase();
  if (l.isEmpty) return false;
  const names = ['ગૌરવ', 'गौरव', 'gaurav', 'ગીગાભાઈ', 'गीगाभाई', 'gigabhai', 'વાળા', 'वाला', 'vala'];
  var rest = l;
  for (final n in names) {
    rest = rest.replaceAll(lettersOnly(n).toLowerCase(), '');
  }
  // Only name words (and at most a few letters of connecting words) remain.
  return rest.runes.length <= 6 && rest.runes.length < l.runes.length;
}

String _stripKeepNoise(String text) => text
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !_keepNoise.hasMatch(l) && !_timeOnly.hasMatch(l) && !_monthDate.hasMatch(l) && !_isSignature(l))
    .join('\n');

/// Splits text pasted from one or more Google Keep notes into single poems.
///
/// Numbered notes ("૧:- title" … "****") are split exactly like a Takeout
/// note; a first line that is not a numbered title becomes the collection
/// name. Text without numbers is split at lines of marks (****, ++++, ####…)
/// or, failing those, at two or more blank lines; each piece's first line is
/// its title. Dates, places, the poet's name and Keep's own "Edited…" lines
/// are dropped. Pasting the same text again adds nothing.
KeepParseResult parseKeepText(String text, {String? collection, DateTime? now}) {
  final today = now ?? DateTime.now();
  final clean = _stripKeepNoise(text);
  final lines = clean.split('\n');
  final poems = <ImportedPoem>[];

  // A note title line on top (not itself a numbered poem title) names the collection.
  var coll = collection ?? '';
  final firstIdx = lines.indexWhere((l) => l.trim().isNotEmpty);
  final numbered = splitNote(clean, now: today);

  ImportedPoem make(int? number, String title, String body, String? problem, DateTime? written) {
    final key = sha1.convert(utf8.encode('paste|${number ?? ''}|${lettersOnly(title)}|${lettersOnly(body)}')).toString();
    return ImportedPoem(
      number: number,
      title: title,
      body: body,
      lang: detectLang('$title\n$body'),
      createdAt: written ?? today,
      updatedAt: today,
      collection: coll,
      sourceKey: 'paste:$key',
      fileName: 'paste',
      problem: problem,
    );
  }

  if (numbered.poems.isNotEmpty) {
    if (coll.isEmpty && firstIdx >= 0 && _heading.firstMatch(lines[firstIdx]) == null) {
      final name = collectionName(lines[firstIdx]);
      if (name.runes.length <= 40) coll = name;
    }
    for (final p in numbered.poems) {
      poems.add(make(p.number, p.title, p.body, p.problem, p.written));
    }
  } else {
    // No numbering: split at mark lines, or at blank-line gaps.
    final hasMarks = lines.any((l) => _isSeparator(l.trim()) && l.trim().isNotEmpty);
    final chunks = <List<String>>[[]];
    var blanks = 0;
    for (final l in lines) {
      final t = l.trim();
      if (hasMarks ? (_isSeparator(t) && t.isNotEmpty) : (t.isEmpty && ++blanks >= 2)) {
        if (chunks.last.any((x) => x.trim().isNotEmpty)) chunks.add([]);
        blanks = 0;
        continue;
      }
      if (t.isNotEmpty) blanks = 0;
      chunks.last.add(l);
    }
    for (final chunk in chunks) {
      final written = _writtenOn(chunk, today);
      final body = tidyBody(chunk);
      if (body.isEmpty || !body.any(hasLetter)) continue;
      // A short first line followed by more text is the title.
      var title = '';
      var rest = body;
      if (body.length > 1 && body.first.runes.length <= 50) {
        title = tidyTitle(body.first);
        rest = tidyBody(body.sublist(1));
      }
      if (rest.isEmpty) {
        rest = body;
        title = '';
      }
      if (title.isEmpty) title = tidyTitle(rest.first);
      poems.add(make(null, title, rest.join('\n'), null, written));
    }
  }
  if (coll.isEmpty) coll = 'Google Keep';
  for (final p in poems) {
    p.collection = coll;
  }
  return KeepParseResult(poems, [NoteSummary('paste', coll, poems.length, numbered.listed.length, const [])], const []);
}

// ---------- prose (stories, articles, essays) ----------

final _proseNoiseWord = RegExp(r'\b(ok|okay)\b|ઓકે|ઑકે', caseSensitive: false);
final _proseKindWord = RegExp(r'^(કહાની|વાર્તા|લેખ|નિબંધ|कहानी|लेख|निबंध)[\s.:,-]*$');

/// A prose title without the poet's working marks: "અંતિમ લક્ષ.૧. કહાની.. ઓકે" → "અંતિમ લક્ષ",
/// "વેદના... ,(૦૨)... ok.." → "વેદના", "ભરતી ઓટ . સફળતા કે નિષ્ફળતા?" stays whole.
String proseTitle(String raw) {
  var t = raw.replaceAll(' ', ' ').replaceAll(_proseNoiseWord, ' ');
  t = t.replaceAll(RegExp(r'^\s*[0-9૦-૯०-९]+\s+'), ''); // leading file number
  t = t.replaceAll(RegExp(r'\(\s*[0-9૦-૯०-९.]*\s*\)'), ' '); // "(૦૨)"
  t = t.replaceAll(RegExp(r'[.।]\s*[0-9૦-૯०-९]+\s*[.।]?'), ' '); // ".૧." / "... ૧૧."
  t = t.replaceAll(RegExp(r'\s+[0-9૦-૯०-९]+\s*$'), ''); // trailing number
  t = t.replaceAll(RegExp(r'(?<=\S)\s*[.]{1,}\s*(કહાની|વાર્તા)\b.*$'), ''); // ".. કહાની...."
  t = t.replaceAll(RegExp(r'[\s.,:;_\-]+$'), '').replaceAll(RegExp(r'^[\s.,:;_\-]+'), '');
  // Inner runs of dots become one space ("ભરતી ઓટ . સફળતા" keeps its words).
  t = t.replaceAll(RegExp(r'\s*\.{2,}\s*'), ' ').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  // "… કહાની" at the end only says what it is.
  t = t.replaceAll(RegExp(r'\s+(કહાની|વાર્તા|कहानी)$'), '');
  // A lone " . " between two parts reads as a dash: "ભરતી ઓટ – સફળતા કે નિષ્ફળતા".
  t = t.replaceAll(RegExp(r'\s+\.\s+'), ' – ').trim();
  return t;
}

/// The text of a prose piece: the heading lines the poet writes on top (the
/// title again, "કહાની", "લેખક:- જી.એસ.વાળા \"ગૌરવ\"", a bare number) and his
/// name or a date at the end are dropped; paragraphs are kept, one blank line
/// apart, without the leading spaces Keep keeps.
String proseBody(String text, String title) {
  final lines = text.replaceAll('\r\n', '\n').replaceAll(' ', ' ').split('\n').map((l) => l.trim()).toList();
  bool isHeader(String l) {
    if (l.isEmpty) return true;
    if (!hasLetter(l)) return true; // "૧..", "1", ". "
    if (_proseKindWord.hasMatch(l)) return true;
    if (_isSignature(l) || l.contains('વાળા') || l.contains('લેખક') || l.contains('ગૌરવ')) return true;
    final p = proseTitle(l);
    return p.isNotEmpty && (_similar(p, title) || _similar(title, p));
  }

  var start = 0;
  var seen = 0;
  while (start < lines.length && seen < 8 && isHeader(lines[start])) {
    if (lines[start].isNotEmpty) seen++;
    start++;
  }
  var end = lines.length;
  while (end > start &&
      (lines[end - 1].isEmpty ||
          !hasLetter(lines[end - 1]) ||
          _isSignature(lines[end - 1]) ||
          _dateLine.hasMatch(lines[end - 1]) && lines[end - 1].runes.length < 30)) {
    end--;
  }
  final out = <String>[];
  for (final l in lines.sublist(start, end)) {
    if (l.isEmpty) {
      if (out.isNotEmpty && out.last.isNotEmpty) out.add('');
    } else {
      out.add(l);
    }
  }
  return out.join('\n').trim();
}

/// Turns Google Keep notes that each hold one story or article into prose
/// entries ([files]: name → note json). Order follows the number in front of
/// the file name.
List<ImportedPoem> parseProseNotes(Map<String, String> files, {required String collection, DateTime? now}) {
  final today = now ?? DateTime.now();
  final out = <ImportedPoem>[];
  for (final e in files.entries) {
    Map<String, dynamic> note;
    try {
      final d = jsonDecode(e.value);
      if (d is! Map<String, dynamic> || d['isTrashed'] == true) continue;
      note = d;
    } on FormatException {
      continue;
    }
    final text = '${note['textContent'] ?? ''}';
    if (text.trim().isEmpty) continue;
    final fileNo = int.tryParse(RegExp(r'^\s*(\d+)').firstMatch(e.key.split(RegExp(r'[\\/]')).last)?[1] ?? '');
    var title = proseTitle('${note['title'] ?? ''}');
    if (title.isEmpty) title = proseTitle(e.key.replaceAll(RegExp(r'\.json$', caseSensitive: false), ''));
    final body = proseBody(text, title);
    if (body.isEmpty) continue;
    final created = _fromUsec(note['createdTimestampUsec'], today);
    final edited = _fromUsec(note['userEditedTimestampUsec'], created);
    final key = sha1.convert(utf8.encode('prose|${lettersOnly(title)}|${lettersOnly(body)}')).toString();
    out.add(
      ImportedPoem(
        number: fileNo,
        title: title,
        body: body,
        lang: detectLang('$title\n$body'),
        createdAt: created,
        updatedAt: edited,
        collection: collection,
        sourceKey: 'prose:$key',
        fileName: e.key,
        kind: 'prose',
      ),
    );
  }
  out.sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
  return out;
}
