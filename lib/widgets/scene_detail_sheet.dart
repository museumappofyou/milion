import 'package:flutter/material.dart';

import '../models/scene.dart';
import '../services/notes_service.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';

class SceneDetailSheet extends StatefulWidget {
  const SceneDetailSheet({
    super.key,
    required this.scene,
    this.confidence,
    this.onExamine,
  });
  final Scene scene;
  final double? confidence;
  final VoidCallback? onExamine;
  @override
  State<SceneDetailSheet> createState() => _SceneDetailSheetState();
}

class _SceneDetailSheetState extends State<SceneDetailSheet> {
  final _notes = NotesService(), _noteController = TextEditingController();
  bool _loaded = false, _saved = false;
  @override
  void initState() {
    super.initState();
    _notes.noteFor(widget.scene.id).then((note) {
      if (mounted) {
        setState(() {
          _noteController.text = note;
          _loaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _notes.saveNote(widget.scene.id, _noteController.text);
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.noteSaved(widget.scene.id))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.scene, s = context.l10n, theme = Theme.of(context);
    return DimensionSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.id, style: TypeRole.measurement),
          const SizedBox(height: 8),
          Text(a.prettyTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text('${a.room} · ${a.surface}'),
          if (widget.confidence != null) ...[
            const SizedBox(height: 8),
            Text(
              s.modelMatch('${(widget.confidence! * 100).round()}'),
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (context.language == 'tr') ...[
            const SizedBox(height: 8),
            Text(s.contentEnglish, style: theme.textTheme.bodySmall),
          ],
          if (a.summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(a.summary),
          ],
          if (a.cues.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(s.lookFor, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(a.cues.join(' · ')),
          ],
          if (widget.onExamine != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onExamine!();
              },
              icon: const PlanIcon(PlanSymbol.layers),
              label: Text(s.exploreRelief),
            ),
          ],
          if (a.position.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(s.where, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(a.position),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Text(s.yourNote, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 5,
            enabled: _loaded,
            onChanged: (_) => setState(() => _saved = false),
            decoration: InputDecoration(hintText: s.noteHint),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                onPressed: _loaded ? _save : null,
                child: Text(s.saveNote),
              ),
              if (_saved) Text(s.saved),
            ],
          ),
        ],
      ),
    );
  }
}
