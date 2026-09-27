import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Future<img.Image> _decode(String path) async {
  final bytes = await rootBundle.load(path);
  return img.decodeImage(bytes.buffer.asUint8List())!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v5 views stay on the master pixel grid', () async {
    final manifest = jsonDecode(
      await rootBundle.loadString('assets/anastasis/relief_v5/manifest.json'),
    ) as Map<String, dynamic>;
    final size = (manifest['size'] as List).cast<int>();
    final views = (manifest['views'] as List).cast<Map<String, dynamic>>();
    expect(views.map((v) => v['id']), containsAll(['relief', 'semantic']));
    for (final view in views) {
      final image = await _decode(view['file'] as String);
      expect([image.width, image.height], size, reason: view['id'] as String);
    }
  });

  test(
    'relief only modulates the original RGB within the light clamp',
    () async {
      final original = await _decode('assets/anastasis/conch_reference.jpg');
      final relief = await _decode(
        'assets/anastasis/relief_v5/relief_front.jpg',
      );
      var samples = 0, brighter = 0, changed = 0;
      for (var y = 2; y < original.height; y += 7) {
        for (var x = 2; x < original.width; x += 7) {
          final o = original.getPixel(x, y), r = relief.getPixel(x, y);
          final lo = o.r + o.g + o.b, lr = r.r + r.g + r.b;
          samples++;
          // 1.08 clamp plus JPEG tolerance.
          if (lr > lo * 1.08 + 18) brighter++;
          if ((lr - lo).abs() > 12) changed++;
        }
      }
      expect(brighter / samples, lessThan(.01), reason: 'no recoloring glow');
      expect(changed / samples, greaterThan(.15), reason: 'relief is visible');
    },
  );

  test(
    'semantic map separates rear, middle and front figures on both sides',
    () async {
      final semantic = await _decode(
        'assets/anastasis/relief_v5/semantic_layers.png',
      );
      const clusters = {
        'rear': (124, 72, 170),
        'middle': (60, 110, 215),
        'front': (40, 170, 80),
        'principal': (245, 140, 30),
        'mandorla': (40, 215, 225),
        'christ': (225, 40, 40),
      };
      final left = <String>{}, right = <String>{};
      for (var y = 0; y < semantic.height; y += 3) {
        for (var x = 0; x < semantic.width; x += 3) {
          final p = semantic.getPixel(x, y);
          for (final entry in clusters.entries) {
            final (r, g, b) = entry.value;
            if (p.r == r && p.g == g && p.b == b) {
              (x < semantic.width / 2 ? left : right).add(entry.key);
            }
          }
        }
      }
      for (final side in [left, right]) {
        expect(side, containsAll(['rear', 'middle', 'front', 'principal']));
      }
      expect({...left, ...right}, containsAll(['mandorla', 'christ']));
    },
  );
}
