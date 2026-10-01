import 'package:flutter/widgets.dart';

import '../content/models.dart';
import '../l10n/strings.dart';
import 'plan_icon.dart';

/// One plan glyph per §3 technique code.
PlanSymbol techniqueSymbol(Technique t) => switch (t) {
  Technique.DP => PlanSymbol.parallax,
  Technique.GL => PlanSymbol.gilded,
  Technique.RL => PlanSymbol.raking,
  Technique.PU => PlanSymbol.popup,
  Technique.WR => PlanSymbol.wipe,
  Technique.SB => PlanSymbol.story,
  Technique.MM => PlanSymbol.flow,
  Technique.SR => PlanSymbol.stroke,
  Technique.LU => PlanSymbol.lookUp,
  Technique.CA => PlanSymbol.assembly,
  Technique.CS => PlanSymbol.section,
  Technique.WK => PlanSymbol.cistern,
  Technique.TT => PlanSymbol.turntable,
  Technique.TM => PlanSymbol.timeModel,
  Technique.SK => PlanSymbol.sky,
  Technique.VO => PlanSymbol.sound,
};

String techniqueLabel(BuildContext context, Technique t) {
  final s = context.l10n;
  return switch (t) {
    Technique.DP => s.techDP,
    Technique.GL => s.techGL,
    Technique.RL => s.techRL,
    Technique.PU => s.techPU,
    Technique.WR => s.techWR,
    Technique.SB => s.techSB,
    Technique.MM => s.techMM,
    Technique.SR => s.techSR,
    Technique.LU => s.techLU,
    Technique.CA => s.techCA,
    Technique.CS => s.techCS,
    Technique.WK => s.techWK,
    Technique.TT => s.techTT,
    Technique.TM => s.techTM,
    Technique.SK => s.techSK,
    Technique.VO => s.techVO,
  };
}

/// A row of technique glyphs announced once as a list.
class TechniqueIcons extends StatelessWidget {
  const TechniqueIcons(this.techniques, {super.key, this.size = 20});
  final Iterable<Technique> techniques;
  final double size;
  @override
  Widget build(BuildContext context) {
    final list = techniques.toList()..sort((a, b) => a.index - b.index);
    return Semantics(
      label: context.l10n.techniqueList(
        list.map((t) => techniqueLabel(context, t)).join(', '),
      ),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 8,
          children: [
            for (final t in list) PlanIcon(techniqueSymbol(t), size: size),
          ],
        ),
      ),
    );
  }
}
