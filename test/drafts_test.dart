import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gsv_poems/app_providers.dart';
import 'package:gsv_poems/core/l10n/strings.dart';
import 'package:gsv_poems/core/text/text_tools.dart';
import 'package:gsv_poems/core/theme/app_themes.dart';
import 'package:gsv_poems/data/backup/backup_service.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/data/poem_repository.dart';
import 'package:gsv_poems/data/security/pin_service.dart';
import 'package:gsv_poems/data/sync/github_library.dart';
import 'package:gsv_poems/features/drafts/drafts.dart';
import 'package:gsv_poems/features/sync/writer_gate.dart';

class MemoryStore implements SecretStore {
  final m = <String, String>{};
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
  @override
  Future<void> delete(String key) async => m.remove(key);
}

const textA = 'ભીની માટીની સુગંધમાં યાદો ફરી ખીલી ઊઠી, આંગણે ઊભી લીમડી ટીપે ટીપે ગીત ગાતી.';
const textB = 'સાંજ પડી ને સૂરજ ઢળ્યો, પંખી માળે પાછો વળ્યો, મનમાં શાંતિનો દીવો બળ્યો.';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(initializeDateFormatting);

  late AppDatabase db;
  late PoemRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PoemRepository(db);
  });
  tearDown(() => db.close());

  test('a draft stays out of the collection until it is published', () async {
    final published = await repo.createPoem(title: 'A', body: textA);
    final draft = await repo.createPoem(title: 'B', body: textB, isDraft: true);
    expect((await repo.watchPoems().first).map((p) => p.id), [published]);
    expect((await repo.watchDrafts().first).map((p) => p.id), [draft]);
    var s = await repo.watchStats().first;
    expect((s.total, s.poems, s.drafts), (1, 1, 1));
    expect(await repo.search('સાંજ પડી'), isEmpty, reason: 'drafts are not in search results');

    await repo.publishDraft(draft);
    expect(await repo.watchDrafts().first, isEmpty);
    s = await repo.watchStats().first;
    expect((s.total, s.drafts), (2, 0));
  });

  test('the online library never carries drafts; backups on his own devices do', () async {
    final dir = Directory.systemTemp.createTempSync('gsvdraft');
    addTearDown(() => dir.deleteSync(recursive: true));
    final lib = GithubLibrary(repo, BackupService(repo, MemoryStore(), baseDir: () async => dir));
    await repo.createPoem(title: 'A', body: textA);
    final d = await repo.createPoem(title: 'B', body: textB, isDraft: true);
    await repo.updatePoem(d, title: 'B2', body: '$textB નવું', keepVersion: true);
    final public = await lib.publicExport();
    expect((public['poems'] as List).map((p) => (p as Map)['title']), ['A']);
    expect((public['versions'] as List), isEmpty);
    final private = await repo.exportBackup();
    expect((private['poems'] as List), hasLength(2));
    // A draft published later changes what readers get.
    final before = await lib.fingerprint();
    await repo.publishDraft(d);
    expect(await lib.fingerprint(), isNot(before));
  });

  test("the poet's PIN check travels inside the encrypted collection to a reading phone", () async {
    final pins = PinService(MemoryStore(), iterations: 1000);
    await pins.setPin('2255');
    await refreshOwnerVerifier(repo, pins, (maker: 'nothing', model: 'A059P'));
    final data = await repo.exportBackup();
    final reader = AppDatabase(NativeDatabase.memory());
    addTearDown(reader.close);
    final readerRepo = PoemRepository(reader);
    await readerRepo.restoreBackup(data, applySettings: false);
    final v = await localOwnerVerifier(readerRepo);
    expect(v, isNotNull);
    expect(await PinService.matches(v!, '2255'), isTrue);
    expect(await PinService.matches(v, '1234'), isFalse);
    // Only his phone publishes it.
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    final otherRepo = PoemRepository(other);
    await refreshOwnerVerifier(otherRepo, pins, (maker: 'google', model: 'Pixel 10 Pro'));
    expect(await localOwnerVerifier(otherRepo), isNull);
    expect(jsonEncode(data).contains('2255'), isFalse);
  });

  test('email setup: a name in the sender box becomes the address; clear messages otherwise', () {
    final named = EmailConfig.typed(to: ' gsvala7989@gmail.com ', from: 'G.S. Vala', password: 'abcd efgh ijkl mnop');
    expect(named.from, 'gsvala7989@gmail.com');
    expect(named.appPassword, 'abcdefghijklmnop');
    expect(named.problem, isNull);
    expect(EmailConfig.typed(to: 'papa', from: 'a@gmail.com', password: 'abcdefghijklmnop').problem, 'email_bad_to');
    expect(EmailConfig.typed(to: 'papa@yahoo.com', from: 'G.S. Vala', password: 'abcdefghijklmnop').problem, 'email_bad_from');
    expect(EmailConfig.typed(to: 'a@gmail.com', from: '', password: 'abcd efgh').problem, 'email_bad_pass');
    for (final k in ['email_bad_to', 'email_bad_from', 'email_bad_pass', 'email_from_help']) {
      expect(tr(k, PoemLang.gu), isNot(k));
    }
  });

  testWidgets('drafts list shows each draft with publish, edit and delete', (tester) async {
    final drafts = [
      Poem(
        id: 'd1', number: null, title: 'નવી કવિતા', body: 'પંક્તિ', lang: 'gu', categoryId: 'other', isFavorite: false, wordCount: 1,
        searchBlob: '', createdAt: DateTime(2026, 11, 8), updatedAt: DateTime(2026, 11, 8), source: 'app', sourceKey: null,
        contentKey: null, deletedAt: null, kind: 'poem', isDraft: true,
      ),
    ];
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [draftsProvider.overrideWith((ref) => Stream.value(drafts))],
        child: MaterialApp(
          theme: buildTheme(themeById('night')),
          home: const LangScope(lang: PoemLang.gu, child: Scaffold(body: Column(children: [DraftsNotice(), Expanded(child: DraftsSection())]))),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('નવી કવિતા'), findsOneWidget);
    expect(find.text('${tr('drafts_title', PoemLang.gu)} ૧'), findsOneWidget);
    expect(find.text(tr('draft_publish_short', PoemLang.gu)), findsOneWidget);
    expect(find.text(tr('edit', PoemLang.gu)), findsOneWidget);
    expect(find.text(tr('draft_delete', PoemLang.gu)), findsOneWidget);
    expect(find.byType(AttentionDot), findsWidgets);
  });
}
