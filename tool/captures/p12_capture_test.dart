// P12 evidence: Milestone IX (the dome that fell) in each epoch, in Choisy's
// view and during the collapse; stills of plates VII, VIII and X in their
// story beats (EN and TR); and the hook, ten seconds of the Deesis gold
// swaying under gilded light ("tilt your phone"). Run:
//   flutter test tool/captures/p12_capture_test.dart
// then encode the hook (frames land in the gitignored studio/cache):
//   ffmpeg -framerate 24 -i studio/cache/p12-hook/%04d.png -pix_fmt yuv420p
//     -vf scale=-2:1920:flags=lanczos,pad=1080:1920:(ow-iw)/2:0 -c:v libx264 -crf 22
//     studio/captures/P12/tilt-your-phone-deesis-10s.mp4
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/space/capture.dart';
import 'package:milion/space/controller.dart';
import 'package:milion/space/renderer.dart';
import 'package:milion/space/style.dart';

import '../../test/helpers.dart' show loadThemeFonts;
import '../../test/plate_player_test.dart' show loadPlate, state;
import '../../test/space_kit_test.dart' show kitModel, kitStudy;
import 'p06_capture_test.dart' show capture, mount;

const out = 'studio/captures/P12';
const hookFrames = 'studio/cache/p12-hook';

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

void main() {
  setUpAll(() => Directory(out).createSync(recursive: true));

  testWidgets('Milestone IX: Hagia Sophia in each epoch and as it falls', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final study = kitStudy('ayasofya'), model = kitModel(study);
      final c = SpaceController(study, model);
      final r = SpaceRenderer(model);
      final above = c.overviewView;
      for (final e in study.epochs) {
        final shown = {for (final step in study.stepsIn(e.year)) ...step.parts};
        for (final style in [SpaceStyle.drawing, SpaceStyle.stone]) {
          await still(
            r,
            SpaceScene(
              view: above,
              style: style,
              parts: [
                for (final part in model.parts)
                  shown.contains(part.id)
                      ? const SpacePartState()
                      : SpacePartState.hidden,
              ],
            ),
            'ix-${e.year}-${style.name}',
          );
        }
      }
      c
        ..choisy()
        ..setView(c.choisyView);
      await still(r, c.scene(), 'ix-choisy-537');
      // The story through the fall and the new dome, in Choisy's view.
      final timeline = c.timeline;
      for (final b in timeline.beats) {
        if (b.step.id != 'collapse' && b.step.id != 'light') continue;
        for (final f in [.2, .45, .7, 1.0]) {
          final s = timeline.at(b.start + b.duration * f);
          final m = s.moment;
          for (final choisy in [false, true]) {
            final story = SpaceController(study, model);
            if (choisy) story.choisy();
            story
              ..setView(choisy ? story.choisyView : story.overviewView)
              ..seek(b.start + b.duration * f);
            await still(
              r,
              story.scene(),
              'ix-story-${b.step.id}-${(f * 100).round()}'
              '${choisy ? '-choisy' : ''}',
            );
            story.dispose();
          }
          expect(m.epoch, greaterThan(0));
        }
      }
      r.dispose();
      c.dispose();
    });
  });

  // Each Milestone plate at the moment of its own technique: VII's wipe of
  // the RECONSTRUCTION, VIII's IMAGINED slot, X under raking and candle light.
  for (final lang in ['en', 'tr']) {
    testWidgets('plates VII, VIII and X in their story beats ($lang)', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      await loadThemeFonts(tester);
      for (final id in ['deesis', 'zoe', 'halvdan']) {
        final key = GlobalKey(), p = await loadPlate(id);
        await mount(tester, key, p, lang: lang);
        final c = state(tester).controller;
        for (final b in p.beats) {
          if (lang == 'tr' && b.layer == null) continue;
          c.seek(b.start + b.duration * .8);
          await tester.pump();
          await capture(tester, key, '$out/plate-$id-${b.detailId}-$lang.png');
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
      expect(tester.takeException(), isNull);
    }, timeout: const Timeout(Duration(minutes: 6)));
  }

  // The hook: ten seconds at 24 fps of the Deesis reveal under gilded light;
  // while it plays the light sways as a tilting phone would move it.
  testWidgets('hook: tilt your phone, the Deesis gold', (tester) async {
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    final dir = Directory(hookFrames);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final key = GlobalKey(), p = await loadPlate('deesis');
    expect(p.reveal.light, PlateLight.gilded);
    await mount(tester, key, p);
    final c = state(tester).controller..playReveal();
    await tester.pump();
    for (var n = 1; n <= 240; n++) {
      await tester.pump(const Duration(microseconds: 41667));
      await capture(
        tester,
        key,
        '$hookFrames/${n.toString().padLeft(4, '0')}.png',
      );
      if (n == 1 || n == 120 || n == 240) {
        await capture(tester, key, '$out/hook-deesis-$n.png');
      }
    }
    expect(c.honesty.name, isNot('IMAGINED'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 8)));
}
