import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'section.dart';
import 'section_controller.dart';

/// Where things fall on screen for a given reading depth: the painter and
/// the taps share it.
class SectionLayout {
  SectionLayout(this.size, this.depth, {this.gauge = 68})
    : pxPerMetre = size.height / 4.6,
      reading = size.height * .42;
  final Size size;
  final double depth, gauge, pxPerMetre, reading;
  double get left => 12;
  double get width => size.width - left - gauge;
  double y(double d) => reading + (depth - d) * pxPerMetre;
  double x(double u) => left + u * width;

  /// The ship's hull on screen, before any lift.
  Rect ship(SectionShip s) {
    final w = s.glyph * width;
    final h = switch (s.type) {
      ShipType.galley => w * .14,
      ShipType.round => w * .34,
      null => w * .28,
    };
    return Rect.fromCenter(
      center: Offset(x(s.x), y(s.depth)),
      width: w,
      height: math.max(8, h),
    );
  }

  Rect find(SectionFind f) {
    final w = math.max(30.0, f.length * width);
    return Rect.fromCenter(
      center: Offset(x(f.x), y(f.depth)),
      width: w,
      height: 24,
    );
  }

  /// The pop-up offset of a card lifted by [lift] (the drawing's paper
  /// rises toward the eye: up and a little left), plus [parallax] for a
  /// tilt or drag.
  Offset raise(double lift, Offset parallax) =>
      Offset(-3 * lift, -9 * lift) + parallax * lift;
}

/// The section as a measured drawing: hatched strata between depths, sea
/// level dashed, the depth gauge on the right edge, finds and ships as
/// cards that pop up out of their cut-outs (PU).
class SectionPainter extends CustomPainter {
  SectionPainter({
    required this.controller,
    required this.ink,
    required this.secondary,
    required this.accent,
    required this.paper,
    required this.text,
    required this.language,
    this.parallax = Offset.zero,
    this.devicePixelRatio = 2,
  }) : super(repaint: controller);
  final SectionController controller;
  final Color ink, secondary, accent, paper;
  final TextStyle text;
  final String language;
  final Offset parallax;

  /// The ground is rasterised once at this ratio (at most 2, to keep the
  /// image near 10 MB).
  final double devicePixelRatio;

  _SectionCache get _cache => _caches[controller] ??= _SectionCache();

  @override
  void paint(Canvas canvas, Size size) {
    final m = controller.manifest;
    final l = SectionLayout(size, controller.depth);
    final cache = _cache..check(this, size);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // The strata, their hatching, the station and sea level do not change
    // as the section scrolls: drawn once into an image (P14, A52s: drawn
    // per frame they held the reveal near 35 fps), then placed by depth.
    final ground = cache.ground ??= _rasterise(size);
    final top = l.y(m.top);
    canvas.drawImageRect(
      ground,
      Offset.zero & Size(ground.width.toDouble(), ground.height.toDouble()),
      Rect.fromLTWH(0, top, size.width, l.y(m.bottom) - top),
      Paint()..filterQuality = FilterQuality.medium,
    );
    for (final f in m.finds) {
      final r = l.find(f);
      if (r.bottom < -40 || r.top > size.height + 40) continue;
      _card(canvas, r, controller.lift(f.id, f.depth), l, (c, rect) {
        _glyph(c, f.kind, rect);
      }, label: f.label.inLanguage(language));
    }
    for (final s in m.ships) {
      final r = l.ship(s);
      if (r.bottom < -40 || r.top > size.height + 40) continue;
      _hull(
        canvas,
        s,
        r,
        controller.lift('ship-${s.yk}', s.depth, ship: true),
        l,
      );
    }
    canvas.restore();
    _gauge(canvas, l);
  }

