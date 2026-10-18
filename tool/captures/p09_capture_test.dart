// P09 evidence: the kit's three buildings as stills and player layouts, host
// frame-build budgets beside P08's study, and the hook. Run:
//   flutter test tool/captures/p09_capture_test.dart
// then encode the hook (frames land in the gitignored studio/cache):
//   ffmpeg -framerate 24 -i studio/cache/p09-hook/%04d.png -pix_fmt yuv420p
//     studio/captures/P09/three-buildings-assembling-10s.mp4
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/design/tokens.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/space/camera.dart';
import 'package:milion/space/capture.dart';
import 'package:milion/space/controller.dart';
import 'package:milion/space/model.dart';
import 'package:milion/space/player.dart';
import 'package:milion/space/renderer.dart';
import 'package:milion/space/study.dart';
import 'package:milion/space/style.dart';

import '../../test/helpers.dart' show loadThemeFonts;
import '../../test/space_engine_test.dart' show loadModel, loadStudy;
import '../../test/space_kit_test.dart' show kit, kitModel, kitStudy;
import '../../test/space_player_test.dart' show fileBytes, space;
import 'p06_capture_test.dart' show capture;
import 'p08_capture_test.dart' show summary;

const out = 'studio/captures/P09';
const _degree = math.pi / 180;

/// Each building's name and first date for the hook's panels.
const names = {
  'bodrum-camii': 'Bodrum Camii · c. 920',
  'kucuk-ayasofya': 'Küçük Ayasofya · 536',
  'sehzade-camii': 'Şehzade Camii · 1548',
};

Future<void> still(
  SpaceRenderer renderer,
  SpaceScene scene,
  String name,
) async {
  final image = await renderSpaceStill(
    renderer,
    scene,
    const Size(540, 960),
    pixelRatio: 2,
  );
  File('$out/$name.png').writeAsBytesSync(await encodePng(image));
  image.dispose();
}

/// Frame build while orbiting 360° from the study's own Choisy view.
Map<String, Object> orbit(SpaceStudy study, SpaceModel model, bool cut) {
  final c = SpaceController(study, model);
  final renderer = SpaceRenderer(model);
  final parts = [for (final _ in model.parts) const SpacePartState()];
  final micros = <int>[];
  var drawn = 0;
  for (var lap = 0; lap < 2; lap++) {
    for (var i = 0; i < 120; i++) {
      final recorder = ui.PictureRecorder();
      renderer.paint(
        Canvas(recorder),
        const Size(390, 680),
        SpaceScene(
          view: c.choisyView.orbit(i * math.pi / 60, 0),
          style: SpaceStyle.drawing,
          parts: parts,
          section: cut ? c.sectionPlane : null,
        ),
      );
      recorder.endRecording().dispose();
      if (lap == 1) {
        micros.add(renderer.stats.micros);
        drawn = math.max(drawn, renderer.stats.triangles);
      }
    }
  }
  renderer.dispose();
  c.dispose();
  return {...summary(micros), 'maxTrianglesDrawn': drawn};
}

Future<void> mountPlayer(
  WidgetTester tester,
  GlobalKey key,
  SpaceStudy study, {
  String lang = 'en',
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
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
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: SpacePlayer(study: study, loadBytes: fileBytes),
      ),
    ),
  );
  await tester.runAsync(() async {
    for (var i = 0; i < 150 && space(tester).controller == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump();
    }
  });
  await tester.pump();
}

