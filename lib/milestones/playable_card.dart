import 'package:flutter/material.dart';

import '../content/geography.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../design/components.dart';
import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../shell/app_scope.dart';
import '../space/study.dart';
import 'milestone_row.dart';

/// Resolves a bundled photographic thumbnail for a playable Milestone when one
/// exists; returns null when the card should draw an architectural plate.
String? milestonePreviewAsset(
  AppScope app,
  ContentRegistry registry,
  Milestone m,
) {
  final plate = app.plates.forMilestone(m);
  if (plate != null) return plate.original;

  final walk = app.walks.forMilestone(m);
  if (walk != null) {
    final colonnade = registry.mediaItem('ug-cistern-colonnade-photo')?.path;
    if (colonnade != null) return colonnade;
    if (walk.photos.isNotEmpty) return walk.photos.values.first;
  }

  final section = app.sections.forMilestone(m);
  if (section != null) {
    for (final f in section.finds) {
      final path = f.photo == null ? null : registry.mediaItem(f.photo!)?.path;
      if (path != null) return path;
    }
  }

  final study = app.studyFor(m);
  if (study != null) return studyPreviewAsset(registry, study);

  return _placeFirstMedia(registry, m.placeIds.firstOrNull);
}

/// Resolves a bundled photographic thumbnail for a 3D study when one exists;
/// returns null for architectural studies that draw a blueprint plate instead.
String? studyPreviewAsset(ContentRegistry registry, SpaceStudy study) {
  if (study.id == 'serpent-column') {
    final path = registry.mediaItem('ic-serpent-photo')?.path;
    if (path != null) return path;
  }
  return _placeFirstMedia(registry, study.placeId);
}

String? _placeFirstMedia(ContentRegistry registry, String? placeId) {
  if (placeId == null) return null;
  final place = registry.place(placeId);
  if (place == null) return null;
  for (final stratum in place.strata) {
    for (final id in stratum.mediaIds) {
      final item = registry.mediaItem(id);
      if (item != null) return item.path;
    }
  }
  return null;
}

/// Formatted epoch span for a 3D study (e.g. "537–1573" or "479 BC–2026").
String studyEpochSpan(BuildContext context, SpaceStudy study) {
  if (study.epochs.isEmpty) return '';
  String fmt(int year) =>
      year < 0 ? context.l10n.atlasYearBc('${-year}') : '$year';
  if (study.epochs.length == 1) return fmt(study.epochs.first.year);
  return '${fmt(study.epochs.first.year)}–${fmt(study.epochs.last.year)}';
}

/// Unmistakable architectural micro-label naming the type of interactive
/// experience (`3D MODEL`, `3D WALK`, `RELIEF PLATE`, `EXCAVATION SECTION`).
class PlayableTypeTag extends StatelessWidget {
  const PlayableTypeTag({
    super.key,
    required this.symbol,
    required this.label,
    required this.color,
  });

  factory PlayableTypeTag.forKind(BuildContext context, PlayableKind kind) {
    final s = context.l10n;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = MeasureColors.of(context);
    return switch (kind) {
      PlayableKind.space => PlayableTypeTag(
        symbol: PlanSymbol.assembly,
        label: s.kind3dModel,
        color: c.accent,
      ),
      PlayableKind.walk => PlayableTypeTag(
        symbol: PlanSymbol.cistern,
        label: s.kind3dWalk,
        color: dark ? const Color(0xFF88BCE0) : Pigment.cobalt,
      ),
      PlayableKind.plate => PlayableTypeTag(
        symbol: PlanSymbol.layers,
        label: s.kindReliefPlate,
        color: c.accent,
      ),
      PlayableKind.section => PlayableTypeTag(
        symbol: PlanSymbol.section,
        label: s.kindSection,
        color: dark ? const Color(0xFF8EC5B6) : Pigment.verdigris,
      ),
    };
  }

  final PlanSymbol symbol;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      PlanIcon(symbol, size: 13, color: color),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          TypeRole.capitals(label, context.language),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TypeRole.measurement.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: .6,
            color: color,
          ),
        ),
      ),
    ],
  );
}

/// Sharp architectural preview frame (`2 dp` corners, `1 px` hairline):
/// displays a real photographic crop when available, or a custom drafting-plate
/// elevation graphic for unphotographed 3D architectural studies.
class ExperienceThumbnail extends StatelessWidget {
  const ExperienceThumbnail({
    super.key,
    required this.width,
    required this.height,
    required this.symbol,
    this.assetPath,
    this.cornerLabel,
    this.footerLabel,
    this.collected = false,
    this.framed = true,
  });

