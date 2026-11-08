import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/icon3d.dart';
import '../../app_providers.dart';
import '../../data/backup/scheduler.dart';
import '../backup/backup_screens.dart';
import '../sync/drive_screen.dart';
import '../sync/writer_gate.dart';
import '../sync/library_screen.dart';
import '../collection/collection_screen.dart';
import '../editor/editor_screen.dart';
import '../home/home_screen.dart';
import '../drafts/drafts.dart';
import '../search/search_screen.dart';
import '../widget/home_screen_widget.dart';
import '../settings/settings_screen.dart';
import '../update/update_prompt.dart';

enum Tab { settings, search, home, collection }

/// Main frame. Bottom bar, left to right: Settings · Search · HOME · Write · Collection.
class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  Tab _tab = Tab.home;

  @override
  void initState() {
    super.initState();
    // Every time the app is opened (after the PIN), look for a newer version.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkForUpdate(context);
      unawaited(_startupJobs());
      final prefs = ref.read(prefsProvider);
      unawaited(updateHomeScreenWidget(prefs.place, prefs.lang));
    });
    // The home-screen widget follows the chosen place and language.
    ref.listenManual(prefsProvider.select((p) => (p.place, p.lang)), (_, next) => unawaited(updateHomeScreenWidget(next.$1, next.$2)));
  }

  /// Once per open: ask for notification permission the first time, and take
  /// the backup if 11:59 PM was missed (phone off or battery saver).
  Future<void> _startupJobs() async {
    final repo = ref.read(repoProvider);
    if (await repo.getSetting('notifAsked') == null) {
      await repo.setSetting('notifAsked', '1');
      try {
        await askNotificationPermission();
      } on Object {
        // Older Android: nothing to ask.
      }
    }
    await refreshOwnerVerifier(repo, ref.read(pinServiceProvider), await ref.read(deviceModelProvider.future));
    // The online library: readers look once a day, the poet's devices publish.
    unawaited(ref.read(libraryProvider).quiet(daily: true));
    final sync = ref.read(syncProvider);
    if (await sync.connected()) {
      try {
        await sync.run();
      } on Object {
        // Offline or signed out: tried again later.
      }
    }
    final svc = ref.read(backupServiceProvider);
    if (await svc.overdue()) {
      try {
        final lang = ref.read(prefsProvider).lang;
        await svc.nightly(subject: tr('backup_mail_subject', lang), body: tr('backup_mail_body', lang));
        ref.invalidate(backupStatusProvider);
      } on Object {
        // Shown on the Settings backup card next time.
      }
    }
  }

  void _go(Tab t) => setState(() => _tab = t);

  Future<void> _write() async {
    if (!await ensureCanWrite(context, ref) || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditorScreen()));
  }

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
        bottomNavigationBar: _BottomBar(current: _tab, onTab: _go, onWrite: _write, drafts: ref.watch(draftsProvider).asData?.value.length ?? 0),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.current, required this.onTab, required this.onWrite, this.drafts = 0});
  final int drafts;
  final Tab current;
  final ValueChanged<Tab> onTab;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    Widget item(String icon, String key, VoidCallback onTap, {bool selected = false, bool dot = false}) => Expanded(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // A red dot marks unfinished work (drafts waiting).
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon3D(icon, size: 38),
                    if (dot) const Positioned(right: -2, top: -2, child: AttentionDot(size: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.t(key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? c.primary : c.mute,
                  ),
                ),
              ],
            ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: homeSelected ? c.accent : Colors.transparent, width: 3),
              ),
              child: const Icon3D('home', size: 70),
            ),
            Text(
              context.t('nav_home'),
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: homeSelected ? c.primary : c.mute),
            ),
          ],
        ),
      ),
    );

    final row = Row(
      children: [
        // Order: Write · Search · Home (raised, centre) · Collection · Settings.
        item('write', 'nav_write', onWrite),
        item('search', 'nav_search', () => onTab(Tab.search), selected: current == Tab.search, dot: drafts > 0),
        const Expanded(child: SizedBox(height: 66)),
        item('collection', 'nav_collection', () => onTab(Tab.collection), selected: current == Tab.collection),
        item('settings', 'nav_settings', () => onTab(Tab.settings), selected: current == Tab.settings),
      ],
    );

    final inset = tablet ? 0.0 : bottomInset;
    final bar = ClipRRect(
      borderRadius: tablet ? BorderRadius.circular(40) : BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(6, 4, 6, 4 + inset),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.9),
            border: tablet ? Border.all(color: c.primary.withValues(alpha: 0.1)) : Border(top: BorderSide(color: c.primary.withValues(alpha: 0.12))),
          ),
          child: row,
        ),
      ),
    );

    final stack = SizedBox(
      height: 74 + inset + 24,
      child: Stack(
        children: [
          Positioned(left: 0, right: 0, bottom: 0, child: bar),
          Positioned(top: 0, left: 0, right: 0, child: Center(child: home)),
        ],
      ),
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
