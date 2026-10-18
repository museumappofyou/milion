import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../design/components.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import 'camera.dart';
import 'player.dart';
import 'style.dart';

enum SpacePanel { assemble, section, style, sources }

const _numerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];

/// Scrollable controls; the drawing stays full height while exploring.
class SpaceSheet extends StatelessWidget {
  const SpaceSheet({super.key, required this.player, required this.panel});
  final SpacePlayerState player;
  final SpacePanel panel;
  @override
  Widget build(BuildContext context) {
    final c = player.controller!;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final s = context.l10n, lang = context.language;
        final metres = NumberFormat('0.0', lang);
        final heading = switch (panel) {
          SpacePanel.assemble => s.spaceAssemble,
          SpacePanel.section => s.spaceSection,
          SpacePanel.style => s.spaceStyle,
          SpacePanel.sources => s.spaceSources,
        };
        final b = c.model.bounds, axis = c.sectionAxis;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .78,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          heading,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: s.plateClose,
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (panel == SpacePanel.assemble) ...[
                    if (c.reduced) Text(s.plateStillHint),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!c.reduced)
                          OutlinedButton(
                            key: const ValueKey('space-reveal'),
                            onPressed: c.playReveal,
                            child: Text(s.plateStartReveal),
                          ),
                        if (!c.reduced)
                          FilledButton(
                            key: const ValueKey('space-play'),
                            onPressed: c.playing ? c.pause : c.play,
                            child: Text(c.playing ? s.platePause : s.spacePlay),
                          ),
                        OutlinedButton(
                          key: const ValueKey('space-previous'),
                          onPressed: () => c.step(-1),
                          child: Text(s.platePrevious),
                        ),
                        OutlinedButton(
                          key: const ValueKey('space-next'),
                          onPressed: () => c.step(1),
                          child: Text(s.plateNext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(s.spaceAssembly),
                    Slider(
                      key: const ValueKey('space-assembly'),
                      value: c.moment.assembly.clamp(
                        0,
                        c.steps.length.toDouble(),
                      ),
                      max: c.steps.length.toDouble(),
                      divisions: c.steps.length * 4,
                      semanticFormatterCallback: (v) => s.spaceAssemblyValue(
                        '${v.floor()}',
                        '${c.steps.length}',
                      ),
                      onChanged: c.seekAssembly,
                    ),
                    Text(s.spaceExplode),
                    Slider(
                      key: const ValueKey('space-explode'),
                      value: c.explode,
                      onChanged: c.setExplode,
                      semanticFormatterCallback: (v) => '${(v * 100).round()}%',
                    ),
                    // One epoch: nothing to scrub between.
                    if (c.study.epochs.length > 1) ...[
                      Text(s.spaceTime),
                      Slider(
                        key: const ValueKey('space-time'),
                        value: c.visibleEpoch.toDouble(),
                        max: (c.study.epochs.length - 1).toDouble(),
                        divisions: c.study.epochs.length - 1,
                        // The stops are named below; a value label would make
                        // TalkBack read the year twice.
                        semanticFormatterCallback: (v) =>
                            c.study.epochs[v.round()].label.inLanguage(lang),
                        onChanged: (v) => c.setEpoch(v.round()),
                      ),
                      // Stops of the scrubber, first and last at its ends;
                      // long labels wrap rather than overflow at 200% text.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (i, e) in c.study.epochs.indexed)
                            Expanded(
                              child: Text(
                                e.label.inLanguage(lang),
                                textAlign: i == 0
                                    ? TextAlign.start
                                    : i == c.study.epochs.length - 1
                                    ? TextAlign.end
                                    : TextAlign.center,
                                style: TypeRole.measurement,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      s.spaceSteps,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final (i, step) in c.steps.indexed)
                      ListTile(
                        key: ValueKey('space-step-${step.id}'),
                        contentPadding: EdgeInsets.zero,
                        leading: Text(
                          i < _numerals.length ? _numerals[i] : '${i + 1}',
                          style: TypeRole.inscription(
                            16,
                            color: MeasureColors.of(context).accent,
                          ),
                        ),
                        title: Text(step.label.inLanguage(lang)),
                        selected: c.currentStep == step,
                        onTap: () => c.seekAssembly(i + 1.0),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        player.controls(SpacePanel.sources);
                      },
                      child: Text(s.spaceSources),
                    ),
                  ],
                  if (panel == SpacePanel.section) ...[
                    SwitchListTile(
                      key: const ValueKey('space-section-switch'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.spaceSectionPlane),
                      subtitle: Text(s.spaceSectionHint),
                      value: c.section,
                      onChanged: c.setSection,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // A kit study is drawn in the building's frame (+y
                        // along its axis), so its cuts are long and cross
                        // sections; P08's bay keeps the compass.
                        for (final (a, label) in [
                          (2, s.spaceCutPlan),
                          if (c.study.orientation == null) ...[
                            (0, s.spaceCutNorthSouth),
                            (1, s.spaceCutEastWest),
                          ] else ...[
                            (0, s.spaceCutLong),
                            (1, s.spaceCutCross),
                          ],
                        ])
                          ChoiceChip(
                            key: ValueKey('space-cut-$a'),
                            label: Text(label),
                            selected: c.section && axis == a,
                            onSelected: (_) => c.setSectionAxis(a),
                          ),
                      ],
                    ),
                    Slider(
                      key: const ValueKey('space-section-offset'),
                      value: c.sectionOffset.clamp(b.min(axis), b.max(axis)),
                      min: b.min(axis),
                      max: b.max(axis),
                      label: s.spaceMetres(metres.format(c.sectionOffset)),
                      semanticFormatterCallback: (v) =>
                          s.spaceMetres(metres.format(v)),
                      onChanged: c.setSectionOffset,
                    ),
                  ],
                  if (panel == SpacePanel.style) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (style, label) in [
                          (SpaceStyle.drawing, s.spaceStyleDrawing),
                          (SpaceStyle.stone, s.spaceStyleStone),
                          (SpaceStyle.night, s.spaceStyleNight),
                        ])
                          ChoiceChip(
                            key: ValueKey('space-style-${style.name}'),
                            label: Text(label),
                            selected: c.style == style,
                            onSelected: (_) => c.setStyle(style),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      key: const ValueKey('space-choisy'),
                      onPressed: c.choisy,
                      child: Text(s.spaceChoisy),
                    ),
                    Text(s.spaceChoisyHint),
                    SwitchListTile(
                      key: const ValueKey('space-perspective'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.spacePerspective),
                      value: c.view.projection == SpaceProjection.perspective,
                      onChanged: (v) => c.setView(
                        c.view.copyWith(
                          projection: v
                              ? SpaceProjection.perspective
                              : SpaceProjection.axonometric,
                        ),
                      ),
                    ),
                    Text(s.spaceGestureHint),
                  ],
                  if (panel == SpacePanel.sources) ...[
                    HonestyLabel(c.honesty),
                    const SizedBox(height: 8),
                    Text(c.study.description.inLanguage(lang)),
                    const SizedBox(height: 16),
                    for (final source in c.study.citations)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source.title.inLanguage(lang),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(source.author.inLanguage(lang)),
                            SelectableText(source.url),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
