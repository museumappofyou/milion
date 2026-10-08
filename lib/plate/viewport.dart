import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/tokens.dart';
import '../l10n/strings.dart';
import '../today/detail_crop.dart';
import 'camera.dart';
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
          final caption =
              c.sample?.beat.caption.inLanguage(context.language) ??
              detail?.sentence.inLanguage(context.language);
          final interactive = c.layer == PlateLayerId.original;
          return Stack(
            children: [
              Positioned.fill(
                child: Semantics(
                  label: player.widget.manifest.title.inLanguage(
                    context.language,
                  ),
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
                              : CustomPaint(
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
              Positioned(
                top: 8,
                left: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor
                        .withValues(alpha: .94),
                  ),
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
                    constraints: BoxConstraints(
                      maxHeight: player.viewport.height * .28,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor
                            .withValues(alpha: .94),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Semantics(
                          liveRegion: !c.playing,
                          child: Text(
                            caption,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
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