  final double width;
  final double height;
  final PlanSymbol symbol;
  final String? assetPath;
  final String? cornerLabel;
  final String? footerLabel;
  final bool collected;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.poche,
        borderRadius: framed ? Space.radius : BorderRadius.zero,
        border: framed
            ? Border.all(
                color: collected ? Pigment.gold : c.line,
                width: collected ? 1.5 : 1,
              )
            : Border(bottom: BorderSide(color: c.line.withValues(alpha: .6))),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (assetPath != null)
            Image.asset(
              assetPath!,
              fit: BoxFit.cover,
              cacheWidth: (width * 3).round().clamp(160, 480),
              errorBuilder: (_, _, _) =>
                  _BlueprintPlate(symbol: symbol, footerLabel: footerLabel),
            )
          else
            _BlueprintPlate(symbol: symbol, footerLabel: footerLabel),
          if (cornerLabel != null)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: collected
                      ? Pigment.gold
                      : Pigment.lamp.withValues(alpha: .86),
                  border: Border(
                    right: BorderSide(
                      color: collected
                          ? Pigment.gold
                          : Pigment.marble.withValues(alpha: .28),
                      width: .75,
                    ),
                    bottom: BorderSide(
                      color: collected
                          ? Pigment.gold
                          : Pigment.marble.withValues(alpha: .28),
                      width: .75,
                    ),
                  ),
                ),
                child: Text(
                  cornerLabel!,
                  textScaler: TextScaler.noScaling,
                  style: TypeRole.inscription(
                    13,
                    color: collected ? Pigment.lamp : Pigment.marble,
                  ).copyWith(fontWeight: FontWeight.w600, letterSpacing: .6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlueprintPlate extends StatelessWidget {
  const _BlueprintPlate({required this.symbol, this.footerLabel});
  final PlanSymbol symbol;
  final String? footerLabel;

  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context);
    return CustomPaint(
      painter: _DraftingGridPainter(c.line.withValues(alpha: .26)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PlanIcon(symbol, size: 28, color: c.accent),
          if (footerLabel != null && footerLabel!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  footerLabel!,
                  textScaler: TextScaler.noScaling,
                  style: TypeRole.measurement.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.secondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DraftingGridPainter extends CustomPainter {
  const _DraftingGridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = .75
      ..style = PaintingStyle.stroke;
    // Architectural construction crosshair & inset frame.
    canvas.drawRect(Rect.fromLTWH(5, 5, size.width - 10, size.height - 10), p);
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      p,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      p,
    );
  }

  @override
  bool shouldRepaint(_DraftingGridPainter old) => old.color != color;
}

/// Editorial playable Milestone card: photographic/blueprint thumbnail,
/// unmistakable experience-type header, title, location, quiet honesty stamp,
/// and directional chevron.
class PlayableMilestoneCard extends StatelessWidget {
  const PlayableMilestoneCard({
    super.key,
    required this.milestone,
    required this.registry,
    required this.opened,
    required this.onTap,
  });

  final Milestone milestone;
  final ContentRegistry registry;
  final bool opened;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = MeasureColors.of(context);
    final s = context.l10n;
    final lang = context.language;
    final kind = app.playableKind(milestone);
    if (kind == null) {
      return MilestoneRow(
        milestone: milestone,
        registry: registry,
        opened: opened,
        onTap: onTap,
      );
    }
    final thumb = milestonePreviewAsset(app, registry, milestone);
    final study = app.studyFor(milestone);
    final symbol = switch (kind) {
      PlayableKind.space => PlanSymbol.assembly,
      PlayableKind.walk => PlanSymbol.cistern,
      PlayableKind.plate => PlanSymbol.layers,
      PlayableKind.section => PlanSymbol.section,
    };
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final thumbSize = largeText ? 60.0 : 82.0;
    return MergeSemantics(
      child: InkWell(
        key: ValueKey('milestone-${milestone.numeral}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.line.withValues(alpha: .55)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: ExperienceThumbnail(
                  width: thumbSize,
                  height: thumbSize,
                  symbol: symbol,
                  assetPath: thumb,
                  cornerLabel: milestone.numeral,
                  footerLabel: study == null
                      ? null
                      : studyEpochSpan(context, study),
                  collected: opened,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PlayableTypeTag.forKind(context, kind),
                        if (milestone.flagship) const FlagshipMark(size: 11),
                        if (opened)
                          Text(
                            TypeRole.capitals(s.statusOpened, lang),
                            style: TypeRole.measurement.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Pigment.gold
                                  : Pigment.bronze,
                            ),
                          )
                        else
                          // Prototype or approved: review debt stays visible.
                          Text(
                            TypeRole.capitals(
                              milestoneStatus(
                                context,
                                milestone,
                                opened: false,
                              ),
                              lang,
                            ),
                            key: ValueKey(
                              'playable-status-${milestone.numeral}',
                            ),
                            style: TypeRole.measurement.copyWith(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: MeasureColors.of(context).secondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      milestone.title.inLanguage(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      milestoneWhere(context, registry, milestone),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    HonestyRange(milestone.honesty),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: c.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Editorial playable card for a standalone 3D architectural study
/// (`sehzade-camii`, `kucuk-ayasofya`, `bodrum-camii`, `how-a-dome-stands`).
class SpaceStudyCard extends StatelessWidget {
  const SpaceStudyCard({
    super.key,
    required this.study,
    required this.registry,
    required this.onTap,
  });

  final SpaceStudy study;
  final ContentRegistry registry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context), s = context.l10n;
    final lang = context.language;
    final place = study.placeId == null ? null : registry.place(study.placeId!);
    final span = studyEpochSpan(context, study);
    final subtitle = place != null
        ? '${place.names.inLanguage(lang)} · ${formatMilDistance(fromMilion(place).km, language: lang)}'
        : span;
    final thumb = studyPreviewAsset(registry, study);
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final thumbSize = largeText ? 60.0 : 82.0;
    return MergeSemantics(
      child: InkWell(
        key: ValueKey('study-${study.id}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.line.withValues(alpha: .55)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: ExperienceThumbnail(
                  width: thumbSize,
                  height: thumbSize,
                  symbol: study.placeId == null
                      ? PlanSymbol.section
                      : PlanSymbol.dome,
                  assetPath: thumb,
                  cornerLabel: s.placeCapability3d,
                  footerLabel: span,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlayableTypeTag.forKind(context, PlayableKind.space),
                    const SizedBox(height: 4),
                    Text(
                      study.title.inLanguage(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        HonestyLabel(study.honesty),
                        if (place != null && span.isNotEmpty)
                          Text(
                            span,
                            style: TypeRole.measurement.copyWith(
                              fontSize: 11,
                              color: c.secondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: c.secondary),
            ],
          ),
        ),
      ),
    );
  }
}
