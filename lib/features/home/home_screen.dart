import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/db/database.dart';
import '../../data/poem_repository.dart';
import '../common/poem_tile.dart';
import '../duplicates/duplicates_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.onOpenCollection, required this.onWrite});
  final VoidCallback onOpenCollection;
  final VoidCallback onWrite;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _lang = 'gu';

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
              Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/logo_source.webp', width: 46, height: 46, fit: BoxFit.cover, excludeFromSemantics: true),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(context.t('app_title'),
                        style: TextStyle(fontFamily: 'NotoSerifGujarati', fontSize: 22, fontWeight: FontWeight.w700, color: c.ink)),
                    Text(context.t('greeting'), style: TextStyle(fontSize: 14, color: c.mute)),
                  ]),
                ),
                const HelpButton('home'),
              ]),
              const SizedBox(height: 16),
              _TodayCard(lang: lang),
              const SizedBox(height: 22),
              const DuplicateNotice(),
              if (stats.total == 0)
                EmptyState(
                  icon: 'write',
                  text: context.t('no_poems'),
                  action: PrimaryButton(label: context.t('write_first'), onPressed: widget.onWrite),
                ),
              if (recent.isNotEmpty) ...[
                SectionTitle(
                  context.t('recent7'),
                  action: TextButton(
                    onPressed: () async {
                      await ref.read(prefsProvider.notifier).clearRecent();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('list_cleared'))));
                    },
                    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    child: Text(context.t('clear_list'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.primary)),
                  ),
                ),
                for (var i = 0; i < recent.length && i < 7; i++) PoemTile(poem: recent[i], onTap: () => openPoem(context, recent, i)),
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(child: _Stat(value: localDigits(NumberFormat.decimalPattern('en_IN').format(stats.total), lang), label: context.t('total_poems'))),
                      Expanded(child: _Stat(value: localDigits(NumberFormat.decimalPattern('en_IN').format(stats.words), lang), label: context.t('total_words'))),
                    ]),
                    const SizedBox(height: 14),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(minimumSize: const Size(48, 52), textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
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
                        title: Text(poemTitle(langPoems[i]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: poemFont(langPoems[i].lang), fontSize: 18, color: c.ink)),
                        trailing: Icon(Icons.chevron_right_rounded, color: c.accent),
                        onTap: () => openPoem(context, langPoems, i),
                      ),
                    if (langPoems.length > 5)
                      TextButton(
                        onPressed: widget.onOpenCollection,
                        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                        child: Text('${context.t('all_poems')} →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.primary)),
                      ),
                  ]),
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

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.lang});
  final PoemLang lang;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final now = DateTime.now();
    final loc = lang.name;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: RadialGradient(center: const Alignment(1, -1), radius: 1.6, colors: [c.heroA, c.heroB, c.heroC], stops: const [0, 0.45, 1]),
        boxShadow: [BoxShadow(color: c.heroC.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14))],
      ),
      child: Stack(children: [
        const Positioned(right: -8, top: -8, child: Opacity(opacity: 0.22, child: Icon3D('lotus', size: 90))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(localDigits(now.day, lang),
                style: const TextStyle(fontFamily: 'NotoSerifGujarati', fontSize: 64, height: 0.95, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(localDigits(DateFormat('MMMM y', loc).format(now), lang),
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('${DateFormat('EEEE', loc).format(now)} · ${DateFormat('d MMM y', 'en').format(now)}',
                      style: const TextStyle(fontSize: 15, color: Color(0xFFD6ECEA))),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Row(children: [
              const Icon3D('calendar', size: 36),
              const SizedBox(width: 10),
              Expanded(child: Text(context.t('panchang_soon'), style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600))),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.1, color: context.gc.ink)),
        Text(label, style: TextStyle(fontSize: 15, color: context.gc.mute)),
      ]);
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon3D('star', size: 34),
          const SizedBox(height: 4),
          Text(poemTitle(poem),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: poemFont(poem.lang), fontSize: 17, fontWeight: FontWeight.w700, color: c.ink)),
          const SizedBox(height: 2),
          Expanded(
            child: Text(lines,
                maxLines: 3,
                overflow: TextOverflow.fade,
                style: TextStyle(fontFamily: poemFont(poem.lang), fontSize: 15, height: 1.55, color: c.mute)),
          ),
        ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: c.mute)),
        const SizedBox(height: 6),
        Text(poemTitle(p), style: TextStyle(fontFamily: poemFont(p.lang), fontSize: 20, fontWeight: FontWeight.w700, color: c.ink)),
        const SizedBox(height: 6),
        Text(lines, style: TextStyle(fontFamily: poemFont(p.lang), fontSize: 17, height: 1.8, color: c.ink)),
        TextButton(
          onPressed: () => openPoem(context, poems, 0),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(48, 48)),
          child: Text('${context.t('read_full')} →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.primary)),
        ),
      ]),
    );
  }
}
