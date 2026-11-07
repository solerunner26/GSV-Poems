import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/text/text_tools.dart';
import 'db/database.dart';
import 'import/keep_parser.dart';

enum PoemSort { newest, oldest, number, title }

class PoemStats {
  const PoemStats({this.total = 0, this.words = 0, this.gu = 0, this.hi = 0, this.en = 0, this.inBin = 0});
  final int total, words, gu, hi, en, inBin;
}

class RestoreOutcome {
  const RestoreOutcome(this.added, this.updated, this.unchanged);
  final int added, updated, unchanged;
}

class ImportOutcome {
  const ImportOutcome(this.added, this.alreadyThere, {this.duplicates = 0});
  final int added, alreadyThere;

  /// Poems whose text matches another poem — listed for review, never removed by themselves.
  final int duplicates;
}

/// Key used to spot the same poem twice, whatever its spacing, commas or line breaks.
/// Very short texts get no key, so two one-line drafts are not called duplicates.
String? contentKeyOf(String body) {
  final letters = lettersOnly(body);
  if (letters.runes.length < 20) return null;
  return sha1.convert(utf8.encode(letters)).toString();
}

/// All reads and writes of poems go through here.
class PoemRepository {
  PoemRepository(this.db, {DateTime Function()? clock}) : _now = clock ?? DateTime.now {
    AppDatabase.backfill = backfillKeys;
  }

  /// After a database upgrade: fill in duplicate keys for poems saved by older versions.
  static Future<void> backfillKeys(AppDatabase db) async {
    final rows = await db.select(db.poems).get();
    for (final p in rows) {
      await (db.update(db.poems)..where((x) => x.id.equals(p.id))).write(PoemsCompanion(contentKey: Value(contentKeyOf(p.body))));
    }
  }

  final AppDatabase db;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  // ---------- reading ----------

  Stream<List<Poem>> watchPoems({String? lang, String? categoryId, PoemSort sort = PoemSort.newest}) {
    final q = db.select(db.poems)..where((p) => p.deletedAt.isNull());
    if (lang != null) q.where((p) => p.lang.equals(lang));
    if (categoryId != null) q.where((p) => p.categoryId.equals(categoryId));
    q.orderBy([
      switch (sort) {
        PoemSort.newest => (p) => OrderingTerm.desc(p.createdAt),
        PoemSort.oldest => (p) => OrderingTerm.asc(p.createdAt),
        PoemSort.number => (p) => OrderingTerm.asc(p.number),
        PoemSort.title => (p) => OrderingTerm.asc(p.title),
      },
    ]);
    return q.watch();
  }

  Stream<List<Poem>> watchRecycleBin() =>
      (db.select(db.poems)
            ..where((p) => p.deletedAt.isNotNull())
            ..orderBy([(p) => OrderingTerm.desc(p.deletedAt)]))
          .watch();

