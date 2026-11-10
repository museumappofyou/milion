import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../city/city_tab.dart' show categorySymbol;
import '../content/geography.dart';
import '../content/models.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import 'atlas_assets.dart';
import 'atlas_controller.dart';
import 'atlas_markers.dart';
import 'atlas_style.dart';
import 'atlas_tiles.dart';
import 'atlas_view.dart';
import 'historic.dart';
import 'historic_shapes.dart';

/// The raster half of the map: tiles of the current manner, crossfaded into
/// the next one while the slider moves between eras. Missing tiles show
/// their nearest rendered ancestor, so panning never reveals a hole.
class AtlasTilePainter extends CustomPainter {
  AtlasTilePainter(this.cache, this.controller)
    : super(repaint: Listenable.merge([controller.motion, cache]));
  final TileCache cache;
  final AtlasController controller;

  static final _image = Paint()
    ..filterQuality = FilterQuality.low
    ..isAntiAlias = false;

  @override
  void paint(Canvas canvas, Size size) {
    final view = controller.view, year = controller.year;
    final manners = mannersAt(year);
    canvas.drawRect(Offset.zero & size, Paint()..color = styleAt(year).water);
    final keep = <TileKey>{};
    canvas.save();
    canvas.transform(view.matrix(size));
    void layer(AtlasManner manner, double opacity) {
      _image.color = Color.fromRGBO(0, 0, 0, opacity);
      {
        for (final key in visibleTiles(view, size, manner)) {
          keep.add(key);
          final image = cache.peek(key);
          if (image != null) {
            _draw(canvas, image, key, key);
            continue;
          }
          cache.request(key);
          for (var a = key.parent, d = 1; a != null && d <= 5; d++) {
            final up = cache.peek(a);
            if (up != null) {
              _draw(canvas, up, a, key);
              break;
            }
            a = a.parent;
          }
        }
      }
    }

    if (manners.t < 1 || manners.from == manners.to) layer(manners.from, 1);
    if (manners.from != manners.to && manners.t > 0) {
      layer(manners.to, manners.t);
    }
    canvas.restore();
    cache.retain(keep);
  }

  /// Draws the part of [image] (tile [source]) that covers [target].
  void _draw(Canvas canvas, ui.Image image, TileKey source, TileKey target) {
    final res = image.width.toDouble();
    final d = target.z - source.z;
    final cells = 1 << d;
    final sz = res / cells;
    final fx = target.x - (source.x << d), fy = target.y - (source.y << d);
    final src = Rect.fromLTWH(fx * sz, (cells - 1 - fy) * sz, sz, sz);
    final dst = tileRect(target.z, target.x, target.y);
    canvas.save();
    canvas.translate(dst.left, dst.bottom);
    canvas.scale(dst.width / res, -dst.height / res);
    canvas.drawImageRect(image, src, Rect.fromLTWH(0, 0, res, res), _image);
    canvas.restore();
  }

  @override
  bool shouldRepaint(AtlasTilePainter old) =>
      old.cache != cache || old.controller != controller;
}

/// What the overlay needs besides the controller; rebuilt when filters,
/// selection or language change.
class OverlayScene {
  OverlayScene({
    required this.assets,
    required this.places,
    required this.selected,
    required this.language,
    required this.colors,
  });
  final AtlasAssets assets;
  final List<Place> places;
  final String? selected;
  final String language;
  final MeasureColors colors;
}

/// The vector half: historic features by year, the Below layer, Milion
/// rings and place markers, redrawn every frame from cached world paths.
class AtlasOverlayPainter extends CustomPainter {
  AtlasOverlayPainter(
    this.scene,
    this.controller,
    this.geometry, {
    this.semantics,
  }) : super(repaint: Listenable.merge([controller.motion, controller]));
  final OverlayScene scene;
  final AtlasController controller;
  final HistoricGeometryCache geometry;

  /// Builds the marker nodes; see the map's _MarkerSemantics.
  final AtlasSemantics? semantics;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => semantics?.build;

  @override
  bool shouldRebuildSemantics(AtlasOverlayPainter oldDelegate) =>
      semantics?.differs(oldDelegate.semantics) ??
      oldDelegate.semantics != null;

