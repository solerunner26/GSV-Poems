import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/text/text_tools.dart';
import 'data/db/database.dart';
import 'data/poem_repository.dart';
import 'data/security/pin_service.dart';

/// Replaced in main() with the opened database.
final dbProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('dbProvider must be overridden'));
final repoProvider = Provider<PoemRepository>((ref) => PoemRepository(ref.watch(dbProvider)));
final pinServiceProvider = Provider<PinService>((ref) => PinService(const SecureSecretStore()));

class AppPrefs {
  const AppPrefs({this.themeId = 'mor', this.lang = PoemLang.gu, this.textScale = 1.0, this.recentClearedAt});
  final String themeId;
  final PoemLang lang;
  final double textScale;
  final DateTime? recentClearedAt;

  AppPrefs copyWith({String? themeId, PoemLang? lang, double? textScale, DateTime? recentClearedAt}) => AppPrefs(
        themeId: themeId ?? this.themeId,
        lang: lang ?? this.lang,
        textScale: textScale ?? this.textScale,
        recentClearedAt: recentClearedAt ?? this.recentClearedAt,
      );

  static AppPrefs fromMap(Map<String, String> m) => AppPrefs(
        themeId: m['theme'] ?? 'mor',
        lang: langFromCode(m['lang'] ?? 'gu'),
        textScale: double.tryParse(m['textScale'] ?? '') ?? 1.0,
        recentClearedAt: DateTime.tryParse(m['recentClearedAt'] ?? ''),
      );
}

class PrefsNotifier extends Notifier<AppPrefs> {
  PrefsNotifier([this._initial = const AppPrefs()]);
  final AppPrefs _initial;

  @override
  AppPrefs build() => _initial;

  PoemRepository get _repo => ref.read(repoProvider);

  Future<void> setTheme(String id) async {
    state = state.copyWith(themeId: id);
    await _repo.setSetting('theme', id);
  }

  Future<void> setLang(PoemLang l) async {
    state = state.copyWith(lang: l);
    await _repo.setSetting('lang', l.name);
  }

  Future<void> setTextScale(double s) async {
    state = state.copyWith(textScale: s);
    await _repo.setSetting('textScale', '$s');
  }

  Future<void> clearRecent() async {
    final now = DateTime.now();
    state = state.copyWith(recentClearedAt: now);
    await _repo.setSetting('recentClearedAt', now.toIso8601String());
  }
}

final prefsProvider = NotifierProvider<PrefsNotifier, AppPrefs>(PrefsNotifier.new);

typedef PoemQuery = ({String? lang, String? categoryId, PoemSort sort});

final poemsProvider = StreamProvider.family<List<Poem>, PoemQuery>(
  (ref, q) => ref.watch(repoProvider).watchPoems(lang: q.lang, categoryId: q.categoryId, sort: q.sort),
);
final statsProvider = StreamProvider<PoemStats>((ref) => ref.watch(repoProvider).watchStats());
final favoritesProvider = StreamProvider<List<Poem>>((ref) => ref.watch(repoProvider).watchFavorites());
final binProvider = StreamProvider<List<Poem>>((ref) => ref.watch(repoProvider).watchRecycleBin());
final categoriesProvider = StreamProvider<List<PoemCategory>>((ref) => ref.watch(repoProvider).watchCategories());
final recentProvider = StreamProvider<List<Poem>>((ref) {
  final cleared = ref.watch(prefsProvider.select((p) => p.recentClearedAt));
  return ref.watch(repoProvider).watchRecent(clearedAt: cleared);
});
final poemProvider = StreamProvider.family<Poem?, String>((ref, id) => ref.watch(repoProvider).watchPoem(id));
final onThisDayProvider = FutureProvider<List<Poem>>((ref) => ref.watch(repoProvider).onThisDay());

/// Category name in the interface language.
String categoryName(PoemCategory c, PoemLang lang) => switch (lang) {
      PoemLang.gu => c.nameGu,
      PoemLang.hi => c.nameHi,
      PoemLang.en => c.nameEn,
    };
