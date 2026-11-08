import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/strings.dart';
import '../../core/panchang/festivals.dart';
import '../../core/panchang/names.dart';
import '../../core/panchang/panchang.dart';
import '../../core/text/text_tools.dart';
import '../calendar/calendar_screen.dart' show clock, placeLabel;

/// The Android home-screen widget: today's Gujarati date, tithi, festival and
/// the Choghadiya running now. The app works out a week ahead; the widget
/// itself (Kotlin, GsvWidgetProvider) picks the current day and Choghadiya
/// by the clock and wakes at the end of each one, so it stays right even when
/// the app is not opened.
const widgetDataKey = 'gsv_widget';
const widgetAndroidName = 'GsvWidgetProvider';
const widgetQualifiedName = 'com.gsvpoems.gsv_poems.GsvWidgetProvider';

/// Seven days of widget text, ready to show (local digits, chosen language).
Future<Map<String, dynamic>> buildWidgetData(Place place, PoemLang lang, {DateTime? now}) async {
  await initializeDateFormatting();
  final today = now ?? DateTime.now();
  final l = lang.index;
  final where = placeLabel(place, lang);
  final days = <Map<String, dynamic>>[];
  for (var i = -1; i < 7; i++) {
    final d = DateTime(today.year, today.month, today.day).add(Duration(days: i));
    final p = panchangFor(d, place);
    final slots = [...p.dayChoghadiya, ...p.nightChoghadiya];
    final fests = festivalsOn(d, place).map((f) => f.names[l]).toList();
    days.add({
      'date': DateFormat('yyyy-MM-dd').format(d),
      'day': localDigits(d.day, lang),
      'month': localDigits(DateFormat('MMMM y', lang.name).format(d), lang),
      'weekday': vaarNames[d.weekday % 7][l],
      'tithi': dateLine(p, l),
      'festival': fests.join(' · '),
      'sun': '${tr('sunrise', lang)} ${clock(p.sunrise, lang)} · ${tr('sunset', lang)} ${clock(p.sunset, lang)}',
      'slots': [
        for (var k = 0; k < slots.length; k++)
          {
            's': slots[k].start.millisecondsSinceEpoch,
            'e': slots[k].end.millisecondsSinceEpoch,
            'name': '${tr('now_running', lang)}: ${choghadiyaNames[slots[k].kind]![l]} ${tr('choghadiya_one', lang)}',
            'q': slots[k].quality.name,
            'detail':
                '${qualityNames[slots[k].quality]![l]} · ${clock(slots[k].end, lang)} ${tr('till', lang)}'
                '${k + 1 < slots.length ? ' · ${tr('then', lang)} ${choghadiyaNames[slots[k + 1].kind]![l]}' : ''}',
          },
      ],
    });
  }
  return {'v': 1, 'place': where, 'days': days};
}

/// Recomputes the widget's week and asks Android to redraw it. Safe to call
/// anywhere (does nothing when no widget is placed or off Android).
Future<void> updateHomeScreenWidget(Place place, PoemLang lang) async {
  try {
    final data = await buildWidgetData(place, lang);
    await HomeWidget.saveWidgetData<String>(widgetDataKey, jsonEncode(data));
    await HomeWidget.updateWidget(androidName: widgetAndroidName, qualifiedAndroidName: widgetQualifiedName);
  } on Object {
    // No widget support here (tests, other platforms): nothing to update.
  }
}

/// Asks the launcher to place the widget on the home screen (Android 8+).
Future<bool> requestHomeScreenWidget() async {
  try {
    if (await HomeWidget.isRequestPinWidgetSupported() != true) return false;
    await HomeWidget.requestPinWidget(androidName: widgetAndroidName, qualifiedAndroidName: widgetQualifiedName);
    return true;
  } on Object {
    return false;
  }
}
