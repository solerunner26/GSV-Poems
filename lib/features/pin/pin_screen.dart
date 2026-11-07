import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/security/pin_service.dart';

enum PinMode { unlock, change }

enum _Step { current, enter, create, confirm }

/// Unlock screen. With no PIN yet it walks through creating one.
/// In [PinMode.change] it asks for the current PIN, then a new one twice.
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key, required this.onUnlocked, this.mode = PinMode.unlock});
  final VoidCallback onUnlocked;
  final PinMode mode;

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _digits = '';
  String? _firstEntry;
  String? _error;
  bool _busy = false;
  bool _bioAvailable = false;
  _Step? _step;
  final _auth = LocalAuthentication();

  PinService get _pins => ref.read(pinServiceProvider);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final has = await _pins.hasPin();
    var bio = false;
    if (has && widget.mode == PinMode.unlock && await _pins.biometricEnabled()) {
      try {
        bio = await _auth.canCheckBiometrics && (await _auth.getAvailableBiometrics()).isNotEmpty;
      } on PlatformException {
        bio = false;
      }
    }
    if (!mounted) return;
    setState(() {
      _bioAvailable = bio;
      _step = widget.mode == PinMode.change ? _Step.current : (has ? _Step.enter : _Step.create);
    });
    if (bio) unawaited(_tryBiometric());
  }

  Future<void> _tryBiometric() async {
    try {
      final ok = await _auth.authenticate(localizedReason: context.t('fingerprint_reason'), biometricOnly: true);
      if (ok && mounted) widget.onUnlocked();
    } on PlatformException {
      // Falls back to the keypad.
    } on LocalAuthException {
      // Falls back to the keypad.
    }
  }

  void _press(int d) {
    if (_busy || _digits.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _digits += '$d';
      _error = null;
    });
    if (_digits.length == 4) _submit();
  }

  void _back() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  Future<void> _submit() async {
    final pin = _digits;
    setState(() => _busy = true);
    String? err;
    switch (_step!) {
      case _Step.enter:
      case _Step.current:
        final r = await _pins.check(pin);
        if (r == PinCheck.ok) {
          if (_step == _Step.current) {
            setState(() => _step = _Step.create);
          } else {
            widget.onUnlocked();
            return;
          }
        } else {
          err = r == PinCheck.lockedOut ? 'pin_locked' : 'pin_wrong';
          HapticFeedback.heavyImpact();
        }
      case _Step.create:
        _firstEntry = pin;
        setState(() => _step = _Step.confirm);
      case _Step.confirm:
        if (pin == _firstEntry) {
          await _pins.setPin(pin);
          if (!mounted) return;
          if (widget.mode == PinMode.change) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('pin_changed'))));
          }
          widget.onUnlocked();
          return;
        }
        err = 'pin_mismatch';
        _firstEntry = null;
        setState(() => _step = _Step.create);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _digits = '';
      _error = err;
    });
  }

  void _forgot() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('pin_forgot')),
        content: Text(context.t('pin_forgot_body'), style: const TextStyle(fontSize: 17, height: 1.5)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('close')))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lang = context.lang;
    final step = _step;
    final (title, sub) = switch (step) {
      _Step.current => ('pin_current', 'pin_enter_sub'),
      _Step.create => ('pin_new', 'pin_new_sub'),
      _Step.confirm => ('pin_confirm', 'pin_enter_sub'),
      _ => ('pin_enter', 'pin_enter_sub'),
    };
    return Scaffold(
      appBar: widget.mode == PinMode.change ? AppBar(backgroundColor: c.bg, foregroundColor: c.primary) : null,
      body: SafeArea(
        child: step == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(children: [
                    const Icon3D('lotus', size: 96, well: true),
                    const SizedBox(height: 14),
                    Text(context.t(title),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'NotoSerifGujarati', fontSize: 26, fontWeight: FontWeight.w700, color: c.ink)),
                    const SizedBox(height: 4),
                    Text(context.t(sub), style: TextStyle(fontSize: 16, color: c.mute)),
                    const SizedBox(height: 22),
                    Semantics(
                      liveRegion: true,
                      label: '${_digits.length} / 4',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(4, (i) {
                          final on = i < _digits.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            margin: const EdgeInsets.symmetric(horizontal: 11),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: on ? c.primary : Colors.transparent,
                              border: Border.all(color: on ? c.primary : c.accent, width: 2),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(
                      height: 44,
                      child: Center(
                        child: _error == null
                            ? (_busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)) : null)
                            : Text(context.t(_error!),
                                textAlign: TextAlign.center, style: const TextStyle(color: GsvColors.bad, fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 26,
                        children: [
                          for (final d in [1, 2, 3, 4, 5, 6, 7, 8, 9]) _Key(label: localDigits(d, lang), semantic: '$d', onTap: () => _press(d)),
                          if (_bioAvailable)
                            _IconKey(icon: 'fingerprint', label: context.t('unlock_fingerprint'), onTap: _tryBiometric)
                          else
                            const SizedBox.shrink(),
                          _Key(label: localDigits(0, lang), semantic: '0', onTap: () => _press(0)),
                          _IconKey(icon: 'undo', label: context.t('delete_digit'), onTap: _back),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (step == _Step.enter)
                      TextButton(
                        onPressed: _forgot,
                        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                        child: Text(context.t('pin_forgot'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.primary)),
                      ),
                  ]),
                ),
              ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.semantic, required this.onTap});
  final String label, semantic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: const CircleBorder(),
        elevation: c.isDark ? 0 : 2,
        shadowColor: c.ink.withValues(alpha: 0.3),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: Text(label, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: c.ink))),
        ),
      ),
    );
  }
}

class _IconKey extends StatelessWidget {
  const _IconKey({required this.icon, required this.label, required this.onTap});
  final String icon, label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(onTap: onTap, child: Center(child: Icon3D(icon, size: 58))),
      );
}
