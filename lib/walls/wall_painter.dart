import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'wall_controller.dart';
import 'wall_strip.dart';

/// Where things fall on the strip (P15, XVIII): an elevation of the walls
/// seen from the field, scrolling sideways; under it the cross-section at
/// the reading line, to scale; at the foot the whole line, Marmara to the
/// Golden Horn.
class WallLayout {
  WallLayout(this.size, this.at, this.manifest, {this.span = 320});
  final Size size;
  final double at;
  final WallStripManifest manifest;

  /// Metres of wall across the screen.
  final double span;

  double get pxPerMetre => size.width / span;
  double get heightPx => pxPerMetre * manifest.heightScale;

  /// The elevation's ground line, the section's band and the overview bar.
  double get elevationTop => 52;
  double get groundY => elevationTop + manifest.innerTowerHeight * heightPx + 8;
  double get moatBottomY => groundY + _moatDepth * heightPx;
  double get rulerY => moatBottomY + 14;

  /// Below the honesty label and the scale note (the player sets them at
  /// [rulerY] + 30).
  double get sectionTop => rulerY + 62;
  double get overviewY => size.height - 22;
  double get sectionBottom => overviewY - 30;

  double get _moatDepth {
    for (final l in manifest.layers) {
      if (l.kind == WallLayerKind.moat) return -l.height;
    }
    return 0;
  }

  double xOf(double metres) => size.width / 2 + (metres - at) * pxPerMetre;
  double metresAt(double x) => at + (x - size.width / 2) / pxPerMetre;
  bool visible(double metres, [double pad = 30]) {
    final x = xOf(metres);
    return x > -pad && x < size.width + pad;
  }

  /// The overview bar spans the width less a margin.
  double overviewX(double metres) =>
      16 + (size.width - 32) * (metres / manifest.length).clamp(0.0, 1.0);
  double overviewMetres(double x) =>
      ((x - 16) / (size.width - 32)).clamp(0.0, 1.0) * manifest.length;

  /// A gate's label box in the elevation, for taps.
  Rect gateHit(WallGate g) => Rect.fromCenter(
    center: Offset(xOf(g.at), groundY - 30),
    width: 56,
    height: 90,
  );
}

/// The gate under a tap on the elevation, if any.
WallGate? gateAt(WallController c, Size size, Offset p, {double span = 320}) {
  final layout = WallLayout(size, c.at, c.manifest, span: span);
  for (final g in c.manifest.gates) {
    if (layout.visible(g.at) && layout.gateHit(g).contains(p)) return g;
  }
  return null;
}

class WallPainter extends CustomPainter {
  WallPainter({
    required this.controller,
    required this.ink,
    required this.secondary,
    required this.accent,
    required this.paper,
    required this.poche,
    required this.text,
    required this.language,
    this.span = 320,
  }) : super(repaint: controller);

  final WallController controller;
  final Color ink, secondary, accent, paper, poche;
  final TextStyle text;
  final String language;
  final double span;

  final Map<String, TextPainter> _labels = {};

