import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/figure_rig.dart';

/// Articulated figure gestures on the existing v5 photograph and relief.
class InteractiveReliefSurface extends CustomPainter {
  InteractiveReliefSurface({
    required this.texture,
    required this.sourceSize,
    required this.rig,
    required this.frame,
    this.study,
    this.studyAmount = 0,
    this.phase = 0,
    this.motionAmount = 1,
    this.posed = false,
  });
  final ui.Image texture;
  final ui.Image? study;
  final double studyAmount, phase, motionAmount;
  final Size sourceSize;
  final FigureRig rig;
  final Rect frame;
  final bool posed;

  static Rect fitFrame(Size viewport, Size source) {
    final fitted = applyBoxFit(BoxFit.contain, source, viewport).destination;
    return Alignment.center.inscribe(fitted, Offset.zero & viewport);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!posed || phase == 0 || phase == 1) {
      if (study == null || studyAmount < 1) _flat(canvas, texture, 1);
      if (study != null && studyAmount > 0) _flat(canvas, study!, studyAmount);
    } else {
      _mesh(canvas);
    }
  }

  void _flat(Canvas canvas, ui.Image image, double opacity) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      frame,
      Paint()
        ..filterQuality = FilterQuality.high
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
  }

  void _mesh(Canvas canvas) {
    final positions = rig.positions(phase, frame, intensity: motionAmount);
    if (study == null || studyAmount < 1) {
      _meshLayer(canvas, positions, texture, 1);
    }
    if (study != null && studyAmount > 0) {
      _meshLayer(canvas, positions, study!, studyAmount);
    }
  }

  void _meshLayer(
    Canvas canvas,
    Float32List positions,
    ui.Image image,
    double opacity,
  ) {
    final shader = rig.shaderFor(image);
    final mesh = ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: rig.textureCoordinates(image),
      indices: rig.indices,
    );
    try {
      canvas.drawVertices(
        mesh,
        BlendMode.srcOver,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, opacity)
          ..shader = shader,
      );
    } finally {
      mesh.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant InteractiveReliefSurface old) =>
      old.texture != texture ||
      old.study != study ||
      old.studyAmount != studyAmount ||
      old.frame != frame ||
      old.phase != phase ||
      old.motionAmount != motionAmount ||
      old.posed != posed;
}
