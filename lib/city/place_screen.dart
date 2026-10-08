import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/geography.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../design/components.dart';
import '../design/motion.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../milestones/milestone_row.dart';
import '../services/progress_service.dart';
import '../shell/app_scope.dart';
import '../shell/navigation.dart';
import '../widgets/artwork_sheet.dart';
import 'city_tab.dart';
import 'dig_gauge.dart';
import 'dig_plate.dart';
import 'dig_sections.dart';
import 'external_links.dart';
import 'visit_card.dart';

/// The dig: the present header on top, then the authored layers newest to
/// oldest under a pinned plate, with the depth gauge on the edge. Places
/// without layers keep the P04 present-day header (P04/P05 Decisions).
class PlaceScreen extends StatefulWidget {
  const PlaceScreen({super.key, required this.place});
  final Place place;
  @override
  State<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<PlaceScreen> {
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  late final List<GlobalKey> _sectionKeys = [
    for (final _ in widget.place.strata) GlobalKey(),
  ];
  int _selected = 0;

  /// Set while the gauge's finger is down: preview only, no page scroll.
  int? _preview;
  int _scrollRequest = 0;

  List<Stratum> get _strata => widget.place.strata;
  int get _index => _preview ?? _selected;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_strata.length < 2 || _preview != null) return;
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.attached) return;
    final top = viewport.localToGlobal(Offset.zero).dy;
    var current = 0;
    for (var i = 0; i < _strata.length; i++) {
      final box =
          _sectionKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= top + 1) current = i;
    }
    if (current != _selected) {
      MotionToken.detent();
      setState(() => _selected = current);
    }
  }

  void _commit(int index) {
    final request = ++_scrollRequest;
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    final box =
        _sectionKeys[index].currentContext?.findRenderObject() as RenderBox?;
    setState(() => _preview = null);
    if (viewport == null ||
        box == null ||
        !viewport.attached ||
        !box.attached) {
      setState(() => _selected = index);
      return;
    }
    final delta =
        box.localToGlobal(Offset.zero).dy -
        viewport.localToGlobal(Offset.zero).dy;
    final target = (_scroll.offset + delta).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _scroll.jumpTo(target);
      setState(() => _selected = index);
      return;
    }
    _scroll
        .animateTo(
          target,
          duration: MotionToken.duration(MeasureMotion.dig, reduced: false),
          curve: MotionToken.curves[MeasureMotion.dig]!,
        )
        .then((_) {
          if (mounted && request == _scrollRequest) {
            setState(() => _selected = index);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n, lang = context.language;
    final app = AppScope.of(context), registry = app.registry!;
    final progress = ProgressScope.of(context);
    final place = widget.place;
    final strata = place.strata;
    final current = strata.isEmpty ? null : strata[_index];
    final media = current == null || current.mediaIds.isEmpty
        ? null
        : registry.mediaItem(current.mediaIds.first);
    final credit = media == null
        ? null
        : '${media.credit.inLanguage(lang)} — '
              '${registry.source(media.sourceId)?.title.inLanguage(lang) ?? ''}';
    return Scaffold(
      appBar: AppBar(
        title: Text(place.names.inLanguage(lang), maxLines: 2),
        actions: [
          if (app.placeRecognised(place.id))
            IconButton(
              key: const ValueKey('place-camera-eye'),
              tooltip: s.recognise,
              onPressed: () => openScan(context),
              icon: const PlanIcon(PlanSymbol.cameraEye),
            ),
        ],
      ),
      body: strata.isEmpty
          ? ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PresentHeader(
                    place: place,
                    registry: registry,
                    artworks: registry.artworks
                        .where((a) => a.placeId == place.id)
                        .length,
                    onOpenArtworks: () => openArtworks(context, place.id),
                  ),
                ),
                if (place.visit != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: VisitCard(place: place, registry: registry),
                  ),
                for (final milestone in registry.register.where(
                  (m) => m.placeIds.contains(place.id),
                ))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: MilestoneRow(
                      milestone: milestone,
                      registry: registry,
                      opened: progress.isOpened(milestone.id),
                      onTap: () => openMilestone(context, milestone),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: SourceList(
                    sources: [
                      for (final id in place.sourceIds)
                        if (registry.source(id) != null) registry.source(id)!,
                    ],
                    title: s.sourcesTitle,
                  ),
                ),
              ],
            )
          : Column(
              children: [
                DigHero(stratum: current!, media: media, credit: credit),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          key: _viewportKey,
                          controller: _scroll,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  16,
                                  24,
                                  0,
                                ),
                                child: PresentHeader(
                                  place: place,
                                  registry: registry,
                                  artworks: registry.artworks
                                      .where((a) => a.placeId == place.id)
                                      .length,
                                  onOpenArtworks: () =>
                                      openArtworks(context, place.id),
                                ),
                              ),
                            ),
                            for (var i = 0; i < strata.length; i++)
                              SliverToBoxAdapter(
                                child: Padding(
                                  key: _sectionKeys[i],
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    40,
                                    24,
                                    0,
                                  ),
                                  child: DigStratumView(
                                    registry: registry,
                                    stratum: strata[i],
                                    opened: (m) => progress.isOpened(m.id),
                                    onOpenArtwork: (artwork) =>
                                        showArtworkSheet(context, artwork),
                                    onOpenMilestone: (milestone) =>
                                        openMilestone(context, milestone),
                                    extra: i == 0 && place.visit != null
                                        ? VisitCard(
                                            place: place,
                                            registry: registry,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  40,
                                  24,
                                  0,
                                ),
                                child: SourceList(
                                  sources: [
                                    for (final id in place.sourceIds)
                                      if (registry.source(id) != null)
                                        registry.source(id)!,
                                  ],
                                  title: s.sourcesTitle,
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 64),
                            ),
                          ],
                        ),
                      ),
                      if (strata.length > 1)
                        DigGauge(
                          strata: strata,
                          selected: _selected,
                          displayYear: strata[_index].gaugeYear,
                          onPreview: (index) =>
                              setState(() => _preview = index),
                          onCommit: _commit,
                          onCancel: () {
                            setState(() => _preview = null);
                            _onScroll();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Opens the typed artwork sheet outside the catalogue as well.
void showArtworkSheet(BuildContext context, Artwork artwork) {
  final app = AppScope.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ArtworkSheet(
      artwork: artwork,
      onScan: app.artworkRecognised(artwork.id)
          ? () => openScan(context)
          : null,
    ),
  );
}

/// The present-day header: identity, distance, state, visit card.
class PresentHeader extends StatelessWidget {
  const PresentHeader({
    super.key,
    required this.place,
    required this.registry,
    required this.artworks,
    this.onOpenArtworks,
  });
  final Place place;
  final ContentRegistry registry;
  final int artworks;
  final VoidCallback? onOpenArtworks;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language,
        theme = Theme.of(context);
    final p = place;
    final m = fromMilion(p);
    final other = lang == 'tr' ? p.names.en : p.names.tr;
    final status = switch (p.status.value) {
      PlaceStatus.open => s.placeStatusOpen,
      PlaceStatus.closed => s.placeStatusClosed,
      PlaceStatus.restoration => s.placeStatusRestoration,
      PlaceStatus.ruin => s.placeStatusRuin,
      PlaceStatus.unknown => s.placeStatusUnknown,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        () {
          final distance = Column(
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
            ],
          );
          final go = OutlinedButton.icon(
            key: const ValueKey('place-go'),
            onPressed: () => launchUrl(
              walkingDirectionsUri(p),
              mode: LaunchMode.externalApplication,
            ),
            icon: const PlanIcon(PlanSymbol.route, size: 18),
            label: Text(s.digGo),
          );
          final largeText = MediaQuery.textScalerOf(context).scale(16) > 20;
          if (largeText) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [distance, const SizedBox(height: 8), go],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: distance),
              const SizedBox(width: 12),
              go,
            ],
          );
        }(),
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
        if (artworks > 0 && onOpenArtworks != null) ...[
          const SizedBox(height: 16),
          InkWell(
            key: const ValueKey('place-artworks'),
            onTap: onOpenArtworks,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.line),
                  bottom: BorderSide(color: c.line),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
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
        if (p.review == ReviewStatus.reviewed) ...[
          const SizedBox(height: 16),
          Text(
            TypeRole.capitals(s.placeFunction, lang),
            style: TypeRole.measurement.copyWith(color: c.secondary),
          ),
          const SizedBox(height: 4),
          Text(p.currentFunction.inLanguage(lang)),
          const SizedBox(height: 8),
          Text(
            p.status.checkedAt == null
                ? status
                : '$status · '
                      '${s.placeCheckedOn(DateFormat.yMMMMd(lang).format(p.status.checkedAt!))}',
          ),
          const SizedBox(height: 8),
          Text(p.hook.inLanguage(lang)),
        ] else ...[
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: TesseraSlot(
                  state: SlotState.planned,
                  width: 12,
                  height: 12,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.notReviewed, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      s.placeDraftBody(p.qid, _checkedOn(context, registry, p)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
      ],
    );
  }

  static String _checkedOn(
    BuildContext context,
    ContentRegistry registry,
    Place p,
  ) {
    final sources = [
      for (final id in p.sourceIds)
        if (registry.source(id) != null) registry.source(id)!,
    ];
    final checked = sources
        .where((x) => x.url.contains('wikidata.org'))
        .firstOrNull;
    return checked == null
        ? '—'
        : DateFormat.yMMMMd(context.language).format(checked.accessedAt);
  }
}
