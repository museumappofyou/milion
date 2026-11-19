import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_scene/scene.dart' as fs;

import '../content/models.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../plate/look_up.dart';
import '../shell/app_scope.dart';
import '../shell/original_photo.dart';
import '../space/snapshot_builder.dart';
import 'walk.dart';
import 'walk_controller.dart';
import 'walk_scene.dart';

enum WalkPanel { story, look, layers }

/// An immersive walk (WK, P14): the hall drawn by flutter_scene, walked on
/// its deck with a thumb (drag up to walk, sideways to turn) or turned with
/// the phone after an opt-in; a 10-second reveal, a story through the stops,
/// and stills for reduced motion. Leader lines name what is near.
class WalkPlayer extends StatefulWidget {
  const WalkPlayer({
    super.key,
    required this.walk,
    this.loadBytes,
    this.backend,
    this.orientation,
  });
  final WalkManifest walk;

  /// Test seams: the model's bytes, whether Flutter GPU can draw, and the
  /// rotation sensor.
  final LoadBytes? loadBytes;
  final bool? backend;
  final PlateOrientation? orientation;
  @override
  WalkPlayerState createState() => WalkPlayerState();
}

class WalkPlayerState extends State<WalkPlayer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final WalkController controller = WalkController(widget.walk);
  late final PlateOrientation orientation =
      widget.orientation ?? PlateOrientation();
  late final bool backend = widget.backend ?? walkBackendAvailable();
  WalkScene? scene;
  Object? error;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  WalkPanel? _open;
  WalkPanel? get openPanel => _open;
  double? _yawAtSensor;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Without the GPU view (tests, old phones) a ticker runs the timeline;
    // with it, the SceneView's own tick does.
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      controller.advance(dt);
    });
    controller.addListener(_changed);
    orientation.motion.addListener(_sensed);
    orientation.addListener(_sensorState);
    if (backend) _load();
  }

  Future<void> _load() async {
    try {
      final s = await WalkScene.load(widget.walk, loadBytes: widget.loadBytes);
      if (!mounted) return s.dispose();
      setState(() => scene = s);
    } on Object catch (e) {
      if (mounted) setState(() => error = e);
    }
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
    final tick = !backend && controller.needsTicker && _active;
    if (tick && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!tick && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _sensorState() => setState(() {});

  /// The rotation sensor turns the head: its first reading keeps the
  /// current heading, then the phone's turn adds to it.
  void _sensed() {
    if (!orientation.enabled) return;
    final a = orientation.basis.angles;
    _yawAtSensor ??= controller.yaw - a.azimuth;
    controller.look(_yawAtSensor! + a.azimuth, a.elevation);
  }

  void setLookSensor(bool on) {
    _yawAtSensor = null;
    orientation.setEnabled(on);
  }

  void controls(WalkPanel panel) =>
      setState(() => _open = _open == panel ? null : panel);
  void closeControls() => setState(() => _open = null);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _active ? orientation.resume() : orientation.suspend();
    _changed();
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    controller.removeListener(_changed);
    controller.dispose();
    orientation.motion.removeListener(_sensed);
    orientation.removeListener(_sensorState);
    if (widget.orientation == null) orientation.dispose();
    scene?.dispose();
    super.dispose();
  }

  void _drag(DragUpdateDetails d, Size size) {
    if (orientation.enabled) setLookSensor(false);
    controller.walk(
      forward: -d.delta.dy * .045,
      turn: d.delta.dx * 1.1 / size.width,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DesignTheme.lamp,
      child: Builder(
        builder: (context) {
          final s = context.l10n, lang = context.language;
          final c = controller;
          return Scaffold(
            appBar: AppBar(title: Text(widget.walk.title.inLanguage(lang))),
            body: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.biggest;
                      return Stack(
                        children: [
                          Positioned.fill(child: _view(context, size)),
                          // Leader lines and the small plan belong to the
                          // 3D view; without it the plan is the view.
                          if (backend)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: WalkCalloutPainter(
                                      c,
                                      lang,
                                      Theme.of(context).textTheme.bodySmall!,
                                      MeasureColors.of(context).accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (backend)
                            Positioned(
                              top: 56,
                              right: 12,
                              child: IgnorePointer(
                                child: Semantics(
                                  label: s.walkPlan,
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      size: Size(
                                        108,
                                        108 *
                                            widget.walk.grid.width /
                                            widget.walk.grid.length,
                                      ),
                                      painter: WalkPlanPainter(
                                        c,
                                        MeasureColors.of(context).accent,
                                        MeasureColors.of(context).secondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          _WalkLabels(
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
                    child: WalkSheet(player: this, panel: panel),
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
                      runSpacing: 4,
                      children: [
                        for (final item in [
                          (WalkPanel.story, PlanSymbol.story, s.plateStory),
                          (WalkPanel.look, PlanSymbol.lookUp, s.walkLook),
                          (WalkPanel.layers, PlanSymbol.layers, s.plateLayers),
                        ])
                          TextButton.icon(
                            key: ValueKey('walk-${item.$1.name}'),
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

  Widget _view(BuildContext context, Size size) {
    final s = context.l10n, lang = context.language, c = controller;
    final fog = widget.walk.fogColour;
    final ground = Color.fromARGB(
      255,
      (math.pow(fog[0], 1 / 2.2) * 255).round(),
      (math.pow(fog[1], 1 / 2.2) * 255).round(),
      (math.pow(fog[2], 1 / 2.2) * 255).round(),
    );
    Widget view;
    if (error != null) {
      view = Center(
        child: ContentState(
          error: true,
          title: s.sceneUnavailable,
          message: s.walkUnavailable,
        ),
      );
    } else if (!backend) {
      // No GPU view: the plan at full size, with the same stops.
      view = Padding(
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 120),
        child: Center(
          child: AspectRatio(
            aspectRatio: widget.walk.grid.length / widget.walk.grid.width,
            child: CustomPaint(
              key: const ValueKey('walk-plan-fallback'),
              painter: WalkPlanPainter(
                c,
                MeasureColors.of(context).accent,
                MeasureColors.of(context).secondary,
              ),
            ),
          ),
        ),
      );
    } else if (scene == null) {
      view = Center(
        child: Semantics(label: s.walkLoading, child: const TesseraLoader()),
      );
    } else {
      final w = scene!;
      view = fs.SceneView(
        w.scene,
        key: const ValueKey('walk-scene'),
        autoTick: _active,
        onTick: (elapsed, dt) => c.advance(dt),
        cameraBuilder: (elapsed) {
          w.update(c, elapsed.inMicroseconds / 1e6);
          return w.camera(c.camera);
        },
      );
    }
    return ColoredBox(
      color: ground,
      child: Semantics(
        label:
            '${widget.walk.title.inLanguage(lang)}. '
            '${widget.walk.talkback.inLanguage(lang)}',
        hint: s.walkHint,
        customSemanticsActions: {
          CustomSemanticsAction(label: s.plateNext): () => c.step(1),
          CustomSemanticsAction(label: s.platePrevious): () => c.step(-1),
          CustomSemanticsAction(label: s.platePlay): c.playStory,
        },
        child: GestureDetector(
          key: const ValueKey('walk-viewport'),
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => c.explore(),
          onPanUpdate: (d) => _drag(d, size),
          onDoubleTap: () => c.step(1),
          onTap: c.mode == WalkMode.stills ? () => c.step(1) : null,
          child: view,
        ),
      ),
    );
  }
}

/// The honesty label, the stop and the caption, rebuilt only when one of
/// them changes.
class _WalkLabels extends StatelessWidget {
  const _WalkLabels({required this.controller, required this.captionHeight});
  final WalkController controller;
  final double captionHeight;

  @override
  Widget build(BuildContext context) => SnapshotBuilder(
    listenable: controller,
    snapshot: () => (
      controller.honesty,
      controller.caption,
      controller.currentStop?.id,
      controller.mode,
    ),
    builder: (context) {
      final c = controller, lang = context.language, s = context.l10n;
      final ground = Theme.of(context).scaffoldBackgroundColor
          .withValues(alpha: .9);
      final caption = c.caption?.inLanguage(lang);
      final stop = c.currentStop;
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
                  key: const ValueKey('walk-honesty'),
                ),
              ),
            ),
          ),
          if (caption != null)
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: captionHeight),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: ground),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Semantics(
                      liveRegion: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.mode == WalkMode.stills)
                            Text(
                              s.walkStill(
                                '${c.stillIndex + 1}',
                                '${c.manifest.stills.length}',
                              ),
                              style: TypeRole.measurement,
                            ),
                          if (stop != null && c.mode != WalkMode.reveal)
                            Text(
                              stop.label.inLanguage(lang),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          Text(
                            caption,
                            key: const ValueKey('walk-caption'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (stop?.photo case final photo?
                              when c.mode == WalkMode.stills)
                            TextButton.icon(
                              key: const ValueKey('walk-still-photo'),
                              onPressed: () => openOriginalPhoto(
                                context,
                                photo,
                                title: stop!.label,
                              ),
                              icon: const Icon(Icons.photo_outlined, size: 18),
                              label: Text(s.seePhotograph),
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

/// Leader lines: each callout's point in the hall, a hairline to its label
/// at the nearer margin (P03's plates with leader lines, in space).
class WalkCalloutPainter extends CustomPainter {
  WalkCalloutPainter(this.controller, this.language, this.style, this.colour)
    : super(repaint: controller);
  final WalkController controller;
  final String language;
  final TextStyle style;
  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    final callouts = controller.visibleCallouts();
    if (callouts.isEmpty) return;
    final p = WalkProjector(controller.camera, size.width, size.height);
    final line = Paint()
      ..color = colour
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final usedLeft = <double>[], usedRight = <double>[];
    for (final c in callouts) {
      final at = p.project(c.anchor);
      if (at == null) continue;
      final (x, y) = at;
      if (x < 0 || x > size.width || y < 64 || y > size.height * .72) continue;
      final left = x < size.width / 2;
      final text = TextPainter(
        text: TextSpan(
          text: c.label.inLanguage(language),
          style: style.copyWith(color: colour),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: size.width * .34);
      // Keep labels from stacking on each other at one margin.
      var ly = y - text.height / 2;
      final used = left ? usedLeft : usedRight;
      for (final u in used) {
        if ((ly - u).abs() < text.height + 6) ly = u + text.height + 6;
      }
      used.add(ly);
      final lx = left ? 12.0 : size.width - 12 - text.width;
      final end = Offset(
        left ? lx + text.width + 4 : lx - 4,
        ly + text.height / 2,
      );
      canvas
        ..drawCircle(Offset(x, y), 2.5, line)
        ..drawLine(Offset(x, y), end, line);
      final bg = Paint()..color = const Color(0xCC151314);
      canvas.drawRect(
        Rect.fromLTWH(lx - 4, ly - 2, text.width + 8, text.height + 4),
        bg,
      );
      text.paint(canvas, Offset(lx, ly));
    }
  }

  @override
  bool shouldRepaint(WalkCalloutPainter old) =>
      old.controller != controller || old.language != language;
}

/// The hall in plan: its outline, the 336 columns as points, the deck, and
/// where the eye stands and looks.
class WalkPlanPainter extends CustomPainter {
  WalkPlanPainter(this.controller, this.accent, this.ink)
    : super(repaint: controller);
  final WalkController controller;
  final Color accent, ink;

  @override
  void paint(Canvas canvas, Size size) {
    final m = controller.manifest, g = m.grid;
    final k = math.min(size.width / g.length, size.height / g.width);
    Offset at(double x, double z) => Offset(x * k, z * k);
    final hair = Paint()
      ..color = ink
      ..strokeWidth = .8
      ..style = PaintingStyle.stroke;
    canvas
      ..drawRect(
        Rect.fromLTWH(0, 0, g.length * k, g.width * k),
        Paint()..color = const Color(0xCC151314),
      )
      ..drawRect(Rect.fromLTWH(0, 0, g.length * k, g.width * k), hair);
    final dot = Paint()..color = ink;
    final r = math.max(.6, .28 * k);
    for (var a = 1; a <= g.along; a++) {
      for (var b = 1; b <= g.across; b++) {
        final (x, z) = g.column(a, b);
        canvas.drawCircle(at(x, z), m.specialAt(a, b) == null ? r : r * 2, dot);
      }
    }
    final deck = Path();
    for (var i = 0; i < m.route.length; i++) {
      final (x, z) = m.route[i];
      final o = at(x, z);
      i == 0 ? deck.moveTo(o.dx, o.dy) : deck.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      deck,
      Paint()
        ..color = accent.withValues(alpha: .6)
        ..strokeWidth = math.max(1, 2.2 * k)
        ..style = PaintingStyle.stroke,
    );
    // The view: a cone about three bays deep, kept inside the hall.
    final cam = controller.camera;
    final eye = at(cam.eye.x, cam.eye.z);
    final reach = 14 * k;
    final view = Path()
      ..moveTo(eye.dx, eye.dy)
      ..lineTo(
        eye.dx + math.cos(cam.yaw - .5) * reach,
        eye.dy + math.sin(cam.yaw - .5) * reach,
      )
      ..lineTo(
        eye.dx + math.cos(cam.yaw + .5) * reach,
        eye.dy + math.sin(cam.yaw + .5) * reach,
      )
      ..close();
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(0, 0, g.length * k, g.width * k))
      ..drawPath(view, Paint()..color = accent.withValues(alpha: .25))
      ..restore()
      ..drawCircle(eye, math.max(2, 1.2 * k), Paint()..color = accent);
  }

  @override
  bool shouldRepaint(WalkPlanPainter old) => old.controller != controller;
}

/// The docks: Story (reveal, story, stops, stills), Look (the rotation
/// sensor, opt-in) and Layers (fish, leader lines, sources, sound to come).
class WalkSheet extends StatelessWidget {
  const WalkSheet({super.key, required this.player, required this.panel});
  final WalkPlayerState player;
  final WalkPanel panel;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final c = player.controller, m = c.manifest;
    final theme = Theme.of(context);
    final registry = AppScope.maybeOf(context)?.registry;
    final reduced = c.reduced;
    List<Widget> rows;
    switch (panel) {
      case WalkPanel.story:
        rows = [
          if (reduced) Text(s.plateStillHint, style: theme.textTheme.bodySmall),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('walk-play-reveal'),
                onPressed: () {
                  player.closeControls();
                  c.play();
                },
                icon: const PlanIcon(PlanSymbol.light, size: 18),
                label: Text(s.plateStartReveal),
              ),
              OutlinedButton.icon(
                key: const ValueKey('walk-play-story'),
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
          Text(s.walkStops, style: theme.textTheme.titleSmall),
          for (final stop in m.stops)
            InkWell(
              key: ValueKey('walk-stop-${stop.id}'),
              onTap: () {
                if (reduced) {
                  final i = m.stills.indexOf(stop.id);
                  c.stills(i < 0 ? 0 : i);
                } else {
                  c.goTo(stop);
                }
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    const PlanIcon(PlanSymbol.route, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(stop.label.inLanguage(lang))),
                    if (stop.photo case final photo?)
                      IconButton(
                        key: ValueKey('walk-photo-${stop.id}'),
                        tooltip: s.seePhotograph,
                        onPressed: () => openOriginalPhoto(
                          context,
                          photo,
                          title: stop.label,
                        ),
                        icon: const Icon(Icons.photo_outlined, size: 20),
                      ),
                  ],
                ),
              ),
            ),
        ];
      case WalkPanel.look:
        rows = [
          SwitchListTile(
            key: const ValueKey('walk-look-sensor'),
            contentPadding: EdgeInsets.zero,
            title: Text(s.walkLookSensor),
            subtitle: Text(
              player.orientation.unavailable
                  ? s.plateGyroUnavailable
                  : s.plateLookUpSensorHint,
            ),
            value: player.orientation.enabled,
            onChanged: player.setLookSensor,
          ),
          Text(s.walkHint, style: theme.textTheme.bodySmall),
        ];
      case WalkPanel.layers:
        rows = [
          SwitchListTile(
            key: const ValueKey('walk-fish'),
            contentPadding: EdgeInsets.zero,
            title: Text(s.walkFish),
            subtitle: Text(m.fishNote.inLanguage(lang)),
            value: c.fish,
            onChanged: reduced ? null : c.setFish,
          ),
          SwitchListTile(
            key: const ValueKey('walk-callouts'),
            contentPadding: EdgeInsets.zero,
            title: Text(s.walkCallouts),
            value: c.labels,
            onChanged: c.setLabels,
          ),
          for (final a in m.ambient)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PlanIcon(PlanSymbol.sound, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      a.note.inLanguage(lang),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(s.sourcesTitle, style: theme.textTheme.titleSmall),
          for (final id in m.allSourceIds)
            if (registry?.source(id) case final source?)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  source.title.inLanguage(lang),
                  style: theme.textTheme.bodySmall,
                ),
              ),
        ];
    }
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
                  child: Text(switch (panel) {
                    WalkPanel.story => s.plateStory,
                    WalkPanel.look => s.walkLook,
                    WalkPanel.layers => s.plateLayers,
                  }, style: theme.textTheme.titleMedium),
                ),
                IconButton(
                  key: const ValueKey('walk-close-controls'),
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

/// The honesty label a walk shows by default.
Honesty walkHonesty(WalkManifest m) => m.honesty;
