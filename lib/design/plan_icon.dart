import 'dart:math' as math;

import 'package:flutter/material.dart';

enum PlanSymbol {
  dome,
  minaret,
  column,
  gate,
  cistern,
  vitrine,
  route,
  tessera,
  cameraEye,
  sound,
  light,
  layers,
  story,
  // P04 shell destinations.
  dial,
  milestone,
  // P04 technique glyphs for the §3 codes without an existing symbol.
  parallax,
  gilded,
  raking,
  popup,
  wipe,
  flow,
  stroke,
  lookUp,
  assembly,
  section,
  turntable,
  timeModel,
  sky,
}

/// Architectural linework on a shared 24-unit plan grid; no icon font.
class PlanIcon extends StatelessWidget {
  const PlanIcon(
    this.symbol, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });
  final PlanSymbol symbol;
  final double size;
  final Color? color;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    image: semanticLabel != null,
    child: ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _PlanPainter(
          symbol,
          color ??
              IconTheme.of(context).color ??
              Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}

class _PlanPainter extends CustomPainter {
  _PlanPainter(this.symbol, this.color);
  final PlanSymbol symbol;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.25
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;
    void line(double x, double y, double a, double b) =>
        canvas.drawLine(Offset(x, y), Offset(a, b), p);
    void rect(double x, double y, double w, double h) =>
        canvas.drawRect(Rect.fromLTWH(x, y, w, h), p);
    switch (symbol) {
      case PlanSymbol.dome:
        rect(4, 4, 16, 16);
        canvas.drawCircle(const Offset(12, 12), 7, p);
        line(12, 2, 12, 22);
        line(2, 12, 22, 12);
      case PlanSymbol.minaret:
        rect(9, 8, 6, 13);
        line(8, 8, 16, 8);
        line(8, 15, 16, 15);
        canvas.drawPath(
          Path()
            ..moveTo(9, 8)
            ..lineTo(12, 2)
            ..lineTo(15, 8),
          p,
        );
      case PlanSymbol.column:
        rect(7, 3, 10, 3);
        rect(9, 6, 6, 12);
        rect(6, 18, 12, 3);
        line(12, 7, 12, 17);
      case PlanSymbol.gate:
        rect(3, 4, 4, 17);
        rect(17, 4, 4, 17);
        line(7, 4, 17, 4);
        line(7, 8, 17, 8);
        canvas.drawArc(
          const Rect.fromLTWH(7, 11, 10, 10),
          math.pi,
          math.pi,
          false,
          p,
        );
        line(7, 16, 7, 21);
        line(17, 16, 17, 21);
      case PlanSymbol.cistern:
        rect(3, 3, 18, 18);
        for (final x in [7.0, 12.0, 17.0]) {
          for (final y in [7.0, 12.0, 17.0]) {
            canvas.drawCircle(Offset(x, y), 1, p);
          }
        }
      case PlanSymbol.vitrine:
        rect(4, 4, 16, 14);
        line(2, 21, 22, 21);
        line(7, 18, 7, 21);
        line(17, 18, 17, 21);
        canvas.drawPath(
          Path()
            ..moveTo(8, 14)
            ..lineTo(12, 7)
            ..lineTo(16, 14)
            ..close(),
          p,
        );
      case PlanSymbol.route:
        canvas.drawPath(
          Path()
            ..moveTo(4, 20)
            ..lineTo(4, 12)
            ..lineTo(18, 12)
            ..lineTo(18, 4),
          p,
        );
        rect(2, 18, 4, 4);
        canvas.drawCircle(const Offset(18, 4), 2, p);
      case PlanSymbol.tessera:
        for (final o in [
          const Offset(3, 3),
          const Offset(13, 3),
          const Offset(3, 13),
        ]) {
          canvas.drawPath(
            Path()
              ..moveTo(o.dx, o.dy + 1)
              ..lineTo(o.dx + 7, o.dy)
              ..lineTo(o.dx + 8, o.dy + 8)
              ..lineTo(o.dx + 1, o.dy + 7)
              ..close(),
            p,
          );
        }
        rect(14, 14, 6, 6);
      case PlanSymbol.cameraEye:
        rect(3, 5, 18, 14);
        canvas.drawPath(
          Path()
            ..moveTo(5, 12)
            ..quadraticBezierTo(12, 4, 19, 12)
            ..quadraticBezierTo(12, 20, 5, 12),
          p,
        );
        canvas.drawCircle(const Offset(12, 12), 2, p);
      case PlanSymbol.sound:
        line(4, 8, 4, 16);
        line(7, 5, 7, 19);
        for (final r in [6.0, 10.0, 14.0]) {
          canvas.drawArc(
            Rect.fromCircle(center: const Offset(6, 12), radius: r),
            -.65,
            1.3,
            false,
            p,
          );
        }
      case PlanSymbol.light:
        canvas.drawCircle(const Offset(12, 12), 4, p);
        for (var n = 0; n < 8; n++) {
          final a = n * math.pi / 4;
          line(
            12 + 7 * math.cos(a),
            12 + 7 * math.sin(a),
            12 + 10 * math.cos(a),
            12 + 10 * math.sin(a),
          );
        }
      case PlanSymbol.layers:
        for (final y in [5.0, 10.0, 15.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(3, y)
              ..lineTo(12, y + 4)
              ..lineTo(21, y),
            p,
          );
        }
      case PlanSymbol.story:
        rect(5, 3, 14, 18);
        line(8, 7, 16, 7);
        line(8, 11, 16, 11);
        line(8, 15, 13, 15);
        line(3, 5, 3, 19);
      case PlanSymbol.dial:
        canvas.drawCircle(const Offset(12, 12), 9.5, p);
        canvas.drawCircle(const Offset(12, 12), 5, p);
        rect(11, 11, 2, 2);
        line(12, 11, 16.5, 3.5);
        line(12, 1, 12, 3);
      case PlanSymbol.milestone:
        canvas.drawArc(
          const Rect.fromLTWH(8, 3, 8, 4),
          math.pi,
          math.pi,
          false,
          p,
        );
        line(8, 5, 8, 18);
        line(16, 5, 16, 18);
        rect(6, 18, 12, 3);
        line(10, 10, 14, 10);
        line(12, 10, 12, 14);
        line(10, 14, 14, 14);
      case PlanSymbol.parallax:
        rect(3, 8, 12, 12);
        rect(9, 3, 12, 12);
        line(3, 8, 9, 3);
        line(15, 20, 21, 15);
      case PlanSymbol.gilded:
        canvas.drawPath(
          Path()
            ..moveTo(4, 11)
            ..lineTo(14, 10)
            ..lineTo(15, 20)
            ..lineTo(5, 21)
            ..close(),
          p,
        );
        line(16, 8, 20, 4);
        line(17, 11, 22, 11);
        line(13, 7, 13, 2);
      case PlanSymbol.raking:
        line(2, 4, 10, 12);
        line(6, 2, 14, 10);
        canvas.drawPath(
          Path()
            ..moveTo(2, 20)
            ..quadraticBezierTo(6, 13, 10, 18)
            ..quadraticBezierTo(14, 22, 17, 16)
            ..lineTo(22, 20),
          p,
        );
      case PlanSymbol.popup:
        line(2, 21, 22, 21);
        rect(4, 11, 5, 10);
        rect(10, 5, 5, 16);
        rect(16, 13, 5, 8);
      case PlanSymbol.wipe:
        rect(3, 5, 18, 14);
        line(12, 2, 12, 22);
        // Hatched half: the reconstruction side of the wipe.
        line(3, 9, 7, 5);
        line(3, 13, 11, 5);
        line(3, 17, 12, 8);
        line(5, 19, 12, 12);
        line(9, 19, 12, 16);
      case PlanSymbol.flow:
        for (final y in [7.0, 12.0, 17.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(3, y)
              ..quadraticBezierTo(7.5, y - 3, 12, y)
              ..quadraticBezierTo(16.5, y + 3, 21, y),
            p,
          );
        }
      case PlanSymbol.stroke:
        canvas.drawArc(
          const Rect.fromLTWH(3, 6, 18, 24),
          math.pi * 1.05,
          math.pi * .85,
          false,
          p,
        );
        canvas.drawCircle(const Offset(4, 17), 1.5, p);
        canvas.drawPath(
          Path()
            ..moveTo(19, 9)
            ..lineTo(22, 5)
            ..lineTo(20, 4)
            ..close(),
          p,
        );
      case PlanSymbol.lookUp:
        canvas.drawCircle(const Offset(12, 12), 9.5, p);
        canvas.drawCircle(const Offset(12, 12), 3, p);
        for (var n = 0; n < 8; n++) {
          final a = n * math.pi / 4;
          line(
            12 + 3 * math.cos(a),
            12 + 3 * math.sin(a),
            12 + 9.5 * math.cos(a),
            12 + 9.5 * math.sin(a),
          );
        }
      case PlanSymbol.assembly:
        rect(4, 18, 16, 3);
        rect(6, 11, 12, 4);
        canvas.drawArc(
          const Rect.fromLTWH(7, 3, 10, 10),
          math.pi,
          math.pi,
          false,
          p,
        );
        line(7, 8, 17, 8);
      case PlanSymbol.section:
        line(2, 18, 22, 18);
        canvas.drawArc(
          const Rect.fromLTWH(3, 6, 18, 24),
          math.pi,
          math.pi,
          false,
          p,
        );
        canvas.drawArc(
          const Rect.fromLTWH(6, 9, 12, 18),
          math.pi,
          math.pi,
          false,
          p,
        );
        line(3, 18, 6, 15);
        line(18, 15, 21, 18);
        line(12, 2, 12, 5);
      case PlanSymbol.turntable:
        canvas.drawOval(const Rect.fromLTWH(3, 15, 18, 6), p);
        rect(10, 6, 4, 11);
        canvas.drawArc(
          const Rect.fromLTWH(2, 9, 20, 9),
          math.pi * .1,
          math.pi * .8,
          false,
          p,
        );
      case PlanSymbol.timeModel:
        line(4, 3, 4, 21);
        for (final y in [6.0, 12.0, 18.0]) {
          line(2, y, 4, y);
          line(7, y, 21, y);
        }
        line(7, 9, 15, 9);
        line(7, 15, 18, 15);
      case PlanSymbol.sky:
        line(2, 19, 22, 19);
        canvas.drawArc(
          const Rect.fromLTWH(4, 6, 16, 26),
          math.pi,
          math.pi,
          false,
          p,
        );
        canvas.drawCircle(const Offset(16, 8.5), 2.5, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlanPainter old) =>
      old.symbol != symbol || old.color != color;
}
