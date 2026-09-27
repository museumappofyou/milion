import 'package:flutter/material.dart';

import '../models/scene.dart';
import '../theme/milion_theme.dart';
import '../services/notes_service.dart';

class SceneDetailSheet extends StatefulWidget {
  const SceneDetailSheet({
    super.key,
    required this.scene,
    this.confidence,
    this.onExamine,
  });

  final Scene scene;
  final double? confidence;

  /// Opens a painted relief when one is available for this scene.
  final VoidCallback? onExamine;

  @override
  State<SceneDetailSheet> createState() => _SceneDetailSheetState();
}

class _SceneDetailSheetState extends State<SceneDetailSheet> {
  final NotesService _notes = NotesService();
  final TextEditingController _noteController = TextEditingController();
  bool _loaded = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _notes.noteFor(widget.scene.id).then((note) {
      if (!mounted) {
        return;
      }
      setState(() {
        _noteController.text = note;
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _notes.saveNote(widget.scene.id, _noteController.text);
    if (!mounted) {
      return;
    }
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Note saved for ${widget.scene.id}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scene.id, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text(
                  scene.prettyTitle,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Tag(label: scene.room),
                  _Tag(label: scene.surface),
                  if (scene.artworkType.isNotEmpty)
                    _Tag(label: scene.artworkType),
                ],
              ),
              if (widget.confidence != null) ...[
                const SizedBox(height: 8),
                Text(
                  'model match ${(widget.confidence! * 100).toStringAsFixed(0)}% · unverified',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
              if (scene.summary.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(scene.summary, style: theme.textTheme.bodyMedium),
              ],
              if (scene.cues.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Look for', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [for (final cue in scene.cues) _Tag(label: cue)],
                ),
              ],
              if (widget.onExamine != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onExamine!.call();
                    },
                    icon: const Icon(Icons.threed_rotation, size: 18),
                    label: const Text('Explore painted relief'),
                  ),
                ),
              ],
              if (scene.position.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Where', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(scene.position, style: theme.textTheme.bodySmall),
              ],
              const Divider(height: 32),
              Text('Your note', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 5,
                enabled: _loaded,
                onChanged: (_) {
                  if (_saved) {
                    setState(() => _saved = false);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Write a small note about this scene...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (_saved)
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF2E7D32),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Saved',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _loaded ? _save : null,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save note'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MilionTheme.parchment,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
