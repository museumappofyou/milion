import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:milion/plate/assets.dart';
import 'package:milion/plate/controller.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/plate/painter.dart';

Future<Uint8List> pixels(
  PlateManifest p,
  PlateAssets assets,
  PlateController c,
) async {
  final recorder = ui.PictureRecorder(), size = assets.sourceSize;
  PlatePainter(
    assets: assets,
    manifest: p,
    frame: ui.Offset.zero & size,
    controller: c,
  ).paint(ui.Canvas(recorder), size);
  final picture = recorder.endRecording(),
      image = await picture.toImage(p.width, p.height);
  final bytes = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

void compareMasked(Uint8List before, Uint8List after, Uint8List mask) {
  var changed = 0, outside = 0;
  for (var i = 0; i < before.length; i += 4) {
    var difference = 0;
    for (var channel = 0; channel < 3; channel++) {
      difference += (before[i + channel] - after[i + channel]).abs();
    }
    if (mask[i] == 0) {
      outside++;
      expect(difference, lessThanOrEqualTo(3));
    } else if (difference > 6) {
      changed++;
    }
  }
  expect(outside, greaterThan(before.length ~/ 40));
  expect(changed, greaterThan(100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final name in ['anastasis']) {
    test(
      '$name reconstruction changes only damaged zones and long-press returns exact original',
      () async {
        final p = PlateManifest.fromJson(
          jsonDecode(
            File('assets/plates/$name/manifest.json').readAsStringSync(),
          ) as Map<String, dynamic>,
        );
        final assets = PlateAssets();
        await assets.load(p);
        final c = PlateController(p)..setReduced(true);
        final original = await pixels(p, assets, c);
        c.setLayer(PlateLayerId.reconstruction);
        c.setWipe(1);
        final restored = await pixels(p, assets, c);
        final mask =
            (await assets.images[p.layer(PlateLayerId.reconstruction)!.mask!]!
                    .toByteData())!
                .buffer
                .asUint8List();
        compareMasked(original, restored, mask);
        c.peek(true);
        expect(await pixels(p, assets, c), orderedEquals(original));
        c.dispose();
        assets.dispose();
      },
    );
  }
  test(
    'river and scroll shader passes leave every unmasked pixel unchanged',
    () async {
      final p = PlateManifest.fromJson(
        jsonDecode(
          File('assets/plates/judgment/manifest.json').readAsStringSync(),
        ) as Map<String, dynamic>,
      );
      final assets = PlateAssets();
      await assets.load(p);
      final c = PlateController(p)..setLayer(PlateLayerId.depth);
      final base = await pixels(p, assets, c);
      c.setPaintMotion(river: true);
      c.advance(3);
      compareMasked(
        base,
        await pixels(p, assets, c),
        (await assets.images[p.flowEffect!.mask]!.toByteData())!.buffer.asUint8List(),
      );
      c.setPaintMotion(river: false, scroll: true);
      c.effectSeconds = 4;
      compareMasked(
        base,
        await pixels(p, assets, c),
        (await assets.images[p.spiralEffect!.mask]!.toByteData())!.buffer
            .asUint8List(),
      );
      c.dispose();
      assets.dispose();
    },
  );
}
