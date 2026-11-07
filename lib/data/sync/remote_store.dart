import 'dart:typed_data';

/// A backup file stored somewhere off the phone.
class RemoteFile {
  const RemoteFile(this.id, this.name, this.modified);
  final String id, name;
  final DateTime modified;
}

/// Where backups are shared between devices (Google Drive in the app; an
/// in-memory fake in tests).
abstract class RemoteStore {
  Future<List<RemoteFile>> list();
  Future<Uint8List> download(String id);

  /// Creates the file, or replaces the one with the same name.
  Future<void> upload(String name, Uint8List bytes);
  Future<void> delete(String id);
}
