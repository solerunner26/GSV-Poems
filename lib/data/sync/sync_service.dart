import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../backup/backup_codec.dart';
import '../backup/backup_service.dart';
import '../poem_repository.dart';
import 'remote_store.dart';

class SyncResult {
  const SyncResult({this.devices = 0, this.added = 0, this.updated = 0, this.uploaded = false, this.needsKey = false});

  /// Other devices whose backups were read.
  final int devices;
  final int added, updated;
  final bool uploaded;

  /// Another device's backup is locked with a different recovery key: the
  /// poet must type that key once on this device.
  final bool needsKey;
}

/// Two (or more) devices share one Drive folder. Each keeps its own latest
/// backup there (`gsv-poems-latest-<device>.gsvbak`) plus a dated copy per day.
/// Syncing reads the others' latest backups, merges them poem by poem (newer
/// edit wins, the other text goes to history, nothing is duplicated or erased),
/// then uploads this device's backup.
class SyncService {
  SyncService(this.repo, this.backups, this.remote, {this.ownerVerifier});
  final PoemRepository repo;
  final BackupService backups;
  final RemoteStore remote;

  /// On the poet's own phone: its PIN verifier, published so that his PIN
  /// can unlock writing on another device.
  final Future<Map<String, String>?> Function()? ownerVerifier;

  static const ownerFile = 'gsv-owner.json';

  /// The poet's PIN verifier, as published by his phone, or null.
  Future<Map<String, dynamic>?> fetchOwnerVerifier() async {
    for (final f in await remote.list()) {
      if (f.name != ownerFile) continue;
      final m = jsonDecode(utf8.decode(await remote.download(f.id)));
      return m is Map<String, dynamic> ? m : null;
    }
    return null;
  }

  static const keepDailyDays = 14;
  static final _latest = RegExp(r'^gsv-poems-latest-([A-Za-z0-9]+)\.gsvbak$');
  static final _daily = RegExp(r'^gsv-poems-(\d{4}-\d{2}-\d{2})-([A-Za-z0-9]+)\.gsvbak$');

  Future<String> deviceId() async {
    final have = await repo.getSetting('deviceId');
    if (have != null) return have;
    final id = const Uuid().v4().replaceAll('-', '').substring(0, 12);
    await repo.setSetting('deviceId', id);
    return id;
  }

  /// Syncs once. When [typedKey] is given (the other device's recovery key) it
  /// is checked against the other backup and then used on this device too.
  Future<SyncResult> sync({String? typedKey}) async {
    final me = await deviceId();
    final files = await remote.list();
    var devices = 0, added = 0, updated = 0;
    var needsKey = false;
    for (final f in files) {
      final m = _latest.firstMatch(f.name);
      if (m == null || m[1] == me) continue;
      final seenKey = 'syncSeen:${f.name}';
      final seen = await repo.getSetting(seenKey);
      if (seen == f.modified.toIso8601String() && typedKey == null) {
        devices++;
        continue;
      }
      final bytes = await remote.download(f.id);
      Map<String, dynamic> data;
      try {
        data = (await backups.open(bytes)).data;
      } on WrongKeyException {
        if (typedKey == null) {
          needsKey = true;
          continue;
        }
        try {
          data = (await backups.open(bytes, typedKey: typedKey)).data;
        } on WrongKeyException {
          needsKey = true;
          continue;
        }
        await backups.adoptRecoveryKey(typedKey);
      }
      final out = await repo.restoreBackup(data, applySettings: false);
      added += out.added;
      updated += out.updated;
      devices++;
      await repo.setSetting(seenKey, f.modified.toIso8601String());
    }

    // Never upload with a different key than the other device: wait until the
    // poet has typed the shared recovery key.
    var uploaded = false;
    if (!needsKey) {
      final file = await backups.backupNow();
      final Uint8List bytes = await file.readAsBytes();
      await remote.upload('gsv-poems-latest-$me.gsvbak', bytes);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final dailyName = 'gsv-poems-$today-$me.gsvbak';
      if (!files.any((f) => f.name == dailyName)) await remote.upload(dailyName, bytes);
      uploaded = true;
      // Keep two weeks of daily copies per device on Drive.
      final cutoff = DateTime.now().subtract(const Duration(days: keepDailyDays));
      for (final f in files) {
        final d = _daily.firstMatch(f.name);
        if (d == null || d[2] != me) continue;
        final day = DateTime.tryParse(d[1]!);
        if (day != null && day.isBefore(cutoff)) await remote.delete(f.id);
      }
    }
    final owner = await ownerVerifier?.call();
    if (owner != null) await remote.upload(ownerFile, Uint8List.fromList(utf8.encode(jsonEncode(owner))));
    await repo.setSetting('lastSyncAt', DateTime.now().toIso8601String());
    await repo.setSetting('syncNeedsKey', needsKey ? '1' : '');
    return SyncResult(devices: devices, added: added, updated: updated, uploaded: uploaded, needsKey: needsKey);
  }
}
