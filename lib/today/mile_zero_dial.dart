import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../content/geography.dart';
import '../content/models.dart';
import '../design/motion.dart';
import '../design/tokens.dart';
import '../first_run/peninsula_data.dart';
import '../l10n/strings.dart';

class DialPlace {
  DialPlace(this.place) : measurement = fromMilion(place);
  final Place place;
  final MileMeasurement measurement;
  double get km => measurement.km;
  double get bearing => measurement.bearing ?? 0;
  bool get reviewed => place.review == ReviewStatus.reviewed;
}

/// Plottable places around mile zero, ordered clockwise from true north.
List<DialPlace> dialPlaces(Iterable<Place> places) => [
  for (final p in places)
    if (fromMilion(p).bearing != null) DialPlace(p),
]..sort((a, b) => a.bearing.compareTo(b.bearing));

/// Logarithmic, so the peninsula and the province share one plate; the
/// [knee] keeps the first Roman miles wide. Every ring carries its true value.
abstract final class DialScale {
  static const rings = [1, 2, 3, 5, 10, 20, 50];
  static const outerMiles = 50.0;
  static const knee = .35; // km
  static double unit(double km) => math.min(
    1,
    math.log(1 + km / knee) / math.log(1 + outerMiles * romanMileKm / knee),
  );
  static Offset point(double km, double bearing) {
    final a = bearing * math.pi / 180, u = unit(km);
    return Offset(math.sin(a) * u, -math.cos(a) * u);
  }

  /// The OSM coastline in the same projection, computed once.
  static final List<List<Offset>> coast = [
    for (final line in peninsulaCoast)
      [
        for (var i = 0; i + 1 < line.length; i += 2)
          point(
            math.sqrt(line[i] * line[i] + line[i + 1] * line[i + 1]) / 1000,
            math.atan2(line[i].toDouble(), line[i + 1].toDouble()) *
                180 /
                math.pi,
          ),
      ],
  ];
}

/// The Mile Zero dial: a fixed plate of Roman-mile rings and place ticks by
/// true bearing, with a rotating index (the rete) that detents at each place.
class MileZeroDial extends StatefulWidget {
  const MileZeroDial({
    super.key,
    required this.places,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
  });
  final List<DialPlace> places;
  final int selected;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onOpen;
  @override
  State<MileZeroDial> createState() => MileZeroDialState();
}

