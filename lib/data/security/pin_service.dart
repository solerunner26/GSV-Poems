import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key/value interface so the PIN logic can be unit-tested.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSecretStore implements SecretStore {
  const SecureSecretStore();
  static const _s = FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _s.read(key: key);
  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

/// PBKDF2-HMAC-SHA256 (RFC 8018).
Uint8List pbkdf2(List<int> password, List<int> salt, int iterations, int length) {
  final hmac = Hmac(sha256, password);
  final out = BytesBuilder();
  for (var block = 1; out.length < length; block++) {
    final first = hmac.convert([...salt, block >> 24 & 255, block >> 16 & 255, block >> 8 & 255, block & 255]).bytes;
    var u = first;
    final t = List<int>.from(first);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    out.add(t);
  }
  return Uint8List.fromList(out.toBytes().sublist(0, length));
}

enum PinCheck { ok, wrong, lockedOut }

/// Stores only a salted PBKDF2 hash of the 4-digit PIN, never the PIN itself.
class PinService {
  PinService(this.store, {DateTime Function()? clock, this.iterations = 60000}) : _now = clock ?? DateTime.now;

  final SecretStore store;
  final DateTime Function() _now;
  final int iterations;

  static const maxTries = 5;
  static const lockout = Duration(seconds: 30);
  static const _kHash = 'pin_hash', _kSalt = 'pin_salt', _kIter = 'pin_iter';
  static const _kFails = 'pin_fails', _kLockUntil = 'pin_lock_until', _kBio = 'pin_biometric';

  Future<bool> hasPin() async => (await store.read(_kHash)) != null;

  static bool isValidPin(String pin) => RegExp(r'^[0-9]{4}$').hasMatch(pin);

  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) throw ArgumentError('PIN must be 4 digits');
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final it = iterations;
    final hash = await Isolate.run(() => pbkdf2(utf8.encode(pin), salt, it, 32));
    await store.write(_kSalt, base64Encode(salt));
    await store.write(_kIter, '$iterations');
    await store.write(_kHash, base64Encode(hash));
    await store.delete(_kFails);
    await store.delete(_kLockUntil);
  }

  Future<Duration?> lockedFor() async {
    final until = int.tryParse(await store.read(_kLockUntil) ?? '');
    if (until == null) return null;
    final left = DateTime.fromMillisecondsSinceEpoch(until).difference(_now());
    return left.isNegative ? null : left;
  }

  Future<PinCheck> check(String pin) async {
    if (await lockedFor() != null) return PinCheck.lockedOut;
    final saltB64 = await store.read(_kSalt);
    final hashB64 = await store.read(_kHash);
    if (saltB64 == null || hashB64 == null) return PinCheck.wrong;
    final iter = int.tryParse(await store.read(_kIter) ?? '') ?? iterations;
    final salt = base64Decode(saltB64);
    // Hashing runs off the UI thread so the keypad never freezes.
    final calc = await Isolate.run(() => pbkdf2(utf8.encode(pin), salt, iter, 32));
    final want = base64Decode(hashB64);
    var diff = calc.length ^ want.length;
    for (var i = 0; i < calc.length && i < want.length; i++) {
      diff |= calc[i] ^ want[i];
    }
    if (diff == 0) {
      await store.delete(_kFails);
      await store.delete(_kLockUntil);
      return PinCheck.ok;
    }
    final fails = (int.tryParse(await store.read(_kFails) ?? '') ?? 0) + 1;
    if (fails >= maxTries) {
      await store.write(_kLockUntil, '${_now().add(lockout).millisecondsSinceEpoch}');
      await store.delete(_kFails);
      return PinCheck.lockedOut;
    }
    await store.write(_kFails, '$fails');
    return PinCheck.wrong;
  }

  /// The salted hash of this device's PIN, to let the poet's own PIN unlock
  /// writing on another device. Never the PIN itself.
  Future<Map<String, String>?> verifier() async {
    final salt = await store.read(_kSalt), hash = await store.read(_kHash);
    if (salt == null || hash == null) return null;
    return {'salt': salt, 'hash': hash, 'iter': await store.read(_kIter) ?? '$iterations'};
  }

  /// Whether [pin] matches a [verifier] from another device.
  static Future<bool> matches(Map<String, dynamic> verifier, String pin) async {
    final salt = base64Decode('${verifier['salt']}');
    final want = base64Decode('${verifier['hash']}');
    final iter = int.tryParse('${verifier['iter']}') ?? 60000;
    final calc = await Isolate.run(() => pbkdf2(utf8.encode(pin), salt, iter, 32));
    var diff = calc.length ^ want.length;
    for (var i = 0; i < calc.length && i < want.length; i++) {
      diff |= calc[i] ^ want[i];
    }
    return diff == 0;
  }

  Future<bool> biometricEnabled() async => (await store.read(_kBio)) == '1';
  Future<void> setBiometric(bool on) => on ? store.write(_kBio, '1') : store.delete(_kBio);
}
