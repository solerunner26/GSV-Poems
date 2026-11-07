import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/data/security/pin_service.dart';

class MemoryStore implements SecretStore {
  final m = <String, String>{};
  @override
  Future<String?> read(String key) async => m[key];
  @override
  Future<void> write(String key, String value) async => m[key] = value;
  @override
  Future<void> delete(String key) async => m.remove(key);
}

void main() {
  test('PBKDF2-SHA256 matches the RFC 7914 test vector', () {
    final out = pbkdf2(utf8.encode('passwd'), utf8.encode('salt'), 1, 64);
    final hex = out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(hex.substring(0, 32), '55ac046e56e3089fec1691c22544b605');
  });

  group('PinService', () {
    late MemoryStore store;
    late DateTime now;
    late PinService pins;

    setUp(() {
      store = MemoryStore();
      now = DateTime(2026, 11, 7, 10);
      pins = PinService(store, clock: () => now, iterations: 1000);
    });

    test('stores a hash, never the PIN itself', () async {
      await pins.setPin('4321');
      expect(await pins.hasPin(), isTrue);
      expect(store.m.values.any((v) => v.contains('4321')), isFalse);
    });

    test('right PIN opens, wrong PIN does not', () async {
      await pins.setPin('4321');
      expect(await pins.check('4321'), PinCheck.ok);
      expect(await pins.check('1234'), PinCheck.wrong);
    });

    test('5 wrong tries lock for 30 seconds, then it opens again', () async {
      await pins.setPin('4321');
      for (var i = 0; i < 4; i++) {
        expect(await pins.check('0000'), PinCheck.wrong);
      }
      expect(await pins.check('0000'), PinCheck.lockedOut);
      expect(await pins.check('4321'), PinCheck.lockedOut);
      now = now.add(const Duration(seconds: 31));
      expect(await pins.check('4321'), PinCheck.ok);
    });

    test('only 4 digits are accepted', () {
      expect(PinService.isValidPin('12a4'), isFalse);
      expect(PinService.isValidPin('12345'), isFalse);
      expect(PinService.isValidPin('0007'), isTrue);
      expect(() => pins.setPin('12'), throwsArgumentError);
    });
  });
}
