import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gsv_poems/app_providers.dart';
import 'package:gsv_poems/core/l10n/strings.dart';
import 'package:gsv_poems/core/text/text_tools.dart';
import 'package:gsv_poems/core/theme/app_themes.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/data/poem_repository.dart';
import 'package:gsv_poems/features/calendar/calendar_screen.dart';
import 'package:gsv_poems/features/home/home_screen.dart';

/// Renders screens on a phone-sized and a tablet-sized surface in all three
/// languages, and fails on any layout overflow or exception. Database streams
/// are replaced with fixed sample data so the test needs no database.
void main() {
  setUpAll(() => initializeDateFormatting());

  final poem = Poem(
    id: 'p1', number: 12, title: 'વરસાદની પહેલી સાંજ', body: 'ભીની માટીની સુગંધમાં\nયાદો ફરી ખીલી ઊઠી', lang: 'gu',
    categoryId: 'prakruti', isFavorite: true, wordCount: 7, searchBlob: '', createdAt: DateTime(2024, 11, 7),
    updatedAt: DateTime(2026, 11, 6), source: 'app', sourceKey: null, contentKey: null, deletedAt: null,
  );

  Future<void> pumpScreen(WidgetTester tester, Widget screen, PoemLang lang, Size size) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        minuteProvider.overrideWith((ref) => Stream.value(DateTime(2026, 11, 7, 15, 40))),
        prefsProvider.overrideWith(() => PrefsNotifier(AppPrefs(lang: lang))),
        statsProvider.overrideWith((ref) => Stream.value(const PoemStats(total: 890, words: 121105, gu: 801, hi: 89))),
        recentProvider.overrideWith((ref) => Stream.value([poem])),
        favoritesProvider.overrideWith((ref) => Stream.value([poem])),
        poemsProvider.overrideWith((ref, q) => Stream.value([poem])),
        onThisDayProvider.overrideWith((ref) async => [poem]),
        duplicateCountProvider.overrideWith((ref) => Stream.value(2)),
        categoriesProvider.overrideWith((ref) => Stream.value(const <PoemCategory>[])),
      ],
      child: MaterialApp(theme: buildTheme(themeById('mor')), home: LangScope(lang: lang, child: screen)),
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final lang in PoemLang.values) {
    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      testWidgets('Panchang screen · ${lang.name} · ${size.width.toInt()}', (tester) async {
        await pumpScreen(tester, CalendarScreen(initial: DateTime(2026, 11, 8)), lang, size);
        expect(tester.takeException(), isNull);
        expect(find.textContaining(tr('panchang', lang)), findsWidgets);
      });
      testWidgets('Home screen · ${lang.name} · ${size.width.toInt()}', (tester) async {
        await pumpScreen(tester, Scaffold(body: HomeScreen(onOpenCollection: () {}, onWrite: () {})), lang, size);
        expect(tester.takeException(), isNull);
        expect(find.textContaining(tr('upcoming_fest', lang)), findsOneWidget);
      });
    }
  }
}
