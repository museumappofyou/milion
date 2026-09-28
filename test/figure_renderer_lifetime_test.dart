import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:milion/services/figure_rig.dart';
import 'package:milion/widgets/interactive_relief_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> texture(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(color, BlendMode.src);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 8, 8),
    Paint()..color = Colors.white,
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(16, 16);
  } finally {
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final version in [1, 2]) {
    test(
      'v$version successive figure poses keep borrowed textures alive',
      () async {
        final original = await texture(Colors.red);
        final study = await texture(Colors.blue);
        final rig = FigureRig(
          {
            'cols': 3,
            'rows': 3,
            'vertices': [4],
            'offsets': [.02, .01, .01, -.01],
            'gestures': ['test gesture'],
            if (version == 2) 'frames': 4,
          },
          poseData: version == 2
              ? ByteData.view(
                  Float32List.fromList([0, 0, .02, .01, 0, 0, -.02, -.01])
                      .buffer,
                )
              : null,
        );
        for (var frame = 0; frame < 24; frame++) {
          final recorder = ui.PictureRecorder();
          InteractiveReliefSurface(
            texture: original,
            study: study,
            studyAmount: .35,
            sourceSize: const Size(16, 16),
            rig: rig,
            frame: const Rect.fromLTWH(0, 0, 32, 32),
            phase: (frame + 1) / 25,
            posed: true,
          ).paint(Canvas(recorder), const Size(32, 32));
          final picture = recorder.endRecording();
          expect(
            original.debugDisposed,
            isFalse,
            reason: 'Frame $frame disposed the shared scene image',
          );
          expect(
            study.debugDisposed,
            isFalse,
            reason: 'Frame $frame disposed the shared restoration image',
          );
          final raster = await picture.toImage(32, 32);
          final bytes = await raster.toByteData();
          expect(bytes, isNotNull);
          expect(bytes!.getUint8((20 * 32 + 20) * 4 + 3), 255);
          raster.dispose();
          picture.dispose();
        }
        rig.dispose();
        expect(original.debugDisposed, isFalse);
        expect(study.debugDisposed, isFalse);
        // Closing the scene releases the images once, independently of shaders.
        original.dispose();
        study.dispose();
      },
    );
  }
}
