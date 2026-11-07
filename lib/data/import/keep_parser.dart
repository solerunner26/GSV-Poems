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
  });

  final int? number;
  final String title;
  final String body;
  final PoemLang lang;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Collection (category) name taken from the note's title, e.g. "જીવન મંથન".
  final String collection;

  /// Stable fingerprint, so importing the same export twice adds nothing.
  final String sourceKey;
  final String fileName;
  final String? problem;
}

/// What one note (file) produced, for the preview screen.
class NoteSummary {
  NoteSummary(this.fileName, this.collection, this.poems, this.listed, this.missing);
  final String fileName;
  final String collection;
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
  final words = s.split(RegExp(r'\s+')).where((w) => w.runes.any((c) {
        final off = c >= 0x0A80 && c <= 0x0AFF ? c - 0x0A80 : (c >= 0x0900 && c <= 0x097F ? c - 0x0900 : null);
        return off == null ? RegExp(r'[A-Za-z]').hasMatch(String.fromCharCode(c)) : off >= 0x05 && off <= 0x39;
      }));
  return words.join(' ').trim();
}

typedef SplitPoem = ({int? number, String title, String body, String? problem});

/// Splits one note into poems.
///
/// A note opens with a list of contents ("૧:- title" lines with nothing in
/// between). Each poem then starts with its numbered title line and ends at a
/// line of marks (****, ++++, ####…) or at the next poem's title. When there is
/// a list of contents, only numbers from that list (in rising order) start a
/// poem, so a numbered line inside a poem is never mistaken for a new one.
({List<SplitPoem> poems, List<int> listed}) splitNote(String text) {
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
    final body = <String>[];
    for (var i = starts[s] + 1; i < end; i++) {
      if (_isSeparator(lines[i].trim())) continue;
      body.add(lines[i].trimRight());
    }
    while (body.isNotEmpty && body.first.trim().isEmpty) {
      body.removeAt(0);
    }
    while (body.isNotEmpty && body.last.trim().isEmpty) {
      body.removeLast();
    }
    var title = _cleanTitle(m[2]!);
    if (title.replaceAll('-', '').trim().isEmpty) title = '';
    if (body.isEmpty && title.isEmpty) continue;
    String? problem;
    if (body.isEmpty) problem = 'Only a title, no poem text';
    if (title.isEmpty) title = _cleanTitle(body.first);
    poems.add((number: parseAnyDigits(m[1]!), title: title, body: body.join('\n'), problem: problem));
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

    final split = splitNote(text);
    final found = <int>{};
    for (final p in split.poems) {
      if (p.number != null) found.add(p.number!);
      final lines = p.body.split('\n');
      final written = _writtenOn(lines, today);
      final key = sha1.convert(utf8.encode('${p.number ?? ''}|${p.title}|${p.body.replaceAll(RegExp(r'\s+'), ' ')}')).toString();
      poems.add(ImportedPoem(
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
      ));
    }
    final missing = [for (final n in split.listed) if (!found.contains(n)) n];
    notes.add(NoteSummary(name, collection, split.poems.length, split.listed.length, missing));
  }
  return KeepParseResult(poems, notes, skipped);
}
