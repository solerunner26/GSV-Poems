import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/db/database.dart';
import '../../data/poem_repository.dart';
import '../common/new_topic_sheet.dart';
import '../common/poem_share.dart';
import '../common/poem_tile.dart';
import '../editor/editor_screen.dart';

/// "⋯" on a poem: edit, share or move to the recycle bin.
Future<void> poemActions(BuildContext context, WidgetRef ref, Poem p) async {
  final repo = ref.read(repoProvider);
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon3D('edit', size: 44),
            title: Text(ctx.t('edit'), style: const TextStyle(fontSize: 18)),
            onTap: () => Navigator.pop(ctx, 'edit'),
          ),
          ListTile(
            leading: const Icon3D('share', size: 44),
            title: Text(ctx.t('share'), style: const TextStyle(fontSize: 18)),
            onTap: () => Navigator.pop(ctx, 'share'),
          ),
          ListTile(
            leading: const Icon3D('trash', size: 44),
            title: Text(ctx.t('delete'), style: const TextStyle(fontSize: 18)),
            onTap: () => Navigator.pop(ctx, 'bin'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case 'edit':
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditorScreen(poemId: p.id)));
    case 'share':
      await sharePoem(context, p);
    case 'bin':
      await repo.moveToBin(p.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${poemTitle(p)}" — ${context.t('moved_to_bin')}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: context.t('restore'), onPressed: () => repo.restoreFromBin(p.id)),
        ),
      );
  }
}

bool _inSection(Poem p, PoemLang section) => section == PoemLang.hi ? p.lang == 'hi' : p.lang != 'hi';

/// Topics at a glance: a Gujarati / Hindi switch, "All poems", then one compact
/// row per topic. Tapping a row opens that topic on its own screen.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  /// Gujarati or Hindi section. Starts on Hindi only when the interface is Hindi.
  PoemLang? _section;

  void _open(PoemLang section, {PoemCategory? topic}) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TopicPoemsScreen(section: section, topicId: topic?.id),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lang = context.lang;
    final section = _section ?? (lang == PoemLang.hi ? PoemLang.hi : PoemLang.gu);
    final allCats = ref.watch(categoriesProvider).asData?.value ?? const <PoemCategory>[];
    final every = ref.watch(poemsProvider((lang: null, categoryId: null, sort: PoemSort.number))).asData?.value ?? const <Poem>[];
    final mine = every.where((p) => _inSection(p, section)).toList();
    final stats = ref.watch(statsProvider).asData?.value ?? const PoemStats();
    final counts = <String, int>{}, anyCounts = <String, int>{};
    for (final p in every) {
      final k = p.categoryId ?? 'other';
      anyCounts[k] = (anyCounts[k] ?? 0) + 1;
      if (_inSection(p, section)) counts[k] = (counts[k] ?? 0) + 1;
    }
    // Topics with poems in this section, new empty topics, and Others.
    final cats = allCats.where((t) => (counts[t.id] ?? 0) > 0 || (anyCounts[t.id] ?? 0) == 0 || t.id == 'other').toList();
    // Names follow the section's script (जीवन मंथन in Hindi, જીવન મંથન in Gujarati).
    final nameLang = lang == PoemLang.en ? PoemLang.en : section;
    final cols = MediaQuery.sizeOf(context).width >= 600 ? 3 : 2;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeader(
                  title: context.t('nav_collection'),
                  actions: [
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecycleBinScreen())),
                      icon: const Icon3D('trash', size: 34),
                      label: Text(
                        '${context.t('recycle_bin')} · ${localDigits(stats.inBin, lang)}',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.primary),
                      ),
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    ),
                    const HelpButton('collection'),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: SegmentedButton<PoemLang>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      minimumSize: const Size(48, 54),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    segments: [
                      ButtonSegment(value: PoemLang.gu, label: Text('${tr('lang_gu', PoemLang.gu)} · ${localDigits(stats.gu + stats.en, lang)}')),
                      ButtonSegment(value: PoemLang.hi, label: Text('${tr('lang_hi', PoemLang.hi)} · ${localDigits(stats.hi, lang)}')),
                    ],
                    selected: {section},
                    onSelectionChanged: (s) => setState(() => _section = s.first),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: _TopicRow(
                    icon: 'collection',
                    name: context.t('all_poems'),
                    count: '${localDigits(mine.length, lang)} ${context.t('poems')}',
                    emphasised: true,
                    onTap: () => _open(section),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 76,
                  ),
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final t = cats[i];
                    return _TopicRow(
                      icon: t.iconKey,
                      name: categoryName(t, nameLang),
                      count: '${localDigits(counts[t.id] ?? 0, lang)} ${context.t('poems')}',
                      onTap: () => _open(section, topic: t),
                    );
                  }, childCount: cats.length),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 140),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => addTopic(context, ref),
                      icon: Icon(Icons.add_rounded, color: c.primary),
                      label: Text(
                        context.t('topic_new'),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.primary),
                      ),
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One compact, tappable topic: symbol, name, count and a chevron.
class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.icon, required this.name, required this.count, required this.onTap, this.emphasised = false});
  final String icon, name, count;
  final VoidCallback onTap;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Semantics(
      button: true,
      label: '$name, $count',
      excludeSemantics: true,
      child: GsvCard(
        onTap: onTap,
        radius: 18,
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        child: Row(
          children: [
            Icon3D(icon, size: 48),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: emphasised ? 17 : 16, fontWeight: FontWeight.w700, color: c.ink),
                  ),
                  Text(count, maxLines: 1, style: TextStyle(fontSize: 13.5, color: c.mute)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.accentText),
          ],
        ),
      ),
    );
  }
}

