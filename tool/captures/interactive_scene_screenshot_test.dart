import 'dart:io';
import 'dart:ui' as ui;

import 'package:milion/screens/anastasis_relief_screen.dart';
import 'package:milion/screens/last_judgment_relief_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/l10n/strings.dart';

import '../../test/frontier_navigation_test.dart' show loadThemeFonts;
import '../../test/scene_explorer_test.dart' show assetsReady, visibleTap;

import 'package:flutter_test/flutter_test.dart';

const out = 'studio/captures/P03/artwork-regression';

Future<void> load(WidgetTester tester) => assetsReady(tester);

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
    await loadThemeFonts(tester);
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
              theme: DesignTheme.lamp,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: home,
            ),
          ),
        );
        await load(tester);
        final size = '${w.toInt()}x${h.toInt()}';
        await capture(tester, key, '${name}_overview_$size');
        if (w == 390) {
          await tester.tap(find.byType(DropdownButtonFormField<String>));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Christ').last);
          await tester.pumpAndSettle();
          for (final label in ['Depth', 'Original', 'Reconstruction']) {
            await visibleTap(tester, label);
            await load(tester);
            await capture(tester, key, '${name}_${label.toLowerCase()}_$size');
          }
          await tester.tap(find.byTooltip('Scene options'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Restoration studies'));
          await load(tester);
          await visibleTap(tester, 'Reconstruction');
          await load(tester);
          await capture(tester, key, '${name}_study_$size');
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
}
