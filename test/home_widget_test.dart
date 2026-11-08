import 'package:flutter_test/flutter_test.dart';
import 'package:gsv_poems/core/panchang/panchang.dart';
import 'package:gsv_poems/core/text/text_tools.dart';
import 'package:gsv_poems/features/widget/home_screen_widget.dart';

void main() {
  test('the widget gets a week of Gujarati date, tithi and Choghadiya with no gaps', () async {
    final now = DateTime(2026, 11, 7, 15, 40);
    final data = await buildWidgetData(Place.ahmedabad, PoemLang.gu, now: now);
    expect(data['place'], 'અમદાવાદ');
    final days = (data['days'] as List).cast<Map<String, dynamic>>();
    expect(days, hasLength(8), reason: 'yesterday (for the night before sunrise) and seven days ahead');
    final today = days.firstWhere((d) => d['date'] == '2026-11-07');
    expect(today['day'], '૭');
    expect(today['weekday'], 'શનિવાર');
    expect(today['tithi'], contains('આસો'));
    expect(today['festival'], contains('ધનતેરસ'));
    expect(today['sun'], contains('સૂર્યોદય'));

    // Every moment of the week falls in exactly one Choghadiya.
    final slots = [
      for (final d in days) ...(d['slots'] as List).cast<Map<String, dynamic>>(),
    ]..sort((a, b) => (a['s'] as int).compareTo(b['s'] as int));
    for (var i = 1; i < slots.length; i++) {
      expect((slots[i]['s'] as int) - (slots[i - 1]['e'] as int), lessThan(60000), reason: 'no gap between Choghadiyas');
    }
    final at = now.millisecondsSinceEpoch;
    final current = slots.where((s) => (s['s'] as int) <= at && at < (s['e'] as int)).toList();
    expect(current, hasLength(1));
    expect(current.single['name'], contains('ચોઘડિયું'));
    expect(current.single['detail'], contains('સુધી'));
    expect(['good', 'neutral', 'bad'], contains(current.single['q']));
  });

  test('Hindi interface gives Hindi text', () async {
    final data = await buildWidgetData(Place.ahmedabad, PoemLang.hi, now: DateTime(2026, 11, 7, 9));
    final today = (data['days'] as List).cast<Map<String, dynamic>>().firstWhere((d) => d['date'] == '2026-11-07');
    expect(today['weekday'], 'शनिवार');
  });
}
