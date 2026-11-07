import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/icon3d.dart';

/// Symbols offered for a new topic (all from the app's own icon set).
const topicIconChoices = [
  'lotus',
  'bhakti',
  'prem',
  'prakruti',
  'tree',
  'jivan',
  'swirl',
  'parivar',
  'samaj',
  'desh',
  'ghazal',
  'bhajan',
  'hasya',
  'star',
  'spark',
  'flame',
  'wave',
  'sunrise',
  'mountain',
  'hourglass',
  'gift',
  'diya',
  'photo',
  'other',
];

/// Asks for a topic name and a symbol, creates the topic and returns its id
/// (null when cancelled). The same name in Gujarati or Hindi is never added twice.
Future<String?> addTopic(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _NewTopicForm(
        onCreate: (name, icon) async {
          final id = await ref.read(repoProvider).ensureCategory(name, iconKey: icon);
          if (ctx.mounted) Navigator.pop(ctx, id);
        },
      ),
    ),
  );
}

class _NewTopicForm extends StatefulWidget {
  const _NewTopicForm({required this.onCreate});
  final Future<void> Function(String name, String icon) onCreate;

  @override
  State<_NewTopicForm> createState() => _NewTopicFormState();
}

class _NewTopicFormState extends State<_NewTopicForm> {
  final _name = TextEditingController();
  String _icon = topicIconChoices.first;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final n = _name.text.trim();
    if (n.isEmpty) return;
    setState(() => _busy = true);
    await widget.onCreate(n, _icon);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gc;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.t('topic_new'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontFamily: 'NotoSerifGujarati', fontSize: 20, fontWeight: FontWeight.w600),
              decoration: InputDecoration(labelText: context.t('topic_name')),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 14),
            Text(
              context.t('topic_symbol'),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.mute),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in topicIconChoices)
                  Semantics(
                    button: true,
                    selected: key == _icon,
                    label: iconArt[key]?.label ?? key,
                    excludeSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _icon = key),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: key == _icon ? c.primary : Colors.transparent, width: 2.5),
                        ),
                        child: Icon3D(key, size: 48),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            PrimaryButton(label: context.t('topic_add'), icon: 'check', onPressed: _busy ? null : _save),
          ],
        ),
      ),
    );
  }
}
