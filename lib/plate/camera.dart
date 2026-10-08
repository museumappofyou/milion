import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../content/models.dart';

Rect plateFrame(Size viewport, Size source) => Alignment.center.inscribe(
  applyBoxFit(BoxFit.contain, source, viewport).destination,
  Offset.zero & viewport,
);
Rect plateWindow(Rect frame, NormalRect w) => Rect.fromLTRB(
  frame.left + w.left * frame.width,
  frame.top + w.top * frame.height,
  frame.left + w.right * frame.width,
  frame.top + w.bottom * frame.height,
);

/// The first view fills the artwork area; Overview can reveal the whole plate.
Matrix4 plateCoverCamera(Size viewport, Size source) {
  final f = plateFrame(viewport, source);
  final s = math.max(viewport.width / f.width, viewport.height / f.height);
  return boundPlateCamera(
    viewport,
    source,
    Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - f.center.dx * s,
        viewport.height / 2 - f.center.dy * s,
        0,
        1,
      )
      ..scaleByDouble(s, s, 1, 1),
  );
}

Matrix4 boundPlateCamera(Size viewport, Size source, Matrix4 value) {
  if (viewport.isEmpty) return Matrix4.identity();
  final s = value.getMaxScaleOnAxis().clamp(1.0, 8.0),
      t = value.getTranslation();
  final f = plateFrame(viewport, source);
  final x = f.width * s <= viewport.width
      ? viewport.width / 2 - f.center.dx * s
      : t.x.clamp(viewport.width - f.right * s, -f.left * s);
  final y = f.height * s <= viewport.height
      ? viewport.height / 2 - f.center.dy * s
      : t.y.clamp(viewport.height - f.bottom * s, -f.top * s);
  return Matrix4.identity()
    ..translateByDouble(x, y, 0, 1)
    ..scaleByDouble(s, s, 1, 1);
}

Matrix4 plateWindowCamera(Size viewport, Size source, NormalRect window) {
  final crop = plateWindow(plateFrame(viewport, source), window);
  final s = math
      .min(
        (viewport.width - 32) / crop.width,
        (viewport.height - 32) / crop.height,
      )
      .clamp(1.0, 8.0);
  return boundPlateCamera(
    viewport,
    source,
    Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - crop.center.dx * s,
        viewport.height / 2 - crop.center.dy * s,
        0,
        1,
      )
      ..scaleByDouble(s, s, 1, 1),
  );
}
