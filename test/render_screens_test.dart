// Renders the main screens and every symbol to PNG files for a visual design
// review. Skipped unless PREVIEW_DIR is given:
//   flutter test test/render_screens_test.dart --dart-define=PREVIEW_DIR=<folder>
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
import 'package:gsv_poems/core/widgets/icon3d.dart';
import 'package:gsv_poems/data/backup/backup_service.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/data/poem_repository.dart';
import 'package:gsv_poems/features/backup/backup_screens.dart';
import 'package:gsv_poems/features/calendar/calendar_screen.dart';
import 'package:gsv_poems/features/collection/collection_screen.dart';
import 'package:gsv_poems/features/editor/editor_screen.dart';
import 'package:gsv_poems/features/home/home_screen.dart';
import 'package:gsv_poems/features/profile/profile_screen.dart';
import 'package:gsv_poems/data/profile.dart';
import 'package:gsv_poems/features/reader/reader_screen.dart';
import 'package:gsv_poems/features/settings/settings_screen.dart';

const _dir = String.fromEnvironment('PREVIEW_DIR');
final _theme = const String.fromEnvironment('THEME', defaultValue: 'night');

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
    await _font('TiroDevanagariHindi', ['assets/fonts/TiroDevanagariHindi-Regular.ttf']);
    for (final fam in ['HindVadodara', 'Roboto']) {
      await _font(fam, ['assets/fonts/HindVadodara-Regular.ttf', 'assets/fonts/HindVadodara-SemiBold.ttf', 'assets/fonts/HindVadodara-Bold.ttf']);
    }
  });

  Poem poem(String id, String title, String body, String cat, {int n = 1}) => Poem(
    id: id,
    number: n,
    title: title,
    body: body,
    lang: 'gu',
    categoryId: cat,
    isFavorite: n.isEven,
    wordCount: 12,
    searchBlob: '',
    createdAt: DateTime(2024, 11, 7),
    updatedAt: DateTime(2026, 11, 6),
    source: 'app',
    sourceKey: null,
    contentKey: null,
    deletedAt: null,
    kind: 'poem',
  );
  final poems = [
    poem('p1', 'વરસાદની પહેલી સાંજ', 'ભીની માટીની સુગંધમાં\nયાદો ફરી ખીલી ઊઠી\nઆંગણે ટપકે ટીપાં\nમનમાં ગીત જાગી ઊઠી', 'prakruti', n: 12),
    poem('p2', 'પ્રેમ મિલન', 'તું આવે ને\nઆખું આભ હસે', 'prem', n: 3),
    poem('p3', 'માનો ખોળો', 'સૌથી મીઠી છાંય\nમાનો ખોળો', 'parivar', n: 7),
  ];
  const cats = [
    PoemCategory(id: 'prakruti', nameGu: 'પ્રકૃતિ', nameHi: 'प्रकृति', nameEn: 'Nature', iconKey: 'prakruti', sortOrder: 1),
    PoemCategory(id: 'prem', nameGu: 'પ્રેમ', nameHi: 'प्रेम', nameEn: 'Love', iconKey: 'prem', sortOrder: 2),
    PoemCategory(id: 'parivar', nameGu: 'પરિવાર', nameHi: 'परिवार', nameEn: 'Family', iconKey: 'parivar', sortOrder: 3),
    PoemCategory(id: 'bhakti', nameGu: 'ભક્તિ', nameHi: 'भक्ति', nameEn: 'Devotion', iconKey: 'bhakti', sortOrder: 4),
    PoemCategory(id: 'desh', nameGu: 'દેશ પ્રેમ', nameHi: 'देश प्रेम', nameEn: 'Country', iconKey: 'desh', sortOrder: 5),
  ];

  Future<void> shoot(WidgetTester tester, String name, Widget screen, {bool scaffold = false}) async {
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
            prefsProvider.overrideWith(() => PrefsNotifier(AppPrefs(themeId: _theme))),
            statsProvider.overrideWith((ref) => Stream.value(const PoemStats(total: 890, words: 121105, gu: 801, hi: 89))),
            recentProvider.overrideWith((ref) => Stream.value(poems)),
            favoritesProvider.overrideWith((ref) => Stream.value(poems)),
            poemsProvider.overrideWith((ref, q) => Stream.value(poems)),
            poemProvider.overrideWith((ref, id) => Stream.value(poems.firstWhere((p) => p.id == id))),
            onThisDayProvider.overrideWith((ref) async => poems),
            duplicateCountProvider.overrideWith((ref) => Stream.value(0)),
            categoriesProvider.overrideWith((ref) => Stream.value(cats)),
            profileProvider.overrideWith(
              (ref) async => const Profile(name: 'ગીગાભાઈ સનાભાઈ વાળા', penName: 'ગૌરવ', birthDate: '૧૨ જૂન ૧૯૫૮', place: 'ભાવનગર'),
            ),
            backupStatusProvider.overrideWith((ref) async => BackupStatus(lastBackup: DateTime(2026, 11, 7, 23, 59), localCount: 14)),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(themeById(_theme)),
            home: LangScope(
              lang: PoemLang.gu,
              child: scaffold ? Scaffold(body: screen) : screen,
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$_dir/$name.png').writeAsBytes(png!.buffer.asUint8List());
    });
  }

  final screens = <String, (Widget, bool)>{
    'home': (HomeScreen(onOpenCollection: () {}, onWrite: () {}), true),
    'collection': (const CollectionScreen(), true),
    'topic': (const TopicPoemsScreen(lang: PoemLang.gu, topicId: 'prakruti'), false),
    'reader': (const ReaderScreen(ids: ['p1', 'p2']), false),
    'editor': (const EditorScreen(), false),
    'calendar': (CalendarScreen(initial: DateTime(2026, 11, 8)), false),
    'settings': (const SettingsScreen(), true),
    'profile': (const ProfileScreen(), false),
  };
  for (final e in screens.entries) {
    testWidgets('screen ${e.key}', skip: _dir.isEmpty, (tester) async {
      await shoot(tester, '${_theme}_${e.key}', e.value.$1, scaffold: e.value.$2);
    });
  }

  testWidgets('all symbols', skip: _dir.isEmpty, (tester) async {
    await shoot(
      tester,
      '${_theme}_icons',
      Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final k in iconArt.keys)
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon3D(k, size: 58),
                  // Centre guides.
                  Container(width: 1, height: 58, color: const Color(0x66FF0000)),
                  Container(width: 58, height: 1, color: const Color(0x66FF0000)),
                ],
              ),
          ],
        ),
      ),
      scaffold: true,
    );
  });
}