  ui.Image _rasterise(Size size) {
    final m = controller.manifest;
    final l = SectionLayout(size, 0);
    final ratio = math.min(devicePixelRatio, 2.0);
    final height = l.y(m.bottom) - l.y(m.top);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(ratio)
      ..translate(0, -l.y(m.top));
    final hair = Paint()
      ..color = ink
      ..strokeWidth = .8
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTRB(0, l.y(m.top), size.width, l.y(m.bottom)),
      Paint()..color = paper,
    );
    for (final s in m.strata) {
      final band = Rect.fromLTRB(
        l.left,
        l.y(s.from),
        l.left + l.width,
        l.y(s.to),
      );
      canvas.drawRect(band, Paint()..color = _tint(s.hatch));
      canvas.save();
      canvas.clipRect(band);
      _hatch(canvas, s, band, l);
      canvas.restore();
      canvas.drawLine(band.topLeft, band.topRight, hair);
    }
    _seaLevel(canvas, l);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      (size.width * ratio).ceil(),
      (height * ratio).ceil(),
    );
    picture.dispose();
    return image;
  }

  Color _tint(String hatch) => switch (hatch) {
    'none' => paper,
    'rubble' => Color.alphaBlend(ink.withValues(alpha: .07), paper),
    'sand' => Color.alphaBlend(const Color(0x22C9A04C), paper),
    'stones' => Color.alphaBlend(ink.withValues(alpha: .12), paper),
    _ => Color.alphaBlend(const Color(0x1C4E1B2B), paper),
  };

  void _hatch(Canvas canvas, SectionStratum s, Rect band, SectionLayout l) {
    final pen = Paint()
      ..color = secondary.withValues(alpha: .55)
      ..strokeWidth = .7
      ..style = PaintingStyle.stroke;
    // Patterns are anchored to depth, not to the screen, so they scroll
    // with the section.
    final rng = math.Random(s.id.hashCode);
    final metresTop = s.from, metresBottom = s.to;
    switch (s.hatch) {
      case 'rubble':
        for (var d = metresTop; d > metresBottom; d -= .16) {
          final y = l.y(d);
          if (y < band.top - 10 || y > band.bottom + 10) {
            rng.nextDouble();
            continue;
          }
          for (
            var x = band.left + rng.nextDouble() * 14;
            x < band.right;
            x += 16 + rng.nextDouble() * 10
          ) {
            final w = 4 + rng.nextDouble() * 6, h = 3 + rng.nextDouble() * 4;
            canvas.drawPath(
              Path()
                ..moveTo(x, y)
                ..lineTo(x + w, y - h * .4)
                ..lineTo(x + w * .8, y + h * .6)
                ..lineTo(x + w * .1, y + h * .5)
                ..close(),
              pen,
            );
          }
        }
      case 'sand':
        final dot = Paint()..color = secondary.withValues(alpha: .5);
        for (var d = metresTop; d > metresBottom; d -= .055) {
          final y = l.y(d);
          if (y < band.top - 2 || y > band.bottom + 2) continue;
          final shift = (d * 97).floor().isEven ? 0.0 : 4.5;
          for (var x = band.left + shift; x < band.right; x += 9) {
            canvas.drawCircle(Offset(x, y), .7, dot);
          }
        }
      case 'stones':
        for (var d = metresTop; d > metresBottom; d -= .07) {
          final y = l.y(d);
          for (
            var x = band.left + (d * 53).abs() % 11;
            x < band.right;
            x += 13
          ) {
            canvas.drawCircle(Offset(x, y), 2.2, pen);
          }
        }
      case 'clay':
        for (var d = metresTop; d > metresBottom; d -= .05) {
          final y = l.y(d);
          if (y < band.top - 2 || y > band.bottom + 2) continue;
          final offset = (d * 41).abs() % 18;
          for (var x = band.left - offset; x < band.right; x += 18) {
            canvas.drawLine(Offset(x, y), Offset(x + 10, y), pen);
          }
        }
      default:
        _station(canvas, band, l);
    }
  }

  /// Today's station drawn in section: the ground line, a platform slab,
  /// two tracks.
  void _station(Canvas canvas, Rect band, SectionLayout l) {
    final pen = Paint()
      ..color = ink
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final ground = l.y(controller.manifest.top - .05);
    canvas.drawLine(
      Offset(band.left, ground),
      Offset(band.right, ground),
      pen..strokeWidth = 1.6,
    );
    final hall = Rect.fromLTRB(l.x(.18), l.y(1.9), l.x(.82), l.y(.75));
    canvas
      ..drawRect(hall, pen..strokeWidth = 1)
      ..drawRect(
        Rect.fromLTRB(
          hall.left,
          l.y(1.05),
          hall.left + hall.width * .44,
          l.y(.75),
        ),
        Paint()..color = ink.withValues(alpha: .18),
      );
    for (final u in [.6, .7]) {
      final x = l.x(u);
      canvas
        ..drawCircle(Offset(x - 6, l.y(.8)), 2.4, pen)
        ..drawCircle(Offset(x + 6, l.y(.8)), 2.4, pen);
    }
  }

  void _seaLevel(Canvas canvas, SectionLayout l) {
    final y = l.y(0);
    if (y < 0 || y > l.size.height) return;
    final dash = Paint()
      ..color = accent
      ..strokeWidth = 1;
    for (var x = l.left; x < l.left + l.width; x += 10) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 5, l.left + l.width), y),
        dash,
      );
    }
    _label(
      canvas,
      Offset(l.left + 4, y - 16),
      language == 'tr' ? '0 m · deniz seviyesi' : '0 m · sea level',
      accent,
    );
  }

  /// A cut-out card: its hole stays in the drawing; the card rises with
  /// [lift] and keeps the glyph.
  void _card(
    Canvas canvas,
    Rect r,
    double lift,
    SectionLayout l,
    void Function(Canvas, Rect) glyph, {
    String? label,
  }) {
    if (lift > .02) {
      canvas.drawRect(r, Paint()..color = ink.withValues(alpha: .22 * lift));
    }
    final raised = r.shift(l.raise(lift, parallax));
    canvas
      ..drawRect(raised, Paint()..color = paper)
      ..drawRect(
        raised,
        Paint()
          ..color = lift > .5 ? accent : ink
          ..strokeWidth = .8
          ..style = PaintingStyle.stroke,
      );
    glyph(canvas, raised.deflate(4));
    if (label != null && lift > .55) {
      // A card right of the middle hangs its label from its right edge,
      // clear of the gauge.
      final right = raised.center.dx > l.x(.55);
      _label(
        canvas,
        (right ? raised.bottomRight : raised.bottomLeft) + const Offset(0, 3),
        label,
        ink,
        maxWidth: l.width * .62,
        alignRight: right,
      );
    }
  }

  void _glyph(Canvas canvas, String kind, Rect r) {
    final pen = Paint()
      ..color = ink
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final c = r.center;
    switch (kind) {
      case 'grave':
        canvas
          ..drawOval(r.deflate(1), pen)
          ..drawArc(
            Rect.fromCenter(
              center: c,
              width: r.width * .5,
              height: r.height * .6,
            ),
            .4,
            4.6,
            false,
            pen,
          );
      case 'urn':
        for (final dx in [-r.width * .25, 0.0, r.width * .25]) {
          final o = c + Offset(dx, 0);
          canvas.drawPath(
            Path()
              ..moveTo(o.dx - 3, o.dy - 6)
              ..quadraticBezierTo(o.dx - 7, o.dy, o.dx - 2, o.dy + 6)
              ..lineTo(o.dx + 2, o.dy + 6)
              ..quadraticBezierTo(o.dx + 7, o.dy, o.dx + 3, o.dy - 6),
            pen,
          );
        }
      case 'footprints':
        for (var i = 0; i < 9; i++) {
          final x = r.left + 6 + i * (r.width - 12) / 8;
          final y = c.dy + (i.isEven ? -3 : 3);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, y), width: 5, height: 3),
            pen,
          );
        }
      case 'hut':
        for (var i = 0; i < 6; i++) {
          final x = r.left + 3 + i * (r.width - 6) / 5;
          canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), pen);
        }
        canvas.drawLine(r.centerLeft, r.centerRight, pen);
      case 'trees':
        for (final dx in [-r.width * .2, r.width * .2]) {
          final o = c + Offset(dx, 0);
          canvas
            ..drawLine(o + const Offset(0, -6), o + const Offset(0, 4), pen)
            ..drawLine(o + const Offset(0, 4), o + const Offset(-5, 7), pen)
            ..drawLine(o + const Offset(0, 4), o + const Offset(5, 7), pen);
        }
      default: // worked wood and rope
        canvas
          ..drawLine(r.centerLeft, r.centerRight, pen)
          ..drawCircle(c + Offset(r.width * .25, 0), 4, pen);
    }
  }

  void _hull(
    Canvas canvas,
    SectionShip s,
    Rect r,
    double lift,
    SectionLayout l,
  ) {
    Path hull(Rect b) {
      final p = Path()..moveTo(b.left, b.top);
      if (s.type == ShipType.galley) {
        p
          ..quadraticBezierTo(
            b.left + b.width * .1,
            b.bottom,
            b.center.dx,
            b.bottom,
          )
          ..quadraticBezierTo(
            b.right - b.width * .08,
            b.bottom,
            b.right,
            b.top,
          );
      } else {
        p
          ..quadraticBezierTo(
            b.left + b.width * .05,
            b.bottom,
            b.center.dx,
            b.bottom,
          )
          ..quadraticBezierTo(
            b.right - b.width * .05,
            b.bottom,
            b.right,
            b.top - b.height * .1,
          );
      }
      return p..close();
    }

    // The hull and its outline in the hull's own frame, made once per ship
    // and size (a dashed outline is many small paths).
    final (local, line) = _cache.hulls[(s.yk, r.size)] ??= () {
      final shape = hull(Offset.zero & r.size);
      if (s.type != null) return (shape, shape);
      // Type not itemised in the sources read: a dashed hull.
      final dashed = Path();
      for (final m in shape.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 6) {
          dashed.addPath(
            m.extractPath(d, math.min(d + 3, m.length)),
            Offset.zero,
          );
        }
      }
      return (shape, dashed);
    }();
    if (lift > .02) {
      canvas
        ..save()
        ..translate(r.left, r.top)
        ..drawPath(local, Paint()..color = ink.withValues(alpha: .25 * lift))
        ..restore();
    }
    final raised = r.shift(l.raise(lift, parallax));
    final outline = Paint()
      ..color = lift > .5 ? accent : ink
      ..strokeWidth = s.type == null ? .7 : 1
      ..style = PaintingStyle.stroke;
    canvas
      ..save()
      ..translate(raised.left, raised.top)
      ..drawPath(local, Paint()..color = paper)
      ..drawPath(line, outline)
      ..restore();
    if (s.type == ShipType.galley) {
      for (var i = 1; i < 10; i++) {
        final x = raised.left + raised.width * i / 10;
        canvas.drawLine(
          Offset(x, raised.top),
          Offset(x - 3, raised.top - 4),
          outline,
        );
      }
    }
    if (s.cargo) {
      final dot = Paint()..color = ink;
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(raised.left + raised.width * (.35 + i * .15), raised.top + 3),
          1.6,
          dot,
        );
      }
    }
    if (lift > .45) {
      _label(
        canvas,
        Offset(raised.left, raised.top - 14),
        'YK ${s.yk}',
        lift > .5 ? accent : ink,
      );
    }
  }

  void _gauge(Canvas canvas, SectionLayout l) {
    final m = controller.manifest;
    final x = l.size.width - l.gauge + 10;
    final rail = Paint()
      ..color = ink
      ..strokeWidth = 1;
    canvas.drawLine(Offset(x, 0), Offset(x, l.size.height), rail);
    for (var d = m.top.floor(); d >= m.bottom.ceil() - 1; d--) {
      final y = l.y(d.toDouble());
      if (y < -10 || y > l.size.height + 10) continue;
      canvas.drawLine(Offset(x, y), Offset(x + 8, y), rail);
      final label = d == 0 ? '0' : (d > 0 ? '+$d' : '−${-d}');
      _label(canvas, Offset(x + 11, y - 7), '$label m', secondary);
      final half = l.y(d - .5);
      canvas.drawLine(Offset(x, half), Offset(x + 4, half), rail);
    }
    // The reading line and its readout: depth and the stratum's years.
    final y = l.reading;
    final mark = Paint()
      ..color = accent
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(l.left, y),
      Offset(x + 8, y),
      mark..color = accent.withValues(alpha: .55),
    );
    final depth = controller.depth;
    final readout = depth.abs() < .05
        ? '0.0 m'
        : '${depth > 0 ? '+' : '−'}${depth.abs().toStringAsFixed(1)} m';
    final stratum = m.stratumAt(depth);
    final years = stratum.years.inLanguage(language);
    _label(
      canvas,
      Offset(l.left + 4, y + 4),
      '${language == 'tr' ? readout.replaceAll('.', ',') : readout} · $years',
      accent,
      background: true,
    );
  }

  void _label(
    Canvas canvas,
    Offset at,
    String s,
    Color colour, {
    double? maxWidth,
    bool background = false,
    bool alignRight = false,
  }) {
    TextPainter make() => TextPainter(
      text: TextSpan(
        text: s,
        style: text.copyWith(color: colour),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: maxWidth ?? 220);
    // The readout changes every frame; every other label is kept.
    final tp = background
        ? make()
        : _cache.labels[(s, colour, maxWidth)] ??= make();
    if (background) {
      canvas.drawRect(
        Rect.fromLTWH(at.dx - 3, at.dy - 1, tp.width + 6, tp.height + 2),
        Paint()..color = paper.withValues(alpha: .92),
      );
    }
    tp.paint(canvas, alignRight ? at - Offset(tp.width, 0) : at);
  }

  @override
  bool shouldRepaint(SectionPainter old) =>
      old.controller != controller ||
      old.language != language ||
      old.parallax != parallax ||
      old.ink != ink;
}

