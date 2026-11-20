import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../atlas/atlas_assets.dart';
import '../atlas/atlas_data.dart';
import '../atlas/atlas_style.dart';
import '../atlas/historic.dart';
import 'siege.dart';
import 'siege_controller.dart';

/// The siege's base map, drawn once from the Atlas's offline data in its
/// Byzantine manner: the land as it was (before the modern fills), the
/// water, and the walls standing in 1453.
class SiegeBase {
  SiegeBase(this.image, this.metres);
  final ui.Image image;

  /// The frame in metres east and north of the Milion.
  final Rect metres;

  /// [widthPx] pixels across; north up.
  static Future<SiegeBase> render(
    AtlasAssets atlas,
    SiegeManifest m, {
    int widthPx = 2048,
  }) {
    final frame = siegeFrameMetres(m);
    // `frame` has top = north (larger y); work with min/max explicitly.
    final west = frame.left, east = frame.right;
    final south = math.min(frame.top, frame.bottom);
    final north = math.max(frame.top, frame.bottom);
    final k = widthPx / (east - west);
    final heightPx = ((north - south) * k).round();
    final style = MannerStyle.manuscript;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    double sx(double x) => (x - west) * k;
    double sy(double y) => (north - y) * k;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, widthPx.toDouble(), heightPx.toDouble()),
      Paint()..color = style.water,
    );
    final query = Rect.fromLTRB(west, south, east, north);
    final lod = (east - west) / widthPx > 8 ? AtlasLod.coarse : AtlasLod.fine;
    final land = Path()..fillType = PathFillType.evenOdd;
    void addRing(Path path, List<double> ring) {
      for (var i = 0; i + 1 < ring.length; i += 2) {
        final o = Offset(sx(ring[i]), sy(ring[i + 1]));
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      path.close();
    }

    final index = atlas.index;
    for (final f in [
      for (final f in index.layer(AtlasLayer.land, lod)!.query(query))
        if (f.cls != 1) f,
      ...?index.layer(AtlasLayer.landThen, lod)?.query(query),
    ]) {
      for (final ring in f.rings) {
        addRing(land, ring);
      }
    }
    canvas.drawPath(land, Paint()..color = style.land);
    canvas.drawPath(
      land,
      Paint()
        ..color = style.shore
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final lakes = Path()..fillType = PathFillType.evenOdd;
    for (final f
        in index.layer(AtlasLayer.water, lod)?.query(query) ??
            const <AtlasFeature>[]) {
      if (f.cls == 1) continue;
      for (final ring in f.rings) {
        addRing(lakes, ring);
      }
    }
    canvas.drawPath(lakes, Paint()..color = style.water);

    // The walls that stood in 1453, in ink: the accent is the events'.
    final wall = Paint()
      ..color = style.label
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round;
    for (final f in atlas.historic.inLayer(HistoricLayer.walls)) {
      if (f.from > 1453 || (f.to != null && f.to! < 1453)) continue;
      if (f.kind == HistoricKind.gate) continue;
      for (final part in f.parts) {
        final path = Path();
        for (var i = 0; i + 1 < part.length; i += 2) {
          final o = Offset(sx(part[i]), sy(part[i + 1]));
          if (i == 0) {
            path.moveTo(o.dx, o.dy);
          } else {
            path.lineTo(o.dx, o.dy);
          }
        }
        canvas.drawPath(path, wall);
      }
    }
    final picture = recorder.endRecording();
    return picture
        .toImage(widthPx, heightPx)
        .then(
          (image) => SiegeBase(image, Rect.fromLTRB(west, south, east, north)),
        );
  }
}

/// Screen ↔ map for a view of [width] metres centred on (lat, lng).
class SiegeCamera {
  SiegeCamera(this.size, SiegeView view)
    : centre = projectMetres(view.lat, view.lng),
      k = size.width / view.width;
  final Size size;
  final Offset centre;

  /// Pixels per metre.
  final double k;
  Offset toScreen(Offset m) => Offset(
    size.width / 2 + (m.dx - centre.dx) * k,
    size.height / 2 - (m.dy - centre.dy) * k,
  );
  Offset of(double lat, double lng) => toScreen(projectMetres(lat, lng));
}

