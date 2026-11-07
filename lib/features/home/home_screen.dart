import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../core/widgets/moon_phase.dart';
import '../../core/widgets/neon_surface.dart';
import '../../data/db/database.dart';
import '../../data/poem_repository.dart';
import '../../core/panchang/astro.dart';
import '../../core/panchang/names.dart';
import '../../core/panchang/panchang.dart';
import '../calendar/calendar_screen.dart';
import '../common/poem_tile.dart';
import '../duplicates/duplicates_screen.dart';
import '../sync/drive_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onOpenCollection, required this.onWrite});
  final VoidCallback onOpenCollection;
  final VoidCallback onWrite;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _lang = 'gu';
  bool _recentAll = false;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final stats = ref.watch(statsProvider).asData?.value ?? const PoemStats();
    final recent = ref.watch(recentProvider).asData?.value ?? const <Poem>[];
    final favs = ref.watch(favoritesProvider).asData?.value ?? const <Poem>[];
    final langPoems = ref.watch(poemsProvider((lang: _lang, categoryId: null, sort: PoemSort.newest))).asData?.value ?? const <Poem>[];
    final onThisDay = ref.watch(onThisDayProvider).asData?.value ?? const <Poem>[];
    final lang = context.lang;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 140),
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/images/logo_source.webp', width: 46, height: 46, fit: BoxFit.cover, excludeFromSemantics: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('app_title'),
                          style: TextStyle(fontFamily: 'NotoSerifGujarati', fontSize: 22, fontWeight: FontWeight.w700, color: c.ink),
                        ),
                        Text(context.t('greeting'), style: TextStyle(fontSize: 14, color: c.mute)),
                      ],
                    ),
                  ),
                  const HelpButton('home'),
                ],
              ),
              const SizedBox(height: 16),
              _TodayCard(lang: lang),
              const SizedBox(height: 18),
              const _FestivalAlert(),
              const DuplicateNotice(),
              const DriveReconnectNotice(),
              const _UpcomingFestivals(),
              if (stats.total == 0)
                EmptyState(
                  icon: 'write',
                  text: context.t('no_poems'),
                  action: PrimaryButton(label: context.t('write_first'), onPressed: widget.onWrite),
                ),
              if (recent.isNotEmpty) ...[
                SectionTitle(
                  context.t('recent7'),
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await ref.read(prefsProvider.notifier).clearRecent();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('list_cleared'))));
                        },
                        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                        child: Text(
                          context.t('clear_list'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.primary),
                        ),
                      ),
                      if (recent.length > 5) ExpandArrow(expanded: _recentAll, onPressed: () => setState(() => _recentAll = !_recentAll)),
                    ],
                  ),
                ),
                // Five at first; the arrow shows up to seven.
                for (var i = 0; i < recent.length && i < (_recentAll ? 7 : 5); i++)
                  PoemTile(poem: recent[i], onTap: () => openPoem(context, recent, i)),
                const SizedBox(height: 14),
              ],
              if (stats.total > 0) ...[
                SectionTitle(context.t('favorites')),
                if (favs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Text(context.t('no_favorites'), style: TextStyle(fontSize: 16, color: c.mute)),
                  )
                else
                  SizedBox(
                    height: 176,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: favs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => _FavCard(poem: favs[i], onTap: () => openPoem(context, favs, i)),
                    ),
                  ),
                const SizedBox(height: 22),
                GsvCard(
                  radius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Stat(
                              value: localDigits(NumberFormat.decimalPattern('en_IN').format(stats.total), lang),
                              label: context.t('total_poems'),
                            ),
                          ),
                          Expanded(
                            child: _Stat(
                              value: localDigits(NumberFormat.decimalPattern('en_IN').format(stats.words), lang),
                              label: context.t('total_words'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          minimumSize: const Size(48, 52),
                          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        segments: [
                          ButtonSegment(value: 'gu', label: Text('${tr('lang_gu', PoemLang.gu)} · ${localDigits(stats.gu, lang)}')),
                          ButtonSegment(value: 'hi', label: Text('${tr('lang_hi', PoemLang.hi)} · ${localDigits(stats.hi, lang)}')),
                        ],
                        selected: {_lang},
                        onSelectionChanged: (s) => setState(() => _lang = s.first),
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < langPoems.length && i < 5; i++)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                          minTileHeight: 52,
                          title: Text(
                            poemTitle(langPoems[i]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: poemFont(langPoems[i].lang), fontSize: 18, color: c.ink),
                          ),
                          trailing: Icon(Icons.chevron_right_rounded, color: c.accent),
                          onTap: () => openPoem(context, langPoems, i),
                        ),
                      if (langPoems.length > 5)
                        TextButton(
                          onPressed: widget.onOpenCollection,
                          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                          child: Text(
                            '${context.t('all_poems')} →',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.primary),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _FeatureCard(
                  label: onThisDay.isNotEmpty
                      ? '${context.t('on_this_day')} · ${localDigits(onThisDay.first.createdAt.year, lang)}'
                      : context.t('poem_of_day'),
                  poems: onThisDay.isNotEmpty ? onThisDay : _poemOfDay(langPoems),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Poem> _poemOfDay(List<Poem> pool) {
    if (pool.isEmpty) return const [];
    final now = DateTime.now();
    final seed = now.year * 400 + now.month * 31 + now.day;
    return [pool[seed % pool.length]];
  }
}

/// Today's date in both calendars and the Choghadiya running now. Tap → Panchang.
class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.lang});
  final PoemLang lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gc;
    final now = ref.watch(minuteProvider).asData?.value ?? DateTime.now();
    final p = ref.watch(todayPanchangProvider);
    final l = lang.index;
    // Before sunrise the night Choghadiya of the previous day is still running.
    final before = now.isBefore(p.sunrise) ? panchangFor(now.subtract(const Duration(days: 1)), ref.watch(prefsProvider).place) : p;
    final ch = before.choghadiyaAt(now);
    final list = [...before.dayChoghadiya, ...before.nightChoghadiya];
    final nextCh = ch == null ? null : (list.indexOf(ch) + 1 < list.length ? list[list.indexOf(ch) + 1] : null);
    final loc = lang.name;
    final moonE = elongation(julianDay(now.toUtc()));
    // The day card is the screen's featured surface: the theme's signature
    // light plays around its moon when it appears and every few seconds.
    return NeonPressSurface(
      radius: 26,
      featured: true,
      focal: (s) => Offset(s.width - 51, 49),
      focalRadius: 36,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CalendarScreen())),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: RadialGradient(center: const Alignment(1, -1), radius: 1.6, colors: [c.heroA, c.heroB, c.heroC], stops: const [0, 0.45, 1]),
              boxShadow: [BoxShadow(color: c.heroC.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14))],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          localDigits(now.day, lang),
                          style: const TextStyle(
                            fontFamily: 'NotoSerifGujarati',
                            fontSize: 64,
                            height: 0.95,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localDigits(DateFormat('MMMM y', loc).format(now), lang),
                                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                Text(
                                  '${vaarNames[p.vaar][l]} · ${DateFormat('d MMM y', 'en').format(now)}',
                                  style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.85)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MoonPhase(
                              elongation: moonE,
                              size: 58,
                              glow: Colors.white,
                              semanticLabel:
                                  '${context.t('moon')}: ${localDigits((MoonPhase.litFraction(moonE) * 100).round(), lang)}% · ${context.t(moonE < 180 ? 'moon_waxing' : 'moon_waning')}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${localDigits((MoonPhase.litFraction(moonE) * 100).round(), lang)}%',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dateLine(p, l),
                      style: const TextStyle(fontFamily: 'NotoSerifGujarati', fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    Text(
                      '${context.t('vs')} ${localDigits(p.samvat, lang)} · ${context.t('nakshatra')}: ${nakshatraNames[p.nakshatra][l]}',
                      style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(height: 12),
                    if (ch != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: switch (ch.quality) {
                                  Quality.good => const Color(0xFF9BE3A5),
                                  Quality.neutral => const Color(0xFFBFD7FF),
                                  Quality.bad => const Color(0xFFFFB4A8),
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${context.t('now_running')}: ${choghadiyaNames[ch.kind]![l]} ${context.t('choghadiya_one')}',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                  Text(
                                    '${qualityNames[ch.quality]![l]} · ${clock(ch.end, lang)} ${context.t('till')}'
                                    '${nextCh == null ? '' : ' · ${context.t('then')} ${choghadiyaNames[nextCh.kind]![l]}'}',
                                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.white),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Tomorrow is Diwali" / "Today is Ekadashi" strip.
class _FestivalAlert extends ConsumerWidget {
  const _FestivalAlert();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gc;
    final l = context.lang.index;
    final today = ref.watch(todayPanchangProvider).date;
    final items = ref.watch(upcomingFestivalsProvider).where((f) => f.date.difference(today).inDays <= 1).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final first = items.first;
    final isToday = DateUtils.isSameDay(first.date, today);
    final names = items.where((f) => DateUtils.isSameDay(f.date, first.date)).map((f) => f.festival.names[l]).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.alertBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.alertBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Icon3D(first.festival.icon, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.t(isToday ? 'today_is' : 'tomorrow_is')} $names',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.ink),
                    ),
                    Text(
                      '${vaarNames[first.date.weekday % 7][l]} · ${localDigits(DateFormat('d MMMM', context.lang.name).format(first.date), context.lang)}',
                      style: TextStyle(fontSize: 15, color: c.mute),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The next festivals and vrat days (Purnima, Ekadashi, Chaturthi…).
class _UpcomingFestivals extends ConsumerStatefulWidget {
  const _UpcomingFestivals();

  @override
  ConsumerState<_UpcomingFestivals> createState() => _UpcomingFestivalsState();
}

class _UpcomingFestivalsState extends ConsumerState<_UpcomingFestivals> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lang = context.lang;
    final l = lang.index;
    final today = ref.watch(todayPanchangProvider).date;
    final every = ref.watch(upcomingFestivalsProvider).where((f) => !f.date.isBefore(today)).toList();
    // The next three; the arrow beside the title shows the rest.
    final items = _all ? every : every.take(3).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            context.t('upcoming_fest'),
            action: every.length > 3 ? ExpandArrow(expanded: _all, onPressed: () => setState(() => _all = !_all)) : null,
          ),
          GsvCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CalendarScreen(initial: items[i].date))),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: i == 0 ? null : Border(top: BorderSide(color: c.primary.withValues(alpha: 0.08))),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(14)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  localDigits(items[i].date.day, lang),
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1, color: c.ink),
                                ),
                                Text(DateFormat('MMM', lang.name).format(items[i].date), style: TextStyle(fontSize: 12.5, color: c.mute)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  items[i].festival.names[l],
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
                                ),
                                Text(
                                  '${vaarNames[items[i].date.weekday % 7][l]} · ${dateLine(panchangFor(items[i].date, ref.watch(prefsProvider).place), l)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14, color: c.mute),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: festivalColor(items[i].festival.kind)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.1, color: context.gc.ink),
      ),
      Text(label, style: TextStyle(fontSize: 15, color: context.gc.mute)),
    ],
  );
}

