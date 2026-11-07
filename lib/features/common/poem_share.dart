import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/db/database.dart';
import 'poem_tile.dart';

const logoMarkAsset = 'assets/images/logo_mark.png';

/// Asks whether to send the poem as a picture or as text, then shares it.
Future<void> sharePoem(BuildContext context, Poem poem) async {
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Text(ctx.t('share_how'), style: Theme.of(ctx).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon3D('photo', size: 44),
            title: Text(ctx.t('share_image'), style: const TextStyle(fontSize: 18)),
            subtitle: Text(ctx.t('share_image_sub'), style: const TextStyle(fontSize: 14)),
            onTap: () => Navigator.pop(ctx, 'image'),
          ),
          ListTile(
            leading: const Icon3D('write', size: 44),
            title: Text(ctx.t('share_text'), style: const TextStyle(fontSize: 18)),
            subtitle: Text(ctx.t('share_text_sub'), style: const TextStyle(fontSize: 14)),
            onTap: () => Navigator.pop(ctx, 'text'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  final lang = langFromCode(poem.lang);
  final text = '${poemTitle(poem)}\n\n${poem.body.trim()}\n\n— ${tr('poet_name', lang)}';
  if (choice == 'text') {
    await SharePlus.instance.share(ShareParams(text: text, subject: poemTitle(poem)));
    return;
  }
  final colors = context.gc;
  final messenger = ScaffoldMessenger.of(context);
  final working = context.t('share_making');
  messenger.showSnackBar(SnackBar(content: Text(working), duration: const Duration(seconds: 2)));
  final jpg = await poemJpeg(poem, colors);
  final dir = Directory(p.join((await getTemporaryDirectory()).path, 'share'));
  await dir.create(recursive: true);
  final name = 'poem_${poem.number ?? poem.id.substring(0, 8)}.jpg';
  final file = File(p.join(dir.path, name));
  await file.writeAsBytes(jpg, flush: true);
  messenger.hideCurrentSnackBar();
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'image/jpeg', name: name)],
      subject: poemTitle(poem),
    ),
  );
}

Future<ui.Image> _loadLogo() async {
  final data = await rootBundle.load(logoMarkAsset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  return (await codec.getNextFrame()).image;
}

/// Draws the poem as a card in the active theme's colours and encodes it as JPEG.
Future<Uint8List> poemJpeg(Poem poem, GsvColors c) async {
  const width = 1080.0, pad = 96.0, logoSize = 150.0;
  final lang = langFromCode(poem.lang);
  final font = poemFont(poem.lang);
  TextPainter lay(String s, TextStyle style) => TextPainter(
    text: TextSpan(text: s, style: style),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(minWidth: width - 2 * pad, maxWidth: width - 2 * pad);

  final title = lay(poemTitle(poem), TextStyle(fontFamily: font, fontSize: 58, height: 1.25, fontWeight: FontWeight.w700, color: c.ink));
  var size = 40.0;
  var body = lay(poem.body.trim(), TextStyle(fontFamily: font, fontSize: size, height: 1.8, color: c.ink));
  // Keep very long poems to a shareable height.
  while (body.height > 5600 && size > 24) {
    size -= 2;
    body = lay(poem.body.trim(), TextStyle(fontFamily: font, fontSize: size, height: 1.8, color: c.ink));
  }
  final sign = lay('— ${tr('poet_name', lang)}', TextStyle(fontSize: 32, fontStyle: FontStyle.italic, color: c.mute));
  final height = (pad + logoSize + 28 + title.height + 44 + body.height + 64 + sign.height + pad).ceilToDouble();

  final logo = await _loadLogo();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, width, height);
  canvas.drawRect(rect, Paint()..color = c.surface);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.8, -1),
        radius: 1.2,
        colors: [
          c.glow.withValues(alpha: c.isDark ? 0.16 : 0.10),
          c.glow.withValues(alpha: 0),
        ],
      ).createShader(rect),
  );
  final src = Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble());
  // Faint watermark.
  final wm = (width * 0.78).clamp(0.0, height * 0.8);
  canvas.drawImageRect(
    logo,
    src,
    Rect.fromCenter(center: rect.center, width: wm, height: wm),
    Paint()..colorFilter = ColorFilter.mode(c.ink.withValues(alpha: c.isDark ? 0.07 : 0.06), BlendMode.srcIn),
  );
  // Frame.
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect.deflate(34), const Radius.circular(36)),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = c.accentText.withValues(alpha: 0.6),
  );
  var y = pad;
  canvas.drawImageRect(
    logo,
    src,
    Rect.fromLTWH((width - logoSize) / 2, y, logoSize, logoSize),
    Paint()..colorFilter = c.isDark ? ColorFilter.mode(c.accentText, BlendMode.srcIn) : null,
  );
  y += logoSize + 28;
  title.paint(canvas, Offset(pad, y));
  y += title.height + 44;
  body.paint(canvas, Offset(pad, y));
  y += body.height + 64;
  sign.paint(canvas, Offset(pad, y));

  final image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
  final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  logo.dispose();
  return compute(_encodeJpg, (raw!.buffer.asUint8List(), width.toInt(), height.toInt()));
}

Uint8List _encodeJpg((Uint8List, int, int) args) {
  final (rgba, w, h) = args;
  final im = img.Image.fromBytes(width: w, height: h, bytes: rgba.buffer, numChannels: 4, order: img.ChannelOrder.rgba);
  return img.encodeJpg(im, quality: 92);
}
