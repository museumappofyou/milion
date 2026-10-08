import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> loadMap(String path) async {
  final data = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('P06 maps are bundled at the size of the source photographs', () async {
    for (final (plate, width, height, maps) in [
      ('anastasis', 2048, 1091, ['surface', 'gold', 'damaged']),
      (
        'judgment',
        1600,
        1067,
        ['surface', 'gold', 'river', 'scroll', 'damaged'],
      ),
    ]) {
      for (final name in maps) {
        final path = 'assets/plates/$plate/$name.png';
        final image = await loadMap(path);
        try {
          expect(image.width, width, reason: path);
          expect(image.height, height, reason: path);
        } finally {
          image.dispose();
        }
      }
    }
  });

  test(
    'the shader river coverage channel leaves the rest of the paint still',
    () async {
      final image = await loadMap('assets/plates/judgment/river.png');
      try {
        final rgba = (await image.toByteData())!.buffer.asUint8List();
        var covered = 0;
        for (var i = 0; i < rgba.length; i += 4) {
          if (rgba[i] > 0) covered++;
        }
        // The annotated river is a small part of the lower-right vault.
        // A BGR/RGB mix-up made every pixel nonzero in the shader's R mask.
        final fraction = covered / (image.width * image.height);
        expect(fraction, inExclusiveRange(.01, .15));
        expect(rgba[0], 0, reason: 'the upper-left background cannot flow');
      } finally {
        image.dispose();
      }
    },
  );
}
