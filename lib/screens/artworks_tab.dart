import 'package:flutter/material.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../services/notes_service.dart';
import '../widgets/artwork_sheet.dart';

/// The catalogue, rendered from typed registry records. The temporary
/// scene adapter is gone; the classifier maps predictions to artwork ids.
class ArtworksTab extends StatefulWidget {
  const ArtworksTab({
    super.key,
    required this.artworks,
    this.examinable = const {},
    this.onExamine,
    this.onScan,
  });
  final List<Artwork> artworks;

  /// Artwork ids with a playable plate; [onExamine] opens one by id.
  final Set<String> examinable;
  final ValueChanged<String>? onExamine;

  /// Camera-eye action for a catalogue the classifier covers.
  final VoidCallback? onScan;
  @override
  State<ArtworksTab> createState() => _ArtworksTabState();
}

class _ArtworksTabState extends State<ArtworksTab> {
  final _notes = NotesService(), _search = TextEditingController();
  Set<String> _notedIds = {};
  String _query = '';
  String? _room;
  bool _interactiveOnly = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final ids = await _notes.notedSceneIds();
    if (mounted) setState(() => _notedIds = ids);
  }

  bool _interactive(Artwork a) => widget.examinable.contains(a.id);
  void _clear() => setState(() {
    _query = '';
    _search.clear();
    _room = null;
    _interactiveOnly = false;
  });
  Future<void> _open(Artwork artwork) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ArtworkSheet(
        artwork: artwork,
        onExamine: _interactive(artwork) && widget.onExamine != null
            ? () => widget.onExamine!(artwork.id)
            : null,
        onScan: widget.onScan,
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language,
        q = _query.toLowerCase().trim();
    final artworks = widget.artworks
        .where(
          (a) =>
              (_room == null || _room == a.room.inLanguage(lang)) &&
              (!_interactiveOnly || _interactive(a)) &&
              (q.isEmpty ||
                  '${a.id} ${a.title.inLanguage(lang)} ${a.room.inLanguage(lang)} '
                          '${a.surface.inLanguage(lang)} '
                          '${a.cues.map((x) => x.inLanguage(lang)).join(' ')}'
                      .toLowerCase()
                      .contains(q)),
        )
        .toList();
    final rooms =
        widget.artworks.map((a) => a.room.inLanguage(lang)).toSet().toList()
          ..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.collection),
        actions: [
          if (widget.onScan != null)
            IconButton(
              tooltip: s.recognise,
              onPressed: widget.onScan,
              icon: const PlanIcon(PlanSymbol.cameraEye),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              s.catalogueCount('${widget.artworks.length}'),
              style: TextStyle(color: c.secondary),
            ),
          ),
          if (lang == 'tr')
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                s.contentEnglish,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: s.searchScenes,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: s.clearSearch,
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DropdownButtonFormField<String>(
              key: ValueKey(_room),
              initialValue: _room ?? '',
              isExpanded: true,
              decoration: InputDecoration(labelText: s.room),
              items: [
                DropdownMenuItem(value: '', child: Text(s.allRooms)),
                for (final r in rooms)
                  DropdownMenuItem(
                    value: r,
                    child: Text(r, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _room = v == '' ? null : v),
            ),
          ),
          CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            title: Text(s.interactive),
            secondary: const PlanIcon(PlanSymbol.layers),
            value: _interactiveOnly,
            onChanged: (v) => setState(() => _interactiveOnly = v ?? false),
          ),
          const Divider(),
          Expanded(
            child: artworks.isEmpty
                ? SingleChildScrollView(
                    child: ContentState(
                      title: s.noScenes,
                      message: s.noScenesBody,
                      onAction: _clear,
                      actionLabel: s.clearFilters,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: artworks.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, i) {
                      final a = artworks[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        leading: SizedBox(
                          width: 48,
                          child: Text(
                            a.id,
                            style: TypeRole.measurement.copyWith(
                              color: c.accent,
                            ),
                          ),
                        ),
                        title: Text(a.title.inLanguage(lang)),
                        subtitle: Text(
                          '${a.room.inLanguage(lang)} · ${a.surface.inLanguage(lang)}',
                        ),
                        trailing: _notedIds.contains(a.id)
                            ? Tooltip(
                                message: s.hasNote,
                                child: const PlanIcon(
                                  PlanSymbol.story,
                                  size: 20,
                                ),
                              )
                            : null,
                        onTap: () => _open(a),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
