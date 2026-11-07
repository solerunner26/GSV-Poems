import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/icon3d.dart';
import '../collection/collection_screen.dart';
import '../editor/editor_screen.dart';
import '../home/home_screen.dart';
import '../search/search_screen.dart';
import '../settings/settings_screen.dart';

enum Tab { settings, search, home, collection }

/// Main frame. Bottom bar, left to right: Settings · Search · HOME · Write · Collection.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  Tab _tab = Tab.home;

  void _go(Tab t) => setState(() => _tab = t);

  void _write() => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditorScreen()));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _tab == Tab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(Tab.home);
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _tab.index,
          children: [
            const SettingsScreen(),
            const SearchScreen(),
            HomeScreen(onOpenCollection: () => _go(Tab.collection), onWrite: _write),
            const CollectionScreen(),
          ],
        ),
        bottomNavigationBar: _BottomBar(current: _tab, onTab: _go, onWrite: _write),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.current, required this.onTab, required this.onWrite});
  final Tab current;
  final ValueChanged<Tab> onTab;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    Widget item(String icon, String key, VoidCallback onTap, {bool selected = false}) => Expanded(
          child: Semantics(
            button: true,
            selected: selected,
            label: context.t(key),
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                height: 66,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: selected ? c.accent.withValues(alpha: 0.16) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon3D(icon, size: 38),
                  const SizedBox(height: 2),
                  Text(context.t(key),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13.5,
                          height: 1.1,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected ? c.primary : c.mute)),
                ]),
              ),
            ),
          ),
        );

    final homeSelected = current == Tab.home;
    // The raised Home button sits above the bar, so it lives in a Stack whose
    // top strip is transparent (taps there still reach it).
    final home = Semantics(
      button: true,
      selected: homeSelected,
      label: context.t('nav_home'),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTab(Tab.home),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: homeSelected ? c.accent : Colors.transparent, width: 3),
            ),
            child: const Icon3D('home', size: 70),
          ),
          Text(context.t('nav_home'),
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: homeSelected ? c.primary : c.mute)),
        ]),
      ),
    );

    final row = Row(children: [
      item('settings', 'nav_settings', () => onTab(Tab.settings), selected: current == Tab.settings),
      item('search', 'nav_search', () => onTab(Tab.search), selected: current == Tab.search),
      const Expanded(child: SizedBox(height: 66)),
      item('write', 'nav_write', onWrite),
      item('collection', 'nav_collection', () => onTab(Tab.collection), selected: current == Tab.collection),
    ]);

    final inset = tablet ? 0.0 : bottomInset;
    final bar = ClipRRect(
      borderRadius: tablet ? BorderRadius.circular(40) : BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(6, 4, 6, 4 + inset),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.9),
            border: tablet
                ? Border.all(color: c.primary.withValues(alpha: 0.1))
                : Border(top: BorderSide(color: c.primary.withValues(alpha: 0.12))),
          ),
          child: row,
        ),
      ),
    );

    final stack = SizedBox(
      height: 74 + inset + 24,
      child: Stack(children: [
        Positioned(left: 0, right: 0, bottom: 0, child: bar),
        Positioned(top: 0, left: 0, right: 0, child: Center(child: home)),
      ]),
    );

    if (!tablet) return stack;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Center(heightFactor: 1, child: SizedBox(width: 640, child: stack)),
      ),
    );
  }
}
