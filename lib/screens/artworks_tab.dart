import 'package:flutter/material.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../services/notes_service.dart';
import '../shell/app_scope.dart';
import '../widgets/artwork_sheet.dart';

/// The catalogue, rendered from typed registry records: compact search + chip
/// strip (reclaiming viewport height), room headers, medium swatches, and an
/// unmistakable Relief Plate badge on interactive artworks.
class ArtworksTab extends StatefulWidget {
  const ArtworksTab({
    super.key,
    required this.artworks,
    required this.place,
    this.examinable = const {},
    this.onExamine,
    this.onScan,
  });
  final List<Artwork> artworks;

  /// The place's name for the header (P12: the list was always "Chora").
  final Localized place;

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
        sources:
            AppScope.maybeOf(context)?.registry?.sourcesOf(artwork) ?? const [],
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
    final interactiveCount = widget.artworks.where(_interactive).length;
    final groupByRoom = _room == null && rooms.length > 1;

    final grouped = <String, List<Artwork>>{};
    if (groupByRoom) {
      for (final a in artworks) {
        (grouped[a.room.inLanguage(lang)] ??= []).add(a);
      }
    }

    Widget artworkRow(Artwork a) {
      final isInteractive = _interactive(a);
      final plateColor = c.accent;
      return InkWell(
        key: ValueKey('artwork-row-${a.id}'),
        onTap: () => _open(a),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.line.withValues(alpha: .55)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Medium swatch: gold for mosaic, bole for fresco, a hairline
              // square for anything else (inscriptions, reliefs, objects).
              Container(
                width: 8,
                height: 8,
                color: switch (a.kind) {
                  ArtworkKind.mosaic => Pigment.gold,
                  ArtworkKind.fresco => Pigment.bole,
                  _ => c.line,
                },
              ),
              const SizedBox(width: 12),
              // Chora's ids are its catalogue codes (F02, M49_1);
              // a place without codes shows none, not its slugs.
              if (a.code != null) ...[
                SizedBox(
                  width: 48,
                  child: Text(
                    a.code!,
                    style: TypeRole.measurement.copyWith(
                      color: c.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title.inLanguage(lang),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: isInteractive
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      groupByRoom
                          ? a.surface.inLanguage(lang)
                          : '${a.room.inLanguage(lang)} · ${a.surface.inLanguage(lang)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (isInteractive) ...[
                      const SizedBox(height: 5),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.poche,
                          borderRadius: Space.radius,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PlanIcon(
                                PlanSymbol.layers,
                                size: 12,
                                color: plateColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                TypeRole.capitals(s.kindReliefPlate, lang),
                                style: TypeRole.measurement.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: .45,
                                  color: plateColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_notedIds.contains(a.id)) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: s.hasNote,
                  child: PlanIcon(PlanSymbol.story, size: 18, color: c.accent),
                ),
              ],
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: c.secondary),
            ],
          ),
        ),
      );
    }

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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              s.catalogueCount(
                '${widget.artworks.length}',
                widget.place.inLanguage(lang),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              key: const ValueKey('artworks-search'),
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                hintText: s.searchScenes,
                prefixIcon: const Icon(Icons.search, size: 20),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: s.clearSearch,
                        onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }),
                        icon: const Icon(Icons.close, size: 18),
                      ),
              ),
            ),
          ),
          if (interactiveCount > 0 || rooms.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  if (interactiveCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        key: const ValueKey('artworks-filter-interactive'),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        avatar: PlanIcon(
                          PlanSymbol.layers,
                          size: 14,
                          color: _interactiveOnly ? c.accent : c.secondary,
                        ),
                        label: Text('${s.interactive} · $interactiveCount'),
                        selected: _interactiveOnly,
                        onSelected: (v) => setState(() => _interactiveOnly = v),
                      ),
                    ),
                  if (rooms.length > 1) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        key: const ValueKey('artworks-room-all'),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        label: Text(s.allRooms),
                        selected: _room == null,
                        onSelected: (_) => setState(() => _room = null),
                      ),
                    ),
                    for (final r in rooms)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          label: Text(r),
                          selected: _room == r,
                          onSelected: (_) =>
                              setState(() => _room = _room == r ? null : r),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          const Divider(height: 1),
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
                : groupByRoom
                ? CustomScrollView(
                    slivers: [
                      for (final entry in grouped.entries) ...[
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                            decoration: BoxDecoration(
                              color: c.poche.withValues(alpha: .45),
                              border: Border(
                                top: BorderSide(
                                  color: c.line.withValues(alpha: .6),
                                ),
                              ),
                            ),
                            child: Semantics(
                              header: true,
                              child: Text(
                                '${TypeRole.capitals(entry.key, lang)} · ${entry.value.length}',
                                style: TypeRole.measurement.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: .6,
                                  color: c.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SliverList.builder(
                          itemCount: entry.value.length,
                          itemBuilder: (context, i) =>
                              artworkRow(entry.value[i]),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: artworks.length,
                    itemBuilder: (context, i) => artworkRow(artworks[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
