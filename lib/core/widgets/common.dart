import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../text/text_tools.dart';
import '../theme/app_themes.dart';
import '../theme/neon_tokens.dart';
import 'icon3d.dart';
import 'neon_surface.dart';

/// White card with the soft shadow used across the app.
class GsvCard extends StatelessWidget {
  const GsvCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.radius = 20});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: neonGlow(c, context.neon.glowIntensity, strength: onTap == null ? 0.6 : 1),
      ),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    return onTap == null ? card : NeonPressSurface(radius: radius, child: card);
  }
}

/// The main action button: gradient fill, large text, 60 dp tall.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.height = 60});
  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: NeonPressSurface(
        radius: height / 2.6,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2.6),
            boxShadow: onPressed == null ? null : neonGlow(c, context.neon.glowIntensity, strength: 1.3),
          ),
          child: Material(
            borderRadius: BorderRadius.circular(height / 2.6),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(gradient: c.buttonGradient),
              child: InkWell(
                onTap: onPressed,
                child: SizedBox(
                  height: height,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[Icon3D(icon!, size: 40), const SizedBox(width: 6)],
                      Flexible(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.onPrimary, fontSize: 19, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round 3D icon button with a tooltip / screen-reader label.
class Icon3DButton extends StatelessWidget {
  const Icon3DButton(this.icon, {super.key, required this.label, required this.onPressed, this.size = 48});
  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: size * 0.6,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon3D(icon, size: size),
        ),
      ),
    ),
  );
}

/// "?" button that opens the help for the current screen.
class HelpButton extends StatelessWidget {
  const HelpButton(this.screen, {super.key});
  final String screen;

  @override
  Widget build(BuildContext context) => Icon3DButton(
    'help',
    label: context.t('help_for_screen'),
    size: 48,
    onPressed: () {
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon3D('help', size: 44),
                    const SizedBox(width: 10),
                    Text(context.t('help_for_screen'), style: Theme.of(ctx).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 12),
                Text(context.help(screen), style: const TextStyle(fontSize: 18, height: 1.6)),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('close'))),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Screen title row: optional back button, title, trailing actions.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.back = false, this.actions = const [], this.subtitle});
  final String title;
  final String? subtitle;
  final bool back;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        children: [
          if (back)
            TextButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: Icon(Icons.chevron_left_rounded, size: 28, color: c.primary),
              label: Text(
                context.t('back'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.primary),
              ),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            )
          else
            const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: back ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: back
                      ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
                      : TextStyle(fontFamily: 'NotoSerifGujarati', fontSize: 28, fontWeight: FontWeight.w700, color: c.ink),
                ),
                if (subtitle != null) Text(subtitle!, style: TextStyle(fontSize: 13, color: c.mute)),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// Small round arrow that shows more or fewer items of a list. It turns to
/// point up when expanded.
class ExpandArrow extends StatelessWidget {
  const ExpandArrow({super.key, required this.expanded, required this.onPressed});
  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      expanded: expanded,
      label: context.t(expanded ? 'show_less' : 'show_more'),
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 26,
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary.withValues(alpha: 0.12)),
          child: AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: c.primary),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Row(
      children: [
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleLarge)),
        ?action,
      ],
    ),
  );
}

/// "Today" / "Yesterday" / "3 days ago" / "12 Jul 2024" in the UI language.
String friendlyDate(BuildContext context, DateTime d) {
  final now = DateTime.now();
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  final lang = context.lang;
  if (days == 0) return context.t('today');
  if (days == 1) return context.t('yesterday');
  if (days < 7) return '${localDigits(days, lang)} ${context.t('days_ago')}';
  return localDigits(DateFormat('d MMM y', lang.name).format(d), lang);
}

/// Empty state with a big icon and one clear action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text, this.action});
  final String icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
    child: Column(
      children: [
        Icon3D(icon, size: 84, well: true),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, color: context.gc.mute),
        ),
        if (action != null) ...[const SizedBox(height: 14), action!],
      ],
    ),
  );
}