  @override
  void paint(Canvas canvas, Size size) {
    final view = controller.view, year = controller.year;
    final style = styleAt(year);
    final manners = mannersAt(year);
    final manuscript = manners.from == AtlasManner.manuscript
        ? 1 - manners.t
        : 0.0;
    final px = 1 / view.scale; // metres per logical pixel
    final visible = view.visibleWorld(size).inflate(200 * px);

    canvas.save();
    canvas.transform(view.matrix(size));
    final labels = <(Offset, String, _LabelKind, double)>[];
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (controller.below) {
      // Below: the city above fades back so what lies under it reads.
      canvas.drawRect(
        visible,
        fill..color = scene.colors.ground.withValues(alpha: .55),
      );
    }

    final order = [
      HistoricKind.waterThen,
      HistoricKind.shoreThen,
      HistoricKind.street,
      HistoricKind.forum,
      HistoricKind.seaWall,
      HistoricKind.landWall,
      HistoricKind.gate,
      HistoricKind.hill,
      HistoricKind.siege,
      HistoricKind.excavation,
      HistoricKind.substructure,
      HistoricKind.cistern,
      HistoricKind.tunnel,
    ];
    for (final kind in order) {
      for (final f in geometry.byKind(kind)) {
        final below = f.feature.layer == HistoricLayer.below;
        if (below != controller.below) continue;
        if (!f.bounds.overlaps(visible)) continue;
        final a = f.feature.presence(year);
        if (a <= .01) continue;
        _feature(canvas, f, a, style, manuscript, px, fill, stroke, labels);
      }
    }

    if (controller.below) _tunnels(canvas, year, px);
    if (controller.rings) _rings(canvas, view, size, px, stroke, labels);
    final me = controller.me;
    if (me != null) {
      canvas.drawCircle(me, 9 * px, fill..color = Pigment.marble);
      canvas.drawCircle(me, 6 * px, fill..color = Pigment.cobalt);
    }
    canvas.restore();

    _labels(canvas, view, size, labels);
    _markers(canvas, view, size, year);
  }