class SiegePainter extends CustomPainter {
  SiegePainter({
    required this.controller,
    required this.base,
    required this.ink,
    required this.secondary,
    required this.accent,
    required this.paper,
    required this.text,
    required this.language,
  }) : super(repaint: controller);

  final SiegeController controller;
  final SiegeBase? base;
  final Color ink, secondary, accent, paper;
  final TextStyle text;
  final String language;
  final Map<String, TextPainter> _labels = {};

  TextPainter _label(String s, Color colour, {double size = 11}) =>
      _labels.putIfAbsent('$s|${colour.toARGB32()}|$size', () {
        return TextPainter(
          text: TextSpan(
            text: s,
            style: text.copyWith(
              fontSize: size,
              color: colour,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 2,
        )..layout(maxWidth: 150);
      });

  @override
  void paint(Canvas canvas, Size size) {
    final cam = SiegeCamera(
      size,
      fitView(controller.view, size, controller.manifest),
    );
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    final b = base;
    if (b != null) {
      final img = b.image;
      final kImg = img.width / b.metres.width;
      // The screen's rectangle in metres, then in the image's pixels.
      final tl = Offset(
        cam.centre.dx - size.width / 2 / cam.k,
        cam.centre.dy + size.height / 2 / cam.k,
      );
      final br = Offset(
        cam.centre.dx + size.width / 2 / cam.k,
        cam.centre.dy - size.height / 2 / cam.k,
      );
      final src = Rect.fromLTRB(
        (tl.dx - b.metres.left) * kImg,
        (b.metres.bottom - tl.dy) * kImg,
        (br.dx - b.metres.left) * kImg,
        (b.metres.bottom - br.dy) * kImg,
      );
      canvas.drawImageRect(
        img,
        src,
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    final focused = {for (final e in controller.focused) e.id};
    final events = controller.shown.toList();
    // Quiet first, named on top.
    events.sort(
      (a, b) =>
          (focused.contains(a.id) ? 1 : 0) - (focused.contains(b.id) ? 1 : 0),
    );
    // A map name never sits under an event's label.
    final boxes = [
      for (final e in events)
        if (focused.contains(e.id)) _labelBox(cam, e).$2,
    ];
    _names(canvas, cam, boxes);
    for (final e in events) {
      _event(canvas, cam, e, focused.contains(e.id));
    }
    _scaleBar(canvas, size, cam);
  }

  /// The map's names, written over the base and under the events.
  void _names(Canvas canvas, SiegeCamera cam, List<Rect> avoid) {
    for (final n in controller.manifest.labels) {
      final p = cam.of(n.lat, n.lng);
      if (p.dx < -80 || p.dx > cam.size.width + 80) continue;
      if (p.dy < -20 || p.dy > cam.size.height + 20) continue;
      final words = n.text.inLanguage(language);
      final tp = _nameCache.putIfAbsent('$words|${n.water}', () {
        return TextPainter(
          text: TextSpan(
            text: n.water ? words : words.toUpperCase(),
            style: text.copyWith(
              fontSize: n.water ? 11 : 9.5,
              color: secondary,
              fontStyle: n.water ? FontStyle.italic : FontStyle.normal,
              letterSpacing: n.water ? 0 : 1.4,
              height: 1.1,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 2,
        )..layout(maxWidth: 120);
      });
      final at = p - Offset(tp.width / 2, tp.height / 2);
      final box = (at & tp.size).inflate(2);
      if (avoid.any(box.overlaps)) continue;
      tp.paint(canvas, at);
    }
  }

  /// Where a named event's label goes: its anchor and its box.
  (Offset, Rect, TextPainter) _labelBox(SiegeCamera cam, SiegeEvent e) {
    final tp = _label(e.label.inLanguage(language), ink);
    final pts = e.shape.points;
    final a = pts.length == 1 ? pts.first : pts[pts.length ~/ 2];
    final anchor = cam.of(a.lat, a.lng);
    final right = anchor.dx < cam.size.width * .6;
    final at = anchor + Offset(right ? 14 : -14 - tp.width, -tp.height - 8);
    return (
      anchor,
      Rect.fromLTWH(at.dx - 3, at.dy - 2, tp.width + 6, tp.height + 4),
      tp,
    );
  }

  final Map<String, TextPainter> _nameCache = {};

  void _event(Canvas canvas, SiegeCamera cam, SiegeEvent e, bool strong) {
    final colour = strong ? accent : ink.withValues(alpha: .55);
    final pts = [for (final p in e.shape.points) cam.of(p.lat, p.lng)];
    final pen = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = strong ? 2 : 1.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = colour;
    final dashed = e.certainty == Certainty.conjectural;
    final p = controller.progress(e);
    switch (e.kind) {
      case 'camp':
        for (var i = -1; i <= 1; i++) {
          final c = pts.first + Offset(i * 9.0, (i.abs()) * 3.0);
          canvas.drawPath(
            Path()
              ..moveTo(c.dx - 4, c.dy + 3)
              ..lineTo(c.dx, c.dy - 5)
              ..lineTo(c.dx + 4, c.dy + 3)
              ..close(),
            pen,
          );
        }
      case 'gun':
        final c = pts.first;
        final aim = pts.length > 1 ? pts[1] : c + const Offset(-20, 0);
        final dir = (aim - c) / math.max(1, (aim - c).distance);
        canvas.drawCircle(c, 4, fill);
        canvas.drawLine(c, c + dir * 12, pen..strokeWidth = 3);
        pen.strokeWidth = strong ? 2 : 1.3;
        if (pts.length > 1 && strong) {
          _dashedLine(canvas, c + dir * 14, aim, pen);
        }
      case 'chain':
        _polyline(canvas, pts, pen, dashed: dashed);
        for (final b in _along(pts, 10)) {
          canvas.drawCircle(b, 2.2, fill);
        }
      case 'bridge':
        _polyline(canvas, pts, pen..strokeWidth = 3, dashed: dashed);
        pen.strokeWidth = strong ? 2 : 1.3;
      case 'overland':
        // No witness describes the route: a corridor about 500 m wide under
        // the line says where it may have run.
        if (dashed) {
          canvas.drawPath(
            Path()..addPolygon(pts, false),
            Paint()
              ..color = colour.withValues(alpha: .13)
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(10, 500 * cam.k)
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
        }
        _polyline(canvas, pts, pen, dashed: true);
        final along = _alongFraction(pts);
        for (var i = 0; i < 6; i++) {
          final f = p * 1.15 - i * .05;
          if (f <= 0 || f > 1.0) continue;
          _ship(canvas, along(f), colour, strong ? 1.0 : .8);
        }
      case 'fleet':
        for (var i = 0; i < pts.length; i++) {
          _ship(canvas, pts[i], colour, strong ? 1.0 : .8);
        }
      case 'assault':
        final a = pts.first, b = pts.last;
        canvas.drawLine(a, b, pen..strokeWidth = strong ? 3 : 2);
        final dir = (b - a) / math.max(1, (b - a).distance);
        final n = Offset(-dir.dy, dir.dx);
        canvas.drawPath(
          Path()
            ..moveTo(b.dx, b.dy)
            ..lineTo(b.dx - dir.dx * 9 + n.dx * 5, b.dy - dir.dy * 9 + n.dy * 5)
            ..lineTo(b.dx - dir.dx * 9 - n.dx * 5, b.dy - dir.dy * 9 - n.dy * 5)
            ..close(),
          fill,
        );
        pen.strokeWidth = strong ? 2 : 1.3;
      case 'fort':
        canvas.drawRect(
          Rect.fromCenter(center: pts.first, width: 9, height: 9),
          pen,
        );
      case 'tower' || 'mine':
        final c = pts.first;
        canvas.drawCircle(c, 5, pen);
        canvas.drawLine(
          c - const Offset(3.5, 3.5),
          c + const Offset(3.5, 3.5),
          pen,
        );
        canvas.drawLine(
          c - const Offset(3.5, -3.5),
          c + const Offset(3.5, -3.5),
          pen,
        );
      default:
        // breach, legend: an asterisk; a legend's is ringed, dashed.
        final c = pts.first;
        for (var i = 0; i < 3; i++) {
          final a = i * math.pi / 3;
          final d = Offset(math.cos(a), math.sin(a)) * 6;
          canvas.drawLine(c - d, c + d, pen);
        }
        if (e.kind == 'legend') {
          _dashedCircle(canvas, c, 11, pen);
        }
    }
    if (strong) {
      final (anchor, box, tp) = _labelBox(cam, e);
      final right = box.left > anchor.dx;
      canvas.drawRect(box, Paint()..color = paper.withValues(alpha: .86));
      canvas.drawLine(
        anchor,
        Offset(right ? box.left : box.right, box.bottom),
        Paint()
          ..color = ink
          ..strokeWidth = .7,
      );
      tp.paint(canvas, box.topLeft + const Offset(3, 2));
    }
  }

  void _ship(Canvas canvas, Offset c, Color colour, double s) {
    final hull = Path()
      ..moveTo(c.dx - 7 * s, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + 6 * s, c.dx + 7 * s, c.dy)
      ..close();
    canvas.drawPath(hull, Paint()..color = colour);
    canvas.drawLine(
      c,
      c - Offset(0, 8 * s),
      Paint()
        ..color = colour
        ..strokeWidth = 1,
    );
  }

  void _polyline(
    Canvas canvas,
    List<Offset> pts,
    Paint pen, {
    bool dashed = false,
  }) {
    for (var i = 1; i < pts.length; i++) {
      if (dashed) {
        _dashedLine(canvas, pts[i - 1], pts[i], pen);
      } else {
        canvas.drawLine(pts[i - 1], pts[i], pen);
      }
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint pen) {
    final d = (b - a).distance;
    if (d == 0) return;
    final u = (b - a) / d;
    for (var t = 0.0; t < d; t += 8) {
      canvas.drawLine(a + u * t, a + u * math.min(d, t + 4.5), pen);
    }
  }

  void _dashedCircle(Canvas canvas, Offset c, double r, Paint pen) {
    for (var a = 0.0; a < 2 * math.pi; a += .5) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, .28, false, pen);
    }
  }

  Iterable<Offset> _along(List<Offset> pts, double every) sync* {
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final d = (b - a).distance;
      for (var t = 0.0; t < d; t += every) {
        yield Offset.lerp(a, b, t / d)!;
      }
    }
  }

  Offset Function(double) _alongFraction(List<Offset> pts) {
    final lengths = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      lengths.add(lengths.last + (pts[i] - pts[i - 1]).distance);
    }
    final total = lengths.last;
    return (f) {
      final target = f.clamp(0.0, 1.0) * total;
      for (var i = 1; i < pts.length; i++) {
        if (target <= lengths[i]) {
          final seg = lengths[i] - lengths[i - 1];
          return Offset.lerp(
            pts[i - 1],
            pts[i],
            seg == 0 ? 0 : (target - lengths[i - 1]) / seg,
          )!;
        }
      }
      return pts.last;
    };
  }

  void _scaleBar(Canvas canvas, Size size, SiegeCamera cam) {
    final metres = cam.size.width / cam.k > 6000 ? 1000.0 : 500.0;
    final w = metres * cam.k;
    // Top left, under the honesty label: the caption covers the foot.
    const y = 52.0;
    final pen = Paint()
      ..color = ink
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(16, y), Offset(16 + w, y), pen);
    canvas.drawLine(Offset(16, y - 4), Offset(16, y + 2), pen);
    canvas.drawLine(Offset(16 + w, y - 4), Offset(16 + w, y + 2), pen);
    _label(
      metres >= 1000 ? '1 km' : '500 m',
      ink,
      size: 10,
    ).paint(canvas, Offset(20 + w, y - 7));
  }

  @override
  bool shouldRepaint(SiegePainter old) =>
      old.controller != controller ||
      old.base != base ||
      old.ink != ink ||
      old.language != language;
}
