import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'writer_gate.dart';
import 'library_screen.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/sync/drive_service.dart';
import '../../data/sync/sync_service.dart';
import '../backup/backup_screens.dart';

/// Values the Google Cloud Android client needs (shown on the setup panel).
const appPackage = 'com.gsvpoems.gsv_poems';
const releaseSha1 = '74:9D:C7:12:D9:4D:55:DF:20:9B:3E:D8:67:42:3F:E5:DA:CD:CB:CD';

final driveClientIdProvider = FutureProvider<String>((ref) async {
  final s = await ref.watch(repoProvider).getSetting('driveClientId');
  return (s == null || s.isEmpty) ? defaultWebClientId : s;
});

/// One Drive connection for the whole app.
final driveServiceProvider = FutureProvider<DriveService>((ref) async => DriveService(await ref.watch(driveClientIdProvider.future)));

/// Runs a sync (Drive must already be connected). Several calls close
/// together run once.
class SyncCoordinator {
  SyncCoordinator(this.ref);
  final Ref ref;
  Future<SyncResult>? _running;
  Timer? _soon;

  Future<bool> connected() async => (await ref.read(repoProvider).getSetting('driveEmail'))?.isNotEmpty ?? false;

  Future<SyncResult> run({String? typedKey}) => _running ??= () async {
    final repo = ref.read(repoProvider);
    try {
      final drive = await ref.read(driveServiceProvider.future);
      if (!await drive.signInQuietly()) {
        await repo.setSetting('driveNeedsReconnect', '1');
        throw StateError('Google Drive needs to be connected again');
      }
      final model = await ref.read(deviceModelProvider.future);
      await refreshOwnerVerifier(repo, ref.read(pinServiceProvider), model);
      final svc = SyncService(
        repo,
        ref.read(backupServiceProvider),
        drive,
        ownerVerifier: publishesOwnerPin(model) ? () => ref.read(pinServiceProvider).verifier() : null,
      );
      final r = await svc.sync(typedKey: typedKey);
      await repo.setSetting('driveNeedsReconnect', '');
      return r;
    } finally {
      ref.invalidate(driveReconnectProvider);
      ref.invalidate(syncNeedsKeyProvider);
      _running = null;
      ref.invalidate(backupStatusProvider);
    }
  }();

  /// A quiet sync a few seconds after an edit, when Drive is connected.
  void soon() {
    _soon?.cancel();
    _soon = Timer(const Duration(seconds: 4), () async {
      unawaited(ref.read(libraryProvider).quiet());
      if (!await connected()) return;
      try {
        await run();
      } on Object {
        // Tried again on the next open, edit or night.
      }
    });
  }
}

final syncProvider = Provider<SyncCoordinator>((ref) => SyncCoordinator(ref));

/// True when another device's backup is locked with a different recovery key,
/// so its poems cannot come in until that key is typed here once.
final syncNeedsKeyProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(repoProvider);
  if (await repo.getSetting('libNeedsKey') == '1') return true;
  final connected = (await repo.getSetting('driveEmail'))?.isNotEmpty ?? false;
  return connected && await repo.getSetting('syncNeedsKey') == '1';
});

/// Card on Home: the other device's poems are waiting for its recovery key.
class SyncKeyNotice extends ConsumerWidget {
  const SyncKeyNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(syncNeedsKeyProvider).asData?.value ?? false)) return const SizedBox.shrink();
    final c = context.gc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GsvCard(
        onTap: () async {
          final lib = await ref.read(repoProvider).getSetting('libNeedsKey') == '1';
          if (!context.mounted) return;
          await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => lib ? const LibraryScreen() : const DriveScreen()));
        },
        child: Row(
          children: [
            const Icon3D('key', size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('sync_key_title'),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
                  ),
                  Text(context.t('sync_key_body'), style: TextStyle(fontSize: 14.5, height: 1.4, color: c.mute)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: c.accent),
          ],
        ),
      ),
    );
  }
}

/// True when Google asked for permission again (e.g. after 7 days in Testing
/// mode): Home then shows a "Reconnect Google Drive" card.
final driveReconnectProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(repoProvider);
  final connected = (await repo.getSetting('driveEmail'))?.isNotEmpty ?? false;
  return connected && await repo.getSetting('driveNeedsReconnect') == '1';
});

