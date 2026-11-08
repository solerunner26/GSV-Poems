// Renders the Home screen in each theme to PNG files for a visual check of the
// neon backdrop, glows and accents. Run with:
//   flutter test test/render_preview_test.dart --dart-define=PREVIEW_DIR=<folder>
// Without PREVIEW_DIR it is skipped.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gsv_poems/app_providers.dart';
import 'package:gsv_poems/core/l10n/strings.dart';
import 'package:gsv_poems/core/text/text_tools.dart';
import 'package:gsv_poems/core/theme/app_themes.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/data/poem_repository.dart';
import 'package:gsv_poems/features/home/home_screen.dart';

const _dir = String.fromEnvironment('PREVIEW_DIR');

Future<void> _font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(rootBundle.load(f));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await _font('NotoSerifGujarati', ['assets/fonts/NotoSerifGujarati.ttf']);
    await _font('HindVadodara', ['assets/fonts/HindVadodara-Regular.ttf', 'assets/fonts/HindVadodara-Bold.ttf']);
    await _font('Roboto', ['assets/fonts/HindVadodara-Regular.ttf', 'assets/fonts/HindVadodara-Bold.ttf']);
  });

  final poem = Poem(
    id: 'p1',
    number: 12,
    title: 'વરસાદની પહેલી સાંજ',
    body: 'ભીની માટીની સુગંધમાં\nયાદો ફરી ખીલી ઊઠી',
    lang: 'gu',
    categoryId: 'prakruti',
    isFavorite: true,
    wordCount: 7,
    searchBlob: '',
    createdAt: DateTime(2024, 11, 7),
    updatedAt: DateTime(2026, 11, 6),
    source: 'app',
    sourceKey: null,
    contentKey: null,
    deletedAt: null,
    kind: 'poem', isDraft: false,
  );

  final themes = const String.fromEnvironment('THEMES', defaultValue: 'mor,night,light,neel,van,kamal').split(',');
  final times = const String.fromEnvironment('TIMES', defaultValue: '0,3000').split(',').map(int.parse).toList();
  for (final id in themes) {
    testWidgets('preview $id', skip: _dir.isEmpty, (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ProviderScope(
            overrides: [
              minuteProvider.overrideWith((ref) => Stream.value(DateTime(2026, 11, 7, 15, 40))),
              prefsProvider.overrideWith(() => PrefsNotifier(const AppPrefs(lang: PoemLang.gu))),
              statsProvider.overrideWith((ref) => Stream.value(const PoemStats(total: 890, words: 121105, gu: 801, hi: 89))),
              recentProvider.overrideWith((ref) => Stream.value([poem, poem])),
              favoritesProvider.overrideWith((ref) => Stream.value([poem])),
              poemsProvider.overrideWith((ref, q) => Stream.value([poem])),
              onThisDayProvider.overrideWith((ref) async => [poem]),
              duplicateCountProvider.overrideWith((ref) => Stream.value(0)),
              categoriesProvider.overrideWith((ref) => Stream.value(const <PoemCategory>[])),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTheme(themeById(id)),
              home: LangScope(
                lang: PoemLang.gu,
                child: Scaffold(
                  body: HomeScreen(onOpenCollection: () {}, onWrite: () {}),
                ),
              ),
            ),
          ),
        ),
      );
      var elapsed = 0;
      for (final t in times) {
        await tester.pump(Duration(milliseconds: t - elapsed));
        elapsed = t;
        if (t == times.last && const bool.fromEnvironment('TAP')) {
          await tester.tapAt(const Offset(195, 200));
          await tester.pump(const Duration(milliseconds: 450));
        }
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('$_dir/home_${id}_$t.png').writeAsBytes(png!.buffer.asUint8List());
        });
      }
    });
  }
}
