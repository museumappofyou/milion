import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../l10n/strings.dart';
import 'manifest.dart';
import 'player.dart';

enum PlatePanel { story, light, layers, debug, sources }

/// The controls for one panel. Story, Light, Layers and Debug dock under
/// the photograph, which stays in view and answers each change as it is
/// made (the owner, 2026-11-16, of the 3D studies: closing a sheet to see
/// what a control did was not playable). Sources, which is read, is a sheet.
class PlateSheet extends StatelessWidget {
  const PlateSheet({super.key, required this.player, required this.panel});
  final PlatePlayerState player;
  final PlatePanel panel;
  bool get docked => panel != PlatePanel.sources;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      player.controller,
      player.tilt,
      player.orientation,
    ]),
    builder: (context, _) {
      final s = context.l10n, c = player.controller, p = player.widget.manifest;
      final heading = switch (panel) {
        PlatePanel.story => s.plateStory,
        PlatePanel.light => s.light,
        PlatePanel.layers => s.plateLayers,
        PlatePanel.debug => s.plateDebug,
        PlatePanel.sources => s.plateSources,
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
            key: const ValueKey('plate-dock-close'),
            tooltip: s.plateClose,
            visualDensity: VisualDensity.compact,
            icon: Icon(docked ? Icons.expand_more : Icons.close),
            onPressed: docked
                ? player.closeControls
                : () => Navigator.pop(context),
          ),
        ],
      );
      Widget frame(Widget body) => docked
          // The header stays put while the controls scroll under it.
          ? ConstrainedBox(
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
            )
          : SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .78,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [header, const SizedBox(height: 12), body],
                  ),
                ),
              ),
            );
      return frame(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
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
                onChanged: (v) => c.reveal ? c.seekReveal(v) : c.seek(v),
              ),
              if (c.sample != null)
                Text(c.sample!.beat.caption.inLanguage(context.language)),
              if (c.visibleGesture > 0 && c.visibleGesture < 1) ...[
                const HonestyLabel(Honesty.IMAGINED),
                Text(s.plateMotionCaption),
              ],
              TextButton(
                onPressed: () => player.controls(PlatePanel.sources),
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
                onChanged: c.reduced || c.lookUp ? null : player.setGyro,
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
                    if (p.has(PlateLayerId.reconstruction))
                      (PlateLayerId.reconstruction, s.reconstruction),
                    if (p.has(PlateLayerId.imagined))
                      (PlateLayerId.imagined, s.imagined),
                  ])
                    ChoiceChip(
                      label: Text(item.$2),
                      selected: !c.lookUp && c.layer == item.$1,
                      onSelected: (_) => item.$1 == PlateLayerId.original
                          ? player.original()
                          : (c..setLookUp(false)).setLayer(item.$1),
                    ),
                  if (c.canLookUp)
                    ChoiceChip(
                      key: const ValueKey('plate-look-up-chip'),
                      label: Text(s.plateLookUp),
                      selected: c.lookUp,
                      onSelected: (v) => c.setLookUp(v),
                    ),
                ],
              ),
              if (c.lookUp) ...[
                Text(s.plateLookUpHint),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.plateLookUpSensor),
                  subtitle: Text(
                    player.orientation.unavailable
                        ? s.plateGyroUnavailable
                        : s.plateLookUpSensorHint,
                  ),
                  value: player.orientation.enabled,
                  onChanged: player.setLookUpSensor,
                ),
              ],
              if (maskedLayers.contains(c.layer)) ...[
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
              if (p.flowEffect != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.platePaintMotion),
                  value: c.flow,
                  onChanged: c.reduced
                      ? null
                      : (v) => c.setPaintMotion(river: v),
                ),
              if (p.spiralEffect != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.plateScrollMotion),
                  value: c.spiral,
                  onChanged: c.reduced
                      ? null
                      : (v) => c.setPaintMotion(scroll: v),
                ),
              TextButton(
                onPressed: () => player.controls(PlatePanel.sources),
                child: Text(s.plateSources),
              ),
              if (kDebugMode)
                TextButton(
                  onPressed: () => player.controls(PlatePanel.debug),
                  child: Text(s.plateDebug),
                ),
            ],
            if (panel == PlatePanel.debug) ...[
              // Only a plate with a rig has a gesture study to scrub.
              if (player.assets.rig != null) ...[
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
              ],
              if (p.has(PlateLayerId.reconstruction)) ...[
                Text(s.restorationAmount),
                Slider(value: c.restoration, onChanged: c.setRestoration),
              ],
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
      );
    },
  );
}
