import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../poem_repository.dart';
import 'seed_format.dart';

export 'seed_format.dart';

/// On launch any bundled poem not yet on the phone is added; poems already
/// there are never touched again.
/// Adds the bundled poems once per seed version. Returns how many were added
/// (0 when this seed was already loaded, or when the app has no seed).
Future<int> loadSeed(PoemRepository repo, Future<String> Function() readAsset) async {
  String json;
  try {
    json = await readAsset();
  } on Object {
    return 0;
  }
  final hash = sha1.convert(utf8.encode(json)).toString();
  if (await repo.getSetting('seedHash') == hash) return 0;
  final out = await repo.importPoems(decodeSeed(json));
  await repo.setSetting('seedHash', hash);
  return out.added;
}
