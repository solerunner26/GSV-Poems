// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PoemsTable extends Poems with TableInfo<$PoemsTable, Poem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PoemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('gu'),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
    'word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _searchBlobMeta = const VerificationMeta(
    'searchBlob',
  );
  @override
  late final GeneratedColumn<String> searchBlob = GeneratedColumn<String>(
    'search_blob',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('app'),
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentKeyMeta = const VerificationMeta(
    'contentKey',
  );
  @override
  late final GeneratedColumn<String> contentKey = GeneratedColumn<String>(
    'content_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    number,
    title,
    body,
    lang,
    categoryId,
    isFavorite,
    wordCount,
    searchBlob,
    createdAt,
    updatedAt,
    deletedAt,
    source,
    sourceKey,
    contentKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'poems';
  @override
  VerificationContext validateIntegrity(
    Insertable<Poem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    }
    if (data.containsKey('search_blob')) {
      context.handle(
        _searchBlobMeta,
        searchBlob.isAcceptableOrUnknown(data['search_blob']!, _searchBlobMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    }
    if (data.containsKey('content_key')) {
      context.handle(
        _contentKeyMeta,
        contentKey.isAcceptableOrUnknown(data['content_key']!, _contentKeyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Poem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Poem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_count'],
      )!,
      searchBlob: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_blob'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      ),
      contentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_key'],
      ),
    );
  }

  @override
  $PoemsTable createAlias(String alias) {
    return $PoemsTable(attachedDatabase, alias);
  }
}

class Poem extends DataClass implements Insertable<Poem> {
  final String id;
  final int? number;
  final String title;
  final String body;
  final String lang;
  final String? categoryId;
  final bool isFavorite;
  final int wordCount;
  final String searchBlob;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Null = live. A date = in the recycle bin since then.
  final DateTime? deletedAt;
  final String source;
  final String? sourceKey;

  /// Same text (ignoring spacing, punctuation and line breaks) → same key.
  final String? contentKey;
  const Poem({
    required this.id,
    this.number,
    required this.title,
    required this.body,
    required this.lang,
    this.categoryId,
    required this.isFavorite,
    required this.wordCount,
    required this.searchBlob,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.source,
    this.sourceKey,
    this.contentKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<int>(number);
    }
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['lang'] = Variable<String>(lang);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['word_count'] = Variable<int>(wordCount);
    map['search_blob'] = Variable<String>(searchBlob);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceKey != null) {
      map['source_key'] = Variable<String>(sourceKey);
    }
    if (!nullToAbsent || contentKey != null) {
      map['content_key'] = Variable<String>(contentKey);
    }
    return map;
  }

  PoemsCompanion toCompanion(bool nullToAbsent) {
    return PoemsCompanion(
      id: Value(id),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      title: Value(title),
      body: Value(body),
      lang: Value(lang),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      isFavorite: Value(isFavorite),
      wordCount: Value(wordCount),
      searchBlob: Value(searchBlob),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      source: Value(source),
      sourceKey: sourceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceKey),
      contentKey: contentKey == null && nullToAbsent
          ? const Value.absent()
          : Value(contentKey),
    );
  }

  factory Poem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Poem(
      id: serializer.fromJson<String>(json['id']),
      number: serializer.fromJson<int?>(json['number']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      lang: serializer.fromJson<String>(json['lang']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
      searchBlob: serializer.fromJson<String>(json['searchBlob']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      source: serializer.fromJson<String>(json['source']),
      sourceKey: serializer.fromJson<String?>(json['sourceKey']),
      contentKey: serializer.fromJson<String?>(json['contentKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'number': serializer.toJson<int?>(number),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'lang': serializer.toJson<String>(lang),
      'categoryId': serializer.toJson<String?>(categoryId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'wordCount': serializer.toJson<int>(wordCount),
      'searchBlob': serializer.toJson<String>(searchBlob),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'source': serializer.toJson<String>(source),
      'sourceKey': serializer.toJson<String?>(sourceKey),
      'contentKey': serializer.toJson<String?>(contentKey),
    };
  }

  Poem copyWith({
    String? id,
    Value<int?> number = const Value.absent(),
    String? title,
    String? body,
    String? lang,
    Value<String?> categoryId = const Value.absent(),
    bool? isFavorite,
    int? wordCount,
    String? searchBlob,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? source,
    Value<String?> sourceKey = const Value.absent(),
    Value<String?> contentKey = const Value.absent(),
  }) => Poem(
    id: id ?? this.id,
    number: number.present ? number.value : this.number,
    title: title ?? this.title,
    body: body ?? this.body,
    lang: lang ?? this.lang,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    isFavorite: isFavorite ?? this.isFavorite,
    wordCount: wordCount ?? this.wordCount,
    searchBlob: searchBlob ?? this.searchBlob,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    source: source ?? this.source,
    sourceKey: sourceKey.present ? sourceKey.value : this.sourceKey,
    contentKey: contentKey.present ? contentKey.value : this.contentKey,
  );
  Poem copyWithCompanion(PoemsCompanion data) {
    return Poem(
      id: data.id.present ? data.id.value : this.id,
      number: data.number.present ? data.number.value : this.number,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      lang: data.lang.present ? data.lang.value : this.lang,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      searchBlob: data.searchBlob.present
          ? data.searchBlob.value
          : this.searchBlob,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      source: data.source.present ? data.source.value : this.source,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      contentKey: data.contentKey.present
          ? data.contentKey.value
          : this.contentKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Poem(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('lang: $lang, ')
          ..write('categoryId: $categoryId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('wordCount: $wordCount, ')
          ..write('searchBlob: $searchBlob, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('source: $source, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('contentKey: $contentKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    number,
    title,
    body,
    lang,
    categoryId,
    isFavorite,
    wordCount,
    searchBlob,
    createdAt,
    updatedAt,
    deletedAt,
    source,
    sourceKey,
    contentKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Poem &&
          other.id == this.id &&
          other.number == this.number &&
          other.title == this.title &&
          other.body == this.body &&
          other.lang == this.lang &&
          other.categoryId == this.categoryId &&
          other.isFavorite == this.isFavorite &&
          other.wordCount == this.wordCount &&
          other.searchBlob == this.searchBlob &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.source == this.source &&
          other.sourceKey == this.sourceKey &&
          other.contentKey == this.contentKey);
}

class PoemsCompanion extends UpdateCompanion<Poem> {
  final Value<String> id;
  final Value<int?> number;
  final Value<String> title;
  final Value<String> body;
  final Value<String> lang;
  final Value<String?> categoryId;
  final Value<bool> isFavorite;
  final Value<int> wordCount;
  final Value<String> searchBlob;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> source;
  final Value<String?> sourceKey;
  final Value<String?> contentKey;
  final Value<int> rowid;
  const PoemsCompanion({
    this.id = const Value.absent(),
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.lang = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.searchBlob = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.contentKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PoemsCompanion.insert({
    required String id,
    this.number = const Value.absent(),
    this.title = const Value.absent(),
    required String body,
    this.lang = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.searchBlob = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.contentKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       body = Value(body),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Poem> custom({
    Expression<String>? id,
    Expression<int>? number,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? lang,
    Expression<String>? categoryId,
    Expression<bool>? isFavorite,
    Expression<int>? wordCount,
    Expression<String>? searchBlob,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? source,
    Expression<String>? sourceKey,
    Expression<String>? contentKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (number != null) 'number': number,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (lang != null) 'lang': lang,
      if (categoryId != null) 'category_id': categoryId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (wordCount != null) 'word_count': wordCount,
      if (searchBlob != null) 'search_blob': searchBlob,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (source != null) 'source': source,
      if (sourceKey != null) 'source_key': sourceKey,
      if (contentKey != null) 'content_key': contentKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PoemsCompanion copyWith({
    Value<String>? id,
    Value<int?>? number,
    Value<String>? title,
    Value<String>? body,
    Value<String>? lang,
    Value<String?>? categoryId,
    Value<bool>? isFavorite,
    Value<int>? wordCount,
    Value<String>? searchBlob,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? source,
    Value<String?>? sourceKey,
    Value<String?>? contentKey,
    Value<int>? rowid,
  }) {
    return PoemsCompanion(
      id: id ?? this.id,
      number: number ?? this.number,
      title: title ?? this.title,
      body: body ?? this.body,
      lang: lang ?? this.lang,
      categoryId: categoryId ?? this.categoryId,
      isFavorite: isFavorite ?? this.isFavorite,
      wordCount: wordCount ?? this.wordCount,
      searchBlob: searchBlob ?? this.searchBlob,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      source: source ?? this.source,
      sourceKey: sourceKey ?? this.sourceKey,
      contentKey: contentKey ?? this.contentKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (searchBlob.present) {
      map['search_blob'] = Variable<String>(searchBlob.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (contentKey.present) {
      map['content_key'] = Variable<String>(contentKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoemsCompanion(')
          ..write('id: $id, ')
          ..write('number: $number, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('lang: $lang, ')
          ..write('categoryId: $categoryId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('wordCount: $wordCount, ')
          ..write('searchBlob: $searchBlob, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('source: $source, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('contentKey: $contentKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PoemCategoriesTable extends PoemCategories
    with TableInfo<$PoemCategoriesTable, PoemCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PoemCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameGuMeta = const VerificationMeta('nameGu');
  @override
  late final GeneratedColumn<String> nameGu = GeneratedColumn<String>(
    'name_gu',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameHiMeta = const VerificationMeta('nameHi');
  @override
  late final GeneratedColumn<String> nameHi = GeneratedColumn<String>(
    'name_hi',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nameGu,
    nameHi,
    nameEn,
    iconKey,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'poem_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<PoemCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name_gu')) {
      context.handle(
        _nameGuMeta,
        nameGu.isAcceptableOrUnknown(data['name_gu']!, _nameGuMeta),
      );
    } else if (isInserting) {
      context.missing(_nameGuMeta);
    }
    if (data.containsKey('name_hi')) {
      context.handle(
        _nameHiMeta,
        nameHi.isAcceptableOrUnknown(data['name_hi']!, _nameHiMeta),
      );
    } else if (isInserting) {
      context.missing(_nameHiMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    } else if (isInserting) {
      context.missing(_nameEnMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PoemCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PoemCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nameGu: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_gu'],
      )!,
      nameHi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_hi'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $PoemCategoriesTable createAlias(String alias) {
    return $PoemCategoriesTable(attachedDatabase, alias);
  }
}

class PoemCategory extends DataClass implements Insertable<PoemCategory> {
  final String id;
  final String nameGu;
  final String nameHi;
  final String nameEn;
  final String iconKey;
  final int sortOrder;
  const PoemCategory({
    required this.id,
    required this.nameGu,
    required this.nameHi,
    required this.nameEn,
    required this.iconKey,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name_gu'] = Variable<String>(nameGu);
    map['name_hi'] = Variable<String>(nameHi);
    map['name_en'] = Variable<String>(nameEn);
    map['icon_key'] = Variable<String>(iconKey);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  PoemCategoriesCompanion toCompanion(bool nullToAbsent) {
    return PoemCategoriesCompanion(
      id: Value(id),
      nameGu: Value(nameGu),
      nameHi: Value(nameHi),
      nameEn: Value(nameEn),
      iconKey: Value(iconKey),
      sortOrder: Value(sortOrder),
    );
  }

  factory PoemCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PoemCategory(
      id: serializer.fromJson<String>(json['id']),
      nameGu: serializer.fromJson<String>(json['nameGu']),
      nameHi: serializer.fromJson<String>(json['nameHi']),
      nameEn: serializer.fromJson<String>(json['nameEn']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nameGu': serializer.toJson<String>(nameGu),
      'nameHi': serializer.toJson<String>(nameHi),
      'nameEn': serializer.toJson<String>(nameEn),
      'iconKey': serializer.toJson<String>(iconKey),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  PoemCategory copyWith({
    String? id,
    String? nameGu,
    String? nameHi,
    String? nameEn,
    String? iconKey,
    int? sortOrder,
  }) => PoemCategory(
    id: id ?? this.id,
    nameGu: nameGu ?? this.nameGu,
    nameHi: nameHi ?? this.nameHi,
    nameEn: nameEn ?? this.nameEn,
    iconKey: iconKey ?? this.iconKey,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  PoemCategory copyWithCompanion(PoemCategoriesCompanion data) {
    return PoemCategory(
      id: data.id.present ? data.id.value : this.id,
      nameGu: data.nameGu.present ? data.nameGu.value : this.nameGu,
      nameHi: data.nameHi.present ? data.nameHi.value : this.nameHi,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PoemCategory(')
          ..write('id: $id, ')
          ..write('nameGu: $nameGu, ')
          ..write('nameHi: $nameHi, ')
          ..write('nameEn: $nameEn, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nameGu, nameHi, nameEn, iconKey, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PoemCategory &&
          other.id == this.id &&
          other.nameGu == this.nameGu &&
          other.nameHi == this.nameHi &&
          other.nameEn == this.nameEn &&
          other.iconKey == this.iconKey &&
          other.sortOrder == this.sortOrder);
}

class PoemCategoriesCompanion extends UpdateCompanion<PoemCategory> {
  final Value<String> id;
  final Value<String> nameGu;
  final Value<String> nameHi;
  final Value<String> nameEn;
  final Value<String> iconKey;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const PoemCategoriesCompanion({
    this.id = const Value.absent(),
    this.nameGu = const Value.absent(),
    this.nameHi = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PoemCategoriesCompanion.insert({
    required String id,
    required String nameGu,
    required String nameHi,
    required String nameEn,
    required String iconKey,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nameGu = Value(nameGu),
       nameHi = Value(nameHi),
       nameEn = Value(nameEn),
       iconKey = Value(iconKey);
  static Insertable<PoemCategory> custom({
    Expression<String>? id,
    Expression<String>? nameGu,
    Expression<String>? nameHi,
    Expression<String>? nameEn,
    Expression<String>? iconKey,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nameGu != null) 'name_gu': nameGu,
      if (nameHi != null) 'name_hi': nameHi,
      if (nameEn != null) 'name_en': nameEn,
      if (iconKey != null) 'icon_key': iconKey,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PoemCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? nameGu,
    Value<String>? nameHi,
    Value<String>? nameEn,
    Value<String>? iconKey,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return PoemCategoriesCompanion(
      id: id ?? this.id,
      nameGu: nameGu ?? this.nameGu,
      nameHi: nameHi ?? this.nameHi,
      nameEn: nameEn ?? this.nameEn,
      iconKey: iconKey ?? this.iconKey,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nameGu.present) {
      map['name_gu'] = Variable<String>(nameGu.value);
    }
    if (nameHi.present) {
      map['name_hi'] = Variable<String>(nameHi.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoemCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('nameGu: $nameGu, ')
          ..write('nameHi: $nameHi, ')
          ..write('nameEn: $nameEn, ')
          ..write('iconKey: $iconKey, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PoemVersionsTable extends PoemVersions
    with TableInfo<$PoemVersionsTable, PoemVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PoemVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _poemIdMeta = const VerificationMeta('poemId');
  @override
  late final GeneratedColumn<String> poemId = GeneratedColumn<String>(
    'poem_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES poems (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, poemId, title, body, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'poem_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PoemVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('poem_id')) {
      context.handle(
        _poemIdMeta,
        poemId.isAcceptableOrUnknown(data['poem_id']!, _poemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_poemIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PoemVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PoemVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      poemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poem_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $PoemVersionsTable createAlias(String alias) {
    return $PoemVersionsTable(attachedDatabase, alias);
  }
}

class PoemVersion extends DataClass implements Insertable<PoemVersion> {
  final int id;
  final String poemId;
  final String title;
  final String body;
  final DateTime savedAt;
  const PoemVersion({
    required this.id,
    required this.poemId,
    required this.title,
    required this.body,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['poem_id'] = Variable<String>(poemId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  PoemVersionsCompanion toCompanion(bool nullToAbsent) {
    return PoemVersionsCompanion(
      id: Value(id),
      poemId: Value(poemId),
      title: Value(title),
      body: Value(body),
      savedAt: Value(savedAt),
    );
  }

  factory PoemVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PoemVersion(
      id: serializer.fromJson<int>(json['id']),
      poemId: serializer.fromJson<String>(json['poemId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'poemId': serializer.toJson<String>(poemId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  PoemVersion copyWith({
    int? id,
    String? poemId,
    String? title,
    String? body,
    DateTime? savedAt,
  }) => PoemVersion(
    id: id ?? this.id,
    poemId: poemId ?? this.poemId,
    title: title ?? this.title,
    body: body ?? this.body,
    savedAt: savedAt ?? this.savedAt,
  );
  PoemVersion copyWithCompanion(PoemVersionsCompanion data) {
    return PoemVersion(
      id: data.id.present ? data.id.value : this.id,
      poemId: data.poemId.present ? data.poemId.value : this.poemId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PoemVersion(')
          ..write('id: $id, ')
          ..write('poemId: $poemId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, poemId, title, body, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PoemVersion &&
          other.id == this.id &&
          other.poemId == this.poemId &&
          other.title == this.title &&
          other.body == this.body &&
          other.savedAt == this.savedAt);
}

class PoemVersionsCompanion extends UpdateCompanion<PoemVersion> {
  final Value<int> id;
  final Value<String> poemId;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> savedAt;
  const PoemVersionsCompanion({
    this.id = const Value.absent(),
    this.poemId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  PoemVersionsCompanion.insert({
    this.id = const Value.absent(),
    required String poemId,
    required String title,
    required String body,
    required DateTime savedAt,
  }) : poemId = Value(poemId),
       title = Value(title),
       body = Value(body),
       savedAt = Value(savedAt);
  static Insertable<PoemVersion> custom({
    Expression<int>? id,
    Expression<String>? poemId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? savedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (poemId != null) 'poem_id': poemId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  PoemVersionsCompanion copyWith({
    Value<int>? id,
    Value<String>? poemId,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? savedAt,
  }) {
    return PoemVersionsCompanion(
      id: id ?? this.id,
      poemId: poemId ?? this.poemId,
      title: title ?? this.title,
      body: body ?? this.body,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (poemId.present) {
      map['poem_id'] = Variable<String>(poemId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoemVersionsCompanion(')
          ..write('id: $id, ')
          ..write('poemId: $poemId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PoemsTable poems = $PoemsTable(this);
  late final $PoemCategoriesTable poemCategories = $PoemCategoriesTable(this);
  late final $PoemVersionsTable poemVersions = $PoemVersionsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    poems,
    poemCategories,
    poemVersions,
    appSettings,
  ];
}

typedef $$PoemsTableCreateCompanionBuilder = PoemsCompanion Function({
  required String id,
  Value<int?> number,
  Value<String> title,
  required String body,
  Value<String> lang,
  Value<String?> categoryId,
  Value<bool> isFavorite,
  Value<int> wordCount,
  Value<String> searchBlob,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> source,
  Value<String?> sourceKey,
  Value<String?> contentKey,
  Value<int> rowid,
});
typedef $$PoemsTableUpdateCompanionBuilder = PoemsCompanion Function({
  Value<String> id,
  Value<int?> number,
  Value<String> title,
  Value<String> body,
  Value<String> lang,
  Value<String?> categoryId,
  Value<bool> isFavorite,
  Value<int> wordCount,
  Value<String> searchBlob,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> source,
  Value<String?> sourceKey,
  Value<String?> contentKey,
  Value<int> rowid,
});

final class $$PoemsTableReferences
    extends BaseReferences<_$AppDatabase, $PoemsTable, Poem> {
  $$PoemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PoemVersionsTable, List<PoemVersion>>
  _poemVersionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.poemVersions,
    aliasName: 'poems__id__poem_versions__poem_id',
  );

  $$PoemVersionsTableProcessedTableManager get poemVersionsRefs {
    final manager = $$PoemVersionsTableTableManager(
      $_db,
      $_db.poemVersions,
    ).filter((f) => f.poemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_poemVersionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PoemsTableFilterComposer extends Composer<_$AppDatabase, $PoemsTable> {
  $$PoemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchBlob => $composableBuilder(
    column: $table.searchBlob,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentKey => $composableBuilder(
    column: $table.contentKey,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> poemVersionsRefs(
    Expression<bool> Function($$PoemVersionsTableFilterComposer f) f,
  ) {
    final $$PoemVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poemVersions,
      getReferencedColumn: (t) => t.poemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemVersionsTableFilterComposer(
            $db: $db,
            $table: $db.poemVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PoemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PoemsTable> {
  $$PoemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchBlob => $composableBuilder(
    column: $table.searchBlob,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentKey => $composableBuilder(
    column: $table.contentKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PoemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PoemsTable> {
  $$PoemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<String> get searchBlob => $composableBuilder(
    column: $table.searchBlob,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get contentKey => $composableBuilder(
    column: $table.contentKey,
    builder: (column) => column,
  );

  Expression<T> poemVersionsRefs<T extends Object>(
    Expression<T> Function($$PoemVersionsTableAnnotationComposer a) f,
  ) {
    final $$PoemVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poemVersions,
      getReferencedColumn: (t) => t.poemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.poemVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PoemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PoemsTable,
          Poem,
          $$PoemsTableFilterComposer,
          $$PoemsTableOrderingComposer,
          $$PoemsTableAnnotationComposer,
          $$PoemsTableCreateCompanionBuilder,
          $$PoemsTableUpdateCompanionBuilder,
          (Poem, $$PoemsTableReferences),
          Poem,
          PrefetchHooks Function({bool poemVersionsRefs})
        > {
  $$PoemsTableTableManager(_$AppDatabase db, $PoemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<String> searchBlob = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                Value<String?> contentKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoemsCompanion(
                id: id,
                number: number,
                title: title,
                body: body,
                lang: lang,
                categoryId: categoryId,
                isFavorite: isFavorite,
                wordCount: wordCount,
                searchBlob: searchBlob,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                source: source,
                sourceKey: sourceKey,
                contentKey: contentKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int?> number = const Value.absent(),
                Value<String> title = const Value.absent(),
                required String body,
                Value<String> lang = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<String> searchBlob = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                Value<String?> contentKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoemsCompanion.insert(
                id: id,
                number: number,
                title: title,
                body: body,
                lang: lang,
                categoryId: categoryId,
                isFavorite: isFavorite,
                wordCount: wordCount,
                searchBlob: searchBlob,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                source: source,
                sourceKey: sourceKey,
                contentKey: contentKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PoemsTable, Poem>(table),
                  $$PoemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({poemVersionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (poemVersionsRefs) db.poemVersions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (poemVersionsRefs)
                    await $_getPrefetchedDataByColumns<
                      Poem,
                      $PoemsTable,
                      PoemVersion,
                      $PoemVersionsTable
                    >(
                      currentTable: table,
                      referencedTable: $$PoemsTableReferences
                          ._poemVersionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$PoemsTableReferences(
                        db,
                        table,
                        p0,
                      ).poemVersionsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'poem_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PoemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PoemsTable,
      Poem,
      $$PoemsTableFilterComposer,
      $$PoemsTableOrderingComposer,
      $$PoemsTableAnnotationComposer,
      $$PoemsTableCreateCompanionBuilder,
      $$PoemsTableUpdateCompanionBuilder,
      (Poem, $$PoemsTableReferences),
      Poem,
      PrefetchHooks Function({bool poemVersionsRefs})
    >;
typedef $$PoemCategoriesTableCreateCompanionBuilder =
    PoemCategoriesCompanion Function({
      required String id,
      required String nameGu,
      required String nameHi,
      required String nameEn,
      required String iconKey,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$PoemCategoriesTableUpdateCompanionBuilder =
    PoemCategoriesCompanion Function({
      Value<String> id,
      Value<String> nameGu,
      Value<String> nameHi,
      Value<String> nameEn,
      Value<String> iconKey,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$PoemCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $PoemCategoriesTable> {
  $$PoemCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameGu => $composableBuilder(
    column: $table.nameGu,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameHi => $composableBuilder(
    column: $table.nameHi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PoemCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PoemCategoriesTable> {
  $$PoemCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameGu => $composableBuilder(
    column: $table.nameGu,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameHi => $composableBuilder(
    column: $table.nameHi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PoemCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PoemCategoriesTable> {
  $$PoemCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nameGu =>
      $composableBuilder(column: $table.nameGu, builder: (column) => column);

  GeneratedColumn<String> get nameHi =>
      $composableBuilder(column: $table.nameHi, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$PoemCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PoemCategoriesTable,
          PoemCategory,
          $$PoemCategoriesTableFilterComposer,
          $$PoemCategoriesTableOrderingComposer,
          $$PoemCategoriesTableAnnotationComposer,
          $$PoemCategoriesTableCreateCompanionBuilder,
          $$PoemCategoriesTableUpdateCompanionBuilder,
          (
            PoemCategory,
            BaseReferences<_$AppDatabase, $PoemCategoriesTable, PoemCategory>,
          ),
          PoemCategory,
          PrefetchHooks Function()
        > {
  $$PoemCategoriesTableTableManager(
    _$AppDatabase db,
    $PoemCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoemCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoemCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoemCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nameGu = const Value.absent(),
                Value<String> nameHi = const Value.absent(),
                Value<String> nameEn = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoemCategoriesCompanion(
                id: id,
                nameGu: nameGu,
                nameHi: nameHi,
                nameEn: nameEn,
                iconKey: iconKey,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nameGu,
                required String nameHi,
                required String nameEn,
                required String iconKey,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoemCategoriesCompanion.insert(
                id: id,
                nameGu: nameGu,
                nameHi: nameHi,
                nameEn: nameEn,
                iconKey: iconKey,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PoemCategoriesTable, PoemCategory>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PoemCategoriesTable,
                    PoemCategory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PoemCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PoemCategoriesTable,
      PoemCategory,
      $$PoemCategoriesTableFilterComposer,
      $$PoemCategoriesTableOrderingComposer,
      $$PoemCategoriesTableAnnotationComposer,
      $$PoemCategoriesTableCreateCompanionBuilder,
      $$PoemCategoriesTableUpdateCompanionBuilder,
      (
        PoemCategory,
        BaseReferences<_$AppDatabase, $PoemCategoriesTable, PoemCategory>,
      ),
      PoemCategory,
      PrefetchHooks Function()
    >;
typedef $$PoemVersionsTableCreateCompanionBuilder =
    PoemVersionsCompanion Function({
      Value<int> id,
      required String poemId,
      required String title,
      required String body,
      required DateTime savedAt,
    });
typedef $$PoemVersionsTableUpdateCompanionBuilder =
    PoemVersionsCompanion Function({
      Value<int> id,
      Value<String> poemId,
      Value<String> title,
      Value<String> body,
      Value<DateTime> savedAt,
    });

final class $$PoemVersionsTableReferences
    extends BaseReferences<_$AppDatabase, $PoemVersionsTable, PoemVersion> {
  $$PoemVersionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PoemsTable _poemIdTable(_$AppDatabase db) =>
      db.poems.createAlias('poem_versions__poem_id__poems__id');

  $$PoemsTableProcessedTableManager get poemId {
    final $_column = $_itemColumn<String>('poem_id')!;

    final manager = $$PoemsTableTableManager(
      $_db,
      $_db.poems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_poemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PoemVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $PoemVersionsTable> {
  $$PoemVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PoemsTableFilterComposer get poemId {
    final $$PoemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poemId,
      referencedTable: $db.poems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemsTableFilterComposer(
            $db: $db,
            $table: $db.poems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoemVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PoemVersionsTable> {
  $$PoemVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PoemsTableOrderingComposer get poemId {
    final $$PoemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poemId,
      referencedTable: $db.poems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemsTableOrderingComposer(
            $db: $db,
            $table: $db.poems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoemVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PoemVersionsTable> {
  $$PoemVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  $$PoemsTableAnnotationComposer get poemId {
    final $$PoemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poemId,
      referencedTable: $db.poems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoemsTableAnnotationComposer(
            $db: $db,
            $table: $db.poems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoemVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PoemVersionsTable,
          PoemVersion,
          $$PoemVersionsTableFilterComposer,
          $$PoemVersionsTableOrderingComposer,
          $$PoemVersionsTableAnnotationComposer,
          $$PoemVersionsTableCreateCompanionBuilder,
          $$PoemVersionsTableUpdateCompanionBuilder,
          (PoemVersion, $$PoemVersionsTableReferences),
          PoemVersion,
          PrefetchHooks Function({bool poemId})
        > {
  $$PoemVersionsTableTableManager(_$AppDatabase db, $PoemVersionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoemVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoemVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoemVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> poemId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
              }) => PoemVersionsCompanion(
                id: id,
                poemId: poemId,
                title: title,
                body: body,
                savedAt: savedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String poemId,
                required String title,
                required String body,
                required DateTime savedAt,
              }) => PoemVersionsCompanion.insert(
                id: id,
                poemId: poemId,
                title: title,
                body: body,
                savedAt: savedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PoemVersionsTable, PoemVersion>(table),
                  $$PoemVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({poemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (poemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.poemId,
                        referencedTable: $$PoemVersionsTableReferences
                            ._poemIdTable(db),
                        referencedColumn: $$PoemVersionsTableReferences
                            ._poemIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PoemVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PoemVersionsTable,
      PoemVersion,
      $$PoemVersionsTableFilterComposer,
      $$PoemVersionsTableOrderingComposer,
      $$PoemVersionsTableAnnotationComposer,
      $$PoemVersionsTableCreateCompanionBuilder,
      $$PoemVersionsTableUpdateCompanionBuilder,
      (PoemVersion, $$PoemVersionsTableReferences),
      PoemVersion,
      PrefetchHooks Function({bool poemId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PoemsTableTableManager get poems =>
      $$PoemsTableTableManager(_db, _db.poems);
  $$PoemCategoriesTableTableManager get poemCategories =>
      $$PoemCategoriesTableTableManager(_db, _db.poemCategories);
  $$PoemVersionsTableTableManager get poemVersions =>
      $$PoemVersionsTableTableManager(_db, _db.poemVersions);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
