import 'dart:convert';
import 'dart:ui' as ui;

import 'package:milion/models/explorable_scene.dart';
import 'package:milion/services/explorer_assets.dart';
import 'package:milion/widgets/interactive_relief_surface.dart';
import 'package:milion/screens/anastasis_relief_screen.dart';
import 'package:milion/screens/last_judgment_relief_screen.dart';
import 'package:milion/screens/restoration_studies_screen.dart';
import 'package:milion/screens/scene_explorer_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> assetsReady(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 200; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
      if (i >= 20 &&
          find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
  });
  await tester.pumpAndSettle();
}

Future<void> openScene(
  WidgetTester tester,
  Widget home, {
  bool reduced = false,
  GlobalKey? boundary,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          disableAnimations: reduced,
        ),
        child: RepaintBoundary(key: boundary, child: home),
      ),
    ),
  );
  await assetsReady(tester);
}

SceneExplorerScreenState state(WidgetTester tester) =>
    tester.state<SceneExplorerScreenState>(find.byType(SceneExplorerScreen));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'both scenes retain all source images and valid sampled v5 geometry',
    () async {
      for (final scene in [
        ExplorableScene.anastasis,
        ExplorableScene.judgment,
      ]) {
        final geometry = jsonDecode(
          await rootBundle.loadString(scene.geometry),
        ) as Map<String, dynamic>;
        final heights = (geometry['height'] as List).cast<num>();
        expect(
          heights.length,
          (geometry['cols'] as int) * (geometry['rows'] as int),
        );
        expect(heights.every((v) => v.isFinite && v >= 0 && v < .1), isTrue);
        expect(heights.any((v) => v > .02), isTrue);
        for (final file in {
          scene.original,
          scene.relief,
          scene.restored,
          ...scene.studies.expand((study) => [study.original, study.study]),
        }) {
          final bytes = await rootBundle.load(file);
          expect(bytes.lengthInBytes, greaterThan(10000), reason: file);
        }
        for (final d in scene.details) {
          expect(const Rect.fromLTWH(0, 0, 1, 1).contains(d.point), isTrue);
          expect(d.window.width, greaterThan(0));
          expect(d.window.height, greaterThan(0));
          expect(d.window.right, lessThanOrEqualTo(1));
          expect(d.window.bottom, lessThanOrEqualTo(1));
        }
      }
    },
  );

  test('restored scenes are single 4K exports with the source aspect', () async {
    for (final scene in [ExplorableScene.anastasis, ExplorableScene.judgment]) {
      final bytes = await rootBundle.load(scene.restored);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 3840);
      expect(image.width / image.height, closeTo(scene.size.aspectRatio, .001));
      expect(scene.studies, hasLength(1));
      expect(scene.studies.first.study, scene.restored);
      expect(scene.studies.first.initialBlend, 1);
      image.dispose();
      codec.dispose();
    }
  });

  for (final (name, home) in [
    ('Anastasis', const AnastasisReliefScreen()),
    ('Last Judgment', const LastJudgmentReliefScreen()),
  ]) {
    testWidgets('$name zooms, pans and compares original, relief, restored', (
      tester,
    ) async {
      await openScene(tester, home);
      final explorer = state(tester);
      expect(explorer.zoom, 1);
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(explorer.zoom, closeTo(1.5, .01));
      await tester.drag(
        find.byKey(const ValueKey('scene-interactive-viewer')),
        const Offset(40, 0),
      );
      await tester.pumpAndSettle();
      expect(explorer.transformation.value.getTranslation().x, isNot(0));
      final current = explorer.transformation.value.clone();
      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();
      expect(explorer.variant, 'Original');
      expect(explorer.transformation.value, current);
      await tester.tap(find.text('Restored'));
      await assetsReady(tester);
      expect(explorer.variant, 'Restored');
      expect(explorer.restorationAmount, 1);
      expect(
        find.text('4K restoration · interpretive · original preserved'),
        findsOneWidget,
      );
      expect(explorer.zoom, closeTo(1.5, .01));
      await tester.tap(find.byTooltip('Reset view'));
      await tester.pumpAndSettle();
      expect(explorer.zoom, closeTo(1, .001));
      await tester.tap(find.byTooltip('Scene options'));
      await tester.pumpAndSettle();
      expect(find.text('Classic v5 viewer'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '$name animates figures in place, freezes on pause and supports every texture',
      (tester) async {
        await openScene(tester, home);
        final explorer = state(tester);
        expect(find.text('Play tour'), findsNothing);
        final camera = explorer.transformation.value.clone();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('figure-canvas')),
        );
        Future<List<int>> pixels() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          image.dispose();
          return data.buffer.asUint8List().toList();
        }

        final still = await tester.runAsync(pixels);
        await tester.tap(find.text('Animate figures'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(explorer.isMotionPlaying, isTrue);
        expect(explorer.figurePose, closeTo(1 / 3, .01));
        expect(explorer.transformation.value, camera);
        expect(explorer.selectedDetail, isNull);
        final surface =
            tester
                    .widget<CustomPaint>(
                      find.descendant(
                        of: find.byKey(const ValueKey('figure-canvas')),
                        matching: find.byType(CustomPaint),
                      ),
                    )
                    .painter!
                as InteractiveReliefSurface;
        expect(surface.showDetails, isFalse);
        final animated = await tester.runAsync(pixels);
        expect(animated, isNot(equals(still)));
        await tester.tap(find.text('Pause figures'));
        await tester.pumpAndSettle();
        final paused = await tester.runAsync(pixels);
        final pose = explorer.figurePose;
        await tester.pump(const Duration(seconds: 5));
        expect(explorer.isMotionPlaying, isFalse);
        expect(explorer.figurePose, pose);
        expect(await tester.runAsync(pixels), equals(paused));
        expect(explorer.transformation.value, camera);
        expect(explorer.motionAmount, 1);
        await tester.drag(
          find.byKey(const ValueKey('figure-intensity')),
          const Offset(-220, 0),
        );
        await tester.pumpAndSettle();
        expect(explorer.motionAmount, lessThan(.5));
        expect(explorer.figurePose, pose);
        expect(await tester.runAsync(pixels), isNot(equals(paused)));
        await tester.drag(
          find.byKey(const ValueKey('figure-intensity')),
          const Offset(220, 0),
        );
        await tester.pumpAndSettle();
        expect(explorer.motionAmount, 1);
        await tester.tap(find.text('Still'));
        await tester.pumpAndSettle();
        expect(explorer.figurePose, 0);
        expect(await tester.runAsync(pixels), equals(still));
        // Manual pose scrubbing pauses the clock and keeps its selected pose.
        await tester.drag(
          find.byKey(const ValueKey('figure-pose')),
          const Offset(60, 0),
        );
        await tester.pumpAndSettle();
        expect(explorer.figurePose, greaterThan(0));
        expect(explorer.isMotionPlaying, isFalse);
        for (final texture in ['Original', 'Restored']) {
          await tester.tap(find.text(texture));
          await assetsReady(tester);
          await tester.tap(find.text('Animate figures'));
          await tester.pump();
          final before = explorer.figurePose;
          await tester.pump(const Duration(milliseconds: 500));
          expect(explorer.isMotionPlaying, isTrue);
          expect(explorer.figurePose, isNot(before));
          // User can zoom and select a figure while the gesture continues.
          await tester.tap(find.byTooltip('Zoom in'));
          await tester.pump(const Duration(milliseconds: 800));
          expect(explorer.isMotionPlaying, isTrue);
          await tester.tap(find.text('Pause figures'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('pinch, double tap and mouse wheel change zoom within bounds', (
    tester,
  ) async {
    await openScene(tester, const AnastasisReliefScreen());
    final viewer = find.byKey(const ValueKey('scene-interactive-viewer'));
    final center = tester.getCenter(viewer);
    final first = await tester.startGesture(
      center - const Offset(35, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(35, 0),
      pointer: 2,
    );
    await tester.pump();
    await first.moveTo(center - const Offset(85, 0));
    await second.moveTo(center + const Offset(85, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(state(tester).zoom, greaterThan(1));
    await tester.tap(find.byTooltip('Reset view'));
    await tester.pumpAndSettle();
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(state(tester).zoom, closeTo(2, .01));
    await tester.sendEventToBinding(
      PointerScrollEvent(position: center, scrollDelta: const Offset(0, -100)),
    );
    await tester.pumpAndSettle();
    expect(state(tester).zoom, greaterThan(2));
    state(tester).zoomBy(100);
    await tester.pumpAndSettle();
    expect(state(tester).zoom, closeTo(8, .01));
    state(tester).zoomBy(.0001);
    await tester.pumpAndSettle();
    expect(state(tester).zoom, closeTo(1, .01));
  });

  testWidgets(
    'reduced motion allows manual poses and lifecycle pauses figures',
    (tester) async {
      await openScene(tester, const LastJudgmentReliefScreen(), reduced: true);
      await tester.tap(find.text('Animate figures'));
      await tester.pump();
      expect(state(tester).isMotionPlaying, isFalse);
      await tester.drag(
        find.byKey(const ValueKey('figure-pose')),
        const Offset(40, 0),
      );
      await tester.pumpAndSettle();
      expect(state(tester).figurePose, greaterThan(0));
      await tester.pumpWidget(const SizedBox.shrink());
      await openScene(tester, const LastJudgmentReliefScreen());
      await tester.tap(find.text('Animate figures'));
      await tester.pump(const Duration(seconds: 1));
      state(tester).didChangeAppLifecycleState(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      final pose = state(tester).figurePose;
      await tester.pump(const Duration(seconds: 2));
      expect(state(tester).isMotionPlaying, isFalse);
      expect(state(tester).figurePose, pose);
      state(tester).didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.tap(find.text('Animate figures'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'figure rigs keep scenery fixed and never fold during a complete gesture',
    () async {
      for (final scene in [
        ExplorableScene.anastasis,
        ExplorableScene.judgment,
      ]) {
        final owner = ExplorerAssets();
        final rig = await owner.figures(scene.figures);
        expect(rig.frameCount, 48);
        final frame = Offset.zero & scene.size;
        final initial = rig.positions(0, frame);
        final moving = rig.vertices.toSet();
        expect(moving.length, greaterThan(1000));
        expect(moving.length, lessThan(rig.cols * rig.rows * .65));
        double maxTravel = 0;
        double minimumArea = double.infinity;
        var fixedScenery = true;
        for (var sample = 0; sample <= 32; sample++) {
          final points = rig.positions(sample / 32, frame);
          for (var i = 0; i < rig.cols * rig.rows; i++) {
            if (!moving.contains(i)) {
              fixedScenery &=
                  points[i * 2] == initial[i * 2] &&
                  points[i * 2 + 1] == initial[i * 2 + 1];
            } else {
              final distance = Offset(
                points[i * 2] - initial[i * 2],
                points[i * 2 + 1] - initial[i * 2 + 1],
              ).distance;
              if (distance > maxTravel) maxTravel = distance;
            }
          }
          for (var j = 0; j < rig.indices.length; j += 3) {
            final a = rig.indices[j] * 2,
                b = rig.indices[j + 1] * 2,
                c = rig.indices[j + 2] * 2;
            final cross =
                (points[b] - points[a]) * (points[c + 1] - points[a + 1]) -
                (points[b + 1] - points[a + 1]) * (points[c] - points[a]);
            if (cross < minimumArea) minimumArea = cross;
          }
        }
        expect(fixedScenery, isTrue);
        expect(minimumArea, greaterThan(0));
        expect(
          maxTravel,
          greaterThan(scene == ExplorableScene.anastasis ? 45 : 28),
        );
        expect(rig.positions(1, frame), orderedEquals(initial));
        expect(rig.positions(.25, frame, intensity: 0), orderedEquals(initial));
        owner.dispose();
      }
    },
  );

  testWidgets('the 4K restoration study retains the original comparison', (
    tester,
  ) async {
    await openScene(tester, const LastJudgmentReliefScreen());
    await tester.tap(find.byTooltip('Scene options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restoration studies'));
    await assetsReady(tester);
    expect(find.byType(RestorationStudiesScreen), findsOneWidget);
    await tester.tap(find.text('4K restored vault'));
    await assetsReady(tester);
    expect(
      find.byKey(const ValueKey('study-interactive-viewer')),
      findsOneWidget,
    );
    await tester.tap(find.text('Original'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('source photograph is unchanged'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
