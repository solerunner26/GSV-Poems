import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/core/text/text_tools.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/data/import/keep_parser.dart';
import 'package:gsv_poems/data/import/seed.dart';
import 'package:gsv_poems/data/poem_repository.dart';
import 'package:gsv_poems/data/update/update_service.dart';

ImportedPoem poem(String body, {String collection = 'જીવન મંથન', int number = 1, String key = 'k1'}) => ImportedPoem(
      number: number,
      title: 'શીર્ષક $number',
      body: body,
      lang: detectLang(body),
      createdAt: DateTime(2024, 7, 25, 12),
      updatedAt: DateTime(2024, 7, 26),
      collection: collection,
      sourceKey: key,
      fileName: 'f.json',
    );

const text = 'ભીની માટીની સુગંધમાં યાદો ફરી ખીલી ઊઠી,\nઆંગણે ઊભી લીમડી ટીપે ટીપે ગીત ગાતી.';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('update check', () {
    test('build number from the APK name or tag', () {
      expect(buildNumberFrom('gsv-poems-v1.1.0-beta.1-build2.apk'), 2);
      expect(buildNumberFrom('v1.0.0+7'), 7);
      expect(buildNumberFrom('random.apk'), isNull);
    });

    test('newest non-draft release with an APK wins; betas count', () {
      final r = pickLatest([
        {'tag_name': 'v1.2.0', 'draft': true, 'assets': [{'name': 'gsv-poems-build9.apk', 'browser_download_url': 'x'}]},
        {'tag_name': 'v1.1.0-beta.1', 'prerelease': true, 'name': 'Beta 1', 'body': 'notes',
          'assets': [{'name': 'gsv-poems-v1.1.0-beta.1-build3.apk', 'browser_download_url': 'https://x/3.apk', 'size': 2048}]},
        {'tag_name': 'v1.0.0', 'assets': [{'name': 'gsv-poems-build1.apk', 'browser_download_url': 'https://x/1.apk'}, {'name': 'notes.txt'}]},
      ])!;
      expect(r.build, 3);
      expect(r.apkUrl, 'https://x/3.apk');
      expect(r.notes, 'notes');
      expect(pickLatest([{'tag_name': 'v1', 'assets': []}]), isNull);
    });
  });

  group('database', () {
    late AppDatabase db;
    late PoemRepository repo;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = PoemRepository(db);
    });
    tearDown(() => db.close());

    test('duplicates are found whatever the spacing or commas, and only removed on request', () async {
      final a = await repo.createPoem(title: 'A', body: text, categoryId: 'prem');
      await repo.createPoem(title: 'B', body: text.replaceAll(',', '').replaceAll('\n', '   \n\n'), categoryId: 'desh');
      await repo.createPoem(title: 'C', body: 'એક સાવ જુદી કવિતા અહીં લખેલી છે ભાઈ');
      final groups = await repo.duplicateGroups();
      expect(groups, hasLength(1));
      expect(groups.single, hasLength(2));
      expect((await repo.watchPoems().first), hasLength(3), reason: 'nothing removed by itself');
      expect((await repo.findDuplicatesOf(text)).length, 2);
      expect((await repo.findDuplicatesOf(text, excludeId: a)).length, 1);
      expect(await repo.removeDuplicates(groups.single, keepId: a), 1);
      expect(await repo.duplicateGroups(), isEmpty);
      expect((await repo.watchRecycleBin().first), hasLength(1), reason: 'the extra copy can still be restored');
    });

    test('short drafts are never called duplicates', () async {
      await repo.createPoem(title: '', body: 'હે મન');
      await repo.createPoem(title: '', body: 'હે મન');
      expect(await repo.duplicateGroups(), isEmpty);
    });

    test('poems without a category go to Others / અન્ય / अन्य; "અન્ય વિભાગ" joins it', () async {
      final id = await repo.createPoem(title: '', body: 'કોઈ વિભાગ વગરની કવિતા અહીં');
      expect((await repo.getPoem(id))!.categoryId, 'other');
      final other = (await repo.watchCategories().first).firstWhere((c) => c.id == 'other');
      expect([other.nameGu, other.nameHi, other.nameEn], ['અન્ય', 'अन्य', 'Others']);
      expect(await repo.ensureCategory('અન્ય વિભાગ'), 'other');
    });

    test('collection icons are two-tone and match the theme of the collection', () async {
      Future<String> icon(String name) async {
        final id = await repo.ensureCategory(name);
        return (await repo.watchCategories().first).firstWhere((c) => c.id == id).iconKey;
      }

      expect(await icon('જીવન મંથન'), 'swirl');
      expect(await icon('સંઘર્ષમય જીવન'), 'mountain');
      expect(await icon('પ્રેમ જ્યોત'), 'flame');
      expect(await icon('ભક્તિ સાગર મંચ'), 'wave');
      expect(await icon('પરિવારનાં પ્રભાત પુષ્પો'), 'sunrise');
      expect(await icon('સ્મૃતિ'), 'hourglass');
      expect(await icon('શુભેચ્છા મંચ'), 'gift');
      expect(await icon('પ્રકૃતિ સંગ'), 'tree');
      expect(await icon('દેશ પ્રેમ'), 'desh');
    });

    test('bundled seed: written, read back, loaded once, then skipped', () async {
      final json = encodeSeed([poem(text), poem('मन का आँगन रोशन है शब्दों के दीप जलाकर', collection: 'जीवन मंथन', number: 2, key: 'k2')]);
      expect(decodeSeed(json).map((p) => p.lang), [PoemLang.gu, PoemLang.hi]);
      expect(await loadSeed(repo, () async => json), 2);
      expect(await loadSeed(repo, () async => json), 0);
      expect(await loadSeed(repo, () async => throw StateError('no asset')), 0);
      final cats = await repo.watchCategories().first;
      expect(cats.where((c) => c.nameGu == 'જીવન મંથન'), hasLength(1));
      final p = (await repo.watchPoems(lang: 'gu').first).single;
      expect(p.createdAt, DateTime(2024, 7, 25, 12));
    });
  });
}
