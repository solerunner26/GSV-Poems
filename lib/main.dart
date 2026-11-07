import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'app_providers.dart';
import 'data/db/database.dart';
import 'data/poem_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final db = AppDatabase();
  final prefs = AppPrefs.fromMap(await PoemRepository(db).allSettings());
  runApp(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(db),
      prefsProvider.overrideWith(() => PrefsNotifier(prefs)),
    ],
    child: const GsvApp(),
  ));
}
