// P13 evidence: the kit studies of Milestones 0 (the Milion), XII (the
// Hippodrome through time) and XIV (the Serpent Column) in each epoch, from
// above and in Choisy's view, and the reveal's turntable. Run:
//   flutter test tool/captures/p13_capture_test.dart
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/geography.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/first_run/first_run_painter.dart';
import 'package:milion/first_run/first_run_screen.dart';
import 'package:milion/first_run/milion_intro.dart';
import 'package:milion/space/capture.dart';
import 'package:milion/space/controller.dart';
import 'package:milion/space/renderer.dart';
import 'package:milion/space/style.dart';

import '../../test/helpers.dart' show loadThemeFonts;
import '../../test/space_kit_test.dart' show kitModel, kitStudy;

const out = 'studio/captures/P13';
final only = Platform.environment['P13_ONLY'];

Future<void> still(SpaceRenderer r, SpaceScene scene, String name) async {
  final image = await renderSpaceStill(
    r,
    scene,
    const Size(540, 960),
    pixelRatio: 2,
  );
  File('$out/$name.png').writeAsBytesSync(await encodePng(image));
  image.dispose();
}

Future<void> epochs(String id, String prefix) async {
  final study = kitStudy(id), model = kitModel(study);
  final c = SpaceController(study, model);
  final r = SpaceRenderer(model);
  for (final e in study.epochs) {
    final shown = {for (final step in study.stepsIn(e.year)) ...step.parts};
    for (final style in [SpaceStyle.drawing, SpaceStyle.stone]) {
      await still(
        r,
        SpaceScene(
          view: c.overviewView,
          style: style,
          parts: [
            for (final part in model.parts)
              shown.contains(part.id)
                  ? const SpacePartState()
                  : SpacePartState.hidden,
          ],
        ),
        '$prefix-${e.year < 0 ? '${-e.year}bc' : e.year}-${style.name}',
      );
    }
  }
  c
    ..choisy()
    ..setView(c.choisyView);
  await still(r, c.scene(), '$prefix-choisy');
  r.dispose();
  c.dispose();
}

Future<ByteData> fileBytes(String path) async =>
    ByteData.sublistView(File(path).readAsBytesSync());

/// Milestone 0 frames at [times] (seconds), 390 × 844 at 2×, EN.
Future<void> firstRun(WidgetTester tester, List<double> times, String dir,
    {String Function(double t, int i)? name}) async {
  await loadThemeFonts(tester);
  final registry = (await tester.runAsync(
    () => ContentRepository((p) => File(p).readAsString()).load(),
  ))!;
  final intro = (await tester.runAsync(() => MilionIntro.load(fileBytes)))!;
  final places = [
    for (final (id, left, below) in firstRunPlaces)
      LitPlace(
        registry.place(id)!.names.en,
        formatMilDistance(fromMilion(registry.place(id)!).km),
        metresFromMilion(registry.place(id)!.coordinates),
        left: left,
        below: below,
      ),
  ];
  Directory(dir).createSync(recursive: true);
  for (final (i, t) in times.indexed) {
    await tester.runAsync(() async {
      const size = Size(390, 844);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder)..scale(2);
      FirstRunPainter(
        t: t,
        line: 'Every road started here.',
        stone: 'MILION',
        street: 'Divanyolu, beside the Basilica Cistern',
        coordinates: '41.008043° N · 28.978066° E',
        places: places,
        scaler: TextScaler.noScaling,
        intro: intro,
        honesty: 'RECONSTRUCTION',
        roads: firstRunRays('en'),
      ).paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(780, 1688);
      File('$dir/${name?.call(t, i) ?? 'first-run-${t.toStringAsFixed(1)}'}.png')
          .writeAsBytesSync(await encodePng(image));
      image.dispose();
      picture.dispose();
    });
  }
  intro.dispose();
}

void main() {
  setUpAll(() => Directory(out).createSync(recursive: true));

  testWidgets('Milestone 0: the first run at key moments', (tester) async {
    if (only != null && only != 'first-run') return;
    await firstRun(tester, [
      1.5, 2.4, 3.0, 3.6, 4.2, 4.6, 5.0, 5.3, 5.6, 6.4, 7.4, 8.4, 10.1, 11.6,
    ], '$out/first-run');
  });

  // The hook, "Every road started here.": the whole 12 s first run at 24 fps
  // into studio/cache/p13/hook-frames, for ffmpeg (P13_ONLY=hook only).
  testWidgets('Milestone 0: the hook clip frames', (tester) async {
    if (only != 'hook') return;
    final times = [for (var i = 0; i < 12 * 24; i++) i / 24];
    await firstRun(
      tester,
      times,
      'studio/cache/p13/hook-frames',
      name: (t, i) => i.toString().padLeft(4, '0'),
    );
  });

  for (final (id, prefix) in [
    ('milion', '0-milion'),
    ('hippodrome', 'xii-hippodrome'),
    ('serpent-column', 'xiv-serpent'),
  ]) {
    testWidgets('$id in each epoch', (tester) async {
      if (only != null && only != id) return;
      if (!File('assets/space/$id/study.json').existsSync()) return;
      await tester.runAsync(() => epochs(id, prefix));
    });
  }
}
