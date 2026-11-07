/// The Hindu calendar (Gujarati style: amanta months, Vikram Samvat from
/// Kartik) for any date and place, worked out on the phone.
library;

import 'astro.dart';
import 'names.dart';

class Place {
  const Place(this.name, this.lat, this.lon);
  final String name;
  final double lat, lon;
  static const ahmedabad = Place('Ahmedabad', 23.0225, 72.5714);
}

class Choghadiya {
  const Choghadiya(this.kind, this.start, this.end, {required this.night});
  final ChoghadiyaKind kind;
  final DateTime start, end;
  final bool night;
  Quality get quality => qualityOf(kind);
  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

class LunarMonth {
  const LunarMonth(this.index, {required this.adhik, required this.start, required this.end});

  /// 0 = Chaitra … 6 = Ashvin (Aso), 7 = Kartik … 11 = Phalgun.
  final int index;
  final bool adhik;

  /// New moons that begin and end this month (UTC).
  final DateTime start, end;
}

class PanchangDay {
  PanchangDay({
    required this.date,
    required this.sunrise,
    required this.sunset,
    required this.nextSunrise,
    required this.tithi,
    required this.tithiEnds,
    required this.sunsetTithi,
    required this.middayTithi,
    required this.afternoonTithi,
    required this.midnightTithi,
    required this.nakshatra,
    required this.nakshatraEnds,
    required this.yoga,
    required this.yogaEnds,
    required this.karana,
    required this.month,
    required this.samvat,
    required this.sunRashi,
  });

  /// Local calendar date (time part 00:00).
  final DateTime date;

  /// Local times.
  final DateTime sunrise, sunset, nextSunrise;

  /// 1–30 at sunrise (1–15 Shukla/સુદ, 16–30 Krishna/વદ; 15 Purnima, 30 Amavasya).
  final int tithi;
  final DateTime tithiEnds;

  /// The tithi at sunset (Diwali is kept when Amavasya holds in the evening).
  final int sunsetTithi;

  /// Tithi at midday, in the afternoon (aparahna) and at midnight (nishita):
  /// Ganesh Chaturthi follows midday, Dussehra the afternoon, Shivratri and
  /// Janmashtami midnight.
  final int middayTithi, afternoonTithi, midnightTithi;

  /// 0–26, and when it changes (local time).
  final int nakshatra;
  final DateTime nakshatraEnds;
  final int yoga;
  final DateTime yogaEnds;

  /// Index into [karanaNames].
  final int karana;
  final LunarMonth month;

  /// Vikram Samvat (Gujarati, new year on Kartik Shukla 1).
  final int samvat;

  /// Sidereal sign of the Sun at sunrise, 0 = Mesha … 9 = Makara.
  final int sunRashi;

  int get vaar => date.weekday % 7;
  bool get shukla => tithi <= 15;
  int get tithiInPaksha => shukla ? tithi : tithi - 15;

  List<Choghadiya> get dayChoghadiya => _segments(sunrise, sunset, _dayStart[vaar], _dayCycle, night: false);
  List<Choghadiya> get nightChoghadiya => _segments(sunset, nextSunrise, _nightStart[vaar], _nightCycle, night: true);

