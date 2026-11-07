import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Where new versions are published. Releases on this repo must stay public
/// for the phone to download them without a password.
const updateRepo = 'solerunner26/GSV-Poems';

class ReleaseInfo {
  const ReleaseInfo({required this.tag, required this.name, required this.notes, required this.build, required this.apkUrl, required this.apkSize});
  final String tag, name, notes, apkUrl;
  final int build, apkSize;
}

/// Build number from an APK name like "gsv-poems-v1.1.0-beta.1-build2.apk" or a tag "v1.1.0+2".
int? buildNumberFrom(String s) {
  final m = RegExp(r'build[-_]?(\d+)', caseSensitive: false).firstMatch(s) ?? RegExp(r'\+(\d+)$').firstMatch(s);
  return m == null ? null : int.tryParse(m[1]!);
}

/// The newest published (non-draft) release that carries an APK. Betas count.
ReleaseInfo? pickLatest(List<dynamic> releases) {
  ReleaseInfo? best;
  for (final r in releases.whereType<Map<String, dynamic>>()) {
    if (r['draft'] == true) continue;
    for (final a in (r['assets'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
      final name = '${a['name'] ?? ''}';
      if (!name.toLowerCase().endsWith('.apk')) continue;
      final build = buildNumberFrom(name) ?? buildNumberFrom('${r['tag_name'] ?? ''}');
      if (build == null) continue;
      if (best == null || build > best.build) {
        best = ReleaseInfo(
          tag: '${r['tag_name'] ?? ''}',
          name: '${r['name'] ?? r['tag_name'] ?? ''}',
          notes: '${r['body'] ?? ''}',
          build: build,
          apkUrl: '${a['browser_download_url']}',
          apkSize: (a['size'] as num?)?.toInt() ?? 0,
        );
      }
    }
  }
  return best;
}

class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// A newer release than [currentBuild], or null (also null when offline).
  Future<ReleaseInfo?> check(int currentBuild) async {
    try {
      final res = await _client
          .get(Uri.parse('https://api.github.com/repos/$updateRepo/releases?per_page=10'),
              headers: {'Accept': 'application/vnd.github+json', 'User-Agent': 'GSV-Poems-App'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final latest = pickLatest(jsonDecode(res.body) as List<dynamic>);
      return latest != null && latest.build > currentBuild ? latest : null;
    } on Object {
      return null;
    }
  }

  /// Downloads the APK to the app's cache and returns its path.
  Future<String> download(ReleaseInfo r, void Function(double progress) onProgress) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/gsv-poems-update.apk');
    final res = await _client.send(http.Request('GET', Uri.parse(r.apkUrl)));
    if (res.statusCode != 200) throw HttpException('Download failed (${res.statusCode})');
    final total = res.contentLength ?? r.apkSize;
    final sink = file.openWrite();
    var got = 0;
    await for (final chunk in res.stream) {
      sink.add(chunk);
      got += chunk.length;
      if (total > 0) onProgress(got / total);
    }
    await sink.close();
    return file.path;
  }
}
