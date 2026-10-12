// Widget captures for P04; run with `flutter test tool/captures/p04_capture_test.dart`.
// Writes studio/captures/P04/: Today at 360/390/430 dp in EN/TR at 100/200%,
// three Detail-of-the-day stills, every tab, the dial's list alternative,
// the explorer landing at a detail and the first-run frames (EN and TR).
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/first_run/first_run_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/helpers.dart';
import '../../test/plate_player_test.dart' show assetsReady;

const out = 'studio/captures/P04';

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

/// Decodes every on-screen image before a frame is captured (on the device
/// the deferred first frame waits for today's detail in the same way).
Future<void> imagesReady(WidgetTester tester) async {
  for (final element in find.byType(Image).evaluate()) {
    final image = element.widget as Image;
    await tester.runAsync(() => precacheImage(image.image, element));
  }
  await tester.pump();
}

Future<void> scrollBy(WidgetTester tester, double dy) async {
  // Down the centre line: radial on the dial, so the page scrolls.
  await tester.drag(find.byType(Scrollable).first, Offset(0, -dy));
  await tester.pumpAndSettle();
}

Map<String, String> tabLabels(String language) => language == 'en'
    ? {'city': 'City', 'milestones': 'Milestones', 'mosaic': 'Mosaic'}
    : {'city': 'Şehir', 'milestones': 'Taşlar', 'mosaic': 'Mozaik'};

void main() {
  setUpAll(() => Directory(out).createSync(recursive: true));

  testWidgets('Detail of the day: three dates, 3× stills', (tester) async {
    for (final day in [1, 2, 3]) {
      final key = GlobalKey();
      await pumpShell(tester, boundary: key, date: DateTime(2026, 10, day, 9));
      await imagesReady(tester);
      await capture(
        tester,
        key,
        'detail-of-the-day-2026-10-0$day',
        pixelRatio: 3,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Today and tabs at 360/390/430 dp, EN/TR, 100/200%', (
    tester,
  ) async {
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
          await imagesReady(tester);
          await capture(tester, key, 'today-$label');
          await scrollBy(tester, 640);
          await capture(tester, key, 'today-$label-dial');
          await scrollBy(tester, 700);
          await capture(tester, key, 'today-$label-chapter');
          if (width == 390) {
            for (final MapEntry(key: tab, value: name) in tabLabels(
              language,
            ).entries) {
              await tester.tap(destination(name));
              await ready(tester);
              await capture(tester, key, '$tab-$label');
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
  });

  testWidgets('dial list, place page, register sheet, explorer landing', (
    tester,
  ) async {
    final key = GlobalKey();
    await pumpShell(tester, boundary: key);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('dial-toggle')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('dial-toggle')));
    await tester.pumpAndSettle();
    await capture(tester, key, 'today-390-en-list');
    await tester.scrollUntilVisible(
      find.text('308°'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('308°'));
    await tester.pumpAndSettle();
    await capture(tester, key, 'place-chora-390-en');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(destination('Milestones'));
    await tester.pumpAndSettle();
    final vii = find.byKey(const ValueKey('milestone-VII'));
    await tester.scrollUntilVisible(
      vii,
      400,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(vii);
    await tester.pumpAndSettle();
    await capture(tester, key, 'milestone-vii-sheet-390-en');
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await tester.tap(destination('Today'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('detail-of-day')),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('detail-of-day')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, key, 'detail-flight-mid');
    await assetsReady(tester);
    await capture(tester, key, 'detail-landed-390-en');
  });

  testWidgets('first-run frames, EN and TR', (tester) async {
    for (final language in ['en', 'tr']) {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      SharedPreferences.setMockInitialValues({'milion_language': language});
      await loadThemeFonts(tester);
      await tester.pumpWidget(RepaintBoundary(key: key, child: testApp()));
      await waitForContent(tester);
      final times = language == 'en'
          ? [1.4, 2.6, 3.6, 4.6, 5.2, 6.0, 7.0, 8.2, 9.2, 10.1, 11.6]
          : [4.6, 10.1, 11.6];
      for (final t in times) {
        tester
                .state<FirstRunScreenState>(find.byType(FirstRunScreen))
                .clock
                .value =
            t / 12;
        await tester.pump();
        await capture(
          tester,
          key,
          'first-run-$language-${t.toStringAsFixed(1)}',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
    tester.view.reset();
  });
}
