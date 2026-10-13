import 'dart:typed_data';
import 'dart:ui' as ui;

import 'controller.dart';
import 'model.dart';
import 'renderer.dart';
import 'study.dart';
import 'style.dart';

/// P17 share hooks: the scene drawn offscreen at any size, independent of the
/// screen and the player's own state.
Future<ui.Image> renderSpaceStill(
  SpaceRenderer renderer,
  SpaceScene scene,
  ui.Size size, {
  double pixelRatio = 1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..scale(pixelRatio);
  renderer.paint(canvas, size, scene);
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(
      (size.width * pixelRatio).round(),
      (size.height * pixelRatio).round(),
    );
  } finally {
    picture.dispose();
  }
}

Future<Uint8List> encodePng(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();

/// Frames of the reveal (or the story) at [fps], from a private controller so
/// a capture never moves what the reader is looking at. Each image is the
/// caller's to dispose.
Stream<ui.Image> spaceFrames(
  SpaceStudy study,
  SpaceModel model,
  ui.Size size, {
  bool reveal = true,
  double fps = 24,
  double pixelRatio = 1,
  SpaceStyle style = SpaceStyle.drawing,
}) async* {
  final controller = SpaceController(study, model)..setStyle(style);
  final renderer = SpaceRenderer(model);
  try {
    if (reveal) controller.playReveal();
    final seconds = reveal ? study.reveal.seconds : study.storySeconds;
    final count = (seconds * fps).round();
    for (var i = 0; i < count; i++) {
      final t = i / fps;
      reveal ? controller.seekReveal(t) : controller.seek(t);
      yield await renderSpaceStill(
        renderer,
        controller.scene(),
        size,
        pixelRatio: pixelRatio,
      );
    }
  } finally {
    renderer.dispose();
    controller.dispose();
  }
}
