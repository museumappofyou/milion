import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import 'atlas_controller.dart';
import 'atlas_map.dart' show atlasEraCaption, atlasYearLabel;
import 'historic.dart';

/// Top-left labeled mode chips on the Atlas: Mile rings, Below (underground),
/// and Historic layers. Replaces unlabeled geometric icon boxes so every
/// map overlay reads clearly at a glance.
class AtlasLayerChips extends StatelessWidget {
  const AtlasLayerChips({
    super.key,
    required this.controller,
    required this.onLayers,
  });
  final AtlasController controller;
  final VoidCallback onLayers;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = controller;
    final colors = MeasureColors.of(context);
    Widget chip({
      required Key key,
      required String label,
      required String tooltip,
      required PlanSymbol symbol,
      required VoidCallback onTap,
      bool selected = false,
      bool toggle = true,
    }) {
      final bg = selected ? colors.ink : colors.ground.withValues(alpha: .94);
      final fg = selected ? colors.ground : colors.ink;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Tooltip(
          message: tooltip,
          child: Semantics(
            button: true,
            // Mile rings and Below switch; Layers only opens a sheet.
            toggled: toggle ? selected : null,
            label: tooltip,
            child: Material(
              color: bg,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: selected ? colors.ink : colors.line),
                borderRadius: const BorderRadius.all(Radius.circular(3)),
              ),
              child: InkWell(
                key: key,
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlanIcon(symbol, size: 17, color: fg),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: TypeRole.bodyFamily,
                            fontSize: 12.5,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip(
            key: const ValueKey('atlas-rings'),
            label: s.atlasRings,
            tooltip:
                '${s.atlasRings}. ${s.atlasRingsHint(c.me == null ? s.atlasMileZero : s.atlasYou)}',
            symbol: PlanSymbol.dial,
            selected: c.rings,
            onTap: () => c.rings = !c.rings,
          ),
          chip(
            key: const ValueKey('atlas-below'),
            label: s.atlasBelow,
            tooltip: '${s.atlasBelow}. ${s.atlasBelowHint}',
            symbol: PlanSymbol.cistern,
            selected: c.below,
            onTap: () => c.below = !c.below,
          ),
          chip(
            key: const ValueKey('atlas-layers'),
            label: s.atlasLayersShort,
            tooltip: s.atlasHistoricSources,
            symbol: PlanSymbol.layers,
            onTap: onLayers,
            toggle: false,
          ),
        ],
      ),
    );
  }
}

/// Compact right-edge spatial instrument cluster: joined +/− zoom bar,
/// locate ("From me"), recenter, and conditional North reset.
class AtlasControls extends StatelessWidget {
  const AtlasControls({
    super.key,
    required this.controller,
    required this.locating,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onNorth,
    required this.onRecenter,
    required this.onFromMe,
  });
  final AtlasController controller;
  final bool locating;
  final VoidCallback onZoomIn, onZoomOut, onNorth, onRecenter, onFromMe;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = controller;
    final colors = MeasureColors.of(context);
    const radius = BorderRadius.all(Radius.circular(3));
    Widget solo({
      required Key key,
      required String tooltip,
      required Widget icon,
      required VoidCallback? onPressed,
      bool selected = false,
    }) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: selected ? colors.ink : colors.ground.withValues(alpha: .94),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: selected ? colors.ink : colors.line),
          borderRadius: radius,
        ),
        child: IconButton(
          key: key,
          tooltip: tooltip,
          isSelected: selected,
          onPressed: onPressed,
          color: selected ? colors.ground : colors.ink,
          icon: icon,
        ),
      ),
    );
    final rotated = c.view.rotation.abs() % (2 * math.pi) > .01;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Joined + / − zoom instrument block.
        Material(
          color: colors.ground.withValues(alpha: .94),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: colors.line),
            borderRadius: radius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const ValueKey('atlas-zoom-in'),
                tooltip: s.atlasZoomIn,
                onPressed: onZoomIn,
                color: colors.ink,
                icon: const Icon(Icons.add, size: 20),
              ),
              Container(width: 32, height: 1, color: colors.line),
              IconButton(
                key: const ValueKey('atlas-zoom-out'),
                tooltip: s.atlasZoomOut,
                onPressed: onZoomOut,
                color: colors.ink,
                icon: const Icon(Icons.remove, size: 20),
              ),
            ],
          ),
        ),
        solo(
          key: const ValueKey('atlas-from-me'),
          tooltip: c.me == null ? s.atlasFromMe : s.atlasFromMilion,
          icon: locating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location, size: 20),
          selected: c.me != null,
          onPressed: onFromMe,
        ),
        solo(
          key: const ValueKey('atlas-recenter'),
          tooltip: s.atlasRecenter,
          icon: const Icon(Icons.center_focus_strong_outlined, size: 20),
          onPressed: onRecenter,
        ),
        if (rotated)
          solo(
            key: const ValueKey('atlas-north'),
            tooltip: s.atlasNorth,
            icon: Transform.rotate(
              angle: c.view.rotation,
              child: const Icon(Icons.navigation_outlined, size: 20),
            ),
            onPressed: onNorth,
          ),
      ],
    );
  }
}

/// The time slider: play, the year and its caption, and the seven stops.
class AtlasTimeBar extends StatelessWidget {
  const AtlasTimeBar({
    super.key,
    required this.stop,
    required this.playing,
    required this.onStop,
    required this.onPlay,
  });
  final int stop;
  final bool playing;
  final void Function(int) onStop;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final colors = MeasureColors.of(context);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.ground.withValues(alpha: .94),
        border: Border(top: BorderSide(color: colors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 8),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('atlas-play'),
                  tooltip: playing ? s.atlasPause : s.atlasPlay,
                  onPressed: onPlay,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                ),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      stop == atlasYears.length - 1
                          ? atlasEraCaption(context, stop)
                          : '${atlasYearLabel(context, atlasYears[stop])} · '
                                '${atlasEraCaption(context, stop)}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
              ],
            ),
            Slider(
              key: const ValueKey('atlas-time'),
              value: stop.toDouble(),
              max: atlasYears.length - 1.0,
              divisions: atlasYears.length - 1,
              label: atlasYearLabel(context, atlasYears[stop]),
              semanticFormatterCallback: (v) =>
                  '${atlasYearLabel(context, atlasYears[v.round()])}, '
                  '${atlasEraCaption(context, v.round())}',
              onChanged: (v) {
                if (v.round() != stop) onStop(v.round());
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // The slider's semantics read each year in full; the ticks
              // shrink to fit at large text sizes rather than overflow.
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    for (var i = 0; i < atlasYears.length; i++)
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            i == atlasYears.length - 1
                                ? s.atlasEraToday
                                : '${atlasYears[i]}',
                            style: TypeRole.measurement.copyWith(
                              fontSize: 11,
                              color: i == stop ? colors.ink : colors.secondary,
                              fontWeight: i == stop ? FontWeight.w600 : null,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
