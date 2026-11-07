/// Sun and Moon positions and sunrise, computed on the phone (no internet).
///
/// Formulas from Jean Meeus, "Astronomical Algorithms" (2nd ed.):
/// Sun ch. 25 (≈0.01°), Moon ch. 47 with the 60 main longitude terms
/// (≈0.005°), so tithi end times are good to a few minutes. Sunrise uses the
/// standard −0.833° altitude (refraction + solar radius).
library;

import 'dart:math' as math;

const _deg = math.pi / 180;

double _norm(double a) {
  final r = a % 360;
  return r < 0 ? r + 360 : r;
}

double _sin(double d) => math.sin(d * _deg);
double _cos(double d) => math.cos(d * _deg);

/// Julian Day for a UTC moment.
double julianDay(DateTime utc) {
  final u = utc.toUtc();
  return u.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
}

DateTime fromJulianDay(double jd) =>
    DateTime.fromMillisecondsSinceEpoch(((jd - 2440587.5) * 86400000).round(), isUtc: true);

/// TT − UT in days (about 69–75 s for 2000–2050).
double _deltaTDays(double jd) {
  final year = 2000 + (jd - 2451545.0) / 365.25;
  final t = year - 2000;
  final seconds = 62.92 + 0.32217 * t + 0.005589 * t * t;
  return seconds / 86400;
}

/// Julian centuries of Terrestrial Time since J2000.
double _centuries(double jdUt) => (jdUt + _deltaTDays(jdUt) - 2451545.0) / 36525;

/// Apparent geocentric ecliptic longitude of the Sun, tropical, degrees.
double sunLongitude(double jdUt) {
  final t = _centuries(jdUt);
  final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
  final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
  final c = (1.914602 - 0.004817 * t - 0.000014 * t * t) * _sin(m) +
      (0.019993 - 0.000101 * t) * _sin(2 * m) +
      0.000289 * _sin(3 * m);
  final omega = 125.04 - 1934.136 * t;
  return _norm(l0 + c - 0.00569 - 0.00478 * _sin(omega));
}

// Meeus table 47.A: D, M, M', F, coefficient of sin (1e-6 degree).
const _moonTerms = <List<int>>[
  [0, 0, 1, 0, 6288774], [2, 0, -1, 0, 1274027], [2, 0, 0, 0, 658314], [0, 0, 2, 0, 213618],
  [0, 1, 0, 0, -185116], [0, 0, 0, 2, -114332], [2, 0, -2, 0, 58793], [2, -1, -1, 0, 57066],
  [2, 0, 1, 0, 53322], [2, -1, 0, 0, 45758], [0, 1, -1, 0, -40923], [1, 0, 0, 0, -34720],
  [0, 1, 1, 0, -30383], [2, 0, 0, -2, 15327], [0, 0, 1, 2, -12528], [0, 0, 1, -2, 10980],
  [4, 0, -1, 0, 10675], [0, 0, 3, 0, 10034], [4, 0, -2, 0, 8548], [2, 1, -1, 0, -7888],
  [2, 1, 0, 0, -6766], [1, 0, -1, 0, -5163], [1, 1, 0, 0, 4987], [2, -1, 1, 0, 4036],
  [2, 0, 2, 0, 3994], [4, 0, 0, 0, 3861], [2, 0, -3, 0, 3665], [0, 1, -2, 0, -2689],
  [2, 0, -1, 2, -2602], [2, -1, -2, 0, 2390], [1, 0, 1, 0, -2348], [2, -2, 0, 0, 2236],
  [0, 1, 2, 0, -2120], [0, 2, 0, 0, -2069], [2, -2, -1, 0, 2048], [2, 0, 1, -2, -1773],
  [2, 0, 0, 2, -1595], [4, -1, -1, 0, 1215], [0, 0, 2, 2, -1110], [3, 0, -1, 0, -892],
  [2, 1, 1, 0, -810], [4, -1, -2, 0, 759], [0, 2, -1, 0, -713], [2, 2, -1, 0, -700],
  [2, 1, -2, 0, 691], [2, -1, 0, -2, 596], [4, 0, 1, 0, 549], [0, 0, 4, 0, 537],
  [4, -1, 0, 0, 520], [1, 0, -2, 0, -487], [2, 1, 0, -2, -399], [0, 0, 2, -2, -381],
  [1, 1, 1, 0, 351], [3, 0, -2, 0, -340], [4, 0, -3, 0, 330], [2, -1, 2, 0, 327],
  [0, 2, 1, 0, -323], [1, 1, -1, 0, 299], [2, 0, 3, 0, 294],
];

