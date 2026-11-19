import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/geography.dart';
import '../content/models.dart';
import '../design/tokens.dart';
import 'milion_intro.dart';
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

/// A road's ray: its name, the itinerary's distance and its bearing.
class RoadRay {
  const RoadRay(this.name, this.distance, this.bearing);
  final String name, distance;

  /// Degrees from north, clockwise.
  final double bearing;
}

/// Milestone 0 as one drawing on a 12-second clock ([t] in seconds), the
/// structure P04's lite version set: black → one gold tessera → the Milion's
/// fragment on Divanyolu and, around it, the domed tetrapylon assembling
/// while the camera pulls back (P13; the 3D study [intro]) → the camera tips
/// over to the street plan at mile zero → the peninsula, with the roads that
/// counted their miles from the city → Roman-mile rings → five places →
/// “Every road started here.” Without [intro] (not loaded yet) the stone is
/// marked by its tessera alone.
class FirstRunPainter extends CustomPainter {
  FirstRunPainter({
    required this.t,
    required this.line,
    required this.stone,
    required this.street,
    required this.coordinates,
    required this.places,
    required this.scaler,
    this.intro,
    this.honesty = '',
    this.roads = const [],
    this.still = false,
  });
  final double t;
  final String line, stone, street, coordinates;

  /// The label the drawn reconstruction carries (§3), in capitals.
  final String honesty;
  final List<LitPlace> places;
  final List<RoadRay> roads;
  final MilionIntro? intro;
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
    final plan = ease(span(t, 4.6, 5.3));

    // Plan: pull back from street scale at mile zero to the peninsula.
    final mapT = ease(span(t, 5.4, 8.2));
    final s0 = unit * .5 / 220, s1 = unit * .5 / 4200;
    final scale = s0 * math.pow(s1 / s0, mapT);
    final camera = Offset.lerp(Offset.zero, const Offset(-1250, 450), mapT)!;
    Offset screen(double x, double y) =>
        c + Offset((x - camera.dx) * scale, -(y - camera.dy) * scale);

    // The Milion in 3D: the fragment, the tetrapylon assembling round it,
    // then tipped over onto the plan at the street's scale. It fades as the
    // street plan takes over where it stands.
    var foot = c;
    final shown = span(t, 2.0, 2.4) * (1 - span(t, 5.3, 5.8));
    final milion = intro;
    if (milion != null && shown > 0) {
      final view = milion.view(
        size,
        t,
        planScale: scale.toDouble(),
        planCentre: camera,
      );
      final p = milion.paint(
        canvas,
        size,
        view,
        milion.parts(t, still: still),
        shown,
      );
      foot = p.toScreen(0, 0, 0);
      final label = span(t, 3.6, 4.3) * (1 - plan);
      if (label > 0) {
        // Under the drawing, on a leader from its lowest corner: a phone
        // is too narrow beside it.
        final m = milion.monument;
        var low = const Offset(0, -1e9);
        for (final x in [m.minX, m.maxX]) {
          for (final y in [m.minY, m.maxY]) {
            final q = p.toScreen(x, y, m.minZ);
            if (q.dy > low.dy) low = q;
          }
        }
        final end = low + Offset(0, math.min(unit * .08, 28));
        canvas.drawLine(low, end, _stroke(Pigment.marble, .8 * label));
        final room = size.width - 48;
        final title = _label(
          stone,
          TypeRole.inscription(
            16,
            color: Pigment.marble.withValues(alpha: label),
          ),
          maxWidth: room,
        );
        final where = _label(
          '$street\n$coordinates',
          TypeRole.measurement.copyWith(
            fontSize: 10,
            color: Pigment.marble.withValues(alpha: label * .8),
          ),
          maxWidth: room,
        );
        final tag = _label(
          honesty,
          TypeRole.measurement.copyWith(
            fontSize: 9,
            letterSpacing: 1.2,
            color: Pigment.gold.withValues(alpha: label),
          ),
          maxWidth: room,
        );
        var y = end.dy + 6;
        for (final text in [title, where, tag]) {
          final x = (end.dx - text.width / 2)
              .clamp(24.0, math.max(24.0, size.width - 24 - text.width))
              .toDouble();
          text.paint(canvas, Offset(x, y));
          y += text.height + 3;
        }
        title.dispose();
        where.dispose();
        tag.dispose();
      }
    }

