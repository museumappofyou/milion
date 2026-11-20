import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../content/geography.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../milestones/chapters.dart';
import '../milestones/milestone_row.dart';
import '../milestones/playable_card.dart';
import '../mosaic/mosaic_strip.dart';
import '../services/progress_service.dart';
import '../shell/app_scope.dart';
import '../shell/app_shell.dart';
import '../shell/navigation.dart';
import '../theme/milion_theme.dart';
import 'detail_crop.dart';
import 'mile_zero_dial.dart';

/// Today is a composition, not a feed: the detail of the day, the Mile Zero
/// dial, the mosaic strip and the current chapter.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with RestorationMixin {
  final _place = RestorableStringN(null);
  final _list = RestorableBool(false);
  final _dialAll = RestorableBool(false);
  ContentRegistry? _registry;
  List<DialPlace> _places = const [];

  @override
  String get restorationId => 'today';
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_place, 'dial-place');
    registerForRestoration(_list, 'dial-list');
    registerForRestoration(_dialAll, 'dial-all');
  }

  @override
  void dispose() {
    _place.dispose();
    _list.dispose();
    _dialAll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context), registry = app.registry;
    final s = context.l10n;
    if (registry == null) {
      return Center(
        child: app.error == null
            ? const SizedBox.shrink()
            : ContentState(
                error: true,
                title: s.todayError,
                message: s.todayErrorBody,
                onAction: app.retry,
              ),
      );
    }
    if (_registry != registry) {
      _registry = registry;
      _places = dialPlaces(registry.plottablePlaces);
    }
    final interactiveIds = app.interactivePlaceIds;
    final featuredPlaces = [
      for (final p in _places)
        if (p.reviewed || interactiveIds.contains(p.place.id)) p,
    ];
    final shownPlaces = _dialAll.value || featuredPlaces.isEmpty
        ? _places
        : featuredPlaces;
    final detail = detailOfDay(
      registry,
      app.clock(),
      playable: (d) =>
          app.plates.forMilestone(registry.milestone(d.milestoneId)!) != null,
    );
    var selected = shownPlaces.indexWhere((p) => p.place.id == _place.value);
    if (selected < 0) {
      // Start the index on the place the detail of the day belongs to.
      final home = detail == null
          ? null
          : registry.artwork(detail.artworkId).placeId;
      selected = math.max(0, shownPlaces.indexWhere((p) => p.place.id == home));
    }
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion(
      value: DesignTheme.overlay(Brightness.dark),
      child: Stack(
        children: [
          CustomScrollView(
            restorationId: 'today-scroll',
            slivers: [
              if (detail != null)
                SliverToBoxAdapter(
                  child: Theme(
                    data: DesignTheme.lamp,
                    child: _DetailPanel(detail: detail, registry: registry),
                  ),
                ),
              SliverToBoxAdapter(
                child: _DialHeader(
                  list: _list.value,
                  showAll: _dialAll.value,
                  featuredCount: featuredPlaces.length,
                  allCount: _places.length,
                  onToggle: () => setState(() => _list.value = !_list.value),
                  onScopeChanged: (all) => setState(() => _dialAll.value = all),
                ),
              ),
              if (_list.value)
                _PlaceList(places: shownPlaces)
              else
                SliverToBoxAdapter(
                  child: _DialSection(
                    places: shownPlaces,
                    selected: selected,
                    onSelected: (i) =>
                        setState(() => _place.value = shownPlaces[i].place.id),
                  ),
                ),
              SliverToBoxAdapter(child: _MosaicSection(registry: registry)),
              SliverToBoxAdapter(child: _ChapterSection(registry: registry)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
          // A solid lamp strip keeps the light status icons legible over marble.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top,
            child: const ColoredBox(color: Pigment.lamp),
          ),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.detail, required this.registry});
  final Detail detail;
  final ContentRegistry registry;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    final milestone = registry.milestone(detail.milestoneId)!;
    final scene = AppScope.of(context).plates.forMilestone(milestone)!;
    final artwork = registry.artwork(detail.artworkId);
    final place = registry.place(artwork.placeId)!;
    final screen = MediaQuery.sizeOf(context);
    final height = (screen.width * .96)
        .clamp(240.0, math.max(240.0, screen.height * .46))
        .toDouble();
    final date = DateFormat.yMMMMd(lang).format(AppScope.of(context).clock());
    void open() => openMilestone(context, milestone, detail: detail);
    return ColoredBox(
      color: c.ground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
            child: Row(
              children: [
                const MilionWordmark(compact: true),
                const Spacer(),
                IconButton(
                  tooltip: s.about,
                  onPressed: () => openAbout(context),
                  icon: const PlanIcon(PlanSymbol.story),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              TypeRole.capitals('${s.detailOfDay} · $date', lang),
              style: TypeRole.measurement.copyWith(color: c.secondary),
            ),
          ),
          Semantics(
            button: true,
            label:
                '${detail.title.inLanguage(lang)}. ${detail.sentence.inLanguage(lang)}',
            hint: s.openMilestoneDetail(milestone.numeral),
            child: GestureDetector(
              key: const ValueKey('detail-of-day'),
              onTap: open,
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final g = CropGeometry(
                      box.biggest,
                      Size(scene.width.toDouble(), scene.height.toDouble()),
                      detail.window,
                    );
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Hero(
                            tag: detailHeroTag(detail),
                            transitionOnUserGestures: true,
                            child: DetailCrop(
                              asset: scene.original,
                              source: Size(
                                scene.width.toDouble(),
                                scene.height.toDouble(),
                              ),
                              window: detail.window,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _LeaderPainter(
                                g.toBox(detail.anchorX, detail.anchorY),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MilestoneNumeral(milestone.numeral, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TypeRole.capitals(
                              detail.title.inLanguage(lang),
                              lang,
                            ),
                            style: TypeRole.measurement.copyWith(
                              color: c.accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            detail.sentence.inLanguage(lang),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    HonestyLabel(detail.honesty),
                    Text(
                      s.detailSource(
                        milestone.title.inLanguage(lang),
                        place.names.inLanguage(lang),
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: open,
                  icon: const PlanIcon(PlanSymbol.layers, size: 18),
                  label: Text(s.openMilestoneDetail(milestone.numeral)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A hairline from the detail to the margin caption (signature 3).
class _LeaderPainter extends CustomPainter {
  _LeaderPainter(this.anchor);
  final Offset anchor;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(anchor.dx, anchor.dy + 6)
      ..lineTo(anchor.dx, size.height + 12)
      ..lineTo(24, size.height + 12)
      ..lineTo(24, size.height + 24);
    final tick = Path()
      ..moveTo(anchor.dx - 6, anchor.dy)
      ..lineTo(anchor.dx + 6, anchor.dy)
      ..moveTo(anchor.dx, anchor.dy - 6)
      ..lineTo(anchor.dx, anchor.dy + 6);
    // A lamp under-stroke keeps the marble hairline legible over pale gold.
    for (final (color, width) in [(Pigment.lamp, 3.0), (Pigment.marble, 1.0)]) {
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width;
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(path, p);
      canvas.drawPath(tick, p);
      canvas.restore();
    }
    canvas.drawPath(
      Path()
        ..moveTo(anchor.dx, size.height)
        ..lineTo(anchor.dx, size.height + 12)
        ..lineTo(24, size.height + 12)
        ..lineTo(24, size.height + 24),
      Paint()
        ..color = Pigment.marble
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_LeaderPainter old) => old.anchor != anchor;
}

class _DialHeader extends StatelessWidget {
  const _DialHeader({
    required this.list,
    required this.showAll,
    required this.featuredCount,
    required this.allCount,
    required this.onToggle,
    required this.onScopeChanged,
  });
  final bool list;
  final bool showAll;
  final int featuredCount;
  final int allCount;
  final VoidCallback onToggle;
  final ValueChanged<bool> onScopeChanged;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n, c = MeasureColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      TypeRole.capitals(s.mileZero, context.language),
                      style: TypeRole.inscription(20, color: c.ink),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.milionCoordinates,
                    style: TypeRole.measurement.copyWith(color: c.secondary),
                  ),
                ],
              ),
              OutlinedButton.icon(
                key: const ValueKey('dial-toggle'),
                onPressed: onToggle,
                icon: PlanIcon(list ? PlanSymbol.dial : PlanSymbol.story),
                label: Text(list ? s.showDial : s.showList),
              ),
            ],
          ),
          if (featuredCount > 0 && featuredCount < allCount) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  key: const ValueKey('dial-scope-featured'),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  selected: !showAll,
                  label: Text(s.dialScopeFeatured('$featuredCount')),
                  onSelected: (_) => onScopeChanged(false),
                ),
                ChoiceChip(
                  key: const ValueKey('dial-scope-all'),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  selected: showAll,
                  label: Text(s.dialScopeAll('$allCount')),
                  onSelected: (_) => onScopeChanged(true),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DialSection extends StatelessWidget {
  const _DialSection({
    required this.places,
    required this.selected,
    required this.onSelected,
  });
  final List<DialPlace> places;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    final width = MediaQuery.sizeOf(context).width;
    // Margins either side of the plate stay free for scrolling the page.
    final side = math.min(width - 96, 380.0);
    if (places.isEmpty) return const SizedBox.shrink();
    final p = places[selected];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox.square(
              dimension: side,
              child: MileZeroDial(
                key: const ValueKey('mile-zero-dial'),
                places: places,
                selected: selected,
                onSelected: onSelected,
                onOpen: (i) => openPlace(context, places[i].place),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.bearing('${p.bearing.round()}'),
            style: TypeRole.measurement.copyWith(color: c.accent),
          ),
          const SizedBox(height: 4),
          Text(
            p.place.names.inLanguage(lang),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MilDistance(p.km),
              Text(
                p.reviewed ? s.reviewed : s.notReviewed,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => openPlace(context, p.place),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    s.openPlace(p.place.names.inLanguage(lang)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(s.dialHint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// The dial's list alternative: the same places, clockwise from north.
class _PlaceList extends StatelessWidget {
  const _PlaceList({required this.places});
  final List<DialPlace> places;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n,
        c = MeasureColors.of(context),
        lang = context.language;
    return SliverList.builder(
      itemCount: places.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              s.placesByBearing('${places.length}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        final p = places[i - 1];
        return InkWell(
          onTap: () => openPlace(context, p.place),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    '${p.bearing.round()}°',
                    style: TypeRole.measurement.copyWith(color: c.accent),
                  ),
                ),
                Expanded(child: Text(p.place.names.inLanguage(lang))),
                const SizedBox(width: 8),
                Text(
                  formatMilDistance(p.km, language: lang),
                  style: TypeRole.measurement.copyWith(color: c.secondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MosaicSection extends StatelessWidget {
  const _MosaicSection({required this.registry});
  final ContentRegistry registry;
  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: MosaicStrip(
        register: registry.register,
        opened: ProgressScope.of(context).opened,
        onTap: () => ShellScope.of(context)?.select(Destination.mosaic),
      ),
    );
  }
}

class _ChapterSection extends StatelessWidget {
  const _ChapterSection({required this.registry});
  final ContentRegistry registry;
  @override
  Widget build(BuildContext context) {
    final s = context.l10n, progress = ProgressScope.of(context);
    final chapter = chaptersOf(context).first;
    final pieces = registry.register.where(chapter.contains).toList();
    final app = AppScope.of(context);
    // Playable pieces first (plates, 3D studies, walk, section), then planned.
    final next = [
      ...pieces.where((m) => app.playable(m) && !progress.isOpened(m.id)),
      ...pieces.where((m) => app.playable(m) && progress.isOpened(m.id)),
      ...pieces.where((m) => !app.playable(m)),
    ].take(4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChapterBand(chapter: chapter, pieces: pieces, current: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text(
            s.nextMilestones,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final m in next)
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
    );
  }
}
