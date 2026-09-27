import 'dart:io';
import 'dart:ui' as ui;

import 'package:milion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/frontier_navigation_test.dart'
    show ready, destination, loadThemeFonts;

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File('studio/ui_refresh/previews/$name.png')
        .writeAsBytesSync(data.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  testWidgets(
    'front page and collection layouts on phone, tablet and desktop',
    (tester) async {
      // Visual captures run through flutter test from tool/captures/.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      Directory('studio/ui_refresh/previews').createSync(recursive: true);
      addTearDown(tester.view.reset);
      await loadThemeFonts(tester);
      for (final size in [
        const Size(360, 800),
        const Size(390, 844),
        const Size(768, 1024),
        const Size(1440, 1000),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(key: key, child: const MilionApp()),
        );
        await ready(tester);
        final label = '${size.width.toInt()}x${size.height.toInt()}';
        await capture(tester, key, 'home_$label');
        final scroll = find.byKey(const PageStorageKey('frontier-scroll'));
        await tester.drag(scroll, Offset(0, -size.height * .8));
        await tester.pumpAndSettle();
        await capture(tester, key, 'scenes_$label');
        await tester.drag(scroll, const Offset(0, -1500));
        await tester.pumpAndSettle();
        await capture(tester, key, 'footer_$label');
        if (size.width < 900) {
          await tester.tap(destination('Collection'));
        } else {
          await tester.tap(find.text('Collection'));
        }
        await ready(tester);
        await tester.tap(find.text('Interactive'));
        await tester.pumpAndSettle();
        await capture(tester, key, 'collection_$label');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );
  testWidgets('front page accommodates larger system text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await loadThemeFonts(tester);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const MilionApp()),
    );
    await ready(tester);
    await capture(tester, key, 'home_large_text');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
