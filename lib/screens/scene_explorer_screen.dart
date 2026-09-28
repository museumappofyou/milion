import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/explorable_scene.dart';
import '../design/tokens.dart';
import '../design/theme.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/plan_icon.dart';
import '../content/models.dart' show Honesty;
import '../l10n/strings.dart';
import '../l10n/scene_strings.dart';
import '../services/explorer_assets.dart';
import '../services/figure_rig.dart';
import '../widgets/interactive_relief_surface.dart';
import 'restoration_studies_screen.dart';

class SceneExplorerScreen extends StatefulWidget {
  const SceneExplorerScreen({
    super.key,
    required this.scene,
    this.initialFocus = 'Overview',
  });
  final ExplorableScene scene;
  final String initialFocus;

  @override
  State<SceneExplorerScreen> createState() => SceneExplorerScreenState();
}

class SceneExplorerScreenState extends State<SceneExplorerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const ink = Pigment.lamp;
  final _assets = ExplorerAssets();
  final TransformationController transformation = TransformationController();
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: MotionToken.durations[MeasureMotion.dig],
  )..addListener(_moveTick);
  late final AnimationController _figures = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final Future<void> _loading = _load();
  late ui.Image _original, _relief;
  ui.Image? _restored;
  late FigureRig _rig;
  Matrix4Tween? _matrixTween;
  String _variant = 'Original';
  String? _selected;
  bool _motion = false, _posed = false, _pins = true, _busy = false;
  double _strength = 1;
  double _motionAmount = .25;
  Size _viewport = Size.zero;
  bool _initialApplied = false;

  double get zoom => transformation.value.getMaxScaleOnAxis();
  double get figurePose => _figures.value;
  double get motionAmount => _motionAmount;
  double get restorationAmount => _strength;
  bool get isMotionPlaying => _motion;
  String get variant => _variant;
  String? get selectedDetail => _selected;
  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _load() async {
    final results = await Future.wait<Object>([
      _assets.image(widget.scene.original),
      _assets.image(widget.scene.relief),
      _assets.figures(widget.scene.figures),
    ]);
    _original = results[0] as ui.Image;
    _relief = results[1] as ui.Image;
    _rig = results[2] as FigureRig;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion && _motion) {
      _figures.stop();
      _motion = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _move.stop();
      _figures.stop();
      if (mounted) setState(() => _motion = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _move.dispose();
    _figures.dispose();
    transformation.dispose();
    _assets.dispose();
    super.dispose();
  }

  Rect get _frame =>
      InteractiveReliefSurface.fitFrame(_viewport, widget.scene.size);

  Matrix4 _bounded(Matrix4 value) {
    if (_viewport.isEmpty) return Matrix4.identity();
    final s = value.getMaxScaleOnAxis().clamp(1.0, 8.0);
    final t = value.getTranslation();
    final f = _frame;
    final x = f.width * s <= _viewport.width
        ? _viewport.width / 2 - f.center.dx * s
        : t.x.clamp(_viewport.width - f.right * s, -f.left * s);
    final y = f.height * s <= _viewport.height
        ? _viewport.height / 2 - f.center.dy * s
        : t.y.clamp(_viewport.height - f.bottom * s, -f.top * s);
    return Matrix4.identity()
      ..translateByDouble(x, y, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  void _moveTick() {
    if (_matrixTween != null) {
      transformation.value = _matrixTween!.transform(
        MotionToken.curves[MeasureMotion.dig]!.transform(_move.value),
      );
    }
  }

  void _moveTo(Matrix4 target) {
    _move.stop();
    target = _bounded(target);
    if (_reduceMotion) {
      transformation.value = target;
      return;
    }
    _matrixTween = Matrix4Tween(
      begin: transformation.value.clone(),
      end: target,
    );
    _move.forward(from: 0);
  }

  void zoomBy(double factor, [Offset? anchor]) {
    _move.stop();
    final at = anchor ?? _viewport.center(Offset.zero);
    final point = transformation.toScene(at);
    final target = (zoom * factor).clamp(1.0, 8.0);
    _moveTo(
      Matrix4.identity()
        ..translateByDouble(
          at.dx - point.dx * target,
          at.dy - point.dy * target,
          0,
          1,
        )
        ..scaleByDouble(target, target, 1, 1),
    );
  }

  void resetView() {
    setState(() => _selected = null);
    _moveTo(Matrix4.identity());
  }

  void _focus(SceneDetail detail) {
    setState(() => _selected = detail.id);
    final frame = _frame, r = detail.window;
    final crop = Rect.fromLTRB(
      frame.left + r.left * frame.width,
      frame.top + r.top * frame.height,
      frame.left + r.right * frame.width,
      frame.top + r.bottom * frame.height,
    );
    final s = math
        .min(
          (_viewport.width - 36) / crop.width,
          (_viewport.height - 36) / crop.height,
        )
        .clamp(1.0, 8.0);
    _moveTo(
      Matrix4.identity()
        ..translateByDouble(
          _viewport.width / 2 - crop.center.dx * s,
          _viewport.height / 2 - crop.center.dy * s,
          0,
          1,
        )
        ..scaleByDouble(s, s, 1, 1),
    );
  }

  Future<void> _setVariant(String value) async {
    _move.stop();
    if (value == 'Restored' && _restored == null) {
      setState(() => _busy = true);
      try {
        final image = await _assets.image(widget.scene.restored);
        if (!mounted) return;
        _restored = image;
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.studyUnavailable)),
          );
        }
        if (mounted) setState(() => _busy = false);
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      if (value == 'Original') {
        _figures.stop();
        _figures.value = 0;
        _motion = false;
        _posed = false;
      }
      _variant = value;
      _busy = false;
    });
  }

  void _toggleMotion() {
    if (_reduceMotion) return;
    setState(() {
      _motion = !_motion;
      _posed = true;
    });
    if (_motion) {
      _figures.forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _motion = false);
      });
    } else {
      _figures.stop();
    }
  }

  void _stillFigures() {
    _figures.stop();
    _figures.value = 0;
    setState(() {
      _motion = false;
      _posed = false;
    });
  }

  void _scrubFigures(double value) {
    _figures.stop();
    _figures.value = value;
    setState(() {
      _motion = false;
      _posed = true;
    });
  }

  void _tapDetail(TapUpDetails tap) {
    if (!_pins || _posed || _selected != null || zoom >= 1.8) return;
    for (final detail in widget.scene.details.reversed) {
      final p = Offset(
        _frame.left + detail.point.dx * _frame.width,
        _frame.top + detail.point.dy * _frame.height,
      );
      if ((p - tap.localPosition).distance < 25 / zoom) {
        _focus(detail);
        return;
      }
    }
  }

  Future<void> _openPage(WidgetBuilder builder) async {
    _move.stop();
    _figures.stop();
    setState(() => _motion = false);
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: DesignTheme.lamp,
    child: Builder(builder: _buildLamp),
  );

  Widget _buildLamp(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      backgroundColor: ink,
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(24) + 40,
        title: Text(sceneTitle(context, widget.scene), maxLines: 2),
        actions: [
          IconButton(
            tooltip: s.resetView,
            onPressed: resetView,
            icon: const Icon(Icons.center_focus_strong_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: s.sceneOptions,
            onSelected: (v) {
              if (v == 'studies') {
                _openPage((_) => RestorationStudiesScreen(scene: widget.scene));
              }
              if (v == 'pins') setState(() => _pins = !_pins);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'pins',
                child: Text(_pins ? s.hideMarkers : s.showMarkers),
              ),
              PopupMenuItem(value: 'studies', child: Text(s.studies)),
            ],
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: ContentState(error: true, title: s.sceneUnavailable),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: TesseraLoader());
          }
          final chosen = widget.scene.details
              .where((d) => d.id == _selected)
              .firstOrNull;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: HonestyLabel(
                    _posed
                        ? Honesty.IMAGINED
                        : _variant == 'Original'
                        ? Honesty.ORIGINAL
                        : _variant == 'Relief'
                        ? Honesty.DEPTH
                        : Honesty.RECONSTRUCTION,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    if (_viewport != size) {
                      _viewport = size;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        if (!_initialApplied) {
                          _initialApplied = true;
                          final detail = widget.scene.details
                              .where(
                                (d) =>
                                    d.title.toLowerCase() ==
                                    widget.initialFocus.toLowerCase(),
                              )
                              .firstOrNull;
                          if (detail != null) {
                            _focus(detail);
                            return;
                          }
                        }
                        if (chosen != null) {
                          _focus(chosen);
                        } else {
                          transformation.value = _bounded(transformation.value);
                        }
                      });
                    }
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: InteractiveViewer(
                            key: const ValueKey('scene-interactive-viewer'),
                            transformationController: transformation,
                            minScale: 1,
                            maxScale: 8,
                            trackpadScrollCausesScale: true,
                            onInteractionStart: (_) => _move.stop(),
                            onInteractionEnd: (_) =>
                                _moveTo(transformation.value),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: _tapDetail,
                              onDoubleTapDown: (d) {
                                final at = MatrixUtils.transformPoint(
                                  transformation.value,
                                  d.localPosition,
                                );
                                zoomBy(zoom > 4 ? 1 / zoom : 2, at);
                              },
                              onDoubleTap: () {},
                              child: RepaintBoundary(
                                key: const ValueKey('figure-canvas'),
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([
                                    transformation,
                                    _figures,
                                  ]),
                                  builder: (context, _) => CustomPaint(
                                    size: size,
                                    painter: InteractiveReliefSurface(
                                      texture: _variant == 'Relief'
                                          ? _relief
                                          : _original,
                                      study: _variant == 'Restored'
                                          ? _restored
                                          : null,
                                      studyAmount: _strength,
                                      sourceSize: widget.scene.size,
                                      rig: _rig,
                                      frame: _frame,
                                      phase: _figures.value,
                                      motionAmount: _motionAmount,
                                      posed: _posed,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Material(
                            color: MeasureColors.lamp.poche,
                            shape: const RoundedRectangleBorder(
                              borderRadius: Space.radius,
                            ),
                            child: Column(
                              children: [
                                IconButton(
                                  tooltip: s.zoomIn,
                                  onPressed: () => zoomBy(1.5),
                                  icon: const Icon(Icons.add),
                                ),
                                AnimatedBuilder(
                                  animation: transformation,
                                  builder: (_, _) => Text(
                                    '${zoom.toStringAsFixed(1)}×',
                                    style: TypeRole.measurement,
                                  ),
                                ),
                                IconButton(
                                  tooltip: s.zoomOut,
                                  onPressed: () => zoomBy(1 / 1.5),
                                  icon: const Icon(Icons.remove),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (chosen != null && _pins && !_posed)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: transformation,
                                builder: (context, _) => CustomPaint(
                                  painter: _MarginCallout(
                                    MatrixUtils.transformPoint(
                                      transformation.value,
                                      Offset(
                                        _frame.left +
                                            _frame.width * chosen.point.dx,
                                        _frame.top +
                                            _frame.height * chosen.point.dy,
                                      ),
                                    ),
                                    detailTitle(context, chosen.id),
                                    MediaQuery.textScalerOf(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_busy)
                          const Positioned(
                            top: 12,
                            left: 12,
                            child: TesseraLoader(),
                          ),
                      ],
                    );
                  },
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .46,
                ),
                child: SingleChildScrollView(
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            key: ValueKey(_selected),
                            initialValue: _selected ?? '',
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: s.chooseDetail,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: '',
                                child: Text(s.overview),
                              ),
                              for (final d in widget.scene.details)
                                DropdownMenuItem(
                                  value: d.id,
                                  child: Text(detailTitle(context, d.id)),
                                ),
                            ],
                            onChanged: (id) {
                              if (id == null || id.isEmpty) {
                                resetView();
                              } else {
                                _focus(
                                  widget.scene.details.firstWhere(
                                    (d) => d.id == id,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            chosen == null
                                ? s.detailHint
                                : detailBody(
                                    context,
                                    widget.scene.id,
                                    chosen.id,
                                  ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final (value, label) in [
                                ('Original', s.original),
                                ('Relief', s.depth),
                                ('Restored', s.reconstruction),
                              ])
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _setVariant(value),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _variant == value
                                        ? MeasureColors.lamp.poche
                                        : null,
                                  ),
                                  child: Text(label),
                                ),
                            ],
                          ),
                          if (_variant == 'Restored') ...[
                            Text(
                              s.restorationNotice,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Slider(
                              key: const ValueKey('restoration-strength'),
                              value: _strength,
                              semanticFormatterCallback: (v) =>
                                  s.movementPercent('${(v * 100).round()}'),
                              onChanged: (v) => setState(() => _strength = v),
                            ),
                          ],
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(s.gestureStudy),
                            leading: const PlanIcon(PlanSymbol.story),
                            children: [
                              const HonestyLabel(Honesty.IMAGINED),
                              const SizedBox(height: 8),
                              Text(
                                _reduceMotion
                                    ? s.reducedMotionHint
                                    : s.gestureBody,
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: _reduceMotion
                                        ? null
                                        : _toggleMotion,
                                    child: Text(
                                      _motion ? s.pauseGesture : s.playGesture,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _stillFigures,
                                    child: Text(s.still),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(s.pose),
                                  Expanded(
                                    child: AnimatedBuilder(
                                      animation: _figures,
                                      builder: (_, _) => Slider(
                                        key: const ValueKey('figure-pose'),
                                        value: _figures.value,
                                        onChanged: _scrubFigures,
                                        semanticFormatterCallback: (v) =>
                                            s.gesturePercent(
                                              '${(v * 100).round()}',
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(s.movement),
                                  Expanded(
                                    child: Slider(
                                      key: const ValueKey('figure-intensity'),
                                      value: _motionAmount,
                                      min: .1,
                                      max: .35,
                                      onChanged: (v) =>
                                          setState(() => _motionAmount = v),
                                      semanticFormatterCallback: (v) =>
                                          s.movementPercent(
                                            '${(v * 100).round()}',
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                s.singleGesture,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MarginCallout extends CustomPainter {
  _MarginCallout(this.anchor, this.caption, this.scaler);
  final Offset anchor;
  final String caption;
  final TextScaler scaler;
  @override
  void paint(Canvas canvas, Size size) {
    final text = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      text: TextSpan(
        text: caption,
        style: TypeRole.measurement.copyWith(color: Pigment.marble),
      ),
    )..layout(maxWidth: size.width - 32);
    final top = size.height - text.height - 16;
    canvas.drawRect(
      Rect.fromLTWH(0, top - 8, size.width, size.height - top + 8),
      Paint()..color = Pigment.lamp,
    );
    canvas.drawPath(
      Path()
        ..moveTo(
          anchor.dx.clamp(8, size.width - 8),
          anchor.dy.clamp(0, top - 16),
        )
        ..lineTo(size.width - 16, top - 8)
        ..lineTo(16, top - 8)
        ..lineTo(16, top),
      Paint()
        ..color = Pigment.marble
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    text.paint(canvas, Offset(16, top + 4));
    text.dispose();
  }

  @override
  bool shouldRepaint(_MarginCallout old) =>
      anchor != old.anchor || caption != old.caption || scaler != old.scaler;
}
