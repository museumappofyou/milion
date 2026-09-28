import 'package:flutter/material.dart';

import '../content/models.dart';
import '../l10n/strings.dart';
import '../screens/anastasis_relief_screen.dart';
import '../screens/last_judgment_relief_screen.dart';
import '../theme/milion_theme.dart';
import 'components.dart';
import 'motion.dart';
import 'plan_icon.dart';
import 'theme.dart';
import 'tokens.dart';

String planLabel(BuildContext context, PlanSymbol icon) {
  final s = context.l10n;
  return switch (icon) {
    PlanSymbol.dome => s.iconDome,
    PlanSymbol.minaret => s.iconMinaret,
    PlanSymbol.column => s.iconColumn,
    PlanSymbol.gate => s.iconGate,
    PlanSymbol.cistern => s.iconCistern,
    PlanSymbol.vitrine => s.iconVitrine,
    PlanSymbol.route => s.iconRoute,
    PlanSymbol.tessera => s.iconTessera,
    PlanSymbol.cameraEye => s.iconCameraEye,
    PlanSymbol.sound => s.iconSound,
    PlanSymbol.light => s.iconLight,
    PlanSymbol.layers => s.iconLayers,
    PlanSymbol.story => s.iconStory,
  };
}

/// The same samples drive the hidden working sheet and individual goldens.
Map<String, Widget> designSamples(BuildContext context) {
  final s = context.l10n, c = MeasureColors.of(context);
  return {
    'milestone-numeral': const MilestoneNumeral('XLVII'),
    'milestone-collected': const MilestoneNumeral('IV', collected: true),
    'mil-distance': const MilDistance(5.9),
    for (final h in Honesty.values)
      'honesty-${h.name.toLowerCase()}': HonestyLabel(h),
    'strata-band': StrataBand(
      fromYear: 1315,
      toYear: 1321,
      title: s.stratumTitle,
      body: s.stratumBody,
    ),
    'depth-gauge': DepthGauge(
      years: const [2026, 1945, 1511, 1321],
      selectedYear: 1321,
      onSelected: (_) => MotionToken.detent(),
    ),
    'leader-line': LeaderLineCallout(
      caption: s.leaderCaption,
      child: ColoredBox(
        color: c.poche,
        child: const Center(child: PlanIcon(PlanSymbol.dome, size: 80)),
      ),
    ),
    for (final icon in PlanSymbol.values)
      'plan-${icon.name}': Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlanIcon(icon, semanticLabel: planLabel(context, icon)),
          const SizedBox(width: 16),
          Flexible(child: Text(planLabel(context, icon))),
        ],
      ),
    'scale-bar': const ScaleBar(),
    'north-arrow': const NorthArrow(),
    'tessera-loader': const TesseraLoader(animated: false),
    'tessera-chip': TesseraChip(s.saved, collected: true),
    'empty': const ContentState(),
    'error': ContentState(error: true, onAction: () {}),
    'dimension-sheet': Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DimensionHandle(),
        Text(s.sheetTitle),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => showDimensionSheet(context, child: Text(s.yourNote)),
          child: Text(s.openSheet),
        ),
      ],
    ),
  };
}

class DesignSheet extends StatelessWidget {
  const DesignSheet({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(s.designSheet)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.designIntro),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const TodayDirection(lampFirst: true),
                        ),
                      ),
                      child: Text(s.directionA),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              const TodayDirection(lampFirst: false),
                        ),
                      ),
                      child: Text(s.directionB),
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (final lamp in [false, true])
            for (final scale in [1.0, 2.0])
              Theme(
                data: lamp ? DesignTheme.lamp : DesignTheme.marble,
                child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: DesignGallery(lamp: lamp, scale: scale),
                ),
              ),
        ],
      ),
    );
  }
}

