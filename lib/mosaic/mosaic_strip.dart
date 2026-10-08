import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../l10n/strings.dart';
import '../milestones/milestone_row.dart';
import '../shell/app_scope.dart';

/// One tessera per register entry: gold when opened, outlined when planned.
class MosaicStrip extends StatelessWidget {
  const MosaicStrip({
    super.key,
    required this.register,
    required this.opened,
    this.onTap,
  });
  final List<Milestone> register;
  final Set<String> opened;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final count = register.where((m) => opened.contains(m.id)).length;
    final next =
        register
            .where(
              (m) =>
                  !opened.contains(m.id) &&
                  slotFor(
                        m,
                        opened: false,
                        playable:
                            AppScope.of(context).plates.forMilestone(m) != null,
                      ) ==
                      SlotState.available,
            )
            .firstOrNull ??
        register.where((m) => !opened.contains(m.id)).firstOrNull;
    final progress = s.mosaicProgress('$count', '${register.length}');
    return Semantics(
      button: onTap != null,
      label: progress,
      child: InkWell(
        key: const ValueKey('mosaic-strip'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: LayoutBuilder(
                builder: (context, box) {
                  // Two courses of tesserae, like a mosaic border.
                  const gap = 3.0, perRow = 24;
                  final w = (box.maxWidth - gap * (perRow - 1)) / perRow;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final m in register)
                        TesseraSlot(
                          state: slotFor(
                            m,
                            opened: opened.contains(m.id),
                            playable:
                                AppScope.of(context).plates.forMilestone(m) !=
                                null,
                          ),
                          width: w,
                          height: math.max(14, w * 1.3),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: Text(
                progress,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (next != null)
              Text(
                s.mosaicNext(next.numeral, next.title.inLanguage(lang)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
