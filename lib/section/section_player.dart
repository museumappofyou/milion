import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/player_bar.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import '../shell/original_photo.dart';
import '../space/snapshot_builder.dart';
import 'section.dart';
import 'section_controller.dart';
import 'section_painter.dart';

enum SectionPanel { story, ships }

/// A drawn excavation section (PU and SB, P14: XVII, the harbour under the
/// metro). Drag up or down to dig; the finds near the reading line, or the
/// ones the story names, pop up out of the drawing; tap a ship for its type.
class SectionPlayer extends StatefulWidget {
  const SectionPlayer({super.key, required this.section});
  final SectionManifest section;
  @override
  SectionPlayerState createState() => SectionPlayerState();
}

class SectionPlayerState extends State<SectionPlayer>
    with SingleTickerProviderStateMixin {
  late final SectionController controller = SectionController(widget.section);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  SectionPanel? _open;
  SectionPanel? get openPanel => _open;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      controller.advance(dt);
    });
    controller.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (controller.reduced != reduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.setReduced(reduced);
      });
    }
  }

  void _changed() {
    if (controller.needsTicker && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!controller.needsTicker && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void controls(SectionPanel panel) =>
      setState(() => _open = _open == panel ? null : panel);
  void closeControls() => setState(() => _open = null);

  @override
  void dispose() {
    _ticker.dispose();
    controller.removeListener(_changed);
    controller.dispose();
    super.dispose();
  }

  Future<void> showShip(SectionShip ship) => showModalBottomSheet<void>(
    context: context,
    builder: (context) => Theme(
      data: DesignTheme.marble,
      child: ShipSheet(ship: ship, section: widget.section),
    ),
  );

  Future<void> showFind(SectionFind find) => showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      final lang = context.language;
      final registry = AppScope.maybeOf(context)?.registry;
      return Theme(
        data: DesignTheme.marble,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DimensionHandle(),
                Text(
                  find.label.inLanguage(lang),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (find.photo case final photo?)
                  OutlinedButton.icon(
                    key: ValueKey('section-photo-${find.id}'),
                    onPressed: () =>
                        openOriginalPhoto(context, photo, title: find.label),
                    icon: const Icon(Icons.photo_outlined, size: 18),
                    label: Text(context.l10n.seePhotograph),
                  ),
                const SizedBox(height: 8),
                for (final id in find.sourceIds)
                  if (registry?.source(id) case final s?)
                    Text(
                      s.title.inLanguage(lang),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Future<void> showSources() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTheme.marble.colorScheme.surface,
    builder: (context) {
      final s = context.l10n, lang = context.language;
      final registry = AppScope.maybeOf(context)?.registry;
      final ids = <String>{
        ...widget.section.sourceIds,
        ...widget.section.shipSourceIds,
        for (final f in widget.section.finds) ...f.sourceIds,
        for (final st in widget.section.strata) ...st.sourceIds,
      };
      return Theme(
        data: DesignTheme.marble,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DimensionHandle(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.sourcesTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: s.plateClose,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.section.talkback.inLanguage(lang)),
                  const SizedBox(height: 16),
                  for (final id in ids)
                    if (registry?.source(id) case final src?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              src.title.inLanguage(lang),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            SelectableText(
                              src.url,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DesignTheme.marble,
      child: Builder(
        builder: (context) {
          final s = context.l10n, lang = context.language;
          final c = controller, colours = MeasureColors.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.section.title.inLanguage(lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                PlayerSourcesButton(
                  key: const ValueKey('section-appbar-sources'),
                  tooltip: s.sourcesTitle,
                  onPressed: showSources,
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: Semantics(
                              label:
                                  '${widget.section.title.inLanguage(lang)}. '
                                  '${widget.section.talkback.inLanguage(lang)}',
                              hint: s.sectionHint,
                              customSemanticsActions: {
                                CustomSemanticsAction(label: s.plateNext): () =>
                                    c.step(1),
                                CustomSemanticsAction(
                                  label: s.platePrevious,
                                ): () =>
                                    c.step(-1),
                                CustomSemanticsAction(label: s.platePlay):
                                    c.playStory,
                              },
                              child: GestureDetector(
                                key: const ValueKey('section-viewport'),
                                behavior: HitTestBehavior.opaque,
                                onVerticalDragStart: (_) => c.explore(),
                                onVerticalDragUpdate: (d) => c.scroll(
                                  -d.delta.dy /
                                      SectionLayout(size, 0).pxPerMetre,
                                ),
                                onTapUp: (d) {
                                  if (c.mode == SectionMode.stills) {
                                    return c.step(1);
                                  }
                                  final ship = shipAt(c, size, d.localPosition);
                                  if (ship != null) {
                                    showShip(ship);
                                    return;
                                  }
                                  final find = findAt(c, size, d.localPosition);
                                  if (find != null) showFind(find);
                                },
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    key: const ValueKey('section-paint'),
                                    size: Size.infinite,
                                    painter: SectionPainter(
                                      controller: c,
                                      ink: colours.ink,
                                      secondary: colours.secondary,
                                      accent: colours.accent,
                                      paper: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      text: TypeRole.measurement,
                                      language: lang,
                                      devicePixelRatio:
                                          MediaQuery.devicePixelRatioOf(
                                            context,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _SectionLabels(
                            controller: c,
                            captionHeight: size.height * .3,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (_open case final panel?)
                  Material(
                    color: Theme.of(context).colorScheme.surface,
                    shape: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: .5,
                      ),
                    ),
                    child: SectionSheet(player: this, panel: panel),
                  ),
                PlayerDockBar(
                  items: [
                    PlayerDockItem(
                      key: const ValueKey('section-story'),
                      symbol: PlanSymbol.story,
                      label: s.plateStory,
                      selected: _open == SectionPanel.story,
                      onTap: () => controls(SectionPanel.story),
                    ),
                    PlayerDockItem(
                      key: const ValueKey('section-ships'),
                      symbol: PlanSymbol.popup,
                      label: s.sectionShips,
                      selected: _open == SectionPanel.ships,
                      onTap: () => controls(SectionPanel.ships),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabels extends StatelessWidget {
  const _SectionLabels({required this.controller, required this.captionHeight});
  final SectionController controller;
  final double captionHeight;

  @override
  Widget build(BuildContext context) => SnapshotBuilder(
    listenable: controller,
    snapshot: () => (
      controller.honesty,
      controller.caption,
      controller.currentBeat?.id,
      controller.mode,
    ),
    builder: (context) {
      final c = controller, lang = context.language, s = context.l10n;
      final ground = Theme.of(context).scaffoldBackgroundColor
          .withValues(alpha: .94);
      final caption = c.caption?.inLanguage(lang);
      final beat = c.currentBeat;
      return Stack(
        children: [
          Positioned(
            top: 8,
            left: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(color: ground),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: HonestyLabel(
                  c.honesty,
                  key: const ValueKey('section-honesty'),
                ),
              ),
            ),
          ),
          if (caption != null)
            Positioned(
              bottom: 8,
              left: 12,
              right: 80,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: captionHeight),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ground,
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: .5,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.mode == SectionMode.stills)
                            Text(
                              s.walkStill(
                                '${c.stillIndex + 1}',
                                '${c.manifest.stills.length}',
                              ),
                              style: TypeRole.measurement,
                            ),
                          if (beat != null)
                            Text(
                              beat.label.inLanguage(lang),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          Text(
                            caption,
                            key: const ValueKey('section-caption'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// What the sources read here say about one wreck.
class ShipSheet extends StatelessWidget {
  const ShipSheet({super.key, required this.ship, required this.section});
  final SectionShip ship;
  final SectionManifest section;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final theme = Theme.of(context);
    final registry = AppScope.maybeOf(context)?.registry;
    final rows = <String>[
      switch (ship.type) {
        ShipType.galley => s.shipGalley,
        ShipType.round => s.shipRound,
        null => s.shipTypeUnknown,
      },
      if (ship.date case final d?) d.inLanguage(lang),
      if (ship.length != null && ship.breadth != null)
        s.shipSize(_number(ship.length!, lang), _number(ship.breadth!, lang)),
      ship.team == 'ina' ? s.shipTeamIna : s.shipTeamIu,
      if (ship.cargo) s.shipCargo,
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          key: ValueKey('ship-sheet-${ship.yk}'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DimensionHandle(),
            Text('YK ${ship.yk}', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(r, style: theme.textTheme.bodyMedium),
              ),
            const SizedBox(height: 8),
            Text(s.shipPlaced, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            for (final id in section.shipSourceIds)
              if (registry?.source(id) case final src?)
                Text(
                  src.title.inLanguage(lang),
                  style: theme.textTheme.bodySmall,
                ),
          ],
        ),
      ),
    );
  }

  static String _number(double v, String lang) {
    final t = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    return lang == 'tr' ? t.replaceAll('.', ',') : t;
  }
}

enum _ShipFilter { all, galley, round, cargo }

/// The docks: Story (reveal, story, beats) and Ships (37 wrecks with type
/// and cargo filters).
class SectionSheet extends StatefulWidget {
  const SectionSheet({super.key, required this.player, required this.panel});
  final SectionPlayerState player;
  final SectionPanel panel;

  @override
  State<SectionSheet> createState() => _SectionSheetState();
}

class _SectionSheetState extends State<SectionSheet> {
  _ShipFilter _shipFilter = _ShipFilter.all;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final colors = MeasureColors.of(context);
    final c = widget.player.controller, m = c.manifest;
    final theme = Theme.of(context);

    final galleyCount = m.ships.where((x) => x.type == ShipType.galley).length;
    final roundCount = m.ships.where((x) => x.type == ShipType.round).length;
    final cargoCount = m.ships.where((x) => x.cargo).length;
    final visibleShips = [
      for (final ship in m.ships)
        if (switch (_shipFilter) {
          _ShipFilter.all => true,
          _ShipFilter.galley => ship.type == ShipType.galley,
          _ShipFilter.round => ship.type == ShipType.round,
          _ShipFilter.cargo => ship.cargo,
        })
          ship,
    ];

    final rows = switch (widget.panel) {
      SectionPanel.story => <Widget>[
        if (c.reduced) Text(s.plateStillHint, style: theme.textTheme.bodySmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const ValueKey('section-play-story'),
              onPressed: () {
                widget.player.closeControls();
                c.playStory();
              },
              icon: const PlanIcon(PlanSymbol.story, size: 18),
              label: Text(s.platePlay),
            ),
            OutlinedButton.icon(
              key: const ValueKey('section-play-reveal'),
              onPressed: () {
                widget.player.closeControls();
                c.play();
              },
              icon: const PlanIcon(PlanSymbol.popup, size: 18),
              label: Text(s.plateStartReveal),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final b in m.beats)
          InkWell(
            key: ValueKey('section-beat-${b.id}'),
            onTap: () {
              if (c.reduced) {
                final i = m.stills.indexOf(b.id);
                c.stills(i < 0 ? 0 : i);
              } else {
                c.goTo(b);
              }
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  const PlanIcon(PlanSymbol.route, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(b.label.inLanguage(lang))),
                ],
              ),
            ),
          ),
      ],
      SectionPanel.ships => <Widget>[
        Text(s.shipPlaced, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final item in [
              (_ShipFilter.all, '${s.shipFilterAll} · ${m.ships.length}'),
              (_ShipFilter.galley, '${s.shipFilterGalleys} · $galleyCount'),
              (_ShipFilter.round, '${s.shipFilterRound} · $roundCount'),
              (_ShipFilter.cargo, '${s.shipFilterCargo} · $cargoCount'),
            ])
              ChoiceChip(
                key: ValueKey('ship-filter-${item.$1.name}'),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selected: _shipFilter == item.$1,
                label: Text(item.$2),
                onSelected: (_) => setState(() => _shipFilter = item.$1),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final ship in visibleShips)
          InkWell(
            key: ValueKey('section-ship-${ship.yk}'),
            onTap: () => widget.player.showShip(ship),
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.line.withValues(alpha: .45)),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 54,
                    child: Text(
                      'YK ${ship.yk}',
                      style: TypeRole.measurement.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(switch (ship.type) {
                          ShipType.galley => s.shipGalley,
                          ShipType.round => s.shipRound,
                          null => s.shipTypeUnknown,
                        }),
                        if (ship.date != null || ship.cargo)
                          Text(
                            [
                              if (ship.date != null)
                                ship.date!.inLanguage(lang),
                              if (ship.cargo) s.shipCargo,
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: colors.secondary),
                ],
              ),
            ),
          ),
      ],
    };
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .44,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.panel == SectionPanel.story
                        ? s.plateStory
                        : s.sectionShips,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const ValueKey('section-close-controls'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: widget.player.closeControls,
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            ...rows,
          ],
        ),
      ),
    );
  }
}
