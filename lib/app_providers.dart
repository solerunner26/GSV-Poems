import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/panchang/festivals.dart';
import 'core/panchang/panchang.dart';
import 'core/text/text_tools.dart';
import 'data/db/database.dart';
import 'data/poem_repository.dart';
import 'data/security/pin_service.dart';

/// Replaced in main() with the opened database.
final dbProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('dbProvider must be overridden'));
final repoProvider = Provider<PoemRepository>((ref) => PoemRepository(ref.watch(dbProvider)));
final pinServiceProvider = Provider<PinService>((ref) => PinService(const SecureSecretStore()));

class AppPrefs {
  const AppPrefs({
    this.themeId = 'mor',
    this.lang = PoemLang.gu,
    this.textScale = 1.0,
    this.recentClearedAt,
    this.place = Place.ahmedabad,
    this.placeChosen = false,
  });
  final String themeId;
  final PoemLang lang;
  final double textScale;
  final DateTime? recentClearedAt;

  /// Where sunrise, tithi and Choghadiya are worked out for.
  final Place place;

  /// False until the poet picked GPS or a city (until then Ahmedabad is used).
  final bool placeChosen;

  AppPrefs copyWith({String? themeId, PoemLang? lang, double? textScale, DateTime? recentClearedAt, Place? place, bool? placeChosen}) => AppPrefs(
    themeId: themeId ?? this.themeId,
    lang: lang ?? this.lang,
    textScale: textScale ?? this.textScale,
    recentClearedAt: recentClearedAt ?? this.recentClearedAt,
    place: place ?? this.place,
    placeChosen: placeChosen ?? this.placeChosen,
  );

  static AppPrefs fromMap(Map<String, String> m) {
    final lat = double.tryParse(m['placeLat'] ?? ''), lon = double.tryParse(m['placeLon'] ?? '');
    return AppPrefs(
      themeId: m['theme'] ?? 'mor',
      lang: langFromCode(m['lang'] ?? 'gu'),
      textScale: double.tryParse(m['textScale'] ?? '') ?? 1.0,
      recentClearedAt: DateTime.tryParse(m['recentClearedAt'] ?? ''),
      place: lat == null || lon == null ? Place.ahmedabad : Place(m['placeName'] ?? 'GPS', lat, lon),
      placeChosen: lat != null,
    );
  }
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

  Future<void> setPlace(Place p) async {
    state = state.copyWith(place: p, placeChosen: true);
    await _repo.setSetting('placeName', p.name);
    await _repo.setSetting('placeLat', '${p.lat}');
    await _repo.setSetting('placeLon', '${p.lon}');
  }

  Future<void> clearRecent() async {
    final now = DateTime.now();
    state = state.copyWith(recentClearedAt: now);
    await _repo.setSetting('recentClearedAt', now.toIso8601String());
  }
}

final prefsProvider = NotifierProvider<PrefsNotifier, AppPrefs>(PrefsNotifier.new);

/// The text size the app uses: the phone's own setting, kept within a range
/// the layouts are built for (very large system sizes no longer cut labels
/// off), times the size chosen in Settings.
double appTextScale(double system, double chosen) => system.clamp(0.85, 1.1) * chosen;

/// Text sizes offered in Settings, smallest first, with their label keys.
const textSizes = [(0.8, 'size_xs'), (0.9, 'size_s'), (1.0, 'size_m'), (1.15, 'size_l'), (1.3, 'size_xl')];

typedef PoemQuery = ({String? lang, String? categoryId, String? kind, PoemSort sort});

final poemsProvider = StreamProvider.family<List<Poem>, PoemQuery>(
  (ref, q) => ref.watch(repoProvider).watchPoems(lang: q.lang, categoryId: q.categoryId, kind: q.kind, sort: q.sort),
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
final duplicateCountProvider = StreamProvider<int>((ref) => ref.watch(repoProvider).watchDuplicateCount());
final onThisDayProvider = FutureProvider<List<Poem>>((ref) => ref.watch(repoProvider).onThisDay());

/// Ticks every minute so "now" (current Choghadiya, today's date) stays fresh.
final minuteProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

/// Today's Panchang at the chosen place (changes at midnight).
final todayPanchangProvider = Provider<PanchangDay>((ref) {
  final now = ref.watch(minuteProvider).asData?.value ?? DateTime.now();
  final place = ref.watch(prefsProvider.select((p) => p.place));
  return panchangFor(now, place);
});

/// Festivals and vrat days for the next 45 days.
final upcomingFestivalsProvider = Provider<List<({DateTime date, Festival festival})>>((ref) {
  final today = ref.watch(todayPanchangProvider).date;
  final place = ref.watch(prefsProvider.select((p) => p.place));
  return upcoming(today, place, days: 45);
});

/// Category name in the interface language.
String categoryName(PoemCategory c, PoemLang lang) => switch (lang) {
  PoemLang.gu => c.nameGu,
  PoemLang.hi => c.nameHi,
  PoemLang.en => c.nameEn,
};
