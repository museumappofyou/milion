// Captures real widget screenshots of the Anastasis tab into
// build/anastasis-preview/ui-*.png so the rendered UI can be inspected
// without a device. Tool, not part of the app's test suite:
//
//   flutter test tool/anastasis_screenshot_test.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:milion/screens/anastasis_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('captures the Anastasis tab', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final boundaryKey = GlobalKey();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(key: boundaryKey, child: const AnastasisTab()),
        ),
      );
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.text('The Anastasis on its semi-dome').evaluate().isNotEmpty) {
          break;
        }
      }
      Directory('build/anastasis-preview').createSync(recursive: true);
      await _capture(tester, boundaryKey, 'ui-top.png');

      await _scroll(tester, -260);
      await _capture(tester, boundaryKey, 'ui-curvature.png');

      await _scroll(tester, -260);
      await _capture(tester, boundaryKey, 'ui-anchors.png');

      await _scroll(tester, -260);
      await _capture(tester, boundaryKey, 'ui-captures.png');

      await _scroll(tester, -260);
      await _capture(tester, boundaryKey, 'ui-provenance.png');

      // Surface guides with hotspot labels: back to the top.
      for (var i = 0; i < 4; i++) {
        await _scroll(tester, 300);
      }
      await tester.tap(find.text('Surface guides'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 16));
      await _capture(tester, boundaryKey, 'ui-guides.png');
    });
  });
}

Future<void> _scroll(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(Scrollable).first, Offset(0, dy));
  await Future<void>.delayed(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String name,
) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (bytes == null) {
    return;
  }
  File('build/anastasis-preview/$name')
      .writeAsBytesSync(bytes.buffer.asUint8List());
  stdout.writeln('wrote build/anastasis-preview/$name');
}
