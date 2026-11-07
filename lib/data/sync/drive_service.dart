import 'dart:async';
import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'remote_store.dart';

/// Only files this app creates are visible to it (Google's "drive.file" scope):
/// the app never sees the rest of the poet's Drive.
const driveScope = 'https://www.googleapis.com/auth/drive.file';
const driveFolderName = 'GSV Poems Backups';

/// The *Web* OAuth client ID from Google Cloud (Credentials). Not a secret:
/// it only names the project. Can also be set in the app (Drive screen).
const defaultWebClientId = '307387375591-prjdev9fb0cd03ptkp8svcg37v68njg9.apps.googleusercontent.com';

class DriveNotSetUp implements Exception {
  @override
  String toString() => 'Google Drive is not set up yet (Web client ID missing).';
}

class _AuthClient extends http.BaseClient {
  _AuthClient(this._headers);
  final Map<String, String> _headers;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

/// Google sign-in and the "GSV Poems Backups" folder.
class DriveService implements RemoteStore {
  DriveService(this.webClientId);
  final String webClientId;

  static bool _initialised = false;
  GoogleSignInAccount? _account;
  drive.DriveApi? _api;
  String? _folderId;

  String? get email => _account?.email;

  Future<void> _init() async {
    if (webClientId.isEmpty) throw DriveNotSetUp();
    if (_initialised) return;
    await GoogleSignIn.instance.initialize(serverClientId: webClientId);
    _initialised = true;
  }

  /// Signs in again without showing anything (works after the first connect).
  Future<bool> signInQuietly() async {
    await _init();
    _account ??= await GoogleSignIn.instance.attemptLightweightAuthentication();
    return _account != null && await _authorize(prompt: false);
  }

  /// The one-time "Connect Google Drive" step: pick the account, allow access.
  Future<String> connect() async {
    await _init();
    _account = await GoogleSignIn.instance.authenticate(scopeHint: const [driveScope]);
    if (!await _authorize(prompt: true)) throw StateError('Drive access was not allowed');
    return _account!.email;
  }

  Future<void> disconnect() async {
    await _init();
    await GoogleSignIn.instance.disconnect();
    _account = null;
    _api = null;
    _folderId = null;
  }

  Future<bool> _authorize({required bool prompt}) async {
    final headers = await _account!.authorizationClient.authorizationHeaders(const [driveScope], promptIfNecessary: prompt);
    if (headers == null) return false;
    _api = drive.DriveApi(_AuthClient(headers));
    return true;
  }

  Future<drive.DriveApi> _ready() async {
    if (_api == null && !await signInQuietly()) throw StateError('Not connected to Google Drive');
    return _api!;
  }

  Future<String> _folder() async {
    if (_folderId != null) return _folderId!;
    final api = await _ready();
    final found = await api.files.list(
      q: "name = '$driveFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      spaces: 'drive',
      $fields: 'files(id)',
    );
    final existing = found.files ?? const [];
    if (existing.isNotEmpty) return _folderId = existing.first.id!;
    final made = await api.files.create(
      drive.File()
        ..name = driveFolderName
        ..mimeType = 'application/vnd.google-apps.folder',
      $fields: 'id',
    );
    return _folderId = made.id!;
  }

  @override
  Future<List<RemoteFile>> list() async {
    final api = await _ready();
    final folder = await _folder();
    final out = <RemoteFile>[];
    String? page;
    do {
      final r = await api.files.list(
        q: "'$folder' in parents and trashed = false",
        spaces: 'drive',
        pageToken: page,
        $fields: 'nextPageToken, files(id, name, modifiedTime)',
      );
      for (final f in r.files ?? const <drive.File>[]) {
        out.add(RemoteFile(f.id!, f.name ?? '', f.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0)));
      }
      page = r.nextPageToken;
    } while (page != null);
    return out;
  }

  @override
  Future<Uint8List> download(String id) async {
    final api = await _ready();
    final media = await api.files.get(id, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final b = BytesBuilder();
    await for (final chunk in media.stream) {
      b.add(chunk);
    }
    return b.toBytes();
  }

  @override
  Future<void> upload(String name, Uint8List bytes) async {
    final api = await _ready();
    final folder = await _folder();
    final media = drive.Media(Stream.value(bytes), bytes.length, contentType: 'application/octet-stream');
    final same = await api.files.list(q: "'$folder' in parents and name = '$name' and trashed = false", spaces: 'drive', $fields: 'files(id)');
    final hit = same.files ?? const [];
    if (hit.isNotEmpty) {
      await api.files.update(drive.File(), hit.first.id!, uploadMedia: media);
    } else {
      await api.files.create(
        drive.File()
          ..name = name
          ..parents = [folder],
        uploadMedia: media,
        $fields: 'id',
      );
    }
  }

  @override
  Future<void> delete(String id) async => (await _ready()).files.delete(id);
}
