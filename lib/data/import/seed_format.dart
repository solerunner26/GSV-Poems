import 'dart:convert';

import '../../core/text/text_tools.dart';
import 'keep_parser.dart';

/// The poet's poems shipped inside the app, already cleaned and split by
/// tool/build_seed.dart. Plain Dart so the build tool can use it too.
const seedAsset = 'assets/poems/seed.json';

String encodeSeed(List<ImportedPoem> poems) => const JsonEncoder.withIndent(' ').convert({
      'format': 1,
      'poems': [
        for (final p in poems)
          {
            'key': p.sourceKey,
            'collection': p.collection,
            'number': p.number,
            'title': p.title,
            'body': p.body,
            'lang': p.lang.name,
            'created': p.createdAt.toIso8601String(),
            'updated': p.updatedAt.toIso8601String(),
          },
      ],
    });

List<ImportedPoem> decodeSeed(String json) {
  final m = jsonDecode(json) as Map<String, dynamic>;
  return [
    for (final e in (m['poems'] as List).cast<Map<String, dynamic>>())
      ImportedPoem(
        number: e['number'] as int?,
        title: e['title'] as String,
        body: e['body'] as String,
        lang: langFromCode(e['lang'] as String),
        createdAt: DateTime.parse(e['created'] as String),
        updatedAt: DateTime.parse(e['updated'] as String),
        collection: e['collection'] as String,
        sourceKey: e['key'] as String,
        fileName: seedAsset,
      ),
  ];
}

