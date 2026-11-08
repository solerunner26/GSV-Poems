import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/data/backup/backup_service.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/data/poem_repository.dart';
import 'package:gsv_poems/data/security/pin_service.dart';
import 'package:gsv_poems/data/sync/github_library.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemoryStore implements SecretStore {
  final m = <String, String>{};
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
  @override
  Future<void> delete(String key) async => m.remove(key);
}

/// GitHub's contents API for one file, in memory.
class FakeGithub {
  Uint8List? file;
  int puts = 0;
  static const token = 'test-token';

  late final client = MockClient((req) async {
    if (req.method == 'GET') {
      if (file == null) return http.Response('not found', 404);
      if (req.headers['Accept'] == 'application/vnd.github.raw') return http.Response.bytes(file!, 200);
      return http.Response(jsonEncode({'sha': sha1.convert(file!).toString()}), 200);
    }
    if (req.method == 'PUT') {
      if (req.headers['Authorization'] != 'Bearer $token') return http.Response('no', 401);
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final current = file == null ? null : sha1.convert(file!).toString();
      if (body['sha'] != current) return http.Response('conflict', 409);
      file = base64Decode(body['content'] as String);
      puts++;
      return http.Response('{}', file == null ? 201 : 200);
    }
    return http.Response('?', 400);
  });
}

class Device {
  Device(FakeGithub gh, {MemoryStore? secrets}) {
    db = AppDatabase(NativeDatabase.memory());
    repo = PoemRepository(db);
    dir = Directory.systemTemp.createTempSync('gsvlib');
    store = secrets ?? MemoryStore();
    backups = BackupService(repo, store, baseDir: () async => dir);
    lib = GithubLibrary(repo, backups, client: gh.client);
  }
  late final AppDatabase db;
  late final PoemRepository repo;
  late final Directory dir;
  late final MemoryStore store;
  late final BackupService backups;
  late final GithubLibrary lib;

  Future<int> count() async => (await repo.watchPoems().first).length;
  Future<void> close() async {
    await db.close();
    dir.deleteSync(recursive: true);
  }
}

const textA = 'ભીની માટીની સુગંધમાં યાદો ફરી ખીલી ઊઠી, આંગણે ઊભી લીમડી ટીપે ટીપે ગીત ગાતી.';
const textB = 'मन का आँगन रोशन है, शब्दों के दीप जलाकर हर साँस में तेरा नाम।';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late FakeGithub gh;
  late Device phone, reader;

  setUp(() {
    gh = FakeGithub();
    phone = Device(gh);
    reader = Device(gh);
  });
  tearDown(() async {
    await phone.close();
    await reader.close();
  });

  test('the phone publishes; a reader with the recovery key gets every poem', () async {
    await phone.repo.createPoem(title: 'A', body: textA);
    await phone.repo.createPoem(title: 'B', body: textB, kind: Kind.prose);
    final pub = await phone.lib.publish(FakeGithub.token);
    expect(pub.published, isTrue);

    // A reader with another key is asked for the poet's key once…
    final first = await reader.lib.pull();
    expect(first.needsKey, isTrue);
    expect(await reader.count(), 0);
    // …and after typing it gets everything, prose included.
    final key = await phone.backups.recoveryKey();
    final second = await reader.lib.pull(typedKey: key);
    expect(second.added, 2);
    final kinds = (await reader.repo.watchPoems().first).map((p) => p.kind).toSet();
    expect(kinds, {Kind.poem, Kind.prose});
    // The key is remembered: the next new poem comes in by itself.
    await phone.repo.createPoem(title: 'C', body: '$textA નવી');
    await phone.lib.publish(FakeGithub.token);
    final third = await reader.lib.pull();
    expect(third.needsKey, isFalse);
    expect(third.added, 1);
    expect(await reader.count(), 3);
  });

  test('an unchanged collection is not sent again, and an unchanged file is not merged again', () async {
    await phone.repo.createPoem(title: 'A', body: textA);
    await phone.lib.publish(FakeGithub.token);
    await phone.lib.publish(FakeGithub.token);
    expect(gh.puts, 1);
    await reader.lib.pull(typedKey: await phone.backups.recoveryKey());
    final again = await reader.lib.pull();
    expect(again.changed, isFalse);
  });

  test('a wrong token publishes nothing', () async {
    await phone.repo.createPoem(title: 'A', body: textA);
    expect(() => phone.lib.publish('wrong'), throwsA(isA<http.ClientException>()));
  });

  test('nothing online yet is not an error', () async {
    final r = await reader.lib.pull();
    expect(r.checked, isTrue);
    expect(r.changed, isFalse);
  });
}
