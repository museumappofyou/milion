import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../l10n/strings.dart';
import 'manifest.dart';
import 'player.dart';

enum PlatePanel { story, light, layers, debug, sources }

/// Scrollable controls leave the photograph full height while exploring.
class PlateSheet extends StatelessWidget {
  const PlateSheet({super.key, required this.player, required this.panel});
  final PlatePlayerState player;
  final PlatePanel panel;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([player.controller, player.tilt]),
    builder: (context, _) {
      final s = context.l10n, c = player.controller, p = player.widget.manifest;
      final heading = switch (panel) {
        PlatePanel.story => s.plateStory,
        PlatePanel.light => s.light,
        PlatePanel.layers => s.plateLayers,
        PlatePanel.debug => s.plateDebug,
        PlatePanel.sources => s.plateSources,
      };
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
                if (panel == PlatePanel.story) ...[
                  if (c.reduced) Text(s.plateStillHint),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!c.reduced)
                        OutlinedButton(
                          onPressed: c.playReveal,
                          child: Text(s.plateStartReveal),
                        ),
                      if (!c.reduced)
                        FilledButton(
                          onPressed: c.playing ? c.pause : c.play,
                          child: Text(c.playing ? s.platePause : s.platePlay),
                        ),
                      OutlinedButton(
                        onPressed: () => c.step(-1),
                        child: Text(s.platePrevious),
                      ),
                      OutlinedButton(
                        onPressed: () => c.step(1),
                        child: Text(s.plateNext),
                      ),
                    ],
                  ),
                  Text(c.reveal ? s.plateReveal : s.plateTimeline),
                  Slider(
                    key: const ValueKey('plate-timeline'),
                    value: c.seconds.clamp(0, c.duration),
                    min: 0,
                    max: c.duration,
                    label: '${c.seconds.toStringAsFixed(1)} s',
                    semanticFormatterCallback: (v) =>
                        '${v.round()} / ${c.duration.round()}',
                    onChanged: (v) => c.reveal
                        ? c.seek(v / c.duration * p.storySeconds)
                        : c.seek(v),
                  ),
                  if (c.sample != null)
                    Text(c.sample!.beat.caption.inLanguage(context.language)),
                  if (c.visibleGesture > 0 && c.visibleGesture < 1) ...[
                    const HonestyLabel(Honesty.IMAGINED),
                    Text(s.plateMotionCaption),
                  ],
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      player.controls(PlatePanel.sources);
                    },
                    child: Text(s.plateSources),
                  ),
                ],
                if (panel == PlatePanel.light) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in [
                        (PlateLight.none, s.plateNoLight),
                        (PlateLight.gilded, s.plateGilded),
                        (PlateLight.raking, s.plateRaking),
                        (PlateLight.candle, s.plateCandle),
                      ])
                        ChoiceChip(
                          label: Text(item.$2),
                          selected: c.visibleLight == item.$1,
                          onSelected: (_) => c.setLight(item.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c.visibleLight == PlateLight.candle
                        ? s.plateCandleHint
                        : c.visibleLight == PlateLight.raking
                        ? s.plateRakingHint
                        : s.plateDragHint,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.plateGyro),
                    subtitle: Text(
                      player.tilt.unavailable
                          ? s.plateGyroUnavailable
                          : s.plateGyroHint,
                    ),
                    value: player.tilt.enabled,
                    onChanged: c.reduced
                        ? null
                        : (value) {
                            if (value) c.setLayer(PlateLayerId.depth);
                            player.tilt.setEnabled(value);
                          },
                  ),
                  if (c.reduced) Text(s.plateStillHint),
                ],
                if (panel == PlatePanel.layers) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in [
                        (PlateLayerId.original, s.original),
                        (PlateLayerId.depth, s.depth),
                        (PlateLayerId.reconstruction, s.reconstruction),
                      ])
                        ChoiceChip(
                          label: Text(item.$2),
                          selected: c.layer == item.$1,
                          onSelected: (_) => item.$1 == PlateLayerId.original
                              ? player.original()
                              : c.setLayer(item.$1),
                        ),
                    ],
                  ),
                  if (c.layer == PlateLayerId.reconstruction) ...[
                    Text(s.plateWipeHint),
                    Slider(
                      key: const ValueKey('plate-wipe'),
                      value: c.wipe,
                      onChanged: c.setWipe,
                      semanticFormatterCallback: (v) => '${(v * 100).round()}%',
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(c.selectedDetail),
                    initialValue: c.selectedDetail ?? '',
                    isExpanded: true,
                    decoration: InputDecoration(labelText: s.plateDetails),
                    items: [
                      DropdownMenuItem(value: '', child: Text(s.overview)),
                      for (final d in p.details)
                        DropdownMenuItem(
                          value: d.id,
                          child: Text(
                            d.title.inLanguage(context.language),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (id) => player.focus(id == '' ? null : id),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        tooltip: s.zoomOut,
                        onPressed: () => player.zoomBy(.8),
                        icon: const Icon(Icons.remove),
                      ),
                      IconButton(
                        tooltip: s.zoomIn,
                        onPressed: () => player.zoomBy(1.25),
                        icon: const Icon(Icons.add),
                      ),
                      TextButton(
                        onPressed: () => player.focus(null),
                        child: Text(s.resetView),
                      ),
                    ],
                  ),
                  if (p.maps.flow != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.platePaintMotion),
                      value: c.flow,
                      onChanged: c.reduced
                          ? null
                          : (v) => c.setPaintMotion(river: v),
                    ),
                  if (p.maps.scroll != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.plateScrollMotion),
                      value: c.spiral,
                      onChanged: c.reduced
                          ? null
                          : (v) => c.setPaintMotion(scroll: v),
                    ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      player.controls(PlatePanel.sources);
                    },
                    child: Text(s.plateSources),
                  ),
                  if (kDebugMode)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        player.controls(PlatePanel.debug);
                      },
                      child: Text(s.plateDebug),
                    ),
                ],
                if (panel == PlatePanel.debug) ...[
                  const HonestyLabel(Honesty.IMAGINED),
                  Text(s.singleGesture),
                  Text(s.pose),
                  Slider(
                    key: const ValueKey('plate-pose'),
                    value: c.gesturePose,
                    onChanged: c.scrubGesture,
                  ),
                  Text(s.movement),
                  Slider(
                    key: const ValueKey('plate-strength'),
                    value: c.gestureStrength,
                    min: .1,
                    max: .35,
                    onChanged: c.setStrength,
                  ),
                  if (!c.reduced)
                    OutlinedButton(
                      onPressed: c.gesturePlaying ? c.pause : c.playGesture,
                      child: Text(
                        c.gesturePlaying ? s.pauseGesture : s.playGesture,
                      ),
                    ),
                  Text(s.restorationAmount),
                  Slider(value: c.restoration, onChanged: c.setRestoration),
                  if (c.reduced) Text(s.plateStillHint),
                ],
                if (panel == PlatePanel.sources) ...[
                  Text(p.credit.inLanguage(context.language)),
                  if (p.originalSourceUrl != null)
                    SelectableText(p.originalSourceUrl!),
                  const SizedBox(height: 16),
                  for (final source in p.citations)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.title.inLanguage(context.language),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(source.author.inLanguage(context.language)),
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