  void _feature(
    Canvas canvas,
    HistoricShape f,
    double a,
    MannerStyle style,
    double manuscript,
    double px,
    Paint fill,
    Paint stroke,
    List<(Offset, String, _LabelKind, double)> labels,
  ) {
    final kind = f.feature.kind;
    final certain = f.feature.certainty.index <= Certainty.traced.index;
    switch (kind) {
      case HistoricKind.waterThen:
        // A filled harbour: its water then, inside its own shore line.
        canvas.drawPath(f.path, fill..color = style.water.withValues(alpha: a));
        stroke
          ..color = style.shore.withValues(alpha: a)
          ..strokeWidth = style.shoreWidth * px;
        canvas.drawPath(f.path, stroke);
      case HistoricKind.shoreThen:
        stroke
          ..color = style.shore.withValues(alpha: a)
          ..strokeWidth = style.shoreWidth * px;
        canvas.drawPath(f.path, stroke);
      case HistoricKind.landWall || HistoricKind.seaWall:
        final land = kind == HistoricKind.landWall;
        final w = (land ? 2.6 : 1.8) * px;
        if (!certain) {
          _dashedWorld(canvas, f, style.wall.withValues(alpha: a * .8), w, px);
        } else {
          stroke
            ..color = style.wall.withValues(alpha: a)
            ..strokeWidth = w;
          canvas.drawPath(f.path, stroke);
        }
        // Towers every ~55 m when they would be ≥ 7 px apart; drawn in
        // the manuscript manner, and in the others only close in.
        final towerPx = 55 / px;
        if (certain && towerPx >= 7 && (manuscript > 0 || towerPx > 18)) {
          final towers = f.towers;
          if (towers != null) {
            stroke
              ..color = style.wall.withValues(alpha: a)
              ..strokeWidth = (land ? 5.0 : 4.0) * px
              ..strokeCap = StrokeCap.square;
            canvas.drawRawPoints(ui.PointMode.points, towers, stroke);
            stroke.strokeCap = StrokeCap.round;
          }
        }
        if (land && px < 14) {
          labels.add((f.anchor, f.label(scene.language), _LabelKind.wall, a));
        }
      case HistoricKind.gate:
        if (px < 6) {
          canvas.drawCircle(
            f.anchor,
            3.2 * px,
            fill..color = style.wall.withValues(alpha: a),
          );
          if (px < 3) {
            labels.add((f.anchor, f.label(scene.language), _LabelKind.gate, a));
          }
        }
      case HistoricKind.street:
        stroke
          ..color = Pigment.marble.withValues(alpha: a * .9)
          ..strokeWidth = 4.2 * px;
        canvas.drawPath(f.path, stroke);
        stroke
          ..color = style.street.withValues(alpha: a)
          ..strokeWidth = 2.2 * px;
        if (certain) {
          canvas.drawPath(f.path, stroke);
        } else {
          _dashedWorld(canvas, f, stroke.color, 2.2 * px, px);
        }
        if (px < 8) {
          labels.add((f.anchor, f.label(scene.language), _LabelKind.street, a));
        }
      case HistoricKind.forum:
        if (f.feature.geometry == HistoricGeometry.polygon) {
          canvas.drawPath(
            f.path,
            fill..color = style.street.withValues(alpha: a * .25),
          );
          stroke
            ..color = style.street.withValues(alpha: a)
            ..strokeWidth = 1.2 * px;
          canvas.drawPath(f.path, stroke);
        } else {
          canvas.drawCircle(
            f.anchor,
            5 * px,
            fill..color = style.street.withValues(alpha: a),
          );
        }
        if (px < 10) {
          labels.add((f.anchor, f.label(scene.language), _LabelKind.forum, a));
        }
      case HistoricKind.hill:
        if (px < 40) {
          labels.add((f.anchor, f.label(scene.language), _LabelKind.hill, a));
        }
      case HistoricKind.siege:
        final c = Pigment.porphyry.withValues(alpha: a);
        if (f.feature.geometry == HistoricGeometry.point) {
          final r = 5 * px, o = f.anchor;
          canvas.drawPath(
            Path()
              ..moveTo(o.dx, o.dy + r)
              ..lineTo(o.dx + r, o.dy - r * .8)
              ..lineTo(o.dx - r, o.dy - r * .8)
              ..close(),
            fill..color = c,
          );
        } else {
          _dashedWorld(canvas, f, c, 2 * px, px, dash: 6, gap: 4);
        }
        if (px < 20) {
          labels.add((f.anchor, f.label(scene.language), _LabelKind.siege, a));
        }
      case HistoricKind.cistern ||
          HistoricKind.substructure ||
          HistoricKind.excavation:
        final c = switch (kind) {
          HistoricKind.cistern => Pigment.cobalt,
          HistoricKind.substructure => Pigment.porphyry,
          _ => Pigment.bronze,
        };
        if (f.feature.geometry == HistoricGeometry.polygon) {
          canvas.drawPath(f.path, fill..color = c.withValues(alpha: a * .35));
          stroke
            ..color = c.withValues(alpha: a)
            ..strokeWidth = 1.4 * px;
          canvas.drawPath(f.path, stroke);
        } else {
          final r = 6 * px;
          canvas.drawRect(
            Rect.fromCenter(center: f.anchor, width: r * 2, height: r * 2),
            fill..color = c.withValues(alpha: a),
          );
        }
        if (px < 12) {
          labels.add((f.anchor, f.label(scene.language), _LabelKind.below, a));
        }
      case HistoricKind.tunnel:
        _dashedWorld(
          canvas,
          f,
          Pigment.turquoise.withValues(alpha: a),
          2.4 * px,
          px,
          dash: 8,
          gap: 5,
        );
        if (px < 30) {
          labels.add((f.anchor, f.label(scene.language), _LabelKind.below, a));
        }
    }
  }

