import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';

/// Write a new poem ([poemId] null) or edit one. Saves itself a moment after
/// each change; the text as it was before editing goes to the edit history once.
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.poemId});
  final String? poemId;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _undo = UndoHistoryController();
  final _speech = SpeechToText();
  String? _id;
  String? _categoryId;
  bool _loaded = false;
  bool _versionTaken = false;
  bool _dirty = false;
  bool _listening = false;
  bool _savedOnce = false;
  String _partial = '';
  Timer? _debounce;
  int? _number;
  // Read once: the final save in dispose() runs after ref is gone.
  late final _repo = ref.read(repoProvider);

  @override
  void initState() {
    super.initState();
    _id = widget.poemId;
    _title.addListener(_changed);
    _body.addListener(_changed);
    _load();
  }

  Future<void> _load() async {
    if (_id != null) {
      final p = await _repo.getPoem(_id!);
      if (p != null) {
        _title.text = p.title;
        _body.text = p.body;
        _categoryId = p.categoryId;
        _number = p.number;
      }
    }
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _dirty = false;
    });
  }

  void _changed() {
    if (!_loaded) return;
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _save);
    setState(() {});
  }

  Future<void> _save() async {
    _debounce?.cancel();
    if (!_dirty) return;
    final title = _title.text, body = _body.text;
    if (body.trim().isEmpty) return;
    final repo = _repo;
    if (_id == null) {
      _id = await repo.createPoem(title: title, body: body, categoryId: _categoryId);
      _number = (await repo.getPoem(_id!))?.number;
      _versionTaken = true;
    } else {
      await repo.updatePoem(_id!, title: title, body: body, categoryId: _categoryId, keepVersion: !_versionTaken);
      _versionTaken = true;
    }
    _dirty = false;
    _savedOnce = true;
    if (mounted) setState(() {});
  }

  Future<void> _saveAndClose() async {
    if (_body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('empty_poem'))));
      return;
    }
    await _stopListening();
    await _save();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final text = context.t('saved');
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  PoemLang get _poemLang => _body.text.trim().length > 12 ? detectLang('${_title.text} ${_body.text}') : context.lang;

  Future<void> _toggleMic() async {
    if (_listening) {
      await _stopListening();
      return;
    }
    final ok = await _speech.initialize(onStatus: (s) {
      if ((s == 'done' || s == 'notListening') && mounted) setState(() => _listening = false);
    });
    if (!ok) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t('voice_unavailable'))));
      return;
    }
    final localeId = switch (_poemLang) {
      PoemLang.hi => 'hi_IN',
      PoemLang.en => 'en_IN',
      PoemLang.gu => 'gu_IN',
    };
    setState(() => _listening = true);
    await _speech.listen(
      onResult: _onSpeech,
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        pauseFor: const Duration(seconds: 6),
        listenFor: const Duration(minutes: 2),
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  void _onSpeech(SpeechRecognitionResult r) {
    if (!r.finalResult) {
      setState(() => _partial = r.recognizedWords);
      return;
    }
    final words = r.recognizedWords.trim();
    setState(() => _partial = '');
    if (words.isEmpty) return;
    final sel = _body.selection;
    final text = _body.text;
    final at = sel.isValid ? sel.end : text.length;
    final needsSpace = at > 0 && !RegExp(r'\s$').hasMatch(text.substring(0, at));
    final insert = '${needsSpace ? ' ' : ''}$words';
    _body.value = TextEditingValue(
      text: text.replaceRange(at, at, insert),
      selection: TextSelection.collapsed(offset: at + insert.length),
    );
  }

  Future<void> _stopListening() async {
    if (_listening) await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_dirty) _save();
    _speech.cancel();
    _title.dispose();
    _body.dispose();
    _undo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final cats = ref.watch(categoriesProvider).asData?.value ?? const [];
    final poemLang = _poemLang;
    final words = wordCount(_body.text);
    return LangScope(
      lang: poemLang,
      child: Builder(builder: (context) {
        final status = _savedOnce && !_dirty
            ? '✓ ${context.t('autosaved')} · ${localDigits(words, poemLang)} ${context.t('words')}'
            : '${localDigits(words, poemLang)} ${context.t('words')}';
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(children: [
                  ScreenHeader(
                    back: true,
                    title: widget.poemId == null ? context.t('editor_new') : context.t('editor_edit'),
                    subtitle: _number == null ? status : '#${localDigits(_number!, poemLang)} · $status',
                    actions: [
                      Icon3DButton('undo', label: context.t('undo'), size: 44, onPressed: () => _undo.undo()),
                      const HelpButton('editor'),
                    ],
                  ),
                  Expanded(
                    child: !_loaded
                        ? const Center(child: CircularProgressIndicator())
                        : ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 16), children: [
                            TextField(
                              controller: _title,
                              textCapitalization: TextCapitalization.sentences,
                              style: TextStyle(fontFamily: poemFont(poemLang.name), fontSize: 20, fontWeight: FontWeight.w700, color: c.ink),
                              decoration: InputDecoration(labelText: context.t('title_hint')),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              child: ListView(scrollDirection: Axis.horizontal, children: [
                                for (final cat in cats)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      avatar: Icon3D(cat.iconKey, size: 30),
                                      label: Text(categoryName(cat, context.lang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      selected: _categoryId == cat.id,
                                      showCheckmark: false,
                                      selectedColor: c.primary.withValues(alpha: 0.18),
                                      onSelected: (on) {
                                        setState(() => _categoryId = on ? cat.id : null);
                                        _changed();
                                      },
                                    ),
                                  ),
                              ]),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              constraints: const BoxConstraints(minHeight: 340),
                              padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: c.ink.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
                              ),
                              child: CustomPaint(
                                painter: _LinedPaper(color: c.accent.withValues(alpha: 0.22), lineHeight: 38),
                                child: TextField(
                                  controller: _body,
                                  undoController: _undo,
                                  maxLines: null,
                                  minLines: 9,
                                  keyboardType: TextInputType.multiline,
                                  style: TextStyle(fontFamily: poemFont(poemLang.name), fontSize: 21, height: 38 / 21, color: c.ink),
                                  decoration: InputDecoration(
                                    hintText: context.t('body_hint'),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ),
                            if (_partial.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('… $_partial', style: TextStyle(fontFamily: poemFont(poemLang.name), fontSize: 18, color: c.accentText)),
                              ),
                            const SizedBox(height: 8),
                            Text(context.t('keyboard_tip'), style: TextStyle(fontSize: 14, color: c.mute)),
                          ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                    child: Row(children: [
                      Expanded(
                        child: SizedBox(
                          height: 60,
                          child: OutlinedButton(
                            onPressed: _toggleMic,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _listening ? c.accent : c.surface,
                              foregroundColor: _listening ? Colors.white : c.primary,
                              side: BorderSide(color: _listening ? c.accent : c.primary, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon3D('mic', size: 40),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(_listening ? context.t('listening') : context.t('voice'),
                                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: PrimaryButton(label: context.t('save'), icon: 'check', onPressed: _saveAndClose)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Faint ruled lines behind the poem text.
class _LinedPaper extends CustomPainter {
  _LinedPaper({required this.color, required this.lineHeight});
  final Color color;
  final double lineHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_LinedPaper old) => old.color != color || old.lineHeight != lineHeight;
}
