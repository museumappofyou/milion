import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../city/city_tab.dart' show categoryLabel, categorySymbol;
import '../city/external_links.dart';
import '../content/geography.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import 'atlas_assets.dart';
import 'atlas_controller.dart';
import 'atlas_map.dart' show atlasEraCaption, atlasYearLabel;
import 'historic.dart';

/// The sheet a marker opens: what the place is, when it stood, how far it is
/// and the two ways on: its dig, or walking directions in Google Maps.
class AtlasPlaceSheet extends StatelessWidget {
  const AtlasPlaceSheet({
    super.key,
    required this.place,
    required this.assets,
    required this.controller,
  });
  final Place place;
  final AtlasAssets assets;
  final AtlasController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final theme = Theme.of(context);
    final colors = MeasureColors.of(context);
    final p = place;
    final sourced = assets.years.sourced(p);
    final from = assets.years.standsFrom(p);
    final clock = AppScope.maybeOf(context)?.clock ?? DateTime.now;
    final open = isOpenAt(p.visit?.weekly ?? const [], clock());
    final me = controller.meCoordinates;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlanIcon(categorySymbol(p)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.names.inLanguage(context.language),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              [
                p.district?.spelling,
                ...p.categories.map((c) => categoryLabel(context, c)),
              ].whereType<String>().join(' · '),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                MilDistance(fromMilion(p).km),
                if (me != null)
                  Text(
                    s.atlasDistanceFromMe(
                      formatMilDistance(
                        measure(me, p.coordinates).km,
                        language: context.language,
                      ),
                    ),
                    style: TypeRole.measurement.copyWith(
                      color: colors.secondary,
                    ),
                  ),
                Text(
                  sourced != null
                      ? s.atlasStandingSince(atlasYearLabel(context, sourced))
                      : s.atlasStandingByEra(atlasYearLabel(context, from)),
                  style: theme.textTheme.bodySmall,
                ),
                if (open != null)
                  Text(
                    open ? s.atlasOpenNow : s.atlasClosedNow,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: open ? Pigment.verdigris : colors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('atlas-sheet-open'),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(s.atlasOpenDig),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  key: const ValueKey('atlas-sheet-go'),
                  onPressed: () => launchUrl(
                    walkingDirectionsUri(p),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const PlanIcon(PlanSymbol.route, size: 18),
                  label: Text(s.digGo),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// What the map draws at the chosen year, layer by layer: each historic
/// feature with its dates, how sure its line is, a note and its sources.
/// Also the map data's attribution. Reachable from the controls, and so by
/// TalkBack, which cannot read lines on a canvas.
class AtlasLayersSheet extends StatelessWidget {
  const AtlasLayersSheet({
    super.key,
    required this.assets,
    required this.year,
    required this.below,
  });
  final AtlasAssets assets;
  final int year;
  final bool below;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final lang = context.language;
    final theme = Theme.of(context);
    final colors = MeasureColors.of(context);
    final registry = AppScope.maybeOf(context)?.registry;
    String certainty(Certainty c) => switch (c) {
      Certainty.surviving => s.atlasCertaintySurviving,
      Certainty.traced => s.atlasCertaintyTraced,
      Certainty.approximate => s.atlasCertaintyApproximate,
      Certainty.conjectural => s.atlasCertaintyConjectural,
    };
    String span(HistoricFeature f) {
      if (f.layer == HistoricLayer.hills) return '';
      final from = atlasYearLabel(context, f.from);
      if (f.to == null) return '$from–';
      if (f.to == f.from) return from;
      return '$from–${atlasYearLabel(context, f.to!)}';
    }

    final shown = [
      for (final f in assets.historic.features)
        if ((f.layer == HistoricLayer.below) == below &&
            f.presence(year.toDouble()) > .5)
          f,
    ];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .6,
      maxChildSize: .95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Text(s.atlasHistoricSources, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${atlasYearLabel(context, year)} · '
            '${atlasEraCaption(context, atlasYears.indexOf(year).clamp(0, atlasYears.length - 1))}',
            style: theme.textTheme.bodySmall,
          ),
          for (final f in shown)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.line)),
              ),
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.layer == HistoricLayer.hills
                          ? f.note.inLanguage(lang).split(RegExp(r'[:,]')).first
                          : f.names.inLanguage(lang),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        span(f),
                        certainty(f.certainty),
                      ].where((t) => t.isNotEmpty).join(' · '),
                      style: TypeRole.measurement.copyWith(
                        color: colors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.note.inLanguage(lang),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        for (final id in f.sourceIds)
                          registry?.source(id)?.title.inLanguage(lang) ?? id,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.secondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(s.atlasAttribution, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
