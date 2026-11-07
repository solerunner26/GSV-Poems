import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'core/l10n/strings.dart';
import 'core/theme/app_themes.dart';
import 'features/pin/pin_screen.dart';
import 'features/shell/shell.dart';
import 'features/splash/splash_screen.dart';

class GsvApp extends ConsumerWidget {
  const GsvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsProvider);
    final colors = themeById(prefs.themeId);
    return MaterialApp(
      title: 'GSV Poems',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(colors),
      locale: Locale(prefs.lang.name),
      supportedLocales: const [Locale('gu'), Locale('hi'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return LangScope(
          lang: prefs.lang,
          child: MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(mq.textScaler.scale(1) * prefs.textScale)),
            child: child!,
          ),
        );
      },
      home: const StartFlow(),
    );
  }
}

enum _Stage { splash, pin, app }

/// Splash → PIN → app. Coming back after 2 minutes in the background asks for the PIN again.
class StartFlow extends StatefulWidget {
  const StartFlow({super.key});

  @override
  State<StartFlow> createState() => _StartFlowState();
}

class _StartFlowState extends State<StartFlow> with WidgetsBindingObserver {
  _Stage _stage = _Stage.splash;
  DateTime? _pausedAt;
  static const _relockAfter = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _stage == _Stage.app) {
      final p = _pausedAt;
      if (p != null && DateTime.now().difference(p) > _relockAfter) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        setState(() => _stage = _Stage.pin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: switch (_stage) {
        _Stage.splash => SplashScreen(key: const ValueKey('splash'), onEnter: () => setState(() => _stage = _Stage.pin)),
        _Stage.pin => PinScreen(key: const ValueKey('pin'), onUnlocked: () => setState(() => _stage = _Stage.app)),
        _Stage.app => const Shell(key: ValueKey('app')),
      },
    );
  }
}
