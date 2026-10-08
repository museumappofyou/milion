import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/theme.dart';
import '../l10n/strings.dart';
import 'assets.dart';
import 'camera.dart';
import 'controller.dart';
import 'manifest.dart';
import 'sheets.dart';
import 'tilt.dart';
import 'viewport.dart';

/// One owner for a manifest's camera, timeline, sensor and GPU resources.
class PlatePlayer extends StatefulWidget {
  const PlatePlayer({
    super.key,
    required this.manifest,
    this.initialDetail,
    this.gyroEvents,
  });
  final PlateManifest manifest;
  final Detail? initialDetail;
  final GyroStream? gyroEvents;
  @override
  PlatePlayerState createState() => PlatePlayerState();
}

class PlatePlayerState extends State<PlatePlayer>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final controller = PlateController(widget.manifest);
  final assets = PlateAssets();
  late final tilt = PlateTilt(events: widget.gyroEvents);
  final transformation = TransformationController();
  late final Future<void> loading;
  late final Ticker _ticker;
  late final AnimationController _move;
  Duration _lastTick = Duration.zero;
  Size viewport = Size.zero;
  Offset lightPosition = const Offset(.5, .5);
  Matrix4 _from = Matrix4.identity(), _to = Matrix4.identity();
  bool _initialApplied = false, _loaded = false;
  late bool heroShown = widget.initialDetail != null;
  Animation<double>? _route;
  bool _routeSettled = false;
  Size get sourceSize =>
      Size(widget.manifest.width.toDouble(), widget.manifest.height.toDouble());
  double get zoom => transformation.value.getMaxScaleOnAxis();
  Detail? get detail => widget.manifest.details
      .where(
        (d) =>
            d.id ==
            (controller.sample?.beat.detailId ?? controller.selectedDetail),
      )
      .firstOrNull;
  bool get ticking => _ticker.isActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((elapsed) {
      final delta = elapsed - _lastTick;
      _lastTick = elapsed;
      controller.advance(delta.inMicroseconds / 1000000);
    });
    _move =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 360),
        )..addListener(() {
          transformation.value = Matrix4Tween(
            begin: _from,
            end: _to,
          ).transform(Curves.easeInOutCubic.transform(_move.value));
        });
    controller.addListener(_changed);
    controller.selectedDetail = widget.initialDetail?.id;
    loading = assets.load(widget.manifest).then((_) {
      _loaded = true;
      if (mounted) {
        setState(() {});
        _settleHero();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    void applyMotionPreference() {
      controller.setReduced(reduced);
      if (reduced && (tilt.enabled || tilt.normalized != Offset.zero)) {
        tilt.setEnabled(false);
      }
      if (reduced) _move.stop();
    }

    if (!_initialApplied) {
      applyMotionPreference();
    } else if (controller.reduced != reduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) applyMotionPreference();
      });
    }
    final route = ModalRoute.of(context)?.animation;
    if (_route != route) {
      _route?.removeStatusListener(_routeStatus);
      _route = route?..addStatusListener(_routeStatus);
      _routeStatus(route?.status ?? AnimationStatus.completed);
    }
  }

  void _routeStatus(AnimationStatus status) {
    _routeSettled = status == AnimationStatus.completed;
    _settleHero();
  }

  void _settleHero() {
    if (!heroShown || !_loaded || !_initialApplied || !_routeSettled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && heroShown) setState(() => heroShown = false);
    });
  }

  void _changed() {
    if (controller.storyActive && viewport.isEmpty == false) {
      _move.stop();
      transformation.value = plateWindowCamera(
        viewport,
        sourceSize,
        controller.sample!.window,
      );
    }
    if (controller.needsTicker && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else if (!controller.needsTicker && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void sizeChanged(Size value) {
    if (viewport == value) return;
    viewport = value;
    if (!_initialApplied) {
      _initialApplied = true;
      final d = widget.initialDetail;
      transformation.value = d == null
          ? plateCoverCamera(viewport, sourceSize)
          : plateWindowCamera(viewport, sourceSize, d.window);
      _settleHero();
    } else {
      transformation.value = boundPlateCamera(
        viewport,
        sourceSize,
        transformation.value,
      );
    }
  }

  void moveTo(Matrix4 value) {
    _from = transformation.value.clone();
    _to = boundPlateCamera(viewport, sourceSize, value);
    if (controller.reduced) {
      transformation.value = _to;
    } else {
      _move.forward(from: 0);
    }
  }

  void focus(String? id) {
    controller.focus(id);
    final d = detail;
    moveTo(
      d == null
          ? Matrix4.identity()
          : plateWindowCamera(viewport, sourceSize, d.window),
    );
  }

  void zoomBy(double factor) {
    controller.pause();
    final s = (zoom * factor).clamp(1.0, 8.0);
    final p = transformation.toScene(viewport.center(Offset.zero));
    moveTo(
      Matrix4.identity()
        ..translateByDouble(
          viewport.width / 2 - p.dx * s,
          viewport.height / 2 - p.dy * s,
          0,
          1,
        )
        ..scaleByDouble(s, s, 1, 1),
    );
  }

  void original() {
    controller.original();
    tilt.setEnabled(false);
  }

  void beginExplore() {
    _move.stop();
    controller.explore();
    tilt.recenter();
  }

  Offset get visibleTilt {
    if (controller.reduced || controller.peekOriginal) return Offset.zero;
    if (controller.playing && !tilt.enabled) {
      return Offset(
        math.sin(controller.seconds * .65) * .5,
        math.sin(controller.seconds * .4) * .25,
      );
    }
    return tilt.normalized;
  }

  void drag(Offset point) {
    if (controller.reduced) {
      if (controller.layer != PlateLayerId.reconstruction) return;
    }
    final frame = plateFrame(viewport, sourceSize);
    final p = transformation.toScene(point);
    final uv = Offset(
      ((p.dx - frame.left) / frame.width).clamp(0, 1),
      ((p.dy - frame.top) / frame.height).clamp(0, 1),
    );
    if (controller.layer == PlateLayerId.reconstruction) {
      controller.setWipe(uv.dx);
    } else if ([
      PlateLight.raking,
      PlateLight.candle,
    ].contains(controller.visibleLight)) {
      setState(() => lightPosition = uv);
    } else {
      tilt.drag(uv * 2 - const Offset(1, 1));
    }
  }

  Future<void> controls(PlatePanel panel) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Theme(
        data: DesignTheme.lamp,
        child: PlateSheet(player: this, panel: panel),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.resume();
      tilt.resume();
    } else {
      controller.suspend();
      tilt.suspend();
      _move.stop();
    }
  }

  @override
  void dispose() {
    _route?.removeStatusListener(_routeStatus);
    WidgetsBinding.instance.removeObserver(this);
    controller.removeListener(_changed);
    _ticker.dispose();
    _move.dispose();
    transformation.dispose();
    tilt.dispose();
    controller.dispose();
    assets.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: DesignTheme.lamp,
    child: Builder(
      builder: (context) {
        final s = context.l10n;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.manifest.title.inLanguage(context.language)),
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
                          message: s.studyUnavailable,
                        ),
                      );
                    }
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Stack(
                        children: [
                          if (heroShown)
                            PlateViewport(player: this, loading: true),
                          Center(
                            child: Semantics(
                              label: s.plateLoading,
                              child: const TesseraLoader(),
                            ),
                          ),
                        ],
                      );
                    }
                    return PlateViewport(player: this);
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
                        (PlatePanel.story, PlanSymbol.story, s.plateStory),
                        (PlatePanel.light, PlanSymbol.light, s.light),
                        (PlatePanel.layers, PlanSymbol.layers, s.plateLayers),
                      ])
                        TextButton.icon(
                          key: ValueKey('plate-${item.$1.name}'),
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
