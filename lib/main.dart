import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'app_providers.dart';
import 'data/db/database.dart';
import 'data/import/seed.dart';
import 'data/poem_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final db = AppDatabase();
  final repo = PoemRepository(db);
  final prefs = AppPrefs.fromMap(await repo.allSettings());
  // The poet's bundled poems fill the collections on first launch (and add any
  // new ones after an update). Runs in the background; the screens update live.
  unawaited(loadSeed(repo, () => rootBundle.loadString(seedAsset)));
  runApp(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(db),
      prefsProvider.overrideWith(() => PrefsNotifier(prefs)),
    ],
    child: const GsvApp(),
  ));
}
