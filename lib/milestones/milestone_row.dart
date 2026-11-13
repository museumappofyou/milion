import 'package:flutter/material.dart';

import '../content/geography.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../design/components.dart';
import '../design/technique.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';

SlotState slotFor(
  Milestone m, {
  required bool opened,
  required bool playable,
}) => opened
    ? SlotState.set
    : playable
    ? SlotState.available
    : SlotState.planned;

String milestoneWhere(
  BuildContext context,
  ContentRegistry registry,
  Milestone m,
) {
  final s = context.l10n, lang = context.language;
  if (m.placeIds.isEmpty) {
    return m.packId == 'craft-kit' ? s.craftKit : s.acrossCity;
  }
  final place = registry.place(m.placeIds.first)!;
  return '${place.names.inLanguage(lang)} · ${formatMilDistance(fromMilion(place).km, language: lang)}';
}

String milestoneStatus(
  BuildContext context,
  Milestone m, {
  required bool opened,
}) {
  final s = context.l10n;
  if (opened) return s.statusOpened;
  return switch (m.status) {
    MilestoneStatus.planned => s.statusPlanned,
    MilestoneStatus.prototype => s.statusPrototype,
    MilestoneStatus.approved => s.statusApproved,
  };
}

/// One register entry: slot, numeral, title, place and mil, techniques,
/// the furthest honesty state and status.
class MilestoneRow extends StatelessWidget {
  const MilestoneRow({
    super.key,
    required this.milestone,
    required this.registry,
    required this.opened,
    required this.onTap,
  });
  final Milestone milestone;
  final ContentRegistry registry;
  final bool opened;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    final m = milestone,
        state = slotFor(
          m,
          opened: opened,
          playable: AppScope.of(context).playable(m),
        );
    return MergeSemantics(
      child: InkWell(
        key: ValueKey('milestone-${m.numeral}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: s.milestoneNumber(m.numeral),
                child: ExcludeSemantics(
                  child: TesseraSlot(
                    state: state,
                    label: m.numeral,
                    width: 56,
                    height: 48,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          m.title.inLanguage(lang),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: state == SlotState.planned
                                    ? c.secondary
                                    : c.ink,
                              ),
                        ),
                        if (m.flagship) const FlagshipMark(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      milestoneWhere(context, registry, m),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TechniqueIcons(m.techniques, size: 18),
                        HonestyRange(m.honesty),
                        Text(
                          milestoneStatus(context, m, opened: opened),
                          style: TypeRole.measurement.copyWith(
                            color: state == SlotState.planned
                                ? c.secondary
                                : c.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
