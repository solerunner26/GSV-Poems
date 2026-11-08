// Adds a folder of Google Keep notes, one story or article per note, to the
// app's bundled writing as prose (replacing any prose added before):
//   dart run tool/add_prose_seed.dart <folder> [collection name]
import 'dart:io';

import 'package:gsv_poems/data/import/keep_parser.dart';
import 'package:gsv_poems/data/import/seed_format.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/add_prose_seed.dart <folder with Keep .json files> [collection]');
    exit(64);
  }
  final collection = args.length > 1 ? args[1] : 'વાર્તા અને લેખ';
  final files = <String, String>{
    for (final f in Directory(args.first).listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.json')))
      f.uri.pathSegments.last: f.readAsStringSync(),
  };
  final prose = parseProseNotes(files, collection: collection);
  final seed = File(seedAsset);
  final poems = decodeSeed(seed.readAsStringSync()).where((p) => p.kind != 'prose').toList();
  seed.writeAsStringSync(encodeSeed([...poems, ...prose]));
  stdout.writeln('Kept ${poems.length} poems, added ${prose.length} prose pieces to $seedAsset');
  for (final p in prose) {
    final first = p.body.split('\n').first;
    stdout.writeln('${p.number}. ${p.title}  |  ${first.length > 60 ? first.substring(0, 60) : first}  |  ${p.body.length} chars');
  }
}
