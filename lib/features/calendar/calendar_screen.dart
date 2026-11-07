import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/panchang/festivals.dart';
import '../../core/panchang/names.dart';
import '../../core/panchang/panchang.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import 'location.dart';

/// "6:53 AM" in the interface language's digits.
String clock(DateTime t, PoemLang lang) => localDigits(DateFormat('h:mm a', 'en').format(t), lang);

Color qualityColor(Quality q) => switch (q) {
  Quality.good => GsvColors.good,
  Quality.neutral => GsvColors.neutral,
  Quality.bad => GsvColors.bad,
};

Color festivalColor(FestivalKind k) => switch (k) {
  FestivalKind.festival => const Color(0xFFB9520A),
  FestivalKind.ekadashi => const Color(0xFF2F5A3C),
  FestivalKind.purnima => const Color(0xFF283A70),
  FestivalKind.amavasya => const Color(0xFF4F6664),
  FestivalKind.chaturthi => const Color(0xFF7A2E5C),
};

/// Bottom sheet: GPS once, or pick a city.
Future<void> choosePlace(BuildContext context, WidgetRef ref) async {
  final notifier = ref.read(prefsProvider.notifier);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.75,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(ctx.t('place'), style: Theme.of(ctx).textTheme.titleLarge),
            Text(ctx.t('place_note'), style: TextStyle(fontSize: 15, color: ctx.gc.mute)),
            const SizedBox(height: 12),
            PrimaryButton(
              label: ctx.t('use_gps'),
              icon: 'location',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(ctx);
                final failed = ctx.t('gps_failed'), done = ctx.t('place_set');
                final p = await placeFromGps();
                if (p == null) {
                  messenger.showSnackBar(SnackBar(content: Text(failed)));
                  return;
                }
                await notifier.setPlace(p);
                if (ctx.mounted) Navigator.pop(ctx);
                messenger.showSnackBar(SnackBar(content: Text('$done: ${p.name}')));
              },
            ),
            const SizedBox(height: 8),
            for (final c in cities)
              ListTile(
                minTileHeight: 56,
                leading: const Icon3D('location', size: 44),
                title: Text(c.$1[ctx.lang.index], style: const TextStyle(fontSize: 18)),
                onTap: () {
                  notifier.setPlace(Place(c.$1[2], c.$2, c.$3));
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

String placeLabel(Place p, PoemLang lang) {
  for (final c in cities) {
    if (c.$1[2] == p.name) return c.$1[lang.index];
  }
  return p.name;
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.initial});
  final DateTime? initial;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;
  bool _night = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initial ?? DateTime.now();
    _selected = DateTime(d.year, d.month, d.day);
    _month = DateTime(d.year, d.month);
  }

  void _goToday() {
    final n = DateTime.now();
    setState(() {
      _selected = DateTime(n.year, n.month, n.day);
      _month = DateTime(n.year, n.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lang = context.lang;
    final l = lang.index;
    final place = ref.watch(prefsProvider.select((p) => p.place));
    final now = ref.watch(minuteProvider).asData?.value ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final p = panchangFor(_selected, place);
    final fests = festivalsOn(_selected, place);
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final lead = DateTime(_month.year, _month.month).weekday % 7; // Sunday first
    final firstP = panchangFor(_month, place);
    final lastP = panchangFor(DateTime(_month.year, _month.month, days), place);
    final monthSpan = firstP.month.index == lastP.month.index
        ? monthNames[firstP.month.index][l]
        : '${monthNames[firstP.month.index][l]} – ${monthNames[lastP.month.index][l]}';
    final samvatSpan = firstP.samvat == lastP.samvat
        ? localDigits(firstP.samvat, lang)
        : '${localDigits(firstP.samvat, lang)} / ${localDigits(lastP.samvat, lang)}';
    final chog = _night ? p.nightChoghadiya : p.dayChoghadiya;

    Widget row(String k, String v) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: TextStyle(fontSize: 13, color: c.mute)),
          Text(
            v,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
          ),
        ],
      ),
    );
    String ends(DateTime t) =>
        '${DateUtils.isSameDay(t, _selected) ? '' : '${localDigits(t.day, lang)} ${DateFormat('MMM', lang.name).format(t)} '}${clock(t, lang)} ${context.t('till')}';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                ScreenHeader(
                  back: true,
                  title: context.t('panchang'),
                  actions: [
                    TextButton(
                      onPressed: _goToday,
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                      child: Text(
                        context.t('today_btn'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.primary),
                      ),
                    ),
                    const HelpButton('calendar'),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => choosePlace(context, ref),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon3D('location', size: 32),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  placeLabel(place, lang),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
                                ),
                              ),
                              Text(
                                context.t('change'),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      GsvCard(
                        padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: '‹',
                                  iconSize: 30,
                                  color: c.primary,
                                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                                  icon: const Icon(Icons.chevron_left_rounded),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        localDigits(DateFormat('MMMM y', lang.name).format(_month), lang),
                                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: c.ink),
                                      ),
                                      Text(
                                        '$monthSpan · ${context.t('vs')} $samvatSpan',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, color: c.mute),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: '›',
                                  iconSize: 30,
                                  color: c.primary,
                                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                                  icon: const Icon(Icons.chevron_right_rounded),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                for (var w = 0; w < 7; w++)
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        vaarNames[w][l].characters.take(lang == PoemLang.en ? 3 : 2).toString(),
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: w == 0 ? GsvColors.bad : c.mute),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            GridView.count(
                              crossAxisCount: 7,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 0.74,
                              children: [
                                for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                                for (var d = 1; d <= days; d++) _dayCell(DateTime(_month.year, _month.month, d), place, today, lang),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      GsvCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vaarNames[p.vaar][l]} · ${localDigits(DateFormat('d MMMM y', lang.name).format(_selected), lang)}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.mute),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateLine(p, l),
                              style: TextStyle(fontFamily: 'NotoSerifGujarati', fontSize: 22, fontWeight: FontWeight.w700, color: c.ink),
                            ),
                            Text(
                              '${context.t('vs')} ${localDigits(p.samvat, lang)}${p.month.adhik ? ' · ${context.t('adhik_month')}' : ''}',
                              style: TextStyle(fontSize: 14, color: c.mute),
                            ),
                            if (fests.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final f in fests)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(color: festivalColor(f.kind), borderRadius: BorderRadius.circular(999)),
                                      child: Text(
                                        f.names[l],
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(children: [row(context.t('tithi'), '${tithiName(p.tithi, l)} · ${ends(p.tithiEnds)}')]),
                            const SizedBox(height: 8),
                            Row(children: [row(context.t('nakshatra'), '${nakshatraNames[p.nakshatra][l]} · ${ends(p.nakshatraEnds)}')]),
                            const SizedBox(height: 8),
                            Row(children: [row(context.t('yoga'), yogaNames[p.yoga][l]), row(context.t('karana'), karanaNames[p.karana][l])]),
                            const SizedBox(height: 8),
                            Row(children: [row(context.t('sunrise'), clock(p.sunrise, lang)), row(context.t('sunset'), clock(p.sunset, lang))]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      GsvCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(context.t('choghadiya'), style: Theme.of(context).textTheme.titleLarge)),
                                SegmentedButton<bool>(
                                  showSelectedIcon: false,
                                  style: SegmentedButton.styleFrom(minimumSize: const Size(48, 44)),
                                  segments: [
                                    ButtonSegment(
                                      value: false,
                                      label: Text(context.t('day'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                    ),
                                    ButtonSegment(
                                      value: true,
                                      label: Text(context.t('night'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                  selected: {_night},
                                  onSelectionChanged: (s) => setState(() => _night = s.first),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final ch in chog)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: ch.contains(now) ? qualityColor(ch.quality).withValues(alpha: 0.14) : c.bg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: ch.contains(now) ? Border.all(color: qualityColor(ch.quality), width: 2) : null,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 150,
                                      child: Text('${clock(ch.start, lang)} – ${clock(ch.end, lang)}', style: TextStyle(fontSize: 15, color: c.ink)),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${choghadiyaNames[ch.kind]![l]}${ch.contains(now) ? ' · ${context.t('now_running')}' : ''}',
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: qualityColor(ch.quality), borderRadius: BorderRadius.circular(999)),
                                      child: Text(
                                        qualityNames[ch.quality]![l],
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dayCell(DateTime d, Place place, DateTime today, PoemLang lang) {
    final c = context.gc;
    final p = panchangFor(d, place);
    final f = festivalsOn(d, place);
    final selected = DateUtils.isSameDay(d, _selected);
    final isToday = DateUtils.isSameDay(d, today);
    final tithiShort = p.tithi == 15 || p.tithi == 30
        ? tithiName(p.tithi, lang.index)
        : '${pakshaNames[p.shukla ? 0 : 1][lang.index].characters.first} ${localDigits(p.tithiInPaksha, lang)}';
    return Semantics(
      button: true,
      selected: selected,
      label: '${d.day}, ${dateLine(p, lang.index)}${f.isEmpty ? '' : ', ${f.map((x) => x.names[lang.index]).join(', ')}'}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selected = d),
        child: Container(
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: selected ? c.primary : (isToday ? c.accent.withValues(alpha: 0.18) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                localDigits(d.day, lang),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.1, color: selected ? c.onPrimary : c.ink),
              ),
              Text(
                tithiShort,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(fontSize: 10.5, height: 1.2, color: selected ? c.onPrimary.withValues(alpha: 0.85) : c.mute),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final x in f.take(3))
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: festivalColor(x.kind)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
