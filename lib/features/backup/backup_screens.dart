import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/neon_tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/backup/backup_codec.dart';
import '../../data/backup/backup_service.dart';
import '../../data/poem_repository.dart';
import '../../data/security/pin_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref.watch(repoProvider), const SecureSecretStore()));
final backupStatusProvider = FutureProvider.autoDispose<BackupStatus>((ref) => ref.watch(backupServiceProvider).status());

String _when(BuildContext context, DateTime? t) {
  if (t == null) return context.t('backup_never');
  return '${friendlyDate(context, t)} · ${localDigits(DateFormat('h:mm a', 'en').format(t), context.lang)}';
}

// ---------------------------------------------------------------------------
// Recovery key
// ---------------------------------------------------------------------------

/// Shows the recovery key in big letters. On first run it ends with
/// "I have written it down".
class RecoveryKeyScreen extends ConsumerStatefulWidget {
  const RecoveryKeyScreen({super.key, this.onDone});

  /// Set on first run; without it the screen has a back button.
  final VoidCallback? onDone;

  @override
  ConsumerState<RecoveryKeyScreen> createState() => _RecoveryKeyScreenState();
}

class _RecoveryKeyScreenState extends ConsumerState<RecoveryKeyScreen> {
  String? _key;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    ref.read(backupServiceProvider).recoveryKey().then((k) {
      if (mounted) setState(() => _key = k);
    });
  }

  Future<void> _email() async {
    setState(() => _sending = true);
    final svc = ref.read(backupServiceProvider);
    final lang = context.lang;
    final err = await svc.emailRecoveryKey(subject: tr('recovery_mail_subject', lang), body: '${tr('recovery_mail_body', lang)}\n\n$_key\n');
    if (!mounted) return;
    setState(() => _sending = false);
    final msg = err == null ? context.t('recovery_emailed') : (err == 'not-configured' ? context.t('email_off') : '${context.t('email_fail')}: $err');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final k = _key;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                ScreenHeader(back: widget.onDone == null, title: context.t('recovery_title')),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      const Center(child: Icon3D('key', size: 96, well: true)),
                      const SizedBox(height: 14),
                      Text(context.t('recovery_intro'), style: const TextStyle(fontSize: 18, height: 1.55)),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.accent, width: 2),
                        ),
                        child: k == null
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  for (final group in k.split('-'))
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: SelectableText(
                                        group,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 6,
                                          fontFamily: 'monospace',
                                          color: c.ink,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 56)),
                              onPressed: k == null ? null : () => SharePlus.instance.share(ShareParams(text: '${context.t('recovery_title')}: $k')),
                              icon: const Icon3D('share', size: 32),
                              label: Text(context.t('recovery_share'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 56)),
                              onPressed: k == null || _sending ? null : _email,
                              icon: const Icon3D('mail', size: 32),
                              label: Text(context.t('recovery_email'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                      if (widget.onDone != null) ...[
                        const SizedBox(height: 18),
                        PrimaryButton(
                          label: context.t('recovery_written'),
                          icon: 'check',
                          onPressed: k == null
                              ? null
                              : () async {
                                  await ref.read(backupServiceProvider).acknowledgeRecovery();
                                  widget.onDone!();
                                },
                        ),
                      ],
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

/// Asks for the recovery key; returns what was typed (null if cancelled).
Future<String?> askRecoveryKey(BuildContext context, {required String title, required String body}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(body, style: const TextStyle(fontSize: 17, height: 1.5)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 20, letterSpacing: 2, fontWeight: FontWeight.w700),
            decoration: InputDecoration(hintText: ctx.t('restore_key_hint')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.t('cancel'), style: const TextStyle(fontSize: 17)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: Text(ctx.t('next'), style: const TextStyle(fontSize: 17)),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Backup card in Settings
// ---------------------------------------------------------------------------

class BackupCard extends ConsumerStatefulWidget {
  const BackupCard({super.key});

  @override
  ConsumerState<BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<BackupCard> {
  bool _busy = false;

  Future<File?> _make() async {
    setState(() => _busy = true);
    try {
      final f = await ref.read(backupServiceProvider).backupNow();
      ref.invalidate(backupStatusProvider);
      return f;
    } on Object catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.t('backup_failed')}: $e')));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backupNow() async {
    final svc = ref.read(backupServiceProvider);
    final lang = context.lang;
    final f = await _make();
    if (f == null || !mounted) return;
    var msg = context.t('backup_done');
    if ((await svc.emailConfig())?.complete ?? false) {
      setState(() => _busy = true);
      final err = await svc.email(f, subject: tr('backup_mail_subject', lang), body: tr('backup_mail_body', lang));
      if (!mounted) return;
      setState(() => _busy = false);
      ref.invalidate(backupStatusProvider);
      msg = err == null ? '$msg · ${context.t('email_backup')} ✓' : '$msg · ${context.t('email_fail')}: $err';
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _whatsapp() async {
    final text = context.t('backup_share_text');
    final f = await _make();
    if (f == null) return;
    await ref.read(backupServiceProvider).share(f, text: text);
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(backupStatusProvider).asData?.value;
    const onDark = Colors.white;
    final c = context.gc;
    final soft = Colors.white.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: RadialGradient(center: const Alignment(1, -1), radius: 1.6, colors: [c.heroA, c.heroB, c.heroC], stops: const [0, 0.5, 1]),
        boxShadow: [
          BoxShadow(color: c.heroC.withValues(alpha: 0.3), blurRadius: 26, offset: const Offset(0, 12)),
          BoxShadow(color: c.glow.withValues(alpha: 0.18 * context.neon.glowIntensity), blurRadius: 28),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon3D('shield', size: 56),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      st?.lastBackup == null ? context.t('backup_never') : context.t('backup_safe'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: onDark),
                    ),
                    Text('${context.t('backup_last')}: ${_when(context, st?.lastBackup)}', style: TextStyle(fontSize: 14, color: soft)),
                    Text('${context.t('backup_nightly')} · ${context.t('backup_locked')}', style: TextStyle(fontSize: 14, color: soft)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('${localDigits(st?.localCount ?? 0, context.lang)} ${context.t('backup_on_phone')}'),
              _chip('${context.t('email_backup')}: ${st?.emailOn ?? false ? context.t('email_on') : context.t('email_off').split(' — ').first}'),
              if (st?.lastEmail != null) _chip('${context.t('email_last')}: ${_when(context, st!.lastEmail)}'),
            ],
          ),
          if (st?.lastError != null) ...[
            const SizedBox(height: 6),
            Text('⚠ ${st!.lastError}', style: const TextStyle(fontSize: 13, color: Color(0xFFFFD2C2))),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: c.heroC,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: _busy ? null : _backupNow,
              child: Text(
                _busy ? context.t('backup_working') : context.t('backup_now'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _outline(context.t('backup_whatsapp'), _busy ? null : _whatsapp)),
              const SizedBox(width: 8),
              Expanded(
                child: _outline(
                  context.t('backup_restore'),
                  _busy ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RestoreScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
    child: Text(
      t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
    ),
  );

  Widget _outline(String label, VoidCallback? onTap) => SizedBox(
    height: 52,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      onPressed: onTap,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Email setup
// ---------------------------------------------------------------------------

class EmailSetupScreen extends ConsumerStatefulWidget {
  const EmailSetupScreen({super.key});

  @override
  ConsumerState<EmailSetupScreen> createState() => _EmailSetupScreenState();
}

class _EmailSetupScreenState extends ConsumerState<EmailSetupScreen> {
  final _to = TextEditingController(), _from = TextEditingController(), _pass = TextEditingController();
  bool _busy = false, _hide = true;
  String? _result;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    ref.read(backupServiceProvider).emailConfig().then((c) {
      if (c == null || !mounted) return;
      setState(() {
        _to.text = c.to;
        _from.text = c.from;
        _pass.text = c.appPassword;
      });
    });
  }

  @override
  void dispose() {
    _to.dispose();
    _from.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    final cfg = EmailConfig.typed(to: _to.text, from: _from.text, password: _pass.text);
    // Show what was understood, so a name in the sender box visibly becomes the address.
    _from.text = cfg.from;
    final problem = cfg.problem;
    if (problem != null) {
      setState(() {
        _result = context.t(problem);
        _ok = false;
      });
      return;
    }
    setState(() => _busy = true);
    final svc = ref.read(backupServiceProvider);
    final lang = context.lang;
    await svc.saveEmailConfig(cfg);
    final f = await svc.backupNow();
    final err = await svc.email(f, subject: tr('backup_mail_subject', lang), body: tr('backup_mail_body', lang));
    ref.invalidate(backupStatusProvider);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _ok = err == null;
      _result = err == null ? context.t('email_ok') : '${context.t('email_fail')}: $err';
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                ScreenHeader(back: true, title: context.t('email_backup')),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                    children: [
                      GsvCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon3D('mail', size: 52),
                            const SizedBox(width: 12),
                            Expanded(child: Text(context.t('email_how'), style: const TextStyle(fontSize: 16, height: 1.55))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _to,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(labelText: context.t('email_to')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _from,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          labelText: context.t('email_from'),
                          hintText: 'name@gmail.com',
                          helperText: context.t('email_from_help'),
                          helperMaxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _pass,
                        obscureText: _hide,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(fontSize: 18, letterSpacing: 1.5),
                        decoration: InputDecoration(
                          labelText: context.t('email_pass'),
                          suffixIcon: IconButton(
                            tooltip: _hide ? 'Show' : 'Hide',
                            onPressed: () => setState(() => _hide = !_hide),
                            icon: Icon(_hide ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: _busy ? context.t('backup_working') : context.t('email_save_test'),
                        icon: 'mail',
                        onPressed: _busy ? null : _saveAndTest,
                      ),
                      if (_result != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _result!,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ok ? GsvColors.good : GsvColors.bad),
                        ),
                      ],
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () async {
                          await ref.read(backupServiceProvider).clearEmailConfig();
                          ref.invalidate(backupStatusProvider);
                          if (!context.mounted) return;
                          Navigator.of(context).maybePop();
                        },
                        child: Text(context.t('email_remove'), style: TextStyle(fontSize: 16, color: c.mute)),
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

// ---------------------------------------------------------------------------
// Restore
// ---------------------------------------------------------------------------

class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  Uint8List? _bytes;
  BackupHeader? _header;
  Map<String, dynamic>? _data;
  String? _error;
  RestoreOutcome? _done;
  bool _busy = false;
  bool _adopted = false;
  List<File> _local = const [];

  @override
  void initState() {
    super.initState();
    ref.read(backupServiceProvider).localBackups().then((f) {
      if (mounted) setState(() => _local = f);
    });
  }

  Future<void> _load(Uint8List bytes) async {
    setState(() {
      _error = null;
      _done = null;
      _data = null;
    });
    try {
      final h = readBackupHeader(bytes);
      setState(() {
        _bytes = bytes;
        _header = h;
      });
      await _unlock(null);
    } on BackupFormatException {
      setState(() => _error = context.t('restore_not_backup'));
    }
  }

  Future<void> _pick() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return;
    await _load(await files.first.readAsBytes());
  }

  /// Tries this phone's key first; if that fails, asks for the key.
  Future<void> _unlock(String? typed) async {
    final bytes = _bytes;
    if (bytes == null) return;
    final svc = ref.read(backupServiceProvider);
    setState(() => _busy = true);
    try {
      final r = await svc.open(bytes, typedKey: typed);
      if (r.usedTypedKey && !(await svc.matchesRecoveryKey(typed!))) {
        await svc.adoptRecoveryKey(typed);
        _adopted = true;
      }
      setState(() => _data = r.data);
    } on WrongKeyException {
      if (!mounted) return;
      setState(() => _busy = false);
      if (typed != null) setState(() => _error = context.t('restore_wrong_key'));
      final k = await askRecoveryKey(context, title: context.t('restore_title'), body: context.t('restore_key_hint'));
      if (k != null && k.trim().isNotEmpty) await _unlock(k);
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore({required bool replace}) async {
    final data = _data;
    if (data == null) return;
    if (replace) {
      for (final key in ['restore_replace_confirm', 'confirm_forever2']) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(ctx.t('restore_replace')),
            content: Text(ctx.t(key), style: const TextStyle(fontSize: 17, height: 1.5)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.t('cancel'), style: const TextStyle(fontSize: 17)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: GsvColors.bad),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.t('restore_replace'), style: const TextStyle(fontSize: 17)),
              ),
            ],
          ),
        );
        if (ok != true) return;
      }
    }
    setState(() => _busy = true);
    // Safety copy of the phone as it is now, before anything changes.
    await ref.read(backupServiceProvider).backupNow();
    final out = await ref.read(repoProvider).restoreBackup(data, replaceAll: replace);
    final prefs = await ref.read(repoProvider).allSettings();
    final n = ref.read(prefsProvider.notifier);
    final restored = AppPrefs.fromMap(prefs);
    await n.setTheme(restored.themeId);
    await n.setLang(restored.lang);
    if (restored.placeChosen) await n.setPlace(restored.place);
    ref.invalidate(backupStatusProvider);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = out;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lang = context.lang;
    final h = _header;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                ScreenHeader(back: true, title: context.t('restore_title')),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                    children: [
                      GsvCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon3D('restore', size: 52),
                            const SizedBox(width: 12),
                            Expanded(child: Text(context.t('restore_how'), style: const TextStyle(fontSize: 16, height: 1.55))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      PrimaryButton(label: context.t('restore_pick'), icon: 'download', onPressed: _busy ? null : _pick),
                      if (_local.isNotEmpty && h == null) ...[
                        const SizedBox(height: 16),
                        Text(context.t('restore_phone_copies'), style: Theme.of(context).textTheme.titleMedium),
                        for (final f in _local)
                          ListTile(
                            minTileHeight: 54,
                            leading: const Icon3D('shield', size: 44),
                            title: Text(f.uri.pathSegments.last.replaceAll('.$backupExtension', ''), style: const TextStyle(fontSize: 16)),
                            onTap: () async => _load(await f.readAsBytes()),
                          ),
                      ],
                      if (_busy) ...[const SizedBox(height: 18), const LinearProgressIndicator()],
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _error!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: GsvColors.bad),
                        ),
                      ],
                      if (h != null) ...[
                        const SizedBox(height: 16),
                        GsvCard(
                          child: Row(
                            children: [
                              const Icon3D('shield', size: 48),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${_when(context, h.created)} ${context.t('restore_of')}\n${localDigits(h.poems, lang)} ${context.t('poems')}',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_data != null && _done == null) ...[
                        const SizedBox(height: 14),
                        if (_adopted) Text(context.t('restore_key_adopted'), style: TextStyle(fontSize: 15, color: c.accentText)),
                        Text(context.t('restore_merge_note'), style: TextStyle(fontSize: 15, color: c.mute)),
                        const SizedBox(height: 10),
                        PrimaryButton(label: context.t('restore_merge'), icon: 'check', onPressed: _busy ? null : () => _restore(replace: false)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy ? null : () => _restore(replace: true),
                          child: Text(context.t('restore_replace'), style: const TextStyle(fontSize: 15, color: GsvColors.bad)),
                        ),
                      ],
                      if (_done != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: c.alertBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: c.alertBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon3D('check', size: 52),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${context.t('restore_done')}: ${localDigits(_done!.added, lang)} ${context.t('restore_added')} · '
                                  '${localDigits(_done!.updated, lang)} ${context.t('restore_updated')} · ${localDigits(_done!.unchanged, lang)} ${context.t('restore_same')}',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
