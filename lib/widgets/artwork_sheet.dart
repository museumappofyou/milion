import 'package:flutter/material.dart';

import '../city/dig_sections.dart' show SourceList;
import '../content/geography.dart' show romanNumeral;
import '../content/models.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../services/notes_service.dart';

/// The typed artwork sheet: catalogue data comes from the registry only.
class ArtworkSheet extends StatefulWidget {
  const ArtworkSheet({
    super.key,
    required this.artwork,
    this.confidence,
    this.onExamine,
    this.onScan,
    this.sources = const [],
  });
  final Artwork artwork;

  /// The artwork's source records, resolved by the caller.
  final List<Source> sources;
  final double? confidence;
  final VoidCallback? onExamine;

  /// Camera-eye action; only for artworks the on-device model can suggest.
  final VoidCallback? onScan;
  @override
  State<ArtworkSheet> createState() => _ArtworkSheetState();
}

class _ArtworkSheetState extends State<ArtworkSheet> {
  final _notes = NotesService(), _noteController = TextEditingController();
  bool _loaded = false, _saved = false;
  @override
  void initState() {
    super.initState();
    _notes.noteFor(widget.artwork.id).then((note) {
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
    await _notes.saveNote(widget.artwork.id, _noteController.text);
    if (!mounted) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.noteSaved(widget.artwork.id))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.artwork, s = context.l10n, lang = context.language;
    final theme = Theme.of(context);
    final summary = a.summary.inLanguage(lang);
    final fallsBackToEnglish =
        lang == 'tr' && (a.summary.tr?.trim().isEmpty ?? true);
    return DimensionSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.id, style: TypeRole.measurement),
          const SizedBox(height: 8),
          Text(a.title.inLanguage(lang), style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text('${a.room.inLanguage(lang)} · ${a.surface.inLanguage(lang)}'),
          if (widget.confidence != null) ...[
            const SizedBox(height: 8),
            Text(
              s.modelMatch('${(widget.confidence! * 100).round()}'),
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (fallsBackToEnglish) ...[
            const SizedBox(height: 8),
            Text(s.contentEnglish, style: theme.textTheme.bodySmall),
          ],
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(summary),
          ],
          if (a.lookFor.isNotEmpty) ...[
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(s.lookForThree, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            for (final (i, item) in a.lookFor.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        romanNumeral(i + 1),
                        style: TypeRole.measurement.copyWith(
                          color: MeasureColors.of(context).accent,
                        ),
                      ),
                    ),
                    Expanded(child: Text(item.inLanguage(lang))),
                  ],
                ),
              ),
          ] else if (a.cues.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(s.lookFor, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(a.cues.map((c) => c.inLanguage(lang)).join(' · ')),
          ],
          if (a.story != null) ...[
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(s.artworkStory, style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Text(a.story!.inLanguage(lang)),
          ],
          if (a.inscriptions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                s.artworkInscriptions,
                style: theme.textTheme.titleMedium,
              ),
            ),
            for (final ins in a.inscriptions)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ins.greek,
                        locale: const Locale('el'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFamily: TypeRole.displayFamily,
                          fontFamilyFallback: TypeRole.displayFallback,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        ins.transliteration,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text('“${ins.translation.inLanguage(lang)}”'),
                      if (ins.basis == InscriptionBasis.photograph)
                        Text(
                          s.inscriptionFromPhoto,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
          ],
          if (a.condition != null) ...[
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                s.artworkCondition,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(a.condition!.inLanguage(lang)),
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
          if (widget.onScan != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('artwork-camera-eye'),
              onPressed: () {
                Navigator.pop(context);
                widget.onScan!();
              },
              icon: const PlanIcon(PlanSymbol.cameraEye),
              label: Text(s.recognise),
            ),
          ],
          if (a.position.inLanguage(lang).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(s.where, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(a.position.inLanguage(lang)),
          ],
          if (widget.sources.isNotEmpty) ...[
            const SizedBox(height: 16),
            SourceList(sources: widget.sources, title: s.sourcesTitle),
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
