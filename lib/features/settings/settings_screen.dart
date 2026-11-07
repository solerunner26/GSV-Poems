import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../backup/backup_screens.dart';
import '../calendar/calendar_screen.dart';
import '../duplicates/duplicates_screen.dart';
import '../import/keep_import_screen.dart';
import '../pin/pin_screen.dart';
import '../update/update_prompt.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _bio;
  String _version = '';

  @override
  void initState() {
    super.initState();
    ref.read(pinServiceProvider).biometricEnabled().then((v) {
      if (mounted) setState(() => _bio = v);
    });
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _version = '${i.version} (${i.buildNumber})');
    });
  }

  Future<void> _toggleBio(bool on) async {
    if (on) {
      final auth = LocalAuthentication();
      var ok = false;
      try {
        ok = await auth.canCheckBiometrics && (await auth.getAvailableBiometrics()).isNotEmpty;
      } on PlatformException {
        ok = false;
      }
      if (!ok) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('fingerprint_none'))));
        return;
      }
    }
    await ref.read(pinServiceProvider).setBiometric(on);
    if (mounted) setState(() => _bio = on);
  }

  void _pickTheme() {
    final notifier = ref.read(prefsProvider.notifier);
    final current = ref.read(prefsProvider).themeId;
    const names = {
      'mor': ['મોર', 'मोर', 'Peacock'],
      'light': ['પ્રકાશ', 'प्रकाश', 'Light'],
      'night': ['રાત', 'रात', 'Night'],
      'kamal': ['કમળ', 'कमल', 'Lotus'],
      'neel': ['નીલ', 'नील', 'Indigo'],
      'van': ['વન', 'वन', 'Forest'],
    };
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              for (final t in allThemes)
                Semantics(
                  button: true,
                  selected: t.id == current,
                  label: names[t.id]![ctx.lang.index],
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      notifier.setTheme(t.id);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: t.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: t.id == current ? t.accent : t.ink.withValues(alpha: 0.12), width: t.id == current ? 3 : 1),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon3D('lotus', size: 52, base: t.primary, glyph: t.isDark ? t.ink : t.accent),
                        const SizedBox(height: 6),
                        Text(names[t.id]![ctx.lang.index], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.ink)),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickLang() {
    final notifier = ref.read(prefsProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final l in PoemLang.values)
            ListTile(
              minTileHeight: 60,
              title: Text(tr('lang_${l.name}', l), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              trailing: ctx.lang == l ? const Icon3D('check', size: 36) : null,
              onTap: () {
                notifier.setLang(l);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final prefs = ref.watch(prefsProvider);
    final sizeKey = prefs.textScale >= 1.3 ? 'size_xl' : prefs.textScale >= 1.15 ? 'size_l' : 'size_m';
    const themeNames = {'mor': 'મોર · Mor', 'light': 'પ્રકાશ · Light', 'night': 'રાત · Night', 'kamal': 'કમળ · Kamal', 'neel': 'નીલ · Neel', 'van': 'વન · Van'};
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
            children: [
              ScreenHeader(title: context.t('settings_title'), actions: const [HelpButton('settings')]),
              _Group(title: context.t('sec_look'), rows: [
                _Row(icon: 'theme', title: context.t('theme'), sub: themeNames[prefs.themeId] ?? '', onTap: _pickTheme),
                _Row(icon: 'language', title: context.t('language'), sub: tr('lang_${prefs.lang.name}', prefs.lang), onTap: _pickLang),
                _Row(
                  icon: 'fontsize',
                  title: context.t('text_size'),
                  sub: context.t(sizeKey),
                  onTap: () {
                    final next = prefs.textScale >= 1.3 ? 1.0 : prefs.textScale >= 1.15 ? 1.3 : 1.15;
                    ref.read(prefsProvider.notifier).setTextScale(next);
                  },
                ),
              ]),
              _Group(title: context.t('sec_security'), rows: [
                _Row(
                  icon: 'lock',
                  title: context.t('change_pin'),
                  sub: '••••',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (routeCtx) => PinScreen(mode: PinMode.change, onUnlocked: () => Navigator.of(routeCtx).pop()),
                  )),
                ),
                _Row(
                  icon: 'fingerprint',
                  title: context.t('fingerprint'),
                  trailing: Switch(value: _bio ?? false, onChanged: _bio == null ? null : _toggleBio),
                  onTap: _bio == null ? null : () => _toggleBio(!(_bio ?? false)),
                ),
              ]),
              const Padding(padding: EdgeInsets.only(bottom: 18), child: BackupCard()),
              _Group(title: context.t('sec_backup'), rows: [
                _Row(
                  icon: 'mail',
                  title: context.t('email_backup'),
                  sub: (ref.watch(backupStatusProvider).asData?.value.emailOn ?? false) ? context.t('email_on') : context.t('email_off'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EmailSetupScreen())),
                ),
                _Row(
                  icon: 'key',
                  title: context.t('recovery_view'),
                  sub: '••••• — PIN',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (routeCtx) => PinScreen(
                      onUnlocked: () => Navigator.of(routeCtx).pushReplacement(MaterialPageRoute<void>(builder: (_) => const RecoveryKeyScreen())),
                    ),
                  )),
                ),
                _Row(
                  icon: 'collection',
                  title: context.t('dup_title'),
                  sub: context.t('dup_note'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DuplicatesScreen())),
                ),
                _Row(
                  icon: 'download',
                  title: context.t('keep_import'),
                  sub: context.t('keep_import_sub'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const KeepImportScreen())),
                ),
              ]),
              _Group(title: context.t('panchang'), rows: [
                _Row(
                  icon: 'location',
                  title: context.t('place'),
                  sub: placeLabel(prefs.place, context.lang),
                  onTap: () => choosePlace(context, ref),
                ),
                _Row(
                  icon: 'calendar',
                  title: context.t('panchang'),
                  sub: context.t('choghadiya'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CalendarScreen())),
                ),
              ]),
              _Group(title: context.t('sec_help'), rows: [
                _Row(icon: 'help', title: context.t('help'), sub: '', onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HelpGuideScreen()))),
                _Row(icon: 'download', title: context.t('check_update'), sub: '${context.t('version')} $_version', onTap: () => checkForUpdate(context, quiet: false)),
              ]),
              const SizedBox(height: 8),
              Center(child: Text('GSV Poems', style: TextStyle(fontSize: 13, color: c.mute))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 6),
            child: Text(title.toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: context.gc.mute)),
          ),
          GsvCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 72, color: context.gc.primary.withValues(alpha: 0.08)),
                rows[i],
              ],
            ]),
          ),
        ]),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, this.sub = '', this.onTap, this.trailing});
  final String icon, title, sub;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return ListTile(
      minTileHeight: 66,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Icon3D(icon, size: 46),
      title: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink)),
      subtitle: sub.isEmpty ? null : Text(sub, style: TextStyle(fontSize: 14, color: c.mute)),
      trailing: trailing ?? (onTap == null ? null : Icon(Icons.chevron_right_rounded, color: c.accent)),
      onTap: onTap,
    );
  }
}

/// In-app guide: one card per screen with the same text as its "?" button.
class HelpGuideScreen extends StatelessWidget {
  const HelpGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const topics = [
      ('home', 'home', 'nav_home'),
      ('write', 'editor', 'nav_write'),
      ('star', 'reader', 'read_full'),
      ('search', 'search', 'nav_search'),
      ('collection', 'collection', 'nav_collection'),
      ('settings', 'settings', 'nav_settings'),
    ];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(children: [
              ScreenHeader(back: true, title: context.t('help')),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(18, 6, 18, 24), children: [
                  for (final (icon, screen, titleKey) in topics)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GsvCard(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon3D(icon, size: 56),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(context.t(titleKey), style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(context.help(screen), style: const TextStyle(fontSize: 17, height: 1.55)),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
