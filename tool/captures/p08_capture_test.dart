// P08 evidence: SpacePlayer layouts, reduced-motion stills, renderer timings
// and the hook frames. Run: flutter test tool/captures/p08_capture_test.dart
// then encode the hook: ffmpeg -framerate 24 -i /tmp/milion-p08-hook/%04d.png
//   -pix_fmt yuv420p studio/captures/P08/dome-assembling-choisy-8s.mp4
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/space/camera.dart';
import 'package:milion/space/capture.dart';
import 'package:milion/space/model.dart';
import 'package:milion/space/player.dart';
import 'package:milion/space/renderer.dart';
import 'package:milion/space/style.dart';

import '../../test/helpers.dart' show loadThemeFonts;
import '../../test/space_engine_test.dart' show loadModel, loadStudy;
import '../../test/space_player_test.dart' show fileBytes, space;
import 'p06_capture_test.dart' show capture;

const out = 'studio/captures/P08';

Future<void> mount(
  WidgetTester tester,
  GlobalKey key, {
  double width = 390,
  String lang = 'en',
  double textScale = 1,
  bool reduced = false,
}) async {
  tester.view.physicalSize = Size(
    width,
    width == 360
        ? 800
        : width == 430
        ? 932
        : 844,
  );
  tester.view.devicePixelRatio = 1;
  final study = loadStudy();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: DesignTheme.marble,
        locale: Locale(lang),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduced,
          ),
          child: child!,
        ),
        home: SpacePlayer(study: study, loadBytes: fileBytes),
      ),
    ),
  );
  await tester.runAsync(() async {
    for (var i = 0; i < 100 && space(tester).controller == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump();
    }
  });
  await tester.pump();
}

Map<String, num> summary(List<int> micros) {
  final ms = [for (final m in micros) m / 1000]..sort();
  double at(double q) => ms[((ms.length - 1) * q).round()];
  return {
    'frames': ms.length,
    'medianMs': double.parse(at(.5).toStringAsFixed(2)),
    'p90Ms': double.parse(at(.9).toStringAsFixed(2)),
    'maxMs': double.parse(ms.last.toStringAsFixed(2)),
  };
}

/// CPU time to build one frame (projection, culling, section, sort, one
/// drawVertices) while orbiting 360°, after a warm-up turn.
Map<String, Object> orbitTimings(SpaceModel model, SpaceSection? section) {
  final renderer = SpaceRenderer(model);
  final parts = [for (final _ in model.parts) const SpacePartState()];
  final micros = <int>[];
  var triangles = 0;
  for (var lap = 0; lap < 2; lap++) {
    for (var i = 0; i < 120; i++) {
      final recorder = ui.PictureRecorder();
      final view = SpaceView.choisy(model.bounds).orbit(i * math.pi / 60, 0);
      renderer.paint(
        Canvas(recorder),
        const Size(390, 680),
        SpaceScene(
          view: view,
          style: SpaceStyle.drawing,
          parts: parts,
          section: section,
        ),
      );
      recorder.endRecording().dispose();
      if (lap == 1) {
        micros.add(renderer.stats.micros);
        triangles = math.max(triangles, renderer.stats.triangles);
      }
    }
  }
  renderer.dispose();
  return {...summary(micros), 'maxTrianglesDrawn': triangles};
}

