import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/db/database.dart';
import '../common/poem_tile.dart';

final duplicateGroupsProvider = FutureProvider.autoDispose<List<List<Poem>>>((ref) {
  ref.watch(duplicateCountProvider);
  return ref.watch(repoProvider).duplicateGroups();
});

/// Every poem that appears more than once. Nothing is removed until the poet
/// taps "Keep this one" for a group; the extra copies go to the recycle bin.
class DuplicatesScreen extends ConsumerWidget {
  const DuplicatesScreen({super.key});

  Future<void> _removeAll(BuildContext context, WidgetRef ref, List<List<Poem>> groups) async {
    final extra = groups.fold<int>(0, (n, g) => n + g.length - 1);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.t('dup_remove_all')),
        content: Text('${localDigits(extra, ctx.lang)} ${ctx.t('dup_remove_all_body')}', style: const TextStyle(fontSize: 17, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.t('cancel'), style: const TextStyle(fontSize: 17)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.t('dup_yes'), style: const TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final repo = ref.read(repoProvider);
    var moved = 0;
    for (final g in groups) {
      moved += await repo.removeDuplicates(g);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${localDigits(moved, context.lang)} ${context.t('dup_moved')}')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gc;
    final lang = context.lang;
    final groups = ref.watch(duplicateGroupsProvider).asData?.value;
    final cats = {for (final x in ref.watch(categoriesProvider).asData?.value ?? const <PoemCategory>[]) x.id: x};
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                ScreenHeader(back: true, title: context.t('dup_title'), subtitle: context.t('dup_note')),
                Expanded(
                  child: groups == null
                      ? const Center(child: CircularProgressIndicator())
                      : groups.isEmpty
                      ? ListView(
                          children: [EmptyState(icon: 'check', text: context.t('dup_none'))],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                          children: [
                            PrimaryButton(label: context.t('dup_remove_all'), icon: 'trash', onPressed: () => _removeAll(context, ref, groups)),
                            const SizedBox(height: 16),
                            for (final g in groups)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: GsvCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon3D('collection', size: 44),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              poemTitle(g.first),
                                              style: TextStyle(
                                                fontFamily: poemFont(g.first.lang),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: c.ink,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '× ${localDigits(g.length, lang)}',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.accentText),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      for (final p in g)
                                        Container(
                                          margin: const EdgeInsets.only(top: 6),
                                          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                                          decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(14)),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () => openPoem(context, g, g.indexOf(p)),
                                                  child: Text(
                                                    [
                                                      if (cats[p.categoryId] != null) categoryName(cats[p.categoryId]!, lang),
                                                      if (p.number != null) '#${localDigits(p.number!, lang)}',
                                                      friendlyDate(context, p.createdAt),
                                                    ].join(' · '),
                                                    style: TextStyle(fontSize: 15, color: c.ink),
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
                                                onPressed: () => ref.read(repoProvider).removeDuplicates(g, keepId: p.id),
                                                child: Text(
                                                  context.t('dup_keep_this'),
                                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.primary),
                                                ),
                                              ),
                                            ],
                                          ),
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
          ),
        ),
      ),
    );
  }
}

/// Orange notice shown on Home and after an import when duplicates exist.
class DuplicateNotice extends ConsumerWidget {
  const DuplicateNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(duplicateCountProvider).asData?.value ?? 0;
    if (n == 0) return const SizedBox.shrink();
    final c = context.gc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: c.alertBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DuplicatesScreen())),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.alertBorder, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon3D('collection', size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${localDigits(n, context.lang)} ${context.t('dup_found')}',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
                      ),
                      Text(context.t('dup_review'), style: TextStyle(fontSize: 15, color: c.mute)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: c.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
