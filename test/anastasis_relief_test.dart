import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'relief assets retain ordered, nonrectangular fresco silhouettes',
    () async {
      final manifest = jsonDecode(
        await rootBundle.loadString('assets/anastasis/relief_v3/manifest.json'),
      ) as Map<String, dynamic>;
      final layers = (manifest['layers'] as List).cast<Map<String, dynamic>>();
      final byId = {for (final layer in layers) layer['id'] as String: layer};
      expect(layers.length, 19);
      expect(byId.keys.toSet().length, layers.length);
      double depth(String id) => (byId[id]!['depth'] as num).toDouble();
      expect(depth('christ'), greaterThan(depth('adam')));
      expect(depth('christ'), greaterThan(depth('eve')));
      expect(depth('adam'), greaterThan(depth('left_front_group')));
      expect(depth('eve'), greaterThan(depth('right_front_group')));
      expect(
        depth('left_rear_group'),
        greaterThan(depth('left_mountain_front')),
      );
      expect(depth('left_front_group'), greaterThan(depth('left_mid_group')));
      expect(depth('left_mid_group'), greaterThan(depth('left_rear_group')));
      expect(depth('right_front_group'), greaterThan(depth('right_mid_group')));
      expect(depth('right_mid_group'), greaterThan(depth('right_rear_group')));
      expect(
        depth('left_mountain_front'),
        greaterThan(depth('left_mountain_mid')),
      );
      expect(
        depth('left_mountain_mid'),
        greaterThan(depth('left_mountain_back')),
      );
      expect(
        depth('right_mountain_front'),
        greaterThan(depth('right_mountain_mid')),
      );
      expect(
        depth('right_mountain_mid'),
        greaterThan(depth('right_mountain_back')),
      );
      for (final id in ['christ', 'adam', 'eve']) {
        final layer = byId[id]!;
        final crop = (layer['crop'] as List).cast<int>();
        final bytes = await rootBundle.load(layer['texture'] as String);
        final image = img.decodePng(bytes.buffer.asUint8List())!;
        expect(image.width, crop[2]);
        expect(image.height, crop[3]);
        var opaque = 0, clear = 0;
        for (var y = 0; y < image.height; y += 5) {
          for (var x = 0; x < image.width; x += 5) {
            if (image.getPixel(x, y).a > 127) {
              opaque++;
            } else {
              clear++;
            }
          }
        }
        expect(opaque, greaterThan(100));
        expect(
          clear,
          greaterThan(100),
          reason: '$id must not be a rectangular sprite',
        );
      }
    },
  );
}