  Stream<List<Poem>> watchFavorites() =>
      (db.select(db.poems)
            ..where((p) => p.deletedAt.isNull() & p.isFavorite.equals(true))
            ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
          .watch();

  /// Poems written or edited in the last 7 days, after [clearedAt] if the list was cleared.
  Stream<List<Poem>> watchRecent({DateTime? clearedAt}) {
    var since = _now().subtract(const Duration(days: 7));
    if (clearedAt != null && clearedAt.isAfter(since)) since = clearedAt;
    return (db.select(db.poems)
          ..where((p) => p.deletedAt.isNull() & p.updatedAt.isBiggerThanValue(since))
          ..orderBy([(p) => OrderingTerm.desc(p.updatedAt)]))
        .watch();
  }

  /// Poems written on today's day and month in earlier years.
  Future<List<Poem>> onThisDay() async {
    final now = _now();
    final all = await (db.select(db.poems)..where((p) => p.deletedAt.isNull())).get();
    return all
        .where((p) => p.createdAt.month == now.month && p.createdAt.day == now.day && p.createdAt.year < now.year)
        .toList();
  }

  Future<Poem?> getPoem(String id) => (db.select(db.poems)..where((p) => p.id.equals(id))).getSingleOrNull();

  Stream<Poem?> watchPoem(String id) =>
      (db.select(db.poems)..where((p) => p.id.equals(id))).watchSingleOrNull();

  Stream<PoemStats> watchStats() {
    final all = db.select(db.poems).watch();
    return all.map((rows) {
      var total = 0, words = 0, gu = 0, hi = 0, en = 0, bin = 0;
      for (final p in rows) {
        if (p.deletedAt != null) {
          bin++;
          continue;
        }
        total++;
        words += p.wordCount;
        switch (p.lang) {
          case 'hi':
            hi++;
          case 'en':
            en++;
          default:
            gu++;
        }
      }
      return PoemStats(total: total, words: words, gu: gu, hi: hi, en: en, inBin: bin);
    });
  }

  Stream<List<PoemCategory>> watchCategories() =>
      (db.select(db.poemCategories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)])).watch();

  Future<List<PoemVersion>> versions(String poemId) =>
      (db.select(db.poemVersions)
            ..where((v) => v.poemId.equals(poemId))
            ..orderBy([(v) => OrderingTerm.desc(v.savedAt)]))
          .get();

  /// Poems containing the query (at least 3 letters), in any script.
  Future<List<Poem>> search(String query, {String? lang}) async {
    final patterns = searchPatterns(query);
    if (patterns.isEmpty) return const [];
    String esc(String s) => s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
    final q = db.select(db.poems)
      ..where((p) {
        Expression<bool> any = const Constant(false);
        for (final pat in patterns) {
          any = any | p.searchBlob.like('%${esc(pat)}%', escapeChar: r'\');
        }
        return p.deletedAt.isNull() & any;
      });
    if (lang != null) q.where((p) => p.lang.equals(lang));
    q.orderBy([(p) => OrderingTerm.desc(p.updatedAt)]);
    return rankSearchResults(await q.get(), query);
  }

  /// Orders matches the way a reader expects: every poem whose title has the
  /// word comes first, then poems that have it only in their verses. Inside
  /// each group a whole word beats part of a longer word, and an earlier
  /// position beats a later one (so "પ્રેમ મિલન" comes before "પ્રકૃતિનો પ્રેમ").
  static List<Poem> rankSearchResults(List<Poem> poems, String query) {
    final patterns = searchPatterns(query);
    if (patterns.isEmpty) return poems;
    final raw = patterns.first;
    final folded = patterns.length > 1 ? patterns[1] : raw;

    // (whole word?, position) of the first match in [text], or null.
    (bool, int)? find(String text) {
      final t = text.toLowerCase();
      var i = t.indexOf(raw);
      var len = raw.length;
      var hay = t;
      if (i < 0) {
        hay = foldLatin(transliterate(t));
        i = hay.indexOf(folded);
        len = folded.length;
      }
      if (i < 0) return null;
      bool edge(int at) => at < 0 || at >= hay.length || RegExp(r'[\s\p{P}]', unicode: true).hasMatch(hay[at]);
      return (edge(i - 1) && edge(i + len), i);
    }

    final scored = <(int, int, int, int, Poem)>[];
    for (var k = 0; k < poems.length; k++) {
      final p = poems[k];
      final inTitle = find(p.title);
      final hit = inTitle ?? find(p.body);
      scored.add((
        inTitle != null ? 0 : 1,
        hit == null || hit.$1 ? 0 : 1,
        hit?.$2 ?? 1 << 30,
        k, // keeps the newest-first order among equals
        p,
      ));
    }
    scored.sort((a, b) {
      for (final c in [a.$1.compareTo(b.$1), a.$2.compareTo(b.$2), a.$3.compareTo(b.$3)]) {
        if (c != 0) return c;
      }
      return a.$4.compareTo(b.$4);
    });
    return [for (final s in scored) s.$5];
  }

  // ---------- writing ----------

  /// Next number inside a collection (each collection counts from 1, like the poet's notes).
  Future<int> _nextNumber(String? categoryId) async {
    final max = db.poems.number.max();
    final q = db.selectOnly(db.poems)..addColumns([max]);
    q.where(categoryId == null ? db.poems.categoryId.isNull() : db.poems.categoryId.equals(categoryId));
    final row = await q.getSingle();
    return (row.read(max) ?? 0) + 1;
  }

  static String _nameKey(String name) =>
      foldLatin(transliterate(name.trim())).replaceAll(RegExp(r'[^a-z0-9 ]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _iconFor(String key) {
    // Keys are in folded Latin (sh→s, aa→a). Most specific first:
    // "sangharshmay jivan" is struggle, "desh prem" is the nation.
    const map = {
      'sanghar': 'mountain', 'des ': 'desh', 'tahevar': 'diya', 'prer': 'spark', 'smrit': 'hourglass',
      'subhech': 'gift', 'jyot': 'flame', 'sagar': 'wave', 'prabhat': 'sunrise', 'manthan': 'swirl',
      'prakriti sang': 'tree', 'prakrit': 'prakruti', 'prakrut': 'prakruti', 'samaj': 'samaj', 'parivar': 'parivar',
      'bhakti': 'bhakti', 'bhajan': 'bhajan', 'gajal': 'ghazal', 'prem': 'prem', 'hasy': 'hasya', 'jivan': 'jivan',
    };
    for (final e in map.entries) {
      if (key.contains(e.key)) return e.value;
    }
    return 'lotus';
  }

  /// Finds the category with this name in either script, or creates it.
  /// "જીવન મંથન" and "जीवन मंथन" are the same collection.
  Future<String> ensureCategory(String name, {String? iconKey}) async {
    final key = _nameKey(name);
    // "અન્ય વિભાગ" / "अन्य" (other) belong in Others.
    if (key == 'any' || key.startsWith('any ') || key == 'others' || key == 'other') return 'other';
    final cats = await db.select(db.poemCategories).get();
    for (final c in cats) {
      if (_nameKey(c.nameGu) == key || _nameKey(c.nameHi) == key || _nameKey(c.nameEn) == key) return c.id;
    }
    final slug = key.isEmpty ? 'c${cats.length}' : key.replaceAll(' ', '_');
    var id = 'c_$slug';
    while (cats.any((c) => c.id == id)) {
      id = '${id}_';
    }
    // English name: readable transliteration ("Desh Prem", not the folded search key).
    final latin = transliterate(name.trim())
        .replaceAll('aa', 'a')
        .replaceAll('ii', 'i')
        .replaceAll('uu', 'u')
        .replaceAll(RegExp(r'[^a-z ]'), '');
    final title = latin.split(' ').where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    final order = cats.fold<int>(0, (m, c) => c.sortOrder > m ? c.sortOrder : m) + 1;
    await db.into(db.poemCategories).insert(PoemCategoriesCompanion.insert(
          id: id,
          nameGu: toScript(name.trim(), PoemLang.gu),
          nameHi: toScript(name.trim(), PoemLang.hi),
          nameEn: title.isEmpty ? name.trim() : title,
          iconKey: iconKey ?? _iconFor(key),
          sortOrder: Value(order),
        ));
    return id;
  }

  /// Creates a poem and returns its id.
  Future<String> createPoem({required String title, required String body, String? categoryId, String? lang}) async {
    final id = _uuid.v4();
    final now = _now();
    categoryId ??= 'other';
    await db.into(db.poems).insert(PoemsCompanion.insert(
          id: id,
          number: Value(await _nextNumber(categoryId)),
          title: Value(title.trim()),
          body: body,
          lang: Value(lang ?? detectLang('$title $body').name),
          categoryId: Value(categoryId),
          wordCount: Value(wordCount(body)),
          searchBlob: Value(buildSearchBlob(title, body)),
          contentKey: Value(contentKeyOf(body)),
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  /// Updates text and category. When [keepVersion] is set, the text as it was
  /// before is saved to the edit history first.
  Future<void> updatePoem(String id, {required String title, required String body, String? categoryId, bool keepVersion = false}) async {
    await db.transaction(() async {
      final old = await getPoem(id);
      if (old == null) return;
      final changed = old.title != title.trim() || old.body != body;
      if (keepVersion && changed) {
        await db.into(db.poemVersions).insert(
              PoemVersionsCompanion.insert(poemId: id, title: old.title, body: old.body, savedAt: old.updatedAt),
            );
      }
      await (db.update(db.poems)..where((p) => p.id.equals(id))).write(PoemsCompanion(
            title: Value(title.trim()),
            body: Value(body),
            lang: Value(detectLang('$title $body').name),
            categoryId: Value(categoryId ?? 'other'),
            wordCount: Value(wordCount(body)),
            searchBlob: Value(buildSearchBlob(title, body)),
            contentKey: Value(contentKeyOf(body)),
            updatedAt: changed || old.categoryId != categoryId ? Value(_now()) : const Value.absent(),
          ));
    });
  }

  Future<void> restoreVersion(PoemVersion v) async {
    final p = await getPoem(v.poemId);
    if (p == null) return;
    await updatePoem(p.id, title: v.title, body: v.body, categoryId: p.categoryId, keepVersion: true);
  }

  Future<void> setFavorite(String id, bool fav) =>
      (db.update(db.poems)..where((p) => p.id.equals(id))).write(PoemsCompanion(isFavorite: Value(fav)));

  /// Moves a poem to the recycle bin. Nothing is erased.
  /// Counts as an edit (updatedAt moves), so the other device follows when syncing.
  Future<void> moveToBin(String id) {
    final now = _now();
    return (db.update(db.poems)..where((p) => p.id.equals(id))).write(PoemsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
  }

  Future<void> restoreFromBin(String id) =>
      (db.update(db.poems)..where((p) => p.id.equals(id))).write(PoemsCompanion(deletedAt: const Value(null), updatedAt: Value(_now())));

  /// The only real delete. Only allowed for a poem already in the recycle bin.
  Future<void> deleteForever(String id) => db.transaction(() async {
        final p = await getPoem(id);
        if (p == null || p.deletedAt == null) return;
        await (db.delete(db.poemVersions)..where((v) => v.poemId.equals(id))).go();
        await (db.delete(db.poems)..where((x) => x.id.equals(id))).go();
      });

  // ---------- import ----------

  /// Adds imported poems, skipping any already imported (matched by sourceKey).
  /// Each poem goes into the collection named after its note.
  Future<ImportOutcome> importPoems(List<ImportedPoem> poems) async {
    var added = 0, skipped = 0;
    await db.transaction(() async {
      final existing = (await (db.selectOnly(db.poems)..addColumns([db.poems.sourceKey])).get())
          .map((r) => r.read(db.poems.sourceKey))
          .whereType<String>()
          .toSet();
      final catIds = <String, String>{};
      for (final p in poems) {
        if (existing.contains(p.sourceKey)) {
          skipped++;
          continue;
        }
        existing.add(p.sourceKey);
        final cat = catIds[p.collection] ??= await ensureCategory(p.collection);
        await db.into(db.poems).insert(PoemsCompanion.insert(
              id: _uuid.v4(),
              number: Value(p.number),
              title: Value(p.title),
              body: p.body,
              lang: Value(p.lang.name),
              categoryId: Value(cat),
              wordCount: Value(wordCount(p.body)),
              searchBlob: Value(buildSearchBlob(p.title, p.body)),
              contentKey: Value(contentKeyOf(p.body)),
              createdAt: p.createdAt,
              updatedAt: p.updatedAt,
              source: const Value('keep'),
              sourceKey: Value(p.sourceKey),
            ));
        added++;
      }
    });
    return ImportOutcome(added, skipped, duplicates: (await duplicateGroups()).fold(0, (n, g) => n + g.length - 1));
  }

  // ---------- duplicates ----------

  /// Live poems whose text matches [body] (spacing and punctuation ignored).
  Future<List<Poem>> findDuplicatesOf(String body, {String? excludeId}) async {
    final key = contentKeyOf(body);
    if (key == null) return const [];
    final q = db.select(db.poems)..where((p) => p.deletedAt.isNull() & p.contentKey.equals(key));
    if (excludeId != null) q.where((p) => p.id.equals(excludeId).not());
    return q.get();
  }

  /// Groups of live poems with the same text, oldest first in each group.
  Future<List<List<Poem>>> duplicateGroups() async {
    final rows = await (db.select(db.poems)
          ..where((p) => p.deletedAt.isNull() & p.contentKey.isNotNull())
          ..orderBy([(p) => OrderingTerm.asc(p.createdAt)]))
        .get();
    final byKey = <String, List<Poem>>{};
    for (final p in rows) {
      (byKey[p.contentKey!] ??= []).add(p);
    }
    return byKey.values.where((g) => g.length > 1).toList();
  }

  Stream<int> watchDuplicateCount() => db.select(db.poems).watch().asyncMap((_) async {
        final groups = await duplicateGroups();
        return groups.fold<int>(0, (n, g) => n + g.length - 1);
      });

  /// Keeps the first copy of a group and moves the others to the recycle bin
  /// (they can still be restored). Only runs when the poet asks.
  Future<int> removeDuplicates(List<Poem> group, {String? keepId}) async {
    final keep = keepId ?? group.first.id;
    var moved = 0;
    for (final p in group) {
      if (p.id == keep) continue;
      await moveToBin(p.id);
      moved++;
    }
    return moved;
  }

  // ---------- backup & restore ----------

  /// Settings that travel with a backup (never secrets: those live in secure storage).
  static const backupSettingKeys = {'theme', 'lang', 'textScale', 'placeName', 'placeLat', 'placeLon', 'seedHash', 'recentClearedAt'};

  /// Everything a backup holds: poems (also those in the recycle bin), edit history, collections, settings.
  Future<Map<String, dynamic>> exportBackup() async {
    final poems = await db.select(db.poems).get();
    final cats = await db.select(db.poemCategories).get();
    final versions = await db.select(db.poemVersions).get();
    final settings = await allSettings();
    return {
      'format': 1,
      'poems': [for (final p in poems) p.toJson()],
      'categories': [for (final c in cats) c.toJson()],
      'versions': [for (final v in versions) (v.toJson()..remove('id'))],
      'settings': {for (final e in settings.entries) if (backupSettingKeys.contains(e.key)) e.key: e.value},
    };
  }

  /// Brings a backup back without ever duplicating or erasing a poem.
  ///
  /// A poem in the backup is matched to one on the phone by its id, else by the
  /// bundled-poem key, else by identical text. When both exist the newer edit
  /// wins and the other text is kept in edit history. A poem deleted in the
  /// backup only goes to the recycle bin here. With [replaceAll] the phone's
  /// poems are first cleared (the poet confirms this twice in the app).
  Future<RestoreOutcome> restoreBackup(Map<String, dynamic> data, {bool replaceAll = false, bool applySettings = true}) async {
    var added = 0, updated = 0, same = 0;
    await db.transaction(() async {
      if (replaceAll) {
        await db.delete(db.poemVersions).go();
        await db.delete(db.poems).go();
      }
      for (final m in (data['categories'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        final c = PoemCategory.fromJson(m);
        await db.into(db.poemCategories).insertOnConflictUpdate(c);
      }
      final local = await db.select(db.poems).get();
      final byId = {for (final p in local) p.id: p};
      final bySource = {for (final p in local) if (p.sourceKey != null) p.sourceKey!: p};
      final byContent = {for (final p in local) if (p.contentKey != null) p.contentKey!: p};
      final idMap = <String, String>{};
      for (final m in (data['poems'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        var b = Poem.fromJson(m);
        b = b.copyWith(contentKey: Value(b.contentKey ?? contentKeyOf(b.body)));
        final mine = byId[b.id] ?? (b.sourceKey == null ? null : bySource[b.sourceKey]) ?? (b.contentKey == null ? null : byContent[b.contentKey]);
        if (mine == null) {
          await db.into(db.poems).insert(b);
          idMap[b.id] = b.id;
          added++;
          continue;
        }
        idMap[b.id] = mine.id;
        if (!b.updatedAt.isAfter(mine.updatedAt)) {
          // The phone's copy is the same age or newer: keep it. The other
          // text is not thrown away: it goes into this poem's edit history.
          if ((b.body != mine.body || b.title != mine.title) && b.updatedAt.isBefore(mine.updatedAt)) {
            final already = await (db.select(db.poemVersions)
                  ..where((v) => v.poemId.equals(mine.id) & v.savedAt.equals(b.updatedAt)))
                .get();
            if (already.isEmpty) {
              await db.into(db.poemVersions).insert(
                    PoemVersionsCompanion.insert(poemId: mine.id, title: b.title, body: b.body, savedAt: b.updatedAt),
                  );
            }
          }
          // A deletion or a favourite mark made elsewhere still counts.
          final binIt = b.deletedAt != null && mine.deletedAt == null && b.deletedAt!.isAfter(mine.updatedAt);
          if (binIt || (b.isFavorite && !mine.isFavorite)) {
            await (db.update(db.poems)..where((x) => x.id.equals(mine.id))).write(PoemsCompanion(
                  deletedAt: binIt ? Value(b.deletedAt) : const Value.absent(),
                  isFavorite: b.isFavorite ? const Value(true) : const Value.absent(),
                ));
            updated++;
          } else {
            same++;
          }
          continue;
        }
        if (mine.body != b.body || mine.title != b.title) {
          await db.into(db.poemVersions).insert(
                PoemVersionsCompanion.insert(poemId: mine.id, title: mine.title, body: mine.body, savedAt: mine.updatedAt),
              );
        }
        await (db.update(db.poems)..where((x) => x.id.equals(mine.id))).write(PoemsCompanion(
              number: Value(b.number),
              title: Value(b.title),
              body: Value(b.body),
              lang: Value(b.lang),
              categoryId: Value(b.categoryId),
              isFavorite: Value(b.isFavorite || mine.isFavorite),
              wordCount: Value(b.wordCount),
              searchBlob: Value(buildSearchBlob(b.title, b.body)),
              contentKey: Value(contentKeyOf(b.body)),
              updatedAt: Value(b.updatedAt),
              deletedAt: Value(b.deletedAt),
              sourceKey: Value(mine.sourceKey ?? b.sourceKey),
            ));
        updated++;
      }
      // Edit history: add what is missing (same poem + same time = already there).
      final have = {for (final v in await db.select(db.poemVersions).get()) '${v.poemId}|${v.savedAt.millisecondsSinceEpoch}'};
      for (final m in (data['versions'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        final poemId = idMap[m['poemId']];
        if (poemId == null) continue;
        final saved = DateTime.fromMillisecondsSinceEpoch((m['savedAt'] as num).toInt());
        if (!have.add('$poemId|${saved.millisecondsSinceEpoch}')) continue;
        await db.into(db.poemVersions).insert(
              PoemVersionsCompanion.insert(poemId: poemId, title: '${m['title'] ?? ''}', body: '${m['body'] ?? ''}', savedAt: saved),
            );
      }
      // Syncing with another device keeps this device's own theme, language and place.
      final settings = applySettings ? (data['settings'] as Map?)?.cast<String, dynamic>() ?? const {} : const <String, dynamic>{};
      for (final e in settings.entries) {
        if (backupSettingKeys.contains(e.key)) await setSetting(e.key, '${e.value}');
      }
    });
    return RestoreOutcome(added, updated, same);
  }

  // ---------- settings ----------

  Future<String?> getSetting(String key) async =>
      (await (db.select(db.appSettings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setSetting(String key, String value) =>
      db.into(db.appSettings).insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));

  Future<Map<String, String>> allSettings() async =>
      {for (final s in await db.select(db.appSettings).get()) s.key: s.value};
}
