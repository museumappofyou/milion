import 'dart:io';
import 'dart:ui' as ui;

import 'package:milion/screens/anastasis_relief_screen.dart';
import 'package:milion/screens/last_judgment_relief_screen.dart';
import 'package:milion/screens/scene_explorer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'interactive_scene_screenshot_test.dart' show load;

void main() {
  testWidgets('capture actual figure playback for both scenes', (tester) async {
    tester.view.physicalSize = const Size(720, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
      if (font.existsSync()) {
        final loader = FontLoader('CaptureFont')
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
        await loader.load();
      }
    });
    for (final (name, home, detail) in [
      ('anastasis', const AnastasisReliefScreen(), 'Christ'),
      ('last_judgment', const LastJudgmentReliefScreen(), 'Deesis'),
      ('last_judgment_angel', const LastJudgmentReliefScreen(), 'Heavens'),
    ]) {
      const sceneFilter = String.fromEnvironment('SCENE');
      if (sceneFilter.isNotEmpty && sceneFilter != name) continue;
      final directory = Directory('/tmp/chora-figure-v2-frames/$name')
        ..createSync(recursive: true);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(useMaterial3: true, fontFamily: 'CaptureFont'),
            home: home,
          ),
        ),
      );
      await load(tester);
      await tester.tap(find.text(detail));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restored'));
      await load(tester);
      if (name == 'anastasis') {
        tester
            .state<SceneExplorerScreenState>(find.byType(SceneExplorerScreen))
            .zoomBy(.75);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Animate figures'));
      await tester.pump();
      const previewOnly = bool.fromEnvironment('PREVIEW_ONLY');
      for (var frame = 0; frame < (previewOnly ? 5 : 144); frame++) {
        if (frame > 0) {
          await tester.pump(
            Duration(microseconds: previewOnly ? 1250000 : 41667),
          );
        }
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.png,
          ))!;
          File('${directory.path}/${frame.toString().padLeft(4, '0')}.png')
              .writeAsBytesSync(bytes.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
