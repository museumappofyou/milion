import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

import '../design/components.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import 'camera.dart';
import 'controller.dart';
import 'player.dart';
import 'study.dart';
import 'style.dart';
import 'snapshot_builder.dart';

enum SpacePanel { assemble, section, style, sources }

const _numerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
String _numeral(int i) => i < _numerals.length ? _numerals[i] : '${i + 1}';

/// The controls for one panel. Assemble, Section and Style dock under the
/// drawing, which stays in view and answers each change as it is made (the
/// owner, 2026-11-16: closing a sheet to see what an added element did was
/// not playable). Sources, which is read rather than played, is a sheet.
class SpaceSheet extends StatelessWidget {
  const SpaceSheet({super.key, required this.player, required this.panel});
  final SpacePlayerState player;
  final SpacePanel panel;
  bool get docked => panel != SpacePanel.sources;

  @override
  Widget build(BuildContext context) {
    final c = player.controller!;
    // Only what the controls show: the assembly slider draws its thumb at
    // its divisions (four per step), so playback rebuilds it a few dozen
    // times, not every frame.
    return SnapshotBuilder(
      listenable: c,
      snapshot: () => (
        c.reduced,
        c.playing,
        (c.moment.assembly.clamp(0, c.visibleSteps.length) * 4).round(),
        c.assemblyTarget,
        c.explode,
        c.visibleEpoch,
        c.currentStep,
        c.reveal && c.storyActive,
        c.section,
        c.sectionAxis,
        c.sectionOffset,
        c.style,
        c.view.projection,
        c.honesty,
      ),
      builder: (context) {
        final s = context.l10n;
        final heading = switch (panel) {
          SpacePanel.assemble => s.spaceAssemble,
          SpacePanel.section => s.spaceSection,
          SpacePanel.style => s.spaceStyle,
          SpacePanel.sources => s.spaceSources,
        };
        final header = Row(
          children: [
            Expanded(
              child: Text(
                heading,
                style: docked
                    ? Theme.of(context).textTheme.titleSmall
                    : Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              key: const ValueKey('space-dock-close'),
              tooltip: s.plateClose,
              visualDensity: VisualDensity.compact,
              icon: Icon(docked ? Icons.expand_more : Icons.close),
              onPressed: docked
                  ? player.closeControls
                  : () => Navigator.pop(context),
            ),
          ],
        );
        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!docked) header,
            ...switch (panel) {
              SpacePanel.assemble => _assemble(context, c),
              SpacePanel.section => _section(context, c),
              SpacePanel.style => _style(context, c),
              SpacePanel.sources => _sources(context, c),
            },
          ],
        );
        if (docked) {
          // The header stays put while the controls scroll under it.
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: header,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                    child: body,
                  ),
                ),
              ],
            ),
          );
        }
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .78,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [const DimensionHandle(), body],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _assemble(BuildContext context, SpaceController c) {
    final s = context.l10n, lang = context.language;
    final steps = c.visibleSteps, total = steps.length;
    final done = c.storyActive
        ? steps.indexOf(c.currentStep!) + 1
        : c.assemblyTarget.round();
    final shown = done > 0 && done <= total ? steps[done - 1] : null;
    return [
      // Build by hand: the drawing above answers each tap.
      Row(
        children: [
          IconButton.filledTonal(
            key: const ValueKey('space-build-less'),
            tooltip: s.spaceRemoveStep,
            onPressed: done > 0 ? () => c.build(-1) : null,
            icon: const Icon(Icons.remove),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.spaceAssemblyValue('$done', '$total'),
                  key: const ValueKey('space-build-count'),
                  style: TypeRole.measurement,
                ),
                Text(
                  shown == null
                      ? s.spaceNothingBuilt
                      : '${_numeral(done - 1)}  ${shown.label.inLanguage(lang)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const ValueKey('space-build-more'),
            tooltip: s.spaceAddStep,
            onPressed: done < total ? () => c.build(1) : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      if (c.caption?.inLanguage(lang) case final caption?)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Semantics(
            liveRegion: true,
            child: Text(
              caption,
              key: const ValueKey('space-caption'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      const SizedBox(height: 8),
      _StepStrip(controller: c, done: done),
      Slider(
        key: const ValueKey('space-assembly'),
        value: c.moment.assembly.clamp(0, total.toDouble()),
        max: total.toDouble(),
        divisions: total * 4,
        semanticFormatterCallback: (v) =>
            s.spaceAssemblyValue('${v.floor()}', '$total'),
        onChanged: c.seekAssembly,
      ),
      Text(
        TypeRole.capitals(s.spaceExplode, lang),
        style: TypeRole.measurement.copyWith(
          fontSize: 11,
          color: MeasureColors.of(context).secondary,
        ),
      ),
      Slider(
        key: const ValueKey('space-explode'),
        value: c.explode,
        onChanged: c.setExplode,
        semanticFormatterCallback: (v) => '${(v * 100).round()}%',
      ),
      // One epoch: nothing to switch between.
      if (c.study.epochs.length > 1) ...[
        const SizedBox(height: 6),
        Text(
          TypeRole.capitals(s.spaceTime, lang),
          style: TypeRole.measurement.copyWith(
            fontSize: 11,
            color: MeasureColors.of(context).secondary,
          ),
        ),
        const SizedBox(height: 6),
        _EpochSelector(controller: c),
        const SizedBox(height: 6),
        Text(
          c.study.epochs[c.visibleEpoch].label.inLanguage(lang),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: MeasureColors.of(context).ink),
        ),
      ],
      const SizedBox(height: 14),
      if (c.reduced) Text(s.plateStillHint),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (!c.reduced)
            FilledButton.icon(
              key: const ValueKey('space-play'),
              onPressed: c.playing ? c.pause : c.play,
              icon: Icon(c.playing ? Icons.pause : Icons.play_arrow, size: 18),
              label: Text(c.playing ? s.platePause : s.spacePlay),
            ),
          if (!c.reduced)
            OutlinedButton(
              key: const ValueKey('space-reveal'),
              onPressed: c.playReveal,
              child: Text(s.plateStartReveal),
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
    ];
  }

  List<Widget> _section(BuildContext context, SpaceController c) {
    final s = context.l10n, lang = context.language;
    final metres = NumberFormat('0.0', lang);
    final axis = c.sectionAxis;
    final (lo, hi) = c.sectionRange();
    return [
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
          // A kit study is drawn in the building's frame (+y along its
          // axis), so its cuts are long and cross sections; P08's bay keeps
          // the compass.
          for (final (a, label) in [
            if (c.study.orientation == null) ...[
              (0, s.spaceCutNorthSouth),
              (1, s.spaceCutEastWest),
            ] else ...[
              (0, s.spaceCutLong),
              (1, s.spaceCutCross),
            ],
            (2, s.spaceCutPlan),
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
        value: c.sectionOffset.clamp(lo, hi),
        min: lo,
        max: hi,
        label: s.spaceMetres(metres.format(c.sectionOffset)),
        semanticFormatterCallback: (v) => s.spaceMetres(metres.format(v)),
        onChanged: c.setSectionOffset,
      ),
    ];
  }

  List<Widget> _style(BuildContext context, SpaceController c) {
    final s = context.l10n,
        lang = context.language,
        colors = MeasureColors.of(context);
    return [
      Text(
        TypeRole.capitals(s.spaceRendering, lang),
        style: TypeRole.measurement.copyWith(
          fontSize: 11,
          color: colors.secondary,
        ),
      ),
      const SizedBox(height: 6),
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
              showCheckmark: false,
              label: Text(label),
              selected: c.style == style,
              onSelected: (_) => c.setStyle(style),
            ),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        TypeRole.capitals(s.spaceCamera, lang),
        style: TypeRole.measurement.copyWith(
          fontSize: 11,
          color: colors.secondary,
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            key: const ValueKey('space-overview'),
            onPressed: c.overview,
            child: Text(s.spaceOverview),
          ),
          OutlinedButton(
            key: const ValueKey('space-choisy'),
            onPressed: c.choisy,
            child: Text(s.spaceChoisy),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(s.spaceChoisyHint, style: Theme.of(context).textTheme.bodySmall),
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
      Text(s.spaceGestureHint, style: Theme.of(context).textTheme.bodySmall),
    ];
  }

  List<Widget> _sources(BuildContext context, SpaceController c) {
    final lang = context.language;
    return [
      const SizedBox(height: 12),
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
    ];
  }
}

/// The steps as a row of chips: built ones filled. A tap builds up (or
/// takes down) to that step; the row keeps the latest step in view.
class _StepStrip extends StatefulWidget {
  const _StepStrip({required this.controller, required this.done});
  final SpaceController controller;
  final int done;
  @override
  State<_StepStrip> createState() => _StepStripState();
}

class _StepStripState extends State<_StepStrip> {
  final _keys = <String, GlobalKey>{};

  GlobalKey _key(SpaceStep s) => _keys.putIfAbsent(s.id, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    _reveal(animate: false);
  }

  @override
  void didUpdateWidget(_StepStrip old) {
    super.didUpdateWidget(old);
    if (old.done != widget.done) _reveal(animate: true);
  }

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Keeps the latest step built in view, scrolling the strip only:
  /// `Scrollable.ensureVisible` also scrolled the dock, moving − and + from
  /// under the finger. Jumps while the story plays: an animated scroll each
  /// beat would update semantics every frame.
  void _reveal({required bool animate}) {
    final c = widget.controller, steps = c.visibleSteps;
    if (steps.isEmpty) return;
    final i = (widget.done - 1).clamp(0, steps.length - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _keys[steps[i].id]?.currentContext?.findRenderObject();
      if (!mounted || chip == null || !_scroll.hasClients) return;
      final position = _scroll.position;
      final target = RenderAbstractViewport.of(chip)
          .getOffsetToReveal(chip, .5)
          .offset
          .clamp(position.minScrollExtent, position.maxScrollExtent);
      if (!animate || c.reduced || c.playing) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller, lang = context.language;
    // Every chip is built (a study has at most a dozen steps), so the
    // latest one can be scrolled to; a lazy list never built it (A52s,
    // 2026-11-16: the strip opened on I and II with VII built).
    return SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, step) in c.visibleSteps.indexed)
            Padding(
              key: _key(step),
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: ValueKey('space-step-${step.id}'),
                showCheckmark: false,
                label: Text('${_numeral(i)}  ${step.label.inLanguage(lang)}'),
                selected: i < widget.done,
                onSelected: (_) => c.buildTo(i + 1),
              ),
            ),
        ],
      ),
    );
  }
}

/// Crisp equal-width architectural year bar replacing the 4-column truncated
/// epoch slider: each year is cleanly selectable with full contrast and the
/// active epoch's complete caption reads below without clipping.
class _EpochSelector extends StatelessWidget {
  const _EpochSelector({required this.controller});
  final SpaceController controller;

  @override
  Widget build(BuildContext context) {
    final c = MeasureColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = dark ? c.ink : c.accent;
    final activeFg = c.ground;
    final s = context.l10n;
    final lang = context.language;
    final epochs = controller.study.epochs;
    final current = controller.visibleEpoch;
    return Container(
      key: const ValueKey('space-time'),
      decoration: BoxDecoration(
        borderRadius: Space.radius,
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, e) in epochs.indexed)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == current,
                  label: e.label.inLanguage(lang),
                  child: InkWell(
                    key: ValueKey('space-epoch-${e.year}'),
                    onTap: () => controller.setEpoch(i),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 46),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == current ? activeBg : c.ground,
                        border: i == 0
                            ? null
                            : Border(left: BorderSide(color: c.line)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          e.year < 0
                              ? s.atlasYearBc('${-e.year}')
                              : '${e.year}',
                          style: TypeRole.measurement.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: i == current ? activeFg : c.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