  TextPainter _label(
    String s,
    double size,
    Color colour, {
    FontWeight? w,
    double width = 120,
  }) {
    final key = '$s|$size|${colour.toARGB32()}|$w|$width';
    return _labels.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: s,
          style: text.copyWith(
            fontSize: size,
            color: colour,
            fontWeight: w,
            height: 1.1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: width);
    });
  }

  String _km(double metres) {
    final km = (metres / 1000).toStringAsFixed(1);
    return '${language == 'tr' ? km.replaceAll('.', ',') : km} km';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final m = controller.manifest;
    final at = controller.at;
    final l = WallLayout(size, at, m, span: span);
    final hair = Paint()
      ..color = ink
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final faint = Paint()
      ..color = secondary.withValues(alpha: .55)
      ..strokeWidth = .6
      ..style = PaintingStyle.stroke;
    final innerFill = Paint()..color = poche;
    final outerFill = Paint()..color = Color.lerp(paper, poche, .45)!;
    final cut = Paint()..color = ink;

    final from = l.metresAt(-40), to = l.metresAt(size.width + 40);
    _elevation(canvas, l, from, to, hair, faint, innerFill, outerFill);
    _ruler(canvas, l, from, to, faint);
    _readingLine(canvas, l);
    _section(canvas, l, controller.segment, hair, faint, cut);
    _overview(canvas, l, hair, faint);
  }

  WallLayer? _layer(WallLayerKind kind) {
    for (final l in controller.manifest.layers) {
      if (l.kind == kind) return l;
    }
    return null;
  }

  void _elevation(
    Canvas canvas,
    WallLayout l,
    double from,
    double to,
    Paint hair,
    Paint faint,
    Paint innerFill,
    Paint outerFill,
  ) {
    final m = controller.manifest;
    final h = l.heightPx, y0 = l.groundY;
    final inner = _layer(WallLayerKind.innerWall)!;
    final outer = _layer(WallLayerKind.outerWall);
    final breast = _layer(WallLayerKind.breastwork);
    final moat = _layer(WallLayerKind.moat);

    // Draw stretch by stretch: a single wall has no moat and no outer wall.
    for (final seg in m.segments) {
      final a = math.max(seg.from, from), b = math.min(seg.to, to);
      if (a >= b) continue;
      final xa = l.xOf(a), xb = l.xOf(b);
      final kind = seg.kind;
      // The inner wall, behind.
      final innerTop = y0 - inner.height * h;
      canvas.drawRect(Rect.fromLTRB(xa, innerTop, xb, y0), innerFill);
      canvas.drawLine(Offset(xa, innerTop), Offset(xb, innerTop), hair);
      _crenels(canvas, xa, xb, innerTop, l.pxPerMetre, hair);
      if (kind.hasOuterWall && outer != null) {
        final outerTop = y0 - outer.height * h;
        canvas.drawRect(Rect.fromLTRB(xa, outerTop, xb, y0), outerFill);
        canvas.drawLine(Offset(xa, outerTop), Offset(xb, outerTop), hair);
        _crenels(canvas, xa, xb, outerTop, l.pxPerMetre, hair);
      }
      if (kind.hasMoat && breast != null) {
        final bt = y0 - breast.height * h;
        canvas.drawLine(Offset(xa, bt), Offset(xb, bt), faint);
      }
      if (kind.hasMoat && moat != null) {
        // The moat, in front, below the field: hatched.
        final mb = y0 - moat.height * h;
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(xa, y0, xb, mb));
        for (var x = xa - (xa % 6) - 40; x < xb + 40; x += 6) {
          canvas.drawLine(Offset(x, mb), Offset(x + (mb - y0), y0), faint);
        }
        canvas.restore();
        canvas.drawLine(Offset(xa, mb), Offset(xb, mb), faint);
      }
      canvas.drawLine(Offset(xa, y0), Offset(xb, y0), hair);
    }

    // Towers: inner first (behind), then the outer ones in front.
    for (final pass in ['inner', 'outer']) {
      for (final t in m.towers) {
        if (t.wall != pass || t.at < from || t.at > to) continue;
        final seg = m.segmentAt(t.at);
        if (pass == 'outer' && !seg.kind.hasOuterWall) continue;
        final width = (pass == 'inner' ? 10.0 : 6.0) * l.pxPerMetre;
        final top =
            y0 -
            (pass == 'inner' ? m.innerTowerHeight : m.outerTowerHeight) * h;
        final x = l.xOf(t.at);
        final r = Rect.fromLTRB(x - width / 2, top, x + width / 2, y0);
        canvas.drawRect(r, pass == 'inner' ? innerFill : outerFill);
        canvas.drawRect(r, hair);
        _crenels(canvas, r.left, r.right, top, l.pxPerMetre, hair);
        if (pass == 'inner' && l.pxPerMetre > .8) {
          // Two window slits high in the tower.
          final slit = Paint()..color = ink.withValues(alpha: .7);
          for (final dx in [-.22, .22]) {
            canvas.drawRect(
              Rect.fromCenter(
                center: Offset(x + dx * width, top + (y0 - top) * .28),
                width: math.max(1.2, .8 * l.pxPerMetre),
                height: math.max(4, 2.2 * h),
              ),
              slit,
            );
          }
        }
      }
    }

    // Gates: openings through both walls, a bridge over the moat, a label
    // with a hairline leader to the gate.
    for (final g in m.gates) {
      if (g.at < from || g.at > to) continue;
      final x = l.xOf(g.at);
      final seg = m.segmentAt(g.at);
      if (g.legend) {
        // The Kerkoporta: a dashed postern; its place is disputed.
        final top = y0 - 4.5 * h;
        _dashed(canvas, Rect.fromLTRB(x - 3, top, x + 3, y0), hair);
      } else {
        final w = 5 * l.pxPerMetre;
        final innerTop = y0 - math.min(inner.height * .8, 9) * h;
        final open = Path()
          ..moveTo(x - w / 2, y0)
          ..lineTo(x - w / 2, innerTop + w / 2)
          ..arcToPoint(
            Offset(x + w / 2, innerTop + w / 2),
            radius: Radius.circular(w / 2),
          )
          ..lineTo(x + w / 2, y0)
          ..close();
        canvas.drawPath(open, Paint()..color = paper);
        canvas.drawPath(open, hair);
        if (seg.kind.hasMoat && moat != null) {
          final bridgeY = y0 + 2;
          canvas.drawLine(
            Offset(x - w, bridgeY),
            Offset(x + w, bridgeY),
            hair..strokeWidth = 1.6,
          );
          hair.strokeWidth = 1;
        }
      }
      final name = g.names.inLanguage(language);
      final tp = _label(
        name,
        11,
        g.legend ? secondary : ink,
        w: FontWeight.w600,
      );
      final labelTop = 8.0 + (m.gates.indexOf(g) % 2) * 2;
      final lx = (x - tp.width / 2).clamp(4.0, l.size.width - tp.width - 4);
      tp.paint(canvas, Offset(lx, labelTop));
      final year = g.year;
      var below = labelTop + tp.height;
      if (year != null) {
        final yp = _label(year, 10, secondary);
        yp.paint(canvas, Offset(lx, below));
        below += yp.height;
      }
      canvas.drawLine(
        Offset(x, below + 3),
        Offset(x, y0 - m.innerTowerHeight * h - 2),
        faint,
      );
    }
  }

  void _crenels(
    Canvas canvas,
    double xa,
    double xb,
    double top,
    double k,
    Paint p,
  ) {
    if (k < .9) return;
    final step = 2.4 * k, merlon = 1.2 * k, rise = math.max(1.5, .9 * k);
    for (var x = xa; x + merlon <= xb; x += step) {
      canvas.drawRect(Rect.fromLTWH(x, top - rise, merlon, rise), p);
    }
  }

  void _dashed(Canvas canvas, Rect r, Paint p) {
    final path = Path()..addRect(r);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 4) {
        canvas.drawPath(metric.extractPath(d, d + 2), p);
      }
    }
  }

  void _ruler(Canvas canvas, WallLayout l, double from, double to, Paint p) {
    final y = l.rulerY;
    canvas.drawLine(Offset(0, y), Offset(l.size.width, y), p);
    final first = (from / 100).ceil() * 100;
    for (var m = first.toDouble(); m <= to; m += 100) {
      if (m < 0 || m > controller.manifest.length) continue;
      final x = l.xOf(m);
      final major = m % 500 == 0;
      canvas.drawLine(Offset(x, y), Offset(x, y + (major ? 7 : 4)), p);
      // The reading line's own distance is printed under it; a tick's
      // label that would collide with it is left out.
      if (major && (x - l.size.width / 2).abs() > 56) {
        _label(_km(m), 10, secondary).paint(canvas, Offset(x + 3, y + 3));
      }
    }
  }

  void _readingLine(Canvas canvas, WallLayout l) {
    final x = l.size.width / 2;
    final p = Paint()
      ..color = accent
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, l.elevationTop - 6), Offset(x, l.rulerY + 8), p);
    final here = _label(_km(controller.at), 11, accent, w: FontWeight.w600);
    here.paint(canvas, Offset(x + 4, l.rulerY + 14));
  }

  void _section(
    Canvas canvas,
    WallLayout l,
    WallSegment seg,
    Paint hair,
    Paint faint,
    Paint cut,
  ) {
    final m = controller.manifest;
    final layers = [
      for (final x in m.layers)
        if (seg.kind.shows(x.kind)) x,
    ];
    if (layers.isEmpty) return;
    // One scale and one placement for every segment, set by the whole
    // triple defence: where the moat and the outer wall are gone, the inner
    // wall stands where and as tall as it does elsewhere. (Fitted to each
    // segment, the single wall at Blachernae filled the screen and read as
    // three times the size of the Theodosian one.)
    final first = m.layers.first.from;
    final width = m.layers.last.to - first + 10;
    final top = l.sectionTop + 26, bottom = l.sectionBottom - 46;
    final maxH = m.innerTowerHeight + 2;
    var moatDepth = 0.0;
    for (final x in m.layers) {
      if (x.kind == WallLayerKind.moat) moatDepth = -x.height;
    }
    final k = math.min(
      (l.size.width - 40) / width,
      (bottom - top) / (maxH + moatDepth),
    );
    final x0 = (l.size.width - width * k) / 2 + 5 * k;
    final base = top + maxH * k;
    double sx(double metres) => x0 + (metres - first) * k;

    // Field to the left (outside), city to the right.
    canvas.drawLine(Offset(16, base), Offset(l.size.width - 16, base), faint);
    // The layers' names hang just under the drawing, in two rows.
    final under = base + moatDepth * k + 12;
    final rowY = [under, under + 16];
    var row = 0;
    for (final layer in layers) {
      final a = sx(layer.from), b = sx(layer.to);
      switch (layer.kind) {
        case WallLayerKind.moat:
          final d = base - layer.height * k;
          final path = Path()
            ..moveTo(a, base)
            ..lineTo(a + (b - a) * .08, d)
            ..lineTo(b - (b - a) * .08, d)
            ..lineTo(b, base);
          canvas.drawPath(path, hair);
          canvas.save();
          canvas.clipRect(Rect.fromLTRB(a, d, b, d + 6));
          for (var x = a; x < b; x += 5) {
            canvas.drawLine(Offset(x, d + 6), Offset(x + 6, d), faint);
          }
          canvas.restore();
        case WallLayerKind.terrace || WallLayerKind.peribolos:
          final t = base - layer.height * k;
          canvas.drawLine(Offset(a, t), Offset(b, t), hair);
        case WallLayerKind.breastwork ||
            WallLayerKind.outerWall ||
            WallLayerKind.innerWall:
          // Cut walls in poché.
          canvas.drawRect(
            Rect.fromLTRB(a, base - layer.height * k, b, base),
            cut,
          );
      }
      // A leader to the layer's name, alternating rows.
      final name = layer.label.inLanguage(language);
      final tp = _label(name, 10, ink);
      final cx = (a + b) / 2;
      final ty = rowY[row % 2];
      final lx = (cx - tp.width / 2).clamp(4.0, l.size.width - tp.width - 4);
      canvas.drawLine(Offset(cx, base + 3), Offset(cx, ty - 1), faint);
      tp.paint(canvas, Offset(lx, ty));
      row++;
    }
    // The inner tower beyond the cut, dashed.
    final innerWall = layers.firstWhere(
      (x) => x.kind == WallLayerKind.innerWall,
    );
    _dashed(
      canvas,
      Rect.fromLTRB(
        sx(innerWall.from) - 9 * k,
        base - m.innerTowerHeight * k,
        sx(innerWall.to),
        base - innerWall.height * k,
      ),
      faint,
    );
    // Scale bar, 10 m, and which side is which.
    final sb = Paint()
      ..color = ink
      ..strokeWidth = 1.4;
    final sy = l.sectionTop + 8;
    canvas.drawLine(Offset(16, sy), Offset(16 + 10 * k, sy), sb);
    _label('10 m', 10, secondary).paint(canvas, Offset(20 + 10 * k, sy - 6));
    final segName = _label(
      seg.label.inLanguage(language),
      10,
      secondary,
      w: FontWeight.w600,
      width: l.size.width * .6,
    );
    segName.paint(canvas, Offset(l.size.width - segName.width - 16, sy - 6));
  }

  void _overview(Canvas canvas, WallLayout l, Paint hair, Paint faint) {
    final m = controller.manifest;
    final y = l.overviewY;
    canvas.drawLine(
      Offset(l.overviewX(0), y),
      Offset(l.overviewX(m.length), y),
      hair,
    );
    for (final g in m.gates) {
      final x = l.overviewX(g.at);
      canvas.drawLine(
        Offset(x, y - (g.legend ? 3 : 5)),
        Offset(x, y + 5),
        faint,
      );
    }
    final a = l.overviewX(l.metresAt(0)),
        b = l.overviewX(l.metresAt(l.size.width));
    canvas.drawRect(
      Rect.fromLTRB(a, y - 6, math.max(b, a + 2), y + 6),
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final ends = language == 'tr'
        ? ('Marmara', 'Haliç')
        : ('Marmara', 'Golden Horn');
    _label(
      ends.$1,
      9.5,
      secondary,
    ).paint(canvas, Offset(l.overviewX(0), y + 7));
    final e = _label(ends.$2, 9.5, secondary);
    e.paint(canvas, Offset(l.overviewX(m.length) - e.width, y + 7));
  }

  @override
  bool shouldRepaint(WallPainter old) =>
      old.controller != controller ||
      old.ink != ink ||
      old.paper != paper ||
      old.language != language ||
      old.span != span;
}

/// For tests and captures: the strip at [at] as an image.
Future<ui.Image> renderWallStill(
  WallPainter painter,
  Size size, {
  double pixelRatio = 1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(pixelRatio);
  canvas.drawRect(Offset.zero & size, Paint()..color = painter.paper);
  painter.paint(canvas, size);
  return recorder.endRecording().toImage(
    (size.width * pixelRatio).round(),
    (size.height * pixelRatio).round(),
  );
}
