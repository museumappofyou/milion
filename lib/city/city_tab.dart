import 'package:flutter/material.dart';

import '../content/geography.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import '../shell/navigation.dart';

PlanSymbol categorySymbol(Place p) {
  final c = p.categories.where((c) => c != Category.byzantine).firstOrNull;
  return switch (c) {
    Category.mosque => PlanSymbol.minaret,
    Category.museum => PlanSymbol.vitrine,
    Category.palace || Category.fortification => PlanSymbol.gate,
    Category.cistern => PlanSymbol.cistern,
    Category.tower => PlanSymbol.column,
    Category.bazaar => PlanSymbol.route,
    Category.bath => PlanSymbol.dome,
    Category.other => PlanSymbol.milestone,
    Category.byzantine || null => PlanSymbol.dome,
  };
}

String categoryLabel(BuildContext context, Category c) {
  final s = context.l10n;
  return switch (c) {
    Category.byzantine => s.categoryByzantine,
    Category.mosque => s.categoryMosque,
    Category.museum => s.categoryMuseum,
    Category.palace => s.categoryPalace,
    Category.fortification => s.categoryFortification,
    Category.cistern => s.categoryCistern,
    Category.tower => s.categoryTower,
    Category.bazaar => s.categoryBazaar,
    Category.bath => s.categoryBath,
    Category.other => s.categoryOther,
  };
}

/// Places by mil distance until the P10 Atlas.
class CityTab extends StatelessWidget {
  const CityTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    final registry = AppScope.of(context).registry;
    final places = registry?.plottablePlaces ?? const <Place>[];
    final reviewed = places
        .where((p) => p.review == ReviewStatus.reviewed)
        .length;
    return Scaffold(
      appBar: AppBar(title: Text(s.navCity)),
      body: CustomScrollView(
        restorationId: 'city-scroll',
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.cityTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(s.plottedPlaces('${places.length}', '$reviewed')),
                  const SizedBox(height: 4),
                  Text(
                    s.straightLine,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: places.length,
            itemBuilder: (context, i) {
              final p = places[i], m = fromMilion(p);
              final draft = p.review == ReviewStatus.draft;
              return MergeSemantics(
                child: InkWell(
                  onTap: () => openPlace(context, p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.line)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PlanIcon(categorySymbol(p)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.names.inLanguage(lang),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  p.district?.spelling,
                                  ...p.categories.map(
                                    (c) => categoryLabel(context, c),
                                  ),
                                ].whereType<String>().join(' · '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 12,
                                children: [
                                  MilDistance(m.km),
                                  if (m.bearing != null)
                                    Text(
                                      '${m.bearing!.round()}°',
                                      style: TypeRole.measurement.copyWith(
                                        color: c.secondary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: draft ? s.notReviewed : s.reviewed,
                          child: TesseraSlot(
                            state: draft
                                ? SlotState.planned
                                : SlotState.available,
                            width: 12,
                            height: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
