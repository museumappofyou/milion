import 'dart:io';
import 'dart:ui' as ui;

import 'package:milion/screens/anastasis_relief_screen.dart';
import 'package:milion/screens/last_judgment_relief_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const out = 'studio/figure_animation/v2/previews/layouts';

Future<void> load(WidgetTester tester) async {
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

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File('$out/$name.png').writeAsBytesSync(data.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets('interactive scene layouts and comparison captures', (
    tester,
  ) async {
    Directory(out).createSync(recursive: true);
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
    final key = GlobalKey();
    for (final (name, home) in [
      ('anastasis', const AnastasisReliefScreen()),
      ('last_judgment', const LastJudgmentReliefScreen()),
    ]) {
      for (final (w, h) in [
        (360.0, 800.0),
        (390.0, 844.0),
        (430.0, 932.0),
        (1440.0, 900.0),
      ]) {
        tester.view.physicalSize = Size(w, h);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                fontFamily: 'CaptureFont',
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF1F3B73),
                ),
              ),
              home: home,
            ),
          ),
        );
        await load(tester);
        final size = '${w.toInt()}x${h.toInt()}';
        await capture(tester, key, '${name}_overview_$size');
        if (w == 390) {
          await tester.tap(find.text('Christ'));
          await tester.pumpAndSettle();
          await capture(tester, key, '${name}_christ_relief');
          await tester.tap(find.text('Original'));
          await tester.pumpAndSettle();
          await capture(tester, key, '${name}_christ_original');
          await tester.tap(find.text('Restored'));
          await load(tester);
          await capture(tester, key, '${name}_christ_restored_4k_full');
          await tester.drag(
            find.byKey(const ValueKey('restoration-strength')),
            const Offset(-90, 0),
          );
          await tester.pumpAndSettle();
          await capture(tester, key, '${name}_christ_restored_blend');
          await tester.tap(find.text('Relief'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Animate figures'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 2));
          await capture(tester, key, '${name}_figure_motion');
          await tester.tap(find.text('Pause figures'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Scene options'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Restoration studies'));
          await load(tester);
          await tester.tap(
            find.text(
              name == 'anastasis'
                  ? 'Christ and the faces'
                  : 'Christ, Mary and John',
            ),
          );
          await load(tester);
          await capture(tester, key, '${name}_detail_file_study');
        }
        if (w == 360) {
          await tester.tap(find.text('Restored'));
          await load(tester);
          await capture(tester, key, '${name}_restored_360x800');
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
}