/// Geocentric ecliptic longitude of the Moon, tropical, degrees (same frame as [sunLongitude]).
double moonLongitude(double jdUt) {
  final t = _centuries(jdUt);
  final t2 = t * t, t3 = t2 * t, t4 = t3 * t;
  final lp = 218.3164477 + 481267.88123421 * t - 0.0015786 * t2 + t3 / 538841 - t4 / 65194000;
  final d = 297.8501921 + 445267.1114034 * t - 0.0018819 * t2 + t3 / 545868 - t4 / 113065000;
  final m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000;
  final mp = 134.9633964 + 477198.8675055 * t + 0.0087414 * t2 + t3 / 69699 - t4 / 14712000;
  final f = 93.2720950 + 483202.0175233 * t - 0.0036539 * t2 - t3 / 3526000 + t4 / 863310000;
  final e = 1 - 0.002516 * t - 0.0000074 * t2;
  var sum = 0.0;
  for (final r in _moonTerms) {
    var c = r[4].toDouble();
    if (r[1].abs() == 1) c *= e;
    if (r[1].abs() == 2) c *= e * e;
    sum += c * _sin(r[0] * d + r[1] * m + r[2] * mp + r[3] * f);
  }
  final a1 = 119.75 + 131.849 * t, a2 = 53.09 + 479264.290 * t;
  sum += 3958 * _sin(a1) + 1962 * _sin(lp - f) + 318 * _sin(a2);
  // Aberration of the Sun is in [sunLongitude]; the Moon's is negligible (≈0.0002°).
  return _norm(lp + sum / 1e6 - 0.00478 * _sin(125.04 - 1934.136 * t));
}

/// Lahiri (Chitrapaksha) ayanamsa, degrees.
double ayanamsa(double jdUt) {
  final t = (jdUt - 2451545.0) / 36525;
  return 23.85306 + 1.39722 * t + 0.00018 * t * t;
}

double siderealSun(double jd) => _norm(sunLongitude(jd) - ayanamsa(jd));
double siderealMoon(double jd) => _norm(moonLongitude(jd) - ayanamsa(jd));

/// Moon minus Sun, 0–360°: 12° per tithi.
double elongation(double jd) => _norm(moonLongitude(jd) - sunLongitude(jd));

/// Sunrise and sunset (UTC) for the local calendar date [y]-[m]-[d] at the
/// given place. Null when the sun does not rise or set (polar day/night).
({DateTime rise, DateTime set})? sunTimes(int y, int m, int d, double lat, double lon, Duration utcOffset) {
  // NOAA method, repeated with the Sun's position at the event itself (~1 min accuracy).
  // Minutes are counted from 00:00 UTC of the same calendar date; for places far
  // east (New Zealand) they come out negative, which lands on the right instant.
  final utcMidnight = DateTime.utc(y, m, d);
  DateTime? event(bool rising) {
    var jd = julianDay(utcMidnight.add(const Duration(hours: 12)).subtract(utcOffset));
    for (var i = 0; i < 3; i++) {
      final t = (jd - 2451545.0) / 36525;
      final l0 = _norm(280.46646 + 36000.76983 * t);
      final ma = 357.52911 + 35999.05029 * t;
      final ecc = 0.016708634 - 0.000042037 * t;
      final c = (1.914602 - 0.004817 * t) * _sin(ma) + 0.019993 * _sin(2 * ma) + 0.000289 * _sin(3 * ma);
      final lambda = l0 + c - 0.00569 - 0.00478 * _sin(125.04 - 1934.136 * t);
      final eps = 23.439291 - 0.0130042 * t + 0.00256 * _cos(125.04 - 1934.136 * t);
      final decl = math.asin(_sin(eps) * _sin(lambda)) / _deg;
      final yv = math.pow(math.tan(eps / 2 * _deg), 2).toDouble();
      final eqTime = 4 / _deg *
          (yv * math.sin(2 * l0 * _deg) -
              2 * ecc * math.sin(ma * _deg) +
              4 * ecc * yv * math.sin(ma * _deg) * math.cos(2 * l0 * _deg) -
              0.5 * yv * yv * math.sin(4 * l0 * _deg) -
              1.25 * ecc * ecc * math.sin(2 * ma * _deg)); // minutes
      final cosH = (_cos(90.833) - _sin(lat) * _sin(decl)) / (_cos(lat) * _cos(decl));
      if (cosH.abs() > 1) return null;
      final h = math.acos(cosH) / _deg;
      final minutesUtc = 720 - 4 * (lon + (rising ? h : -h)) - eqTime;
      jd = julianDay(utcMidnight.add(Duration(milliseconds: (minutesUtc * 60000).round())));
    }
    return fromJulianDay(jd);
  }

  final r = event(true), s = event(false);
  if (r == null || s == null) return null;
  return (rise: r, set: s);
}

/// Finds when [f] (an increasing angle, unwrapped by the caller) reaches [target]
/// between [a] and [b] (Julian Days), by bisection. Accurate to ~5 seconds.
double solveCrossing(double Function(double jd) f, double target, double a, double b) {
  var lo = a, hi = b;
  for (var i = 0; i < 40; i++) {
    final mid = (lo + hi) / 2;
    if (f(mid) < target) {
      lo = mid;
    } else {
      hi = mid;
    }
    if (hi - lo < 0.00005) break;
  }
  return (lo + hi) / 2;
}
