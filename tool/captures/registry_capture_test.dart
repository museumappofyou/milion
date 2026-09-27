import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/screens/registry_screen.dart';
import 'package:milion/theme/milion_theme.dart';

import '../../test/frontier_navigation_test.dart' show loadThemeFonts;

void main() {
  testWidgets('P02 registry EN/TR and district-count evidence at 390 dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    final registry = await tester.runAsync(
      () => ContentRepository((p) => File(p).readAsString()).load(),
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          theme: MilionTheme.light,
          debugShowCheckedModeBanner: false,
          home: RegistryScreen(registry: registry),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async => tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('studio/captures/P02/$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
    await capture('registry-en');
    await tester.tap(find.text('TR'));
    await tester.pumpAndSettle();
    await capture('registry-tr');
    await tester.tap(find.text('İlçeye göre sayılar · 39'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await capture('registry-districts');
    expect(tester.takeException(), isNull);
  });
}
