import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import 'camera.dart';
import 'controller.dart';
import 'model.dart';
import 'renderer.dart';
import 'sheets.dart';
import 'study.dart';
import 'style.dart';

typedef LoadBytes = Future<ByteData> Function(String asset);

/// One owner for a study's model, camera, timeline and renderer: orbit with
/// one finger, pinch and move with two, double-tap for Choisy's view.
class SpacePlayer extends StatefulWidget {
  const SpacePlayer({super.key, required this.study, this.loadBytes});
  final SpaceStudy study;

  /// Test seam; the app reads the bundled model.
  final LoadBytes? loadBytes;
  @override
  SpacePlayerState createState() => SpacePlayerState();
}

class SpacePlayerState extends State<SpacePlayer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  SpaceController? controller;
  SpaceRenderer? renderer;
  late final Future<void> loading;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  /// The projector of the last painted frame (gestures and the handle).
  SpaceProjector? projector;
  SpaceView? _gestureStart;
  int loadMicros = 0;
  bool _night = false;
  bool get ticking => _ticker.isActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((elapsed) {
      final delta = elapsed - _lastTick;
      _lastTick = elapsed;
      controller?.advance(delta.inMicroseconds / 1000000);
    });
    loading = _load();
  }

  Future<void> _load() async {
    final watch = Stopwatch()..start();
    final bytes = await (widget.loadBytes ?? rootBundle.load)(
      widget.study.model,
    );
    final model = SpaceModel.fromGlb(bytes);
    widget.study.checkModel(model);
    loadMicros = watch.elapsedMicroseconds;
    if (!mounted) return;
    final c = SpaceController(widget.study, model)
      ..setReduced(MediaQuery.disableAnimationsOf(context))
      ..addListener(_changed);
    setState(() {
      controller = c;
      renderer = SpaceRenderer(model);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    final c = controller;
    if (c != null && c.reduced != reduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) c.setReduced(reduced);
      });
    }
  }

  void _changed() {
    final c = controller!;
    // Night reads under the lamp theme; the chrome follows the style.
    if ((c.style == SpaceStyle.night) != _night) {
      setState(() => _night = c.style == SpaceStyle.night);
    }
    if (c.needsTicker && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else if (!c.needsTicker && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _scaleStart(ScaleStartDetails d) => _gestureStart = controller!.view;

  void _scaleUpdate(ScaleUpdateDetails d) {
    final c = controller!, start = _gestureStart, p = projector;
    if (start == null || p == null) return;
    if (d.pointerCount < 2) {
      c.setView(
        c.view.orbit(-d.focalPointDelta.dx * .008, d.focalPointDelta.dy * .008),
      );
    } else {
      final zoomed = c.view.copyWith(zoom: start.zoom * d.scale);
      c.setView(
        SpaceProjector(zoomed, p.size, c.model.bounds).pan(d.focalPointDelta),
      );
    }
  }

  /// The sheet carries the style's own surface and text, whatever the app's.
  Future<void> controls(SpacePanel panel) async {
    final theme = _night ? DesignTheme.lamp : DesignTheme.marble;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (_) => Theme(
        data: theme,
        child: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!,
          child: SpaceSheet(player: this, panel: panel),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = controller;
    if (c == null) return;
    state == AppLifecycleState.resumed ? c.resume() : c.suspend();
  }

  @override
  void didUpdateWidget(SpacePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      oldWidget.study.id == widget.study.id,
      'Key each SpacePlayer by its study id (ValueKey(study.id)).',
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    controller?.removeListener(_changed);
    controller?.dispose();
    renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _night ? DesignTheme.lamp : DesignTheme.marble,
      child: Builder(
        builder: (context) {
          final s = context.l10n;
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.study.title.inLanguage(context.language)),
            ),
            body: Column(
              children: [
                Expanded(
                  child: FutureBuilder<void>(
                    future: loading,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: ContentState(
                            error: true,
                            title: s.sceneUnavailable,
                            message: s.spaceUnavailable,
                          ),
                        );
                      }
                      if (controller == null) {
                        return Center(
                          child: Semantics(
                            label: s.spaceLoading,
                            child: const TesseraLoader(),
                          ),
                        );
                      }
                      return SpaceViewport(player: this);
                    },
                  ),
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
                          (
                            SpacePanel.assemble,
                            PlanSymbol.assembly,
                            s.spaceAssemble,
                          ),
                          (
                            SpacePanel.section,
                            PlanSymbol.section,
                            s.spaceSection,
                          ),
                          (SpacePanel.style, PlanSymbol.light, s.spaceStyle),
                        ])
                          TextButton.icon(
                            key: ValueKey('space-${item.$1.name}'),
                            onPressed: controller == null
                                ? null
                                : () => controls(item.$1),
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

class SpaceViewport extends StatelessWidget {
  const SpaceViewport({super.key, required this.player});
  final SpacePlayerState player;
  @override
  Widget build(BuildContext context) {
    final c = player.controller!, s = context.l10n;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final lang = context.language, step = c.currentStep;
        final caption = c.caption?.inLanguage(lang);
        final ground = Theme.of(context).scaffoldBackgroundColor
            .withValues(alpha: .94);
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final p = SpaceProjector(c.visibleView, size, c.model.bounds);
            return Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    label:
                        '${c.study.title.inLanguage(lang)}. '
                        '${c.study.description.inLanguage(lang)}',
                    customSemanticsActions: {
                      CustomSemanticsAction(label: s.plateNext): () =>
                          c.step(1),
                      CustomSemanticsAction(label: s.platePrevious): () =>
                          c.step(-1),
                      CustomSemanticsAction(label: s.spaceChoisy): c.choisy,
                    },
                    child: GestureDetector(
                      key: const ValueKey('space-viewport'),
                      onScaleStart: player._scaleStart,
                      onScaleUpdate: player._scaleUpdate,
                      onDoubleTap: c.choisy,
                      child: RepaintBoundary(
                        key: const ValueKey('space-paint'),
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: SpacePainter(
                            player.renderer!,
                            c,
                            (projector) => player.projector = projector,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (c.section) ...sectionHandle(context, c, p),
                // Label and year share one wrapping row, so neither covers
                // the other at 200% text.
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(color: ground),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: HonestyLabel(
                            c.honesty,
                            key: const ValueKey('space-honesty'),
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(color: ground),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            c.study.epochs[c.visibleEpoch].label.inLanguage(
                              lang,
                            ),
                            key: const ValueKey('space-epoch'),
                            style: TypeRole.measurement,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (caption != null)
                  Positioned(
                    bottom: 8,
                    left: 12,
                    right: 12,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: size.height * .3),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: ground),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Semantics(
                            liveRegion: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (step != null &&
                                    !(c.reveal && c.storyActive))
                                  Text(
                                    step.label.inLanguage(lang),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                Text(
                                  caption,
                                  key: const ValueKey('space-caption'),
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
      },
    );
  }

  /// The section plane's outline and a handle that drags it along its axis.
  List<Widget> sectionHandle(
    BuildContext context,
    SpaceController c,
    SpaceProjector p,
  ) {
    final b = c.model.bounds, axis = c.sectionAxis;
    final centre = [b.centerX, b.centerY, b.centerZ]..[axis] = c.sectionOffset;
    final at = p.toScreen(centre[0], centre[1], centre[2]);
    final dir = p.screenDirection(
      axis == 0 ? 1 : 0,
      axis == 1 ? 1 : 0,
      axis == 2 ? 1 : 0,
    );
    final colour = MeasureColors.of(context).accent;
    final outline = sectionOutline(p, b, SpaceSection(axis, c.sectionOffset));
    return [
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(painter: _OutlinePainter(outline, colour)),
        ),
      ),
      if (p.size.contains(at))
        Positioned(
          left: at.dx - 22,
          top: at.dy - 22,
          child: Semantics(
            label: context.l10n.spaceSectionHandle,
            child: GestureDetector(
              key: const ValueKey('space-section-handle'),
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) {
                final length = dir.distanceSquared;
                if (length < 1e-6) return;
                c.setSectionOffset(
                  c.sectionOffset +
                      (d.delta.dx * dir.dx + d.delta.dy * dir.dy) / length,
                );
              },
              child: SizedBox(
                width: 44,
                height: 44,
                child: CustomPaint(painter: _HandlePainter(colour, dir)),
              ),
            ),
          ),
        ),
    ];
  }
}

/// Repaints only when the controller changes; the renderer does the work.
class SpacePainter extends CustomPainter {
  SpacePainter(this.renderer, this.controller, this.onProjector)
    : super(repaint: controller);
  final SpaceRenderer renderer;
  final SpaceController controller;
  final ValueChanged<SpaceProjector> onProjector;
  @override
  void paint(Canvas canvas, Size size) =>
      onProjector(renderer.paint(canvas, size, controller.scene()));
  @override
  bool shouldRepaint(SpacePainter old) =>
      old.renderer != renderer || old.controller != controller;
}

class _OutlinePainter extends CustomPainter {
  _OutlinePainter(this.corners, this.colour);
  final List<Offset> corners;
  final Color colour;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colour.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < corners.length; i++) {
      final a = corners[i], b = corners[(i + 1) % corners.length];
      // Dashed hairline: a plane is a construction line, not an edge.
      final n = math.max(1, ((b - a).distance / 6).floor());
      for (var k = 0; k < n; k += 2) {
        canvas.drawLine(
          Offset.lerp(a, b, k / n)!,
          Offset.lerp(a, b, math.min(k + 1, n) / n)!,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OutlinePainter old) =>
      old.colour != colour || !_same(old.corners, corners);
  static bool _same(List<Offset> a, List<Offset> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);
}

class _HandlePainter extends CustomPainter {
  _HandlePainter(this.colour, this.direction);
  final Color colour;
  final Offset direction;
  @override
  void paint(Canvas canvas, Size size) {
    // An open ring with arrowheads along the plane's normal: a handle, not
    // a cut face (poché is filled).
    final c = size.center(Offset.zero);
    final line = Paint()
      ..color = colour
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, 7, line);
    if (direction.distance < 1e-6) return;
    final d = direction / direction.distance, n = Offset(-d.dy, d.dx);
    for (final sign in [-1.0, 1.0]) {
      final tip = c + d * (19 * sign), back = tip - d * (5 * sign);
      canvas
        ..drawLine(c + d * (9 * sign), tip, line)
        ..drawPath(
          Path()
            ..moveTo((back + n * 4).dx, (back + n * 4).dy)
            ..lineTo(tip.dx, tip.dy)
            ..lineTo((back - n * 4).dx, (back - n * 4).dy),
          line,
        );
    }
  }

  @override
  bool shouldRepaint(_HandlePainter old) =>
      old.colour != colour || old.direction != direction;
}
