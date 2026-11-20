import 'package:flutter/material.dart';

import '../content/models.dart';
import '../content/registry.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../services/progress_service.dart';
import '../shell/app_scope.dart';
import '../shell/navigation.dart';
import 'chapters.dart';
import 'milestone_row.dart';
import 'playable_card.dart';

enum _RegisterFilter { playable, models3d, plates, walks, all }

/// The register, led by playable experiences first: visual cards for every
/// interactive Milestone and standalone 3D architectural study, with planned
/// Milestones tucked into collapsible chapter sections below.
class MilestonesTab extends StatefulWidget {
  const MilestonesTab({super.key});
  @override
  State<MilestonesTab> createState() => _MilestonesTabState();
}

class _MilestonesTabState extends State<MilestonesTab> with RestorationMixin {
  final _filterIndex = RestorableInt(0);
  final Set<String> _expandedPlanned = {};

  _RegisterFilter get _filter => _RegisterFilter.values[_filterIndex.value];

  @override
  String get restorationId => 'milestones';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_filterIndex, 'filter');
  }

  @override
  void dispose() {
    _filterIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, c = MeasureColors.of(context);
    final app = AppScope.of(context), registry = app.registry;
    final progress = ProgressScope.of(context);
    final register = registry?.register ?? const <Milestone>[];
    final playableMilestones = [
      for (final m in register)
        if (app.playable(m)) m,
    ];
    final standaloneStudies = app.standaloneStudies;
    final openedCount = playableMilestones
        .where((m) => progress.isOpened(m.id))
        .length;

    final models3dMilestones = [
      for (final m in playableMilestones)
        if (app.playableKind(m) == PlayableKind.space) m,
    ];
    final plateMilestones = [
      for (final m in playableMilestones)
        if (app.playableKind(m) == PlayableKind.plate) m,
    ];
    final walkSectionMilestones = [
      for (final m in playableMilestones)
        if (const {
          PlayableKind.walk,
          PlayableKind.section,
          PlayableKind.strip,
          PlayableKind.map,
        }.contains(app.playableKind(m)))
          m,
    ];
    final chapters = chaptersOf(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.navMilestones)),
      body: registry == null
          ? const SizedBox.shrink()
          : CustomScrollView(
              restorationId: 'register-scroll',
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.registerCounts(
                            '${register.length}',
                            '${playableMilestones.length}',
                            '${register.where((m) => m.status == MilestoneStatus.approved).length}',
                            '${register.where((m) => m.status == MilestoneStatus.planned).length}',
                          ),
                          key: const ValueKey('register-counts'),
                          style: TypeRole.measurement.copyWith(
                            fontSize: 13,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.playableCountSummary(
                            '${playableMilestones.length}',
                            '$openedCount',
                          ),
                          style: TypeRole.measurement.copyWith(
                            fontSize: 12,
                            color: c.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: Space.radius,
                          child: SizedBox(
                            height: 4,
                            child: LinearProgressIndicator(
                              value: playableMilestones.isEmpty
                                  ? 0
                                  : openedCount / playableMilestones.length,
                              backgroundColor: c.poche,
                              valueColor: const AlwaysStoppedAnimation(
                                Pigment.gold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Row(
                      children: [
                        for (final item in [
                          (
                            _RegisterFilter.playable,
                            s.filterPlayable,
                            playableMilestones.length,
                          ),
                          (
                            _RegisterFilter.models3d,
                            s.filter3dModels,
                            models3dMilestones.length,
                          ),
                          (
                            _RegisterFilter.plates,
                            s.filterReliefPlates,
                            plateMilestones.length,
                          ),
                          (
                            _RegisterFilter.walks,
                            s.filterWalksSections,
                            walkSectionMilestones.length,
                          ),
                          (
                            _RegisterFilter.all,
                            s.filterAllRegister('${register.length}'),
                            null,
                          ),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              key: ValueKey(
                                'milestones-filter-${item.$1.name}',
                              ),
                              showCheckmark: false,
                              selected: _filter == item.$1,
                              label: Text(
                                item.$3 == null
                                    ? item.$2
                                    : '${item.$2} · ${item.$3}',
                              ),
                              onSelected: (_) => setState(
                                () => _filterIndex.value = item.$1.index,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                ...switch (_filter) {
                  _RegisterFilter.playable => [
                    SliverList.list(
                      children: [
                        for (final m in playableMilestones)
                          PlayableMilestoneCard(
                            milestone: m,
                            registry: registry,
                            opened: progress.isOpened(m.id),
                            onTap: () => openMilestone(context, m),
                          ),
                      ],
                    ),
                    if (standaloneStudies.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _SectionBand(
                          title: s.standaloneStudiesTitle,
                          subtitle: s.standaloneStudiesSubtitle,
                          count: standaloneStudies.length,
                          symbol: PlanSymbol.assembly,
                        ),
                      ),
                      SliverList.list(
                        children: [
                          for (final study in standaloneStudies)
                            SpaceStudyCard(
                              study: study,
                              registry: registry,
                              onTap: () => openStudy(context, study),
                            ),
                        ],
                      ),
                    ],
                    SliverToBoxAdapter(
                      child: _SectionBand(
                        title: s.upcomingRegisterTitle,
                        count: register.length - playableMilestones.length,
                        symbol: PlanSymbol.milestone,
                      ),
                    ),
                    for (final chapter in chapters)
                      ..._plannedChapterSlivers(
                        context,
                        chapter: chapter,
                        planned: [
                          for (final m in register)
                            if (chapter.contains(m) && !app.playable(m)) m,
                        ],
                        registry: registry,
                        progress: progress,
                      ),
                  ],
                  _RegisterFilter.models3d => [
                    SliverList.list(
                      children: [
                        for (final m in models3dMilestones)
                          PlayableMilestoneCard(
                            milestone: m,
                            registry: registry,
                            opened: progress.isOpened(m.id),
                            onTap: () => openMilestone(context, m),
                          ),
                        for (final study in standaloneStudies)
                          SpaceStudyCard(
                            study: study,
                            registry: registry,
                            onTap: () => openStudy(context, study),
                          ),
                      ],
                    ),
                  ],
                  _RegisterFilter.plates => [
                    SliverList.list(
                      children: [
                        for (final m in plateMilestones)
                          PlayableMilestoneCard(
                            milestone: m,
                            registry: registry,
                            opened: progress.isOpened(m.id),
                            onTap: () => openMilestone(context, m),
                          ),
                      ],
                    ),
                  ],
                  _RegisterFilter.walks => [
                    SliverList.list(
                      children: [
                        for (final m in walkSectionMilestones)
                          PlayableMilestoneCard(
                            milestone: m,
                            registry: registry,
                            opened: progress.isOpened(m.id),
                            onTap: () => openMilestone(context, m),
                          ),
                      ],
                    ),
                  ],
                  _RegisterFilter.all => [
                    for (final chapter in chapters) ...[
                      SliverToBoxAdapter(
                        child: ChapterBand(
                          chapter: chapter,
                          pieces: register.where(chapter.contains).toList(),
                        ),
                      ),
                      SliverList.list(
                        children: [
                          for (final m in register.where(chapter.contains))
                            app.playable(m)
                                ? PlayableMilestoneCard(
                                    milestone: m,
                                    registry: registry,
                                    opened: progress.isOpened(m.id),
                                    onTap: () => openMilestone(context, m),
                                  )
                                : MilestoneRow(
                                    milestone: m,
                                    registry: registry,
                                    opened: progress.isOpened(m.id),
                                    onTap: () => openMilestone(context, m),
                                  ),
                        ],
                      ),
                    ],
                    if (standaloneStudies.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _SectionBand(
                          title: s.standaloneStudiesTitle,
                          subtitle: s.standaloneStudiesSubtitle,
                          count: standaloneStudies.length,
                          symbol: PlanSymbol.assembly,
                        ),
                      ),
                      SliverList.list(
                        children: [
                          for (final study in standaloneStudies)
                            SpaceStudyCard(
                              study: study,
                              registry: registry,
                              onTap: () => openStudy(context, study),
                            ),
                        ],
                      ),
                    ],
                  ],
                },
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  List<Widget> _plannedChapterSlivers(
    BuildContext context, {
    required Chapter chapter,
    required List<Milestone> planned,
    required ContentRegistry registry,
    required MilestoneProgress progress,
  }) {
    if (planned.isEmpty) return const [];
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    final open = _expandedPlanned.contains(chapter.numeral);
    return [
      SliverToBoxAdapter(
        child: InkWell(
          key: ValueKey('planned-chapter-${chapter.numeral}'),
          onTap: () => setState(() {
            if (open) {
              _expandedPlanned.remove(chapter.numeral);
            } else {
              _expandedPlanned.add(chapter.numeral);
            }
          }),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: open ? c.poche.withValues(alpha: .55) : c.ground,
              border: Border(
                top: BorderSide(color: c.line.withValues(alpha: .6)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: chapter.ground,
                    border: Border.all(color: chapter.material, width: 1.5),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TypeRole.capitals(
                          s.chapterHeading(chapter.numeral, chapter.name),
                          lang,
                        ),
                        style: TypeRole.inscription(14, color: c.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.upcomingChapterCount('${planned.length}'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  open ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: c.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
      if (open)
        SliverList.list(
          children: [
            for (final m in planned)
              MilestoneRow(
                milestone: m,
                registry: registry,
                opened: progress.isOpened(m.id),
                onTap: () => openMilestone(context, m),
              ),
          ],
        ),
    ];
  }
}

class _SectionBand extends StatelessWidget {
  const _SectionBand({
    required this.title,
    this.subtitle,
    required this.count,
    required this.symbol,
  });

  final String title;
  final String? subtitle;
  final int count;
  final PlanSymbol symbol;

  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context), lang = context.language;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: c.poche.withValues(alpha: .45),
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: PlanIcon(symbol, size: 18, color: c.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    '${TypeRole.capitals(title, lang)} · $count',
                    style: TypeRole.inscription(15, color: c.ink),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
