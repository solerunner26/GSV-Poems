import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/core/text/text_tools.dart';
import 'package:gsv_poems/data/backup/backup_codec.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/data/import/keep_parser.dart';
import 'package:gsv_poems/data/poem_repository.dart';

const textA = 'ભીની માટીની સુગંધમાં યાદો ફરી ખીલી ઊઠી, આંગણે ઊભી લીમડી ટીપે ટીપે ગીત ગાતી.';
const textB = 'मन का आँगन रोशन है, शब्दों के दीप जलाकर हर साँस में तेरा नाम।';

ImportedPoem seedPoem(String key, String body) => ImportedPoem(
      number: 1, title: 'T', body: body, lang: detectLang(body), createdAt: DateTime(2024), updatedAt: DateTime(2024),
      collection: 'જીવન મંથન', sourceKey: key, fileName: 'seed');

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('recovery key', () {
    test('25 characters in 5 groups, forgiving when typed back', () {
      final k = newRecoveryKey();
      expect(RegExp(r'^[0-9A-Z]{5}(-[0-9A-Z]{5}){4}$').hasMatch(k), isTrue);
      expect(looksLikeRecoveryKey(k.toLowerCase().replaceAll('-', ' ')), isTrue);
      expect(normalizeRecoveryKey('ab0o1-il'), 'AB00111');
      expect(looksLikeRecoveryKey('too short'), isFalse);
    });
  });

  group('encrypted file', () {
    const key = '7K2QM-ABCDE-FGHJK-MNPQR-STVWX';
    final contents = {'format': 1, 'poems': [{'body': textA}], 'categories': [], 'versions': [], 'settings': {}};

    test('opens with the key, typed loosely; poems are not readable without it', () async {
      final bytes = await encodeBackup(contents, key, iterations: 1000);
      expect(utf8.decode(bytes, allowMalformed: true).contains('ભીની'), isFalse, reason: 'poems are encrypted');
      expect(readBackupHeader(bytes).poems, 1);
      final back = await decodeBackup(bytes, key.toLowerCase().replaceAll('-', ''));
      expect((back['poems'] as List).single['body'], textA);
    });

    test('the wrong key or a changed file is refused', () async {
      final bytes = await encodeBackup(contents, key, iterations: 1000);
      await expectLater(decodeBackup(bytes, '00000-00000-00000-00000-00000'), throwsA(isA<WrongKeyException>()));
      final tampered = Uint8List.fromList(bytes)..[bytes.length - 20] ^= 1;
      await expectLater(decodeBackup(tampered, key), throwsA(isA<WrongKeyException>()));
    });

    test('a file that is not a backup is recognised', () {
      expect(() => readBackupHeader(Uint8List.fromList(utf8.encode('hello'))), throwsA(isA<BackupFormatException>()));
    });
  });

  group('restore', () {
    late AppDatabase phone, other;
    late PoemRepository mine, theirs;
    setUp(() {
      phone = AppDatabase(NativeDatabase.memory());
      other = AppDatabase(NativeDatabase.memory());
      mine = PoemRepository(phone);
      theirs = PoemRepository(other);
    });
    tearDown(() async {
      await phone.close();
      await other.close();
    });

    test('full round trip: poems, bin, favourites, history and settings come back', () async {
      final a = await theirs.createPoem(title: 'A', body: textA, categoryId: 'prem');
      final b = await theirs.createPoem(title: 'B', body: textB);
      await theirs.setFavorite(a, true);
      await theirs.updatePoem(a, title: 'A2', body: '$textA ફરી', categoryId: 'prem', keepVersion: true);
      await theirs.moveToBin(b);
      await theirs.setSetting('theme', 'van');
      await theirs.setSetting('pin_hash_should_not_travel', 'x');
      final out = await mine.restoreBackup(await theirs.exportBackup());
      expect(out.added, 2);
      expect((await mine.getPoem(a))!.title, 'A2');
      expect((await mine.getPoem(a))!.isFavorite, isTrue);
      expect((await mine.getPoem(b))!.deletedAt, isNotNull, reason: 'stays in the recycle bin');
      expect((await mine.versions(a)).single.body, textA);
      expect(await mine.getSetting('theme'), 'van');
      expect(await mine.getSetting('pin_hash_should_not_travel'), isNull);
    });

    test('restoring twice adds nothing', () async {
      await theirs.createPoem(title: 'A', body: textA);
      final data = await theirs.exportBackup();
      await mine.restoreBackup(data);
      final again = await mine.restoreBackup(data);
      expect(again.added, 0);
      expect(await mine.watchPoems().first, hasLength(1));
      expect(await mine.versions((await mine.watchPoems().first).single.id), isEmpty);
    });

    test('after reinstalling, bundled poems are matched, not duplicated, and old edits come back', () async {
      // Old phone: bundled poem, edited by the poet later.
      await theirs.importPoems([seedPoem('seed:1', textA)]);
      final old = (await theirs.watchPoems().first).single;
      await theirs.updatePoem(old.id, title: 'સુધારેલું', body: '$textA નવી પંક્તિ', categoryId: old.categoryId, keepVersion: true);
      final backup = await theirs.exportBackup();
      // New phone: the app adds the bundled poems again (new ids) on first launch.
      await mine.importPoems([seedPoem('seed:1', textA)]);
      final out = await mine.restoreBackup(backup);
      final all = await mine.watchPoems().first;
      expect(all, hasLength(1), reason: 'matched by the bundled-poem key, not duplicated');
      expect(out.updated, 1);
      expect(all.single.title, 'સુધારેલું');
      expect(await mine.versions(all.single.id), isNotEmpty, reason: 'the older text is kept in history');
    });

    test('the newer edit wins; the other text is kept, nothing is lost', () async {
      var now = DateTime(2026, 1, 1);
      final t = PoemRepository(other, clock: () => now);
      final m = PoemRepository(phone, clock: () => now);
      final id = await t.createPoem(title: 'X', body: textA);
      await m.restoreBackup(await t.exportBackup());
      now = DateTime(2026, 2, 1);
      await m.updatePoem(id, title: 'X', body: '$textA phone edit', categoryId: 'other');
      now = DateTime(2026, 3, 1);
      await t.updatePoem(id, title: 'X', body: '$textA tablet edit', categoryId: 'other');
      await m.restoreBackup(await t.exportBackup());
      expect((await m.getPoem(id))!.body, endsWith('tablet edit'));
      expect((await m.versions(id)).map((v) => v.body), contains('$textA phone edit'));
      // The older backup does not undo the newer text.
      now = DateTime(2026, 4, 1);
      await m.updatePoem(id, title: 'X', body: '$textA newest', categoryId: 'other');
      await m.restoreBackup(await t.exportBackup());
      expect((await m.getPoem(id))!.body, endsWith('newest'));
    });

    test('a poem written on the phone with the same text as one in the backup is not doubled', () async {
      await theirs.createPoem(title: 'A', body: textA);
      await mine.createPoem(title: 'A', body: textA.replaceAll(',', ''));
      await mine.restoreBackup(await theirs.exportBackup());
      expect(await mine.watchPoems().first, hasLength(1));
    });

    test('replace everything clears the phone first', () async {
      await mine.createPoem(title: 'Local only', body: textB);
      await theirs.createPoem(title: 'A', body: textA);
      await mine.restoreBackup(await theirs.exportBackup(), replaceAll: true);
      final all = await mine.watchPoems().first;
      expect(all.map((p) => p.title), ['A']);
    });
  });
}
