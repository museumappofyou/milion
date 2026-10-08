import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/plate/player.dart';

import '../scene_explorer_test.dart' show loadPlate, openScene, state;

Future<void> repaint(WidgetTester tester, GlobalKey key) async {
  void visit(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(visit);
  }

  visit(key.currentContext!.findRenderObject()!);
  await tester.pump();
}

void main() {
  for (final name in ['anastasis', 'judgment']) {
    testWidgets('$name all light modes, reconstruction and still goldens', (
      tester,
    ) async {
      final p = await loadPlate(name);
      final boundary = GlobalKey();
      await openScene(tester, PlatePlayer(manifest: p), boundary: boundary);
      final player = state(tester), c = player.controller;
      player.focus(p.beats.first.detailId);
      await tester.pumpAndSettle();
      for (final light in PlateLight.values) {
        c.setLight(light);
        c.setLayer(PlateLayerId.depth);
        c.effectSeconds = 1.25;
        player.tilt.drag(const Offset(.75, -.25));
        await tester.pump();
        await repaint(tester, boundary);
        await expectLater(
          find.byKey(const ValueKey('plate-paint')),
          matchesGoldenFile('../goldens/P06/$name-${light.name}.png'),
        );
      }
      c.original();
      c.setLayer(PlateLayerId.reconstruction);
      c.setWipe(.8);
      await tester.pump();
      await repaint(tester, boundary);
      await expectLater(
        find.byKey(const ValueKey('plate-paint')),
        matchesGoldenFile('../goldens/P06/$name-reconstruction.png'),
      );
      c.original();
      c.setReduced(true);
      c.step(1);
      await tester.pump();
      await repaint(tester, boundary);
      await expectLater(
        find.byKey(const ValueKey('plate-paint')),
        matchesGoldenFile('../goldens/P06/$name-still.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
