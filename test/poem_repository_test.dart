import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/data/import/keep_parser.dart';
import 'package:gsv_poems/data/poem_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late PoemRepository repo;
  var now = DateTime(2026, 11, 7, 12);

  setUp(() {
    now = DateTime(2026, 11, 7, 12);
    db = AppDatabase(NativeDatabase.memory());
    repo = PoemRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  test('new poems are numbered, language and word count are filled in', () async {
    final a = await repo.createPoem(title: '', body: 'ભીની માટીની સુગંધમાં');
    final b = await repo.createPoem(title: 'मन', body: 'मन का आँगन');
    final pa = (await repo.getPoem(a))!, pb = (await repo.getPoem(b))!;
    expect(pa.number, 1);
    expect(pb.number, 2);
    expect(pa.lang, 'gu');
    expect(pb.lang, 'hi');
    expect(pa.wordCount, 3);
  });

  test('default categories are created', () async {
    final cats = await repo.watchCategories().first;
    expect(cats.map((c) => c.id), containsAll(['bhakti', 'prem', 'other']));
  });

  test('search: 3 letters, any script, ignores the recycle bin', () async {
    final id = await repo.createPoem(title: 'પ્રેમની પાંખ', body: 'ઊડે છે મન પ્રેમની પાંખે');
    await repo.createPoem(title: 'दीप', body: 'जले जो प्रेम का दीप');
    await repo.createPoem(title: 'Morning', body: 'soft light');
    expect(await repo.search('pr'), isEmpty);
    expect((await repo.search('prem')).length, 2);
    expect((await repo.search('પ્રેમ')).length, 2);
    expect((await repo.search('prem', lang: 'hi')).single.lang, 'hi');
    expect((await repo.search('LIGHT')).single.title, 'Morning');
    await repo.moveToBin(id);
    expect((await repo.search('prem')).length, 1);
  });

  test('search treats % and _ literally', () async {
    await repo.createPoem(title: '', body: 'one hundred percent');
    expect(await repo.search('%%%'), isEmpty);
    expect(await repo.search('___'), isEmpty);
  });

  test('recycle bin: delete moves, restore brings back, forever only from the bin', () async {
    final id = await repo.createPoem(title: 't', body: 'body text');
    await repo.deleteForever(id); // not in bin yet: must be ignored
    expect(await repo.getPoem(id), isNotNull);
    await repo.moveToBin(id);
    expect(await repo.watchPoems().first, isEmpty);
    expect((await repo.watchRecycleBin().first).single.id, id);
    await repo.restoreFromBin(id);
    expect((await repo.watchPoems().first).single.id, id);
    await repo.moveToBin(id);
    await repo.deleteForever(id);
    expect(await repo.getPoem(id), isNull);
  });

  test('editing keeps the earlier text in history', () async {
    final id = await repo.createPoem(title: 'a', body: 'first text');
    now = now.add(const Duration(minutes: 5));
    await repo.updatePoem(id, title: 'a', body: 'second text', categoryId: null, keepVersion: true);
    final v = await repo.versions(id);
    expect(v.single.body, 'first text');
    await repo.restoreVersion(v.single);
    expect((await repo.getPoem(id))!.body, 'first text');
    expect((await repo.versions(id)).length, 2);
  });

  test('recent list covers 7 days and respects "clear list"', () async {
    final old = await repo.createPoem(title: '', body: 'old poem');
    now = now.add(const Duration(days: 8));
    await repo.createPoem(title: '', body: 'fresh poem');
    final recent = await repo.watchRecent().first;
    expect(recent.map((p) => p.id), isNot(contains(old)));
    expect(recent, hasLength(1));
    expect(await repo.watchRecent(clearedAt: now.add(const Duration(seconds: 1))).first, isEmpty);
  });

  test('stats count live poems by language and the bin separately', () async {
    await repo.createPoem(title: '', body: 'એક બે ત્રણ');
    final hi = await repo.createPoem(title: '', body: 'एक दो');
    await repo.moveToBin(hi);
    final s = await repo.watchStats().first;
    expect(s.total, 1);
    expect(s.gu, 1);
    expect(s.hi, 0);
    expect(s.words, 3);
    expect(s.inBin, 1);
  });

  test('import: collections from note titles, same name in two scripts is one collection, twice adds nothing', () async {
    String n(String title, String text) =>
        '{"title":${_q(title)},"textContent":${_q(text)},"createdTimestampUsec":1700000000000000}';
    final parsed = parseKeepTakeout({
      'g.json': n('૧): જીવન મંથન : ૧ થી ૨:', '૧:- એક\n૨:- બે\n****\n૧:- એક\nપંક્તિ\n****\n૨:- બે\nપંક્તિ'),
      'h.json': n('जीवन मंथन।:-१।', '१:- एक\n२:- दो\n****\n१:- एक\nपंक्ति\n****\n२:- दो\nपंक्ति'),
      'p.json': n('परिवार। ३:- ', '1. घर\nपंक्ति'),
      's.json': n('संघर्षमय जीवन। ७', '1. राह\nपंक्ति'),
    });
    final first = await repo.importPoems(parsed.poems);
    final second = await repo.importPoems(parsed.poems);
    expect(first.added, 6);
    expect(second.added, 0);
    expect(second.alreadyThere, 6);
    final cats = await repo.watchCategories().first;
    final jivan = cats.where((c) => c.nameGu == 'જીવન મંથન').toList();
    expect(jivan, hasLength(1), reason: 'Gujarati and Hindi titles share one collection');
    expect(jivan.single.nameHi, 'जीवन मंथन');
    expect(jivan.single.nameEn, 'Jivan Manthan');
    final inJivan = await repo.watchPoems(categoryId: jivan.single.id, sort: PoemSort.number).first;
    expect(inJivan.map((p) => p.lang).toSet(), {'gu', 'hi'});
    final family = await repo.watchPoems(categoryId: 'parivar').first;
    expect(family.single.title, 'घर', reason: '"परिवार" joins the built-in Family category');
    expect(cats.firstWhere((c) => c.nameHi == 'संघर्षमय जीवन').iconKey, 'shield');
  });

  test('new poems are numbered inside their collection', () async {
    final a = await repo.createPoem(title: '', body: 'x one', categoryId: 'prem');
    final b = await repo.createPoem(title: '', body: 'x two', categoryId: 'prem');
    final c = await repo.createPoem(title: '', body: 'x three', categoryId: 'desh');
    expect([(await repo.getPoem(a))!.number, (await repo.getPoem(b))!.number, (await repo.getPoem(c))!.number], [1, 2, 1]);
  });

  test('settings round-trip', () async {
    await repo.setSetting('theme', 'night');
    await repo.setSetting('theme', 'van');
    expect(await repo.getSetting('theme'), 'van');
    expect(await repo.allSettings(), {'theme': 'van'});
  });
}

String _q(String s) => jsonEncode(s);
