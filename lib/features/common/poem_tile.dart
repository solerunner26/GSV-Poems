import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/db/database.dart';
import '../reader/reader_screen.dart';

String poemTitle(Poem p) {
  if (p.title.trim().isNotEmpty) return p.title.trim();
  final first = p.body.split('\n').map((l) => l.trim()).firstWhere((l) => l.isNotEmpty, orElse: () => '…');
  return first.length > 50 ? '${first.substring(0, 50)}…' : first;
}

void openPoem(BuildContext context, List<Poem> list, int index) {
  Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ReaderScreen(ids: [for (final p in list) p.id], initialIndex: index),
  ));
}

/// One poem row: category tile, title in the poem's script, date · category · words.
class PoemTile extends ConsumerWidget {
  const PoemTile({super.key, required this.poem, required this.onTap, this.trailing, this.showNumber = false});
  final Poem poem;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gc;
    final cats = ref.watch(categoriesProvider).asData?.value ?? const [];
    PoemCategory? cat;
    for (final x in cats) {
      if (x.id == poem.categoryId) cat = x;
    }
    final lang = context.lang;
    final meta = [
      friendlyDate(context, poem.updatedAt),
      if (cat != null) categoryName(cat, lang),
      '${localDigits(poem.wordCount, lang)} ${context.t('words')}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GsvCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        radius: 18,
        child: Row(children: [
          if (showNumber && poem.number != null)
            SizedBox(
              width: 46,
              child: Text('#${localDigits(poem.number!, lang)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.accentText)),
            )
          else
            Padding(padding: const EdgeInsets.only(right: 10), child: Icon3D(cat?.iconKey ?? 'other', size: 48)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(poemTitle(poem),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: poemFont(poem.lang), fontSize: 18, fontWeight: FontWeight.w600, color: c.ink)),
              Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: c.mute)),
            ]),
          ),
          trailing ?? const SizedBox(width: 8),
        ]),
      ),
    );
  }
}
