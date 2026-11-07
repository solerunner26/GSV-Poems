import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/import/keep_parser.dart';
import '../../data/poem_repository.dart';
import '../duplicates/duplicates_screen.dart';

/// Pick Google Takeout Keep .json files, preview what was found, then add.
class KeepImportScreen extends ConsumerStatefulWidget {
  const KeepImportScreen({super.key});

  @override
  ConsumerState<KeepImportScreen> createState() => _KeepImportScreenState();
}

class _KeepImportScreenState extends ConsumerState<KeepImportScreen> {
  KeepParseResult? _result;
  ImportOutcome? _outcome;
  bool _busy = false;

  Future<void> _pick() async {
    final picked = await FilePicker.pickFiles(type: FileType.any);
    if (picked.isEmpty) return;
    setState(() {
      _busy = true;
      _outcome = null;
    });
    final files = <String, String>{};
    for (final f in picked) {
      if (!f.name.toLowerCase().endsWith('.json')) continue;
      files[f.name] = utf8.decode(await f.readAsBytes(), allowMalformed: true);
    }
    final r = parseKeepTakeout(files);
    if (!mounted) return;
    setState(() {
      _result = r;
      _busy = false;
    });
  }

  Future<void> _import() async {
    final r = _result;
    if (r == null || r.poems.isEmpty) return;
    setState(() => _busy = true);
    final out = await ref.read(repoProvider).importPoems(r.poems);
    if (!mounted) return;
    setState(() {
      _outcome = out;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lang = context.lang;
    final r = _result;
    final byCollection = <String, int>{};
    for (final p in r?.poems ?? const <ImportedPoem>[]) {
      byCollection[p.collection] = (byCollection[p.collection] ?? 0) + 1;
    }
    final missing = [for (final n in r?.notes ?? const <NoteSummary>[]) if (n.missing.isNotEmpty) n];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(children: [
              ScreenHeader(back: true, title: context.t('keep_import')),
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(18, 6, 18, 24), children: [
                  GsvCard(
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon3D('download', size: 56),
                      const SizedBox(width: 12),
                      Expanded(child: Text(context.t('keep_how'), style: const TextStyle(fontSize: 17, height: 1.55))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: context.t('keep_pick'), icon: 'collection', onPressed: _busy ? null : _pick),
                  if (_busy) ...[
                    const SizedBox(height: 18),
                    Center(child: Text(context.t('keep_reading'), style: TextStyle(fontSize: 16, color: c.mute))),
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                  if (r != null && !_busy) ...[
                    const SizedBox(height: 20),
                    if (r.poems.isEmpty)
                      EmptyState(icon: 'search', text: context.t('keep_none'))
                    else ...[
                      Text(
                        '${localDigits(r.poems.length, lang)} ${context.t('keep_found')} · ${localDigits(byCollection.length, lang)} ${context.t('keep_in')}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      for (final e in byCollection.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GsvCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(children: [
                              const Icon3D('collection', size: 42),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(e.key,
                                    style: TextStyle(fontFamily: poemFont(detectLang(e.key).name), fontSize: 18, fontWeight: FontWeight.w700, color: c.ink)),
                              ),
                              Text('${localDigits(e.value, lang)} ${context.t('poems')}', style: TextStyle(fontSize: 15, color: c.mute)),
                            ]),
                          ),
                        ),
                      if (missing.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(context.t('keep_missing'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.accentText)),
                        for (final n in missing)
                          Text('${n.collection}: #${n.missing.map((x) => localDigits(x, lang)).join(', #')}', style: TextStyle(fontSize: 15, color: c.mute)),
                      ],
                      if (r.problems.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        for (final p in r.problems)
                          Text('⚠ #${p.number ?? '-'} ${p.title} — ${p.problem}', style: const TextStyle(fontSize: 15, color: GsvColors.bad)),
                      ],
                      if (r.skippedNotes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('${context.t('keep_skipped')}: ${localDigits(r.skippedNotes.length, lang)}', style: TextStyle(fontSize: 15, color: c.mute)),
                        ),
                      const SizedBox(height: 18),
                      if (_outcome == null)
                        PrimaryButton(label: '${context.t('keep_add')} (${localDigits(r.poems.length, lang)})', icon: 'check', onPressed: _import)
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: c.alertBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.alertBorder)),
                          child: Row(children: [
                            const Icon3D('shield', size: 52),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${localDigits(_outcome!.added, lang)} ${context.t('keep_done')}'
                                '${_outcome!.alreadyThere > 0 ? ' · ${localDigits(_outcome!.alreadyThere, lang)} ${context.t('keep_already')}' : ''}',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.ink),
                              ),
                            ),
                          ]),
                        ),
                      if (_outcome != null && _outcome!.duplicates > 0) ...[
                        const SizedBox(height: 12),
                        const DuplicateNotice(),
                      ],
                    ],
                  ],
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
