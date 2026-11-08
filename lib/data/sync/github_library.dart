import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../backup/backup_codec.dart';
import '../backup/backup_service.dart';
import '../poem_repository.dart';

class LibraryResult {
  const LibraryResult({this.checked = false, this.changed = false, this.added = 0, this.updated = 0, this.published = false, this.needsKey = false});

  /// The online copy was read.
  final bool checked;

  /// It held something new and was merged in.
  final bool changed;
  final int added, updated;

  /// This device's poems were sent up.
  final bool published;

  /// The online copy is locked with another recovery key.
  final bool needsKey;
}

/// The whole collection, encrypted with the recovery key, kept as one file in
/// a public GitHub repository. The poet's devices publish it (with a GitHub
/// token typed once on them); every device reads it without any account, so
/// readers see new poems the day they open the app. Without the recovery key
/// the file is unreadable.
class GithubLibrary {
  GithubLibrary(this.repo, this.backups, {http.Client? client, this.owner = defaultOwner, this.name = defaultRepo}) : _http = client ?? http.Client();

  static const defaultOwner = 'solerunner26';
  static const defaultRepo = 'GSV-Poems-Data';
  static const path = 'poems.gsvbak';

  final PoemRepository repo;
  final BackupService backups;
  final http.Client _http;
  final String owner, name;

  Uri get _contents => Uri.https('api.github.com', '/repos/$owner/$name/contents/$path');

  /// Where readers can see the file (shown in Settings).
  String get webUrl => 'https://github.com/$owner/$name';

  static String _today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// A fingerprint of the poems and topics only (not settings or edit times of
  /// the backup itself), so an unchanged collection is never sent twice.
  Future<String> fingerprint() async {
    final data = await repo.exportBackup();
    final poems = [...(data['poems'] as List)]..sort((a, b) => '${(a as Map)['id']}'.compareTo('${(b as Map)['id']}'));
    final cats = [...(data['categories'] as List)]..sort((a, b) => '${(a as Map)['id']}'.compareTo('${(b as Map)['id']}'));
    return sha1.convert(utf8.encode(jsonEncode({'p': poems, 'c': cats}))).toString();
  }

  /// Reads the online copy and merges anything new (newer edit wins, nothing
  /// is lost). [typedKey]: the poet's recovery key, typed once on a new device.
  Future<LibraryResult> pull({String? typedKey}) async {
    final r = await _http.get(_contents, headers: {'Accept': 'application/vnd.github.raw', 'Cache-Control': 'no-cache'});
    if (r.statusCode == 404) return const LibraryResult(checked: true);
    if (r.statusCode != 200) throw http.ClientException('GitHub ${r.statusCode}');
    final bytes = r.bodyBytes;
    final digest = sha1.convert(bytes).toString();
    if (typedKey == null && await repo.getSetting('libSeen') == digest) {
      await repo.setSetting('libCheckedAt', DateTime.now().toIso8601String());
      return const LibraryResult(checked: true);
    }
    Map<String, dynamic> data;
    try {
      data = (await backups.open(bytes, typedKey: typedKey)).data;
    } on WrongKeyException {
      await repo.setSetting('libNeedsKey', '1');
      return const LibraryResult(checked: true, needsKey: true);
    }
    if (typedKey != null) await backups.adoptRecoveryKey(typedKey);
    final out = await repo.restoreBackup(data, applySettings: false);
    await repo.setSetting('libSeen', digest);
    await repo.setSetting('libNeedsKey', '');
    await repo.setSetting('libCheckedAt', DateTime.now().toIso8601String());
    await repo.setSetting('libPulledOn', _today());
    return LibraryResult(checked: true, changed: true, added: out.added, updated: out.updated);
  }

  /// Merges the online copy, then publishes this device's collection when it
  /// differs from what was last published. Needs the poet's GitHub [token].
  Future<LibraryResult> publish(String token) async {
    final before = await pull();
    if (before.needsKey) return before;
    final fp = await fingerprint();
    if (await repo.getSetting('libPublished') == fp) return before;
    final bytes = await encodeBackup(await repo.exportBackup(), await backups.recoveryKey(), device: 'library');
    final auth = {'Authorization': 'Bearer $token', 'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28'};
    Future<http.Response> put() async {
      final meta = await _http.get(_contents, headers: auth);
      final sha = meta.statusCode == 200 ? (jsonDecode(meta.body) as Map<String, dynamic>)['sha'] as String? : null;
      return _http.put(
        _contents,
        headers: {...auth, 'Content-Type': 'application/json'},
        body: jsonEncode({'message': 'Poems ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', 'content': base64Encode(bytes), 'sha': ?sha}),
      );
    }

    var res = await put();
    // Someone published in between: take theirs in, then try once more.
    if (res.statusCode == 409 || res.statusCode == 422) {
      await pull();
      res = await put();
    }
    if (res.statusCode != 200 && res.statusCode != 201) throw http.ClientException('GitHub ${res.statusCode}: ${res.body}');
    await repo.setSetting('libPublished', fp);
    await repo.setSetting('libSeen', sha1.convert(bytes).toString());
    await repo.setSetting('libPublishedAt', DateTime.now().toIso8601String());
    return LibraryResult(checked: true, changed: before.changed, added: before.added, updated: before.updated, published: true);
  }

  /// True when this device has not looked at the online copy today.
  Future<bool> dueToday() async => await repo.getSetting('libPulledOn') != _today();
}
