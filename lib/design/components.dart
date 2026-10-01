import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/geography.dart';
import '../content/models.dart';
import '../l10n/strings.dart';
import 'motion.dart';
import 'plan_icon.dart';
import 'tokens.dart';

class MilestoneNumeral extends StatelessWidget {
  const MilestoneNumeral(
    this.numeral, {
    super.key,
    this.size = 32,
    this.collected = false,
  });
  final String numeral;
  final double size;
  final bool collected;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.milestoneNumber(numeral),
    child: ExcludeSemantics(
      child: Container(
        color: collected ? Pigment.porphyry : null,
        padding: collected
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : EdgeInsets.zero,
        child: Text(
          numeral,
          style: TypeRole.inscription(
            size,
            color: collected ? Pigment.gold : MeasureColors.of(context).accent,
          ),
        ),
      ),
    ),
  );
}

class MilDistance extends StatelessWidget {
  const MilDistance(this.km, {super.key});
  final double km;
  @override
  Widget build(BuildContext context) => Text(
    formatMilDistance(km, language: context.language),
    style: TypeRole.measurement.copyWith(
      color: MeasureColors.of(context).secondary,
    ),
  );
}

class HonestyLabel extends StatelessWidget {
  const HonestyLabel(this.honesty, {super.key});
  final Honesty honesty;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final (label, description) = switch (honesty) {
      Honesty.ORIGINAL => (s.original, s.originalDescription),
      Honesty.DEPTH => (s.depth, s.depthDescription),
      Honesty.RECONSTRUCTION => (s.reconstruction, s.reconstructionDescription),
      Honesty.IMAGINED => (s.imagined, s.imaginedDescription),
    };
    return Tooltip(
      message: description,
      child: Semantics(
        label: '$label. $description',
        child: ExcludeSemantics(
          child: TesseraChip(TypeRole.capitals(label, context.language)),
        ),
      ),
    );
  }
}

/// How far a piece departs from the photograph: ORIGINAL, then the furthest
/// state it reaches (§3 rule 1: everything starts from the original).
class HonestyRange extends StatelessWidget {
  const HonestyRange(this.labels, {super.key});
  final Set<Honesty> labels;
  @override
  Widget build(BuildContext context) {
    final furthest = labels.reduce((a, b) => a.index >= b.index ? a : b);
    if (furthest == Honesty.ORIGINAL) {
      return const HonestyLabel(Honesty.ORIGINAL);
    }
    final s = context.l10n;
    return Semantics(
      label: s.honestyRange(s.original, switch (furthest) {
        Honesty.ORIGINAL => s.original,
        Honesty.DEPTH => s.depth,
        Honesty.RECONSTRUCTION => s.reconstruction,
        Honesty.IMAGINED => s.imagined,
      }),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const HonestyLabel(Honesty.ORIGINAL),
            CustomPaint(
              size: const Size(16, 8),
              painter: _ArrowPainter(MeasureColors.of(context).secondary),
            ),
            HonestyLabel(furthest),
          ],
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 4, y - 3)
        ..lineTo(size.width, y)
        ..lineTo(size.width - 4, y + 3),
      p,
    );
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

class TesseraChip extends StatelessWidget {
  const TesseraChip(this.label, {super.key, this.collected = false});
  final String label;
  final bool collected;
  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context);
    return CustomPaint(
      foregroundPainter: _TesseraEdge(
        c.line,
        MediaQuery.devicePixelRatioOf(context),
      ),
      child: Container(
        color: collected ? Pigment.gold : null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TypeRole.measurement.copyWith(
            color: collected ? Pigment.lamp : c.ink,
          ),
        ),
      ),
    );
  }
}

/// The irregular one-physical-pixel tessera outline shared by chips and slots.
Path tesseraPath(Size size, double dpr) {
  final n = 1 / dpr;
  return Path()
    ..moveTo(n, n * 2)
    ..lineTo(size.width * .55, n)
    ..lineTo(size.width - n, n * 2)
    ..lineTo(size.width - n * 2, size.height * .55)
    ..lineTo(size.width - n, size.height - n * 2)
    ..lineTo(size.width * .3, size.height - n)
    ..lineTo(n, size.height - n * 2)
    ..lineTo(n * 2, size.height * .4)
    ..close();
}

