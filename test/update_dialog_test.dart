import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/core/l10n/strings.dart';
import 'package:gsv_poems/core/text/text_tools.dart';
import 'package:gsv_poems/core/theme/app_themes.dart';
import 'package:gsv_poems/core/widgets/icon3d.dart';
import 'package:gsv_poems/data/update/update_service.dart';
import 'package:gsv_poems/features/update/update_prompt.dart';

const _dir = String.fromEnvironment('PREVIEW_DIR');

void main() {
  const release = ReleaseInfo(
    tag: 'v2.2.0',
    name: 'GSV Poems 2.2.0 (build 12)',
    notes: '- નવો દેખાવ\n- અપડેટ સંદેશ હવે સ્પષ્ટ\n\n* Search: titles first\n• A much longer line that has to wrap onto two lines inside the dialog box without spilling',
    build: 12,
    apkUrl: 'https://example.invalid/app.apk',
    apkSize: 70000000,
  );

  test('release notes become clean points', () {
    expect(releasePoints(release.notes), [
      'નવો દેખાવ',
      'અપડેટ સંદેશ હવે સ્પષ્ટ',
      'Search: titles first',
      'A much longer line that has to wrap onto two lines inside the dialog box without spilling',
    ]);
  });

  testWidgets('a symbol in a wide box keeps its own size and stays centred', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(themeById('mor')),
        home: const Center(child: SizedBox(width: 400, height: 64, child: Icon3D('download', size: 64))),
      ),
    );
    final box = tester.getRect(find.byType(CustomPaint).last);
    expect(box.width, 64);
    expect(box.height, 64);
    expect(box.center.dx, closeTo(tester.getCenter(find.byType(SizedBox).first).dx, 0.5));
  });

  for (final themeId in ['mor', 'kamal']) {
    for (final lang in PoemLang.values) {
      for (final progress in [null, 0.42]) {
        testWidgets('update dialog · $themeId · ${lang.name} · ${progress == null ? 'ask' : 'downloading'}', (tester) async {
          tester.view.physicalSize = const Size(360, 740) * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          final key = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildTheme(themeById(themeId)),
                home: LangScope(
                  lang: lang,
                  child: Scaffold(
                    body: UpdateDialog(release: release, currentVersion: '2.1.0', initialProgress: progress),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.takeException(), isNull);
          expect(find.text(tr('update_title', lang)), findsOneWidget);
          expect(find.textContaining('2.2.0 · 67 MB', findRichText: true), findsOneWidget);
          // The symbol never overlaps the title.
          final icon = tester.getRect(find.byType(Icon3D).first);
          final title = tester.getRect(find.text(tr('update_title', lang)));
          expect(icon.overlaps(title), isFalse);
          if (progress == null) {
            expect(find.text(tr('update_now', lang)), findsOneWidget);
          } else {
            expect(find.textContaining('42%'), findsOneWidget);
            expect(find.text(tr('update_now', lang)), findsNothing);
          }
          if (_dir.isNotEmpty && lang == PoemLang.gu) {
            final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            await tester.runAsync(() async {
              for (final fam in ['NotoSerifGujarati', 'HindVadodara', 'Roboto']) {
                final l = FontLoader(fam)
                  ..addFont(
                    rootBundle.load(fam == 'NotoSerifGujarati' ? 'assets/fonts/NotoSerifGujarati.ttf' : 'assets/fonts/HindVadodara-Regular.ttf'),
                  );
                await l.load();
              }
            });
            await tester.pump(const Duration(milliseconds: 100));
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 1);
              final png = await image.toByteData(format: ui.ImageByteFormat.png);
              await File('$_dir/update_${themeId}_${progress == null ? 'ask' : 'dl'}.png').writeAsBytes(png!.buffer.asUint8List());
            });
          }
        });
      }
    }
  }
}
