import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../design/components.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../today/detail_crop.dart';
import 'camera.dart';
import 'look_up.dart';
import 'manifest.dart';
import 'painter.dart';
import 'player.dart';

class PlateViewport extends StatelessWidget {
  const PlateViewport({super.key, required this.player, this.loading = false});
  final PlatePlayerState player;
  final bool loading;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      player.sizeChanged(constraints.biggest);
      final c = player.controller, d = player.widget.initialDetail;
      final frame = plateFrame(player.viewport, player.sourceSize);
      return ListenableBuilder(
        listenable: Listenable.merge([c, player.tilt, player.transformation]),
        builder: (context, _) {
          final detail = player.detail;
          final interactive = c.layer == PlateLayerId.original;
          return Stack(
            children: [
              Positioned.fill(
                child: PlateSemantics(
                  player: player,
                  child: GestureDetector(
                    onTapDown: (_) => player.tilt.recenter(),
                    onLongPressStart: (_) => c.peek(true),
                    onLongPressEnd: (_) => c.peek(false),
                    onLongPressCancel: () => c.peek(false),
                    onDoubleTap: () =>
                        player.zoomBy(player.zoom > 1 ? 1 / player.zoom : 2),
                    child: InteractiveViewer(
                      key: const ValueKey('plate-interactive-viewer'),
                      transformationController: player.transformation,
                      minScale: 1,
                      maxScale: 8,
                      panEnabled: interactive,
                      scaleEnabled: true,
                      onInteractionStart: (_) => player.beginExplore(),
                      onInteractionUpdate: (event) {
                        if (!interactive && event.pointerCount == 1) {
                          player.drag(event.localFocalPoint);
                        }
                      },
                      onInteractionEnd: (_) =>
                          player.transformation.value = boundPlateCamera(
                            player.viewport,
                            player.sourceSize,
                            player.transformation.value,
                          ),
                      child: RepaintBoundary(
                        key: const ValueKey('plate-paint'),
                        child: SizedBox.expand(
                          child: loading
                              ? const SizedBox.shrink()
                              // Readings repaint the picture only; the
                              // Semantics above rebuild on state changes.
                              : ValueListenableBuilder<int>(
                                  valueListenable: player.tilt.motion,
                                  builder: (context, _, _) => CustomPaint(
                                    painter: PlatePainter(
                                      assets: player.assets,
                                      manifest: player.widget.manifest,
                                      frame: frame,
                                      controller: c,
                                      tilt: player.visibleTilt,
                                      lightPosition: player.lightPosition,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (player.heroShown && d != null)
                Positioned.fromRect(
                  rect: MatrixUtils.transformRect(
                    player.transformation.value,
                    plateWindow(frame, d.window),
                  ),
                  child: IgnorePointer(
                    child: Hero(
                      tag: detailHeroTag(d),
                      transitionOnUserGestures: true,
                      child: DetailCrop(
                        asset: player.widget.manifest.original,
                        source: player.sourceSize,
                        window: d.window,
                      ),
                    ),
                  ),
                ),
              if (detail != null && !loading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _Anchor(
                        MatrixUtils.transformPoint(
                          player.transformation.value,
                          Offset(
                            frame.left + detail.anchorX * frame.width,
                            frame.top + detail.anchorY * frame.height,
                          ),
                        ),
                        MeasureColors.of(context).accent,
                      ),
                    ),
                  ),
                ),
              ...plateOverlay(context, player),
            ],
          );
        },
      );
    },
  );
}

/// TalkBack: the plate's description, plus the story and Original actions.
class PlateSemantics extends StatelessWidget {
  const PlateSemantics({super.key, required this.player, required this.child});
  final PlatePlayerState player;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final m = player.widget.manifest, c = player.controller, s = context.l10n;
    return Semantics(
      label:
          '${m.title.inLanguage(context.language)}. '
          '${m.description.inLanguage(context.language)}',
      customSemanticsActions: {
        CustomSemanticsAction(label: s.original): player.original,
        CustomSemanticsAction(label: s.plateNext): () => c.step(1),
        CustomSemanticsAction(label: s.platePrevious): () => c.step(-1),
      },
      child: child,
    );
  }
}

/// The honesty label (one tap back to ORIGINAL) and the beat or detail
/// caption, shared by the flat plate and the look-up.
List<Widget> plateOverlay(BuildContext context, PlatePlayerState player) {
  final c = player.controller;
  final caption =
      c.sample?.beat.caption.inLanguage(context.language) ??
      player.detail?.sentence.inLanguage(context.language);
  final ground = Theme.of(context).scaffoldBackgroundColor
      .withValues(alpha: .94);
  return [
    Positioned(
      top: 8,
      left: 12,
      child: DecoratedBox(
        decoration: BoxDecoration(color: ground),
        child: Tooltip(
          message: context.l10n.plateOriginalHint,
          child: TextButton(
            key: const ValueKey('plate-original'),
            onPressed: player.original,
            child: HonestyLabel(c.honesty),
          ),
        ),
      ),
    ),
    if (caption != null)
      Positioned(
        bottom: 8,
        left: 12,
        right: 12,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: player.viewport.height * .28),
          child: DecoratedBox(
            decoration: BoxDecoration(color: ground),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              // Captions change once per beat, so they are announced.
              child: Semantics(
                liveRegion: true,
                child: Text(
                  caption,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ),
      ),
  ];
}

/// LU: the dome overhead, with the same label, caption and actions.
class PlateLookUpScene extends StatelessWidget {
  const PlateLookUpScene({super.key, required this.player});
  final PlatePlayerState player;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      player.sizeChanged(constraints.biggest);
      return ListenableBuilder(
        listenable: player.controller,
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(
              child: PlateSemantics(
                player: player,
                child: PlateLookUpView(
                  assets: player.assets,
                  manifest: player.widget.manifest,
                  controller: player.controller,
                  orientation: player.orientation,
                ),
              ),
            ),
            ...plateOverlay(context, player),
          ],
        ),
      );
    },
  );
}

class _Anchor extends CustomPainter {
  _Anchor(this.point, this.color);
  final Offset point;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (!(Offset.zero & size).contains(point)) return;
    final p = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(point, 4, p);
    canvas.drawPath(
      Path()
        ..moveTo(point.dx, point.dy)
        ..relativeLineTo(18, -18)
        ..lineTo((point.dx + 80).clamp(0, size.width - 12), point.dy - 18),
      p,
    );
  }

  @override
  bool shouldRepaint(_Anchor old) => point != old.point || color != old.color;
}