class DesignGallery extends StatelessWidget {
  const DesignGallery({super.key, required this.lamp, required this.scale});
  final bool lamp;
  final double scale;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n, c = MeasureColors.of(context);
    final pigments = [
      (s.porphyry, Pigment.porphyry),
      (s.tesseraGold, Pigment.gold),
      (s.marble, Pigment.marble),
      (s.lamp, Pigment.lamp),
      (s.cobalt, Pigment.cobalt),
      (s.bole, Pigment.bole),
      (s.turquoise, Pigment.turquoise),
      (s.verdigris, Pigment.verdigris),
      (s.bronze, Pigment.bronze),
    ];
    return ColoredBox(
      color: c.ground,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${lamp ? s.lamp : s.marble} · ${s.scalePercent('${(scale * 100).round()}')}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Text(
                s.paletteTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              for (final (label, color) in pigments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: c.line),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Text(label)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(s.gridLabel),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final space in [
                    Space.xs,
                    Space.sm,
                    Space.md,
                    Space.lg,
                    Space.xl,
                    Space.xxl,
                  ])
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: space, height: space, color: c.poche),
                        const SizedBox(height: 4),
                        Text('${space.toInt()}', style: TypeRole.measurement),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              for (final wave in [
                (s.waveByzantine, Pigment.byzantine),
                (s.waveMosque, Pigment.mosques),
                (s.waveMuseum, Pigment.museums),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 24, height: 24, color: wave.$2.ground),
                      Container(width: 24, height: 24, color: wave.$2.material),
                      const SizedBox(width: 16),
                      Expanded(child: Text(wave.$1)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Text(s.typeTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(s.displayRole, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                s.fontSpecimen,
                style: TypeRole.inscription(24, color: c.ink),
              ),
              const SizedBox(height: 24),
              Text(s.bodyRole, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(s.fontSpecimen),
              const SizedBox(height: 24),
              Text(
                s.componentsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final entry in designSamples(context).entries) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                entry.value,
              ],
              const SizedBox(height: 24),
              Text(
                s.motionTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(s.motionInfo),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => MotionToken.detent(),
                    child: Text(s.hapticDetent),
                  ),
                  OutlinedButton(
                    onPressed: () => MotionToken.collect(),
                    child: Text(s.hapticCollect),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Working composition trials only: route actions open the existing two plates.
class TodayDirection extends StatelessWidget {
  const TodayDirection({super.key, required this.lampFirst});
  final bool lampFirst;
  @override
  Widget build(BuildContext context) => Theme(
    data: lampFirst ? DesignTheme.lamp : DesignTheme.marble,
    child: Builder(
      builder: (context) {
        final s = context.l10n, c = MeasureColors.of(context);
        void open(Widget page) => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => page),
        );
        return Scaffold(
          appBar: AppBar(title: Text(lampFirst ? s.directionA : s.directionB)),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  const MilionWordmark(compact: true),
                  const Spacer(),
                  const NorthArrow(),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                color: lampFirst ? c.poche : Pigment.porphyry,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(88, 88),
                      painter: _DialPainter(Pigment.marble),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.mileZero,
                            style: TypeRole.inscription(
                              20,
                              color: Pigment.marble,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.fromMilion,
                            style: const TextStyle(color: Pigment.marble),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '0 · I · II · III',
                            style: TypeRole.measurement.copyWith(
                              color: Pigment.marble,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const HonestyLabel(Honesty.ORIGINAL),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => open(const AnastasisReliefScreen()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/anastasis/flat_reference.jpg',
                      fit: BoxFit.cover,
                      height: 240,
                      width: double.infinity,
                      semanticLabel: s.anastasis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MilestoneNumeral('I'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            s.anastasisHook,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(s.openAnastasis, style: TextStyle(color: c.accent)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              Text(s.focusChora, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => open(const LastJudgmentReliefScreen()),
                icon: const MilestoneNumeral('II', size: 24),
                label: Text(s.openJudgment),
              ),
              const SizedBox(height: 16),
              const ScaleBar(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    ),
  );
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final c = size.center(Offset.zero);
    for (final r in [12.0, 26.0, 40.0]) {
      canvas.drawCircle(c, r, p);
    }
    canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, size.height), p);
    canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), p);
    canvas.drawLine(c, const Offset(18, 18), p);
    canvas.drawRect(const Rect.fromLTWH(14, 14, 8, 8), p);
  }

  @override
  bool shouldRepaint(_DialPainter old) => color != old.color;
}