class _FavCard extends StatelessWidget {
  const _FavCard({required this.poem, required this.onTap});
  final Poem poem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lines = poem.body.split('\n').where((l) => l.trim().isNotEmpty).take(2).join('\n');
    return SizedBox(
      width: 210,
      child: GsvCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon3D('star', size: 34),
            const SizedBox(height: 4),
            Text(
              poemTitle(poem),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: poemFont(poem.lang), fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                lines,
                maxLines: 3,
                overflow: TextOverflow.fade,
                style: TextStyle(fontFamily: poemFont(poem.lang), fontSize: 15, height: 1.55, color: c.mute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.label, required this.poems});
  final String label;
  final List<Poem> poems;

  @override
  Widget build(BuildContext context) {
    if (poems.isEmpty) return const SizedBox.shrink();
    final c = context.gc;
    final p = poems.first;
    final lines = p.body.split('\n').where((l) => l.trim().isNotEmpty).take(3).join('\n');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: c.tint,
        border: Border.all(color: c.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: c.mute),
          ),
          const SizedBox(height: 6),
          Text(
            poemTitle(p),
            style: TextStyle(fontFamily: poemFont(p.lang), fontSize: 20, fontWeight: FontWeight.w700, color: c.ink),
          ),
          const SizedBox(height: 6),
          Text(
            lines,
            style: TextStyle(fontFamily: poemFont(p.lang), fontSize: 17, height: 1.8, color: c.ink),
          ),
          TextButton(
            onPressed: () => openPoem(context, poems, 0),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(48, 48)),
            child: Text(
              '${context.t('read_full')} →',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.primary),
            ),
          ),
        ],
      ),
    );
  }
}
