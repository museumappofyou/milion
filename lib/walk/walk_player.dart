import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_scene/scene.dart' as fs;

import '../content/models.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/player_bar.dart';
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

class WalkWaypointHit {
  const WalkWaypointHit(this.waypoint, this.center, this.radius);
  final WalkWaypoint waypoint;
  final Offset center;
  final double radius;
}

class WalkCalloutHit {
  const WalkCalloutHit(this.callout, this.rect, this.anchor);
  final WalkCallout callout;
  final Rect rect;
  final Offset anchor;
}

/// An immersive walk (WK, P14): the hall drawn by flutter_scene, full X/Y
/// touch look (drag anywhere to look around, up into the vaults or down into
/// the water), interactive 3D stepping circles on the walkway plus a floating
/// circular movement pad, tappable architectural callout cards with real
/// photographs, a 10-second reveal, a story through the stops, and stills for
/// reduced motion.
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

  // Hit targets refreshed on every overlay paint for tapping deck circles & callouts.
  final _waypointHits = <WalkWaypointHit>[];
  final _calloutHits = <WalkCalloutHit>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Without the GPU view (tests, old phones) a ticker runs timelines/glides;
    // with it, SceneView's own tick drives controller.advance(dt).
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

  void controls(WalkPanel panel) {
    controller.selectCallout(null);
    setState(() => _open = _open == panel ? null : panel);
  }

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

  /// Free X & Y axis look: drag sideways to turn 360°, drag up/down to look
  /// up into the brick vaults and capitals or down into the reflecting water.
  void _drag(DragUpdateDetails d, Size size) {
    if (orientation.enabled) setLookSensor(false);
    controller.lookBy(
      d.delta.dx * 1.45 / math.max(1.0, size.width),
      -d.delta.dy * 1.45 / math.max(1.0, size.height),
    );
  }

  void _tapUp(TapUpDetails details) {
    final c = controller;
    if (c.mode == WalkMode.stills) {
      c.step(1);
      return;
    }
    final pos = details.localPosition;
    // 1. Check tappable architectural callout labels & anchor dots first.
    for (final hit in _calloutHits) {
      if (hit.rect.inflate(8).contains(pos) ||
          (hit.anchor - pos).distance <= 24) {
        if (_open != null) closeControls();
        c.selectCallout(hit.callout);
        return;
      }
    }
    // 2. Check interactive 3D stepping circles on the walkway.
    WalkWaypointHit? bestWp;
    var bestDist = double.infinity;
    for (final hit in _waypointHits) {
      final d = (hit.center - pos).distance;
      final threshold = math.max(28.0, hit.radius * 1.35);
      if (d <= threshold && d < bestDist) {
        bestDist = d;
        bestWp = hit;
      }
    }
    if (bestWp != null) {
      if (_open != null) closeControls();
      c.glideToWaypoint(bestWp.waypoint);
      return;
    }
    // 3. Tapping open space dismisses an open callout card.
    if (c.selectedCallout != null) {
      c.selectCallout(null);
    }
  }

  Future<void> showSources() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTheme.lamp.colorScheme.surface,
    builder: (context) {
      final s = context.l10n, lang = context.language;
      final registry = AppScope.maybeOf(context)?.registry;
      return Theme(
        data: DesignTheme.lamp,
        child: DefaultTextStyle(
          style: DesignTheme.lamp.textTheme.bodyMedium!,
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
                            style: DesignTheme.lamp.textTheme.titleLarge,
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
                    Text(widget.walk.talkback.inLanguage(lang)),
                    const SizedBox(height: 16),
                    for (final id in widget.walk.allSourceIds)
                      if (registry?.source(id) case final source?)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                source.title.inLanguage(lang),
                                style: DesignTheme.lamp.textTheme.titleSmall,
                              ),
                              SelectableText(
                                source.url,
                                style: DesignTheme.lamp.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
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
      data: DesignTheme.lamp,
      child: Builder(
        builder: (context) {
          final s = context.l10n, lang = context.language;
          final c = controller;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.walk.title.inLanguage(lang),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                PlayerSourcesButton(
                  key: const ValueKey('walk-appbar-sources'),
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
                          Positioned.fill(child: _view(context, size)),
                          // Interactive 3D stepping circles projected on the walkway.
                          if (backend)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: WalkWaypointPainter(
                                      c,
                                      MeasureColors.of(context).accent,
                                      _waypointHits,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Tappable leader lines naming columns, vaults, ties & water.
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
                                      _calloutHits,
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
                            captionHeight: size.height * .34,
                            sheetOpen: _open != null,
                          ),
                          // Floating interactive circular walk pad (bottom-left).
                          if (backend)
                            SnapshotBuilder(
                              listenable: c,
                              snapshot: () => (
                                c.mode,
                                c.reduced,
                                c.selectedCallout?.id,
                                _open,
                              ),
                              builder: (context) {
                                final showPad =
                                    c.mode == WalkMode.explore &&
                                    !c.reduced &&
                                    c.selectedCallout == null &&
                                    _open == null;
                                if (!showPad) return const SizedBox.shrink();
                                return Positioned(
                                  left: 16,
                                  bottom: 18,
                                  child: _WalkMoveCircle(
                                    controller: c,
                                    accent: MeasureColors.of(context).accent,
                                  ),
                                );
                              },
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
                PlayerDockBar(
                  items: [
                    PlayerDockItem(
                      key: const ValueKey('walk-story'),
                      symbol: PlanSymbol.story,
                      label: s.plateStory,
                      selected: _open == WalkPanel.story,
                      onTap: () => controls(WalkPanel.story),
                    ),
                    PlayerDockItem(
                      key: const ValueKey('walk-look'),
                      symbol: PlanSymbol.lookUp,
                      label: s.walkLook,
                      selected: _open == WalkPanel.look,
                      onTap: () => controls(WalkPanel.look),
                    ),
                    PlayerDockItem(
                      key: const ValueKey('walk-layers'),
                      symbol: PlanSymbol.layers,
                      label: s.plateLayers,
                      selected: _open == WalkPanel.layers,
                      onTap: () => controls(WalkPanel.layers),
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

  static int _srgbChannel(double linear) {
    final c = linear.clamp(0.0, 1.0);
    final v = c <= 0.0031308
        ? 12.92 * c
        : 1.055 * math.pow(c, 1.0 / 2.4) - 0.055;
    return (v.clamp(0.0, 1.0) * 255).round();
  }

  /// Resolves a linear fog color through the exact same Khronos PBR Neutral
  /// tone mapper + sRGB OETF that flutter_scene's resolve pass applies, so the
  /// viewport backdrop matches distant fogged geometry down to the exact byte.
  static Color _resolveFogColor(List<double> fog) {
    final x = math.min(fog[0], math.min(fog[1], fog[2]));
    final offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
    var r = (fog[0] - offset).clamp(0.0, double.infinity);
    var g = (fog[1] - offset).clamp(0.0, double.infinity);
    var b = (fog[2] - offset).clamp(0.0, double.infinity);
    const startCompression = 0.76;
    const desaturation = 0.15;
    final peak = math.max(r, math.max(g, b));
    if (peak >= startCompression) {
      const d = 1.0 - startCompression;
      final newPeak = 1.0 - d * d / (peak + d - startCompression);
      final scale = newPeak / peak;
      r *= scale;
      g *= scale;
      b *= scale;
      final sat = 1.0 - 1.0 / (desaturation * (peak - newPeak) + 1.0);
      r += (newPeak - r) * sat;
      g += (newPeak - g) * sat;
      b += (newPeak - b) * sat;
    }
    return Color.fromARGB(
      255,
      _srgbChannel(r),
      _srgbChannel(g),
      _srgbChannel(b),
    );
  }

  Widget _view(BuildContext context, Size size) {
    final s = context.l10n, lang = context.language, c = controller;
    final ground = _resolveFogColor(widget.walk.fogColour);
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
          onTapUp: _tapUp,
          onDoubleTap: () => c.step(1),
          child: view,
        ),
      ),
    );
  }
}

/// Interactive circular thumb-pad in the lower-left viewport corner: drag the
/// inner puck up/down to walk smoothly along the boardwalk and left/right to
/// turn, or quick-tap top/bottom to step one bay ahead or back.
class _WalkMoveCircle extends StatefulWidget {
  const _WalkMoveCircle({required this.controller, required this.accent});
  final WalkController controller;
  final Color accent;

  @override
  State<_WalkMoveCircle> createState() => _WalkMoveCircleState();
}

class _WalkMoveCircleState extends State<_WalkMoveCircle> {
  static const double _size = 86;
  static const double _maxOffset = 25;
  Offset _puck = Offset.zero;

  void _update(Offset local) {
    const center = Offset(_size / 2, _size / 2);
    var delta = local - center;
    if (delta.distance > _maxOffset) {
      delta = Offset.fromDirection(delta.direction, _maxOffset);
    }
    setState(() => _puck = delta);
    final nx = (delta.dx / _maxOffset).clamp(-1.0, 1.0);
    final ny = (-delta.dy / _maxOffset).clamp(-1.0, 1.0);
    widget.controller.setPadInput(ny, nx);
  }

  void _reset() {
    if (_puck != Offset.zero) setState(() => _puck = Offset.zero);
    widget.controller.setPadInput(0, 0);
  }

  void _tapUp(TapUpDetails d) {
    final dy = d.localPosition.dy - _size / 2;
    widget.controller.stepAlongFacing(dy <= 0 ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    final active = _puck != Offset.zero;
    return Semantics(
      label: context.l10n.walkMoveLabel,
      hint: context.l10n.walkMoveHint,
      child: GestureDetector(
        key: const ValueKey('walk-move-circle'),
        behavior: HitTestBehavior.opaque,
        onTapUp: _tapUp,
        onPanStart: (d) => _update(d.localPosition),
        onPanUpdate: (d) => _update(d.localPosition),
        onPanEnd: (_) => _reset(),
        onPanCancel: _reset,
        child: SizedBox(
          width: _size,
          height: _size,
          child: CustomPaint(
            painter: _MoveCirclePainter(
              puck: _puck,
              accent: widget.accent,
              active: active,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoveCirclePainter extends CustomPainter {
  const _MoveCirclePainter({
    required this.puck,
    required this.accent,
    required this.active,
  });
  final Offset puck;
  final Color accent;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 2;
    // Translucent dark cistern-lamp glass disc.
    canvas.drawCircle(center, r, Paint()..color = const Color(0xAA151314));
    // Crisp outer ring & subtle inner track ring.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = accent.withValues(alpha: active ? 0.92 : 0.58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 2.0 : 1.4,
    );
    canvas.drawCircle(
      center,
      r * 0.52,
      Paint()
        ..color = accent.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    // Subtle directional chevrons (▲ forward, ▼ back, ◀ left, ▶ right).
    final tickPaint = Paint()
      ..color = accent.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void chevron(Offset tip, Offset dir) {
      final perp = Offset(-dir.dy, dir.dx);
      final p1 = tip - dir * 5 + perp * 4.5;
      final p2 = tip - dir * 5 - perp * 4.5;
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(p2.dx, p2.dy);
      canvas.drawPath(path, tickPaint);
    }

    chevron(center + Offset(0, -(r - 7)), const Offset(0, -1));
    chevron(center + Offset(0, r - 7), const Offset(0, 1));
    chevron(center + Offset(-(r - 7), 0), const Offset(-1, 0));
    chevron(center + Offset(r - 7, 0), const Offset(1, 0));

    // Movable tactile center puck.
    final pCenter = center + puck;
    canvas.drawCircle(
      pCenter,
      14,
      Paint()..color = accent.withValues(alpha: active ? 0.34 : 0.20),
    );
    canvas.drawCircle(
      pCenter,
      11,
      Paint()
        ..color = accent.withValues(alpha: active ? 0.96 : 0.78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    canvas.drawCircle(pCenter, 3.5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_MoveCirclePainter old) =>
      old.puck != puck || old.active != active || old.accent != accent;
}

/// Interactive 3D perspective stepping circles projected onto the visitors'
/// walkway so visitors can tap directly on the floor to glide forward/back.
class WalkWaypointPainter extends CustomPainter {
  WalkWaypointPainter(this.controller, this.accent, this.hits)
    : super(repaint: controller);
  final WalkController controller;
  final Color accent;
  final List<WalkWaypointHit> hits;

  @override
  void paint(Canvas canvas, Size size) {
    hits.clear();
    if (controller.mode != WalkMode.explore || controller.reduced) return;
    final cam = controller.camera;
    final p = WalkProjector(cam, size.width, size.height);
    final eye = cam.eye;
    const circleRadius = 0.44;
    const segments = 16;

    for (final wp in controller.waypoints) {
      final dx = wp.point.x - eye.x;
      final dz = wp.point.z - eye.z;
      final dist = math.sqrt(dx * dx + dz * dz);
      if (dist < 2.2 || dist > 26.0) continue;
      final center2d = p.project(wp.point);
      if (center2d == null) continue;
      final (cx, cy) = center2d;
      if (cx < -20 ||
          cx > size.width + 20 ||
          cy < 80 ||
          cy > size.height - 20) {
        continue;
      }

      // Project a horizontal 3D circle onto the boardwalk plane for true foreshortening.
      final path = Path();
      var maxR = 0.0;
      var valid = true;
      for (var i = 0; i <= segments; i++) {
        final a = 2 * math.pi * i / segments;
        final pt = WalkPoint(
          wp.point.x + math.cos(a) * circleRadius,
          wp.point.y,
          wp.point.z + math.sin(a) * circleRadius,
        );
        final proj = p.project(pt);
        if (proj == null) {
          valid = false;
          break;
        }
        final off = Offset(proj.$1, proj.$2);
        final d = (off - Offset(cx, cy)).distance;
        if (d > maxR) maxR = d;
        if (i == 0) {
          path.moveTo(off.dx, off.dy);
        } else {
          path.lineTo(off.dx, off.dy);
        }
      }
      if (!valid || maxR < 5.0 || maxR > size.width * 0.45) continue;
      path.close();

      final fade = (1.0 - (dist - 3.0) / 23.0).clamp(0.22, 0.92);
      final isStop = wp.stop != null;
      final fillAlpha = isStop ? 0.24 * fade : 0.14 * fade;
      final strokeAlpha = isStop ? 0.92 * fade : 0.68 * fade;

      canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: fillAlpha)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: strokeAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isStop ? 2.1 : 1.5,
      );
      // Inner stepping dot (double ring on named stops).
      if (isStop) {
        final inner = Path();
        for (var i = 0; i <= segments; i++) {
          final a = 2 * math.pi * i / segments;
          final proj = p.project(
            WalkPoint(
              wp.point.x + math.cos(a) * circleRadius * 0.48,
              wp.point.y,
              wp.point.z + math.sin(a) * circleRadius * 0.48,
            ),
          );
          if (proj == null) break;
          i == 0
              ? inner.moveTo(proj.$1, proj.$2)
              : inner.lineTo(proj.$1, proj.$2);
        }
        inner.close();
        canvas.drawPath(
          inner,
          Paint()
            ..color = accent.withValues(alpha: 0.75 * fade)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      } else {
        canvas.drawCircle(
          Offset(cx, cy),
          math.max(2.0, maxR * 0.13),
          Paint()..color = accent.withValues(alpha: 0.72 * fade),
        );
      }
      hits.add(WalkWaypointHit(wp, Offset(cx, cy), maxR));
    }
  }

  @override
  bool shouldRepaint(WalkWaypointPainter old) => old.controller != controller;
}

/// The honesty label, the stop caption, and the tappable architectural fact card.
class _WalkLabels extends StatelessWidget {
  const _WalkLabels({
    required this.controller,
    required this.captionHeight,
    required this.sheetOpen,
  });
  final WalkController controller;
  final double captionHeight;
  final bool sheetOpen;

  @override
  Widget build(BuildContext context) => SnapshotBuilder(
    listenable: controller,
    snapshot: () => (
      controller.honesty,
      controller.caption,
      controller.currentStop?.id,
      controller.mode,
      controller.selectedCallout?.id,
    ),
    builder: (context) {
      final c = controller, lang = context.language, s = context.l10n;
      final ground = Theme.of(context).scaffoldBackgroundColor
          .withValues(alpha: .92);
      final caption = c.caption?.inLanguage(lang);
      final stop = c.currentStop;
      final selected = c.selectedCallout;
      final registry = AppScope.maybeOf(context)?.registry;
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
          if (selected != null && !sheetOpen)
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: captionHeight),
                child: DecoratedBox(
                  key: const ValueKey('walk-callout-card'),
                  decoration: BoxDecoration(
                    color: ground,
                    border: Border.all(
                      color: MeasureColors.of(context).accent
                          .withValues(alpha: .45),
                      width: .8,
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selected.label.inLanguage(lang),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  if (selected.metric case final metric?)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        metric.inLanguage(lang),
                                        style: TypeRole.measurement.copyWith(
                                          color: MeasureColors.of(context)
                                              .accent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('walk-callout-close'),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              onPressed: () => c.selectCallout(null),
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          selected.note.inLanguage(lang),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (selected.photo case final photo?)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: OutlinedButton.icon(
                              key: const ValueKey('walk-callout-photo'),
                              onPressed: () => openOriginalPhoto(
                                context,
                                photo,
                                title: selected.label,
                              ),
                              icon: const Icon(Icons.photo_outlined, size: 18),
                              label: Text(s.seePhotograph),
                            ),
                          ),
                        if (registry != null && selected.sourceIds.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              selected.sourceIds
                                  .map(
                                    (id) => registry
                                        .source(id)
                                        ?.title
                                        .inLanguage(lang),
                                  )
                                  .whereType<String>()
                                  .take(2)
                                  .join(' · '),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: MeasureColors.of(context).secondary,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (caption != null)
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

/// Leader lines: each callout's point in the hall, a hairline to its tappable
/// info label at the nearer margin (P03's plates with leader lines, in space).
class WalkCalloutPainter extends CustomPainter {
  WalkCalloutPainter(
    this.controller,
    this.language,
    this.style,
    this.colour,
    this.hits,
  ) : super(repaint: controller);
  final WalkController controller;
  final String language;
  final TextStyle style;
  final Color colour;
  final List<WalkCalloutHit> hits;

  @override
  void paint(Canvas canvas, Size size) {
    hits.clear();
    final callouts = controller.visibleCallouts();
    if (callouts.isEmpty) return;
    final p = WalkProjector(controller.camera, size.width, size.height);
    final line = Paint()
      ..color = colour
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final dotFill = Paint()..color = colour;
    final usedLeft = <double>[], usedRight = <double>[];
    final selectedId = controller.selectedCallout?.id;

    for (final c in callouts) {
      final at = p.project(c.anchor);
      if (at == null) continue;
      final (x, y) = at;
      if (x < 0 || x > size.width || y < 64 || y > size.height * .72) continue;
      final left = x < size.width / 2;
      final isSelected = c.id == selectedId;
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
        if ((ly - u).abs() < text.height + 10) ly = u + text.height + 10;
      }
      if (ly + text.height > size.height * 0.74) continue;
      used.add(ly);

      const badgeSpace = 15.0;
      final totalW = text.width + badgeSpace;
      final lx = left ? 12.0 : size.width - 12 - totalW;
      final end = Offset(left ? lx + totalW + 5 : lx - 5, ly + text.height / 2);
      final anchor = Offset(x, y);
      canvas
        ..drawCircle(
          anchor,
          isSelected ? 4.5 : 3.0,
          isSelected ? dotFill : line,
        )
        ..drawLine(anchor, end, line);

      final rect = Rect.fromLTWH(lx - 5, ly - 3, totalW + 10, text.height + 6);
      canvas.drawRect(
        rect,
        Paint()
          ..color = isSelected
              ? const Color(0xEE221C18)
              : const Color(0xD4151314),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = colour.withValues(alpha: isSelected ? 0.95 : 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 1.2 : 0.7,
      );
      // Small tappable info dot (`i`) signalling the badge opens details + photo.
      final infoCenter = Offset(lx + 4.5, ly + text.height / 2);
      canvas.drawCircle(
        infoCenter,
        4.5,
        Paint()
          ..color = colour.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9,
      );
      canvas.drawCircle(infoCenter, 1.3, dotFill);
      text.paint(canvas, Offset(lx + badgeSpace - 1, ly));
      hits.add(WalkCalloutHit(c, rect, anchor));
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
              FilledButton.icon(
                key: const ValueKey('walk-play-story'),
                onPressed: () {
                  player.closeControls();
                  c.playStory();
                },
                icon: const PlanIcon(PlanSymbol.story, size: 18),
                label: Text(s.platePlay),
              ),
              OutlinedButton.icon(
                key: const ValueKey('walk-play-reveal'),
                onPressed: () {
                  player.closeControls();
                  c.play();
                },
                icon: const PlanIcon(PlanSymbol.light, size: 18),
                label: Text(s.plateStartReveal),
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
