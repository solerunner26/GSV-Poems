import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Every poem. `id` is a permanent UUID and is the key used for sync and backup.
class Poems extends Table {
  TextColumn get id => text()();
  IntColumn get number => integer().nullable()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text()();
  TextColumn get lang => text().withDefault(const Constant('gu'))();
  TextColumn get categoryId => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get wordCount => integer().withDefault(const Constant(0))();
  TextColumn get searchBlob => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Null = live. A date = in the recycle bin since then.
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get source => text().withDefault(const Constant('app'))();
  TextColumn get sourceKey => text().nullable()();

  /// Same text (ignoring spacing, punctuation and line breaks) → same key.
  TextColumn get contentKey => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PoemCategory')
class PoemCategories extends Table {
  TextColumn get id => text()();
  TextColumn get nameGu => text()();
  TextColumn get nameHi => text()();
  TextColumn get nameEn => text()();
  TextColumn get iconKey => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Earlier text of a poem, kept every time it is changed.
class PoemVersions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get poemId => text().references(Poems, #id)();
  TextColumn get title => text()();
  TextColumn get body => text()();
  DateTimeColumn get savedAt => dateTime()();
}

@DataClassName('AppSetting')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

const defaultCategories = <(String, String, String, String, String)>[
  ('bhakti', 'ભક્તિ', 'भक्ति', 'Devotion', 'bhakti'),
  ('prem', 'પ્રેમ', 'प्रेम', 'Love', 'prem'),
  ('prakruti', 'પ્રકૃતિ', 'प्रकृति', 'Nature', 'prakruti'),
  ('desh', 'દેશ', 'देश', 'Nation', 'desh'),
  ('jivan', 'જીવન', 'जीवन', 'Life', 'jivan'),
  ('parivar', 'પરિવાર', 'परिवार', 'Family', 'parivar'),
  ('ghazal', 'ગઝલ', 'ग़ज़ल', 'Ghazal', 'ghazal'),
  ('bhajan', 'ભજન', 'भजन', 'Bhajan', 'bhajan'),
  ('hasya', 'હાસ્ય', 'हास्य', 'Humour', 'hasya'),
  ('other', 'અન્ય', 'अन्य', 'Others', 'other'),
];

@DriftDatabase(tables: [Poems, PoemCategories, PoemVersions, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'gsv_poems'));

  /// Filled in by the repository: recomputes derived columns after an upgrade.
  static Future<void> Function(AppDatabase db)? backfill;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: duplicate detection key, and "Others" as the home for uncategorised poems.
        await m.addColumn(poems, poems.contentKey);
        await customStatement('CREATE INDEX poems_content_key ON poems (content_key)');
        await customStatement("UPDATE poem_categories SET name_gu = 'અન્ય', name_hi = 'अन्य', name_en = 'Others' WHERE id = 'other'");
        await customStatement("UPDATE poems SET category_id = 'other' WHERE category_id IS NULL");
        await backfill?.call(this);
      }
    },
    onCreate: (m) async {
      await m.createAll();
      await customStatement('CREATE INDEX poems_updated ON poems (updated_at)');
      await customStatement('CREATE UNIQUE INDEX poems_source_key ON poems (source_key)');
      await customStatement('CREATE INDEX poems_content_key ON poems (content_key)');
      await batch((b) {
        for (var i = 0; i < defaultCategories.length; i++) {
          final c = defaultCategories[i];
          b.insert(
            poemCategories,
            PoemCategoriesCompanion.insert(id: c.$1, nameGu: c.$2, nameHi: c.$3, nameEn: c.$4, iconKey: c.$5, sortOrder: Value(i)),
          );
        }
      });
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