class _TesseraEdge extends CustomPainter {
  _TesseraEdge(this.color, this.dpr, {this.fill});
  final Color color;
  final Color? fill;
  final double dpr;
  @override
  void paint(Canvas canvas, Size size) {
    final path = tesseraPath(size, dpr);
    if (fill != null) canvas.drawPath(path, Paint()..color = fill!);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 / dpr,
    );
  }

  @override
  bool shouldRepaint(_TesseraEdge old) =>
      old.color != color || old.dpr != dpr || old.fill != fill;
}

enum SlotState {
  /// Not built yet: an outlined, empty slot.
  planned,

  /// Playable but not opened by this person.
  available,

  /// Opened: set in tessera gold.
  set,
}

/// A mosaic slot. Unfilled slots are outlined tesserae (§2, signature 6).
class TesseraSlot extends StatelessWidget {
  const TesseraSlot({
    super.key,
    required this.state,
    this.width = 48,
    this.height = 48,
    this.label,
  });
  final SlotState state;
  final double width, height;
  final String? label;
  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context);
    final (fill, edge, ink) = switch (state) {
      SlotState.planned => (null, c.line, c.secondary),
      SlotState.available => (c.poche, c.ink, c.accent),
      SlotState.set => (Pigment.gold, Pigment.gold, Pigment.lamp),
    };
    return CustomPaint(
      painter: _TesseraEdge(
        edge,
        MediaQuery.devicePixelRatioOf(context),
        fill: fill,
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: label == null
            ? null
            : Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      label!,
                      style: TypeRole.inscription(16, color: ink),
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// An eight-pointed star, the ★ of the §3 register, drawn not typed.
class FlagshipMark extends StatelessWidget {
  const FlagshipMark({super.key, this.size = 14});
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.flagship,
    child: CustomPaint(
      size: Size.square(size),
      painter: _StarPainter(MeasureColors.of(context).accent),
    ),
  );
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.shortestSide / 2;
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 - math.pi / 2;
      final d = i.isEven ? r : r * .45;
      final p = c + Offset(math.cos(a), math.sin(a)) * d;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

class StrataBand extends StatelessWidget {
  const StrataBand({
    super.key,
    required this.fromYear,
    this.toYear,
    required this.title,
    required this.body,
  });
  final int fromYear;
  final int? toYear;
  final String title, body;
  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.line),
          left: BorderSide(color: c.accent, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            toYear == null ? '$fromYear' : '$fromYear–$toYear',
            style: TypeRole.measurement.copyWith(color: c.accent),
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    );
  }
}

class DepthGauge extends StatelessWidget {
  const DepthGauge({
    super.key,
    required this.years,
    required this.selectedYear,
    this.onSelected,
  });
  final List<int> years;
  final int selectedYear;
  final ValueChanged<int>? onSelected;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final year in years)
        Semantics(
          selected: year == selectedYear,
          child: InkWell(
            onTap: onSelected == null
                ? null
                : () {
                    MotionToken.detent();
                    onSelected!(year);
                  },
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: year == selectedYear ? 24 : 12,
                    height: 1,
                    color: MeasureColors.of(context).accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$year',
                    style: TypeRole.measurement.copyWith(
                      color: MeasureColors.of(context).ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class LeaderLineCallout extends StatelessWidget {
  const LeaderLineCallout({
    super.key,
    required this.child,
    required this.caption,
    this.anchor = const Offset(.4, .4),
    this.height = 200,
  });
  final Widget child;
  final String caption;
  final Offset anchor;
  final double height;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: height,
        child: CustomPaint(
          foregroundPainter: _LeaderPainter(
            anchor,
            MeasureColors.of(context).ink,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24, right: 48),
            child: SizedBox.expand(child: child),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Text(caption, style: Theme.of(context).textTheme.bodySmall),
      ),
    ],
  );
}

class _LeaderPainter extends CustomPainter {
  _LeaderPainter(this.anchor, this.color);
  final Offset anchor;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final at = Offset(anchor.dx * (s.width - 48), anchor.dy * (s.height - 24));
    c.drawPath(
      Path()
        ..moveTo(at.dx, at.dy)
        ..lineTo(s.width - 24, s.height - 32)
        ..lineTo(s.width - 24, s.height - 12)
        ..lineTo(24, s.height - 12)
        ..lineTo(24, s.height),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    c.drawLine(
      at - const Offset(3, 0),
      at + const Offset(3, 0),
      Paint()
        ..color = color
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_LeaderPainter old) =>
      old.anchor != anchor || old.color != color;
}

class ScaleBar extends StatelessWidget {
  const ScaleBar({super.key, this.metres = 10, this.width = 120});
  final int metres;
  final double width;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CustomPaint(
        size: Size(width, 12),
        painter: _ScalePainter(MeasureColors.of(context).ink),
      ),
      Text(
        context.l10n.scaleDistance('$metres'),
        style: TypeRole.measurement.copyWith(
          color: MeasureColors.of(context).ink,
        ),
      ),
    ],
  );
}

