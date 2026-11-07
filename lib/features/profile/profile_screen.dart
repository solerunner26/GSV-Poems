import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/neon_tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/poem_repository.dart';
import '../../data/profile.dart';
import '../../data/splash_photo.dart';
import '../backup/backup_screens.dart';
import '../pin/pin_screen.dart';
import '../settings/settings_screen.dart';

final profileProvider = FutureProvider<Profile>((ref) => Profile.load(ref.watch(repoProvider)));

/// The poet's photo in a round neon frame: the photo chosen in the profile,
/// or the bundled one.
class PoetAvatar extends StatelessWidget {
  const PoetAvatar({super.key, this.size = 46});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return ValueListenableBuilder<String?>(
      valueListenable: SplashPhoto.chosen,
      builder: (context, chosen, _) {
        final fallback = Image.asset(
          'assets/images/poet_photo.webp',
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.6),
        );
        final photo = chosen == null
            ? fallback
            : Image.file(File(chosen), key: ValueKey(chosen), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback);
        return Container(
          padding: EdgeInsets.all(size * 0.05),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.glow, c.accentDeep]),
            boxShadow: [
              BoxShadow(
                color: c.glow.withValues(alpha: 0.45 * context.neon.glowIntensity),
                blurRadius: size * 0.35,
                blurStyle: BlurStyle.outer,
              ),
            ],
          ),
          child: ClipOval(child: photo),
        );
      },
    );
  }
}

