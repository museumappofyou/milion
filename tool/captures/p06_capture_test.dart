import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/plate/player.dart';

import '../../test/helpers.dart' show loadThemeFonts;
import '../../test/scene_explorer_test.dart' show assetsReady, loadPlate, state;

const out = 'studio/captures/P06';
Future<void> capture(WidgetTester tester, GlobalKey key, String path) async {
  final root = key.currentContext!.findRenderObject()!;
  // Native test toImage can omit retained button layers after camera ticks.
  // Repaint the same state; this does not advance the timeline or sensor.
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  repaint(root);
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File(path).writeAsBytesSync(data.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> mount(
  WidgetTester tester,
  GlobalKey key,
  PlateManifest p, {
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
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: DesignTheme.lamp,
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
        home: PlatePlayer(manifest: p),
      ),
    ),
  );
  await assetsReady(tester);
}

void layoutCaptures() {
  testWidgets(
    'P06 original, bilingual 360/390/430 layouts, controls and reduced stills',
    (tester) async {
      Directory(out).createSync(recursive: true);
      addTearDown(tester.view.reset);
      await loadThemeFonts(tester);
      final key = GlobalKey(), budgets = <String, Object>{};
      for (final name in ['anastasis', 'judgment']) {
        final p = await loadPlate(name);
        for (final w in [360.0, 390.0, 430.0]) {
          for (final lang in ['en', 'tr']) {
            for (final scale in [1.0, 2.0]) {
              await mount(
                tester,
                key,
                p,
                width: w,
                lang: lang,
                textScale: scale,
              );
              final tag = '$name-$lang-${w.toInt()}-${(scale * 100).toInt()}';
              await capture(tester, key, '$out/$tag-original.png');
              await tester.tap(find.byKey(const ValueKey('plate-layers')));
              await tester.pumpAndSettle();
              await capture(tester, key, '$out/$tag-layers.png');
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            }
          }
        }
        await mount(tester, key, p, reduced: true);
        final player = state(tester);
        budgets[name] = {
          'decodedTextureBytes': player.assets.textureBytes,
          'meshVertices': player.assets.rig!.cols * player.assets.rig!.rows,
          'geometryVertices':
              player.assets.geometry!.cols * player.assets.geometry!.rows,
          'storySeconds': p.storySeconds,
          'revealSeconds': p.revealSeconds,
          'detailCount': p.details.length,
        };
        for (final beat in p.beats) {
          player.controller.step(1);
          await tester.pump();
          await capture(tester, key, '$out/$name-reduced-${beat.id}.png');
          expect(player.ticking, isFalse);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
      File('$out/budgets.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'measurement': 'native Flutter test renderer; decoded images and mesh, not total device GPU memory',
          'deviceFps': 'unverified; no Android phone/emulator connected',
          'plates': budgets,
        }),
      );
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

void figureClips() {
  testWidgets('P06 three 8-second portrait hooks from actual player frames', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    final key = GlobalKey();
    for (final (clip, plate) in [
      ('gold-tilt', 'anastasis'),
      ('river-flow', 'judgment'),
      ('wrist-grip', 'anastasis'),
    ]) {
      final p = await loadPlate(plate);
      await mount(tester, key, p);
      final player = state(tester), c = player.controller;
      final dir = Directory('/tmp/milion-p06-$clip-frames')
        ..createSync(recursive: true);
      if (clip == 'gold-tilt') {
        player.focus(p.beats.first.detailId);
        c.setLight(PlateLight.gilded);
      }
      if (clip == 'river-flow') {
        player.focus(p.beats[2].detailId);
        c.setPaintMotion(river: true);
      }
      if (clip == 'wrist-grip') {
        c.seek(7);
        c.play();
      }
      await tester.pump();
      for (var frame = 0; frame < 192; frame++) {
        if (clip == 'gold-tilt') {
          player.tilt.drag(
            Offset(
              math.sin(frame / 192 * math.pi * 2) * .85,
              math.cos(frame / 192 * math.pi * 2) * .3,
            ),
          );
        }
        await tester.pump(const Duration(microseconds: 41667));
        await capture(
          tester,
          key,
          '${dir.path}/${frame.toString().padLeft(4, '0')}.png',
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}

void main() {
  layoutCaptures();
  figureClips();
}
