/// Language detection, word counting and transliteration used for search.
///
/// Gujarati (U+0A80–U+0AFF) and Devanagari (U+0900–U+097F) share the same
/// layout inside their Unicode blocks, so one table handles both scripts.
library;

enum PoemLang { gu, hi, en }

PoemLang langFromCode(String code) => PoemLang.values.firstWhere((l) => l.name == code, orElse: () => PoemLang.gu);

bool _isGujarati(int c) => c >= 0x0A80 && c <= 0x0AFF;
bool _isDevanagari(int c) => c >= 0x0900 && c <= 0x097F;
bool _isLatin(int c) => (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);

/// Picks the script with the most letters. Empty or mixed-equal text → Gujarati.
PoemLang detectLang(String text) {
  var gu = 0, hi = 0, en = 0;
  for (final c in text.runes) {
    if (_isGujarati(c)) {
      gu++;
    } else if (_isDevanagari(c)) {
      hi++;
    } else if (_isLatin(c)) {
      en++;
    }
  }
  if (gu == 0 && hi == 0 && en == 0) return PoemLang.gu;
  if (gu >= hi && gu >= en) return PoemLang.gu;
  if (hi >= en) return PoemLang.hi;
  return PoemLang.en;
}

final _wordSplit = RegExp(r'[\s।॥,;:!?.()"“”‘’\-–—]+');

/// Counts words that contain at least one letter (numbers and "****" are skipped).
int wordCount(String text) {
  var n = 0;
  for (final w in text.split(_wordSplit)) {
    if (w.isEmpty) continue;
    if (w.runes.any(_isLetter)) n++;
  }
  return n;
}

/// A letter in any of the three scripts; Indic digits and danda don't count.
bool _isLetter(int c) {
  if (_isLatin(c)) return true;
  final off = _indicOffset(c);
  return off != null && off >= 0x01 && off <= 0x63;
}

// Offsets inside the Indic block (code point minus block start).
const _independentVowels = <int, String>{
  0x05: 'a',
  0x06: 'aa',
  0x07: 'i',
  0x08: 'ii',
  0x09: 'u',
  0x0A: 'uu',
  0x0B: 'ri',
  0x0D: 'e',
  0x0F: 'e',
  0x10: 'ai',
  0x11: 'o',
  0x13: 'o',
  0x14: 'au',
};
const _consonants = <int, String>{
  0x15: 'k',
  0x16: 'kh',
  0x17: 'g',
  0x18: 'gh',
  0x19: 'n',
  0x1A: 'ch',
  0x1B: 'chh',
  0x1C: 'j',
  0x1D: 'jh',
  0x1E: 'n',
  0x1F: 't',
  0x20: 'th',
  0x21: 'd',
  0x22: 'dh',
  0x23: 'n',
  0x24: 't',
  0x25: 'th',
  0x26: 'd',
  0x27: 'dh',
  0x28: 'n',
  0x2A: 'p',
  0x2B: 'ph',
  0x2C: 'b',
  0x2D: 'bh',
  0x2E: 'm',
  0x2F: 'y',
  0x30: 'r',
  0x32: 'l',
  0x33: 'l',
  0x35: 'v',
  0x36: 'sh',
  0x37: 'sh',
  0x38: 's',
  0x39: 'h',
};
const _matras = <int, String>{
  0x3E: 'aa',
  0x3F: 'i',
  0x40: 'ii',
  0x41: 'u',
  0x42: 'uu',
  0x43: 'ri',
  0x45: 'e',
  0x47: 'e',
  0x48: 'ai',
  0x49: 'o',
  0x4B: 'o',
  0x4C: 'au',
};
const _virama = 0x4D;
const _nukta = 0x3C;

int? _indicOffset(int c) {
  if (_isGujarati(c)) return c - 0x0A80;
  if (_isDevanagari(c)) return c - 0x0900;
  return null;
}

/// Gujarati/Hindi → plain Latin letters ("પ્રેમ" → "prem", "प्रेम" → "prem").
/// Latin text passes through lower-cased. Word-final inherent "a" is dropped,
/// as Gujarati and Hindi speakers do.
String transliterate(String text) {
  final out = StringBuffer();
  final runes = text.runes.toList();
  var wordHasIndic = false;
  var endsWithInherentA = false;

  void endWord() {
    if (wordHasIndic && endsWithInherentA) {
      final s = out.toString();
      out
        ..clear()
        ..write(s.substring(0, s.length - 1));
    }
    wordHasIndic = false;
    endsWithInherentA = false;
  }

  for (var i = 0; i < runes.length; i++) {
    final c = runes[i];
    final off = _indicOffset(c);
    if (off == null) {
      if (!_isLatin(c)) endWord();
      out.writeCharCode(c);
      endsWithInherentA = false;
      continue;
    }
    if (off == _nukta) continue;
    final cons = _consonants[off];
    if (cons != null) {
      out.write(cons);
      wordHasIndic = true;
      var j = i + 1;
      while (j < runes.length && _indicOffset(runes[j]) == _nukta) {
        j++;
      }
      final nextOff = j < runes.length ? _indicOffset(runes[j]) : null;
      if (nextOff == _virama) {
        i = j;
        endsWithInherentA = false;
      } else if (nextOff != null && _matras.containsKey(nextOff)) {
        out.write(_matras[nextOff]);
        i = j;
        endsWithInherentA = false;
      } else {
        out.write('a');
        i = j - 1;
        endsWithInherentA = true;
      }
      continue;
    }
    final vowel = _independentVowels[off] ?? _matras[off];
    if (vowel != null) {
      out.write(vowel);
      wordHasIndic = true;
      endsWithInherentA = false;
      continue;
    }
    if (off == 0x01 || off == 0x02) {
      out.write('n');
      endsWithInherentA = false;
    } else if (off == 0x03) {
      out.write('h');
      endsWithInherentA = false;
    } else if (off >= 0x66 && off <= 0x6F) {
      out.writeCharCode(0x30 + off - 0x66);
      endsWithInherentA = false;
    }
  }
  endWord();
  return out.toString().toLowerCase();
}

