// P07 evidence: III–V layouts, reduced-motion stills, budgets and the
// Genealogy look-up hook. Run: flutter test tool/captures/p07_capture_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers.dart' show loadThemeFonts;
import '../../test/plate_player_test.dart' show loadPlate, state;
import 'p06_capture_test.dart' show capture, mount;

const out = 'studio/captures/P07';

void main() {
  testWidgets(
    'P07 III–V original, bilingual 360/390/430 layouts, controls and reduced stills',
    (tester) async {
      Directory(out).createSync(recursive: true);
      addTearDown(tester.view.reset);
      await loadThemeFonts(tester);
      final key = GlobalKey(), budgets = <String, Object>{};
      for (final name in ['metochites', 'genealogy', 'enrollment']) {
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
              if (w == 390 && scale == 1) {
                await tester.tap(find.byKey(const ValueKey('plate-layers')));
                await tester.pumpAndSettle();
                await capture(tester, key, '$out/$tag-layers.png');
              }
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
            }
          }
        }
        await mount(tester, key, p, reduced: true);
        final player = state(tester);
        budgets[name] = {
          'decodedTextureBytes': player.assets.textureBytes,
          'rig': player.assets.rig == null ? 'none' : 'present',
          'storySeconds': p.storySeconds,
          'revealSeconds': p.revealSeconds,
          'revealMoment': p.revealMoment,
          'detailCount': p.details.length,
          'lookUp': p.lookUp != null,
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
          'measurement': 'native Flutter test renderer; decoded images, not total device GPU memory',
          'deviceFps': 'unverified; no Android phone/emulator connected',
          'plates': budgets,
        }),
      );
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );

  testWidgets('P07 hook: eight seconds of looking up into the Genealogy dome', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    final key = GlobalKey(), p = await loadPlate('genealogy');
    await mount(tester, key, p);
    final c = state(tester).controller..playReveal();
    final dir = Directory('/tmp/milion-p07-genealogy-frames')
      ..createSync(recursive: true);
    await tester.pump();
    expect(c.lookUp, isTrue);
    for (var frame = 0; frame < 192; frame++) {
      await tester.pump(const Duration(microseconds: 41667));
      await capture(
        tester,
        key,
        '${dir.path}/${frame.toString().padLeft(4, '0')}.png',
      );
      if (frame == 0 || frame == 96 || frame == 191) {
        await capture(tester, key, '$out/genealogy-look-up-$frame.png');
      }
    }
    expect(c.honesty.name, 'DEPTH');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 4)));
}
