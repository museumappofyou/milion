import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';

import '../city/city_tab.dart' show categoryLabel;
import '../content/geography.dart';
import '../content/models.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/navigation.dart';
import 'atlas_assets.dart';
import 'atlas_controls.dart';
import 'atlas_controller.dart';
import 'atlas_markers.dart';
import 'atlas_overlay.dart';
import 'atlas_style.dart';
import 'atlas_sheets.dart';
import 'atlas_tiles.dart';
import '../space/snapshot_builder.dart';
import 'atlas_view.dart';
import 'historic_shapes.dart';
import 'historic.dart';

/// A year as the Atlas prints it: "668 BC", "537", "Today".
String atlasYearLabel(BuildContext context, int year) {
  final s = context.l10n;
  if (year >= atlasYears.last) return s.atlasEraToday;
  return year < 0 ? s.atlasYearBc('${1 - year}') : '$year';
}

String atlasEraCaption(BuildContext context, int stop) {
  final s = context.l10n;
  return switch (atlasYears[stop]) {
    330 => s.atlasEra330,
    537 => s.atlasEra537,
    1200 => s.atlasEra1200,
    1453 => s.atlasEra1453,
    1560 => s.atlasEra1560,
    1900 => s.atlasEra1900,
    _ => s.atlasEraToday,
  };
}

/// The map half of the City tab (P10): OSM tiles in three historical
/// manners, the hand-authored historic layers, Milion rings and the same
/// places as the list.
class AtlasMap extends StatefulWidget {
  const AtlasMap({
    super.key,
    required this.assets,
    required this.controller,
    required this.places,
  });
  final AtlasAssets assets;
  final AtlasController controller;
  final List<Place> places;

  @override
  State<AtlasMap> createState() => _AtlasMapState();
}

class _AtlasMapState extends State<AtlasMap> with TickerProviderStateMixin {
  late TileCache _tiles;
  late final HistoricGeometryCache _geometry = HistoricGeometryCache(
    widget.assets.historic,
    data: widget.assets.data,
  );
  late final AnimationController _year = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _camera = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final AnimationController _fling = AnimationController.unbounded(
    vsync: this,
  );
  Size _size = Size.zero;
  String? _selected;
  bool _playing = false;
  int _playToken = 0;