class _ScalePainter extends CustomPainter {
  _ScalePainter(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color;
    c.drawRect(Rect.fromLTWH(0, 4, s.width / 2, 4), p);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 1;
    c.drawRect(Rect.fromLTWH(0, 4, s.width, 4), p);
    for (final x in [0.0, s.width / 2, s.width]) {
      c.drawLine(Offset(x, 0), Offset(x, 12), p);
    }
  }

  @override
  bool shouldRepaint(_ScalePainter old) => color != old.color;
}

class NorthArrow extends StatelessWidget {
  const NorthArrow({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.north,
    child: ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.northLetter, style: TypeRole.measurement),
          CustomPaint(
            size: const Size(24, 40),
            painter: _NorthPainter(MeasureColors.of(context).ink),
          ),
        ],
      ),
    ),
  );
}

class _NorthPainter extends CustomPainter {
  _NorthPainter(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    c.drawPath(
      Path()
        ..moveTo(12, 2)
        ..lineTo(4, 26)
        ..lineTo(12, 21)
        ..close(),
      p,
    );
    p.style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(12, 2)
        ..lineTo(20, 26)
        ..lineTo(12, 21)
        ..close(),
      p,
    );
    c.drawLine(const Offset(12, 21), const Offset(12, 38), p);
  }

  @override
  bool shouldRepaint(_NorthPainter old) => color != old.color;
}

class TesseraLoader extends StatefulWidget {
  const TesseraLoader({super.key, this.animated = true});
  final bool animated;
  @override
  State<TesseraLoader> createState() => _TesseraLoaderState();
}

class _TesseraLoaderState extends State<TesseraLoader>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 960),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animated && !MediaQuery.disableAnimationsOf(context)) {
      _clock.repeat();
    } else {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.loading,
    liveRegion: true,
    child: AnimatedBuilder(
      animation: _clock,
      builder: (context, _) => CustomPaint(
        size: const Size(40, 40),
        painter: _LoaderPainter(
          MeasureColors.of(context).accent,
          widget.animated ? _clock.value : .6,
        ),
      ),
    ),
  );
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter(this.color, this.phase);
  final Color color;
  final double phase;
  @override
  void paint(Canvas c, Size s) {
    for (var i = 0; i < 4; i++) {
      final p = Paint()
        ..color = color
        ..style = i <= phase * 4 ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1;
      final x = (i % 2) * 22.0, y = (i ~/ 2) * 22.0;
      c.drawPath(
        Path()
          ..moveTo(x, y + 1)
          ..lineTo(x + 16, y)
          ..lineTo(x + 17, y + 17)
          ..lineTo(x + 1, y + 16)
          ..close(),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_LoaderPainter old) =>
      phase != old.phase || color != old.color;
}

class ContentState extends StatelessWidget {
  const ContentState({
    super.key,
    this.error = false,
    this.title,
    this.message,
    this.onAction,
    this.actionLabel,
  });
  final bool error;
  final String? title, message, actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlanIcon(error ? PlanSymbol.vitrine : PlanSymbol.story, size: 32),
        const SizedBox(height: 16),
        Text(
          title ?? (error ? context.l10n.errorTitle : context.l10n.emptyTitle),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          message ?? (error ? context.l10n.errorBody : context.l10n.emptyBody),
        ),
        if (onAction != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel ?? context.l10n.retry),
            ),
          ),
      ],
    ),
  );
}

class DimensionHandle extends StatelessWidget {
  const DimensionHandle({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.dimensionHandle,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CustomPaint(
          size: const Size(72, 12),
          painter: _ScalePainter(MeasureColors.of(context).line),
        ),
      ),
    ),
  );
}

class DimensionSheet extends StatelessWidget {
  const DimensionSheet({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const DimensionHandle(), child],
        ),
      ),
    ),
  );
}

Future<T?> showDimensionSheet<T>(
  BuildContext context, {
  required Widget child,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  builder: (context) => DimensionSheet(child: child),
);
