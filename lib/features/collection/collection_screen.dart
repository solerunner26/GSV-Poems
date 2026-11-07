import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/db/database.dart';
import '../../data/poem_repository.dart';
import '../common/poem_tile.dart';
import '../editor/editor_screen.dart';

/// Category tiles with counts, then every poem. "⋯" edits, shares or moves to the bin.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  String? _cat;
  PoemSort _sort = PoemSort.number;

  /// Gujarati or Hindi section. Starts on Hindi only when the interface is Hindi.
  PoemLang? _section;

  Future<void> _actions(Poem p) async {
    final repo = ref.read(repoProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon3D('edit', size: 44), title: Text(ctx.t('edit'), style: const TextStyle(fontSize: 18)), onTap: () => Navigator.pop(ctx, 'edit')),
          ListTile(leading: const Icon3D('share', size: 44), title: Text(ctx.t('share'), style: const TextStyle(fontSize: 18)), onTap: () => Navigator.pop(ctx, 'share')),
          ListTile(leading: const Icon3D('trash', size: 44), title: Text(ctx.t('delete'), style: const TextStyle(fontSize: 18)), onTap: () => Navigator.pop(ctx, 'bin')),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'edit':
        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditorScreen(poemId: p.id)));
      case 'share':
        await SharePlus.instance.share(ShareParams(text: '${poemTitle(p)}\n\n${p.body.trim()}\n\n— ${context.t('poet_name')}'));
      case 'bin':
        await repo.moveToBin(p.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${poemTitle(p)}" — ${context.t('moved_to_bin')}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: context.t('restore'), onPressed: () => repo.restoreFromBin(p.id)),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lang = context.lang;
    final section = _section ?? (lang == PoemLang.hi ? PoemLang.hi : PoemLang.gu);
    final allCats = ref.watch(categoriesProvider).asData?.value ?? const <PoemCategory>[];
    // Each section lists only its own language's poems (English poems sit with Gujarati).
    final all = (ref.watch(poemsProvider((lang: null, categoryId: null, sort: _sort))).asData?.value ?? const <Poem>[])
        .where((p) => section == PoemLang.hi ? p.lang == 'hi' : p.lang != 'hi')
        .toList();
    final stats = ref.watch(statsProvider).asData?.value ?? const PoemStats();
    final counts = <String, int>{};
    for (final p in all) {
      counts[p.categoryId ?? 'other'] = (counts[p.categoryId ?? 'other'] ?? 0) + 1;
    }
    // Collections that hold poems in this section, plus "Others" always.
    final cats = allCats.where((c) => (counts[c.id] ?? 0) > 0 || c.id == 'other').toList();
    final shown = _cat == null ? all : all.where((p) => (p.categoryId ?? 'other') == _cat).toList();
    // Collection names follow the section's script (जीवन मंथन in Hindi, જીવન મંથન in Gujarati).
    final nameLang = lang == PoemLang.en ? PoemLang.en : section;
    final cols = MediaQuery.sizeOf(context).width >= 600 ? 5 : 3;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: ScreenHeader(title: context.t('nav_collection'), actions: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecycleBinScreen())),
                  icon: const Icon3D('trash', size: 34),
                  label: Text('${context.t('recycle_bin')} · ${localDigits(stats.inBin, lang)}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.primary)),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                ),
                const HelpButton('collection'),
              ]),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: SegmentedButton<PoemLang>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(minimumSize: const Size(48, 54), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  segments: [
                    ButtonSegment(value: PoemLang.gu, label: Text('${tr('lang_gu', PoemLang.gu)} · ${localDigits(stats.gu + stats.en, lang)}')),
                    ButtonSegment(value: PoemLang.hi, label: Text('${tr('lang_hi', PoemLang.hi)} · ${localDigits(stats.hi, lang)}')),
                  ],
                  selected: {section},
                  onSelectionChanged: (s) => setState(() {
                    _section = s.first;
                    _cat = null;
                  }),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverGrid.count(
                crossAxisCount: cols,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
                children: [
                  for (final cat in cats)
                    _CatTile(
                      icon: cat.iconKey,
                      name: categoryName(cat, nameLang),
                      count: '${localDigits(counts[cat.id] ?? 0, lang)} ${context.t('poems')}',
                      selected: _cat == cat.id,
                      onTap: () => setState(() => _cat = _cat == cat.id ? null : cat.id),
                    ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      _cat == null
                          ? '${context.t('all_poems')} · ${localDigits(shown.length, lang)}'
                          : '${categoryName(allCats.firstWhere((x) => x.id == _cat), nameLang)} · ${localDigits(shown.length, lang)}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  PopupMenuButton<PoemSort>(
                    initialValue: _sort,
                    onSelected: (s) => setState(() => _sort = s),
                    itemBuilder: (_) => [
                      for (final s in PoemSort.values)
                        PopupMenuItem(value: s, child: Text(context.t('sort_${s.name}'), style: const TextStyle(fontSize: 17))),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text('${context.t('sort_${_sort.name}')} ▾', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.primary)),
                    ),
                  ),
                ]),
              ),
            ),
            if (shown.isEmpty) SliverToBoxAdapter(child: EmptyState(icon: 'collection', text: context.t('no_poems'))),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 140),
              sliver: SliverList.builder(
                itemCount: shown.length,
                itemBuilder: (_, i) => PoemTile(
                  poem: shown[i],
                  showNumber: true,
                  onTap: () => openPoem(context, shown, i),
                  trailing: IconButton(
                    tooltip: context.t('more'),
                    iconSize: 26,
                    color: c.primary,
                    onPressed: () => _actions(shown[i]),
                    icon: const Icon(Icons.more_horiz_rounded),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CatTile extends StatelessWidget {
  const _CatTile({required this.icon, required this.name, required this.count, required this.selected, required this.onTap});
  final String icon, name, count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Semantics(
      button: true,
      selected: selected,
      label: '$name, $count',
      excludeSemantics: true,
      child: Material(
        color: selected ? c.primary.withValues(alpha: 0.14) : c.surface,
        borderRadius: BorderRadius.circular(18),
        elevation: c.isDark ? 0 : 1.5,
        shadowColor: c.ink.withValues(alpha: 0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon3D(icon, size: 56),
            const SizedBox(height: 4),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
            Text(count, maxLines: 1, style: TextStyle(fontSize: 13, color: c.mute)),
          ]),
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
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.t('cancel'), style: const TextStyle(fontSize: 17))),
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
            child: Column(children: [
              ScreenHeader(back: true, title: context.t('recycle_bin'), subtitle: context.t('bin_note')),
              Expanded(
                child: bin.isEmpty
                    ? ListView(children: [EmptyState(icon: 'trash', text: context.t('bin_empty'))])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                        itemCount: bin.length,
                        itemBuilder: (_, i) {
                          final p = bin[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GsvCard(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(poemTitle(p), style: TextStyle(fontFamily: poemFont(p.lang), fontSize: 18, fontWeight: FontWeight.w700, color: c.ink)),
                                Text(friendlyDate(context, p.deletedAt ?? p.updatedAt), style: TextStyle(fontSize: 14, color: c.mute)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(minimumSize: const Size(48, 52), backgroundColor: c.primary, foregroundColor: c.onPrimary),
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
                                      if (await _confirm(context, 'confirm_forever') && context.mounted && await _confirm(context, 'confirm_forever2')) {
                                        await repo.deleteForever(p.id);
                                      }
                                    },
                                    child: Text(context.t('delete_forever'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
