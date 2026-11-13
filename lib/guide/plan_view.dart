import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/guide.dart';
import '../content/models.dart';
import '../design/tokens.dart';

/// How a plan sits on screen: the apse at the top (the building's +x up,
/// +y to the left), scaled to fit with a margin.
class PlanFrame {
  PlanFrame(PlaceGuide guide, Size size, {double margin = 20}) : _size = size {
    final b = guide.bounds;
    // Rotated extent: screen x = -y, screen y = -x.
    final w = b.height, h = b.width;
    k = math.min((size.width - 2 * margin) / w, (size.height - 2 * margin) / h);
    _cx = (b.bottom + b.top) / 2;
    _cy = (b.left + b.right) / 2;
  }
  final Size _size;
  late final double k; // pixels per metre
  late final double _cx, _cy; // plan centre (y, x)

  Offset toScreen(PlanPoint p) => Offset(
    _size.width / 2 - (p.y - _cx) * k,
    _size.height / 2 - (p.x - _cy) * k,
  );

  PlanPoint toPlan(Offset s) => PlanPoint(
    _cy - (s.dy - _size.height / 2) / k,
    _cx - (s.dx - _size.width / 2) / k,
  );
}

/// What the plan shows now.
@immutable
class PlanState {
  const PlanState({
    this.room,
    this.focus,
    this.path = const [],
    this.you,
    this.dimmed = const {},
  });

  /// The selected room, or null for all.
  final String? room;

  /// The artwork picked on the plan or found by the camera.
  final String? focus;

  /// A cycle's walking line through its stops.
  final List<PlanPoint> path;

  /// Where "you" stand during a walk (animated between stops).
  final PlanPoint? you;

  /// Artworks drawn faintly (outside the room or cycle in view).
  final Set<String> dimmed;
}

/// The plan drawing: walls as poché around each room, vaults and domes in
/// dashed reflected-ceiling lines, and one tessera per artwork.
class PlanPainter extends CustomPainter {
  PlanPainter({
    required this.guide,
    required this.artworks,
    required this.state,
    required this.colors,
    required this.language,
  });
  final PlaceGuide guide;
  final Map<String, Artwork> artworks;
  final PlanState state;
  final MeasureColors colors;
  final String language;

  /// Wall thickness drawn, in metres (a drawing convention).
  static const wall = 0.9;

  @override
  void paint(Canvas canvas, Size size) {
    final f = PlanFrame(guide, size);
    Path outline(PlanRoom r) {
      final p = Path()
        ..moveTo(
          f.toScreen(r.outline.first).dx,
          f.toScreen(r.outline.first).dy,
        );
      for (final q in r.outline.skip(1)) {
        final s = f.toScreen(q);
        p.lineTo(s.dx, s.dy);
      }
      return p..close();
    }

    final poche = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = wall * f.k
      ..strokeJoin = StrokeJoin.miter
      ..color = Pigment.porphyry.withValues(alpha: .85);
    for (final r in guide.rooms) {
      canvas.drawPath(outline(r), poche);
    }
    for (final r in guide.rooms) {
      final selected = state.room == r.id;
      canvas.drawPath(
        outline(r),
        Paint()
          ..color = selected
              ? Color.lerp(Pigment.marble, Pigment.gold, .18)!
              : Pigment.marble,
      );
    }

    // Reflected ceiling: domes with their ribs, vaults as dashed squares.
    final dashed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Pigment.lamp.withValues(alpha: .45);
    for (final v in guide.vaults) {
      final c = f.toScreen(v.center), r = v.radius * f.k;
      switch (v.kind) {
        case VaultKind.dome:
          _dashedCircle(canvas, c, r, dashed);
          for (var i = 0; i < v.ribs; i++) {
            final a = i * 2 * math.pi / v.ribs;
            canvas.drawLine(
              c + Offset(math.cos(a), math.sin(a)) * r * .25,
              c + Offset(math.cos(a), math.sin(a)) * r,
              dashed,
            );
          }
        case VaultKind.vault:
          final rect = Rect.fromCenter(center: c, width: r * 2, height: r * 2);
          _dashedPath(canvas, Path()..addRect(rect), dashed);
          _dashedPath(
            canvas,
            Path()
              ..moveTo(rect.left, rect.top)
              ..lineTo(rect.right, rect.bottom)
              ..moveTo(rect.right, rect.top)
              ..lineTo(rect.left, rect.bottom),
            dashed,
          );
        case VaultKind.apse:
          _dashedPath(
            canvas,
            Path()
              ..addArc(Rect.fromCircle(center: c, radius: r), math.pi, math.pi),
            dashed,
          );
      }
    }

    // A cycle's walking line.
    if (state.path.length > 1) {
      final p = Path();
      for (final (i, q) in state.path.indexed) {
        final s = f.toScreen(q);
        i == 0 ? p.moveTo(s.dx, s.dy) : p.lineTo(s.dx, s.dy);
      }
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..color = Pigment.gold,
      );
    }

