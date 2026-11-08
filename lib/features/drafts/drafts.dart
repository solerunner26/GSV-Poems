import 'dart:async';

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
import '../editor/editor_screen.dart';
import '../sync/library_screen.dart';
import '../sync/writer_gate.dart';

/// The small red mark that asks for attention to unfinished work.
class AttentionDot extends StatelessWidget {
  const AttentionDot({super.key, this.size = 10});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: GsvColors.bad,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: GsvColors.bad.withValues(alpha: 0.6), blurRadius: size * 0.8)],
    ),
  );
}

Future<void> _publish(BuildContext context, WidgetRef ref, Poem p) async {
  if (!await ensureCanWrite(context, ref) || !context.mounted) return;
  await ref.read(repoProvider).publishDraft(p.id);
  unawaited(ref.read(libraryProvider).quiet());
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('draft_published'))));
}

Future<void> _edit(BuildContext context, WidgetRef ref, Poem p) async {
  if (!await ensureCanWrite(context, ref) || !context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditorScreen(poemId: p.id)));
}

Future<void> _delete(BuildContext context, WidgetRef ref, Poem p) async {
  if (!await ensureCanWrite(context, ref) || !context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.t('draft_delete_q')),
      content: Text(poemTitle(p), style: TextStyle(fontFamily: poemFont(p.lang), fontSize: 18)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.t('cancel'), style: const TextStyle(fontSize: 17)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: GsvColors.bad),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.t('draft_delete'), style: const TextStyle(fontSize: 17)),
        ),
      ],
    ),
  );
  if (ok != true) return;
  final repo = ref.read(repoProvider);
  await repo.moveToBin(p.id);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.t('moved_to_bin')),
        action: SnackBarAction(label: context.t('restore'), onPressed: () => repo.restoreFromBin(p.id)),
      ),
    );
  }
}

/// Unpublished drafts with Publish, Edit and Delete. Nothing here reaches the
/// online library until it is published.
class DraftsSection extends ConsumerWidget {
  const DraftsSection({super.key, this.padding = const EdgeInsets.fromLTRB(18, 4, 18, 140)});
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gc;
    final lang = context.lang;
    final drafts = ref.watch(draftsProvider).asData?.value ?? const <Poem>[];
    return ListView(
      padding: padding,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('${context.t('drafts_title')} · ${localDigits(drafts.length, lang)}', style: Theme.of(context).textTheme.titleLarge),
            ),
            if (drafts.isNotEmpty) const AttentionDot(size: 12),
          ],
        ),
        const SizedBox(height: 4),
        Text(context.t(drafts.isEmpty ? 'drafts_none' : 'drafts_help'), style: TextStyle(fontSize: 14.5, height: 1.4, color: c.mute)),
        const SizedBox(height: 10),
        for (final p in drafts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DraftCard(
              poem: p,
              onEdit: () => _edit(context, ref, p),
              onDelete: () => _delete(context, ref, p),
              onPublish: () => _publish(context, ref, p),
            ),
          ),
      ],
    );
  }
}

/// One draft: title and details, then Delete · Edit · Publish in one row of
/// equal, 44 dp buttons (destructive outlined in red, primary filled).
class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.poem, required this.onEdit, required this.onDelete, required this.onPublish});
  final Poem poem;
  final VoidCallback onEdit, onDelete, onPublish;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lang = context.lang;
    const radius = 12.0;
    const height = 44.0;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    const pad = EdgeInsets.symmetric(horizontal: 8);
    Widget label(IconData icon, String text) => FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(text, maxLines: 1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
    return GsvCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon3D('write', size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poemTitle(poem),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: poemFont(poem.lang), fontSize: 16.5, fontWeight: FontWeight.w700, color: c.ink),
                    ),
                    Text(
                      '${context.t('kind_${poem.kind}')} · ${friendlyDate(context, poem.updatedAt)} · ${localDigits(poem.wordCount, lang)} ${context.t('words')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c.mute),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, height),
                    padding: pad,
                    shape: shape,
                    foregroundColor: GsvColors.bad,
                    side: BorderSide(color: GsvColors.bad.withValues(alpha: 0.7)),
                  ),
                  child: label(Icons.delete_outline_rounded, context.t('draft_delete')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, height),
                    padding: pad,
                    shape: shape,
                    foregroundColor: c.primary,
                    side: BorderSide(color: c.primary.withValues(alpha: 0.7)),
                  ),
                  child: label(Icons.edit_outlined, context.t('edit')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onPublish,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, height),
                    padding: pad,
                    shape: shape,
                    backgroundColor: c.primary,
                    foregroundColor: c.onPrimary,
                  ),
                  child: label(Icons.cloud_upload_outlined, context.t('draft_publish_short')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Drafts on a page of their own (opened from the Home notice).
class DraftsScreen extends StatelessWidget {
  const DraftsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              ScreenHeader(back: true, title: context.t('drafts_title')),
              const Expanded(child: DraftsSection(padding: EdgeInsets.fromLTRB(18, 4, 18, 24))),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Home: unpublished drafts are waiting (shown above the counters).
class DraftsNotice extends ConsumerWidget {
  const DraftsNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(draftsProvider).asData?.value.length ?? 0;
    if (n == 0) return const SizedBox.shrink();
    final c = context.gc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GsvCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DraftsScreen())),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon3D('write', size: 46),
                const Positioned(right: -2, top: -2, child: AttentionDot(size: 12)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${context.t('drafts_title')} ${localDigits(n, context.lang)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.ink),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.accent),
          ],
        ),
      ),
    );
  }
}
