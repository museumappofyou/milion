// flutter test --no-pub tool/mobile_relief_v5_screenshot_test.dart
// Real widget captures of the fifth-pass static relief. The camera is fixed:
// the test also drags the viewer and checks that the frame does not change.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:milion/screens/anastasis_v5_screen.dart';
import 'package:milion/widgets/anastasis_dome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _out = 'anastasis_25d/v5/flutter';

void main() {
  testWidgets('captures the frozen v5 relief at phone and desktop sizes', (
    tester,
  ) async {
    final key = GlobalKey();
    Directory(_out).createSync(recursive: true);
    await tester.runAsync(() async {
      for (final (width, height) in [
        (390.0, 844.0),
        (360.0, 800.0),
        (430.0, 932.0),
        (1440.0, 900.0),
      ]) {
        tester.view.physicalSize = Size(width, height);
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(key: key, child: const AnastasisV5Screen()),
          ),
        );
        for (var i = 0; i < 70; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump();
          if (find.text('Left rock').evaluate().isNotEmpty) break;
        }
        expect(find.text('Left rock'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 50));
        final size = '${width.toInt()}x${height.toInt()}';
        final center = await _capture(key, 'relief_$size.png');
        if (width != 390) {
          await tester.pumpWidget(const SizedBox.shrink());
          continue;
        }
        // Frozen camera: a drag must not change a single pixel.
        await tester.drag(
          find.byType(AnastasisDomeView),
          const Offset(120, 40),
        );
        await tester.pump(const Duration(milliseconds: 700));
        final dragged = await _capture(key, null);
        expect(dragged, equals(center), reason: 'v5 camera must stay fixed');
        await tester.tap(find.text('Original'));
        await tester.pump();
        await _capture(key, 'original_$size.png');
        await tester.tap(find.text('Relief'));
        await tester.pump();
        for (final focus in ['Figures', 'Left rock', 'Right rock']) {
          await tester.ensureVisible(find.text(focus));
          await tester.tap(find.text(focus));
          await tester.pump();
          final name = focus.toLowerCase().replaceAll(' ', '_');
          await _capture(key, '${name}_$size.png');
          await tester.tap(find.text('Original'));
          await tester.pump();
          await _capture(key, '${name}_original_$size.png');
          await tester.tap(find.text('Relief'));
          await tester.pump();
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
    tester.view.reset();
  });
}

Future<Uint8List> _capture(GlobalKey key, String? name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final bytes = data!.buffer.asUint8List();
  if (name != null) File('$_out/$name').writeAsBytesSync(bytes);
  return bytes;
}
