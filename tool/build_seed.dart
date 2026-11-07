// Turns a folder of Google Keep .json notes into the app's bundled poems:
//   dart run tool/build_seed.dart <folder>  [assets/poems/seed.json]
// Poems are cleaned (title + stanzas only), split, given their collection
// from the note title, and written in a stable order.
import 'dart:io';

import 'package:gsv_poems/data/import/keep_parser.dart';
import 'package:gsv_poems/data/import/seed_format.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/build_seed.dart <folder with Keep .json files> [out.json]');
    exit(64);
  }
  final out = File(args.length > 1 ? args[1] : seedAsset);
  final files = <String, String>{
    for (final f in Directory(args.first).listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.json')))
      f.uri.pathSegments.last: f.readAsStringSync(),
  };
  final r = parseKeepTakeout(files);
  final poems = r.poems.where((p) => p.body.trim().isNotEmpty).toList()
    ..sort((a, b) => a.collection != b.collection
        ? a.collection.compareTo(b.collection)
        : (a.number ?? 0).compareTo(b.number ?? 0));
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(encodeSeed(poems));
  final byLang = <String, int>{};
  for (final p in poems) {
    byLang[p.lang.name] = (byLang[p.lang.name] ?? 0) + 1;
  }
  stdout.writeln('Wrote ${poems.length} poems in ${r.collections.length} collections to ${out.path} $byLang');
  final empty = r.poems.length - poems.length;
  if (empty > 0) stdout.writeln('Left out $empty entries with a title but no poem text.');
}
