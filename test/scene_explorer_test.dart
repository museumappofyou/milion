import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/design/components.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/plate/assets.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/plate/player.dart';
import 'package:milion/plate/sheets.dart';
import 'package:milion/screens/anastasis_relief_screen.dart';
import 'package:milion/screens/last_judgment_relief_screen.dart';

import 'helpers.dart' show loadThemeFonts;

Future<PlateManifest> loadPlate(String name) async => PlateManifest.fromJson(
  jsonDecode(File('assets/plates/$name/manifest.json').readAsStringSync())
      as Map<String, dynamic>,
);
Future<void> assetsReady(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 200; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
      if (i >= 10 && find.byType(TesseraLoader).evaluate().isEmpty) break;
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
  await loadThemeFonts(tester);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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

PlatePlayerState state(WidgetTester tester) =>
    tester.state<PlatePlayerState>(find.byType(PlatePlayer));
Future<void> visibleTap(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final (name, home) in [
    ('Anastasis', const AnastasisReliefScreen()),
    ('Judgment', const LastJudgmentReliefScreen()),
  ]) {
    testWidgets(
      '$name original first, zoom bounds, one-tap comparison and disposal',
      (tester) async {
        await openScene(tester, home);
        final p = state(tester), c = p.controller;
        expect(c.layer, PlateLayerId.original);
        expect(c.playing, isFalse);
        expect(p.tilt.subscribed, isFalse);
        expect(p.ticking, isFalse);
        expect(p.assets.textureBytes, lessThanOrEqualTo(150000000));
        expect(
          p.assets.rig!.cols * p.assets.rig!.rows,
          lessThanOrEqualTo(60000),
        );
        p.zoomBy(2 / p.zoom);
        await tester.pumpAndSettle();
        expect(p.zoom, closeTo(2, .01));
        final camera = p.transformation.value.clone();
        c.setLayer(PlateLayerId.reconstruction);
        await tester.pump();
        expect(find.text('RECONSTRUCTION'), findsOneWidget);
        c.peek(true);
        await tester.pump();
        expect(find.text('ORIGINAL'), findsOneWidget);
        c.peek(false);
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('plate-original')));
        await tester.pump();
        expect(c.layer, PlateLayerId.original);
        expect(p.transformation.value, camera);
        p.zoomBy(100);
        await tester.pumpAndSettle();
        expect(p.zoom, closeTo(8, .01));
        p.zoomBy(.001);
        await tester.pumpAndSettle();
        expect(p.zoom, closeTo(1, .01));
        c.setLight(PlateLight.candle);
        await tester.pump();
        expect(p.ticking, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(p.assets.disposed, isTrue);
        expect(p.assets.images, isEmpty);
        expect(c.disposed, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'single-finger drag controls tilt, raking light and reconstruction wipe',
    (tester) async {
      await openScene(tester, const AnastasisReliefScreen());
      final p = state(tester), c = p.controller;
      final view = find.byKey(const ValueKey('plate-interactive-viewer'));
      c.setLight(PlateLight.gilded);
      await tester.pump();
      await tester.drag(view, const Offset(80, 30));
      await tester.pump();
      expect(p.tilt.normalized.distance, greaterThan(.01));
      c.setLight(PlateLight.raking);
      await tester.pump();
      await tester.drag(view, const Offset(-70, 20));
      await tester.pump();
      expect(p.lightPosition, isNot(const Offset(.5, .5)));
      c.setLayer(PlateLayerId.reconstruction);
      await tester.pump();
      await tester.drag(view, const Offset(70, 0));
      await tester.pump();
      expect(c.wipe, isNot(.5));
      c.original();
      await tester.pump();
      p.controls(PlatePanel.light);
      await tester.pumpAndSettle();
      expect(find.text('Tilt with the phone'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'pinch, pan and double-tap preserve the original camera controls',
    (tester) async {
      await openScene(tester, const AnastasisReliefScreen());
      final p = state(tester),
          view = find.byKey(const ValueKey('plate-interactive-viewer'));
      final center = tester.getCenter(view), initial = p.zoom;
      final a = await tester.startGesture(
        center - const Offset(35, 0),
        pointer: 1,
      );
      final b = await tester.startGesture(
        center + const Offset(35, 0),
        pointer: 2,
      );
      await tester.pump();
      await a.moveTo(center - const Offset(60, 0));
      await b.moveTo(center + const Offset(60, 0));
      await tester.pump();
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      expect(p.zoom, greaterThan(initial));
      final before = p.transformation.value.getTranslation().x;
      await tester.drag(view, const Offset(35, 0));
      await tester.pumpAndSettle();
      expect(p.transformation.value.getTranslation().x, isNot(before));
      p.focus(null);
      await tester.pumpAndSettle();
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tapAt(center);
      await tester.pumpAndSettle();
      expect(p.zoom, closeTo(2, .01));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('story pauses, scrubs and performs one bounded wrist gesture', (
    tester,
  ) async {
    await openScene(tester, const AnastasisReliefScreen());
    final p = state(tester), c = p.controller;
    c.seek(10.6);
    await tester.pump();
    expect(c.visibleGesture, closeTo(.5, .001));
    expect(find.text('IMAGINED'), findsOneWidget);
    c.play();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(c.visibleGesture, 0);
    expect(c.seconds, greaterThan(11.5));
    c.pause();
    await tester.pump();
    final t = c.seconds;
    await tester.pump(const Duration(seconds: 8));
    expect(c.seconds, t);
    c.seek(31);
    c.play();
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(c.seconds, 32);
    expect(c.playing, isFalse);
    await tester.pump(const Duration(seconds: 8));
    expect(c.seconds, 32);
    c.original();
    await tester.pump();
    expect(p.ticking, isFalse);
  });
  testWidgets(
    'reduced motion has the whole story as manual stills and stops lifecycle motion',
    (tester) async {
      await openScene(tester, const LastJudgmentReliefScreen(), reduced: true);
      final p = state(tester), c = p.controller;
      await tester.tap(find.byKey(const ValueKey('plate-story')));
      await tester.pumpAndSettle();
      expect(find.text('Play story'), findsNothing);
      for (final beat in c.manifest.beats) {
        await visibleTap(tester, 'Next still');
        await tester.pump();
        expect(c.sample!.beat.id, beat.id);
        expect(c.seconds, beat.start);
        expect(c.visibleGesture, 0);
        expect(p.ticking, isFalse);
      }
      c.scrubGesture(.3);
      await tester.pump();
      expect(c.visibleGesture, .3);
      expect(c.gesturePlaying, isFalse);
      await tester.tap(find.byTooltip('Close controls'));
      await tester.pumpAndSettle();
      c.setReduced(false);
      c.play();
      await tester.pump();
      p.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await tester.pump();
      expect(c.playing, isFalse);
      expect(p.ticking, isFalse);
      p.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(c.playing, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'exiting during asynchronous loading safely releases late resources',
    (tester) async {
      final manifest = await loadPlate('anastasis');
      await tester.pumpWidget(
        MaterialApp(home: PlatePlayer(manifest: manifest)),
      );
      final p = state(tester);
      var completed = false;
      p.loading.then(
        (_) => completed = true,
        onError: (Object _) => completed = true,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        for (var i = 0; i < 200 && !completed; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
          await tester.pump();
        }
      });
      expect(completed, isTrue);
      expect(p.assets.images, isEmpty);
      expect(p.assets.disposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  test('both rigs keep scenery fixed, return to the source, and never fold at the allowed intensity', () async {
    for (final name in ['anastasis', 'judgment']) {
      final manifest = await loadPlate(name), owner = PlateAssets();
      final rig = await owner.readRig(manifest.mesh.figures);
      final frame = Rect.fromLTWH(
        0,
        0,
        manifest.width.toDouble(),
        manifest.height.toDouble(),
      );
      final initial = rig.positions(0, frame), moving = rig.vertices.toSet();
      var minArea = double.infinity, maxTravel = 0.0;
      for (var sample = 0; sample <= 32; sample++) {
        final points = rig.positions(sample / 32, frame, intensity: .35);
        for (var i = 0; i < rig.cols * rig.rows; i++) {
          if (!moving.contains(i)) {
            expect(points[i * 2], initial[i * 2]);
            expect(points[i * 2 + 1], initial[i * 2 + 1]);
          } else {
            final travel = Offset(
              points[i * 2] - initial[i * 2],
              points[i * 2 + 1] - initial[i * 2 + 1],
            ).distance;
            if (travel > maxTravel) maxTravel = travel;
          }
        }
        for (var j = 0; j < rig.indices.length; j += 3) {
          final a = rig.indices[j] * 2,
              b = rig.indices[j + 1] * 2,
              c = rig.indices[j + 2] * 2;
          final cross =
              (points[b] - points[a]) * (points[c + 1] - points[a + 1]) -
              (points[b + 1] - points[a + 1]) * (points[c] - points[a]);
          if (cross < minArea) minArea = cross;
        }
      }
      expect(minArea, greaterThan(0));
      expect(maxTravel, greaterThan(5));
      expect(rig.positions(1, frame), orderedEquals(initial));
      if (name == 'anastasis') {
        final gesture = manifest.beats
            .where((b) => b.gesture != null)
            .single
            .gesture!;
        final windows = [
          for (final w in gesture.windows)
            Rect.fromLTRB(w.left, w.top, w.right, w.bottom),
        ];
        final points = rig.positions(
          .25,
          frame,
          intensity: gesture.strength,
          windows: windows,
        );
        var changed = 0;
        for (var i = 0; i < rig.cols * rig.rows; i++) {
          final uv = Offset(rig.coordinates[i * 2], rig.coordinates[i * 2 + 1]);
          final differs =
              points[i * 2] != initial[i * 2] ||
              points[i * 2 + 1] != initial[i * 2 + 1];
          if (differs) {
            changed++;
            expect(windows.any((w) => w.contains(uv)), isTrue);
          }
        }
        expect(changed, greaterThan(100));
      }
      owner.dispose();
    }
  });
  test('reconstruction exports preserve source aspect and are 4K', () async {
    for (final name in ['anastasis', 'judgment']) {
      final p = await loadPlate(name),
          bytes = await rootBundle.load(
            p.layer(PlateLayerId.reconstruction).asset,
          );
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 3840);
      expect(image.width / image.height, closeTo(p.width / p.height, .001));
      image.dispose();
      codec.dispose();
    }
  });
}
