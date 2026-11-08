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
import '../sync/writer_gate.dart';

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
      if (!await ensureCanWrite(context, ref) || !context.mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditorScreen(poemId: p.id)));
    case 'share':
      await sharePoem(context, p);
    case 'bin':
      if (!await ensureCanWrite(context, ref) || !context.mounted) return;
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

/// Whether [p] belongs to the language filter (null = every language).
/// Gujarati also holds the few English pieces.
bool inLang(Poem p, PoemLang? lang) => switch (lang) {
  null => true,
  PoemLang.hi => p.lang == 'hi',
  _ => p.lang != 'hi',
};

/// The unit after a count: "૧૨ કવિતા" or "૧૨ લેખ".
String kindUnit(BuildContext context, String kind) => context.t(kind == Kind.prose ? 'prose_unit' : 'poems');

/// Writing at a glance. First the two kinds (Poems · Prose), then a language
/// filter (All · Gujarati · Hindi), "All poems", and one compact tile per
/// topic that holds something. Tapping a tile opens that topic on its own screen.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  String _kind = Kind.poem;
  PoemLang? _lang;

  void _open({PoemCategory? topic}) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TopicPoemsScreen(kind: _kind, lang: _lang, topicId: topic?.id),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final ui = context.lang;
    final allCats = ref.watch(categoriesProvider).asData?.value ?? const <PoemCategory>[];
    final every = ref.watch(poemsProvider((lang: null, categoryId: null, kind: _kind, sort: PoemSort.number))).asData?.value ?? const <Poem>[];
    final mine = every.where((p) => inLang(p, _lang)).toList();
    final stats = ref.watch(statsProvider).asData?.value ?? const PoemStats();
    final counts = <String, int>{};
    for (final p in mine) {
      final k = p.categoryId ?? 'other';
      counts[k] = (counts[k] ?? 0) + 1;
    }
    // Only topics that hold something here get a tile.
    final cats = allCats.where((t) => (counts[t.id] ?? 0) > 0).toList();
    // Topic names follow the chosen language's script.
    final nameLang = ui == PoemLang.en ? PoemLang.en : (_lang ?? ui);
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 600 ? 3 : 2;
    // Tiles grow with the text size, so two-line names are never cut off.
    final scaler = MediaQuery.textScalerOf(context);
    final tileHeight = 22 + scaler.scale(15) * 1.25 * 2 + scaler.scale(13) * 1.3;
    final unit = kindUnit(context, _kind);

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
                    IconButton(
                      tooltip: '${context.t('recycle_bin')} · ${localDigits(stats.inBin, ui)}',
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecycleBinScreen())),
                      icon: Badge(isLabelVisible: stats.inBin > 0, label: Text(localDigits(stats.inBin, ui)), child: const Icon3D('trash', size: 36)),
                    ),
                    const HelpButton('collection'),
                  ],
                ),
              ),
              // The two kinds of writing.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      minimumSize: const Size(48, 52),
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    segments: [
                      for (final k in Kind.all)
                        ButtonSegment(
                          value: k,
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('${context.t('kind_$k')} · ${localDigits(stats.of(k), ui)}', maxLines: 1),
                          ),
                        ),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
                  ),
                ),
              ),
              // Language filter.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final l in const [null, PoemLang.gu, PoemLang.hi])
                        ChoiceChip(
                          label: Text(
                            '${l == null ? context.t('lang_all') : tr('lang_${l.name}', l)} · ${localDigits(stats.of(_kind, lang: l?.name), ui)}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _lang == l ? c.onPrimary : c.ink),
                          ),
                          selected: _lang == l,
                          showCheckmark: false,
                          selectedColor: c.primary,
                          onSelected: (_) => setState(() => _lang = l),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: _TopicRow(
                    icon: _kind == Kind.prose ? 'write' : 'collection',
                    name: context.t(_kind == Kind.prose ? 'all_prose' : 'all_poems'),
                    count: '${localDigits(mine.length, ui)} $unit',
                    emphasised: true,
                    onTap: _open,
                  ),
                ),
              ),
              if (mine.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(icon: 'write', text: context.t(_kind == Kind.prose ? 'no_prose' : 'no_poems')),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: tileHeight,
                  ),
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final t = cats[i];
                    return _TopicRow(
                      icon: t.iconKey,
                      name: categoryName(t, nameLang),
                      count: '${localDigits(counts[t.id] ?? 0, ui)} $unit',
                      onTap: () => _open(topic: t),
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
                      onPressed: () async {
                        if (await ensureCanWrite(context, ref) && context.mounted) await addTopic(context, ref);
                      },
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

/// One compact, tappable topic: symbol, name (up to two lines), count and a chevron.
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
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: Row(
          children: [
            Icon3D(icon, size: 40),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: emphasised ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: emphasised ? 17 : 15, height: 1.2, fontWeight: FontWeight.w700, color: c.ink),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(count, maxLines: 1, style: TextStyle(fontSize: 13, color: c.mute)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.accentText),
          ],
        ),
      ),
    );
  }
}

/// The writing of one topic (or all of it) for one kind and language, with
/// sort and the usual "⋯" actions. Back returns to the topics.
class TopicPoemsScreen extends ConsumerStatefulWidget {
  const TopicPoemsScreen({super.key, this.kind = Kind.poem, this.lang, this.topicId});
  final String kind;

  /// Null shows every language.
  final PoemLang? lang;

  /// Null shows every topic.
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
    final poems = (ref.watch(poemsProvider((lang: null, categoryId: null, kind: widget.kind, sort: _sort))).asData?.value ?? const <Poem>[])
        .where((p) => inLang(p, widget.lang) && (widget.topicId == null || (p.categoryId ?? 'other') == widget.topicId))
        .toList();
    final nameLang = lang == PoemLang.en ? PoemLang.en : (widget.lang ?? lang);
    final title = topic == null ? context.t(widget.kind == Kind.prose ? 'all_prose' : 'all_poems') : categoryName(topic, nameLang);
    final langLabel = widget.lang == null ? context.t('lang_all') : tr('lang_${widget.lang!.name}', widget.lang!);
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
                  subtitle: '${context.t('kind_${widget.kind}')} · $langLabel · ${localDigits(poems.length, lang)} ${kindUnit(context, widget.kind)}',
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
                                              if (!await ensureCanWrite(context, ref)) return;
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
                                              if (!context.mounted || !await ensureCanWrite(context, ref)) return;
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
