import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/plan_icon.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import 'atlas_controller.dart';
import 'atlas_map.dart' show atlasEraCaption, atlasYearLabel;
import 'historic.dart';

/// The map's buttons: zoom, mile rings, "From me", Below, the layers
/// sheet, north and back to the peninsula.
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
    required this.onLayers,
  });
  final AtlasController controller;
  final bool locating;
  final VoidCallback onZoomIn, onZoomOut, onNorth, onRecenter, onFromMe;
  final VoidCallback onLayers;

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    final c = controller;
    final colors = MeasureColors.of(context);
    Widget button({
      required Key key,
      required String tooltip,
      required Widget icon,
      required VoidCallback? onPressed,
      bool? selected,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected == true ? colors.ink : colors.ground,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.line),
          borderRadius: Space.radius,
        ),
        child: IconButton(
          key: key,
          tooltip: tooltip,
          isSelected: selected,
          onPressed: onPressed,
          color: selected == true ? colors.ground : colors.ink,
          icon: icon,
        ),
      ),
    );
    final rotated = c.view.rotation.abs() % (2 * math.pi) > .01;
    return Column(
      children: [
        button(
          key: const ValueKey('atlas-zoom-in'),
          tooltip: s.atlasZoomIn,
          icon: const Icon(Icons.add),
          onPressed: onZoomIn,
        ),
        button(
          key: const ValueKey('atlas-zoom-out'),
          tooltip: s.atlasZoomOut,
          icon: const Icon(Icons.remove),
          onPressed: onZoomOut,
        ),
        button(
          key: const ValueKey('atlas-rings'),
          tooltip:
              '${s.atlasRings}. ${s.atlasRingsHint(c.me == null ? s.atlasMileZero : s.atlasYou)}',
          icon: const PlanIcon(PlanSymbol.dial, size: 22),
          selected: c.rings,
          onPressed: () => c.rings = !c.rings,
        ),
        button(
          key: const ValueKey('atlas-from-me'),
          tooltip: c.me == null ? s.atlasFromMe : s.atlasFromMilion,
          icon: locating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          selected: c.me != null,
          onPressed: onFromMe,
        ),
        button(
          key: const ValueKey('atlas-below'),
          tooltip: '${s.atlasBelow}. ${s.atlasBelowHint}',
          icon: const PlanIcon(PlanSymbol.cistern, size: 22),
          selected: c.below,
          onPressed: () => c.below = !c.below,
        ),
        if (rotated)
          button(
            key: const ValueKey('atlas-north'),
            tooltip: s.atlasNorth,
            icon: Transform.rotate(
              angle: c.view.rotation,
              child: const Icon(Icons.navigation_outlined),
            ),
            onPressed: onNorth,
          ),
        button(
          key: const ValueKey('atlas-layers'),
          tooltip: s.atlasHistoricSources,
          icon: const PlanIcon(PlanSymbol.layers, size: 22),
          onPressed: onLayers,
        ),
        button(
          key: const ValueKey('atlas-recenter'),
          tooltip: s.atlasRecenter,
          icon: const Icon(Icons.center_focus_strong_outlined),
          onPressed: onRecenter,
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
