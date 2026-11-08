import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
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
import 'package:gsv_poems/data/security/pin_service.dart';
import 'package:gsv_poems/core/panchang/panchang.dart';
import 'package:gsv_poems/features/calendar/calendar_screen.dart';
import 'package:gsv_poems/features/collection/collection_screen.dart';
import 'package:gsv_poems/features/home/home_screen.dart';
import 'package:gsv_poems/features/sync/writer_gate.dart';

class MemoryStore implements SecretStore {
  final m = <String, String>{};
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
  @override
  Future<void> delete(String key) async => m.remove(key);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(initializeDateFormatting);

  test('text size: huge phone fonts are kept in range, and the chosen size applies on top', () {
    expect(appTextScale(1.0, 1.0), 1.0);
    expect(appTextScale(1.6, 1.0), 1.1);
    expect(appTextScale(0.7, 1.0), 0.85);
    expect(appTextScale(1.3, 0.8), closeTo(0.88, 1e-9));
    expect(textSizes.map((s) => s.$1), [0.8, 0.9, 1.0, 1.15, 1.3]);
    for (final s in textSizes) {
      expect(tr(s.$2, PoemLang.gu), isNot(s.$2));
    }
  });

  test("the poet's devices may write; other phones only read", () {
    expect(isPoetDevice((maker: 'nothing', model: 'A059P')), isTrue);
    expect(isPoetDevice((maker: 'samsung', model: 'SM-T870')), isTrue);
    expect(isPoetDevice((maker: 'samsung', model: 'SM-T976B')), isTrue);
    expect(isPoetDevice((maker: 'samsung', model: 'SM-S918B')), isFalse);
    expect(isPoetDevice((maker: 'xiaomi', model: '23090RA98I')), isFalse);
    expect(isPoetDevice((maker: '', model: '')), isFalse);
    expect(publishesOwnerPin((maker: 'nothing', model: 'A059')), isTrue);
    expect(publishesOwnerPin((maker: 'samsung', model: 'SM-T870')), isFalse);
  });

  test("the poet's PIN check unlocks another device; a wrong PIN does not", () async {
    final pins = PinService(MemoryStore(), iterations: 1000);
    await pins.setPin('4321');
    final v = (await pins.verifier())!;
    expect(v.containsKey('hash') && v.containsKey('salt'), isTrue);
    expect(v.values.any((x) => x.contains('4321')), isFalse, reason: 'never the PIN itself');
    expect(await PinService.matches(v, '4321'), isTrue);
    expect(await PinService.matches(v, '1234'), isFalse);
  });

