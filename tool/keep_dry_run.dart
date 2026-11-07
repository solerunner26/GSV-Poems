// Checks a folder of Google Keep .json files without importing anything:
//   dart run tool/keep_dry_run.dart <folder>
// Prints, per note, the collection name, poems found and any problems.
import 'dart:io';

import 'package:gsv_poems/data/import/keep_parser.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/keep_dry_run.dart <folder with Keep .json files>');
    exit(64);
  }
  final dir = Directory(args.first);
  final files = <String, String>{
    for (final f in dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.json')))
      f.uri.pathSegments.last: f.readAsStringSync(),
  };
  final r = parseKeepTakeout(files);
  for (final n in r.notes) {
    final miss = n.missing.isEmpty ? '' : '  MISSING ${n.missing}';
    stdout.writeln('${n.poems.toString().padLeft(3)} poems  (contents lists ${n.listed})  [${n.collection}]  ${n.fileName}$miss');
  }
  stdout.writeln('\nTotal ${r.poems.length} poems in ${r.collections.length} collections: ${r.collections.join(' | ')}');
  if (r.skippedNotes.isNotEmpty) stdout.writeln('Skipped files: ${r.skippedNotes}');
  for (final p in r.problems) {
    stdout.writeln('PROBLEM #${p.number} "${p.title}" (${p.fileName}): ${p.problem}');
  }
  final dated = r.poems.where((p) => p.createdAt.hour == 12).length;
  stdout.writeln('Poems with a written date found under them: $dated');
  final langs = <String, int>{};
  for (final p in r.poems) {
    langs[p.lang.name] = (langs[p.lang.name] ?? 0) + 1;
  }
  stdout.writeln('Languages: $langs');
}
