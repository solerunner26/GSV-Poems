import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/core/text/text_tools.dart';
import 'package:gsv_poems/data/import/keep_parser.dart';

// Sample notes shaped like the poet's Keep notes (made-up text, not real poems).
const gujaratiNote = '''જીવન મંથન. ૧ થી ૩:
વહેતું જીવન ઝરણું.

૧-    પહેલું શીર્ષક.
૨:-    બીજું શીર્ષક (લાંબું
         નામ.)
૩:-   ત્રીજું શીર્ષક.
+++++********************

૧-    પહેલું શીર્ષક.

પહેલી પંક્તિ અહીં,
બીજી પંક્તિ અહીં.
૨. અંદરની ગણતરી પણ કવિતાનો ભાગ છે
++++++++++++++++++++++++
૨:-   બીજું શીર્ષક.
એક પંક્તિ "ગૌરવ".

૨૬/૭/૨૦..  ઓકલેન્ડ..
**********************
૩:-   ત્રીજું શીર્ષક.
છેલ્લી કવિતા.
:::::::::::::::::---------::::::::::::::::
સમાપ્ત.
૪:-
''';

const hindiNote = '''परिवार। ३:-

१:-  पहला।
२:-  दूसरा।
५:-  पाँचवाँ।
५:-  फिर पाँचवाँ।
*************************†**************
१:- पहला।
पंक्ति एक।
********************************
२:- दूसरा।
पंक्ति दो।
५:- पाँचवाँ।
पंक्ति पाँच।
***
५:- फिर पाँचवाँ।
पंक्ति पाँच बी।
''';

String note(String text, {String title = '', bool trashed = false, int created = 1700000000000000}) => jsonEncode({
      'title': title,
      'textContent': text,
      'isTrashed': trashed,
      'createdTimestampUsec': created,
      'userEditedTimestampUsec': created + 1000000,
    });

void main() {
  group('splitNote', () {
    test('skips the contents list and splits at each numbered title', () {
      final r = splitNote(gujaratiNote);
      expect(r.listed, [1, 2, 3]);
      expect(r.poems.map((p) => p.number), [1, 2, 3]);
      expect(r.poems[0].title, 'પહેલું શીર્ષક');
      expect(r.poems[0].body, 'પહેલી પંક્તિ અહીં,\nબીજી પંક્તિ અહીં.\n૨. અંદરની ગણતરી પણ કવિતાનો ભાગ છે');
      expect(r.poems[1].body, contains('ઓકલેન્ડ'));
      expect(r.poems[2].body, 'છેલ્લી કવિતા.', reason: 'separator, "સમાપ્ત" and the empty "૪:-" are dropped');
    });

    test('any line of marks ends a poem: ****, ++++, :::---:::, ****†****', () {
      for (final p in splitNote(gujaratiNote).poems) {
        expect(p.body, isNot(contains('+++')));
        expect(p.body, isNot(contains('***')));
        expect(p.body, isNot(contains(':::')));
      }
    });

    test('a title line like "४:- समाज संग" before the contents is not a poem; repeated numbers allowed', () {
      final r = splitNote('४:- समाज संग।:- ४:\n\n$hindiNote');
      expect(r.listed, [1, 2, 5, 5]);
      expect(r.poems.map((p) => p.title), ['पहला', 'दूसरा', 'पाँचवाँ', 'फिर पाँचवाँ']);
      expect(r.poems[2].body, 'पंक्ति पाँच।');
    });

    test('mixed Devanagari and Gujarati digits are read as one number', () {
      expect(parseAnyDigits('१૬'), 16);
      final r = splitNote('१:- a\n१૬:- b\n****\n१:- a\nline\n१૬:- b\nline two');
      expect(r.poems.map((p) => p.number), [1, 16]);
    });

    test('a note without a contents list still splits by rising numbers', () {
      final r = splitNote('1. One\nfirst text\n****\n2. Two\nsecond text');
      expect(r.listed, isEmpty);
      expect(r.poems.map((p) => p.title), ['One', 'Two']);
    });
  });

  group('collectionName', () {
    test('drops numbering, ranges and punctuation', () {
      expect(collectionName('૧): જીવન મંથન : ૧૯ થી ૩૬:'), 'જીવન મંથન');
      expect(collectionName('૧):જીવન મંથન: ૯૨ થી ૧૦૯'), 'જીવન મંથન');
      expect(collectionName('૨): સમાજ સંગ. ૧૧૬ થી '), 'સમાજ સંગ');
      expect(collectionName('૩)_ પરિવારનાં પ્રભાત પુષ્પો. ૯૫_- થી ૧૧૦_.json'), 'પરિવારનાં પ્રભાત પુષ્પો');
      expect(collectionName('जीवन मंथन।:-१।'), 'जीवन मंथन');
      expect(collectionName('परिवार। ३:- '), 'परिवार');
      expect(collectionName('प्रकृति प्रेम। २:-'), 'प्रकृति प्रेम');
    });
  });

  group('parseKeepTakeout', () {
    test('collection from the note title, date written under the poem, skips trashed/empty/broken', () {
      final r = parseKeepTakeout({
        'a.json': note(gujaratiNote, title: '૧): જીવન મંથન. ૧ થી ૩:'),
        'b.json': note(hindiNote, title: 'परिवार। ३:- '),
        'c.json': note('1. x\ny', trashed: true),
        'd.json': note('   '),
        'e.json': '{oops',
        'photo.png': 'not json',
      }, now: DateTime(2026, 11, 7));
      expect(r.poems, hasLength(7));
      expect(r.collections, {'જીવન મંથન', 'परिवार'});
      expect(r.skippedNotes, hasLength(3));
      final second = r.poems.firstWhere((p) => p.title == 'બીજું શીર્ષક');
      expect(second.createdAt, DateTime(2020, 7, 26, 12));
      expect(second.lang, PoemLang.gu);
      expect(r.poems.firstWhere((p) => p.collection == 'परिवार').lang, PoemLang.hi);
      expect(r.problems, isEmpty);
    });

    test('a contents entry with no poem yet is reported as missing', () {
      final r = parseKeepTakeout({'a.json': note('1:- a\n2:- b\n****\n1:- a\ntext', title: 'X')});
      expect(r.notes.single.missing, [2]);
    });

    test('the same poem always gets the same sourceKey (safe to import twice)', () {
      final a = parseKeepTakeout({'x.json': note(gujaratiNote, title: 'A')}).poems.first;
      final b = parseKeepTakeout({'y.json': note(gujaratiNote, title: 'A')}).poems.first;
      expect(a.sourceKey, b.sourceKey);
    });
  });

  test('toScript moves names between Gujarati and Devanagari', () {
    expect(toScript('जीवन मंथन', PoemLang.gu), 'જીવન મંથન');
    expect(toScript('સમાજ સંગ', PoemLang.hi), 'समाज संग');
  });
}
