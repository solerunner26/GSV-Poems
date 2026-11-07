import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/core/panchang/astro.dart';

/// Time when the Moon–Sun elongation reaches [target]° near [guess].
DateTime phaseNear(DateTime guess, double target) {
  final g = julianDay(guess);
  double unwrapped(double jd) {
    var e = elongation(jd) - target;
    if (e > 180) e -= 360;
    if (e < -180) e += 360;
    return e;
  }

  return fromJulianDay(solveCrossing(unwrapped, 0, g - 1.5, g + 1.5));
}

void expectNear(DateTime got, DateTime want, Duration tol) {
  expect(got.difference(want).abs() <= tol, isTrue, reason: 'got $got, expected $want ± $tol');
}

void main() {
  group('Moon phases match eclipse times (published by NASA)', () {
    const tol = Duration(minutes: 12);
    test('new moon at the total solar eclipses', () {
      expectNear(phaseNear(DateTime.utc(2024, 4, 8, 18), 0), DateTime.utc(2024, 4, 8, 18, 21), tol);
      expectNear(phaseNear(DateTime.utc(2026, 8, 12, 18), 0), DateTime.utc(2026, 8, 12, 17, 37), tol);
    });
    test('full moon at the lunar eclipses', () {
      expectNear(phaseNear(DateTime.utc(2025, 3, 14, 7), 180), DateTime.utc(2025, 3, 14, 6, 55), tol);
      expectNear(phaseNear(DateTime.utc(2025, 9, 7, 18), 180), DateTime.utc(2025, 9, 7, 18, 9), tol);
      expectNear(phaseNear(DateTime.utc(2026, 3, 3, 12), 180), DateTime.utc(2026, 3, 3, 11, 38), tol);
    });
  });

  group('sunrise and sunset in Ahmedabad (IST)', () {
    const ist = Duration(hours: 5, minutes: 30);
    const lat = 23.0225, lon = 72.5714;
    const tol = Duration(minutes: 5);
    test('June solstice', () {
      final t = sunTimes(2026, 6, 21, lat, lon, ist)!;
      expectNear(t.rise.add(ist), DateTime.utc(2026, 6, 21, 5, 54), tol);
      expectNear(t.set.add(ist), DateTime.utc(2026, 6, 21, 19, 27), tol); // sunrise-sunset.net: 5:54 AM / 7:27 PM
    });
    test('December solstice', () {
      final t = sunTimes(2026, 12, 21, lat, lon, ist)!;
      expectNear(t.rise.add(ist), DateTime.utc(2026, 12, 21, 7, 17), tol);
      expectNear(t.set.add(ist), DateTime.utc(2026, 12, 21, 17, 59), tol);
    });
    test('Auckland, far east of UTC, lands on the right day', () {
      const nzdt = Duration(hours: 13);
      final t = sunTimes(2026, 11, 7, -36.85, 174.76, nzdt)!;
      final local = t.rise.add(nzdt);
      expect(local.day, 7);
      expect(local.hour, inInclusiveRange(5, 6));
    });
  });
}