void main() {
  setUpAll(() => Directory(out).createSync(recursive: true));

  testWidgets('P09 stills: each building drawn, cut and lit', (tester) async {
    await tester.runAsync(() async {
      for (final id in kit) {
        final study = kitStudy(id), model = kitModel(study);
        final c = SpaceController(study, model);
        final r = SpaceRenderer(model);
        final whole = [for (final _ in model.parts) const SpacePartState()];
        SpaceScene scene(
          SpaceView view,
          SpaceStyle style, [
          SpaceSection? section,
          List<SpacePartState>? parts,
        ]) => SpaceScene(
          view: view,
          style: style,
          parts: parts ?? c.partStates(),
          section: section,
        );
        await still(r, c.scene(), '$id-choisy');
        final above = c.choisyView.copyWith(
          elevation: 28 * _degree,
          azimuth: 300 * _degree,
        );
        await still(r, scene(above, SpaceStyle.stone), '$id-stone');
        final b = model.bounds;
        await still(
          r,
          scene(
            c.choisyView.copyWith(
              elevation: 10 * _degree,
              azimuth: 20 * _degree,
            ),
            SpaceStyle.drawing,
            SpaceSection(0, b.centerX),
          ),
          '$id-long-section',
        );
        await still(
          r,
          scene(
            c.choisyView.copyWith(
              elevation: 10 * _degree,
              azimuth: 290 * _degree,
            ),
            SpaceStyle.drawing,
            SpaceSection(1, b.centerY),
          ),
          '$id-cross-section',
        );
        await still(
          r,
          scene(c.choisyView, SpaceStyle.night, c.sectionPlane),
          '$id-night',
        );
        c.setExplode(1);
        await still(
          r,
          scene(above.copyWith(azimuth: 225 * _degree), SpaceStyle.drawing),
          '$id-exploded',
        );
        c.setExplode(0);
        if (study.epochs.length > 1) {
          c.setEpoch(study.epochs.length - 1);
          await still(
            r,
            scene(above, SpaceStyle.stone, null, whole),
            '$id-${study.epochs.last.year}',
          );
        }
        r.dispose();
        c.dispose();
      }
    });
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('P09 player layouts: EN and TR, the section panel', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    final key = GlobalKey();
    for (final id in kit) {
      for (final (lang, scale) in [('en', 1.0), ('tr', 1.0), ('tr', 2.0)]) {
        await mountPlayer(
          tester,
          key,
          kitStudy(id),
          lang: lang,
          textScale: scale,
        );
        final tag = '$id-$lang-390-${(scale * 100).toInt()}';
        await capture(tester, key, '$out/$tag-player.png');
        if (scale == 1) {
          await tester.tap(find.byKey(const ValueKey('space-section')));
          await tester.pumpAndSettle();
          await capture(tester, key, '$out/$tag-section-panel.png');
          await tester.tapAt(const Offset(10, 10));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('P09 budgets: the kit beside P08 on the host', (tester) async {
    Map<String, Object> entry(SpaceStudy study) {
      final file = File(study.model);
      final watch = Stopwatch()..start();
      final model = SpaceModel.fromGlb(
        ByteData.sublistView(file.readAsBytesSync()),
      );
      final parseMs = watch.elapsedMicroseconds / 1000;
      return {
        'triangles': model.triangleCount,
        'vertices': model.parts.fold<int>(0, (n, p) => n + p.vertexCount),
        'parts': model.parts.length,
        'glbBytes': file.lengthSync(),
        'glbParseMs': double.parse(parseMs.toStringAsFixed(1)),
        'orbitChoisyCut': orbit(study, model, true),
        'orbitWhole': orbit(study, model, false),
      };
    }

    File('$out/budgets.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'measurement':
            'host (macOS, Flutter test, JIT) CPU frame build; not device fps. '
            'P08 is the yardstick: on the A52s it ran 54–57 fps in its default '
            'view and 60 fps under touch (P08/device-bench.json).',
        'budgetTriangles': SpaceStudy.triangleBudget,
        'how-a-dome-stands (P08)': entry(loadStudy()),
        for (final id in kit) id: entry(kitStudy(id)),
        'deviceFps': 'unverified: the A52s was not connected (O01)',
      }),
    );
    expect(loadModel().triangleCount, 20144);
  });

  testWidgets('P09 hook: three buildings assembling, ten seconds', (
    tester,
  ) async {
    await loadThemeFonts(tester);
    final dir = Directory('studio/cache/p09-hook')..createSync(recursive: true);
    for (final f in dir.listSync()) {
      f.deleteSync();
    }
    await tester.runAsync(() async {
      final studies = [for (final id in kit) kitStudy(id)];
      final models = [for (final s in studies) kitModel(s)];
      final controllers = [
        for (var i = 0; i < 3; i++)
          SpaceController(studies[i], models[i])..playReveal(),
      ];
      final renderers = [for (final m in models) SpaceRenderer(m)];
      const width = 1080.0, panel = 640.0, fps = 24, frames = 240;
      final palette = SpacePalette.of(SpaceStyle.drawing);
      TextPainter label(
        String text,
        double size,
        Color color, [
        String lang = 'tr',
      ]) => TextPainter(
        text: TextSpan(
          text: TypeRole.capitals(text, lang),
          style: TextStyle(
            fontFamily: TypeRole.displayFamily,
            fontFamilyFallback: TypeRole.displayFallback,
            fontSize: size,
            letterSpacing: size * .08,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final titles = [for (final id in kit) label(names[id]!, 34, palette.ink)];
      final honesty = label('Reconstruction', 20, palette.ink, 'en');
      const top = 96.0, area = Size(width, panel - top - 24);
      // Zoom and offset that fit the reveal's parts, as they turn, into
      // [area] with a margin: their bounds projected at five moments.
      (double, Offset) fit(SpaceController c) {
        final b = c.revealBounds;
        Rect box(double zoom) {
          Rect? r;
          for (final t in [0.0, .25, .5, .75, 1.0]) {
            c.seekReveal(t * c.study.reveal.seconds);
            final view = c.scene().view;
            final p = SpaceProjector(
              view.copyWith(zoom: view.zoom * zoom),
              area,
              c.model.bounds,
            );
            for (final x in [b.minX, b.maxX]) {
              for (final y in [b.minY, b.maxY]) {
                // Only what the plan cut keeps: from the cut up.
                for (final z in [math.max(b.minZ, c.sectionOffset), b.maxZ]) {
                  final o = p.toScreen(x, y, z);
                  final dot = Rect.fromCenter(center: o, width: 0, height: 0);
                  r = r == null ? dot : r.expandToInclude(dot);
                }
              }
            }
          }
          return r!;
        }

        final first = box(1);
        final zoom = math.min(
          area.width * .9 / first.width,
          area.height * .92 / first.height,
        );
        final fitted = box(zoom);
        c.seekReveal(0);
        return (zoom, area.center(Offset.zero) - fitted.center);
      }

      final fits = [for (final c in controllers) fit(c)];
      for (var f = 0; f < frames; f++) {
        // Each reveal (8 s) plays over the first nine seconds, then holds.
        final t = f / fps;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, width, panel * 3),
          Paint()..color = palette.ground,
        );
        for (var i = 0; i < 3; i++) {
          final c = controllers[i], s = studies[i];
          c.seekReveal(math.min(s.reveal.seconds, t * s.reveal.seconds / 9));
          canvas
            ..save()
            ..translate(0, panel * i)
            ..clipRect(const Rect.fromLTWH(0, 0, width, panel));
          // Each drawing is fitted once into the panel under its title.
          final scene = c.scene();
          final (zoom, shift) = fits[i];
          canvas
            ..save()
            ..translate(shift.dx, top + shift.dy);
          renderers[i].paint(
            canvas,
            area,
            SpaceScene(
              view: scene.view.copyWith(zoom: scene.view.zoom * zoom),
              style: scene.style,
              parts: scene.parts,
              section: scene.section,
            ),
          );
          canvas.restore();
          titles[i].paint(canvas, const Offset(48, 40));
          honesty.paint(
            canvas,
            Offset(width - 48 - honesty.width, panel - 40 - honesty.height),
          );
          canvas.restore();
          if (i > 0) {
            canvas.drawLine(
              Offset(48, panel * i),
              Offset(width - 48, panel * i),
              Paint()
                ..color = palette.ink
                ..strokeWidth = 1,
            );
          }
        }
        final image = await recorder.endRecording().toImage(
          width.toInt(),
          (panel * 3).toInt(),
        );
        final png = await encodePng(image);
        image.dispose();
        final name = (f + 1).toString().padLeft(4, '0');
        File('${dir.path}/$name.png').writeAsBytesSync(png);
        if (f == 0 || f == 119 || f == 239) {
          File('$out/hook-frame-${f + 1}.png').writeAsBytesSync(png);
        }
      }
      for (final r in renderers) {
        r.dispose();
      }
      for (final c in controllers) {
        c.dispose();
      }
      expect(dir.listSync(), hasLength(frames));
    });
  }, timeout: const Timeout(Duration(minutes: 10)));
}