/// The poems of one topic (or all poems) in one language section, with sort
/// and the usual "⋯" actions. Back returns to the topics.
class TopicPoemsScreen extends ConsumerStatefulWidget {
  const TopicPoemsScreen({super.key, required this.section, this.topicId});
  final PoemLang section;

  /// Null shows every poem of the section.
  final String? topicId;

  @override
  ConsumerState<TopicPoemsScreen> createState() => _TopicPoemsScreenState();
}

class _TopicPoemsScreenState extends ConsumerState<TopicPoemsScreen> {
  PoemSort _sort = PoemSort.number;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lang = context.lang;
    final cats = ref.watch(categoriesProvider).asData?.value ?? const <PoemCategory>[];
    PoemCategory? topic;
    for (final t in cats) {
      if (t.id == widget.topicId) topic = t;
    }
    final poems = (ref.watch(poemsProvider((lang: null, categoryId: null, sort: _sort))).asData?.value ?? const <Poem>[])
        .where((p) => _inSection(p, widget.section) && (widget.topicId == null || (p.categoryId ?? 'other') == widget.topicId))
        .toList();
    final nameLang = lang == PoemLang.en ? PoemLang.en : widget.section;
    final title = topic == null ? context.t('all_poems') : categoryName(topic, nameLang);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                ScreenHeader(
                  back: true,
                  title: title,
                  subtitle: '${tr('lang_${widget.section.name}', widget.section)} · ${localDigits(poems.length, lang)} ${context.t('poems')}',
                  actions: [
                    PopupMenuButton<PoemSort>(
                      initialValue: _sort,
                      tooltip: context.t('sort_${_sort.name}'),
                      onSelected: (s) => setState(() => _sort = s),
                      itemBuilder: (_) => [
                        for (final s in PoemSort.values)
                          PopupMenuItem(
                            value: s,
                            child: Text(context.t('sort_${s.name}'), style: const TextStyle(fontSize: 17)),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.sort_rounded, color: c.primary, size: 28),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: poems.isEmpty
                      ? ListView(
                          children: [EmptyState(icon: topic?.iconKey ?? 'collection', text: context.t('no_poems'))],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                          itemCount: poems.length,
                          itemBuilder: (_, i) => PoemTile(
                            poem: poems[i],
                            showNumber: true,
                            onTap: () => openPoem(context, poems, i),
                            trailing: IconButton(
                              tooltip: context.t('more'),
                              iconSize: 26,
                              color: c.primary,
                              onPressed: () => poemActions(context, ref, poems[i]),
                              icon: const Icon(Icons.more_horiz_rounded),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Deleted poems. "Restore" brings one back; "Delete forever" asks twice.
class RecycleBinScreen extends ConsumerWidget {
  const RecycleBinScreen({super.key});

  Future<bool> _confirm(BuildContext context, String key) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.t('delete_forever')),
          content: Text(ctx.t(key), style: const TextStyle(fontSize: 17, height: 1.5)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.t('cancel'), style: const TextStyle(fontSize: 17)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: GsvColors.bad),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.t('yes_delete'), style: const TextStyle(fontSize: 17)),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gc;
    final bin = ref.watch(binProvider).asData?.value ?? const <Poem>[];
    final repo = ref.read(repoProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                ScreenHeader(back: true, title: context.t('recycle_bin'), subtitle: context.t('bin_note')),
                Expanded(
                  child: bin.isEmpty
                      ? ListView(
                          children: [EmptyState(icon: 'trash', text: context.t('bin_empty'))],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                          itemCount: bin.length,
                          itemBuilder: (_, i) {
                            final p = bin[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GsvCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      poemTitle(p),
                                      style: TextStyle(fontFamily: poemFont(p.lang), fontSize: 18, fontWeight: FontWeight.w700, color: c.ink),
                                    ),
                                    Text(friendlyDate(context, p.deletedAt ?? p.updatedAt), style: TextStyle(fontSize: 14, color: c.mute)),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(48, 52),
                                              backgroundColor: c.primary,
                                              foregroundColor: c.onPrimary,
                                            ),
                                            onPressed: () async {
                                              await repo.restoreFromBin(p.id);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('restored'))));
                                              }
                                            },
                                            icon: const Icon3D('restore', size: 32),
                                            label: Text(context.t('restore'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        TextButton(
                                          style: TextButton.styleFrom(minimumSize: const Size(48, 52), foregroundColor: GsvColors.bad),
                                          onPressed: () async {
                                            if (await _confirm(context, 'confirm_forever') &&
                                                context.mounted &&
                                                await _confirm(context, 'confirm_forever2')) {
                                              await repo.deleteForever(p.id);
                                            }
                                          },
                                          child: Text(context.t('delete_forever'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
