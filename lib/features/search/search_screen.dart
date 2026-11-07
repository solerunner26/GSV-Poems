import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/text/text_tools.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';
import '../../data/db/database.dart';
import '../common/poem_tile.dart';

/// Any 3 letters list every poem that contains them, in Gujarati, Hindi or
/// English letters ("prem" also finds પ્રેમ and प्रेम).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  String? _lang;
  List<Poem> _results = const [];
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _q.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 220), _run);
      setState(() {});
    });
  }

  Future<void> _run() async {
    final text = _q.text;
    if (text.trim().runes.length < 3) {
      setState(() {
        _results = const [];
        _searched = false;
      });
      return;
    }
    final r = await ref.read(repoProvider).search(text, lang: _lang);
    if (!mounted || text != _q.text) return;
    setState(() {
      _results = r;
      _searched = true;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final lang = context.lang;
    final chips = <(String?, String)>[(null, 'filter_all'), ('gu', 'lang_gu'), ('hi', 'lang_hi'), ('en', 'lang_en')];
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(children: [
            ScreenHeader(title: context.t('nav_search'), actions: const [HelpButton('search')]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: _q,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: 20, color: c.ink),
                decoration: InputDecoration(
                  hintText: context.t('search_hint'),
                  prefixIcon: const Padding(padding: EdgeInsets.all(6), child: Icon3D('search', size: 40)),
                  suffixIcon: _q.text.isEmpty
                      ? null
                      : IconButton(tooltip: context.t('close'), icon: const Icon(Icons.close_rounded), onPressed: _q.clear),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (code, key) in chips)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(code == null ? context.t(key) : tr(key, langFromCode(code)), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        selected: _lang == code,
                        showCheckmark: false,
                        selectedColor: c.primary.withValues(alpha: 0.18),
                        onSelected: (_) {
                          setState(() => _lang = code);
                          _run();
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _searched ? '${localDigits(_results.length, lang)} ${context.t('found')}' : (_q.text.isEmpty ? context.t('cross_script') : context.t('search_min3')),
                  style: TextStyle(fontSize: 15, color: c.mute),
                ),
              ),
            ),
            Expanded(
              child: _searched && _results.isEmpty
                  ? ListView(children: [EmptyState(icon: 'search', text: context.t('no_results'))])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 140),
                      itemCount: _results.length,
                      itemBuilder: (_, i) => _Result(poem: _results[i], query: _q.text, onTap: () => openPoem(context, _results, i)),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.poem, required this.query, required this.onTap});
  final Poem poem;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    final font = poemFont(poem.lang);
    final q = query.trim().toLowerCase();
    final lines = poem.body.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final hitLine = lines.firstWhere((l) => l.toLowerCase().contains(q), orElse: () => lines.isEmpty ? '' : lines.first);
    final at = hitLine.toLowerCase().indexOf(q);
    final base = TextStyle(fontFamily: font, fontSize: 16, height: 1.6, color: c.mute);
    final snippet = at < 0
        ? TextSpan(text: hitLine, style: base)
        : TextSpan(style: base, children: [
            TextSpan(text: hitLine.substring(0, at)),
            TextSpan(
              text: hitLine.substring(at, at + q.length),
              style: TextStyle(backgroundColor: c.accent.withValues(alpha: 0.35), color: c.ink, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: hitLine.substring(at + q.length)),
          ]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GsvCard(
        onTap: onTap,
        radius: 18,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(poemTitle(poem),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: font, fontSize: 18, fontWeight: FontWeight.w700, color: c.ink)),
            ),
            if (poem.number != null)
              Text('#${localDigits(poem.number!, context.lang)}', style: TextStyle(fontSize: 13, color: c.accentText, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 2),
          Text.rich(snippet, maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
