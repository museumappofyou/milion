// P07 pipeline stage (f): the 6-second preview, drawn by the real PlatePlayer.
// Run by tool/plate/build.py:
//   flutter test tool/captures/plate_preview_test.dart \
//     --dart-define=PLATE=assets/plates/<id>/manifest.json --dart-define=FRAMES=<dir>
// Plays the reveal from 0 s (in the look-up view for LU plates) at 24 fps on a
// 390×844 portrait phone and writes 144 numbered PNG frames.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/plate/player.dart';

import '../../test/helpers.dart' show loadThemeFonts;
import '../../test/plate_player_test.dart' show assetsReady, state;
import '../../test/plate_engine_test.dart' show plateAt;

const plate = String.fromEnvironment('PLATE');
const frames = String.fromEnvironment('FRAMES');

/// Native toImage can omit retained layers after camera ticks; repaint first.
Future<void> capture(WidgetTester tester, GlobalKey key, String path) async {
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  repaint(key.currentContext!.findRenderObject()!);
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

void main() {
  testWidgets('six seconds of the reveal', (tester) async {
    if (plate.isEmpty || frames.isEmpty) {
      markTestSkipped('run through tool/plate/build.py');
      return;
    }
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await loadThemeFonts(tester);
    final p = plateAt(plate), key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: DesignTheme.lamp,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlatePlayer(manifest: p),
        ),
      ),
    );
    await assetsReady(tester);
    // A preview of the error screen is a failed build, not a preview.
    expect(
      state(tester).assets.images,
      isNotEmpty,
      reason: 'plate failed to load',
    );
    final c = state(tester).controller;
    c.playReveal();
    await tester.pump();
    Directory(frames).createSync(recursive: true);
    for (var frame = 0; frame < 144; frame++) {
      await tester.pump(const Duration(microseconds: 41667));
      await capture(
        tester,
        key,
        '$frames/${(frame + 1).toString().padLeft(4, '0')}.png',
      );
    }
    expect(c.lookUp, c.canLookUp);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
