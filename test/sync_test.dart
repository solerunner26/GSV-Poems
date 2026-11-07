import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/data/backup/backup_service.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/data/poem_repository.dart';
import 'package:gsv_poems/data/security/pin_service.dart';
import 'package:gsv_poems/data/sync/remote_store.dart';
import 'package:gsv_poems/data/sync/sync_service.dart';

class MemoryStore implements SecretStore {
  final m = <String, String>{};
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
  @override
  Future<void> delete(String key) async => m.remove(key);
}

/// A shared "Drive folder" in memory.
class FakeDrive implements RemoteStore {
  final files = <String, (Uint8List, DateTime)>{};
  var _tick = 0;
  @override
  Future<List<RemoteFile>> list() async => [for (final e in files.entries) RemoteFile(e.key, e.key, e.value.$2)];
  @override
  Future<Uint8List> download(String id) async => files[id]!.$1;
  @override
  Future<void> upload(String name, Uint8List bytes) async => files[name] = (bytes, DateTime(2026).add(Duration(seconds: ++_tick)));
  @override
  Future<void> delete(String id) async => files.remove(id);
}

class Device {
  Device(this.drive, this.clock) {
    db = AppDatabase(NativeDatabase.memory());
    repo = PoemRepository(db, clock: () => clock.now);
    dir = Directory.systemTemp.createTempSync('gsvsync');
    backups = BackupService(repo, MemoryStore(), baseDir: () async => dir);
    sync = SyncService(repo, backups, drive);
  }
  final FakeDrive drive;
  final Clock clock;
  late final AppDatabase db;
  late final PoemRepository repo;
  late final Directory dir;
  late final BackupService backups;
  late final SyncService sync;

  Future<List<Poem>> live() => repo.watchPoems().first;
  Future<void> close() async {
    await db.close();
    dir.deleteSync(recursive: true);
  }
}

class Clock {
  DateTime now = DateTime(2026, 1, 1, 10);
  void step() => now = now.add(const Duration(minutes: 5));
}

const textA = 'ભીની માટીની સુગંધમાં યાદો ફરી ખીલી ઊઠી, આંગણે ઊભી લીમડી ટીપે ટીપે ગીત ગાતી.';
const textB = 'मन का आँगन रोशन है, शब्दों के दीप जलाकर हर साँस में तेरा नाम।';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late FakeDrive drive;
  late Clock clock;
  late Device phone, tablet;

  setUp(() {
    drive = FakeDrive();
    clock = Clock();
    phone = Device(drive, clock);
    tablet = Device(drive, clock);
  });
  tearDown(() async {
    await phone.close();
    await tablet.close();
  });

  test('the second device asks once for the first device\'s recovery key, then both share poems', () async {
    await phone.repo.createPoem(title: 'A', body: textA);
    final r1 = await phone.sync.sync();
    expect(r1.uploaded, isTrue);
    expect(drive.files.keys.where((n) => n.contains('latest')), hasLength(1));

    final r2 = await tablet.sync.sync();
    expect(r2.needsKey, isTrue, reason: 'the tablet made its own key; it cannot open the phone backup');
    expect(r2.uploaded, isFalse, reason: 'never upload with a second key');
    expect(await tablet.live(), isEmpty);

    final r3 = await tablet.sync.sync(typedKey: await phone.backups.recoveryKey());
    expect(r3.needsKey, isFalse);
    expect(r3.added, 1);
    expect(r3.uploaded, isTrue);
    expect(await tablet.backups.recoveryKey(), await phone.backups.recoveryKey(), reason: 'one key for both devices');
  });

  group('after pairing', () {
    setUp(() async {
      await phone.repo.createPoem(title: 'A', body: textA);
      await phone.sync.sync();
      await tablet.sync.sync(typedKey: await phone.backups.recoveryKey());
      await phone.sync.sync();
    });

    test('a poem written on either device reaches the other; repeated syncs add nothing', () async {
      clock.step();
      await tablet.repo.createPoem(title: 'B', body: textB);
      await tablet.sync.sync();
      await phone.sync.sync();
      expect((await phone.live()).map((p) => p.title).toSet(), {'A', 'B'});
      for (var i = 0; i < 3; i++) {
        await phone.sync.sync();
        await tablet.sync.sync();
      }
      expect(await phone.live(), hasLength(2));
      expect(await tablet.live(), hasLength(2));
    });

    test('an edit on the tablet wins on the phone; the phone keeps the older text in history', () async {
      final id = (await tablet.live()).single.id;
      clock.step();
      await tablet.repo.updatePoem(id, title: 'A', body: '$textA ટેબ્લેટ', categoryId: 'other');
      await tablet.sync.sync();
      await phone.sync.sync();
      final p = (await phone.live()).single;
      expect(p.body, endsWith('ટેબ્લેટ'));
      expect((await phone.repo.versions(p.id)).map((v) => v.body), contains(textA));
    });

    test('both edit: the newer edit wins on both devices, nothing is lost', () async {
      final id = (await phone.live()).single.id;
      clock.step();
      await phone.repo.updatePoem(id, title: 'A', body: '$textA phone', categoryId: 'other');
      clock.step();
      await tablet.repo.updatePoem(id, title: 'A', body: '$textA tablet', categoryId: 'other');
      await phone.sync.sync();
      await tablet.sync.sync();
      await phone.sync.sync();
      expect((await phone.live()).single.body, endsWith('tablet'));
      expect((await tablet.live()).single.body, endsWith('tablet'));
      expect((await tablet.repo.versions(id)).map((v) => v.body), contains('$textA phone'));
    });

    test('delete goes to the other device\'s recycle bin, and restore comes back too', () async {
      final id = (await phone.live()).single.id;
      clock.step();
      await phone.repo.moveToBin(id);
      await phone.sync.sync();
      await tablet.sync.sync();
      expect(await tablet.live(), isEmpty);
      expect((await tablet.repo.watchRecycleBin().first).single.id, id, reason: 'only moved to the bin, never erased');
      clock.step();
      await tablet.repo.restoreFromBin(id);
      await tablet.sync.sync();
      await phone.sync.sync();
      expect((await phone.live()).single.id, id);
    });

    test('this device\'s own theme and language are kept when syncing', () async {
      await phone.repo.setSetting('theme', 'night');
      await tablet.repo.setSetting('theme', 'van');
      clock.step();
      await phone.repo.createPoem(title: 'C', body: textB);
      await phone.sync.sync();
      await tablet.sync.sync();
      expect(await tablet.repo.getSetting('theme'), 'van');
    });
  });

  test('two weeks of daily copies are kept on Drive per device', () async {
    final me = await phone.sync.deviceId();
    drive.files['gsv-poems-2020-01-01-$me.gsvbak'] = (Uint8List(0), DateTime(2020));
    drive.files['gsv-poems-2020-01-01-otherdevice.gsvbak'] = (Uint8List(0), DateTime(2020));
    await phone.sync.sync();
    expect(drive.files.containsKey('gsv-poems-2020-01-01-$me.gsvbak'), isFalse);
    expect(drive.files.containsKey('gsv-poems-2020-01-01-otherdevice.gsvbak'), isTrue, reason: 'only its own old copies');
    expect(drive.files.keys.where((n) => n.startsWith('gsv-poems-20') && n.endsWith('$me.gsvbak')), hasLength(1));
  });
}