/// Card on Home when Drive needs to be connected again.
class DriveReconnectNotice extends ConsumerWidget {
  const DriveReconnectNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(driveReconnectProvider).asData?.value ?? false)) return const SizedBox.shrink();
    final c = context.gc;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: c.alertBg,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DriveScreen())),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.alertBorder, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon3D('cloud', size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.t('drive_reconnect'),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
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

class DriveScreen extends ConsumerStatefulWidget {
  const DriveScreen({super.key});

  @override
  ConsumerState<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends ConsumerState<DriveScreen> {
  String? _email, _lastSync, _message;
  bool _needsKey = false, _busy = false, _ok = true, _reconnect = false;
  final _clientId = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(repoProvider);
    final email = await repo.getSetting('driveEmail');
    final last = await repo.getSetting('lastSyncAt');
    final needs = await repo.getSetting('syncNeedsKey');
    final reconnect = await repo.getSetting('driveNeedsReconnect') == '1';
    final id = await ref.read(driveClientIdProvider.future);
    if (!mounted) return;
    setState(() {
      _email = email == null || email.isEmpty ? null : email;
      _lastSync = last;
      _needsKey = needs == '1';
      _reconnect = reconnect;
      _clientId.text = id;
    });
  }

  void _set(String message, bool ok) {
    _message = message;
    _ok = ok;
  }

  @override
  void dispose() {
    _clientId.dispose();
    super.dispose();
  }

  String _describe(SyncResult r) =>
      '${context.t('drive_synced')}: ${localDigits(r.devices, context.lang)} ${context.t('drive_other_devices')} · '
      '${localDigits(r.added, context.lang)} ${context.t('restore_added')} · ${localDigits(r.updated, context.lang)} ${context.t('restore_updated')}';

  Future<void> _do(Future<void> Function() job) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await job();
    } on DriveNotSetUp {
      if (mounted) setState(() => _set(context.t('drive_not_setup'), false));
    } on Object catch (e) {
      if (mounted) setState(() => _set('${context.t('drive_failed')}: $e', false));
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  Future<void> _connect() => _do(() async {
    final drive = await ref.read(driveServiceProvider.future);
    final email = await drive.connect();
    await ref.read(repoProvider).setSetting('driveEmail', email);
    await ref.read(repoProvider).setSetting('driveNeedsReconnect', '');
    final r = await ref.read(syncProvider).run();
    if (mounted) setState(() => _set(_describe(r), !r.needsKey));
  });

  Future<void> _syncNow({String? key}) => _do(() async {
    final r = await ref.read(syncProvider).run(typedKey: key);
    if (!mounted) return;
    setState(() => _set(r.needsKey && key != null ? context.t('restore_wrong_key') : _describe(r), !r.needsKey));
  });

  Future<void> _enterKey() async {
    final k = await askRecoveryKey(context, title: context.t('drive_needs_key'), body: context.t('drive_needs_key_body'));
    if (k != null && k.trim().isNotEmpty) await _syncNow(key: k);
  }

  Future<void> _disconnect() => _do(() async {
    final drive = await ref.read(driveServiceProvider.future);
    await drive.disconnect();
    await ref.read(repoProvider).setSetting('driveEmail', '');
  });

  Future<void> _saveClientId() async {
    await ref.read(repoProvider).setSetting('driveClientId', _clientId.text.trim());
    ref.invalidate(driveClientIdProvider);
    ref.invalidate(driveServiceProvider);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('drive_saved'))));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final last = DateTime.tryParse(_lastSync ?? '');
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                ScreenHeader(back: true, title: context.t('drive_title')),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                    children: [
                      GsvCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon3D('cloud', size: 56),
                            const SizedBox(width: 12),
                            Expanded(child: Text(context.t('drive_intro'), style: const TextStyle(fontSize: 16, height: 1.55))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      GsvCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _email == null ? context.t('drive_not_connected') : '${context.t('drive_connected_as')}: $_email',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
                            ),
                            Text(
                              '${context.t('drive_last_sync')}: ${last == null ? context.t('backup_never') : friendlyDate(context, last)}',
                              style: TextStyle(fontSize: 15, color: c.mute),
                            ),
                          ],
                        ),
                      ),
                      if (_needsKey) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: c.alertBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: c.alertBorder, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon3D('key', size: 44),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      context.t('drive_needs_key'),
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(context.t('drive_needs_key_body'), style: const TextStyle(fontSize: 15, height: 1.5)),
                              const SizedBox(height: 10),
                              FilledButton(
                                style: FilledButton.styleFrom(minimumSize: const Size(48, 52)),
                                onPressed: _busy ? null : _enterKey,
                                child: Text(context.t('drive_enter_key'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_email == null || _reconnect)
                        PrimaryButton(label: context.t('drive_connect'), icon: 'cloud', onPressed: _busy ? null : _connect)
                      else
                        PrimaryButton(
                          label: _busy ? context.t('drive_syncing') : context.t('drive_sync_now'),
                          icon: 'cloud',
                          onPressed: _busy ? null : _syncNow,
                        ),
                      if (_busy) ...[const SizedBox(height: 12), const LinearProgressIndicator()],
                      if (_message != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _message!,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ok ? GsvColors.good : GsvColors.bad),
                        ),
                      ],
                      if (_email != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy ? null : _disconnect,
                          child: Text(context.t('drive_disconnect'), style: TextStyle(fontSize: 15, color: c.mute)),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Card(
                        elevation: 0,
                        color: c.tint,
                        child: ExpansionTile(
                          leading: const Icon3D('settings', size: 44),
                          title: Text(context.t('drive_setup_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            _copyRow('Package name', appPackage),
                            _copyRow('SHA-1', releaseSha1),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _clientId,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(labelText: context.t('drive_client_id'), hintText: '…apps.googleusercontent.com'),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: _saveClientId,
                                child: Text(context.t('save'), style: const TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
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

  Widget _copyRow(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: const TextStyle(fontSize: 13)),
    subtitle: SelectableText(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    trailing: IconButton(
      tooltip: 'Copy',
      icon: const Icon(Icons.copy_rounded),
      onPressed: () => Clipboard.setData(ClipboardData(text: value)),
    ),
  );
}
