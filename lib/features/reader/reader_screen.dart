import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../core/widgets/neon_surface.dart';
import '../../core/theme/neon_tokens.dart';
import '../../data/db/database.dart';
import '../common/poem_share.dart';
import '../common/poem_tile.dart';
import '../editor/editor_screen.dart';

/// Reading mode: one poem per page, swipe for the next. The interface follows
/// the poem's language. The screen stays awake while reading.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.ids, this.initialIndex = 0});
  final List<String> ids;
  final int initialIndex;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  double _size = 22;
  bool _speaking = false;
  final _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _tts.stop();
    _pages.dispose();
    super.dispose();
  }

  Future<void> _speak(Poem p) async {
    if (_speaking) {
      await _tts.stop();
      setState(() => _speaking = false);
      return;
    }
    await _tts.setLanguage(
      p.lang == 'hi'
          ? 'hi-IN'
          : p.lang == 'en'
          ? 'en-IN'
          : 'gu-IN',
    );
    await _tts.setSpeechRate(0.42);
    setState(() => _speaking = true);
    await _tts.speak('${p.title}.\n${p.body}');
  }

  Future<void> _share(Poem p) => sharePoem(context, p);

  Future<void> _more(Poem p) async {
    final repo = ref.read(repoProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => LangScope(
        lang: langFromCode(p.lang),
        child: Builder(
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon3D('undo', size: 44),
                  title: Text(ctx.t('history'), style: const TextStyle(fontSize: 18)),
                  onTap: () => Navigator.pop(ctx, 'history'),
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
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'bin') {
      await repo.moveToBin(p.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final msg = context.t('moved_to_bin'), undo = context.t('restore');
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: undo, onPressed: () => repo.restoreFromBin(p.id)),
        ),
      );
    } else if (choice == 'history') {
      final versions = await repo.versions(p.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => LangScope(
          lang: langFromCode(p.lang),
          child: Builder(
            builder: (ctx) => SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.7,
                child: versions.isEmpty
                    ? EmptyState(icon: 'undo', text: ctx.t('no_history'))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        children: [
                          Text(ctx.t('history'), style: Theme.of(ctx).textTheme.titleLarge),
                          const SizedBox(height: 10),
                          for (final v in versions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GsvCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(friendlyDate(ctx, v.savedAt), style: TextStyle(fontSize: 14, color: ctx.gc.mute)),
                                    Text(
                                      v.body,
                                      maxLines: 6,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontFamily: poemFont(p.lang), fontSize: 16, height: 1.6),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () async {
                                          await repo.restoreVersion(v);
                                          if (ctx.mounted) Navigator.pop(ctx);
                                        },
                                        child: Text(ctx.t('use_version'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(poemProvider(widget.ids[_index])).asData?.value;
    final lang = current == null ? context.lang : langFromCode(current.lang);
    final c = context.gc;
    return LangScope(
      lang: lang,
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: context.t('back'),
                          onPressed: () => Navigator.maybePop(context),
                          iconSize: 30,
                          color: c.primary,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            '${localDigits(_index + 1, lang)} / ${localDigits(widget.ids.length, lang)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.mute),
                          ),
                        ),
                        if (current != null) ...[
                          Icon3DButton(
                            'edit',
                            label: context.t('edit'),
                            size: 44,
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => EditorScreen(poemId: current.id)));
                            },
                          ),
                          IconButton(
                            tooltip: context.t('more'),
                            iconSize: 28,
                            color: c.primary,
                            onPressed: () => _more(current),
                            icon: const Icon(Icons.more_horiz_rounded),
                          ),
                        ],
                        const HelpButton('reader'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: widget.ids.length,
                      onPageChanged: (i) {
                        _tts.stop();
                        setState(() {
                          _index = i;
                          _speaking = false;
                        });
                      },
                      itemBuilder: (_, i) => _PoemPage(id: widget.ids[i], size: _size),
                    ),
                  ),
                  if (widget.ids.length > 1) Text(context.t('swipe_hint'), style: TextStyle(fontSize: 13.5, color: c.mute)),
                  if (current != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                      child: Row(
                        children: [
                          _Tool(
                            label: context.t('smaller'),
                            onTap: () => setState(() => _size = (_size - 2).clamp(16, 34)),
                            child: const Text('A−', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                          ),
                          _Tool(
                            label: context.t('bigger'),
                            onTap: () => setState(() => _size = (_size + 2).clamp(16, 34)),
                            child: const Text('A+', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
                          ),
                          _Tool(
                            label: _speaking ? context.t('stop') : context.t('read_aloud'),
                            onTap: () => _speak(current),
                            child: const Icon3D('speaker', size: 36),
                          ),
                          _Tool(
                            label: context.t('favorite'),
                            selected: current.isFavorite,
                            onTap: () => ref.read(repoProvider).setFavorite(current.id, !current.isFavorite),
                            child: Opacity(opacity: current.isFavorite ? 1 : 0.45, child: const Icon3D('star', size: 36)),
                          ),
                          _Tool(label: context.t('share'), primary: true, onTap: () => _share(current), child: const Icon3D('share', size: 36)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PoemPage extends ConsumerWidget {
  const _PoemPage({required this.id, required this.size});
  final String id;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(poemProvider(id)).asData?.value;
    if (p == null) return const SizedBox.shrink();
    final c = context.gc;
    final lang = langFromCode(p.lang);
    final font = poemFont(p.lang);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: NeonPressSurface(
            radius: 26,
            featured: true,
            interactive: false,
            focal: (s) => Offset(s.width / 2, 54),
            focalRadius: 34,
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(26),
                boxShadow: neonGlow(c, context.neon.glowIntensity, strength: 1.2),
              ),
              child: CustomPaint(
                painter: _Corners(c.accent.withValues(alpha: 0.7)),
                child: Stack(
                  children: [
                    // The poet's logo, faint, behind every poem.
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Image.asset(
                            logoMarkAsset,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                            color: c.ink.withValues(alpha: c.isDark ? 0.07 : 0.06),
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
                      child: Column(
                        children: [
                          const Icon3D('lotus', size: 56),
                          const SizedBox(height: 8),
                          if (p.number != null)
                            Text(
                              '#${localDigits(p.number!, lang)}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.accentText),
                            ),
                          Text(
                            poemTitle(p),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: font, fontSize: size + 4, height: 1.25, fontWeight: FontWeight.w700, color: c.ink),
                          ),
                          const SizedBox(height: 14),
                          SelectableText(
                            p.body.trim(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: font, fontSize: size, height: 1.85, color: c.ink),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            '— ${tr('poet_name', lang)} · ${friendlyDate(context, p.createdAt)}',
                            style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: c.mute),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Saffron corner brackets on the reading page.
class _Corners extends CustomPainter {
  _Corners(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    const m = 14.0, l = 34.0, r = 14.0;
    canvas.drawPath(
      Path()
        ..moveTo(m, m + l)
        ..lineTo(m, m + r)
        ..arcToPoint(const Offset(m + r, m), radius: const Radius.circular(r))
        ..lineTo(m + l, m),
      p,
    );
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w - m, h - m - l)
        ..lineTo(w - m, h - m - r)
        ..arcToPoint(Offset(w - m - r, h - m), radius: const Radius.circular(r))
        ..lineTo(w - m - l, h - m),
      p,
    );
  }

  @override
  bool shouldRepaint(_Corners old) => old.color != color;
}

class _Tool extends StatelessWidget {
  const _Tool({required this.label, required this.onTap, required this.child, this.primary = false, this.selected = false});
  final String label;
  final VoidCallback onTap;
  final Widget child;
  final bool primary, selected;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: primary ? c.primary : c.surface,
            borderRadius: BorderRadius.circular(18),
            elevation: c.isDark ? 0 : 1.5,
            shadowColor: c.ink.withValues(alpha: 0.2),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: SizedBox(
                height: 68,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DefaultTextStyle.merge(
                      style: TextStyle(color: primary ? c.onPrimary : c.primary),
                      child: child,
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: primary ? c.onPrimary : c.primary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
