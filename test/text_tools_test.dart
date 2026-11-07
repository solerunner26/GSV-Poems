import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/core/text/text_tools.dart';

void main() {
  group('transliterate', () {
    test('Gujarati and Hindi "prem" both become "prem"', () {
      expect(transliterate('પ્રેમ'), 'prem');
      expect(transliterate('प्रेम'), 'prem');
    });
    test('keeps inherent a inside a word, drops it at the end', () {
      expect(transliterate('કમળ'), 'kamal');
      expect(transliterate('मन'), 'man');
    });
    test('matras, anusvara and spaces', () {
      expect(transliterate('ગીત ગાતી'), 'giit gaatii');
      expect(foldLatin(transliterate('ગીત ગાતી')), 'git gati');
      expect(transliterate('સંગ્રહ'), 'sangrah');
    });
    test('Latin passes through lower-cased', () {
      expect(transliterate('Love Song'), 'love song');
    });
    test('Gujarati digits become ASCII', () {
      expect(transliterate('૧૨૭'), '127');
    });
  });

  group('search patterns', () {
    test('need at least 3 letters', () {
      expect(searchPatterns('pr'), isEmpty);
      expect(searchPatterns('પ્ર'), isNotEmpty);
    });
    test('"Prem" in Latin matches the folded transliteration of પ્રેમ', () {
      final blob = buildSearchBlob('', 'મારો પ્રેમ');
      final pats = searchPatterns('Prem');
      expect(pats.any(blob.contains), isTrue);
    });
    test('Hindi query finds a Gujarati poem through the shared Latin form', () {
      final blob = buildSearchBlob('', 'પ્રેમની પાંખ');
      expect(searchPatterns('प्रेम').any(blob.contains), isTrue);
    });
    test('spelling variants fold together', () {
      expect(foldLatin('preem'), foldLatin('prim'));
      expect(foldLatin('Premm'), 'prem');
      expect(foldLatin('shaam'), 'sam');
    });
  });

  group('detectLang', () {
    test('picks the dominant script', () {
      expect(detectLang('ભીની માટીની સુગંધ'), PoemLang.gu);
      expect(detectLang('मन का आँगन'), PoemLang.hi);
      expect(detectLang('morning light'), PoemLang.en);
      expect(detectLang(''), PoemLang.gu);
    });
  });

  group('wordCount', () {
    test('ignores numbers, punctuation and the **** end marker', () {
      expect(wordCount('૧૨૭.\nભીની માટીની સુગંધમાં,\nયાદો ફરી ખીલી ઊઠી.\n****'), 7);
      expect(wordCount('शब्दों के दीप जलाकर।'), 4);
    });
  });

  test('localDigits', () {
    expect(localDigits(912, PoemLang.gu), '૯૧૨');
    expect(localDigits(912, PoemLang.hi), '९१२');
    expect(localDigits(912, PoemLang.en), '912');
  });
}
