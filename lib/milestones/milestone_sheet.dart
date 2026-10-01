import 'package:flutter/material.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/technique.dart';
import '../first_run/first_run_screen.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import 'milestone_row.dart';

/// A planned piece: what it will be, where, with which techniques and labels.
Future<void> showMilestoneSheet(BuildContext context, Milestone m) {
  final registry = AppScope.of(context).registry!;
  return showDimensionSheet<void>(
    context,
    child: Builder(
      builder: (context) {
        final s = context.l10n, lang = context.language;
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TesseraSlot(
                  state: SlotState.planned,
                  label: m.numeral,
                  width: 56,
                  height: 48,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        m.title.inLanguage(lang),
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (m.flagship) const FlagshipMark(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(milestoneWhere(context, registry, m)),
            const SizedBox(height: 8),
            Text(s.milestonePlannedBody, style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            Text(s.techniques, style: theme.textTheme.titleMedium),
            for (final t in m.techniques)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    PlanIcon(techniqueSymbol(t)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text('${t.name} · ${techniqueLabel(context, t)}'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(s.labelsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final h in m.honesty) HonestyLabel(h)],
            ),
            if (m.number == 0) ...[
              const SizedBox(height: 24),
              Text(s.replayFirstRunBody, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  final navigator = Navigator.of(context)..pop();
                  replayFirstRun(navigator);
                },
                icon: const PlanIcon(PlanSymbol.dial),
                label: Text(s.replayFirstRun),
              ),
            ],
          ],
        );
      },
    ),
  );
}