    // Tesserae: gold for mosaics, bole for frescoes.
    final side = math.max(7.0, math.min(12.0, f.k * .55));
    for (final a in guide.anchors.values) {
      final art = artworks[a.artworkId];
      if (art == null) continue;
      final c = f.toScreen(a.at);
      final dim = state.dimmed.contains(a.artworkId);
      final base = art.kind == ArtworkKind.fresco ? Pigment.bole : Pigment.gold;
      final focus = state.focus == a.artworkId;
      final s = focus ? side * 1.6 : side;
      final rect = Rect.fromCenter(center: c, width: s, height: s);
      canvas.drawRect(
        rect,
        Paint()..color = base.withValues(alpha: dim ? .25 : 1),
      );
      if (focus) {
        canvas.drawRect(
          rect.inflate(2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Pigment.lamp,
        );
      }
    }

    // You, during a walk.
    final you = state.you;
    if (you != null) {
      final c = f.toScreen(you);
      canvas.drawCircle(c, 9, Paint()..color = Pigment.marble);
      canvas.drawCircle(c, 6, Paint()..color = Pigment.cobalt);
    }

    // Room names: the short name (before any parenthesis), turned to run
    // along a tall narrow room and shrunk only if it still does not fit.
    for (final r in guide.rooms) {
      final tp = TextPainter(
        text: TextSpan(
          text: TypeRole.capitals(
            r.name.inLanguage(language).split(' (').first,
            language,
          ),
          style: TextStyle(
            fontFamily: TypeRole.displayFamily,
            fontSize: 10,
            letterSpacing: 1.2,
            color: Pigment.lamp.withValues(alpha: .7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final b = r.bounds;
      // Screen x runs along the plan's y (north–south), screen y along x.
      final across = (b.top - b.bottom) * f.k - 6;
      final along = (b.right - b.left) * f.k - 6;
      // Turned only when even a 70% size would not fit across.
      final vertical = tp.width * .7 > across && along > across;
      final room = vertical ? along : across;
      final scale = tp.width > room ? math.max(.6, room / tp.width) : 1.0;
      canvas
        ..save()
        ..translate(f.toScreen(r.label).dx, f.toScreen(r.label).dy);
      if (vertical) canvas.rotate(-math.pi / 2);
      canvas.scale(scale);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  static void _dashedCircle(Canvas canvas, Offset c, double r, Paint paint) =>
      _dashedPath(
        canvas,
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
        paint,
      );

  static void _dashedPath(Canvas canvas, Path path, Paint paint) {
    final out = Path();
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        out.addPath(m.extractPath(d, d + 4), Offset.zero);
      }
    }
    canvas.drawPath(out, paint);
  }

  @override
  bool shouldRepaint(PlanPainter old) =>
      old.state != state ||
      old.guide != guide ||
      old.language != language ||
      old.colors != colors;
}

/// The artwork whose tessera is nearest [screen] within [slop] pixels.
String? artworkAt(
  PlaceGuide guide,
  Size size,
  Offset screen, {
  double slop = 22,
}) {
  final f = PlanFrame(guide, size);
  String? best;
  var bestD = slop;
  for (final a in guide.anchors.values) {
    final d = (f.toScreen(a.at) - screen).distance;
    if (d < bestD) {
      best = a.artworkId;
      bestD = d;
    }
  }
  return best;
}

/// The room under [screen].
String? roomAt(PlaceGuide guide, Size size, Offset screen) {
  final p = PlanFrame(guide, size).toPlan(screen);
  for (final r in guide.rooms) {
    if (r.contains(p)) return r.id;
  }
  return null;
}
