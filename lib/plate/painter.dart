import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../widgets/interactive_relief_surface.dart';
import 'assets.dart';
import 'controller.dart';
import 'manifest.dart';

/// Separate cached shader instances keep masked passes composable.
class PlatePainter extends CustomPainter {
  PlatePainter({
    required this.assets,
    required this.manifest,
    required this.frame,
    required this.controller,
    this.tilt = Offset.zero,
    this.lightPosition = const Offset(.5, .5),
  });
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
    final gesture = controller.visibleGesture;
    if (gesture > 0 && gesture < 1) {
      final g = controller.sample?.beat.gesture;
      InteractiveReliefSurface(
        texture: original,
        sourceSize: assets.sourceSize,
        rig: assets.rig!,
        frame: frame,
        phase: gesture,
        posed: true,
        motionAmount: g?.strength ?? controller.gestureStrength,
        gestureWindows: [
          for (final w in g?.windows ?? const [])
            Rect.fromLTRB(w.left, w.top, w.right, w.bottom),
        ],
      ).paint(canvas, size);
      return;
    }
    if (controller.layer == PlateLayerId.reconstruction) {
      _flat(canvas, original);
      final l = manifest.layer(PlateLayerId.reconstruction);
      _pass(
        canvas,
        3,
        assets.images[l.asset]!,
        l.mask!,
        mode: 6,
        amount: controller.restoration,
        light: Offset(controller.wipe, .5),
      );
      return;
    }
    final light = controller.visibleLight;
    final base = assets.images[manifest.layer(PlateLayerId.depth).asset]!;
    final reduced = controller.reduced;
    _pass(
      canvas,
      0,
      base,
      manifest.maps.gold,
      mode: light.index.toDouble(),
      time: reduced ? 0 : controller.effectSeconds,
      amount: 1,
      depth: reduced ? 0 : .025,
    );
    final t = controller.storyActive
        ? controller.seconds
        : controller.effectSeconds;
    if (controller.visibleFlow && manifest.maps.flow != null) {
      _pass(
        canvas,
        1,
        base,
        manifest.maps.flow!,
        mode: 4,
        time: t,
        flow: .025,
        depth: reduced ? 0 : .025,
      );
    }
    if (controller.visibleSpiral && manifest.maps.scroll != null) {
      _pass(
        canvas,
        2,
        base,
        manifest.maps.scroll!,
        mode: 5,
        time: t,
        flow: .7 * (.5 - .5 * math.cos(t * math.pi / 4)),
        depth: reduced ? 0 : .025,
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
    required double mode,
    double time = 0,
    double amount = 1,
    double flow = 0,
    double depth = 0,
    Offset? light,
  }) {
    final shader = assets.shader(slot);
    final p =
        light ??
        (mode == 2 ? lightPosition * 2 - const Offset(1, 1) : lightPosition);
    // Float indices follow shaders/plate.frag; samplers have their own indices.
    final floats = [
      frame.left,
      frame.top,
      frame.width,
      frame.height,
      texture.width.toDouble(),
      texture.height.toDouble(),
      mode,
      time,
      controller.reduced ? 0.0 : tilt.dx,
      controller.reduced ? 0.0 : tilt.dy,
      p.dx,
      p.dy,
      amount,
      flow,
      manifest.scrollCenter[0],
      manifest.scrollCenter[1],
      depth,
    ];
    for (var i = 0; i < floats.length; i++) {
      shader.setFloat(i, floats[i]);
    }
    shader.setImageSampler(0, texture);
    shader.setImageSampler(1, assets.images[manifest.maps.surface]!);
    shader.setImageSampler(2, assets.images[mask]!);
    canvas.drawRect(frame, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(PlatePainter old) => true;
}
