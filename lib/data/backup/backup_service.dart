import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../poem_repository.dart';
import '../security/pin_service.dart';
import 'backup_codec.dart';

/// Gmail settings for the automatic email backup, kept in secure storage.
class EmailConfig {
  const EmailConfig({required this.to, required this.from, required this.appPassword});
  final String to, from, appPassword;
  bool get complete => to.contains('@') && from.contains('@') && appPassword.replaceAll(' ', '').length >= 16;
}

class BackupStatus {
  const BackupStatus({this.lastBackup, this.lastEmail, this.lastError, this.localCount = 0, this.emailOn = false});
  final DateTime? lastBackup, lastEmail;
  final String? lastError;
  final int localCount;
  final bool emailOn;
}

/// Makes, keeps, sends and restores the encrypted backups.
class BackupService {
  BackupService(this.repo, this.secrets, {Future<Directory> Function()? baseDir})
      : _baseDir = baseDir ?? getApplicationDocumentsDirectory;

  final PoemRepository repo;
  final SecretStore secrets;
  final Future<Directory> Function() _baseDir;

  static const keepLocal = 7;
  static const _kRecovery = 'recovery_key', _kAck = 'recovery_ack';
  static const _kTo = 'email_to', _kFrom = 'email_from', _kPass = 'email_app_password';

  // ---------- recovery key ----------

  /// The phone's recovery key, created the first time it is needed.
  Future<String> recoveryKey() async {
    final k = await secrets.read(_kRecovery);
    if (k != null) return k;
    final fresh = newRecoveryKey();
    await secrets.write(_kRecovery, fresh);
    return fresh;
  }

  Future<bool> hasRecoveryKey() async => (await secrets.read(_kRecovery)) != null;

  /// Use a key typed by the poet (after restoring an old backup) from now on,
  /// so there is always just one key to keep.
  Future<void> adoptRecoveryKey(String typed) => secrets.write(_kRecovery, _pretty(normalizeRecoveryKey(typed)));

  Future<bool> matchesRecoveryKey(String typed) async {
    final k = await secrets.read(_kRecovery);
    return k != null && normalizeRecoveryKey(k) == normalizeRecoveryKey(typed);
  }

  Future<bool> recoveryAcknowledged() => recoveryAcknowledgedIn(secrets);
  static Future<bool> recoveryAcknowledgedIn(SecretStore s) async => (await s.read(_kAck)) == '1';
  Future<void> acknowledgeRecovery() => secrets.write(_kAck, '1');

  static String _pretty(String n) => [for (var i = 0; i < n.length; i += 5) n.substring(i, (i + 5).clamp(0, n.length))].join('-');

  // ---------- email settings ----------

  Future<EmailConfig?> emailConfig() async {
    final to = await secrets.read(_kTo), from = await secrets.read(_kFrom), pass = await secrets.read(_kPass);
    if (to == null || from == null || pass == null) return null;
    return EmailConfig(to: to, from: from, appPassword: pass);
  }

  Future<void> saveEmailConfig(EmailConfig c) async {
    await secrets.write(_kTo, c.to.trim());
    await secrets.write(_kFrom, c.from.trim());
    await secrets.write(_kPass, c.appPassword.replaceAll(' ', ''));
  }

  Future<void> clearEmailConfig() async {
    await secrets.delete(_kTo);
    await secrets.delete(_kFrom);
    await secrets.delete(_kPass);
  }

  // ---------- making backups ----------

  Future<Directory> backupDir() async {
    final d = Directory('${(await _baseDir()).path}/backups');
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  /// Newest first.
  Future<List<File>> localBackups() async {
    final files = (await backupDir()).listSync().whereType<File>().where((f) => f.path.endsWith('.$backupExtension')).toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// Writes a new encrypted backup and keeps only the newest [keepLocal].
  Future<File> backupNow() async {
    final key = await recoveryKey();
    final bytes = await encodeBackup(await repo.exportBackup(), key, device: Platform.localHostname);
    final name = 'gsv-poems-${DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now())}.$backupExtension';
    final file = File('${(await backupDir()).path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    final all = await localBackups();
    for (final old in all.skip(keepLocal)) {
      try {
        old.deleteSync();
      } on FileSystemException {
        // Not fatal: try again next time.
      }
    }
    await repo.setSetting('lastBackupAt', DateTime.now().toIso8601String());
    return file;
  }

  /// One tap: Android's share sheet with the file attached (choose WhatsApp).
  Future<void> share(File f, {required String text}) =>
      SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'application/octet-stream')], text: text));

  /// Sends [f] by Gmail. Returns null on success, or the reason it failed.
  Future<String?> email(File f, {required String subject, required String body}) async {
    final c = await emailConfig();
    if (c == null || !c.complete) return 'not-configured';
    final message = Message()
      ..from = Address(c.from, 'GSV Poems')
      ..recipients.add(c.to)
      ..subject = subject
      ..text = body
      ..attachments.add(FileAttachment(f));
    try {
      await send(message, gmail(c.from, c.appPassword), timeout: const Duration(seconds: 60));
      await repo.setSetting('lastEmailAt', DateTime.now().toIso8601String());
      await repo.setSetting('lastBackupError', '');
      return null;
    } on Object catch (e) {
      final why = e is MailerException ? e.message : '$e';
      await repo.setSetting('lastBackupError', why);
      return why;
    }
  }

  /// A plain email holding only the recovery key (never sent together with a backup).
  Future<String?> emailRecoveryKey({required String subject, required String body}) async {
    final c = await emailConfig();
    if (c == null || !c.complete) return 'not-configured';
    final message = Message()
      ..from = Address(c.from, 'GSV Poems')
      ..recipients.add(c.to)
      ..subject = subject
      ..text = body;
    try {
      await send(message, gmail(c.from, c.appPassword), timeout: const Duration(seconds: 60));
      return null;
    } on Object catch (e) {
      return e is MailerException ? e.message : '$e';
    }
  }

  /// The nightly job: back up, then email it when email is set up.
  Future<void> nightly({required String subject, required String body}) async {
    final f = await backupNow();
    if ((await emailConfig())?.complete ?? false) await email(f, subject: subject, body: body);
  }

  /// True when the last backup is more than a day old (e.g. the phone was off at 11:59 PM).
  Future<bool> overdue() async {
    final last = DateTime.tryParse(await repo.getSetting('lastBackupAt') ?? '');
    return last == null || DateTime.now().difference(last) > const Duration(hours: 24);
  }

  Future<BackupStatus> status() async {
    final err = await repo.getSetting('lastBackupError');
    return BackupStatus(
      lastBackup: DateTime.tryParse(await repo.getSetting('lastBackupAt') ?? ''),
      lastEmail: DateTime.tryParse(await repo.getSetting('lastEmailAt') ?? ''),
      lastError: err == null || err.isEmpty ? null : err,
      localCount: (await localBackups()).length,
      emailOn: (await emailConfig())?.complete ?? false,
    );
  }

  // ---------- restoring ----------

  /// Opens a backup file: tries this phone's key first, then [typedKey].
  /// Returns the contents and which key worked.
  Future<({Map<String, dynamic> data, bool usedTypedKey})> open(Uint8List bytes, {String? typedKey}) async {
    if (typedKey != null) return (data: await decodeBackup(bytes, typedKey), usedTypedKey: true);
    final own = await secrets.read(_kRecovery);
    if (own == null) throw WrongKeyException();
    return (data: await decodeBackup(bytes, own), usedTypedKey: false);
  }
}
