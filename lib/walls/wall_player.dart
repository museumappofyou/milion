import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:geolocator/geolocator.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/player_bar.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import '../shell/navigation.dart';
import '../shell/original_photo.dart';
import '../space/snapshot_builder.dart';
import 'wall_controller.dart';
import 'wall_painter.dart';
import 'wall_strip.dart';

enum WallPanel { story, gates, section }

/// Finds where the phone is; replaceable in tests.
typedef WallLocator = Future<Coordinates?> Function();

Future<Coordinates?> _deviceLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) return null;
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }
  final p = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ),
  );
  return Coordinates(p.latitude, p.longitude);
}

/// The land walls as one strip (PU and SB, P15: XVIII). Drag or fling
/// sideways along the 6.5 km from the Sea of Marmara to the Golden Horn;
/// the cross-section under it changes where the defences change; a gate
/// opens its story; on site, the strip scrolls to where you stand.
class WallPlayer extends StatefulWidget {
  const WallPlayer({super.key, required this.strip, this.locator});
  final WallStripManifest strip;
  final WallLocator? locator;
  @override
  WallPlayerState createState() => WallPlayerState();
}

class WallPlayerState extends State<WallPlayer>
    with SingleTickerProviderStateMixin {
  late final WallController controller = WallController(widget.strip);
  late final Ticker _ticker;
  final ScrollController scroll = ScrollController();
  Duration _last = Duration.zero;
  WallPanel? _open;
  WallPanel? get openPanel => _open;
  double _k = 1;
  bool _syncing = false;

  /// Metres across the screen.
  static const span = 320.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      controller.advance(dt);
    });
    controller.addListener(_changed);
    scroll.addListener(_scrolled);
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
    // Keep the scroll position with the controller when it moves itself.
    if (scroll.hasClients) {
      final target = controller.at * _k;
      if ((scroll.offset - target).abs() > .5) {
        _syncing = true;
        scroll.jumpTo(target.clamp(0.0, scroll.position.maxScrollExtent));
        _syncing = false;
      }
    }
  }

  void _scrolled() {
    if (_syncing || !scroll.hasClients) return;
    controller.scrollTo(scroll.offset / _k);
  }

  void controls(WallPanel panel) =>
      setState(() => _open = _open == panel ? null : panel);
  void closeControls() => setState(() => _open = null);

  @override
  void dispose() {
    _ticker.dispose();
    controller.removeListener(_changed);
    scroll.removeListener(_scrolled);
    scroll.dispose();
    controller.dispose();
    super.dispose();
  }

  /// On site, the strip scrolls to where you stand.
  Future<void> locate() async {
    final s = context.l10n, lang = context.language;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(s.atlasLocating)));
    Coordinates? where;
    try {
      where = await (widget.locator ?? _deviceLocation)();
    } on Object {
      where = null;
    }
    if (!mounted) return;
    messenger.hideCurrentSnackBar();
    if (where == null) {
      messenger.showSnackBar(SnackBar(content: Text(s.atlasLocationFailed)));
      return;
    }
    final hit = widget.strip.locate(where);
    String km(double m) {
      final t = (m / 1000).toStringAsFixed(1);
      return lang == 'tr' ? t.replaceAll('.', ',') : t;
    }

    if (hit.off <= onSiteMetres) {
      controller.goTo(hit.at);
      messenger.showSnackBar(SnackBar(content: Text(s.wallsHere(km(hit.at)))));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(s.wallsAway(km(hit.off)))));
    }
  }

  /// How near the line counts as standing at the wall.
  static const onSiteMetres = 400.0;

  Future<void> showGate(WallGate gate) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTheme.marble.colorScheme.surface,
    builder: (context) => Theme(
      data: DesignTheme.marble,
      child: GateSheet(gate: gate),
    ),
  );

  Future<void> showSources() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTheme.marble.colorScheme.surface,
    builder: (context) => Theme(
      data: DesignTheme.marble,
      child: SourcesSheet(
        ids: widget.strip.allSourceIds,
        intro: widget.strip.talkback,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DesignTheme.marble,
      child: Builder(
        builder: (context) {
          final s = context.l10n, lang = context.language;
          final c = controller, colours = MeasureColors.of(context);
          final m = widget.strip;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                m.title.inLanguage(lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                PlayerSourcesButton(
                  key: const ValueKey('walls-appbar-sources'),
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
                      _k = size.width / span;
                      final layout = WallLayout(size, c.at, m, span: span);
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                key: const ValueKey('walls-paint'),
                                painter: WallPainter(
                                  controller: c,
                                  ink: colours.ink,
                                  secondary: colours.secondary,
                                  accent: colours.accent,
                                  paper: Theme.of(context)
                                      .scaffoldBackgroundColor,
                                  poche: colours.poche,
                                  text: TypeRole.measurement,
                                  language: lang,
                                  span: span,
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Semantics(
                              label:
                                  '${m.title.inLanguage(lang)}. '
                                  '${m.talkback.inLanguage(lang)}',
                              hint: s.wallsHint,
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
                                behavior: HitTestBehavior.translucent,
                                onTapUp: (d) {
                                  final p = d.localPosition;
                                  if (c.mode == WallMode.stills) {
                                    return c.step(1);
                                  }
                                  if (p.dy > layout.overviewY - 14) {
                                    c.goTo(layout.overviewMetres(p.dx));
                                    return;
                                  }
                                  final g = gateAt(c, size, p, span: span);
                                  if (g != null) showGate(g);
                                },
                                child: SingleChildScrollView(
                                  key: const ValueKey('walls-viewport'),
                                  controller: scroll,
                                  scrollDirection: Axis.horizontal,
                                  physics: const ClampingScrollPhysics(),
                                  child: SizedBox(
                                    width: m.length * _k + size.width,
                                    height: size.height,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _WallLabels(
                            controller: c,
                            layout: layout,
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
                    child: WallSheet(player: this, panel: panel),
                  ),
                PlayerDockBar(
                  items: [
                    PlayerDockItem(
                      key: const ValueKey('walls-story'),
                      symbol: PlanSymbol.story,
                      label: s.plateStory,
                      selected: _open == WallPanel.story,
                      onTap: () => controls(WallPanel.story),
                    ),
                    PlayerDockItem(
                      key: const ValueKey('walls-gates'),
                      symbol: PlanSymbol.gate,
                      label: s.wallsGates,
                      selected: _open == WallPanel.gates,
                      onTap: () => controls(WallPanel.gates),
                    ),
                    PlayerDockItem(
                      key: const ValueKey('walls-section'),
                      symbol: PlanSymbol.section,
                      label: s.spaceSection,
                      selected: _open == WallPanel.section,
                      onTap: () => controls(WallPanel.section),
                    ),
                    PlayerDockItem(
                      key: const ValueKey('walls-locate'),
                      symbol: PlanSymbol.route,
                      label: s.wallsLocate,
                      selected: false,
                      onTap: locate,
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

class _WallLabels extends StatelessWidget {
  const _WallLabels({
    required this.controller,
    required this.layout,
    required this.captionHeight,
  });
  final WallController controller;
  final WallLayout layout;
  final double captionHeight;

  @override
  Widget build(BuildContext context) => SnapshotBuilder(
    listenable: controller,
    snapshot: () => (
      controller.caption,
      controller.currentBeat?.id,
      controller.mode,
      controller.stillIndex,
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
            top: layout.rulerY + 30,
            left: 12,
            child: HonestyLabel(
              c.honesty,
              key: const ValueKey('walls-honesty'),
            ),
          ),
          Positioned(
            top: layout.rulerY + 30,
            right: 12,
            child: Text(
              s.wallsHeightScale(c.manifest.heightScale.toStringAsFixed(0)),
              key: const ValueKey('walls-scale-note'),
              style: TypeRole.measurement.copyWith(
                fontSize: 10,
                color: MeasureColors.of(context).secondary,
              ),
            ),
          ),
          if (caption != null)
            Positioned(
              bottom: 40,
              left: 12,
              right: 12,
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
                          if (c.mode == WallMode.stills)
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
                            key: const ValueKey('walls-caption'),
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

/// A gate's story: its names, date, kind, what happened there, and the
/// legend's caveat where it is one.
class GateSheet extends StatelessWidget {
  const GateSheet({super.key, required this.gate});
  final WallGate gate;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final theme = Theme.of(context);
    final app = AppScope.maybeOf(context);
    final registry = app?.registry;
    final place = gate.placeId == null ? null : registry?.place(gate.placeId!);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .75,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            key: ValueKey('gate-sheet-${gate.id}'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DimensionHandle(),
              Text(
                gate.names.inLanguage(lang),
                style: theme.textTheme.headlineSmall,
              ),
              if (gate.greek case final g?)
                Text(g, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                [
                  ?gate.year,
                  switch (gate.kind) {
                    'public' => s.wallsGatePublic,
                    'military' => s.wallsGateMilitary,
                    'palace' => s.wallsGatePalace,
                    'site' => s.wallsSite,
                    _ => s.wallsGatePostern,
                  },
                ].join(' · '),
                style: TypeRole.measurement,
              ),
              if (gate.legend) ...[
                const SizedBox(height: 8),
                const HonestyLabel(Honesty.IMAGINED),
              ],
              const SizedBox(height: 10),
              Text(
                gate.caption.inLanguage(lang),
                style: theme.textTheme.bodyMedium,
              ),
              if (gate.positionNote case final n?) ...[
                const SizedBox(height: 8),
                Text(n.inLanguage(lang), style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (gate.photo case final photo?)
                    OutlinedButton.icon(
                      key: ValueKey('gate-photo-${gate.id}'),
                      onPressed: () =>
                          openOriginalPhoto(context, photo, title: gate.names),
                      icon: const Icon(Icons.photo_outlined, size: 18),
                      label: Text(s.seePhotograph),
                    ),
                  if (place != null)
                    OutlinedButton(
                      key: ValueKey('gate-place-${gate.id}'),
                      onPressed: () => openPlace(context, place),
                      child: Text(s.openPlace(place.names.inLanguage(lang))),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (final id in gate.sourceIds)
                if (registry?.source(id) case final src?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      src.title.inLanguage(lang),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every source a player cites, titles and links.
class SourcesSheet extends StatelessWidget {
  const SourcesSheet({super.key, required this.ids, required this.intro});
  final Set<String> ids;
  final Localized intro;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final registry = AppScope.maybeOf(context)?.registry;
    return SafeArea(
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
              Text(
                s.sourcesTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(intro.inLanguage(lang)),
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
    );
  }
}

/// The docks: Story (reveal, story, beats), Gates (each gate, Marmara to the
/// Horn) and Section (the layers of the defences, outside in).
class WallSheet extends StatelessWidget {
  const WallSheet({super.key, required this.player, required this.panel});
  final WallPlayerState player;
  final WallPanel panel;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final c = player.controller, m = c.manifest;
    final theme = Theme.of(context);
    final rows = switch (panel) {
      WallPanel.story => <Widget>[
        if (c.reduced) Text(s.plateStillHint, style: theme.textTheme.bodySmall),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const ValueKey('walls-play-story'),
              onPressed: () {
                player.closeControls();
                c.playStory();
              },
              icon: const PlanIcon(PlanSymbol.story, size: 18),
              label: Text(s.platePlay),
            ),
            OutlinedButton.icon(
              key: const ValueKey('walls-play-reveal'),
              onPressed: () {
                player.closeControls();
                c.play();
              },
              icon: const PlanIcon(PlanSymbol.route, size: 18),
              label: Text(s.plateStartReveal),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final b in m.beats)
          ListTile(
            key: ValueKey('walls-beat-${b.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(b.label.inLanguage(lang)),
            onTap: () {
              player.closeControls();
              if (c.reduced) {
                final i = m.stills.indexOf(b.id);
                if (i >= 0) return c.stills(i);
              }
              c.goTo(b.at);
            },
          ),
      ],
      WallPanel.gates => <Widget>[
        for (final g in m.gates)
          ListTile(
            key: ValueKey('walls-gate-${g.id}'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: PlanIcon(
              PlanSymbol.gate,
              size: 18,
              color: g.legend ? MeasureColors.of(context).secondary : null,
            ),
            title: Text(g.names.inLanguage(lang)),
            subtitle: Text(
              [
                ?g.year,
                _km(g.at, lang),
                if (g.legend) s.wallsLegend,
              ].join(' · '),
            ),
            onTap: () {
              player.closeControls();
              c.goTo(g.at);
              player.showGate(g);
            },
          ),
      ],
      WallPanel.section => <Widget>[
        Text(
          c.segment.label.inLanguage(lang),
          style: theme.textTheme.titleSmall,
        ),
        Text(c.segment.note.inLanguage(lang), style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        for (final l in m.layers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              key: ValueKey('walls-layer-${l.id}'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.label.inLanguage(lang),
                  style: theme.textTheme.titleSmall,
                ),
                Text(l.note.inLanguage(lang), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
      ],
    };
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .38,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        shrinkWrap: true,
        children: rows,
      ),
    );
  }

  static String _km(double metres, String lang) {
    final t = (metres / 1000).toStringAsFixed(1);
    return '${lang == 'tr' ? t.replaceAll('.', ',') : t} km';
  }
}
