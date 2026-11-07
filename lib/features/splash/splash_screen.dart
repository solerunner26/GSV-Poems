import 'package:flutter/material.dart';

import '../../core/l10n/strings.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';

/// Poet's photo in a temple-arch frame, the logo, and one big "Enter" button.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.onEnter});
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final wide = MediaQuery.sizeOf(context).shortestSide >= 600;
    final photoW = wide ? 300.0 : 230.0;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1),
            radius: 1.3,
            colors: [c.surface, c.bg, c.tint],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: Column(children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(photoW * 0.68), bottom: const Radius.circular(30)),
                      border: Border.all(color: c.accent, width: 1.5),
                      boxShadow: [BoxShadow(color: c.ink.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, 18))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(photoW * 0.65), bottom: const Radius.circular(24)),
                      child: Image.asset('assets/images/poet_photo.webp',
                          width: photoW, height: photoW * 1.24, fit: BoxFit.cover, semanticLabel: context.t('poet_name')),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: c.ink.withValues(alpha: 0.1), blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset('assets/images/logo_source.webp', width: 96, height: 96, fit: BoxFit.cover, semanticLabel: 'Gaurav'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(context.t('app_title'),
                      style: TextStyle(fontFamily: 'NotoSerifGujarati', fontSize: 30, fontWeight: FontWeight.w700, color: c.ink)),
                  Text(context.t('poet_name'), style: TextStyle(fontSize: 17, color: c.mute)),
                  const Spacer(),
                  PrimaryButton(label: context.t('enter'), onPressed: onEnter),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
