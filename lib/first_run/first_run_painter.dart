import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/geography.dart';
import '../content/models.dart';
import '../design/tokens.dart';
import 'peninsula_data.dart';

/// Metres east/north of the Milion, the projection the OSM build script uses.
Offset metresFromMilion(Coordinates p) => Offset(
  (p.lng - milion.lng) *
      math.pi /
      180 *
      math.cos(milion.lat * math.pi / 180) *
      earthRadiusKm *
      1000,
  (p.lat - milion.lat) * math.pi / 180 * earthRadiusKm * 1000,
);

class LitPlace {
  const LitPlace(
    this.name,
    this.distance,
    this.metres, {
    this.left = false,
    this.below = false,
  });
  final String name, distance;
  final Offset metres;

  /// Label placement around the dot, set per place so labels never collide.
  final bool left, below;
}

/// Milestone 0 lite as one drawing on a 12-second clock ([t] in seconds):
/// black → one gold tessera → pull back to the Milion pillar in elevation →
/// the street plan at mile zero → the peninsula → Roman-mile rings → five
/// places → “Every road started here.”
class FirstRunPainter extends CustomPainter {
  FirstRunPainter({
    required this.t,
    required this.line,
    required this.stone,
    required this.street,
    required this.coordinates,
    required this.places,
    required this.scaler,
    this.still = false,
  });
  final double t;
  final String line, stone, street, coordinates;
  final List<LitPlace> places;
  final TextScaler scaler;

  /// Reduced-motion frames omit the transient halos.
  final bool still;

  static double span(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);
  static double ease(double x) => Curves.easeInOutCubic.transform(x);

  static Paint _stroke(Color color, double alpha, [double width = 1]) => Paint()
    ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;

