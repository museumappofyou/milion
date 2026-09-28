import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../l10n/strings.dart';

/// An inscriptional M with the gilded zero of the Milion stone held in its
/// vertex: M + 0, the zero-mile point of Constantinople.
/// Geometry matches tool/build_milion_identity.py (64-unit grid).
class MilionMark extends StatelessWidget {
  const MilionMark({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _MilionMarkPainter(MeasureColors.of(context).accent),
    ),
  );
}

class MilionWordmark extends StatelessWidget {
  const MilionWordmark({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.appTitle,
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MilionMark(size: 34),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.brandName,
                style: TypeRole.inscription(
                  24,
                  color: MeasureColors.of(context).ink,
                ).copyWith(letterSpacing: 3.2),
              ),
              if (!compact)
                Text(
                  TypeRole.capitals(context.l10n.tagline, context.language),
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 1.2,
                    color: MeasureColors.of(context).secondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MilionMarkPainter extends CustomPainter {
  _MilionMarkPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    canvas.drawCircle(
      const Offset(32, 35),
      5.175,
      Paint()
        ..color = Pigment.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.45,
    );
    canvas.drawPath(
      Path()
        ..moveTo(12, 51)
        ..lineTo(18.4, 51)
        ..lineTo(22.8, 17)
        ..lineTo(32, 31)
        ..lineTo(41.2, 17)
        ..lineTo(45.6, 51)
        ..lineTo(52, 51)
        ..lineTo(45.6, 12)
        ..lineTo(41.2, 12)
        ..lineTo(32, 27)
        ..lineTo(22.8, 12)
        ..lineTo(18.4, 12)
        ..close(),
      Paint()..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MilionMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
