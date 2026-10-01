import 'package:flutter/material.dart';

import '../content/bundled_content.dart';
import '../design/components.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../milestones/milestone_row.dart';
import '../services/notes_service.dart';
import '../services/progress_service.dart';
import '../shell/app_scope.dart';
import '../shell/navigation.dart';
import '../widgets/scene_detail_sheet.dart';

/// Placeholder until P19 builds the seasonal mosaics: the register as
/// tesserae, and the notes saved on Chora artworks.
class MosaicTab extends StatefulWidget {
  const MosaicTab({super.key});
  @override
  State<MosaicTab> createState() => _MosaicTabState();
}

class _MosaicTabState extends State<MosaicTab> {
  final _notes = NotesService();
  Map<String, String>? _texts;

  @override
  void initState() {
    super.initState();
    NotesService.revision.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    NotesService.revision.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final ids = (await _notes.notedSceneIds()).toList()..sort();
    final texts = {for (final id in ids) id: await _notes.noteFor(id)};
    if (mounted) setState(() => _texts = texts);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    final app = AppScope.of(context), registry = app.registry;
    final opened = ProgressScope.of(context).opened;
    final texts = _texts;
    return Scaffold(
      appBar: AppBar(title: Text(s.navMosaic)),
      body: registry == null
          ? const SizedBox.shrink()
          : ListView(
              restorationId: 'mosaic-scroll',
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(s.mosaicIntro),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Semantics(
                    label: s.mosaicProgress(
                      '${registry.register.where((m) => opened.contains(m.id)).length}',
                      '${registry.register.length}',
                    ),
                    child: ExcludeSemantics(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final m in registry.register)
                            TesseraSlot(
                              state: slotFor(m, opened: opened.contains(m.id)),
                              label: m.numeral,
                              width: 36,
                              height: 36,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    s.notesTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (texts != null && texts.isEmpty)
                  ContentState(title: s.emptyTitle, message: s.emptyBody)
                else if (texts != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                    child: Text(
                      s.notesCount('${texts.length}'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  for (final MapEntry(key: id, value: text) in texts.entries)
                    InkWell(
                      onTap: () async {
                        final artwork = registry.artwork(id);
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => SceneDetailSheet(
                            scene: sceneForArtwork(artwork, language: lang),
                            onScan: app.artworkRecognised(id)
                                ? () => openScan(context)
                                : null,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: c.line)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 56,
                              child: Text(
                                id,
                                style: TypeRole.measurement.copyWith(
                                  color: c.accent,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    registry.artwork(id).title.inLanguage(lang),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    text,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
