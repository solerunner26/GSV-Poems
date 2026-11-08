import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../profile/profile_screen.dart';
import '../sync/drive_screen.dart';
import '../sync/writer_gate.dart';
import '../sync/library_screen.dart';
import '../update/update_prompt.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (mounted) setState(() => _version = '${i.version} (${i.buildNumber})');
    });
  }

  /// Five sizes with a live sample; the whole app follows at once.
  void _pickTextSize() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final current = ref.watch(prefsProvider).textScale;
          final system = MediaQuery.of(context).textScaler.scale(1);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(ctx.t('text_size'), style: Theme.of(ctx).textTheme.titleLarge),
                ),
                RadioGroup<double>(
                  groupValue: current,
                  onChanged: (v) => ref.read(prefsProvider.notifier).setTextScale(v!),
                  child: Column(
                    children: [
                      for (final (scale, key) in textSizes)
                        RadioListTile<double>(
                          value: scale,
                          title: Text(
                            ctx.t(key),
                            // A true preview: shown at the size it gives, not the current one.
                            textScaler: TextScaler.linear(appTextScale(system, scale)),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  void _pickTheme() {
    final notifier = ref.read(prefsProvider.notifier);
    final current = ref.read(prefsProvider).themeId;
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
                  label: ctx.t('theme_${t.id}'),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon3D('lotus', size: 52, base: t.accentDeep, glyph: t.accentLight),
                          const SizedBox(height: 6),
                          Text(
                            ctx.t('theme_${t.id}'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.ink),
                          ),
                        ],
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

  void _pickLang() {
    final notifier = ref.read(prefsProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final prefs = ref.watch(prefsProvider);
    // The closest offered size names the current one.
    var sizeKey = textSizes.first.$2;
    for (final s in textSizes) {
      if ((s.$1 - prefs.textScale).abs() < (textSizes.firstWhere((x) => x.$2 == sizeKey).$1 - prefs.textScale).abs()) sizeKey = s.$2;
    }
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
            children: [
              ScreenHeader(title: context.t('settings_title'), actions: const [HelpButton('settings')]),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: GsvCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
                  child: Row(
                    children: [
                      const PoetAvatar(size: 58),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.t('profile'),
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.gc.ink),
                            ),
                            Text(context.t('profile_row_sub'), style: TextStyle(fontSize: 14, color: context.gc.mute)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: context.gc.accent),
                    ],
                  ),
                ),
              ),
              SettingsGroup(
                title: context.t('sec_look'),
                rows: [
                  SettingsRow(icon: 'theme', title: context.t('theme'), sub: context.t('theme_${prefs.themeId}'), onTap: _pickTheme),
                  SettingsRow(icon: 'language', title: context.t('language'), sub: tr('lang_${prefs.lang.name}', prefs.lang), onTap: _pickLang),
                  SettingsRow(icon: 'fontsize', title: context.t('text_size'), sub: context.t(sizeKey), onTap: _pickTextSize),
                ],
              ),
              const Padding(padding: EdgeInsets.only(bottom: 18), child: BackupCard()),
              SettingsGroup(
                title: context.t('sec_backup'),
                rows: [
                  SettingsRow(
                    icon: 'cloud',
                    title: context.t('drive_title'),
                    sub: context.t('drive_row_sub'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DriveScreen())),
                  ),
                  SettingsRow(
                    icon: 'download',
                    title: context.t('lib_title'),
                    sub: context.t('lib_row_sub'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LibraryScreen())),
                  ),
                  SettingsRow(
                    icon: 'mail',
                    title: context.t('email_backup'),
                    sub: (ref.watch(backupStatusProvider).asData?.value.emailOn ?? false) ? context.t('email_on') : context.t('email_off'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EmailSetupScreen())),
                  ),
                  SettingsRow(
                    icon: 'collection',
                    title: context.t('dup_title'),
                    sub: context.t('dup_note'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DuplicatesScreen())),
                  ),
                  SettingsRow(
                    icon: 'download',
                    title: context.t('keep_import'),
                    sub: context.t('keep_import_sub'),
                    onTap: () async {
                      if (await ensureCanWrite(context, ref) && context.mounted) {
                        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const KeepImportScreen()));
                      }
                    },
                  ),
                ],
              ),
              SettingsGroup(
                title: context.t('panchang'),
                rows: [
                  SettingsRow(
                    icon: 'location',
                    title: context.t('place'),
                    sub: placeLabel(prefs.place, context.lang),
                    onTap: () => choosePlace(context, ref),
                  ),
                  SettingsRow(
                    icon: 'calendar',
                    title: context.t('panchang'),
                    sub: context.t('choghadiya'),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CalendarScreen())),
                  ),
                ],
              ),
              SettingsGroup(
                title: context.t('sec_help'),
                rows: [
                  SettingsRow(
                    icon: 'help',
                    title: context.t('help'),
                    sub: '',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const HelpGuideScreen())),
                  ),
                  SettingsRow(
                    icon: 'download',
                    title: context.t('check_update'),
                    sub: '${context.t('version')} $_version',
                    onTap: () => checkForUpdate(context, quiet: false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('GSV Poems', style: TextStyle(fontSize: 13, color: c.mute)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled card of setting rows.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.rows});
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: context.gc.mute),
          ),
        ),
        GsvCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 72, color: context.gc.primary.withValues(alpha: 0.08)),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// One setting: symbol, title, optional subtitle and trailing control.
class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.icon, required this.title, this.sub = '', this.onTap, this.trailing});
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
      title: Text(
        title,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
      ),
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
            child: Column(
              children: [
                ScreenHeader(back: true, title: context.t('help')),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                    children: [
                      for (final (icon, screen, titleKey) in topics)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GsvCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon3D(icon, size: 56),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(context.t(titleKey), style: Theme.of(context).textTheme.titleLarge),
                                      const SizedBox(height: 4),
                                      Text(context.help(screen), style: const TextStyle(fontSize: 17, height: 1.55)),
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
