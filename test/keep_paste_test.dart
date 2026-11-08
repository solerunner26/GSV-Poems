import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/data/import/keep_parser.dart';

void main() {
  final now = DateTime(2026, 11, 8);

  test('a numbered note copied from Keep becomes single poems in its collection', () {
    const text = '''જીવન મંથન : ૧૯ થી ૨૦
૧૯:- મનનો દીવો
અંધારે પણ દીવો બળે
મનમાં જ્યોતિ ઝળહળે
૨૬/૭/૨૬.. ઓકલેન્ડ..
— ગૌરવ
****
૨૦:- સાંજ
સાંજ પડી ને સૂરજ ઢળ્યો
પંખી માળે પાછો વળ્યો
ગીગાભાઈ સનાભાઈ વાળા
++++
Edited 7 Nov''';
    final r = parseKeepText(text, now: now);
    expect(r.poems.map((p) => p.title), ['મનનો દીવો', 'સાંજ']);
    expect(r.poems.map((p) => p.number), [19, 20]);
    expect(r.poems.first.body, 'અંધારે પણ દીવો બળે\nમનમાં જ્યોતિ ઝળહળે');
    expect(r.poems.last.body, 'સાંજ પડી ને સૂરજ ઢળ્યો\nપંખી માળે પાછો વળ્યો');
    expect(r.poems.every((p) => p.collection == 'જીવન મંથન'), isTrue);
    expect(r.poems.first.createdAt, DateTime(2026, 7, 26, 12));
  });

  test('one poem without numbers: first line is the title, extras are dropped', () {
    const text = '''વરસાદ

ભીની માટીની સુગંધમાં
યાદો ફરી ખીલી ઊઠી

૧૨/૮/૨૫
- ગૌરવ
10:42 pm''';
    final r = parseKeepText(text, now: now);
    expect(r.poems, hasLength(1));
    expect(r.poems.single.title, 'વરસાદ');
    expect(r.poems.single.body, 'ભીની માટીની સુગંધમાં\nયાદો ફરી ખીલી ઊઠી');
  });

  test('several unnumbered poems split at mark lines', () {
    const text = '''माँ
माँ की ममता सबसे न्यारी
****
पिता
पिता का साया सिर पर भारी
*****
Nov 7, 2026''';
    final r = parseKeepText(text, collection: 'परिवार', now: now);
    expect(r.poems.map((p) => p.title), ['माँ', 'पिता']);
    expect(r.poems.every((p) => p.collection == 'परिवार'), isTrue);
  });

  test('pasting the same text twice gives the same keys, so nothing doubles', () {
    const text = 'દીવો\nઅંધારે પણ દીવો બળે';
    expect(parseKeepText(text, now: now).poems.single.sourceKey, parseKeepText(text, now: now).poems.single.sourceKey);
  });
}
