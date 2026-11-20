// P14 evidence on the host: Milestone XVII's drawn section at each story
// beat and its reveal, a ship's sheet, and the cistern walk's plan (the
// view a phone without Flutter GPU shows). The walk itself is drawn by
// flutter_scene, which the test host cannot run: its frames come from the
// A52s (device-*.png) and from tool/walk/preview.py. Run:
//   flutter test tool/captures/p14_capture_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/l10n/app_localizations.dart';
import 'package:milion/section/section.dart';
import 'package:milion/section/section_player.dart';
import 'package:milion/shell/app_scope.dart';
import 'package:milion/walk/walk.dart';
import 'package:milion/walk/walk_player.dart';

import '../../test/helpers.dart' show loadThemeFonts;

const out = 'studio/captures/P14';
final only = Platform.environment['P14_ONLY'];

Future<void> shot(WidgetTester tester, GlobalKey key, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    File('$out/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
    image.dispose();
  });
}

Widget host(
  ContentRegistry registry,
  Widget child,
  GlobalKey key, {
  Locale locale = const Locale('en'),
}) => RepaintBoundary(
  key: key,
  child: AppScope(
    registry: registry,
    error: null,
    retry: () {},
    clock: DateTime.now,
    recognised: const {},
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  ),
);

void main() {
  late ContentRegistry registry;
  setUpAll(() async {
    Directory(out).createSync(recursive: true);
    registry = await ContentRepository((p) => File(p).readAsString()).load();
  });

  SectionManifest section() => SectionManifest.fromJson(
    jsonDecode(File('assets/section/yenikapi/section.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  testWidgets('XVII: the section at each beat, the reveal and a ship', (
    tester,
  ) async {
    if (only != null && only != 'section') return;
    await loadThemeFonts(tester);
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    for (final locale in const [Locale('en'), Locale('tr')]) {
      await tester.pumpWidget(
        host(registry, SectionPlayer(section: section()), key, locale: locale),
      );
      await tester.pumpAndSettle();
      final player = tester.state<SectionPlayerState>(
        find.byType(SectionPlayer),
      );
      final c = player.controller;
      if (locale.languageCode == 'en') {
        c.play();
        for (final t in [0.5, 4.0, 7.0, 9.5]) {
          c.advance(t - c.seconds);
          await tester.pump();
          await shot(tester, key, 'xvii-reveal-${t.toStringAsFixed(1)}s');
        }
      }
      c.stills();
      for (var i = 0; i < c.manifest.stills.length; i++) {
        c.stills(i);
        await tester.pump();
        await shot(
          tester,
          key,
          'xvii-${c.manifest.stills[i]}-${locale.languageCode}',
        );
      }
      if (locale.languageCode == 'en') {
        // Not awaited: the sheet's future ends when it closes, and a timer
        // never fires in the test's fake time.
        unawaited(player.showShip(c.manifest.ships[3]));
        await tester.pumpAndSettle();
        await shot(tester, key, 'xvii-ship-yk4');
      }
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('XVI: the walk\'s plan without Flutter GPU', (tester) async {
    if (only != null && only != 'walk') return;
    await loadThemeFonts(tester);
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final walk = WalkManifest.fromJson(
      jsonDecode(
        File('assets/walk/basilica-cistern/walk.json').readAsStringSync(),
      ) as Map<String, dynamic>,
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      host(registry, WalkPlayer(walk: walk, backend: false), key),
    );
    await tester.pumpAndSettle();
    final player = tester.state<WalkPlayerState>(find.byType(WalkPlayer));
    player.controller.stills(3);
    await tester.pump();
    await shot(tester, key, 'xvi-plan-fallback');
  });
}
