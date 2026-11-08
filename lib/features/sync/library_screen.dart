import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/security/pin_service.dart';
import '../../data/sync/github_library.dart';
import '../backup/backup_screens.dart';
import 'drive_screen.dart';
import 'writer_gate.dart';

const _tokenKey = 'github_token';

/// Runs the online library: the poet's devices publish, every device reads.
class LibraryCoordinator {
  LibraryCoordinator(this.ref, {this.secrets = const SecureSecretStore()});
  final Ref ref;
  final SecretStore secrets;
  Future<LibraryResult>? _running;

  Future<String?> token() async {
    final t = await secrets.read(_tokenKey);
    return t == null || t.trim().isEmpty ? null : t.trim();
  }

  Future<void> setToken(String? t) => t == null || t.trim().isEmpty ? secrets.delete(_tokenKey) : secrets.write(_tokenKey, t.trim());

  /// Reads (and on the poet's devices, publishes) now. [daily]: readers only
  /// look once a day, the first time the app is opened.
  Future<LibraryResult> run({String? typedKey, bool daily = false}) => _running ??= () async {
    try {
      final repo = ref.read(repoProvider);
      final lib = GithubLibrary(repo, ref.read(backupServiceProvider));
      final tok = await token();
      final writer = await ref.read(canWriteProvider.future);
      await refreshOwnerVerifier(repo, ref.read(pinServiceProvider), await ref.read(deviceModelProvider.future));
      if (typedKey == null && writer && tok != null) return await lib.publish(tok);
      if (daily && typedKey == null && !await lib.dueToday()) return const LibraryResult();
      return await lib.pull(typedKey: typedKey);
    } finally {
      _running = null;
      ref.invalidate(syncNeedsKeyProvider);
      ref.invalidate(libraryStatusProvider);
    }
  }();

  /// The same, never disturbing anyone (offline is fine).
  Future<void> quiet({bool daily = false}) async {
    try {
      await run(daily: daily);
    } on Object {
      // Tried again on the next open or edit.
    }
  }
}

final libraryProvider = Provider<LibraryCoordinator>((ref) => LibraryCoordinator(ref));

typedef LibraryStatus = ({String? checked, String? published, bool needsKey, bool hasToken});

final libraryStatusProvider = FutureProvider<LibraryStatus>((ref) async {
  final repo = ref.watch(repoProvider);
  return (
    checked: await repo.getSetting('libCheckedAt'),
    published: await repo.getSetting('libPublishedAt'),
    needsKey: await repo.getSetting('libNeedsKey') == '1',
    hasToken: await ref.read(libraryProvider).token() != null,
  );
});

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _key = TextEditingController();
  final _token = TextEditingController();
  bool _busy = false;
  String? _message;
  bool _ok = true;

  @override
  void dispose() {
    _key.dispose();
    _token.dispose();
    super.dispose();
  }

  String _when(String? iso) {
    final d = iso == null ? null : DateTime.tryParse(iso);
    if (d == null) return '—';
    return localDigits(DateFormat('d MMM, h:mm a', 'en').format(d), context.lang);
  }

  Future<void> _go({String? typedKey}) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final t = context.t;
    try {
      final r = await ref.read(libraryProvider).run(typedKey: typedKey);
      if (!mounted) return;
      setState(() {
        _ok = !r.needsKey;
        _message = r.needsKey
            ? t(typedKey == null ? 'lib_needs_key' : 'restore_wrong_key')
            : '${t('lib_done')} · ${localDigits(r.added, context.lang)} ${t('restore_added')} · ${localDigits(r.updated, context.lang)} ${t('restore_updated')}'
                  '${r.published ? ' · ${t('lib_published')}' : ''}';
      });
      if (!r.needsKey) _key.clear();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _ok = false;
          _message = '${t('drive_failed')}: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveToken() async {
    await ref.read(libraryProvider).setToken(_token.text);
    _token.clear();
    ref.invalidate(libraryStatusProvider);
    await _go();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final st = ref.watch(libraryStatusProvider).asData?.value;
    final writer = ref.watch(canWriteProvider).asData?.value ?? false;
    final lib = GithubLibrary(ref.read(repoProvider), ref.read(backupServiceProvider));
    TextStyle body = TextStyle(fontSize: 15.5, height: 1.45, color: c.mute);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                ScreenHeader(back: true, title: context.t('lib_title')),
                GsvCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon3D('cloud', size: 52),
                      const SizedBox(width: 12),
                      Expanded(child: Text(context.t('lib_how'), style: body)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GsvCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${context.t('lib_checked')}: ${_when(st?.checked)}', style: TextStyle(fontSize: 15.5, color: c.ink)),
                      Text('${context.t('lib_published_at')}: ${_when(st?.published)}', style: TextStyle(fontSize: 15.5, color: c.ink)),
                      const SizedBox(height: 4),
                      Text(lib.webUrl, style: TextStyle(fontSize: 13, color: c.mute)),
                    ],
                  ),
                ),
                if (st?.needsKey ?? false) ...[
                  const SizedBox(height: 14),
                  Text(
                    context.t('lib_needs_key'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _key,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 18, letterSpacing: 1.5),
                    decoration: InputDecoration(
                      hintText: 'XXXXX-XXXXX-XXXXX-XXXXX-XXXXX',
                      filled: true,
                      fillColor: c.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: context.t('writer_unlock'),
                    icon: 'key',
                    height: 54,
                    onPressed: _busy ? null : () => _go(typedKey: _key.text),
                  ),
                ],
                const SizedBox(height: 14),
                PrimaryButton(
                  label: context.t(writer && (st?.hasToken ?? false) ? 'lib_sync_now' : 'lib_check_now'),
                  icon: 'download',
                  height: 56,
                  onPressed: _busy ? null : _go,
                ),
                if (_busy) ...[const SizedBox(height: 12), const LinearProgressIndicator()],
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_message!, style: TextStyle(fontSize: 15.5, color: _ok ? c.ink : GsvColors.bad)),
                  ),
                if (writer) ...[
                  const SizedBox(height: 24),
                  Text(
                    context.t('lib_token_title'),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(context.t(st?.hasToken ?? false ? 'lib_token_saved' : 'lib_token_how'), style: body),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _token,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      hintText: 'github_pat_…',
                      filled: true,
                      fillColor: c.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : _saveToken,
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                          child: Text(context.t('lib_token_save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      if (st?.hasToken ?? false) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed: _busy
                                ? null
                                : () async {
                                    await ref.read(libraryProvider).setToken(null);
                                    ref.invalidate(libraryStatusProvider);
                                  },
                            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                            child: Text(context.t('lib_token_remove'), style: TextStyle(fontSize: 16, color: c.mute)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
