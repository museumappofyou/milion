import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';

PlanSymbol eraSymbol(Era era) => switch (era) {
  Era.ancient || Era.roman => PlanSymbol.column,
  Era.byzantine => PlanSymbol.dome,
  Era.medieval => PlanSymbol.gate,
  Era.ottoman => PlanSymbol.minaret,
  Era.modern => PlanSymbol.vitrine,
};

String eraLabel(BuildContext context, Era era) {
  final s = context.l10n;
  return switch (era) {
    Era.ancient => s.eraAncient,
    Era.roman => s.eraRoman,
    Era.byzantine => s.eraByzantine,
    Era.medieval => s.eraMedieval,
    Era.ottoman => s.eraOttoman,
    Era.modern => s.eraModern,
  };
}

/// One era plate: the credited photograph when a layer has media, otherwise a
/// drawn section diagram. The hero and only the hero shows these (the layer
/// text below keeps the credits as data).
class DigPlate extends StatelessWidget {
  const DigPlate({
    super.key,
    required this.stratum,
    required this.media,
    this.credit,
    this.height = 172,
  });
  final Stratum stratum;
  final Media? media;
  final String? credit;
  final double height;
  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context), s = context.l10n;
    final title = stratum.title.inLanguage(context.language);
    final years = stratum.toYear == null
        ? '${stratum.fromYear}–'
        : '${stratum.fromYear}–${stratum.toYear}';
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (media != null)
            Image.asset(media!.path, fit: BoxFit.cover)
          else
            CustomPaint(
              painter: _SectionDiagramPainter(
                accent: c.accent,
                line: c.line,
                ink: c.ink,
                ground: c.ground,
                poche: c.poche,
              ),
            ),
          if (media == null)
            Center(
              child: ExcludeSemantics(
                child: Container(
                  color: c.ground.withValues(alpha: .82),
                  padding: const EdgeInsets.all(12),
                  child: PlanIcon(
                    eraSymbol(stratum.era),
                    size: math.min(96, height * .55),
                    color: c.ink.withValues(alpha: .55),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            left: 16,
            child: Container(
              color: c.ground.withValues(alpha: .88),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '${s.digGaugeYear('${stratum.gaugeYear}')} · '
                '${eraLabel(context, stratum.era)}',
                style: TypeRole.measurement.copyWith(color: c.accent),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: c.ground.withValues(alpha: .88),
                border: Border(top: BorderSide(color: c.line)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  if (media != null) ...[
                    HonestyLabel(Honesty.ORIGINAL),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        credit ?? title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Text(
                        '${s.digDiagram} · $years',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The pinned hero: it crossfades to the layer under the reading line. With
/// reduced motion the swap is a cut (P05 acceptance).
class DigHero extends StatelessWidget {
  const DigHero({
    super.key,
    required this.stratum,
    required this.media,
    this.credit,
    this.height = 172,
  });
  final Stratum stratum;
  final Media? media;
  final String? credit;
  final double height;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: MotionToken.duration(MeasureMotion.dig, reduced: reduced),
      switchInCurve: MotionToken.curves[MeasureMotion.dig]!,
      switchOutCurve: MotionToken.curves[MeasureMotion.dig]!,
      child: DigPlate(
        key: ValueKey('plate-${stratum.id}'),
        stratum: stratum,
        media: media,
        credit: credit,
        height: height,
      ),
    );
  }
}

/// The drawn layer plate: a section marker, never a fake photograph.
class _SectionDiagramPainter extends CustomPainter {
  _SectionDiagramPainter({
    required this.accent,
    required this.line,
    required this.ink,
    required this.ground,
    required this.poche,
  });
  final Color accent, line, ink, ground, poche;
  @override
  void paint(Canvas canvas, Size size) {
    final background = Color.alphaBlend(poche.withValues(alpha: .45), ground);
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final hair = Paint()
      ..color = line.withValues(alpha: .5)
      ..strokeWidth = 1;
    for (var y = 16.0; y < size.height - 8; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hair);
    }

    // The layer itself: a hatched band across the section.
    final bandTop = size.height * .34, bandBottom = size.height * .62;
    final band = Rect.fromLTRB(0, bandTop, size.width, bandBottom);
    canvas.drawRect(band, Paint()..color = accent.withValues(alpha: .10));
    canvas.drawLine(
      Offset(0, bandTop),
      Offset(size.width, bandTop),
      Paint()
        ..color = accent
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(0, bandBottom),
      Offset(size.width, bandBottom),
      Paint()
        ..color = accent
        ..strokeWidth = 1,
    );
    final hatch = Paint()
      ..color = accent.withValues(alpha: .32)
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width + size.height; x += 9) {
      final top = Offset(x, bandBottom);
      final dy = bandBottom - bandTop;
      canvas.drawLine(top, Offset(x + dy, bandTop), hatch);
    }

    // The measured depth line on the left edge.
    final dimension = Paint()
      ..color = ink.withValues(alpha: .75)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(10, 12), Offset(10, size.height - 12),
        dimension);
    for (final y in [12.0, size.height - 12]) {
      canvas.drawLine(Offset(6, y), Offset(14, y), dimension);
    }
  }

  @override
  bool shouldRepaint(_SectionDiagramPainter old) =>
      old.accent != accent ||
      old.line != line ||
      old.ink != ink ||
      old.poche != poche;
}
