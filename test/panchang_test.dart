import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/core/panchang/festivals.dart';
import 'package:gsv_poems/core/panchang/names.dart';
import 'package:gsv_poems/core/panchang/panchang.dart';

// The Panchang works in the phone's time zone; these reference dates are for
// India (IST), so the date checks only run on a machine set to IST.
final isIst = DateTime(2026, 11, 7).timeZoneOffset == const Duration(hours: 5, minutes: 30);
const skipNotIst = 'reference dates are for India time (IST)';

DateTime? festivalDay(String english, DateTime from, int days) {
  for (final f in upcoming(from, Place.ahmedabad, days: days)) {
    if (f.festival.names[2] == english) return f.date;
  }
  return null;
}

void main() {
  group('festival dates match published panchangs (Drik Panchang and others)', () {
    final checks = <(String, DateTime)>[
      ('Diwali', DateTime(2026, 11, 8)),
      ('Dev Uthi Ekadashi', DateTime(2026, 11, 20)),
      ('Dev Diwali', DateTime(2026, 11, 24)),
      ('Maha Shivratri', DateTime(2027, 3, 6)),
      ('Holi', DateTime(2027, 3, 21)),
      ('Ram Navami', DateTime(2027, 4, 15)),
      ('Janmashtami', DateTime(2027, 8, 24)),
      ('Ganesh Chaturthi', DateTime(2027, 9, 4)),
      ('Navratri begins', DateTime(2027, 9, 30)),
      ('Dussehra', DateTime(2027, 10, 9)),
      ('Diwali', DateTime(2027, 10, 29)),
    ];
    for (final (name, date) in checks) {
      test('$name ${date.toIso8601String().substring(0, 10)}', () {
        expect(festivalDay(name, date.subtract(const Duration(days: 20)), 40), date);
      }, skip: isIst ? false : skipNotIst);
    }
  });

  test('Ekadashi starts at 7:15 AM on 20 Nov 2026 (published: 07:15)', () {
    final p = panchangFor(DateTime(2026, 11, 20), Place.ahmedabad);
    expect(p.tithi, 10, reason: 'Dashami at sunrise');
    expect(p.tithiEnds.hour, 7);
    expect(p.tithiEnds.minute, inInclusiveRange(10, 20));
  }, skip: isIst ? false : skipNotIst);

  test('Gujarati month and Vikram Samvat turn over at Diwali', () {
    final before = panchangFor(DateTime(2026, 11, 7), Place.ahmedabad);
    final after = panchangFor(DateTime(2026, 11, 12), Place.ahmedabad);
    expect(monthNames[before.month.index][0], 'આસો');
    expect(before.samvat, 2082);
    expect(monthNames[after.month.index][0], 'કારતક');
    expect(after.samvat, 2083);
    expect(dateLine(before, 0), startsWith('આસો વદ'));
  }, skip: isIst ? false : skipNotIst);

  test('Choghadiya: 8 by day and 8 by night, first one by weekday', () {
    final sat = panchangFor(DateTime(2026, 11, 7), Place.ahmedabad); // Saturday
    expect(sat.dayChoghadiya.map((c) => c.kind), [
      ChoghadiyaKind.kaal,
      ChoghadiyaKind.shubh,
      ChoghadiyaKind.rog,
      ChoghadiyaKind.udveg,
      ChoghadiyaKind.char,
      ChoghadiyaKind.labh,
      ChoghadiyaKind.amrit,
      ChoghadiyaKind.kaal,
    ]);
    expect(sat.nightChoghadiya.first.kind, ChoghadiyaKind.labh);
    expect(sat.dayChoghadiya.first.start, sat.sunrise);
    expect(sat.dayChoghadiya.last.end, sat.sunset);
    expect(sat.nightChoghadiya.last.end, sat.nextSunrise);
    final sun = panchangFor(DateTime(2026, 11, 8), Place.ahmedabad);
    expect(sun.dayChoghadiya.first.kind, ChoghadiyaKind.udveg);
    expect(sun.nightChoghadiya.first.kind, ChoghadiyaKind.shubh);
    final noon = DateTime(2026, 11, 7, 12, 30);
    expect(sat.choghadiyaAt(noon), isNotNull);
    expect(qualityOf(ChoghadiyaKind.amrit), Quality.good);
    expect(qualityOf(ChoghadiyaKind.kaal), Quality.bad);
  });

  test('Uttarayan is 14 January; every month has two Ekadashis and a Purnima', () {
    expect(festivalsOn(DateTime(2027, 1, 14), Place.ahmedabad).map((f) => f.names[2]), contains('Uttarayan (Makar Sankranti)'));
    final dec = upcoming(DateTime(2026, 12, 1), Place.ahmedabad, days: 31);
    expect(dec.where((f) => f.festival.kind == FestivalKind.ekadashi).length, 2);
    expect(dec.where((f) => f.festival.kind == FestivalKind.purnima).length, 1);
  });
}
