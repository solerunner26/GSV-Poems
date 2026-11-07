import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/update/update_service.dart';

/// Checks GitHub for a newer version. With [quiet] (on app open) nothing is
/// shown unless an update exists; from Settings it also says "up to date".
Future<void> checkForUpdate(BuildContext context, {bool quiet = true}) async {
  final info = await PackageInfo.fromPlatform();
  final current = int.tryParse(info.buildNumber) ?? 0;
  final release = await UpdateService().check(current);
  if (!context.mounted) return;
  if (release == null) {
    if (!quiet) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.t('up_to_date')} · ${info.version}')));
    }
    return;
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDialog(release: release, currentVersion: info.version),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.release, required this.currentVersion});
  final ReleaseInfo release;
  final String currentVersion;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  double? _progress;
  String? _error;

  Future<void> _update() async {
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      final path = await UpdateService().download(widget.release, (p) {
        if (mounted) setState(() => _progress = p);
      });
      // Opens Android's installer. The poems stay: an update keeps all app data.
      final r = await OpenFilex.open(path, type: 'application/vnd.android.package-archive');
      if (r.type != ResultType.done && mounted) setState(() => _error = r.message);
      if (mounted && r.type == ResultType.done) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final r = widget.release;
    final mb = r.apkSize > 0 ? ' · ${(r.apkSize / 1048576).toStringAsFixed(0)} MB' : '';
    return AlertDialog(
      icon: const Icon3D('download', size: 64),
      title: Text(context.t('update_title'), textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${r.name}$mb',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
          ),
          Text('${context.t('update_current')}: ${widget.currentVersion}', style: TextStyle(fontSize: 14, color: c.mute)),
          const SizedBox(height: 8),
          Text(context.t('update_safe'), style: const TextStyle(fontSize: 16, height: 1.5)),
          if (r.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                child: Text(r.notes.trim(), style: TextStyle(fontSize: 14, color: c.mute)),
              ),
            ),
          ],
          if (_progress != null) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(value: _progress == 0 ? null : _progress),
            const SizedBox(height: 4),
            Text('${context.t('update_downloading')} ${((_progress ?? 0) * 100).round()}%', style: TextStyle(fontSize: 14, color: c.mute)),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text('${context.t('update_failed')}\n$_error', style: const TextStyle(fontSize: 14, color: GsvColors.bad)),
          ],
        ],
      ),
      actions: [
        if (_progress == null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t('update_later'), style: const TextStyle(fontSize: 17)),
          ),
        if (_progress == null)
          SizedBox(
            width: 180,
            child: PrimaryButton(label: context.t('update_now'), height: 52, onPressed: _update),
          ),
      ],
    );
  }
}
