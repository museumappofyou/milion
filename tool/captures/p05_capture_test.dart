// Widget captures for P05; run with `flutter test tool/captures/p05_capture_test.dart`.
// Writes studio/captures/P05/: the dig at 360/390/430 dp in EN/TR at 100/200%,
// the visit card, the depth gauge in use, a reduced-motion still, and the 216
// frames of the 9-second vertical recording of digging through Chora's layers
// (encode with ffmpeg; see the P05 changelog).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test/helpers.dart';

const out = 'studio/captures/P05';
const frames = '$out/chora-dig-frames';

Future<void> capture(
  WidgetTester tester,
  GlobalKey key,
  String name, {
  double pixelRatio = 1,
}) async {
  expect(tester.takeException(), isNull, reason: name);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File('$out/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> captureTo(
  WidgetTester tester,
  GlobalKey key,
  String path,
) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File(path).writeAsBytesSync(bytes.buffer.asUint8List());
    image.dispose();
  });
}

/// Every on-screen image decoded before the frame is captured.
Future<void> imagesReady(WidgetTester tester) async {
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget as Image;
    await tester.runAsync(() => precacheImage(image.image, element));
  }
  await tester.pump();
}

Future<void> openChora(WidgetTester tester) async {
  final tr = tester.any(find.text('Şehir'));
  await tester.tap(tr ? destination('Şehir') : destination('City'));
  await ready(tester);
  final chora = tr
      ? find.text('Kariye Camii')
      : find.text('Kariye Mosque (Chora)');
  await tester.scrollUntilVisible(
    chora,
    400,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(chora);
  await ready(tester);
  await imagesReady(tester);
}

Future<void> scrollBy(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(Scrollable).first, Offset(0, -dy));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    Directory(out).createSync(recursive: true);
    Directory(frames).createSync(recursive: true);
  });

  testWidgets('Chora dig at 360/390/430 dp, EN/TR, 100/200%', (tester) async {
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final width in [360.0, 390.0, 430.0]) {
      for (final language in ['en', 'tr']) {
        for (final scale in [1.0, 2.0]) {
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          final key = GlobalKey();
          final label = '${width.toInt()}-$language-${(scale * 100).round()}';
          await pumpShell(
            tester,
            boundary: key,
            size: Size(width, 844),
            prefs: {'milion_language': language},
          );
          await openChora(tester);
          await imagesReady(tester);
          await capture(tester, key, 'dig-top-$label');
          // The visit card inside the present layer.
          await tester.scrollUntilVisible(
            find.text(language == 'tr' ? 'Ziyaret' : 'Visit'),
            500,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await capture(tester, key, 'dig-visit-$label');
          // The Metochites layer and its Milestone entry points.
          await tester.scrollUntilVisible(
            find.text(
              language == 'tr' ? '1321 yılı · Bizans' : 'Year 1321 · Byzantine',
            ),
            600,
            maxScrolls: 200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await capture(tester, key, 'dig-metochites-$label');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
    tester.view.reset();
  });

  testWidgets('reduced motion still and the gauge mid-drag', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final key = GlobalKey();
    await pumpShell(tester, boundary: key);
    await openChora(tester);
    await imagesReady(tester);
    await scrollBy(tester, 900);
    await capture(tester, key, 'dig-reduced-motion-390-en');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('nine seconds of digging: 216 frames at 24 fps', (tester) async {
    final key = GlobalKey();
    await pumpShell(tester, boundary: key, size: const Size(390, 844));
    await openChora(tester);
    await imagesReady(tester);
    final state = tester.state<ScrollableState>(find.byType(Scrollable).first);
    final extent = state.position.maxScrollExtent;
    const total = 24 * 9;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(CustomScrollView)),
    );
    for (var i = 0; i < total; i++) {
      await gesture.moveBy(Offset(0, -extent / total));
      await tester.pump(const Duration(milliseconds: 1000 ~/ 24));
      await captureTo(tester, key, '$frames/frame-${i.toString().padLeft(3, '0')}.png');
    }
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  }, timeout: const Timeout(Duration(minutes: 10)));
}
