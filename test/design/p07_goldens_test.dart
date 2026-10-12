import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/plate/player.dart';

import '../plate_player_test.dart' show loadPlate, openScene, state;
import 'p06_goldens_test.dart' show repaint;

void main() {
  testWidgets('P07: III gilded, IV looking up, V as a reduced-motion still', (
    tester,
  ) async {
    final boundary = GlobalKey();
    Future<void> golden(String name) async {
      await repaint(tester, boundary);
      await expectLater(
        find.byType(PlatePlayer),
        matchesGoldenFile('../goldens/P07/$name.png'),
      );
    }

    var p = await loadPlate('metochites');
    await openScene(
      tester,
      PlatePlayer(key: ValueKey(p.id), manifest: p),
      boundary: boundary,
    );
    var player = state(tester);
    player.focus('detail-metochites-hat');
    await tester.pumpAndSettle();
    player.controller.setLight(PlateLight.gilded);
    player.tilt.drag(const Offset(.6, -.3));
    await tester.pump();
    await golden('metochites-gilded');

    p = await loadPlate('genealogy');
    await openScene(
      tester,
      PlatePlayer(
        key: ValueKey(p.id),
        manifest: p,
        rotationEvents: () => const Stream.empty(),
      ),
      boundary: boundary,
    );
    player = state(tester);
    player.controller.setLookUp(true);
    await tester.pump();
    await golden('genealogy-look-up');
    player.controller.seekReveal(5);
    await tester.pump();
    await golden('genealogy-reveal-5s');

    p = await loadPlate('enrollment');
    await openScene(
      tester,
      PlatePlayer(key: ValueKey(p.id), manifest: p),
      boundary: boundary,
      reduced: true,
    );
    player = state(tester);
    player.controller.step(1);
    player.controller.step(1);
    await tester.pump();
    await golden('enrollment-still-2');
    expect(tester.takeException(), isNull);
  });
}