/// Makes spellings comparable: "Prem", "praem", "premm" all fold to "prem".
String foldLatin(String s) {
  var t = s.toLowerCase();
  const pairs = [
    ['chh', 'ch'],
    ['aa', 'a'],
    ['ee', 'i'],
    ['ii', 'i'],
    ['oo', 'u'],
    ['uu', 'u'],
    ['ph', 'f'],
    ['sh', 's'],
    ['w', 'v'],
    ['z', 'j'],
    ['ae', 'e'],
    ['q', 'k'],
  ];
  for (final p in pairs) {
    t = t.replaceAll(p[0], p[1]);
  }
  final b = StringBuffer();
  int? prev;
  for (final c in t.runes) {
    if (c != prev || !_isLatin(c)) b.writeCharCode(c);
    prev = c;
  }
  return b.toString();
}

/// The text stored with each poem and matched by search.
String buildSearchBlob(String title, String body) {
  final raw = '$title\n$body'.toLowerCase();
  return '$raw\n${foldLatin(transliterate(raw))}';
}

/// The patterns a query should match (raw text, plus its folded Latin form).
List<String> searchPatterns(String query) {
  final q = query.trim().toLowerCase();
  if (q.runes.length < 3) return const [];
  final folded = foldLatin(transliterate(q));
  return {q, if (folded.runes.length >= 3) folded}.toList();
}

const _guDigits = '૦૧૨૩૪૫૬૭૮૯';
const _hiDigits = '०१२३४५६७८९';

/// 912 → "૯૧૨" (gu) / "९१२" (hi) / "912" (en).
String localDigits(Object n, PoemLang lang) {
  final s = n.toString();
  if (lang == PoemLang.en) return s;
  final d = lang == PoemLang.gu ? _guDigits : _hiDigits;
  return s.replaceAllMapped(RegExp('[0-9]'), (m) => d[int.parse(m[0]!)]);
}

/// Gujarati and Devanagari letters sit at the same place in their blocks, so a
/// name can be written in the other script by shifting the code point.
String toScript(String text, PoemLang target) {
  if (target == PoemLang.en) return text;
  final out = StringBuffer();
  for (final c in text.runes) {
    if (target == PoemLang.gu && _isDevanagari(c) && c != 0x0964 && c != 0x0965) {
      final g = c + 0x180;
      out.writeCharCode(_validGujarati(g) ? g : c);
    } else if (target == PoemLang.hi && _isGujarati(c)) {
      out.writeCharCode(c - 0x180);
    } else {
      out.writeCharCode(c);
    }
  }
  return out.toString();
}

// Devanagari code points whose Gujarati twin is unassigned stay as they are.
bool _validGujarati(int c) {
  const missing = {0x0A84, 0x0A8E, 0x0A92, 0x0AA9, 0x0AB1, 0x0AB4, 0x0ABA, 0x0ABB, 0x0AC6, 0x0ACA, 0x0ACE, 0x0ACF};
  return c >= 0x0A81 && c <= 0x0AEF && !missing.contains(c);
}

/// Reads a number written with ASCII, Gujarati or Devanagari digits, even mixed ("१૬" → 16).
int? parseAnyDigits(String s) {
  final b = StringBuffer();
  for (final c in s.runes) {
    if (c >= 0x30 && c <= 0x39) {
      b.writeCharCode(c);
    } else if (c >= 0x0AE6 && c <= 0x0AEF) {
      b.writeCharCode(0x30 + c - 0x0AE6);
    } else if (c >= 0x0966 && c <= 0x096F) {
      b.writeCharCode(0x30 + c - 0x0966);
    } else {
      return null;
    }
  }
  return int.tryParse(b.toString());
}

/// True when the text holds at least one real letter (not only digits or marks).
bool hasLetter(String s) => s.runes.any(_isLetter);

/// Letters only, lower-cased — spacing, punctuation and digits removed.
/// Two copies of a poem with different line breaks or commas give the same key.
String lettersOnly(String s) => String.fromCharCodes(
  s.toLowerCase().runes.where((c) {
    if (_isLatin(c)) return true;
    final off = _indicOffset(c);
    return off != null && off >= 0x01 && off <= 0x63 && off != 0x3C;
  }),
);
