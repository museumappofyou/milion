import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../content/geography.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../milestones/milestone_row.dart';
import '../services/progress_service.dart';
import '../shell/app_scope.dart';
import '../shell/navigation.dart';
import 'city_tab.dart';

/// The present-day header of a place. P05 grows this into the dig; until a
/// place is reviewed only its checked name, position and sources appear.
class PlaceScreen extends StatelessWidget {
  const PlaceScreen({super.key, required this.place});
  final Place place;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    final app = AppScope.of(context), registry = app.registry!;
    final theme = Theme.of(context);
    final m = fromMilion(place), p = place;
    final other = lang == 'tr' ? p.names.en : p.names.tr;
    final sources = [
      for (final id in p.sourceIds)
        registry.sources.firstWhere((x) => x.id == id),
    ];
    final checked = sources
        .where((x) => x.url.contains('wikidata.org'))
        .firstOrNull;
    final milestones = registry.register
        .where((x) => x.placeIds.contains(p.id))
        .toList();
    final artworks = registry.artworks.where((a) => a.placeId == p.id).length;
    final progress = ProgressScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(p.names.inLanguage(lang), maxLines: 2),
        actions: [
          if (app.placeRecognised(p.id))
            IconButton(
              key: const ValueKey('place-camera-eye'),
              tooltip: s.recognise,
              onPressed: () => openScan(context),
              icon: const PlanIcon(PlanSymbol.cameraEye),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatMilDistance(m.km, language: lang),
                  style: TypeRole.inscription(28, color: c.accent),
                ),
                if (m.bearing != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.bearing('${m.bearing!.round()}'),
                    style: TypeRole.measurement.copyWith(color: c.secondary),
                  ),
                ],
                const SizedBox(height: 16),
                if (other != null && other != p.names.inLanguage(lang))
                  Text(other, style: theme.textTheme.titleMedium),
                Text(
                  [
                    p.district?.spelling ?? s.outsideProvince,
                    ...p.categories.map((x) => categoryLabel(context, x)),
                  ].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
                if (p.historicalNames.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(s.historicalNames, style: theme.textTheme.titleMedium),
                  for (final n in p.historicalNames)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        [
                          n.name.inLanguage(lang),
                          if (n.greek != null) n.greek!,
                        ].join(' · '),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TesseraSlot(
                        state: p.review == ReviewStatus.draft
                            ? SlotState.planned
                            : SlotState.available,
                        width: 12,
                        height: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: p.review == ReviewStatus.reviewed
                          ? Text(p.hook.inLanguage(lang))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.notReviewed,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  s.placeDraftBody(
                                    p.qid,
                                    checked == null
                                        ? '—'
                                        : DateFormat.yMMMMd(lang)
                                              .format(checked.accessedAt),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (artworks > 0) ...[
            const SizedBox(height: 24),
            InkWell(
              key: const ValueKey('place-artworks'),
              onTap: () => openArtworks(context, p.id),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: c.line),
                    bottom: BorderSide(color: c.line),
                  ),
                ),
                child: Row(
                  children: [
                    const PlanIcon(PlanSymbol.vitrine),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        s.artworksHere('$artworks'),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (milestones.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(s.milestonesHere, style: theme.textTheme.titleMedium),
            ),
            for (final x in milestones)
              MilestoneRow(
                milestone: x,
                registry: registry,
                opened: progress.isOpened(x.id),
                onTap: () => openMilestone(context, x),
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(s.sourcesTitle, style: theme.textTheme.titleMedium),
          ),
          for (final x in sources)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(x.title.inLanguage(lang)),
                  SelectableText(x.url, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