    if (plan > 0) {
      final street = span(t, 5.0, 5.6) * (1 - span(mapT, .25, .6));
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

    // The roads leave the city, each with the miles an itinerary gives it.
    final zeroOnMap = screen(0, 0);
    final ends = <(RoadRay, Offset, Offset, double)>[];
    for (final (i, road) in roads.indexed) {
      final start = 5.9 + .2 * i;
      final grow = Curves.easeOutCubic.transform(span(t, start, start + .9));
      if (grow == 0) continue;
      final a = road.bearing * math.pi / 180;
      final dir = Offset(math.sin(a), -math.cos(a));
      // To the frame's edge, 12 px in.
      double reach(double from, double d, double lo, double hi) => d > 0
          ? (hi - from) / d
          : d < 0
          ? (lo - from) / d
          : double.infinity;
      final edge = math.min(
        reach(zeroOnMap.dx, dir.dx, 12, size.width - 12),
        reach(zeroOnMap.dy, dir.dy, 12, size.height - 12),
      );
      if (!edge.isFinite || edge <= 0) continue;
      final tip = zeroOnMap + dir * (edge * grow);
      canvas.drawLine(zeroOnMap, tip, _stroke(Pigment.gold, .7, 1));
      ends.add((road, tip, dir, start));
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

    // Mile zero itself: the tessera, first alone, then at the stone's foot,
    // then on the plan.
    final zoom = math.pow(8, 1 - ease(span(t, 2.2, 4.6))).toDouble();
    final side = 7 * zoom * (.6 + .4 * appear);
    final glint = still ? 0.0 : math.sin(span(t, 1.6, 2.2) * math.pi) * .25;
    final at = t < 5.3
        ? Offset.lerp(c, foot, ease(span(t, 2.2, 2.8)))!
        : zero;
    _tessera(canvas, at, side, appear);
    if (glint > 0) {
      _tessera(canvas, at, side * (1 + glint), glint);
    }

    // Five places light up.
    final taken = <Rect>[];
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
      taken.add(
        Rect.fromLTWH(
          x,
          y,
          math.max(name.width, mil.width),
          name.height + mil.height + 1,
        ).inflate(4),
      );
      name.dispose();
      mil.dispose();
    }

    // The roads' names and miles, beside each ray's end, moved along the
    // frame's edge until they clear the places' labels.
    for (final (road, tip, dir, start) in ends) {
      final words = span(t, start + .6, start + 1.2);
      if (words == 0) continue;
      final name = _label(
        road.name,
        TypeRole.measurement.copyWith(
          fontSize: 10,
          letterSpacing: 1,
          color: Pigment.gold.withValues(alpha: words),
        ),
        maxWidth: 150,
      );
      final miles = _label(
        road.distance,
        TypeRole.measurement.copyWith(
          fontSize: 10,
          color: Pigment.marble.withValues(alpha: words * .8),
        ),
        maxWidth: 150,
      );
      final w = math.max(name.width, miles.width);
      final h = name.height + miles.height;
      Offset place(double shift) => Offset(
        (tip.dx - (dir.dx > 0 ? w + 6 : -6)).clamp(8.0, size.width - w - 8),
        (tip.dy - (dir.dy > 0 ? h + 6 : -6) + shift).clamp(
          8.0,
          size.height - h - 8,
        ),
      );
      var at = place(0);
      // Along the edge, away from the frame's middle first.
      final away = tip.dy > size.height / 2 ? 1.0 : -1.0;
      for (final shift in [
        for (var k = 1; k <= 12; k++) ...[away * 12.0 * k, -away * 12.0 * k],
      ]) {
        final box = (at & Size(w, h)).inflate(2);
        if (!taken.any(box.overlaps)) break;
        at = place(shift);
      }
      taken.add((at & Size(w, h)).inflate(4));
      name.paint(canvas, at + Offset((w - name.width) / 2, 0));
      miles.paint(canvas, at + Offset((w - miles.width) / 2, name.height));
      name.dispose();
      miles.dispose();
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
      old.roads != roads ||
      old.intro != intro ||
      old.honesty != honesty ||
      old.scaler != scaler ||
      old.still != still;
}
