import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/explorable_scene.dart';
import '../theme/milion_theme.dart';
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
  static const ink = MilionTheme.night,
      paper = MilionTheme.paper,
      gold = MilionTheme.lightGold;
  final _assets = ExplorerAssets();
  final TransformationController transformation = TransformationController();
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
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
  String _variant = 'Relief';
  String? _selected;
  bool _motion = false, _posed = false, _pins = true, _busy = false;
  double _strength = 1;
  double _motionAmount = 1;
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
        Curves.easeInOutCubic.transform(_move.value),
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
            const SnackBar(
              content: Text('Restoration study could not be loaded.'),
            ),
          );
        }
        if (mounted) setState(() => _busy = false);
        return;
      }
    }
    if (!mounted) return;
    setState(() {
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
      _figures.repeat();
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ink,
    appBar: AppBar(
      backgroundColor: ink,
      foregroundColor: paper,
      titleSpacing: 8,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.scene.title,
            style: MilionTheme.display(27, color: paper),
          ),
          const Text(
            'Explore the painted scene',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              color: Color(0xFFB7C1B3),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Reset view',
          onPressed: resetView,
          icon: const Icon(Icons.center_focus_strong_outlined),
        ),
        PopupMenuButton<String>(
          tooltip: 'Scene options',
          onSelected: (value) {
            if (value == 'studies') {
              _openPage((_) => RestorationStudiesScreen(scene: widget.scene));
            }
            if (value == 'pins') setState(() => _pins = !_pins);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'pins',
              child: Text(
                _pins ? 'Hide detail markers' : 'Show detail markers',
              ),
            ),
            const PopupMenuItem(
              value: 'studies',
              child: Text('Restoration studies'),
            ),
          ],
        ),
      ],
    ),
    body: FutureBuilder<void>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Scene assets unavailable.',
              style: TextStyle(color: paper),
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final chosen = widget.scene.details
            .where((d) => d.id == _selected)
            .firstOrNull;
        return Column(
          children: [
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
                          onInteractionStart: (_) {
                            _move.stop();
                          },
                          onInteractionEnd: (_) =>
                              _moveTo(transformation.value),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: _tapDetail,
                            onDoubleTapDown: (details) {
                              final at = MatrixUtils.transformPoint(
                                transformation.value,
                                details.localPosition,
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
                                    details: widget.scene.details,
                                    selected: _selected,
                                    showDetails:
                                        _pins &&
                                        !_posed &&
                                        _selected == null &&
                                        zoom < 1.8,
                                    fontFamily: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.fontFamily,
                                    zoom: zoom,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Material(
                          color: const Color(0xED253D35),
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            children: [
                              IconButton(
                                tooltip: 'Zoom in',
                                color: paper,
                                onPressed: () => zoomBy(1.5),
                                icon: const Icon(Icons.add),
                              ),
                              AnimatedBuilder(
                                animation: transformation,
                                builder: (_, _) => Text(
                                  '${zoom.toStringAsFixed(1)}×',
                                  style: const TextStyle(
                                    color: paper,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Zoom out',
                                color: paper,
                                onPressed: () => zoomBy(1 / 1.5),
                                icon: const Icon(Icons.remove),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_busy)
                        const Positioned(
                          top: 12,
                          left: 12,
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 68,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chosen?.title ?? 'Choose a detail',
                              style: const TextStyle(
                                color: gold,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              chosen?.description ?? 'Animate the figures, then zoom into their gestures. Drag to explore; use Pose to examine a moment.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: paper,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chip('Overview', _selected == null, resetView),
                          for (final detail in widget.scene.details)
                            _chip(
                              detail.title,
                              _selected == detail.id,
                              () => _focus(detail),
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Tooltip(
                            message: _reduceMotion
                                ? 'Automatic motion is off in accessibility settings. You can still adjust Pose.'
                                : 'Move the figures’ heads, hands and robes',
                            child: FilledButton.icon(
                              onPressed: _reduceMotion ? null : _toggleMotion,
                              icon: Icon(
                                _motion ? Icons.pause : Icons.play_arrow,
                              ),
                              label: Text(
                                _motion ? 'Pause figures' : 'Animate figures',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: gold,
                                foregroundColor: ink,
                                disabledBackgroundColor: const Color(
                                  0xFF33302B,
                                ),
                                disabledForegroundColor: Colors.white38,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _stillFigures,
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Still'),
                          style: TextButton.styleFrom(foregroundColor: paper),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          const Text(
                            'Pose',
                            style: TextStyle(color: paper, fontSize: 11),
                          ),
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _figures,
                              builder: (_, _) => Slider(
                                key: const ValueKey('figure-pose'),
                                value: _figures.value,
                                onChanged: _scrubFigures,
                                activeColor: gold,
                                semanticFormatterCallback: (v) =>
                                    '${(v * 100).round()} percent of gesture',
                              ),
                            ),
                          ),
                          const Text(
                            '6 s loop',
                            style: TextStyle(
                              color: Color(0xFFB7C1B3),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: Row(
                        children: [
                          const Text(
                            'Movement',
                            style: TextStyle(color: paper, fontSize: 11),
                          ),
                          Expanded(
                            child: Slider(
                              key: const ValueKey('figure-intensity'),
                              value: _motionAmount,
                              min: .25,
                              max: 1,
                              activeColor: gold,
                              onChanged: (value) =>
                                  setState(() => _motionAmount = value),
                              semanticFormatterCallback: (v) =>
                                  '${(v * 100).round()} percent movement',
                            ),
                          ),
                          Text(
                            _motionAmount >= .85
                                ? 'Bold'
                                : _motionAmount >= .5
                                ? 'Clear'
                                : 'Gentle',
                            style: const TextStyle(color: gold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (_variant == 'Restored') ...[
                      Row(
                        children: [
                          const Text(
                            'Restoration',
                            style: TextStyle(color: paper, fontSize: 11),
                          ),
                          Expanded(
                            child: Slider(
                              key: const ValueKey('restoration-strength'),
                              value: _strength,
                              onChanged: (value) =>
                                  setState(() => _strength = value),
                              label: '${(_strength * 100).round()}%',
                              activeColor: gold,
                            ),
                          ),
                          Text(
                            '${(_strength * 100).round()}%',
                            style: const TextStyle(color: paper, fontSize: 11),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text(
                          '4K restoration · interpretive · original preserved',
                          style: TextStyle(
                            color: Color(0xFFB7C1B3),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        style: ButtonStyle(
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (s) =>
                                s.contains(WidgetState.selected) ? ink : paper,
                          ),
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (s) => s.contains(WidgetState.selected)
                                ? gold
                                : const Color(0xFF2C3B32),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: 'Original',
                            label: Text('Original'),
                          ),
                          ButtonSegment(value: 'Relief', label: Text('Relief')),
                          ButtonSegment(
                            value: 'Restored',
                            label: Text('Restored'),
                          ),
                        ],
                        selected: {_variant},
                        onSelectionChanged: _busy
                            ? null
                            : (v) => _setVariant(v.first),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _chip(String text, bool selected, VoidCallback action) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: ChoiceChip(
      label: Text(text),
      selected: selected,
      onSelected: (_) => action(),
      selectedColor: gold,
      backgroundColor: const Color(0xFF2C3B32),
      labelStyle: TextStyle(color: selected ? ink : paper, fontSize: 12),
      checkmarkColor: ink,
      side: BorderSide.none,
    ),
  );
}