  TextPainter _label(
    String text,
    TextStyle style, {
    double? maxWidth,
    bool left = false,
  }) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: left ? TextAlign.left : TextAlign.center,
    textScaler: scaler.clamp(maxScaleFactor: 1.5),
  )..layout(maxWidth: maxWidth ?? double.infinity);

  void _tessera(Canvas canvas, Offset at, double side, double alpha) {
    final h = side / 2;
    canvas.drawPath(
      Path()
        ..moveTo(at.dx - h, at.dy - h * .85)
        ..lineTo(at.dx + h, at.dy - h)
        ..lineTo(at.dx + h * .86, at.dy + h)
        ..lineTo(at.dx - h, at.dy + h * .86)
        ..close(),
      Paint()..color = Pigment.gold.withValues(alpha: alpha),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Pigment.lamp);
    if (t < 1) return;
    final c = size.center(Offset.zero), unit = size.shortestSide;
    final appear = Curves.easeOutCubic.transform(span(t, 1, 1.6));
    final pull = ease(span(t, 2.2, 4.6));
    final plan = ease(span(t, 4.6, 5.4));
    final zoom = math.pow(8, 1 - pull).toDouble();
    final h = unit * .4, w = h * .24;

    // Elevation: the re-erected Milion pillar, drawn as hairlines.
    final origin = c + Offset(0, h * .45 * pull * (1 - plan));
    final drawing = span(t, 2.2, 3.2) * (1 - plan);
    if (drawing > 0) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.scale(zoom);
      final ink = _stroke(Pigment.marble, .9 * drawing, 1 / zoom);
      canvas.drawLine(Offset(-w * 2.2, 0), Offset(w * 2.2, 0), ink);
      for (var x = -w * 2.2; x < w * 2.2; x += 6 / zoom) {
        canvas.drawLine(
          Offset(x, 0),
          Offset(x - 8 / zoom, 10 / zoom),
          _stroke(Pigment.marble, .35 * drawing, 1 / zoom),
        );
      }
      canvas.drawRect(Rect.fromLTWH(-w * .75, -h * .07, w * 1.5, h * .07), ink);
      canvas.drawPath(
        Path()
          ..moveTo(-w / 2, -h * .07)
          ..lineTo(-w / 2, -h * .93)
          ..lineTo(-w * .2, -h * .97)
          ..lineTo(0, -h * .94)
          ..lineTo(w * .15, -h)
          ..lineTo(w / 2, -h * .96)
          ..lineTo(w / 2, -h * .07),
        ink,
      );
      canvas.restore();
      final label = span(t, 3.6, 4.3) * (1 - plan);
      if (label > 0) {
        final at = origin + Offset(w / 2, -h * .55);
        final end = at + Offset(h * .3, 0);
        canvas.drawLine(at, end, _stroke(Pigment.marble, .8 * label));
        final room = size.width - end.dx - 24;
        final title = _label(
          stone,
          TypeRole.inscription(
            16,
            color: Pigment.marble.withValues(alpha: label),
          ),
          maxWidth: room,
          left: true,
        );
        final where = _label(
          '$street\n$coordinates',
          TypeRole.measurement.copyWith(
            fontSize: 10,
            color: Pigment.marble.withValues(alpha: label * .8),
          ),
          maxWidth: room,
          left: true,
        );
        title.paint(canvas, end + Offset(8, -title.height / 2));
        where.paint(canvas, end + Offset(8, title.height / 2 + 2));
        title.dispose();
        where.dispose();
      }
    }

    // Plan: pull back from street scale at mile zero to the peninsula.
    final mapT = ease(span(t, 5.4, 8.2));
    final s0 = unit * .5 / 220, s1 = unit * .5 / 4200;
    final scale = s0 * math.pow(s1 / s0, mapT);
    final camera = Offset.lerp(Offset.zero, const Offset(-1250, 450), mapT)!;
    Offset screen(double x, double y) =>
        c + Offset((x - camera.dx) * scale, -(y - camera.dy) * scale);
    if (plan > 0) {
      final street = plan * (1 - span(mapT, .25, .6));
      if (street > 0) {
        for (final way in milionStreet) {
          final kind = way[0].toInt();
          final path = Path()
            ..moveTo(screen(way[1], way[2]).dx, screen(way[1], way[2]).dy);
          for (var i = 3; i + 1 < way.length; i += 2) {
            final p = screen(way[i], way[i + 1]);
            path.lineTo(p.dx, p.dy);
          }
          canvas.drawPath(
            path,
            _stroke(Pigment.marble, street * const [.85, .45, .45, .9][kind]),
          );
        }
      }
      final shore = plan * span(mapT, .2, .6);
      if (shore > 0) {
        for (final coast in peninsulaCoast) {
          final path = Path()
            ..moveTo(
              screen(coast[0].toDouble(), coast[1].toDouble()).dx,
              screen(coast[0].toDouble(), coast[1].toDouble()).dy,
            );
          for (var i = 2; i + 1 < coast.length; i += 2) {
            final p = screen(coast[i].toDouble(), coast[i + 1].toDouble());
            path.lineTo(p.dx, p.dy);
          }
          canvas.drawPath(path, _stroke(Pigment.marble, .75 * shore));
        }
      }
    }

    // Roman-mile rings spread from the stone, one after another.
    final zero = screen(0, 0);
    for (var k = 1; k <= 4; k++) {
      final start = 7.6 + .3 * (k - 1);
      final grow = Curves.easeOutCubic.transform(span(t, start, start + .7));
      if (grow == 0) continue;
      final radius = k * romanMileKm * 1000 * scale * grow;
      canvas.drawCircle(zero, radius, _stroke(Pigment.marble, .55));
      final tag = span(t, start + .5, start + .8);
      if (tag > 0) {
        final text = _label(
          romanNumeral(k),
          TypeRole.measurement.copyWith(
            color: Pigment.marble.withValues(alpha: tag * .9),
          ),
        );
        text.paint(
          canvas,
          zero + const Offset(.707, .707) * radius + const Offset(4, 2),
        );
        text.dispose();
      }
    }

    // Mile zero itself: the tessera, first alone, then on the stone and plan.
    final side = 7 * zoom * (.6 + .4 * appear);
    final glint = still ? 0.0 : math.sin(span(t, 1.6, 2.2) * math.pi) * .25;
    _tessera(canvas, Offset.lerp(origin, zero, plan)!, side, appear);
    if (glint > 0) {
      _tessera(
        canvas,
        Offset.lerp(origin, zero, plan)!,
        side * (1 + glint),
        glint,
      );
    }

    // Five places light up.
    for (final (i, p) in places.indexed) {
      final start = 8.9 + .25 * i;
      final lit = Curves.easeOutCubic.transform(span(t, start, start + .3));
      if (lit == 0) continue;
      final at = screen(p.metres.dx, p.metres.dy);
      if (!still) {
        final halo = span(t, start, start + .6);
        if (halo < 1) {
          canvas.drawCircle(
            at,
            4 + 16 * halo,
            _stroke(Pigment.gold, (1 - halo) * .8),
          );
        }
      }
      canvas.drawRect(
        Rect.fromCenter(center: at, width: 6, height: 6),
        Paint()..color = Pigment.gold.withValues(alpha: lit),
      );
      final name = _label(
        p.name,
        TypeRole.measurement.copyWith(
          fontSize: 11,
          color: Pigment.marble.withValues(alpha: lit),
        ),
        maxWidth: 140,
      );
      final mil = _label(
        p.distance,
        TypeRole.measurement.copyWith(
          fontSize: 10,
          color: Pigment.marble.withValues(alpha: lit * .75),
        ),
      );
      final x = p.left
          ? at.dx - 8 - math.max(name.width, mil.width)
          : at.dx + 8;
      final y = p.below ? at.dy + 6 : at.dy - name.height;
      name.paint(canvas, Offset(x, y));
      mil.paint(canvas, Offset(x, y + name.height + 1));
      name.dispose();
      mil.dispose();
    }

    // One line.
    final words = span(t, 10.2, 10.9);
    if (words > 0) {
      final text = _label(
        line,
        TypeRole.inscription(
          24,
          color: Pigment.marble.withValues(alpha: words),
        ),
        maxWidth: size.width - 48,
      );
      text.paint(
        canvas,
        Offset(c.dx - text.width / 2, size.height * .8 - text.height / 2),
      );
      text.dispose();
    }
  }

  @override
  bool shouldRepaint(FirstRunPainter old) =>
      old.t != t ||
      old.line != line ||
      old.places != places ||
      old.scaler != scaler ||
      old.still != still;
}
