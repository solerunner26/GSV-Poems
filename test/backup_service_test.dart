import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/data/backup/backup_codec.dart';
import 'package:gsv_poems/data/backup/backup_service.dart';
import 'package:gsv_poems/data/backup/scheduler.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/data/poem_repository.dart';
import 'package:gsv_poems/data/security/pin_service.dart';

class MemoryStore implements SecretStore {
  final m = <String, String>{};
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
  @override
  Future<void> delete(String key) async => m.remove(key);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late PoemRepository repo;
  late MemoryStore store;
  late Directory tmp;
  late BackupService svc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PoemRepository(db);
    store = MemoryStore();
    tmp = Directory.systemTemp.createTempSync('gsvbak');
    svc = BackupService(repo, store, baseDir: () async => tmp);
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  test('one recovery key per phone; typed loosely it still matches; an old key can be adopted', () async {
    final k = await svc.recoveryKey();
    expect(await svc.recoveryKey(), k);
    expect(await svc.matchesRecoveryKey(k.toLowerCase().replaceAll('-', ' ')), isTrue);
    expect(await svc.matchesRecoveryKey('00000-00000-00000-00000-00000'), isFalse);
    await svc.adoptRecoveryKey('abcde fghjk mnpqr stvwx yz012');
    expect(await svc.recoveryKey(), 'ABCDE-FGHJK-MNPQR-STVWX-YZ012');
    expect(await svc.recoveryAcknowledged(), isFalse);
    await svc.acknowledgeRecovery();
    expect(await BackupService.recoveryAcknowledgedIn(store), isTrue);
  });

  test('backup on the phone opens with the phone key and keeps only the newest 7', () async {
    await repo.createPoem(title: 'A', body: 'ભીની માટીની સુગંધમાં યાદો ફરી ખીલી ઊઠી');
    expect(await svc.overdue(), isTrue);
    final f = await svc.backupNow();
    expect(await svc.overdue(), isFalse);
    final opened = await svc.open(await f.readAsBytes());
    expect((opened.data['poems'] as List), hasLength(1));
    expect(opened.usedTypedKey, isFalse);
    // Eight more backups with distinct names → still 7 on the phone.
    for (var i = 0; i < 8; i++) {
      File('${(await svc.backupDir()).path}/gsv-poems-2020-01-0${i + 1}-0000.$backupExtension').writeAsBytesSync(await f.readAsBytes());
    }
    await svc.backupNow();
    expect(await svc.localBackups(), hasLength(BackupService.keepLocal));
    final st = await svc.status();
    expect(st.localCount, 7);
    expect(st.lastBackup, isNotNull);
    expect(st.emailOn, isFalse);
  });

  test('a backup from another phone needs that phone\'s key', () async {
    final otherDb = AppDatabase(NativeDatabase.memory());
    final other = BackupService(PoemRepository(otherDb), MemoryStore(), baseDir: () async => tmp);
    final f = await other.backupNow();
    await expectLater(svc.open(await f.readAsBytes()), throwsA(isA<WrongKeyException>()));
    final ok = await svc.open(await f.readAsBytes(), typedKey: await other.recoveryKey());
    expect(ok.usedTypedKey, isTrue);
    await otherDb.close();
  });

  test('email settings: incomplete ones are not used; secrets never go into the database or backup', () async {
    await svc.saveEmailConfig(const EmailConfig(to: 'papa@example.com', from: 'me@gmail.com', appPassword: 'abcd efgh ijkl mnop'));
    expect((await svc.emailConfig())!.appPassword, 'abcdefghijklmnop');
    expect((await svc.emailConfig())!.complete, isTrue);
    expect(const EmailConfig(to: 'x', from: 'y@gmail.com', appPassword: 'short').complete, isFalse);
    final exported = await repo.exportBackup();
    expect(exported.toString().contains('abcdefghijklmnop'), isFalse);
    expect(await repo.allSettings(), isNot(contains('email_app_password')));
    await svc.clearEmailConfig();
    expect(await svc.emailConfig(), isNull);
  });

  test('alarms are set for the next 11:59 PM and 7 PM', () {
    expect(nextAt(23, 59, DateTime(2026, 11, 7, 10)), DateTime(2026, 11, 7, 23, 59));
    expect(nextAt(23, 59, DateTime(2026, 11, 7, 23, 59, 40)), DateTime(2026, 11, 8, 23, 59));
    expect(nextAt(19, 0, DateTime(2026, 11, 7, 20)), DateTime(2026, 11, 8, 19));
  });
}
