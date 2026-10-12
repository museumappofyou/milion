import 'package:flutter/material.dart';

import '../content/models.dart';
import '../content/registry.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../milestones/milestone_row.dart';
import 'dig_plate.dart';

/// A layer of the dig: dated title, 2–4 paragraphs, media credits, its
/// artworks, its Milestones and collapsible sources.
class DigStratumView extends StatelessWidget {
  const DigStratumView({
    super.key,
    required this.registry,
    required this.stratum,
    required this.opened,
    required this.onOpenArtwork,
    required this.onOpenMilestone,
    this.extra,
  });
  final ContentRegistry registry;
  final Stratum stratum;
  final bool Function(Milestone) opened;
  final ValueChanged<Artwork> onOpenArtwork;
  final ValueChanged<Milestone> onOpenMilestone;

  /// Present-layer content (the visit card) between the layer and its sources.
  final Widget? extra;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    final artworks = registry.artworksIn(stratum);
    final milestones = registry.milestonesIn(stratum);
    final sources = [
      for (final id in stratum.sourceIds)
        if (registry.source(id) != null) registry.source(id)!,
    ];
    final years = stratum.toYear == null
        ? '${stratum.fromYear}–'
        : '${stratum.fromYear}–${stratum.toYear}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$years · ${eraLabel(context, stratum.era)}',
          style: TypeRole.measurement.copyWith(color: c.accent),
        ),
        const SizedBox(height: 8),
        Text(
          stratum.title.inLanguage(lang),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        for (final paragraph in stratum.paragraphs(lang))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(paragraph),
          ),
        if (stratum.mediaIds.isNotEmpty)
          for (final id in stratum.mediaIds)
            if (registry.mediaItem(id) != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HonestyLabel(Honesty.ORIGINAL),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        [
                          registry
                                  .source(registry.mediaItem(id)!.sourceId)
                                  ?.title
                                  .inLanguage(lang) ??
                              registry.mediaItem(id)!.path,
                          registry.mediaItem(id)!.credit.inLanguage(lang),
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
        if (artworks.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            s.digLayerArtworks,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          for (final artwork in artworks)
            _ArtworkRow(artwork: artwork, onTap: () => onOpenArtwork(artwork)),
        ],
        if (milestones.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            s.digLayerMilestones,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final milestone in milestones)
            MilestoneRow(
              milestone: milestone,
              registry: registry,
              opened: opened(milestone),
              onTap: () => onOpenMilestone(milestone),
            ),
        ],
        ?extra,
        const SizedBox(height: 16),
        SourceList(sources: sources),
      ],
    );
  }
}

class _ArtworkRow extends StatelessWidget {
  const _ArtworkRow({required this.artwork, required this.onTap});
  final Artwork artwork;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context), lang = context.language;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 48,
              child: Text(
                artwork.id,
                style: TypeRole.measurement.copyWith(color: c.accent),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title.inLanguage(lang),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${artwork.room.inLanguage(lang)} · '
                    '${artwork.surface.inLanguage(lang)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            PlanIcon(PlanSymbol.vitrine, color: c.secondary),
          ],
        ),
      ),
    );
  }
}

/// Collapsible source list; a hairline header, no cards.
class SourceList extends StatefulWidget {
  const SourceList({super.key, required this.sources, this.title});
  final List<Source> sources;
  final String? title;
  @override
  State<SourceList> createState() => _SourceListState();
}

class _SourceListState extends State<SourceList> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (widget.sources.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const PlanIcon(PlanSymbol.story, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title ?? s.digSources('${widget.sources.length}'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: c.secondary,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: reduced ? Duration.zero : const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final source in widget.sources)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(source.title.inLanguage(lang)),
                              const SizedBox(height: 2),
                              SelectableText(
                                source.url,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