  test('prose is kept apart from poems and counted on its own', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = PoemRepository(db);
    await repo.createPoem(title: 'કવિતા', body: 'ભીની માટીની સુગંધમાં યાદો ફરી');
    final essay = await repo.createPoem(title: 'નિબંધ', body: 'આ એક લાંબો લેખ છે જેમાં વિચારો છે.', kind: Kind.prose);
    await repo.createPoem(title: 'लेख', body: 'यह एक हिंदी लेख है।', kind: Kind.prose);
    final s = await repo.watchStats().first;
    expect((s.poems, s.prose, s.proseGu, s.proseHi, s.poemsGu), (1, 2, 1, 1, 1));
    expect(s.of(Kind.prose, lang: 'hi'), 1);
    expect((await repo.watchPoems(kind: Kind.prose).first).length, 2);
    expect((await repo.watchPoems(kind: Kind.poem).first).length, 1);
    // Switching kind in the editor moves it.
    await repo.updatePoem(essay, title: 'નિબંધ', body: 'આ એક લાંબો લેખ છે જેમાં વિચારો છે.', kind: Kind.poem);
    expect((await repo.watchStats().first).prose, 1);
    // Backups from before prose existed still restore, as poems.
    final data = await repo.exportBackup();
    for (final p in data['poems'] as List) {
      (p as Map).remove('kind');
    }
    final other = AppDatabase(NativeDatabase.memory());
    addTearDown(other.close);
    final out = await PoemRepository(other).restoreBackup(data, applySettings: false);
    expect(out.added, 3);
    expect((await PoemRepository(other).watchStats().first).poems, 3);
  });

  Poem poem(String id, String title, String kind, String lang, String cat) => Poem(
    id: id,
    number: 1,
    title: title,
    body: 'પંક્તિ એક\nપંક્તિ બે',
    lang: lang,
    categoryId: cat,
    isFavorite: true,
    wordCount: 4,
    searchBlob: '',
    createdAt: DateTime(2024, 11, 7),
    updatedAt: DateTime(2026, 11, 6),
    source: 'app',
    sourceKey: null,
    contentKey: null,
    deletedAt: null,
    kind: kind,
    isDraft: false,
  );
  final items = [
    poem('a', 'વરસાદની પહેલી સાંજ', Kind.poem, 'gu', 'jivan'),
    poem('b', 'ઘણું લાંબું શીર્ષક ધરાવતી કવિતા', Kind.poem, 'gu', 'desh'),
    poem('c', 'નિબંધ', Kind.prose, 'gu', 'jivan'),
  ];
  const cats = [
    PoemCategory(id: 'jivan', nameGu: 'જીવન મંથન અને વિચારોની વાતો', nameHi: 'जीवन मंथन', nameEn: 'Life', iconKey: 'jivan', sortOrder: 1),
    PoemCategory(id: 'desh', nameGu: 'દેશ પ્રેમ અને રાષ્ટ્ર ભક્તિ', nameHi: 'देश प्रेम', nameEn: 'Nation', iconKey: 'desh', sortOrder: 2),
    PoemCategory(id: 'hasya', nameGu: 'હાસ્ય', nameHi: 'हास्य', nameEn: 'Humour', iconKey: 'hasya', sortOrder: 3),
  ];
  const stats = PoemStats(total: 920, words: 1000, gu: 830, hi: 90, poems: 905, prose: 15, poemsGu: 816, poemsHi: 89, proseGu: 14, proseHi: 1);

  Future<void> pump(WidgetTester tester, Widget screen, {double scale = 1.3}) async {
    tester.view.physicalSize = const Size(360, 780) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          minuteProvider.overrideWith((ref) => Stream.value(DateTime(2026, 11, 7, 15, 40))),
          prefsProvider.overrideWith(() => PrefsNotifier(AppPrefs(textScale: scale))),
          statsProvider.overrideWith((ref) => Stream.value(stats)),
          recentProvider.overrideWith((ref) => Stream.value(items)),
          favoritesProvider.overrideWith((ref) => Stream.value(items)),
          poemsProvider.overrideWith((ref, q) => Stream.value(items.where((p) => q.kind == null || p.kind == q.kind).toList())),
          onThisDayProvider.overrideWith((ref) async => const <Poem>[]),
          duplicateCountProvider.overrideWith((ref) => Stream.value(0)),
          categoriesProvider.overrideWith((ref) => Stream.value(cats)),
        ],
        child: MaterialApp(
          theme: buildTheme(themeById('night')),
          builder: (context, child) => MediaQuery(
            // The phone's own font at its biggest, plus the largest app size.
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(appTextScale(1.5, scale))),
            child: child!,
          ),
          home: LangScope(
            lang: PoemLang.gu,
            child: Scaffold(body: screen),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('collection: poems / prose switch, language filter, topic names never overflow at the largest size', (tester) async {
    await pump(tester, const CollectionScreen());
    expect(tester.takeException(), isNull);
    expect(find.textContaining('${tr('kind_poem', PoemLang.gu)} · ૯૦૫'), findsOneWidget);
    expect(find.textContaining('${tr('kind_prose', PoemLang.gu)} · ૧૫'), findsOneWidget);
    expect(find.textContaining(tr('lang_all', PoemLang.gu)), findsOneWidget);
    // Only topics that hold poems: Humour has none.
    expect(find.text('હાસ્ય'), findsNothing);
    expect(find.text('દેશ પ્રેમ અને રાષ્ટ્ર ભક્તિ'), findsOneWidget);
    // Switch to prose.
    await tester.tap(find.textContaining('${tr('kind_prose', PoemLang.gu)} · ૧૫'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    expect(find.text('દેશ પ્રેમ અને રાષ્ટ્ર ભક્તિ'), findsNothing);
    expect(find.text('જીવન મંથન અને વિચારોની વાતો'), findsOneWidget);
  });

  testWidgets('home: counters for poems and prose open their lists; two recent poems; no overflow', (tester) async {
    await pump(tester, HomeScreen(onOpenCollection: () {}, onWrite: () {}));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('(${placeLabel(Place.ahmedabad, PoemLang.gu)})'), findsOneWidget, reason: 'Choghadiya shows its place');
    await tester.scrollUntilVisible(find.text('૯૦૫'), 200);
    expect(find.text('૯૦૫'), findsOneWidget);
    expect(find.text('૧૫'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('૯૦૫'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('૯૦૫'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(TopicPoemsScreen), findsOneWidget);
  });
}