/// The ship under [point], if any (with its lift applied).
SectionShip? shipAt(SectionController c, Size size, Offset point) {
  final l = SectionLayout(size, c.depth);
  SectionShip? best;
  var bestD = double.infinity;
  for (final s in c.manifest.ships) {
    final r = l
        .ship(s)
        .shift(
          l.raise(c.lift('ship-${s.yk}', s.depth, ship: true), Offset.zero),
        )
        .inflate(10);
    if (r.contains(point)) {
      final d = (r.center - point).distance;
      if (d < bestD) {
        bestD = d;
        best = s;
      }
    }
  }
  return best;
}

/// The find under [point], if any.
SectionFind? findAt(SectionController c, Size size, Offset point) {
  final l = SectionLayout(size, c.depth);
  for (final f in c.manifest.finds) {
    final r = l
        .find(f)
        .shift(l.raise(c.lift(f.id, f.depth), Offset.zero))
        .inflate(8);
    if (r.contains(point)) return f;
  }
  return null;
}

/// What a section's painter keeps between frames: the rasterised ground, the
/// hulls' paths and the laid-out labels. Dropped when the size, colours or
/// language change.
class _SectionCache {
  Object? _key;
  ui.Image? ground;
  final hulls = <(int, Size), (Path, Path)>{};
  final labels = <(String, Color, double?), TextPainter>{};

  void check(SectionPainter p, Size size) {
    final key = (
      size,
      p.devicePixelRatio,
      p.ink,
      p.secondary,
      p.accent,
      p.paper,
      p.language,
      p.text,
    );
    if (key == _key) return;
    _key = key;
    ground?.dispose();
    ground = null;
    hulls.clear();
    for (final t in labels.values) {
      t.dispose();
    }
    labels.clear();
  }
}

final _caches = Expando<_SectionCache>('section painter cache');
