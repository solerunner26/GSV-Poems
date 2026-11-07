/// The .gsvbak backup file: everything needed to bring the collection back,
/// compressed and encrypted (AES-256-GCM) with a key made from the recovery key.
///
/// Layout: the line `GSVBAK1`, one line of plain JSON header (date, poem count,
/// key-derivation salt and nonce — nothing secret), then the encrypted bytes.
/// Without the recovery key the poems cannot be read.
library;

import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

const _magic = 'GSVBAK1';
const backupExtension = 'gsvbak';
const pbkdf2Iterations = 120000;

class BackupHeader {
  const BackupHeader({
    required this.created,
    required this.poems,
    required this.salt,
    required this.nonce,
    required this.iterations,
    this.device = '',
  });
  final DateTime created;
  final int poems;
  final List<int> salt, nonce;
  final int iterations;
  final String device;

  Map<String, dynamic> toJson() => {
    'app': 'gsv-poems',
    'format': 1,
    'created': created.toUtc().toIso8601String(),
    'poems': poems,
    'device': device,
    'kdf': 'pbkdf2-hmac-sha256',
    'iterations': iterations,
    'salt': base64Encode(salt),
    'cipher': 'aes-256-gcm',
    'nonce': base64Encode(nonce),
  };

  static BackupHeader fromJson(Map<String, dynamic> m) => BackupHeader(
    created: DateTime.parse(m['created'] as String).toLocal(),
    poems: (m['poems'] as num?)?.toInt() ?? 0,
    salt: base64Decode(m['salt'] as String),
    nonce: base64Decode(m['nonce'] as String),
    iterations: (m['iterations'] as num?)?.toInt() ?? pbkdf2Iterations,
    device: '${m['device'] ?? ''}',
  );
}

class BackupFormatException implements Exception {
  BackupFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thrown when the recovery key does not open the backup.
class WrongKeyException implements Exception {}

// ---------- recovery key ----------

const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; // Crockford base32: no I, L, O, U

/// A new random recovery key: 25 letters/digits in 5 groups, e.g. "7K2QM-…".
String newRecoveryKey([Random? rnd]) {
  final r = rnd ?? Random.secure();
  final chars = List.generate(25, (_) => _alphabet[r.nextInt(32)]);
  return [for (var i = 0; i < 25; i += 5) chars.sublist(i, i + 5).join()].join('-');
}

/// Accepts the key typed in any case, with or without dashes/spaces, and with
/// the easily confused O/I/L typed instead of 0/1/1.
String normalizeRecoveryKey(String typed) {
  final s = typed.toUpperCase().replaceAll(RegExp(r'[\s\-–_.]'), '').replaceAll('O', '0').replaceAll(RegExp('[IL]'), '1');
  return s;
}

bool looksLikeRecoveryKey(String typed) {
  final n = normalizeRecoveryKey(typed);
  return n.length == 25 && n.split('').every(_alphabet.contains);
}

Future<SecretKey> _deriveKey(String recoveryKey, List<int> salt, int iterations) => Pbkdf2(
  macAlgorithm: Hmac.sha256(),
  iterations: iterations,
  bits: 256,
).deriveKeyFromPassword(password: normalizeRecoveryKey(recoveryKey), nonce: salt);

List<int> _random(int n) {
  final r = Random.secure();
  return List<int>.generate(n, (_) => r.nextInt(256));
}

/// Builds the backup file bytes from the backup contents (a JSON-able map).
Future<Uint8List> encodeBackup(Map<String, dynamic> contents, String recoveryKey, {int iterations = pbkdf2Iterations, String device = ''}) async {
  final salt = _random(16), nonce = _random(12);
  final header = BackupHeader(
    created: DateTime.now(),
    poems: (contents['poems'] as List?)?.length ?? 0,
    salt: salt,
    nonce: nonce,
    iterations: iterations,
    device: device,
  );
  final plain = gzip.encode(utf8.encode(jsonEncode(contents)));
  final key = await _deriveKey(recoveryKey, salt, iterations);
  final box = await AesGcm.with256bits().encrypt(plain, secretKey: key, nonce: nonce);
  final head = utf8.encode('$_magic\n${jsonEncode(header.toJson())}\n');
  return Uint8List.fromList([...head, ...box.cipherText, ...box.mac.bytes]);
}

/// Reads only the plain header (date and poem count) — no key needed.
BackupHeader readBackupHeader(Uint8List bytes) => _split(bytes).header;

({BackupHeader header, Uint8List body}) _split(Uint8List bytes) {
  final first = bytes.indexOf(10);
  if (first < 0 || utf8.decode(bytes.sublist(0, first), allowMalformed: true) != _magic) {
    throw BackupFormatException('This is not a GSV Poems backup file.');
  }
  final second = bytes.indexOf(10, first + 1);
  if (second < 0) throw BackupFormatException('The backup file is incomplete.');
  try {
    final header = BackupHeader.fromJson(jsonDecode(utf8.decode(bytes.sublist(first + 1, second))) as Map<String, dynamic>);
    return (header: header, body: Uint8List.sublistView(bytes, second + 1));
  } on FormatException {
    throw BackupFormatException('The backup file is damaged.');
  }
}

/// Opens a backup with the recovery key. Throws [WrongKeyException] when the
/// key is wrong (or the file was changed).
Future<Map<String, dynamic>> decodeBackup(Uint8List bytes, String recoveryKey) async {
  final s = _split(bytes);
  if (s.body.length < 16) throw BackupFormatException('The backup file is incomplete.');
  final key = await _deriveKey(recoveryKey, s.header.salt, s.header.iterations);
  final box = SecretBox(s.body.sublist(0, s.body.length - 16), nonce: s.header.nonce, mac: Mac(s.body.sublist(s.body.length - 16)));
  List<int> plain;
  try {
    plain = await AesGcm.with256bits().decrypt(box, secretKey: key);
  } on SecretBoxAuthenticationError {
    throw WrongKeyException();
  }
  return jsonDecode(utf8.decode(gzip.decode(plain))) as Map<String, dynamic>;
}