void main() {
  testWidgets(
    'P08 SpacePlayer: 360/390/430 bilingual layouts at 100/200%, panels, stills',
    (tester) async {
      Directory(out).createSync(recursive: true);
      addTearDown(tester.view.reset);
      await loadThemeFonts(tester);
      final key = GlobalKey();
      for (final w in [360.0, 390.0, 430.0]) {
        for (final lang in ['en', 'tr']) {
          for (final scale in [1.0, 2.0]) {
            await mount(tester, key, width: w, lang: lang, textScale: scale);
            final tag = 'study-$lang-${w.toInt()}-${(scale * 100).toInt()}';
            await capture(tester, key, '$out/$tag-choisy.png');
            if (w == 390) {
              for (final panel in ['assemble', 'section', 'style']) {
                await tester.tap(find.byKey(ValueKey('space-$panel')));
                await tester.pumpAndSettle();
                await capture(tester, key, '$out/$tag-$panel.png');
                await tester.tapAt(const Offset(10, 10));
                await tester.pumpAndSettle();
              }
            }
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }
      }
      // Views a reader reaches by hand.
      await mount(tester, key);
      final c = space(tester).controller!;
      c
        ..setSection(false)
        ..setView(c.view.copyWith(elevation: .55));
      await tester.pump();
      await capture(tester, key, '$out/study-above.png');
      c.setExplode(1);
      await tester.pump();
      await capture(tester, key, '$out/study-exploded.png');
      c
        ..setExplode(0)
        ..setSectionAxis(0);
      await tester.pump();
      await capture(tester, key, '$out/study-north-south-section.png');
      for (final style in SpaceStyle.values) {
        c
          ..setStyle(style)
          ..setSectionAxis(2)
          ..setView(c.choisyView)
          ..setEpoch(1);
        await tester.pumpAndSettle();
        await capture(tester, key, '$out/study-1548-${style.name}.png');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      // The reduced-motion story: one still per step.
      await mount(tester, key, reduced: true);
      final r = space(tester).controller!;
      for (final beat in r.timeline.beats) {
        r.step(1);
        await tester.pump();
        expect(space(tester).ticking, isFalse);
        await capture(
          tester,
          key,
          '$out/study-reduced-${beat.index + 1}-${beat.step.id}.png',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );

  testWidgets('P08 budgets: model, load, frame build on the host', (
    tester,
  ) async {
    final study = loadStudy();
    final file = File(study.model);
    final watch = Stopwatch()..start();
    final model = SpaceModel.fromGlb(
      ByteData.sublistView(file.readAsBytesSync()),
    );
    final loadMs = watch.elapsedMicroseconds / 1000;
    final bench = loadModel('studio/spikes/p08/bench-50k.glb');
    File('$out/budgets.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'measurement':
            'host (macOS, Flutter test, JIT) CPU frame build; not device fps',
        'study': {
          'triangles': model.triangleCount,
          'vertices': model.parts.fold(0, (n, p) => n + p.vertexCount),
          'parts': model.parts.length,
          'glbBytes': file.lengthSync(),
          'glbParseMs': double.parse(loadMs.toStringAsFixed(1)),
          'budgetTriangles': 150000,
          'orbitWithPlanCut': orbitTimings(model, const SpaceSection(2, 3)),
          'orbitWhole': orbitTimings(model, null),
        },
        'bench50k': {
          'triangles': bench.triangleCount,
          'orbitWithPlanCut': orbitTimings(bench, const SpaceSection(2, 3)),
        },
        'deviceFps': 'see device-bench.json when the A52s is connected (O01)',
      }),
    );
  });

  testWidgets('P08 hook: eight seconds of the dome assembling in Choisy view', (
    tester,
  ) async {
    final dir = Directory('/tmp/milion-p08-hook')..createSync(recursive: true);
    for (final f in dir.listSync()) {
      f.deleteSync();
    }
    await tester.runAsync(() async {
      var i = 0;
      await for (final frame in spaceFrames(
        loadStudy(),
        loadModel(),
        const Size(540, 960),
        pixelRatio: 2,
      )) {
        final png = await encodePng(frame);
        frame.dispose();
        i++;
        File('${dir.path}/${i.toString().padLeft(4, '0')}.png')
            .writeAsBytesSync(png);
        if (i == 1 || i == 96 || i == 192) {
          File('$out/hook-frame-$i.png').writeAsBytesSync(png);
        }
      }
      expect(i, 192);
    });
  }, timeout: const Timeout(Duration(minutes: 6)));
}