  AtlasController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _tiles = _makeCache(2.6);
    c.addListener(_onSettle);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prefetch();
    });
  }

  int _prefetchedAt = -1;

  void _onSettle() {
    // A fling stopped by a new touch settles too; wait for that gesture.
    if (c.settled != _prefetchedAt && _gestureView == null) _prefetch();
  }

  /// At rest, render every manner's tiles for this view in idle frames, so
  /// the slider's crossfades find them ready.
  void _prefetch() {
    if (_size.isEmpty) return;
    _prefetchedAt = c.settled;
    _tiles.prefetch([
      for (final m in AtlasManner.values) ...visibleTiles(c.view, _size, m),
    ]);
  }

  TileCache _makeCache(double dpr) => TileCache(
    TileRenderer(widget.assets.index),
    resolution: (tileLogicalPx * dpr * .85).round().clamp(256, 640),
    capacity: 72,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final res = (tileLogicalPx * dpr * .85).round().clamp(256, 640);
    if (res != _tiles.resolution) {
      _tiles.dispose();
      _tiles = _makeCache(dpr);
    }
  }

  @override
  void dispose() {
    c.removeListener(_onSettle);
    _playToken++;
    _year.dispose();
    _camera.dispose();
    _fling.dispose();
    _tiles.dispose();
    super.dispose();
  }

  // --- camera -----------------------------------------------------------------

  Rect get _bounds => widget.assets.data.bounds;

  void _setView(AtlasView v) => c.view = v.clampTo(_bounds);

  void _animateView(AtlasView target) {
    _fling.stop();
    _camera.stop();
    final from = c.view;
    final curve = CurvedAnimation(parent: _camera, curve: Curves.easeInOut);
    void listener() => _setView(AtlasView.lerp(from, target, curve.value));
    _camera
      ..value = 0
      ..addListener(listener);
    _camera.forward().orCancel.catchError((_) {}).whenComplete(() {
      _camera.removeListener(listener);
      curve.dispose();
      c.settle();
    });
  }

  AtlasView? _gestureView;
  double _lastScale = 1, _lastRotation = 0;
  bool _rotating = false;
  int _pointers = 0;

  void _onScaleStart(ScaleStartDetails d) {
    _tiles.holdPrefetch = true;
    _fling.stop();
    _camera.stop();
    _gestureView = c.view;
    _lastScale = 1;
    _lastRotation = 0;
    _rotating = false;
    _pointers = d.pointerCount;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_gestureView == null) return;
    _pointers = math.max(_pointers, d.pointerCount);
    var v = c.view.panBy(d.focalPointDelta);
    if (d.pointerCount >= 2) {
      // Rotation only once the twist is deliberate, so pinches stay north up.
      if (!_rotating && d.rotation.abs() > .26) {
        _rotating = true;
        _lastRotation = d.rotation;
      }
      final turn = _rotating ? d.rotation - _lastRotation : 0.0;
      _lastRotation = d.rotation;
      v = v.transformAround(
        d.localFocalPoint,
        _size,
        factor: d.scale / _lastScale,
        turn: turn,
      );
      _lastScale = d.scale;
    }
    _setView(v);
  }

  void _onScaleEnd(ScaleEndDetails d) {
    _gestureView = null;
    final velocity = d.velocity.pixelsPerSecond;
    final speed = velocity.distance;
    if (_pointers == 1 && speed > 250) {
      final dir = velocity / speed;
      final sim = FrictionSimulation(.08, 0, speed);
      var last = 0.0;
      void tick() {
        final x = _fling.value;
        _setView(c.view.panBy(dir * (x - last)));
        last = x;
      }

      _fling.addListener(tick);
      _fling.animateWith(sim).whenCompleteOrCancel(() {
        _fling.removeListener(tick);
        c.settle();
      });
    } else {
      c.settle();
    }
  }

  void _zoom(double factor) => _animateView(
    c.view.transformAround(_size.center(Offset.zero), _size, factor: factor),
  );

  // --- markers ----------------------------------------------------------------

  void _onTapUp(TapUpDetails d) {
    final markers = clusterPlaces(widget.places, c.view);
    final hit = markerAt(markers, c.view, _size, d.localPosition);
    if (hit != null) _activate(hit);
  }

  void _activate(AtlasMarker m) {
    if (m.isCluster) {
      _animateView(zoomToMarker(m, c.view, _size));
      return;
    }
    _openSheet(m.places.single);
  }

  Future<void> _openSheet(Place place) async {
    setState(() => _selected = place.id);
    final open = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          AtlasPlaceSheet(place: place, assets: widget.assets, controller: c),
    );
    if (!mounted) return;
    setState(() => _selected = null);
    if (open == true) await openPlace(context, place);
  }

  // --- time -------------------------------------------------------------------

  Future<void> _goToStop(int stop, {bool user = true}) {
    if (user) {
      _playToken++;
      if (_playing) setState(() => _playing = false);
    }
    c.stop = stop;
    final from = c.year, to = atlasYears[stop].toDouble();
    final reduce = MediaQuery.of(context).disableAnimations;
    _year.stop();
    if (reduce || from == to) {
      c.year = to;
      c.settle();
      return Future.value();
    }
    final curve = CurvedAnimation(parent: _year, curve: Curves.easeInOutCubic);
    void listener() => c.year = from + (to - from) * curve.value;
    _year
      ..value = 0
      ..addListener(listener);
    _year.duration = Duration(
      milliseconds: (700 + 500 * math.min(1, (to - from).abs() / 700)).round(),
    );
    return _year.forward().orCancel.catchError((_) {}).whenComplete(() {
      _year.removeListener(listener);
      curve.dispose();
      c.settle();
    });
  }

  /// The time-lapse: every stop from 330 to today, pausing on each.
  Future<void> _play() async {
    if (_playing) {
      _playToken++;
      setState(() => _playing = false);
      return;
    }
    final token = ++_playToken;
    setState(() => _playing = true);
    for (var i = 0; i < atlasYears.length; i++) {
      if (token != _playToken || !mounted) return;
      await _goToStop(i, user: false);
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }
    if (mounted && token == _playToken) setState(() => _playing = false);
  }

  // --- location ---------------------------------------------------------------

  bool _locating = false;

  Future<void> _fromMe() async {
    final s = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (c.me != null) {
      c.locate(null);
      return;
    }
    if (_locating) return;
    void say(String m) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        say(s.atlasLocationOff);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        say(s.atlasLocationDenied);
        return;
      }
      say(s.atlasLocating);
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      c.locate(Coordinates(p.latitude, p.longitude));
      final me = c.me!;
      if (_bounds.contains(me)) {
        _animateView(c.view.copyWith(center: me));
      }
    } on Object {
      say(s.atlasLocationFailed);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // --- build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final colors = MeasureColors.of(context);
    final scene = OverlayScene(
      assets: widget.assets,
      places: widget.places,
      selected: _selected,
      language: context.language,
      colors: colors,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                onTapUp: _onTapUp,
                // Rebuilt for what it announces: the year, the toggles, and
                // (only while a screen reader listens) where the markers
                // settled. A pan's start and end otherwise cost a frame.
                child: SnapshotBuilder(
                  listenable: c,
                  snapshot: () => (
                    c.stop,
                    c.below,
                    c.rings,
                    c.me,
                    SemanticsBinding.instance.semanticsEnabled ? c.settled : 0,
                  ),
                  builder: (context) => Semantics(
                    container: true,
                    label: c.stop == atlasYears.length - 1
                        ? s.atlasMapLabelToday('${widget.places.length}')
                        : s.atlasMapLabel(
                            atlasYearLabel(context, atlasYears[c.stop]),
                            '${widget.places.length}',
                          ),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        key: const ValueKey('atlas-canvas'),
                        painter: AtlasTilePainter(_tiles, c),
                        foregroundPainter: AtlasOverlayPainter(
                          scene,
                          c,
                          _geometry,
                          semantics: _MarkerSemantics(
                            places: widget.places,
                            controller: c,
                            settled: c.settled,
                            describe: (m) => _describe(context, m),
                            onTap: _activate,
                            textDirection: Directionality.of(context),
                          ),
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: SnapshotBuilder(
                listenable: c,
                snapshot: () => (
                  c.rings,
                  c.me,
                  c.below,
                  _locating,
                  c.view.rotation.abs() % (2 * math.pi) > .01,
                  (c.view.rotation * 8).round(), // the north arrow's angle
                ),
                builder: (context) => AtlasControls(
                  controller: c,
                  locating: _locating,
                  onZoomIn: () => _zoom(2),
                  onZoomOut: () => _zoom(.5),
                  onNorth: () => _animateView(c.view.copyWith(rotation: 0)),
                  onRecenter: () => _animateView(AtlasView.peninsula),
                  onFromMe: _fromMe,
                  onLayers: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => AtlasLayersSheet(
                      assets: widget.assets,
                      year: atlasYears[c.stop],
                      below: c.below,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SnapshotBuilder(
                listenable: c,
                snapshot: () => (c.stop, _playing),
                builder: (context) => AtlasTimeBar(
                  stop: c.stop,
                  playing: _playing,
                  onStop: _goToStop,
                  onPlay: _play,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _describe(BuildContext context, AtlasMarker m) {
    final s = context.l10n;
    if (m.isCluster) return s.atlasCluster('${m.places.length}');
    final p = m.places.single;
    final year = atlasYears[c.stop];
    final parts = [
      p.names.inLanguage(context.language),
      ...p.categories.map((cat) => categoryLabel(context, cat)),
      formatMilDistance(fromMilion(p).km, language: context.language),
      if (widget.assets.years.standsFrom(p) > year)
        s.atlasNotYet(atlasYearLabel(context, year)),
    ];
    return parts.join(', ');
  }
}

/// Marker nodes for TalkBack, rebuilt only when the camera settles or the
/// places change: never per frame while the map moves (the P09 lesson).
class _MarkerSemantics implements AtlasSemantics {
  _MarkerSemantics({
    required this.places,
    required this.controller,
    required this.settled,
    required this.describe,
    required this.onTap,
    required this.textDirection,
  });
  final List<Place> places;
  final AtlasController controller;
  final int settled;
  final String Function(AtlasMarker) describe;
  final void Function(AtlasMarker) onTap;
  final TextDirection textDirection;

  @override
  List<CustomPainterSemantics> build(Size size) {
    final view = controller.view;
    final screen = Offset.zero & size;
    final markers = clusterPlaces(places, view)
      ..sort((a, b) {
        final pa = view.toScreen(a.world, size),
            pb = view.toScreen(b.world, size);
        final row = (pa.dy / 48).floor().compareTo((pb.dy / 48).floor());
        return row != 0 ? row : pa.dx.compareTo(pb.dx);
      });
    return [
      for (final m in markers)
        if (screen.contains(view.toScreen(m.world, size)))
          CustomPainterSemantics(
            key: ValueKey(m.places.map((p) => p.id).join(',')),
            rect: Rect.fromCenter(
              center: view.toScreen(m.world, size),
              width: 48,
              height: 48,
            ),
            properties: SemanticsProperties(
              button: true,
              label: describe(m),
              textDirection: textDirection,
              onTap: () => onTap(m),
            ),
          ),
    ];
  }

  @override
  bool differs(AtlasSemantics? old) =>
      old is! _MarkerSemantics ||
      old.settled != settled ||
      !identical(old.places, places) ||
      old.controller != controller;
}
