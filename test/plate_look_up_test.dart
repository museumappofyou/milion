import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/plate/look_up.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/plate/painter.dart';
import 'package:milion/plate/player.dart';
import 'package:milion/plate/tilt.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'plate_player_test.dart' show loadPlate, openScene, state;

void main() {
  // A sensor-steered view repaints only when a reading arrives. At the 20 ms
  // game rate the A52s presented 49 fps, a 33 ms gap ten times a second
  // (2026-11-09), so both sensors must report faster than a 60 Hz frame.
  test('tilt and look-up sensors report faster than one 60 Hz frame', () {
    const frameUs = 1000000 ~/ 60;
    expect(PlateTilt.samplingPeriod.inMicroseconds, lessThan(frameUs));
    final kotlin = File(
      'android/app/src/main/kotlin/app/milion/MainActivity.kt',
    ).readAsStringSync();
    final period = RegExp(r'SAMPLING_PERIOD_US = ([\d_]+)')
        .firstMatch(kotlin)!
        .group(1)!
        .replaceAll('_', '');
    expect(int.parse(period), lessThan(frameUs));
    expect(int.parse(period), greaterThanOrEqualTo(5000)); // ≤ 200 Hz
    expect(
      kotlin,
      contains('registerListener(this, sensor, SAMPLING_PERIOD_US)'),
    );
  });

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
      await tester.pump(
        const Duration(seconds: 2),
      ); // let gesture timers expire
      await tester.pumpWidget(const SizedBox.shrink());
      expect(player.assets.disposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  // Each sensor reading used to rebuild the plate's Semantics (and an open
  // sheet), so TalkBack received an update every frame while the phone
  // steered: on the A52s uiautomator could never find the window idle
  // (2026-11-09). Readings must repaint the picture and leave semantics be.
  testWidgets('gyro readings repaint the plate without a semantics update', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final events = StreamController<GyroscopeEvent>.broadcast(sync: true);
    addTearDown(events.close);
    await openScene(
      tester,
      PlatePlayer(
        manifest: await loadPlate('anastasis'),
        gyroEvents: () => events.stream,
      ),
    );
    final player = state(tester);
    player.setGyro(true);
    await tester.pump(const Duration(seconds: 1));
    PlatePainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byKey(const ValueKey('plate-paint')),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as PlatePainter;
    final before = painter().tilt;
    final updates = _countSemanticsUpdates(tester);
    final t = DateTime(2026);
    for (var i = 0; i < 30; i++) {
      events.add(
        GyroscopeEvent(2, 2, 0, t.add(Duration(milliseconds: i * 10))),
      );
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(painter().tilt, isNot(before));
    expect(updates(), 0);
    player.setGyro(false);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });

  testWidgets(
    'rotation readings move the look-up, not the open sheet or semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final events = StreamController<List<double>>.broadcast(sync: true);
      addTearDown(events.close);
      await openScene(
        tester,
        PlatePlayer(
          manifest: await loadPlate('genealogy'),
          rotationEvents: () => events.stream,
        ),
      );
      final player = state(tester);
      await tester.tap(find.byKey(const ValueKey('plate-layers')));
      await tester.pumpAndSettle();
      player.setLookUpSensor(true);
      await tester.pumpAndSettle(); // the chips' checkmarks finish moving
      expect(player.orientation.subscribed, isTrue);
      LookUpPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byKey(const ValueKey('plate-look-up')),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as LookUpPainter;
      List<double> turn(double a) => [
        1, 0, 0, //
        0, math.cos(a), -math.sin(a), //
        0, math.sin(a), math.cos(a),
      ];
      events.add(turn(0));
      await tester.pump(const Duration(milliseconds: 10));
      final before = painter().basis.forward;
      final updates = _countSemanticsUpdates(tester);
      for (var i = 1; i <= 30; i++) {
        events.add(turn(i * .02));
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(painter().basis.forward, isNot(before));
      expect(updates(), 0);
      player.setLookUpSensor(false);
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    },
  );
}

/// Counts the semantics updates the framework sends from now on.
int Function() _countSemanticsUpdates(WidgetTester tester) {
  final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
  var count = 0;
  void listener() => count++;
  owner.addListener(listener);
  addTearDown(() => owner.removeListener(listener));
  return () => count;
}
