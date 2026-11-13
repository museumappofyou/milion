import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../content/geography.dart' show romanNumeral;
import '../content/guide.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../widgets/artwork_sheet.dart';
import 'plan_view.dart';

/// A place's guide (P11): its plan with every artwork on it, the artworks
/// of the chosen room, the guided cycles and the hunt.
class GuideScreen extends StatefulWidget {
  const GuideScreen({
    super.key,
    required this.place,
    required this.guide,
    required this.registry,
    this.focus,
    this.flyFrom,
    this.onCatalogue,
    this.onScan,
    this.onExamine,
    this.examinable = const {},
  });
  final Place place;
  final PlaceGuide guide;
  final ContentRegistry registry;

  /// An artwork to point at on arrival (the camera found it).
  final String? focus;

  /// Where the camera frame was on screen, for the flight to [focus].
  final Rect? flyFrom;
  final VoidCallback? onCatalogue, onScan;
  final ValueChanged<String>? onExamine;
  final Set<String> examinable;

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen>
    with TickerProviderStateMixin {
  late final Map<String, Artwork> _artworks = {
    for (final a in widget.registry.artworks)
      if (a.placeId == widget.place.id) a.id: a,
  };
  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  final _planKey = GlobalKey();
  String? _room;
  String? _focus;
  GuideCycle? _cycle;
  int _stop = 0;
  PlanPoint? _from;
  OverlayEntry? _flight;

  @override
  void initState() {
    super.initState();
    _focus = widget.focus;
    final focus = widget.focus;
    if (focus != null) {
      _room = widget.guide.anchors[focus]?.room;
      if (widget.flyFrom != null) {
        // Fly once the page has arrived, so the plan is where it will stay.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final arriving = ModalRoute.of(context)?.animation;
          if (arriving == null || arriving.isCompleted) {
            _fly(focus);
            return;
          }
          void landed(AnimationStatus s) {
            if (s != AnimationStatus.completed) return;
            arriving.removeStatusListener(landed);
            _fly(focus);
          }

          arriving.addStatusListener(landed);
        });
      }
    }
  }

  @override
  void dispose() {
    _flight?.remove();
    _walk.dispose();
    super.dispose();
  }

  PlanPoint _at(String id) => widget.guide.anchors[id]!.at;

  /// The camera's find flies as a tessera from the camera frame to its
  /// place on the plan, then opens.
  void _fly(String id) {
    final box = _planKey.currentContext?.findRenderObject() as RenderBox?;
    final from = widget.flyFrom;
    if (box == null || from == null || !mounted) return;
    final frame = PlanFrame(widget.guide, box.size);
    final to = box.localToGlobal(frame.toScreen(_at(id)));
    final reduce = MediaQuery.disableAnimationsOf(context);
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reduce ? 1 : 750),
    );
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );
    final art = _artworks[id]!;
    _flight = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: curve,
        builder: (context, _) {
          final t = curve.value;
          final rect = Rect.lerp(
            from,
            Rect.fromCenter(center: to, width: 14, height: 14),
            t,
          )!;
          return Positioned.fromRect(
            rect: rect,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      (art.kind == ArtworkKind.fresco
                              ? Pigment.bole
                              : Pigment.gold)
                          .withValues(alpha: lerpDouble(.35, 1, t)!),
                  border: Border.all(color: Pigment.lamp, width: 2),
                ),
              ),
            ),
          );
        },
      ),
    );
    Overlay.of(context).insert(_flight!);
    controller.forward().whenComplete(() {
      _flight?.remove();
      _flight = null;
      controller.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.guideFoundByCamera(
              art.title.inLanguage(context.language),
            ),
          ),
        ),
      );
      _open(art);
    });
  }

  Future<void> _open(Artwork a) async {
    setState(() => _focus = a.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ArtworkSheet(
        artwork: a,
        sources: widget.registry.sourcesOf(a),
        onExamine: widget.examinable.contains(a.id) && widget.onExamine != null
            ? () => widget.onExamine!(a.id)
            : null,
        onScan: widget.onScan,
      ),
    );
  }

  void _startCycle(GuideCycle c) {
    setState(() {
      _cycle = c;
      _stop = 0;
      _from = null;
      _room = null;
      _focus = c.artworkIds.first;
    });
    _walk.value = 1;
  }

  void _goTo(int stop) {
    final c = _cycle!;
    if (stop < 0 || stop >= c.artworkIds.length) return;
    setState(() {
      _from = _at(c.artworkIds[_stop]);
      _stop = stop;
      _focus = c.artworkIds[stop];
    });
    _walk
      ..value = 0
      ..forward();
  }

  void _endCycle() => setState(() {
    _cycle = null;
    _from = null;
  });

  void _tapPlan(Size size, Offset p) {
    final id = artworkAt(widget.guide, size, p);
    if (id != null) {
      _open(_artworks[id]!);
      return;
    }
    final room = roomAt(widget.guide, size, p);
    setState(() => _room = room == _room ? null : room);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final colors = MeasureColors.of(context);
    final guide = widget.guide;
    final hunt = [
      for (final h in widget.registry.hunts)
        if (h.artworkIds.any(_artworks.containsKey)) h,
    ].firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.place.names.inLanguage(lang),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.onScan != null)
            IconButton(
              key: const ValueKey('guide-camera-eye'),
              tooltip: s.recognise,
              onPressed: widget.onScan,
              icon: const PlanIcon(PlanSymbol.cameraEye),
            ),
          if (widget.onCatalogue != null)
            IconButton(
              key: const ValueKey('guide-catalogue'),
              tooltip: s.guideCatalogue,
              onPressed: widget.onCatalogue,
              icon: const Icon(Icons.view_list_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 11,
            child: Semantics(
              label: s.guidePlanLabel(
                widget.place.names.inLanguage(lang),
                guide.rooms.map((r) => r.name.inLanguage(lang)).join(', '),
              ),
              child: ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final size = box.biggest;
                    return InteractiveViewer(
                      maxScale: 5,
                      child: GestureDetector(
                        key: _planKey,
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (d) => _tapPlan(size, d.localPosition),
                        child: AnimatedBuilder(
                          animation: _walk,
                          builder: (context, _) => CustomPaint(
                            key: const ValueKey('guide-plan'),
                            size: size,
                            painter: PlanPainter(
                              guide: guide,
                              artworks: _artworks,
                              colors: colors,
                              language: lang,
                              state: _planState(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Container(height: 1, color: colors.line),
          Expanded(
            flex: 9,
            child: _cycle == null
                ? _RoomPanel(
                    guide: guide,
                    artworks: _artworks,
                    room: _room,
                    focus: _focus,
                    onRoom: (r) => setState(() => _room = r),
                    onOpen: _open,
                    onCycle: _startCycle,
                    hunt: hunt,
                  )
                : _CyclePanel(
                    cycle: _cycle!,
                    stop: _stop,
                    artwork: _artworks[_cycle!.artworkIds[_stop]]!,
                    onPrevious: () => _goTo(_stop - 1),
                    onNext: () => _goTo(_stop + 1),
                    onOpen: () => _open(_artworks[_cycle!.artworkIds[_stop]]!),
                    onEnd: _endCycle,
                  ),
          ),
        ],
      ),
    );
  }

  PlanState _planState() {
    final c = _cycle;
    if (c != null) {
      final here = _at(c.artworkIds[_stop]);
      final from = _from ?? here;
      final t = Curves.easeInOut.transform(_walk.value);
      return PlanState(
        focus: _focus,
        path: [for (final id in c.artworkIds) _at(id)],
        you: PlanPoint(
          from.x + (here.x - from.x) * t,
          from.y + (here.y - from.y) * t,
        ),
        dimmed: {
          for (final id in _artworks.keys)
            if (!c.artworkIds.contains(id)) id,
        },
      );
    }
    return PlanState(
      room: _room,
      focus: _focus,
      dimmed: _room == null
          ? const {}
          : {
              for (final a in widget.guide.anchors.values)
                if (a.room != _room) a.artworkId,
            },
    );
  }
}

String _surfaceGroup(BuildContext context, Artwork a) {
  final s = context.l10n;
  return switch (a.surface.en) {
    'dome' || 'pendentive' => s.guideSurfaceDome,
    'vault' => s.guideSurfaceVault,
    _ => s.guideSurfaceWall,
  };
}

class _RoomPanel extends StatelessWidget {
  const _RoomPanel({
    required this.guide,
    required this.artworks,
    required this.room,
    required this.focus,
    required this.onRoom,
    required this.onOpen,
    required this.onCycle,
    required this.hunt,
  });
  final PlaceGuide guide;
  final Map<String, Artwork> artworks;
  final String? room;
  final String? focus;
  final ValueChanged<String?> onRoom;
  final ValueChanged<Artwork> onOpen;
  final ValueChanged<GuideCycle> onCycle;
  final Hunt? hunt;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final colors = MeasureColors.of(context);
    final theme = Theme.of(context);
    final shown = [
      for (final a in guide.anchors.values)
        if (room == null || a.room == room) artworks[a.artworkId]!,
    ]..sort((a, b) => _order(a.id).compareTo(_order(b.id)));
    final groups = <String, List<Artwork>>{};
    for (final a in shown) {
      (groups[_surfaceGroup(context, a)] ??= []).add(a);
    }
    Widget roomButton(String? id, String label) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        key: ValueKey('guide-room-${id ?? 'all'}'),
        style: OutlinedButton.styleFrom(
          backgroundColor: room == id ? colors.ink : null,
          foregroundColor: room == id ? colors.ground : colors.ink,
          shape: const RoundedRectangleBorder(borderRadius: Space.radius),
        ),
        onPressed: () => onRoom(id),
        child: Text(label),
      ),
    );
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                roomButton(null, s.guideAllRooms),
                for (final r in guide.rooms)
                  roomButton(r.id, r.name.inLanguage(lang)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(s.guideCycles, style: theme.textTheme.titleSmall),
                for (final c in guide.cycles)
                  TextButton(
                    key: ValueKey('guide-cycle-${c.id}'),
                    onPressed: () => onCycle(c),
                    child: Text(
                      '${c.title.inLanguage(lang)} · ${c.artworkIds.length}',
                    ),
                  ),
                if (hunt != null)
                  TextButton.icon(
                    key: const ValueKey('guide-hunt'),
                    onPressed: () => _showHunt(context, hunt!),
                    icon: const PlanIcon(PlanSymbol.tessera, size: 16),
                    label: Text(s.guideHunt),
                  ),
              ],
            ),
          ),
        ),
        for (final e in groups.entries) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Semantics(
                header: true,
                child: Text(
                  '${e.key} · ${e.value.length}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
          ),
          SliverList.builder(
            itemCount: e.value.length,
            itemBuilder: (context, i) {
              final a = e.value[i];
              return MergeSemantics(
                child: InkWell(
                  key: ValueKey('guide-artwork-${a.id}'),
                  onTap: () => onOpen(a),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    color: a.id == focus
                        ? Pigment.gold.withValues(alpha: .15)
                        : null,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          color: a.kind == ArtworkKind.fresco
                              ? Pigment.bole
                              : Pigment.gold,
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 52,
                          child: Text(a.id, style: TypeRole.measurement),
                        ),
                        Expanded(child: Text(a.title.inLanguage(lang))),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  static String _order(String id) {
    final m = RegExp(r'^([A-Z])(\d+)(?:_(\d+))?$').firstMatch(id);
    if (m == null) return id;
    return '${m[1]}${m[2]!.padLeft(3, '0')}${(m[3] ?? '0').padLeft(2, '0')}';
  }
}

void _showHunt(BuildContext context, Hunt hunt) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _HuntSheet(hunt: hunt),
  );
}

class _HuntSheet extends StatefulWidget {
  const _HuntSheet({required this.hunt});
  final Hunt hunt;
  @override
  State<_HuntSheet> createState() => _HuntSheetState();
}

class _HuntSheetState extends State<_HuntSheet> {
  final _shown = <int>{};
  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final theme = Theme.of(context);
    final items = widget.hunt.items;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      maxChildSize: .95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Text(
            widget.hunt.title.inLanguage(lang),
            style: theme.textTheme.titleLarge,
          ),
          Text(s.guideHuntIntro('${items.length}')),
          for (final (i, item) in items.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${romanNumeral(i + 1)} · ${item.title.inLanguage(lang)}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(item.clue.inLanguage(lang)),
                  if (_shown.contains(i))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        item.answer.inLanguage(lang),
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  else
                    TextButton(
                      key: ValueKey('hunt-answer-$i'),
                      onPressed: () => setState(() => _shown.add(i)),
                      child: Text(s.guideHuntAnswer),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CyclePanel extends StatelessWidget {
  const _CyclePanel({
    required this.cycle,
    required this.stop,
    required this.artwork,
    required this.onPrevious,
    required this.onNext,
    required this.onOpen,
    required this.onEnd,
  });
  final GuideCycle cycle;
  final int stop;
  final Artwork artwork;
  final VoidCallback onPrevious, onNext, onOpen, onEnd;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final theme = Theme.of(context);
    final last = cycle.artworkIds.length - 1;
    final first = artwork.lookFor.firstOrNull ?? artwork.summary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      children: [
        Text(cycle.title.inLanguage(lang), style: theme.textTheme.titleMedium),
        if (stop == 0) ...[
          const SizedBox(height: 4),
          Text(cycle.intro.inLanguage(lang), style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(
            '${s.guideCycleStop('${stop + 1}', '${last + 1}')} · '
            '${s.guideYouAreHere(artwork.title.inLanguage(lang))}',
            style: TypeRole.measurement,
          ),
        ),
        const SizedBox(height: 8),
        Text(artwork.title.inLanguage(lang), style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${artwork.room.inLanguage(lang)} · ${artwork.surface.inLanguage(lang)}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(first.inLanguage(lang)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const ValueKey('cycle-previous'),
              onPressed: stop > 0 ? onPrevious : null,
              child: Text(s.guidePrevious),
            ),
            FilledButton(
              key: const ValueKey('cycle-next'),
              onPressed: stop < last ? onNext : null,
              child: Text(s.guideNext),
            ),
            TextButton(
              key: const ValueKey('cycle-open'),
              onPressed: onOpen,
              child: Text(s.guideOpenArtwork),
            ),
            TextButton(
              key: const ValueKey('cycle-end'),
              onPressed: onEnd,
              child: Text(s.guideEndCycle),
            ),
          ],
        ),
      ],
    );
  }
}