/// Round photo button that opens the profile.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.t('profile'),
    excludeSemantics: true,
    child: Tooltip(
      message: context.t('profile'),
      child: InkResponse(
        radius: size * 0.6,
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
        child: PoetAvatar(size: size),
      ),
    ),
  );
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool? _bio;

  @override
  void initState() {
    super.initState();
    ref.read(pinServiceProvider).biometricEnabled().then((v) {
      if (mounted) setState(() => _bio = v);
    }, onError: (_) {});
  }

  Future<void> _toggleBio(bool on) async {
    if (on) {
      final auth = LocalAuthentication();
      var ok = false;
      try {
        ok = await auth.canCheckBiometrics && (await auth.getAvailableBiometrics()).isNotEmpty;
      } on PlatformException {
        ok = false;
      }
      if (!ok) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('fingerprint_none'))));
        return;
      }
    }
    await ref.read(pinServiceProvider).setBiometric(on);
    if (mounted) setState(() => _bio = on);
  }

  Future<void> _photo() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon3D('photo', size: 44),
              title: Text(ctx.t('splash_photo_pick'), style: const TextStyle(fontSize: 18)),
              onTap: () => Navigator.pop(ctx, 'pick'),
            ),
            if (SplashPhoto.chosen.value != null)
              ListTile(
                leading: const Icon3D('undo', size: 44),
                title: Text(ctx.t('splash_photo_reset'), style: const TextStyle(fontSize: 18)),
                onTap: () => Navigator.pop(ctx, 'reset'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null) return;
    if (choice == 'reset') {
      await SplashPhoto.reset();
    } else {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty) return;
      await SplashPhoto.save(await files.first.readAsBytes());
    }
  }

  void _edit(Profile p) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfileEditScreen(initial: p)));

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lang = context.lang;
    final p = ref.watch(profileProvider).asData?.value ?? const Profile();
    final stats = ref.watch(statsProvider).asData?.value ?? const PoemStats();
    final name = p.name.isEmpty ? context.t('poet_name') : p.name;
    String label(String f) => context.t('profile_$f');
    final details = [
      for (final f in Profile.fields.skip(2))
        if (p[f].trim().isNotEmpty) f,
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              children: [
                ScreenHeader(title: context.t('profile'), back: true),
                const SizedBox(height: 8),
                // Photo, name and pen name.
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const PoetAvatar(size: 132),
                      Positioned(
                        right: -4,
                        bottom: 2,
                        child: Icon3DButton('photo', label: context.t('splash_photo'), size: 48, onPressed: _photo),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'NotoSerifGujarati', fontSize: 24, fontWeight: FontWeight.w700, color: c.ink),
                ),
                if (p.penName.isNotEmpty)
                  Text(
                    '“${p.penName}”',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.accentText),
                  ),
                const SizedBox(height: 16),
                // Writing at a glance.
                Row(
                  children: [
                    Expanded(
                      child: _Stat(value: localDigits(stats.total, lang), label: context.t('poems')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stat(value: localDigits(stats.gu, lang), label: context.t('profile_gu')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Stat(value: localDigits(stats.hi, lang), label: context.t('profile_hi')),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Details.
                SettingsGroup(
                  title: context.t('profile_details'),
                  rows: [
                    for (final f in details) SettingsRow(icon: _fieldIcon(f), title: p[f], sub: label(f), onTap: () => _edit(p)),
                    SettingsRow(icon: 'edit', title: context.t(p.isEmpty ? 'profile_add' : 'profile_edit'), onTap: () => _edit(p)),
                  ],
                ),
                // Personal security.
                SettingsGroup(
                  title: context.t('sec_security'),
                  rows: [
                    SettingsRow(
                      icon: 'lock',
                      title: context.t('change_pin'),
                      sub: '••••',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (routeCtx) => PinScreen(mode: PinMode.change, onUnlocked: () => Navigator.of(routeCtx).pop()),
                        ),
                      ),
                    ),
                    SettingsRow(
                      icon: 'fingerprint',
                      title: context.t('fingerprint'),
                      trailing: Switch(value: _bio ?? false, onChanged: _bio == null ? null : _toggleBio),
                      onTap: _bio == null ? null : () => _toggleBio(!(_bio ?? false)),
                    ),
                    SettingsRow(
                      icon: 'key',
                      title: context.t('recovery_view'),
                      sub: '••••• — PIN',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (routeCtx) => PinScreen(
                            onUnlocked: () =>
                                Navigator.of(routeCtx).pushReplacement(MaterialPageRoute<void>(builder: (_) => const RecoveryKeyScreen())),
                          ),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<String?>(
                      valueListenable: SplashPhoto.chosen,
                      builder: (context, chosen, _) => SettingsRow(
                        icon: 'photo',
                        title: context.t('splash_photo'),
                        sub: context.t(chosen == null ? 'splash_photo_original' : 'splash_photo_custom'),
                        onTap: _photo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _fieldIcon(String f) => switch (f) {
    'birthDate' => 'gift',
    'place' => 'location',
    'phone' => 'bell',
    'email' => 'mail',
    _ => 'write',
  };
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return GsvCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.accentText),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: c.mute),
          ),
        ],
      ),
    );
  }
}

/// Edit form for the profile details.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, required this.initial});
  final Profile initial;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final Map<String, TextEditingController> _c = {for (final f in Profile.fields) f: TextEditingController(text: widget.initial[f])};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final p = Profile.fromMap({for (final e in _c.entries) e.key: e.value.text});
    await p.save(ref.read(repoProvider));
    ref.invalidate(profileProvider);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final msg = context.t('profile_saved');
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    TextInputType keyboard(String f) => switch (f) {
      'phone' => TextInputType.phone,
      'email' => TextInputType.emailAddress,
      'about' => TextInputType.multiline,
      _ => TextInputType.text,
    };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                ScreenHeader(title: context.t('profile_edit'), back: true),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                    children: [
                      for (final f in Profile.fields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: TextField(
                            controller: _c[f],
                            keyboardType: keyboard(f),
                            textCapitalization: TextCapitalization.sentences,
                            minLines: f == 'about' ? 3 : 1,
                            maxLines: f == 'about' ? 8 : 1,
                            style: TextStyle(fontSize: 18, color: c.ink),
                            decoration: InputDecoration(
                              labelText: context.t('profile_$f'),
                              hintText: f == 'name' ? context.t('poet_name') : null,
                              filled: true,
                              fillColor: c.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                  child: PrimaryButton(label: context.t('save'), icon: 'check', onPressed: _saving ? null : _save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
