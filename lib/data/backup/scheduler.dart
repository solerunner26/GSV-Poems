import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/l10n/strings.dart';
import '../../core/panchang/festivals.dart';
import '../../core/panchang/panchang.dart';
import '../../core/text/text_tools.dart';
import '../db/database.dart';
import '../poem_repository.dart';
import '../security/pin_service.dart';
import 'backup_service.dart';
import '../sync/drive_service.dart';
import '../sync/sync_service.dart';

const _nightlyId = 1159, _reminderId = 1900;

/// Next time the clock shows [hour]:[minute] (today if still ahead, else tomorrow).
DateTime nextAt(int hour, int minute, [DateTime? from]) {
  final now = from ?? DateTime.now();
  var t = DateTime(now.year, now.month, now.day, hour, minute);
  if (!t.isAfter(now.add(const Duration(seconds: 30)))) t = t.add(const Duration(days: 1));
  return t;
}

/// Sets the two daily alarms (calling again simply replaces them). Uses an
/// exact alarm when Android allows it, otherwise one that may run a few
/// minutes late. A missed backup also runs the next time the app opens.
Future<void> scheduleDailyJobs() async {
  Future<void> one(DateTime at, int id, Function cb) async {
    try {
      final ok = await AndroidAlarmManager.oneShotAt(at, id, cb, exact: true, wakeup: true, allowWhileIdle: true, rescheduleOnReboot: true);
      if (ok) return;
    } on Object {
      // Exact alarms not allowed on this phone: fall back below.
    }
    await AndroidAlarmManager.oneShotAt(at, id, cb, exact: false, wakeup: true, allowWhileIdle: true, rescheduleOnReboot: true);
  }

  await one(nextAt(23, 59), _nightlyId, nightlyBackupAlarm);
  await one(nextAt(19, 0), _reminderId, festivalReminderAlarm);
}

final _notes = FlutterLocalNotificationsPlugin();

Future<void> _initNotes() => _notes.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));

/// Asks Android 13+ for permission to show notifications (once).
Future<void> askNotificationPermission() async {
  await _initNotes();
  await _notes.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
}

Future<void> _show(int id, String title, String body, {required String channel, required String channelName}) => _notes.show(
  id: id,
  title: title,
  body: body,
  notificationDetails: NotificationDetails(
    android: AndroidNotificationDetails(
      channel,
      channelName,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    ),
  ),
);

Future<(AppDatabase, PoemRepository, PoemLang)> _open() async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final repo = PoemRepository(db);
  final lang = langFromCode(await repo.getSetting('lang') ?? 'gu');
  return (db, repo, lang);
}

/// Runs at 11:59 PM, even when the app is closed.
@pragma('vm:entry-point')
Future<void> nightlyBackupAlarm() async {
  final (db, repo, lang) = await _open();
  try {
    final backups = BackupService(repo, const SecureSecretStore());
    await backups.nightly(subject: tr('backup_mail_subject', lang), body: tr('backup_mail_body', lang));
    // Drive (when connected): best effort from the background; the app also syncs on open.
    if ((await repo.getSetting('driveEmail'))?.isNotEmpty ?? false) {
      try {
        final id = await repo.getSetting('driveClientId');
        final drive = DriveService(id == null || id.isEmpty ? defaultWebClientId : id);
        if (await drive.signInQuietly()) await SyncService(repo, backups, drive).sync();
      } on Object {
        // Not fatal.
      }
    }
  } on Object catch (e) {
    await _initNotes();
    await _show(2, tr('backup_failed', lang), '$e', channel: 'backup', channelName: 'Backup');
  } finally {
    await db.close();
    await AndroidAlarmManager.oneShotAt(
      nextAt(23, 59),
      _nightlyId,
      nightlyBackupAlarm,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    ).catchError((_) => false);
  }
}

/// Runs at 7 PM: "Tomorrow is Ekadashi" and the like.
@pragma('vm:entry-point')
Future<void> festivalReminderAlarm() async {
  final (db, repo, lang) = await _open();
  try {
    final lat = double.tryParse(await repo.getSetting('placeLat') ?? ''), lon = double.tryParse(await repo.getSetting('placeLon') ?? '');
    final place = lat == null || lon == null ? Place.ahmedabad : Place('', lat, lon);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final f = festivalsOn(tomorrow, place);
    if (f.isNotEmpty) {
      await _initNotes();
      final p = panchangFor(tomorrow, place);
      await _show(
        1,
        '${tr('tomorrow_is', lang)} ${f.map((x) => x.names[lang.index]).join(' · ')}',
        dateLine(p, lang.index),
        channel: 'festivals',
        channelName: tr('upcoming_fest', lang),
      );
    }
  } finally {
    await db.close();
    await AndroidAlarmManager.oneShotAt(
      nextAt(19, 0),
      _reminderId,
      festivalReminderAlarm,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    ).catchError((_) => false);
  }
}
