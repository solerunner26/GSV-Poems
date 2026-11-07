import 'dart:async';

import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'app_providers.dart';
import 'data/db/database.dart';
import 'data/backup/scheduler.dart';
import 'data/import/seed.dart';
import 'data/poem_repository.dart';
import 'data/splash_photo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final db = AppDatabase();
  final repo = PoemRepository(db);
  final prefs = AppPrefs.fromMap(await repo.allSettings());
  await SplashPhoto.load();
  // The poet's bundled poems fill the collections on first launch (and add any
  // new ones after an update). Runs in the background; the screens update live.
  unawaited(loadSeed(repo, () => rootBundle.loadString(seedAsset)));
  // 11:59 PM backup and 7 PM festival reminder, also when the app is closed.
  unawaited(() async {
    try {
      await AndroidAlarmManager.initialize();
      await scheduleDailyJobs();
    } on Object {
      // Not fatal: a missed backup also runs when the app is opened.
    }
  }());
  runApp(ProviderScope(overrides: [dbProvider.overrideWithValue(db), prefsProvider.overrideWith(() => PrefsNotifier(prefs))], child: const GsvApp()));
}
