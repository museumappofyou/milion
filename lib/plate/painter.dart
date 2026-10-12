import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../widgets/interactive_relief_surface.dart';
import 'assets.dart';
import 'controller.dart';
import 'manifest.dart';

/// Shader `uEffect` values; see shaders/plate.frag.
enum PlateEffect { plate, flow, spiral, wipe }

/// Separate cached shader instances keep masked passes composable. Repaints
/// follow the controller; a camera-only change reuses the painted layer.
class PlatePainter extends CustomPainter {
  PlatePainter({
    required this.assets,
    required this.manifest,
    required this.frame,
    required this.controller,
    this.tilt = Offset.zero,
    this.lightPosition = const Offset(.5, .5),
  }) : super(repaint: controller);
  final PlateAssets assets;
  final PlateManifest manifest;
  final Rect frame;
  final PlateController controller;
  final Offset tilt, lightPosition;

  @override
  void paint(Canvas canvas, Size size) {
    if (assets.disposed || frame.isEmpty) return;
    final original = assets.images[manifest.original]!;
    if (controller.peekOriginal ||
        (controller.layer == PlateLayerId.original &&
            !controller.storyActive &&
            (controller.visibleGesture <= 0 ||
                controller.visibleGesture >= 1))) {
      _flat(canvas, original);
      return;
    }
    final base = assets.images[manifest.depthAsset]!;
    final gesture = controller.visibleGesture;
    final rig = assets.rig;
    if (gesture > 0 && gesture < 1 && rig != null) {
      final g = controller.sample?.beat.gesture;
      // The rig draws the same texture as the story around it, so the beat
      // starts and settles without a pop. Story beats play one reach and
      // return: the first half of the rig's two-cycle study loop.
      InteractiveReliefSurface(
        texture: base,
        sourceSize: assets.sourceSize,
        rig: rig,
        frame: frame,
        phase: g == null ? gesture : gesture * .5,
        posed: true,
        motionAmount: g?.strength ?? controller.gestureStrength,
        gestureWindows: [
          for (final w in g?.windows ?? const [])
            Rect.fromLTRB(w.left, w.top, w.right, w.bottom),
        ],
      ).paint(canvas, size);
      return;
    }
    final reconstruction = manifest.layer(PlateLayerId.reconstruction);
    if (controller.layer == PlateLayerId.reconstruction &&
        reconstruction != null) {
      _flat(canvas, original);
      _pass(
        canvas,
        3,
        assets.images[reconstruction.asset]!,
        reconstruction.mask!,
        effect: PlateEffect.wipe,
        amount: controller.restoration,
        point: Offset(controller.wipe, .5),
      );
      return;
    }
    final light = controller.visibleLight;
    final reduced = controller.reduced;
    final depth = reduced ? 0.0 : .025;
    final t = controller.storyActive
        ? controller.seconds
        : controller.effectSeconds;
    _pass(
      canvas,
      0,
      base,
      manifest.maps.gold,
      light: light,
      time: reduced ? 0 : controller.effectSeconds,
      depth: depth,
    );
    final flow = manifest.flowEffect;
    if (controller.visibleFlow && flow != null) {
      _pass(
        canvas,
        1,
        base,
        flow.mask,
        effect: PlateEffect.flow,
        light: light,
        time: t,
        flow: Offset(flow.period, flow.distance),
        depth: depth,
      );
    }
    final spiral = manifest.spiralEffect;
    if (controller.visibleSpiral && spiral != null) {
      _pass(
        canvas,
        2,
        base,
        spiral.mask,
        effect: PlateEffect.spiral,
        light: light,
        time: t,
        flow: Offset(.7 * (.5 - .5 * math.cos(t * math.pi / 4)), 0),
        center: Offset(spiral.center[0], spiral.center[1]),
        depth: depth,
      );
    }
  }

  void _flat(Canvas canvas, ui.Image image) => canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    frame,
    Paint()..filterQuality = FilterQuality.high,
  );
  void _pass(
    Canvas canvas,
    int slot,
    ui.Image texture,
    String mask, {
    PlateEffect effect = PlateEffect.plate,
    PlateLight light = PlateLight.none,
    double time = 0,
    double amount = 1,
    Offset flow = Offset.zero,
    Offset center = const Offset(.5, .5),
    double depth = 0,
    Offset? point,
  }) {
    final shader = assets.shader(slot);
    final p =
        point ??
        (light == PlateLight.raking
            ? lightPosition * 2 - const Offset(1, 1)
            : lightPosition);
    // Float indices follow shaders/plate.frag; samplers have their own indices.
    final floats = [
      frame.left,
      frame.top,
      frame.width,
      frame.height,
      texture.width.toDouble(),
      texture.height.toDouble(),
      light.index.toDouble(),
      effect.index.toDouble(),
      time,
      controller.reduced ? 0.0 : tilt.dx,
      controller.reduced ? 0.0 : tilt.dy,
      p.dx,
      p.dy,
      amount,
      flow.dx,
      flow.dy,
      center.dx,
      center.dy,
      depth,
    ];
    for (var i = 0; i < floats.length; i++) {
      shader.setFloat(i, floats[i]);
    }
    shader.setImageSampler(0, texture, filterQuality: FilterQuality.medium);
    shader.setImageSampler(
      1,
      assets.images[manifest.maps.surface]!,
      filterQuality: FilterQuality.low,
    );
    shader.setImageSampler(
      2,
      assets.images[mask]!,
      filterQuality: FilterQuality.low,
    );
    canvas.drawRect(frame, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(PlatePainter old) =>
      old.assets != assets ||
      old.manifest != manifest ||
      old.frame != frame ||
      old.controller != controller ||
      old.tilt != tilt ||
      old.lightPosition != lightPosition;
}
