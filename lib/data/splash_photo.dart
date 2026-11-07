import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The photo on the opening screen: the bundled photo of the poet, or one
/// chosen in Settings (kept as a private copy inside the app).
class SplashPhoto {
  SplashPhoto._();

  /// Path of the chosen photo, or null for the bundled one.
  static final ValueNotifier<String?> chosen = ValueNotifier(null);

  static Future<File> _file() async => File(p.join((await getApplicationDocumentsDirectory()).path, 'splash_photo.img'));

  /// Reads whether a photo was chosen. Called once at start-up.
  static Future<void> load() async {
    try {
      final f = await _file();
      chosen.value = await f.exists() ? f.path : null;
    } on Object {
      chosen.value = null;
    }
  }

  static Future<void> save(Uint8List bytes) async {
    final f = await _file();
    await f.writeAsBytes(bytes, flush: true);
    chosen.value = null; // forces listeners to refresh the image
    chosen.value = f.path;
  }

  static Future<void> reset() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
    chosen.value = null;
  }
}
