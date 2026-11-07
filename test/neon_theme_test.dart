import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/app_providers.dart';
import 'package:gsv_poems/core/l10n/strings.dart';
import 'package:gsv_poems/core/text/text_tools.dart';
import 'package:gsv_poems/core/theme/app_themes.dart';
import 'package:gsv_poems/core/theme/neon_backdrop.dart';
import 'package:gsv_poems/core/theme/neon_tokens.dart';
import 'package:gsv_poems/core/widgets/common.dart';
import 'package:gsv_poems/core/widgets/icon3d.dart';
import 'package:gsv_poems/core/widgets/neon_surface.dart';
import 'package:gsv_poems/data/poem_repository.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/features/common/poem_share.dart';

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('six themes, in the agreed order, keep the saved ids', () {
    expect(allThemes.map((t) => t.id), ['mor', 'night', 'light', 'neel', 'van', 'kamal']);
    expect(allThemes.map((t) => t.effect), AccentEffect.values);
    expect(NeonAuraPainter.energize(0), 0);
    expect(NeonAuraPainter.energize(0.65), closeTo(1, 1e-9));
    expect(NeonAuraPainter.energize(1), 0);
    for (final t in allThemes) {
      expect(tr('theme_${t.id}', PoemLang.en), isNot('theme_${t.id}'), reason: 'theme name is localised');
    }
  });

  test('a saved theme survives a restart, and unknown ids fall back to First Light', () {
    for (final t in allThemes) {
      final prefs = AppPrefs.fromMap({'theme': t.id});
      expect(themeById(prefs.themeId).id, t.id);
    }
    expect(themeById(AppPrefs.fromMap({}).themeId).id, 'mor');
    expect(themeById('gone').id, 'mor');
  });

  group('contrast stays readable at the brightest backdrop', () {
    for (final t in allThemes) {
      test(t.id, () {
        final peak = backdropAlpha(1, dark: t.isDark, intensity: NeonTokens.standard.backdropIntensity, glow: t.glow);
        final page = Color.alphaBlend(t.glow.withValues(alpha: peak), t.bg);
        final opacity = t.isDark ? NeonTokens.cardOpacityDark : NeonTokens.cardOpacityLight;
        final card = Color.alphaBlend(t.surface.withValues(alpha: opacity), page);
        expect(contrast(t.ink, page), greaterThanOrEqualTo(4.5), reason: 'ink on page');
        expect(contrast(t.ink, card), greaterThanOrEqualTo(4.5), reason: 'ink on card');
        expect(contrast(t.mute, card), greaterThanOrEqualTo(4.5), reason: 'secondary text on card');
        expect(contrast(t.onPrimary, t.primary), greaterThanOrEqualTo(4.5), reason: 'button label');
        expect(contrast(t.accentText, card), greaterThanOrEqualTo(4.5), reason: 'accent text on card');
        expect(contrast(Colors.white, t.heroB), greaterThanOrEqualTo(4.5), reason: 'white on hero card');
      });
    }
  });

  Widget host(GsvColors t, Widget child, {bool reduce = false}) => MaterialApp(
        theme: buildTheme(t),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: LangScope(lang: PoemLang.gu, child: Scaffold(body: Center(child: child))),
        ),
      );

  for (final t in allThemes) {
    for (final reduce in [false, true]) {
      testWidgets('presses fire once with accents · ${t.id} · reduce=$reduce', (tester) async {
        var card = 0, button = 0, icon = 0;
        await tester.pumpWidget(host(
          t,
          Column(mainAxisSize: MainAxisSize.min, children: [
            GsvCard(onTap: () => card++, child: const Text('card')),
            PrimaryButton(label: 'go', icon: 'write', onPressed: () => button++),
            Icon3DButton('star', label: 'star', onPressed: () => icon++),
          ]),
          reduce: reduce,
        ));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('card'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.bySemanticsLabel('go'));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byType(Icon3DButton));
        await tester.pump(const Duration(seconds: 1));
        expect([card, button, icon], [1, 1, 1]);
        expect(tester.takeException(), isNull);
        expect(find.byType(Icon3D), findsWidgets);
      });
    }
  }

  testWidgets('poem picture is a JPEG', (tester) async {
    final poem = Poem(
      id: 'p1', number: 12, title: 'વરસાદ', body: 'ભીની માટીની સુગંધમાં\nયાદો ફરી ખીલી ઊઠી', lang: 'gu', categoryId: 'prakruti',
      isFavorite: false, wordCount: 7, searchBlob: '', createdAt: DateTime(2024), updatedAt: DateTime(2024),
      source: 'app', sourceKey: null, contentKey: null, deletedAt: null,
    );
    for (final t in [allThemes.first, allThemes[1]]) {
      final bytes = await tester.runAsync(() => poemJpeg(poem, t));
      expect(bytes, isNotNull);
      expect(bytes!.sublist(0, 2), [0xFF, 0xD8]);
      expect(bytes.length, greaterThan(10000));
    }
  });

  test('search lists title matches first, then poems with the word only in verses', () {
    Poem poem(String id, String title, String body, int age) => Poem(
          id: id, number: null, title: title, body: body, lang: 'gu', categoryId: null, isFavorite: false, wordCount: 0,
          searchBlob: '', createdAt: DateTime(2024), updatedAt: DateTime(2026, 1, 30 - age), source: 'app',
          sourceKey: null, contentKey: null, deletedAt: null,
        );
    // Newest first, as the database returns them.
    final found = [
      poem('v1', 'સાંજ', 'મનમાં પ્રેમ જાગ્યો', 0),
      poem('t3', 'પ્રકૃતિનો પ્રેમ', 'વૃક્ષો', 1),
      poem('v2', 'વરસાદ', 'પ્રેમાળ વાદળ અને પ્રેમ', 2),
      poem('t2', 'હું પ્રેમ કરી બેઠો', 'દિલ', 3),
      poem('t1', 'પ્રેમ મિલન', 'મળ્યા', 4),
    ];
    final ranked = PoemRepository.rankSearchResults(found, 'પ્રેમ').map((p) => p.id).toList();
    expect(ranked, ['t1', 't2', 't3', 'v1', 'v2']);
  });

  test('every symbol sits centred on its tile at one shared size', () {
    for (final key in iconArt.keys) {
      final box = debugGlyphBoxOnTile(key);
      expect((box.center.dx - 32).abs(), lessThan(0.01), reason: '$key horizontal');
      expect((box.center.dy - 30.4).abs(), lessThan(0.01), reason: '$key vertical');
      expect(box.longestSide, inInclusiveRange(20, 30.01), reason: '$key size');
      expect(Rect.fromLTWH(7, 6, 50, 50).contains(box.topLeft) && Rect.fromLTWH(7, 6, 50, 50).contains(box.bottomRight), isTrue,
          reason: '$key stays inside the tile');
    }
  });
}