  /// The Choghadiya running at [t] (day or night), if [t] falls in this day.
  Choghadiya? choghadiyaAt(DateTime t) {
    for (final c in [...dayChoghadiya, ...nightChoghadiya]) {
      if (c.contains(t)) return c;
    }
    return null;
  }
}

// Day Choghadiya: the first of the day depends on the weekday, then it
// follows Udveg → Char → Labh → Amrit → Kaal → Shubh → Rog.
const _dayCycle = [
  ChoghadiyaKind.udveg,
  ChoghadiyaKind.char,
  ChoghadiyaKind.labh,
  ChoghadiyaKind.amrit,
  ChoghadiyaKind.kaal,
  ChoghadiyaKind.shubh,
  ChoghadiyaKind.rog,
];
const _dayStart = [
  ChoghadiyaKind.udveg,
  ChoghadiyaKind.amrit,
  ChoghadiyaKind.rog,
  ChoghadiyaKind.labh,
  ChoghadiyaKind.shubh,
  ChoghadiyaKind.char,
  ChoghadiyaKind.kaal,
];
// Night: Shubh → Amrit → Char → Rog → Kaal → Labh → Udveg.
const _nightCycle = [
  ChoghadiyaKind.shubh,
  ChoghadiyaKind.amrit,
  ChoghadiyaKind.char,
  ChoghadiyaKind.rog,
  ChoghadiyaKind.kaal,
  ChoghadiyaKind.labh,
  ChoghadiyaKind.udveg,
];
const _nightStart = [
  ChoghadiyaKind.shubh,
  ChoghadiyaKind.char,
  ChoghadiyaKind.kaal,
  ChoghadiyaKind.udveg,
  ChoghadiyaKind.amrit,
  ChoghadiyaKind.rog,
  ChoghadiyaKind.labh,
];

List<Choghadiya> _segments(DateTime from, DateTime to, ChoghadiyaKind first, List<ChoghadiyaKind> cycle, {required bool night}) {
  final step = to.difference(from) ~/ 8;
  var i = cycle.indexOf(first);
  return [for (var k = 0; k < 8; k++) Choghadiya(cycle[(i + k) % 7], from.add(step * k), k == 7 ? to : from.add(step * (k + 1)), night: night)];
}

double _wrap(double a) {
  final r = a % 360;
  return r < 0 ? r + 360 : r;
}

/// When an angle that grows by about [rate]°/day has moved [delta]° past its value at [jd0].
double _whenAdvanced(double Function(double) angle, double jd0, double delta, double rate) {
  final a0 = angle(jd0);
  double moved(double jd) => _wrap(angle(jd) - a0);
  final guess = delta / rate;
  return solveCrossing(moved, delta, jd0, jd0 + (guess * 1.6 + 0.2).clamp(0.3, 2.5));
}

/// The new moon nearest before [jd] (when the Moon–Sun elongation passes 0°).
double newMoonBefore(double jd) {
  final back = elongation(jd) / 12.19;
  final guess = jd - back;
  double signed(double x) {
    final e = elongation(x);
    return e > 180 ? e - 360 : e;
  }

  return solveCrossing(signed, 0, guess - 1.5, guess + 1.5);
}

final _monthCache = <int, LunarMonth>{};

LunarMonth lunarMonthAt(double jd) {
  final nm = newMoonBefore(jd);
  final key = (nm * 10).round();
  final cached = _monthCache[key];
  if (cached != null) return cached;
  final next = newMoonBefore(nm + 31);
  final rashiStart = siderealSun(nm) ~/ 30;
  final rashiEnd = siderealSun(next) ~/ 30;
  // Amanta rule: the month is named after the Sun's sign at the new moon that
  // starts it (Sun in Meena → Chaitra). Two new moons in one sign → Adhik month.
  final m = LunarMonth((rashiStart + 1) % 12, adhik: rashiStart == rashiEnd, start: fromJulianDay(nm), end: fromJulianDay(next));
  if (_monthCache.length > 200) _monthCache.clear();
  return _monthCache[key] = m;
}

int _samvat(LunarMonth m) {
  // Months since the most recent Kartik (index 7) began.
  final sinceKartik = (m.index - 7 + 12) % 12;
  final kartikStart = m.start.subtract(Duration(hours: (sinceKartik * 29.53 * 24).round()));
  return kartikStart.add(const Duration(days: 10)).year + 57;
}

int _tithiAt(double jd) => (elongation(jd) / 12).floor() + 1;

final _dayCache = <String, PanchangDay>{};

/// Panchang for the local date of [day] at [place]. Times are in the phone's time zone.
PanchangDay panchangFor(DateTime day, Place place) {
  final d = DateTime(day.year, day.month, day.day);
  final cacheKey = '${d.toIso8601String()}|${place.lat}|${place.lon}';
  final hit = _dayCache[cacheKey];
  if (hit != null) return hit;

  final offset = d.add(const Duration(hours: 12)).timeZoneOffset;
  final st =
      sunTimes(d.year, d.month, d.day, place.lat, place.lon, offset) ??
      (rise: DateTime.utc(d.year, d.month, d.day, 6).subtract(offset), set: DateTime.utc(d.year, d.month, d.day, 18).subtract(offset));
  final n = d.add(const Duration(days: 1));
  final nOffset = n.add(const Duration(hours: 12)).timeZoneOffset;
  final nextRise = sunTimes(n.year, n.month, n.day, place.lat, place.lon, nOffset)?.rise ?? st.rise.add(const Duration(days: 1));

  final jd = julianDay(st.rise);
  final tithi = _tithiAt(jd);
  final elong = elongation(jd);
  final tithiEnd = _whenAdvanced(elongation, jd, tithi * 12 - elong, 12.19);
  final moon = siderealMoon(jd);
  const span = 360 / 27;
  final nak = (moon / span).floor() % 27;
  final nakEnd = _whenAdvanced(siderealMoon, jd, (nak + 1) * span - moon, 13.2);
  double yogaAngle(double x) => _wrap(siderealSun(x) + siderealMoon(x));
  final ya = yogaAngle(jd);
  final yoga = (ya / span).floor() % 27;
  final yogaEnd = _whenAdvanced(yogaAngle, jd, (yoga + 1) * span - ya, 14.2);
  final half = (elong / 6).floor(); // 0–59
  final karana = half == 0 ? 10 : (half >= 57 ? 7 + (half - 57) : (half - 1) % 7);
  final month = lunarMonthAt(jd);

  final result = PanchangDay(
    date: d,
    sunrise: st.rise.toLocal(),
    sunset: st.set.toLocal(),
    nextSunrise: nextRise.toLocal(),
    tithi: tithi,
    tithiEnds: fromJulianDay(tithiEnd).toLocal(),
    sunsetTithi: _tithiAt(julianDay(st.set)),
    // Madhyahna (puja time) is the third fifth of daylight; the tithi must hold as it begins.
    middayTithi: _tithiAt(julianDay(st.rise.add(st.set.difference(st.rise) * 0.4))),
    afternoonTithi: _tithiAt(julianDay(st.rise.add(st.set.difference(st.rise) * 0.7))),
    midnightTithi: _tithiAt(julianDay(st.set.add(nextRise.difference(st.set) * 0.5))),
    nakshatra: nak,
    nakshatraEnds: fromJulianDay(nakEnd).toLocal(),
    yoga: yoga,
    yogaEnds: fromJulianDay(yogaEnd).toLocal(),
    karana: karana,
    month: month,
    samvat: _samvat(month),
    sunRashi: siderealSun(jd) ~/ 30,
  );
  if (_dayCache.length > 400) _dayCache.clear();
  return _dayCache[cacheKey] = result;
}

/// Name of a tithi number 1–30 in language index [l] (0 gu, 1 hi, 2 en).
String tithiName(int tithi, int l) {
  if (tithi == 15) return purnima[l];
  if (tithi == 30) return amavasya[l];
  return tithiNames[(tithi - 1) % 15][l];
}

/// "આસો વદ ચૌદસ" / "आश्विन कृष्ण चतुर्दशी" / "Ashvin Krishna Chaturdashi".
String dateLine(PanchangDay p, int l) {
  final month = '${p.month.adhik ? '${adhikName[l]} ' : ''}${monthNames[p.month.index][l]}';
  if (p.tithi == 15 || p.tithi == 30) return '$month ${tithiName(p.tithi, l)}';
  return '$month ${pakshaNames[p.shukla ? 0 : 1][l]} ${tithiName(p.tithi, l)}';
}
