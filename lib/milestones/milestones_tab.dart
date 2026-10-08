import 'package:flutter/material.dart';

import '../content/models.dart';
import '../l10n/strings.dart';
import '../services/progress_service.dart';
import '../shell/app_scope.dart';
import '../shell/navigation.dart';
import 'chapters.dart';
import 'milestone_row.dart';

/// The numbered register (§3), chapter by chapter. Planned pieces are
/// outlined tessera slots.
class MilestonesTab extends StatelessWidget {
  const MilestonesTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final registry = AppScope.of(context).registry;
    final progress = ProgressScope.of(context);
    final register = registry?.register ?? const <Milestone>[];
    return Scaffold(
      appBar: AppBar(title: Text(s.navMilestones)),
      body: registry == null
          ? const SizedBox.shrink()
          : CustomScrollView(
              restorationId: 'register-scroll',
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Text(
                      s.registerCounts(
                        '${register.length}',
                        '${register.where((m) => AppScope.of(context).plates.forMilestone(m) != null).length}',
                        '${register.where((m) => m.status == MilestoneStatus.approved).length}',
                        '${register.where((m) => m.status == MilestoneStatus.planned).length}',
                      ),
                    ),
                  ),
                ),
                for (final chapter in chaptersOf(context)) ...[
                  SliverToBoxAdapter(
                    child: ChapterBand(
                      chapter: chapter,
                      pieces: register.where(chapter.contains).toList(),
                    ),
                  ),
                  SliverList.list(
                    children: [
                      for (final m in register.where(chapter.contains))
                        MilestoneRow(
                          milestone: m,
                          registry: registry,
                          opened: progress.isOpened(m.id),
                          onTap: () => openMilestone(context, m),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
