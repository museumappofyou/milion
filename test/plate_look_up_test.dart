import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/plate/player.dart';

import 'plate_player_test.dart' show loadPlate, openScene, state;

void main() {
  testWidgets(
    'the Genealogy dome starts ORIGINAL, looks up from Layers and returns in one tap',
    (tester) async {
      final p = await loadPlate('genealogy');
      await openScene(
        tester,
        PlatePlayer(manifest: p, rotationEvents: () => const Stream.empty()),
      );
      final player = state(tester), c = player.controller;
      expect(c.layer, PlateLayerId.original);
      expect(find.byKey(const ValueKey('plate-look-up')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('plate-layers')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('plate-look-up-chip')),
      );
      await tester.tap(find.byKey(const ValueKey('plate-look-up-chip')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
      await tester.pumpAndSettle();
      expect(c.lookUp, isTrue);
      expect(find.byKey(const ValueKey('plate-look-up')), findsOneWidget);
      expect(find.text('DEPTH'), findsOneWidget);
      expect(player.orientation.subscribed, isFalse); // the sensor stays opt-in
      // A finger drag pans the dome; the camera leaves the crown.
      final before = player.orientation.basis.angles.elevation;
      await tester.drag(
        find.byKey(const ValueKey('plate-look-up')),
        const Offset(0, -200),
      );
      await tester.pump();
      expect(player.orientation.basis.angles.elevation, lessThan(before));
      await tester.tap(find.byKey(const ValueKey('plate-original')));
      await tester.pump();
      expect(c.lookUp, isFalse);
      expect(find.text('ORIGINAL'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2)); // let gesture timers expire
      await tester.pumpWidget(const SizedBox.shrink());
      expect(player.assets.disposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