class MileZeroDialState extends State<MileZeroDial>
    with SingleTickerProviderStateMixin {
  late double _angle = _bearing(widget.selected);
  late final AnimationController _settle = AnimationController(vsync: this)
    ..addListener(() {
      final t = _tween;
      if (t != null) {
        setState(
          () => _angle = t.transform(
            MotionToken.curves[MeasureMotion.settle]!.transform(_settle.value),
          ),
        );
      }
    });
  Tween<double>? _tween;
  Size _size = Size.zero;

  /// Current index angle in degrees clockwise from true north.
  double get angle => _angle % 360;

  double _bearing(int i) =>
      widget.places.isEmpty ? 0 : widget.places[i].bearing;

  @override
  void didUpdateWidget(MileZeroDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected &&
        _nearest(_angle) != widget.selected) {
      _settleTo(widget.selected);
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  static double _delta(double from, double to) => (to - from + 540) % 360 - 180;

  int _nearest(double angle) {
    var best = 0;
    for (var i = 1; i < widget.places.length; i++) {
      if (_delta(angle, widget.places[i].bearing).abs() <
          _delta(angle, widget.places[best].bearing).abs()) {
        best = i;
      }
    }
    return best;
  }

  void _settleTo(int i) {
    final target = _bearing(i);
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _settle.stop();
      setState(() => _angle = target);
      return;
    }
    _tween = Tween(begin: _angle, end: _angle + _delta(_angle, target));
    _settle
      ..duration = MotionToken.durations[MeasureMotion.settle]
      ..forward(from: 0);
  }

  void _choose(int i) {
    if (i == widget.selected) return;
    MotionToken.detent();
    widget.onSelected(i);
  }

  /// One detent forward or back, as TalkBack's increase/decrease actions.
  void step(int by) {
    if (widget.places.isEmpty) return;
    final i = (widget.selected + by) % widget.places.length;
    _choose(i);
    _settleTo(i);
  }

  double? _touchAngle(Offset local) {
    final v = local - _size.center(Offset.zero);
    if (v.distance < 16) return null;
    return (math.atan2(v.dx, -v.dy) * 180 / math.pi + 360) % 360;
  }

  int? _tickAt(Offset local) {
    final g = _DialGeometry(_size);
    int? best;
    var bestDistance = 24.0;
    for (var i = 0; i < widget.places.length; i++) {
      final d = (g.tick(widget.places[i]) - local).distance;
      if (d < bestDistance) {
        best = i;
        bestDistance = d;
      }
    }
    return best;
  }

  void _dragTo(Offset local, Offset previous) {
    final a = _touchAngle(local), b = _touchAngle(previous);
    if (a == null || b == null) return;
    setState(() => _angle += _delta(b, a));
    _choose(_nearest(_angle));
  }

  void _tap(TapUpDetails details) {
    final tick = _tickAt(details.localPosition);
    if (tick == null) return;
    _choose(tick);
    _settleTo(tick);
    widget.onOpen(tick);
  }

  String _value(BuildContext context, int i) {
    final p = widget.places[i];
    return context.l10n.dialValue(
      p.place.names.inLanguage(context.language),
      formatMilDistance(p.km, language: context.language),
      '${p.bearing.round()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, c = MeasureColors.of(context);
    final n = widget.places.length;
    return Semantics(
      label: s.dialLabel,
      hint: s.dialHint,
      value: n == 0 ? null : _value(context, widget.selected),
      increasedValue: n == 0
          ? null
          : _value(context, (widget.selected + 1) % n),
      decreasedValue: n == 0
          ? null
          : _value(context, (widget.selected - 1 + n) % n),
      onIncrease: n == 0 ? null : () => step(1),
      onDecrease: n == 0 ? null : () => step(-1),
      onTap: n == 0 ? null : () => widget.onOpen(widget.selected),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _size = Size.square(constraints.biggest.shortestSide);
            return RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: {
                TapGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                      TapGestureRecognizer.new,
                      (r) => r.onTapUp = _tap,
                    ),
                _TurnRecognizer:
                    GestureRecognizerFactoryWithHandlers<_TurnRecognizer>(
                      () => _TurnRecognizer(this),
                      (_) {},
                    ),
              },
              child: CustomPaint(
                size: _size,
                painter: _DialPainter(
                  places: widget.places,
                  selected: widget.selected,
                  angle: _angle,
                  colors: c,
                  north: s.northLetter,
                  letters: [s.eastLetter, s.southLetter, s.westLetter],
                  scaler: MediaQuery.textScalerOf(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Turning the ring is circular motion: a drag that starts on the plate and
/// moves mostly along the circle turns the rete; one that moves mostly
/// towards or away from the centre is left to the page scroll.
class _TurnRecognizer extends OneSequenceGestureRecognizer {
  _TurnRecognizer(this.dial);
  final MileZeroDialState dial;
  Offset? _start, _last;
  bool _turning = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    final from = event.localPosition - dial._size.center(Offset.zero);
    final radius = dial._size.shortestSide / 2;
    if (from.distance < radius * .2 || from.distance > radius) return;
    startTrackingPointer(event.pointer, event.transform);
    _start = _last = event.localPosition;
    _turning = false;
  }

  @override
  void handleEvent(PointerEvent event) {
    final start = _start;
    if (start == null) return;
    if (event is PointerMoveEvent) {
      if (_turning) {
        dial._dragTo(event.localPosition, _last!);
        _last = event.localPosition;
        return;
      }
      final moved = event.localPosition - start;
      if (moved.distance < kTouchSlop * .6) return;
      final out = start - dial._size.center(Offset.zero);
      final u = out / out.distance;
      final radial = (moved.dx * u.dx + moved.dy * u.dy).abs();
      final along = (moved.dx * -u.dy + moved.dy * u.dx).abs();
      if (along > radial) {
        _turning = true;
        dial._settle.stop();
        resolve(GestureDisposition.accepted);
        dial._dragTo(event.localPosition, start);
        _last = event.localPosition;
      } else {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(event.pointer);
        _start = null;
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_turning) dial._settleTo(dial.widget.selected);
      _turning = false;
      _start = null;
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    if (_turning) dial._settleTo(dial.widget.selected);
    _turning = false;
    _start = null;
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'turn the Mile Zero dial';
}

class _DialGeometry {
  _DialGeometry(Size size)
    : center = size.center(Offset.zero),
      radius = size.shortestSide / 2 - 34;
  final Offset center;
  final double radius;
  Offset at(double unitRadius, double degrees) {
    final a = degrees * math.pi / 180;
    return center + Offset(math.sin(a), -math.cos(a)) * unitRadius * radius;
  }

  Offset tick(DialPlace p) =>
      center + DialScale.point(p.km, p.bearing) * radius;
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.places,
    required this.selected,
    required this.angle,
    required this.colors,
    required this.north,
    required this.letters,
    required this.scaler,
  });
  final List<DialPlace> places;
  final int selected;
  final double angle;
  final MeasureColors colors;
  final String north;
  final List<String> letters;
  final TextScaler scaler;

  void _text(Canvas canvas, String text, Offset at, Color color, double size) {
    final p = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: scaler.clamp(maxScaleFactor: 1.5),
      text: TextSpan(
        text: text,
        style: TypeRole.measurement.copyWith(color: color, fontSize: size),
      ),
    )..layout();
    p.paint(canvas, at - Offset(p.width / 2, p.height / 2));
    p.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = _DialGeometry(size), c = g.center, r = g.radius;
    final line = Paint()
      ..color = colors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Coastline, warped by the same radial scale as the rings.
    final coast = Paint()
      ..color = colors.line.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final shore in DialScale.coast) {
      final path = Path()
        ..moveTo(c.dx + shore[0].dx * r, c.dy + shore[0].dy * r);
      for (final p in shore.skip(1)) {
        path.lineTo(c.dx + p.dx * r, c.dy + p.dy * r);
      }
      canvas.drawPath(path, coast);
    }
    // Plate: Roman-mile rings, labelled along the north line.
    canvas.drawLine(c, g.at(1, 0), line);
    for (final miles in DialScale.rings) {
      final u = DialScale.unit(miles * romanMileKm);
      canvas.drawCircle(c, u * r, line);
      _text(
        canvas,
        romanNumeral(miles),
        c + Offset(9, -u * r - 6),
        colors.secondary,
        10,
      );
    }
    // Limb: degree scale, every 10°, long at 30°, letters at the cardinals.
    canvas.drawCircle(c, r + 6, line);
    canvas.drawCircle(c, r + 16, line);
    for (var d = 0; d < 360; d += 10) {
      final long = d % 30 == 0;
      canvas.drawLine(
        c +
            Offset(math.sin(d * math.pi / 180), -math.cos(d * math.pi / 180)) *
                (r + 6),
        c +
            Offset(math.sin(d * math.pi / 180), -math.cos(d * math.pi / 180)) *
                (r + (long ? 16 : 11)),
        line,
      );
    }
    for (final (i, letter) in [north, ...letters].indexed) {
      _text(
        canvas,
        letter,
        c +
            Offset(math.sin(i * math.pi / 2), -math.cos(i * math.pi / 2)) *
                (r + 26),
        colors.ink,
        11,
      );
    }
    // Places as radial ticks by bearing.
    for (var i = 0; i < places.length; i++) {
      if (i == selected) continue;
      final p = places[i], at = g.tick(p);
      final dir = (at - c).distance == 0
          ? Offset.zero
          : (at - c) / (at - c).distance;
      canvas.drawLine(
        at - dir * 2.5,
        at + dir * 2.5,
        Paint()
          ..color = p.reviewed
              ? colors.accent
              : colors.ink.withValues(alpha: .7)
          ..strokeWidth = p.reviewed ? 1.5 : 1,
      );
    }
    final accent = Paint()
      ..color = colors.accent
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    if (places.isNotEmpty) {
      final p = places[selected], at = g.tick(p);
      final dir = (at - c).distance == 0
          ? Offset.zero
          : (at - c) / (at - c).distance;
      canvas.drawLine(at - dir * 7, at + dir * 7, accent..strokeWidth = 2);
      canvas.drawRect(
        Rect.fromCenter(center: at, width: 9, height: 9),
        accent..strokeWidth = 1,
      );
    }
    // Rete: the index arm and its pointer, turned by the thumb.
    final tip = g.at(1, angle);
    canvas.drawLine(c, g.at((r + 16) / r, angle), accent..strokeWidth = 1.25);
    final a = angle * math.pi / 180;
    final out = Offset(math.sin(a), -math.cos(a)),
        side = Offset(-out.dy, out.dx);
    final base = c + out * (r + 24);
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx + out.dx * 16, tip.dy + out.dy * 16)
        ..lineTo(base.dx + side.dx * 5, base.dy + side.dy * 5)
        ..lineTo(base.dx - side.dx * 5, base.dy - side.dy * 5)
        ..close(),
      Paint()..color = colors.accent,
    );
    // Mile zero: the gilded tessera at the pivot.
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 3.5, c.dy - 3)
        ..lineTo(c.dx + 3.5, c.dy - 3.5)
        ..lineTo(c.dx + 3, c.dy + 3.5)
        ..lineTo(c.dx - 3.5, c.dy + 3)
        ..close(),
      Paint()..color = Pigment.gold,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.angle != angle ||
      old.selected != selected ||
      old.places != places ||
      old.colors != colors ||
      old.scaler != scaler ||
      old.north != north;
}