  /// Today's tunnels, cased so they read as underground lines.
  void _tunnels(Canvas canvas, double year, double px) {
    double rise(int from) => ((year - from) / 40 + 1).clamp(0.0, 1.0);
    for (final (path, a) in [
      (geometry.network, rise(HistoricGeometryCache.networkYear)),
      (geometry.tunel, rise(HistoricGeometryCache.tunelYear)),
    ]) {
      if (a <= .01) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        path,
        paint
          ..color = Pigment.turquoise.withValues(alpha: a)
          ..strokeWidth = 3.2 * px,
      );
      canvas.drawPath(
        path,
        paint
          ..color = Pigment.marble.withValues(alpha: a)
          ..strokeWidth = 1 * px,
      );
    }
  }

  /// Dashes measured in screen pixels on a world path; the dash pattern is
  /// cached per zoom level so panning reuses it.
  void _dashedWorld(
    Canvas canvas,
    HistoricShape f,
    Color color,
    double width,
    double px, {
    double dash = 5,
    double gap = 4,
  }) {
    final level = (math.log(px) / math.ln2).round();
    final unit = math.pow(2, level).toDouble();
    canvas.drawPath(
      f.dashed(level, dash * unit, gap * unit),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..color = color
        ..strokeWidth = width,
    );
  }

  void _rings(
    Canvas canvas,
    AtlasView view,
    Size size,
    double px,
    Paint stroke,
    List<(Offset, String, _LabelKind, double)> labels,
  ) {
    final centre = controller.me ?? Offset.zero;
    const mile = romanMileKm * 1000;
    // Every mile, or every 5 or 10 when they would crowd.
    final step = [
      1,
      5,
      10,
      50,
    ].firstWhere((k) => k * mile / px >= 44, orElse: () => 50);
    final corners = [
      view.toWorld(Offset.zero, size),
      view.toWorld(Offset(size.width, 0), size),
      view.toWorld(Offset(0, size.height), size),
      view.toWorld(Offset(size.width, size.height), size),
    ];
    final far = corners.map((c) => (c - centre).distance).reduce(math.max);
    final near = view.visibleWorld(size).contains(centre)
        ? 0.0
        : corners.map((c) => (c - centre).distance).reduce(math.min) * .5;
    // The label sits on the ring towards the top of the screen.
    final up =
        view.toWorld(Offset(size.width / 2, 0), size) -
        view.toWorld(Offset(size.width / 2, size.height / 2), size);
    final dir = up / up.distance;
    stroke
      ..color = Pigment.gold.withValues(alpha: .9)
      ..strokeWidth = 1.1 * px;
    final first = math.max(1, (near / (step * mile)).floor());
    for (var n = first * step; n * mile <= far && n <= 60; n += step) {
      final r = n * mile;
      canvas.drawCircle(centre, r, stroke);
      labels.add((centre + dir * r, romanNumeral(n), _LabelKind.ring, 1));
    }
    if (controller.me == null) {
      // Mile zero itself.
      canvas.drawCircle(Offset.zero, 4 * px, Paint()..color = Pigment.gold);
    }
  }

  void _labels(
    Canvas canvas,
    AtlasView view,
    Size size,
    List<(Offset, String, _LabelKind, double)> labels,
  ) {
    final taken = <Rect>[];
    for (final (world, text, kind, a) in labels) {
      if (text.isEmpty) continue;
      final p = view.toScreen(world, size);
      if (p.dx < -80 ||
          p.dy < -40 ||
          p.dx > size.width + 80 ||
          p.dy > size.height + 40) {
        continue;
      }
      final (tp, halo) = _pair(text, kind);
      final offset = kind == _LabelKind.ring
          ? p - Offset(tp.width / 2, tp.height + 2)
          : kind == _LabelKind.hill
          ? p - Offset(tp.width / 2, tp.height / 2)
          : p + const Offset(6, -6) - Offset(0, tp.height / 2);
      final box = (offset & tp.size).inflate(2);
      if (taken.any(box.overlaps)) continue;
      taken.add(box);
      if (a < .99) {
        canvas.saveLayer(
          box.inflate(4),
          Paint()..color = Color.fromRGBO(0, 0, 0, a),
        );
      }
      if (kind == _LabelKind.hill) {
        canvas.drawCircle(
          box.center,
          math.max(box.width, box.height) / 2 + 2,
          Paint()..color = Pigment.marble.withValues(alpha: .85),
        );
        canvas.drawCircle(
          box.center,
          math.max(box.width, box.height) / 2 + 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Pigment.bole,
        );
      }
      halo.paint(canvas, offset);
      tp.paint(canvas, offset);
      if (a < .99) canvas.restore();
    }
  }

  final _textCache = <(String, _LabelKind), (TextPainter, TextPainter)>{};

  (TextPainter, TextPainter) _pair(String text, _LabelKind kind) =>
      _textCache.putIfAbsent((text, kind), () {
        final style = switch (kind) {
          _LabelKind.ring => TypeRole.measurement.copyWith(
            fontSize: 11,
            color: Pigment.bronze,
          ),
          _LabelKind.hill => const TextStyle(
            fontFamily: TypeRole.displayFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Pigment.bole,
          ),
          _LabelKind.wall || _LabelKind.siege => const TextStyle(
            fontFamily: TypeRole.displayFamily,
            fontSize: 11,
            letterSpacing: .8,
            color: Pigment.porphyry,
          ),
          _LabelKind.street || _LabelKind.forum => const TextStyle(
            fontFamily: TypeRole.displayFamily,
            fontSize: 11,
            color: Pigment.bole,
          ),
          _LabelKind.gate => const TextStyle(
            fontFamily: TypeRole.bodyFamily,
            fontSize: 10,
            color: Pigment.lamp,
          ),
          _LabelKind.below => const TextStyle(
            fontFamily: TypeRole.bodyFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Pigment.cobalt,
          ),
        };
        TextPainter make(TextStyle s) => TextPainter(
          text: TextSpan(text: text, style: s),
          textDirection: TextDirection.ltr,
          maxLines: 2,
        )..layout(maxWidth: 160);
        return (
          make(style),
          make(
            style.copyWith(
              color: null,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..strokeJoin = StrokeJoin.round
                ..color = Pigment.marble.withValues(alpha: .9),
            ),
          ),
        );
      });

  void _markers(Canvas canvas, AtlasView view, Size size, double year) {
    final markers = clusterPlaces(scene.places, view);
    final screen = Offset.zero & size;
    final ink = Pigment.lamp;
    for (final m in markers) {
      final p = view.toScreen(m.world, size);
      if (!screen.inflate(30).contains(p)) continue;
      if (m.isCluster) {
        final standing = m.places
            .where((pl) => scene.assets.years.standsFrom(pl) <= year)
            .length;
        final r = 15.0 + math.min(8, m.places.length / 4);
        canvas.drawCircle(
          p,
          r,
          Paint()
            ..color = standing == 0
                ? Pigment.marble.withValues(alpha: .7)
                : Pigment.marble,
        );
        canvas.drawCircle(
          p,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = standing == 0 ? ink.withValues(alpha: .35) : ink,
        );
        final tp = _count(m.places.length);
        tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
        continue;
      }
      final place = m.places.single;
      final stood = scene.assets.years.standsFrom(place) <= year;
      final selected = place.id == scene.selected;
      final r = selected ? 17.0 : 14.0;
      final colour = _wavePigment(place.wave);
      canvas.drawCircle(
        p,
        r,
        Paint()..color = stood ? colour : Pigment.marble.withValues(alpha: .6),
      );
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 2.5 : 1.2
          ..color = stood
              ? (selected ? Pigment.gold : Pigment.marble)
              : colour.withValues(alpha: .5),
      );
      paintPlanSymbol(
        canvas,
        categorySymbol(place),
        Rect.fromCenter(center: p, width: r * 1.25, height: r * 1.25),
        stood ? Pigment.marble : colour.withValues(alpha: .6),
        strokeWidth: 1.6,
      );
    }
  }

  static Color _wavePigment(Wave w) => switch (w) {
    Wave.byzantine => Pigment.porphyry,
    Wave.mosques => Pigment.cobalt,
    Wave.museums => Pigment.verdigris,
    Wave.city || Wave.abroad => Pigment.bronze,
  };

  final _counts = <int, TextPainter>{};
  TextPainter _count(int n) => _counts.putIfAbsent(
    n,
    () => TextPainter(
      text: TextSpan(
        text: '$n',
        style: TypeRole.measurement.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Pigment.lamp,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(),
  );

  @override
  bool shouldRepaint(AtlasOverlayPainter old) =>
      old.scene != scene ||
      old.controller != controller ||
      old.geometry != geometry;
}

enum _LabelKind { ring, hill, wall, gate, street, forum, siege, below }

/// Semantics for the overlay's markers, supplied by the map.
abstract interface class AtlasSemantics {
  List<CustomPainterSemantics> build(Size size);
  bool differs(AtlasSemantics? old);
}
