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
import '../collection/collection_screen.dart';
import '../common/poem_tile.dart';
import '../duplicates/duplicates_screen.dart';
import '../profile/profile_screen.dart';
import '../sync/drive_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onOpenCollection, required this.onWrite});
  final VoidCallback onOpenCollection;
  final VoidCallback onWrite;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _recentAll = false;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final stats = ref.watch(statsProvider).asData?.value ?? const PoemStats();
    final recent = ref.watch(recentProvider).asData?.value ?? const <Poem>[];
    final favs = ref.watch(favoritesProvider).asData?.value ?? const <Poem>[];
    final allPoems = ref.watch(poemsProvider((lang: null, categoryId: null, kind: Kind.poem, sort: PoemSort.newest))).asData?.value ?? const <Poem>[];
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
                      ],
                    ),
                  ),
                  const ProfileButton(),
                ],
              ),
              const SizedBox(height: 16),
              _TodayCard(lang: lang),
              const SizedBox(height: 18),
              const _FestivalAlert(),
              const DuplicateNotice(),
              const DriveReconnectNotice(),
              const SyncKeyNotice(),
              const _UpcomingFestivals(),
              if (stats.total == 0)
                EmptyState(
                  icon: 'write',
                  text: context.t('no_poems'),
                  action: PrimaryButton(label: context.t('write_first'), onPressed: widget.onWrite),
                ),
              if (stats.total > 0) ...[
                // Counters: poems and prose; each number opens its list.
                const _Counters(),
                const SizedBox(height: 18),
              ],
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
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.primary),
                        ),
                      ),
                      if (recent.length > 2) ExpandArrow(expanded: _recentAll, onPressed: () => setState(() => _recentAll = !_recentAll)),
                    ],
                  ),
                ),
                // Two at first; the arrow shows up to seven.
                for (var i = 0; i < recent.length && i < (_recentAll ? 7 : 2); i++)
                  PoemTile(poem: recent[i], onTap: () => openPoem(context, recent, i)),
                const SizedBox(height: 12),
              ],
              if (stats.total > 0) ...[
                _FeatureCard(
                  label: onThisDay.isNotEmpty
                      ? '${context.t('on_this_day')} · ${localDigits(onThisDay.first.createdAt.year, lang)}'
                      : context.t('poem_of_day'),
                  poems: onThisDay.isNotEmpty ? onThisDay : _poemOfDay(allPoems),
                ),
                const SizedBox(height: 18),
                SectionTitle(context.t('favorites')),
                if (favs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Text(context.t('no_favorites'), style: TextStyle(fontSize: 15, color: c.mute)),
                  )
                else
                  SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: favs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => _FavChip(poem: favs[i], onTap: () => openPoem(context, favs, i)),
                    ),
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
                                    '${context.t('now_running')}: ${choghadiyaNames[ch.kind]![l]} ${context.t('choghadiya_one')} (${placeLabel(ref.watch(prefsProvider).place, lang)})',
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
              Icon3D(first.festival.icon, size: 56),
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
    // The next one; the arrow beside the title shows the rest.
    final items = _all ? every : every.take(1).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            context.t('upcoming_fest'),
            action: every.length > 1 ? ExpandArrow(expanded: _all, onPressed: () => setState(() => _all = !_all)) : null,
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
                            // Grows with the text size, never cuts the date.
                            constraints: const BoxConstraints(minWidth: 54, minHeight: 54),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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

/// Poems and prose at a glance. Each big number opens that whole list; the
/// small language counts open that language only.
class _Counters extends ConsumerWidget {
  const _Counters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gc;
    final lang = context.lang;
    final stats = ref.watch(statsProvider).asData?.value ?? const PoemStats();
    String n(int v) => localDigits(NumberFormat.decimalPattern('en_IN').format(v), lang);
    void open(String kind, [PoemLang? l]) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TopicPoemsScreen(kind: kind, lang: l),
      ),
    );

    Widget counter(String kind) => Expanded(
      child: GsvCard(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
        onTap: () => open(kind),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                n(stats.of(kind)),
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.1, color: c.ink),
              ),
            ),
            Text(
              context.t(kind == Kind.prose ? 'total_prose' : 'total_poems'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.mute),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 2,
              children: [
                for (final l in const [PoemLang.gu, PoemLang.hi])
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => open(kind, l),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      child: Text(
                        '${tr('lang_${l.name}', l)} ${n(stats.of(kind, lang: l.name))}',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.accentText),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [counter(Kind.poem), const SizedBox(width: 10), counter(Kind.prose)]),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text('${n(stats.words)} ${context.t('total_words')}', style: TextStyle(fontSize: 13.5, color: c.mute)),
        ),
      ],
    );
  }
}

/// A favourite in one compact line.
class _FavChip extends StatelessWidget {
  const _FavChip({required this.poem, required this.onTap});
  final Poem poem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: GsvCard(
        onTap: onTap,
        radius: 16,
        padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon3D('star', size: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                poemTitle(poem),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: poemFont(poem.lang), fontSize: 15.5, fontWeight: FontWeight.w700, color: c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's poem in one compact card: label, title and the first line.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.label, required this.poems});
  final String label;
  final List<Poem> poems;

  @override
  Widget build(BuildContext context) {
    if (poems.isEmpty) return const SizedBox.shrink();
    final c = context.gc;
    final p = poems.first;
    final first = p.body.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    return GsvCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      onTap: () => openPoem(context, poems, 0),
      child: Row(
        children: [
          const Icon3D('lotus', size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.accentText),
                ),
                Text(
                  poemTitle(p),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: poemFont(p.lang), fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
                ),
                if (first.trim().isNotEmpty && first.trim() != poemTitle(p))
                  Text(
                    first.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: poemFont(p.lang), fontSize: 14.5, color: c.mute),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: c.accentText),
        ],
      ),
    );
  }
}
