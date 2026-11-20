import 'package:flutter/material.dart';

import '../content/geography.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../design/components.dart';
import '../design/technique.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import 'playable_card.dart';

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
    // Review debt stays visible (Decisions 2026-09-27): a prototype opens,
    // but it is not shown as finished until the owner approves it.
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
        app = AppScope.of(context),
        kind = app.playableKind(m),
        state = slotFor(m, opened: opened, playable: kind != null);
    return MergeSemantics(
      child: InkWell(
        key: ValueKey('milestone-${m.numeral}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.line.withValues(alpha: .55)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Semantics(
                label: s.milestoneNumber(m.numeral),
                child: ExcludeSemantics(
                  child: TesseraSlot(
                    state: state,
                    label: m.numeral,
                    width: 52,
                    height: 44,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (kind != null) ...[
                      PlayableTypeTag.forKind(context, kind),
                      const SizedBox(height: 3),
                    ],
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
                        if (m.flagship) const FlagshipMark(size: 12),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      milestoneWhere(context, registry, m),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (state == SlotState.planned)
                          TechniqueIcons(m.techniques, size: 16),
                        HonestyRange(m.honesty),
                        Text(
                          milestoneStatus(context, m, opened: opened),
                          style: TypeRole.measurement.copyWith(
                            fontSize: 11,
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
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: state == SlotState.planned ? c.line : c.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
