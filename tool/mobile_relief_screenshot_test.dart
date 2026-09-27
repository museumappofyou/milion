// flutter test tool/mobile_relief_screenshot_test.dart
// Deterministic widget captures. No presentation motion is running.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:milion/screens/anastasis_v5_screen.dart';
import 'package:milion/services/anastasis_relief.dart';
import 'package:milion/widgets/anastasis_dome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('captures the mobile painted relief at phone sizes', (
    tester,
  ) async {
    final key = GlobalKey();
    Directory('anastasis_25d/v3').createSync(recursive: true);
    await tester.runAsync(() async {
      for (final (width, height) in [
        (360.0, 800.0),
        (390.0, 844.0),
        (430.0, 932.0),
      ]) {
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(key: key, child: const AnastasisV5Screen()),
          ),
        );
        for (var i = 0; i < 70; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
          if (find.text('Left rock').evaluate().isNotEmpty) break;
        }
        expect(find.text('Left rock'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 50));
        await _capture(
          key,
          width == 390
              ? '08_static_relief_mobile.png'
              : 'static_${width.toInt()}x${height.toInt()}.png',
        );
        if (width == 390) {
          final view = tester.state<AnastasisDomeViewState>(
            find.byType(AnastasisDomeView).first,
          );
          final watch = Stopwatch()..start();
          for (var i = 0; i < 20; i++) {
            view.setViewAnglesForDebug(i.isEven ? -3 : 3, 0);
            await tester.pump();
          }
          watch.stop();
          stdout.writeln(
            'Software build/paint: ${(watch.elapsedMicroseconds / 20000).toStringAsFixed(1)} ms per frame (20 poses at 390x844); not device GPU FPS',
          );
          for (final (name, yaw, pitch) in [
            ('left', -5.0, 0.0),
            ('right', 5.0, 0.0),
            ('up', 0.0, -3.0),
            ('down', 0.0, 3.0),
          ]) {
            view.setViewAnglesForDebug(yaw, pitch);
            await tester.pump();
            await _capture(key, '${name}_390x844.png');
          }
          view.resetView();
          await tester.tap(find.text('Original'));
          await tester.pump();
          await _capture(key, 'original_390x844.png');
          await tester.tap(find.text('Relief'));
          await tester.pump();
          await tester.ensureVisible(find.text('Left rock'));
          await tester.tap(find.text('Left rock'));
          await tester.pump();
          await _capture(key, 'left_rock_focus_390x844.png');
          await tester.ensureVisible(find.text('Right rock'));
          await tester.tap(find.text('Right rock'));
          await tester.pump();
          await _capture(key, 'right_rock_focus_390x844.png');
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
    tester.view.reset();
  });

  testWidgets('captures a true side-angle developer view', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final key = GlobalKey();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: const AnastasisV5Screen(
              initialControls: ReliefControls(mode: 'sideAngle'),
            ),
          ),
        ),
      );
      for (var i = 0; i < 70; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.text('Left rock').evaluate().isNotEmpty) break;
      }
      expect(find.text('Left rock'), findsOneWidget);
      await _capture(key, '15_side_angle_debug.png');
    });
    tester.view.reset();
  });

  for (final (name, angle) in [
    ('17_raking_light_left.png', -70.0),
    ('18_raking_light_right.png', 70.0),
  ]) {
    testWidgets('captures $name', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      final key = GlobalKey();
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(
              key: key,
              child: AnastasisV5Screen(
                initialControls: ReliefControls(lightAngle: angle),
              ),
            ),
          ),
        );
        for (var i = 0; i < 70; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
          if (find.text('Left rock').evaluate().isNotEmpty) break;
        }
        expect(find.text('Left rock'), findsOneWidget);
        await tester.ensureVisible(find.text('Left rock'));
        await tester.tap(find.text('Left rock'));
        await tester.pump();
        await _capture(key, name);
      });
      tester.view.reset();
    });
  }
}

Future<void> _capture(GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  File('anastasis_25d/v3/$name').writeAsBytesSync(data!.buffer.asUint8List());
}
