import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/security/pin_service.dart';
import '../../data/sync/sync_service.dart';
import '../backup/backup_screens.dart';
import 'drive_screen.dart';

/// Maker and model of this device ('' in tests or off Android).
typedef DeviceModel = ({String maker, String model});

final deviceModelProvider = FutureProvider<DeviceModel>((ref) async {
  try {
    final a = await DeviceInfoPlugin().androidInfo;
    return (maker: a.manufacturer.toLowerCase(), model: a.model.toUpperCase());
  } on Object {
    return (maker: '', model: '');
  }
});

/// The poet's own devices: his Nothing phone and the Galaxy Tab S7 family
/// (SM-T87x Tab S7, SM-T97x Tab S7+, SM-T73x Tab S7 FE). These add and edit
/// poems; every other device only reads, until his PIN unlocks it.
bool isPoetDevice(DeviceModel d) =>
    d.maker == 'nothing' || d.model.startsWith('SM-T87') || d.model.startsWith('SM-T97') || d.model.startsWith('SM-T73');

/// Only his phone publishes its PIN check (the "PIN of the Nothing phone").
bool publishesOwnerPin(DeviceModel d) => d.maker == 'nothing';

/// May this device add, edit or remove writing?
final canWriteProvider = FutureProvider<bool>((ref) async {
  if (await ref.watch(repoProvider).getSetting('writerUnlocked') == '1') return true;
  return isPoetDevice(await ref.watch(deviceModelProvider.future));
});

/// Call before any change to the collection. Returns true when this device may
/// write; otherwise asks once for the PIN of the poet's phone.
Future<bool> ensureCanWrite(BuildContext context, WidgetRef ref) async {
  if (await ref.read(canWriteProvider.future)) return true;
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(context: context, builder: (_) => const _UnlockDialog());
  return ok ?? false;
}

class _UnlockDialog extends ConsumerStatefulWidget {
  const _UnlockDialog();

  @override
  ConsumerState<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends ConsumerState<_UnlockDialog> {
  final _pin = TextEditingController();
  String? _error;
  bool _busy = false;
  int _fails = 0;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (!PinService.isValidPin(_pin.text)) {
      setState(() => _error = context.t('pin_4_digits'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final t = context.t;
    try {
      final sync = ref.read(syncProvider);
      if (!await sync.connected()) {
        setState(() => _error = t('writer_need_drive'));
        return;
      }
      final drive = await ref.read(driveServiceProvider.future);
      if (!await drive.signInQuietly()) {
        setState(() => _error = t('writer_need_drive'));
        return;
      }
      final repo = ref.read(repoProvider);
      final verifier = await SyncService(repo, ref.read(backupServiceProvider), drive).fetchOwnerVerifier();
      if (verifier == null) {
        setState(() => _error = t('writer_no_owner'));
        return;
      }
      if (await PinService.matches(verifier, _pin.text)) {
        await repo.setSetting('writerUnlocked', '1');
        ref.invalidate(canWriteProvider);
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      _fails++;
      setState(() => _error = t('pin_wrong'));
      if (_fails >= 5) {
        await Future<void>.delayed(const Duration(seconds: 30));
        _fails = 0;
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = '${t('drive_failed')}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon3D('lock', size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.t('writer_title'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(context.t('writer_body'), style: TextStyle(fontSize: 15.5, height: 1.45, color: c.mute)),
            const SizedBox(height: 14),
            TextField(
              controller: _pin,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w700, color: c.ink),
              decoration: InputDecoration(counterText: '', hintText: '••••', errorText: _error, errorMaxLines: 3),
              onSubmitted: (_) => _unlock(),
            ),
            const SizedBox(height: 14),
            PrimaryButton(label: context.t('writer_unlock'), icon: 'key', height: 54, onPressed: _busy ? null : _unlock),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: Text(context.t('update_later'), style: TextStyle(fontSize: 16, color: c.mute)),
            ),
          ],
        ),
      ),
    );
  }
}
