import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/app_providers.dart';
import 'package:gsv_poems/core/l10n/strings.dart';
import 'package:gsv_poems/core/text/text_tools.dart';
import 'package:gsv_poems/core/theme/app_themes.dart';
import 'package:gsv_poems/data/db/database.dart';
import 'package:gsv_poems/data/poem_repository.dart';
import 'package:gsv_poems/data/profile.dart';
import 'package:gsv_poems/features/profile/profile_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('profile details are saved and read back', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PoemRepository(db);
    expect((await Profile.load(repo)).isEmpty, isTrue);
    const p = Profile(name: 'ગીગાભાઈ સનાભાઈ વાળા', penName: 'ગૌરવ', place: 'ભાવનગર', email: 'poet@example.com', about: 'કવિ\nલેખક');
    await p.save(repo);
    final back = await Profile.load(repo);
    for (final f in Profile.fields) {
      expect(back[f], p[f], reason: f);
    }
    expect(back.isEmpty, isFalse);
  });

  test('every profile field has a label in all three languages', () {
    for (final f in Profile.fields) {
      for (final l in PoemLang.values) {
        expect(tr('profile_$f', l), isNot('profile_$f'));
      }
    }
  });

  for (final lang in PoemLang.values) {
    testWidgets('profile screen shows photo, details and security · ${lang.name}', (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWith(() => PrefsNotifier(AppPrefs(lang: lang))),
            statsProvider.overrideWith((ref) => Stream.value(const PoemStats(total: 890, words: 121105, gu: 801, hi: 89))),
            profileProvider.overrideWith((ref) async => const Profile(name: 'ગીગાભાઈ', penName: 'ગૌરવ', place: 'ભાવનગર')),
          ],
          child: MaterialApp(
            theme: buildTheme(themeById('night')),
            home: LangScope(lang: lang, child: const ProfileScreen()),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('ગીગાભાઈ'), findsOneWidget);
      expect(find.text('“ગૌરવ”'), findsOneWidget);
      expect(find.text('ભાવનગર'), findsOneWidget);
      await tester.scrollUntilVisible(find.text(tr('change_pin', lang)), 200);
      expect(find.text(tr('change_pin', lang)), findsOneWidget);
      expect(find.text(tr('fingerprint', lang)), findsOneWidget);
      expect(find.text(tr('recovery_view', lang)), findsOneWidget);
      expect(find.byType(PoetAvatar), findsOneWidget);
    });
  }

  testWidgets('home shows the profile photo button in place of help', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(themeById('mor')),
        home: const LangScope(
          lang: PoemLang.gu,
          child: Scaffold(body: Center(child: ProfileButton())),
        ),
      ),
    );
    await tester.pump();
    expect(find.bySemanticsLabel(tr('profile', PoemLang.gu)), findsOneWidget);
  });
}
