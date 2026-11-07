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
    builder: (_) => UpdateDialog(release: release, currentVersion: info.version),
  );
}

/// Release notes as short points ("- " lines become bullets).
List<String> releasePoints(String notes) => [
  for (final line in notes.split('\n'))
    if (line.trim().replaceFirst(RegExp(r'^[-*•]\s*'), '').isNotEmpty) line.trim().replaceFirst(RegExp(r'^[-*•]\s*'), ''),
];

/// Asks to install a newer version and shows the download.
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.release, required this.currentVersion, @visibleForTesting this.initialProgress});
  final ReleaseInfo release;
  final String currentVersion;

  /// Shows the download state straight away (previews and tests).
  final double? initialProgress;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  late double? _progress = widget.initialProgress;
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
    final newVersion = r.tag.startsWith('v') ? r.tag.substring(1) : r.tag;
    final size = r.apkSize > 0 ? ' · ${(r.apkSize / 1048576).toStringAsFixed(0)} MB' : '';
    final notes = releasePoints(r.notes);
    final busy = _progress != null;
    return Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: c.glow.withValues(alpha: 0.35)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: symbol beside the title, never on top of text.
              Row(
                children: [
                  const Icon3D('download', size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('update_title'),
                          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: c.ink, height: 1.25),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            style: TextStyle(fontSize: 14.5, color: c.mute),
                            children: [
                              TextSpan(text: widget.currentVersion),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.arrow_forward_rounded, size: 16, color: c.accentText),
                                ),
                              ),
                              TextSpan(
                                text: '$newVersion$size',
                                style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Reassurance.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: c.tint, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon3D('shield', size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(context.t('update_safe'), style: TextStyle(fontSize: 15.5, height: 1.45, color: c.ink)),
                    ),
                  ],
                ),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  context.t('update_whats_new'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        for (final n in notes)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8, right: 10),
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(color: c.accentText, shape: BoxShape.circle),
                                  ),
                                ),
                                Expanded(
                                  child: Text(n, style: TextStyle(fontSize: 15, height: 1.45, color: c.mute)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (busy) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(minHeight: 10, value: _progress == 0 ? null : _progress, color: c.primary, backgroundColor: c.tint),
                ),
                const SizedBox(height: 8),
                Text(
                  '${context.t('update_downloading')} ${((_progress ?? 0) * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text('${context.t('update_failed')}\n$_error', style: const TextStyle(fontSize: 14, color: GsvColors.bad)),
              ],
              if (!busy) ...[
                const SizedBox(height: 18),
                PrimaryButton(label: context.t('update_now'), icon: 'download', height: 56, onPressed: _update),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: Text(context.t('update_later'), style: TextStyle(fontSize: 17, color: c.mute)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
