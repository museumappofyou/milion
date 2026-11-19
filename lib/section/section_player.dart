import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import '../design/components.dart';
import '../design/plan_icon.dart';
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                find.label.inLanguage(lang),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (find.photo case final photo?)
                TextButton.icon(
                  key: ValueKey('section-photo-${find.id}'),
                  onPressed: () =>
                      openOriginalPhoto(context, photo, title: find.label),
                  icon: const Icon(Icons.photo_outlined, size: 18),
                  label: Text(context.l10n.seePhotograph),
                ),
              for (final id in find.sourceIds)
                if (registry?.source(id) case final s?)
                  Text(
                    s.title.inLanguage(lang),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
            ],
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
            appBar: AppBar(title: Text(widget.section.title.inLanguage(lang))),
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
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: [
                        for (final item in [
                          (SectionPanel.story, PlanSymbol.story, s.plateStory),
                          (
                            SectionPanel.ships,
                            PlanSymbol.popup,
                            s.sectionShips,
                          ),
                        ])
                          TextButton.icon(
                            key: ValueKey('section-${item.$1.name}'),
                            style: _open == item.$1
                                ? TextButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: .12),
                                  )
                                : null,
                            onPressed: () => controls(item.$1),
                            icon: PlanIcon(item.$2),
                            label: Text(item.$3),
                          ),
                      ],
                    ),
                  ),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          key: ValueKey('ship-sheet-${ship.yk}'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

/// The docks: Story (reveal, story, beats) and Ships (all 37, by number).
class SectionSheet extends StatelessWidget {
  const SectionSheet({super.key, required this.player, required this.panel});
  final SectionPlayerState player;
  final SectionPanel panel;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final c = player.controller, m = c.manifest;
    final theme = Theme.of(context);
    final rows = switch (panel) {
      SectionPanel.story => <Widget>[
        if (c.reduced) Text(s.plateStillHint, style: theme.textTheme.bodySmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('section-play-reveal'),
              onPressed: () {
                player.closeControls();
                c.play();
              },
              icon: const PlanIcon(PlanSymbol.popup, size: 18),
              label: Text(s.plateStartReveal),
            ),
            OutlinedButton.icon(
              key: const ValueKey('section-play-story'),
              onPressed: () {
                player.closeControls();
                c.playStory();
              },
              icon: const PlanIcon(PlanSymbol.story, size: 18),
              label: Text(s.platePlay),
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
        for (final ship in m.ships)
          InkWell(
            key: ValueKey('section-ship-${ship.yk}'),
            onTap: () => player.showShip(ship),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text('YK ${ship.yk}', style: TypeRole.measurement),
                  ),
                  Expanded(
                    child: Text(switch (ship.type) {
                      ShipType.galley => s.shipGalley,
                      ShipType.round => s.shipRound,
                      null => s.shipTypeUnknown,
                    }),
                  ),
                ],
              ),
            ),
          ),
      ],
    };
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .42,
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
                    panel == SectionPanel.story ? s.plateStory : s.sectionShips,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const ValueKey('section-close-controls'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: player.closeControls,
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
