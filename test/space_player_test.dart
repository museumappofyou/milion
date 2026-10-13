import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/design/components.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/space/camera.dart';
import 'package:milion/space/player.dart';
import 'package:milion/space/style.dart';

import 'helpers.dart' show loadThemeFonts;
import 'space_engine_test.dart' show loadStudy;

Future<ByteData> fileBytes(String path) async =>
    ByteData.sublistView(File(path).readAsBytesSync());

Future<void> openStudy(
  WidgetTester tester, {
  bool reduced = false,
  GlobalKey? boundary,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await loadThemeFonts(tester);
  final study = loadStudy();
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          disableAnimations: reduced,
        ),
        child: RepaintBoundary(
          key: boundary,
          child: SpacePlayer(
            key: ValueKey(study.id),
            study: study,
            loadBytes: fileBytes,
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump();
      if (find.byType(TesseraLoader).evaluate().isEmpty) break;
    }
  });
  await tester.pump();
}

SpacePlayerState space(WidgetTester tester) =>
    tester.state<SpacePlayerState>(find.byType(SpacePlayer));

Future<void> openPanel(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

Future<void> closePanel(WidgetTester tester) async {
  await tester.tapAt(const Offset(10, 10));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'opens on the drawing: RECONSTRUCTION, 537, Choisy, no autoplay',
    (tester) async {
      await openStudy(tester);
      final player = space(tester), c = player.controller!;
      expect(find.text('RECONSTRUCTION'), findsOneWidget);
      expect(find.text('Hagia Sophia, 537'), findsOneWidget);
      expect(find.byKey(const ValueKey('space-caption')), findsNothing);
      expect(player.ticking, isFalse);
      expect(c.view, c.choisyView);
      expect(player.renderer!.stats.faces, greaterThan(0));
      expect(player.renderer!.stats.poche, greaterThan(0), reason: 'plan cut');
      // TalkBack reads the description and offers the story as actions.
      final semantics = tester.getSemantics(
        find.byKey(const ValueKey('space-viewport')),
      );
      expect(semantics.label, contains('A diagram, not a survey'));
      expect(semantics.getSemanticsData().customSemanticsActionIds, isNotEmpty);
    },
  );

  testWidgets('one finger orbits within limits, two fingers zoom', (
    tester,
  ) async {
    await openStudy(tester);
    final c = space(tester).controller!;
    final start = c.view;
    await tester.drag(
      find.byKey(const ValueKey('space-viewport')),
      const Offset(-120, 4000),
    );
    await tester.pump();
    expect(c.view.azimuth, isNot(start.azimuth));
    expect(c.view.elevation, closeTo(85 * 3.141592653589793 / 180, 1e-6));
    final centre = tester.getCenter(
      find.byKey(const ValueKey('space-viewport')),
    );
    final a = await tester.startGesture(centre - const Offset(40, 0));
    final b = await tester.startGesture(centre + const Offset(40, 0));
    await tester.pump();
    await a.moveBy(const Offset(-60, 0));
    await b.moveBy(const Offset(60, 0));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pump();
    expect(c.view.zoom, greaterThan(1.2));
    // Double-tap (away from the section handle) goes back to Choisy's view.
    final corner =
        tester.getTopLeft(find.byKey(const ValueKey('space-viewport'))) +
        const Offset(40, 120);
    await tester.tapAt(corner);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(corner);
    await tester.pumpAndSettle();
    expect(c.view, c.choisyView);
  });

  testWidgets('Assemble: steps with captions, scrubbing, the time scrubber', (
    tester,
  ) async {
    await openStudy(tester);
    final c = space(tester).controller!;
    await openPanel(tester, 'space-assemble');
    await tester.tap(find.byKey(const ValueKey('space-next')));
    await tester.pumpAndSettle();
    expect(c.sample!.beat.step.id, 'bay');
    await closePanel(tester);
    expect(find.textContaining('A square bay 31 m wide'), findsOneWidget);
    await openPanel(tester, 'space-assemble');
    await tester.ensureVisible(
      find.byKey(const ValueKey('space-step-pendentives')),
    );
    await tester.tap(find.byKey(const ValueKey('space-step-pendentives')));
    await tester.pumpAndSettle();
    expect(c.assembly, 3);
    expect(c.currentStep!.id, 'pendentives');
    final time = find.byKey(const ValueKey('space-time'));
    await tester.ensureVisible(time);
    await tester.tapAt(tester.getTopRight(time) + const Offset(-24, 24));
    await tester.pumpAndSettle();
    expect(c.epochYear, 1548);
    await closePanel(tester);
    expect(find.text('Şehzade Mosque, 1548'), findsOneWidget);
    expect(space(tester).ticking, isFalse, reason: 'cross-fade finished');
  });

  testWidgets('Section: off, other axes, and the handle drags the plane', (
    tester,
  ) async {
    await openStudy(tester);
    final c = space(tester).controller!;
    await openPanel(tester, 'space-section');
    await tester.tap(find.byKey(const ValueKey('space-cut-1')));
    await tester.pumpAndSettle();
    expect(c.sectionAxis, 1);
    await closePanel(tester);
    final before = c.sectionOffset;
    final handle = find.byKey(const ValueKey('space-section-handle'));
    expect(handle, findsOneWidget);
    final dir = space(tester).projector!.screenDirection(0, 1, 0);
    await tester.drag(handle, dir / dir.distance * 40);
    await tester.pump();
    expect(c.sectionOffset, greaterThan(before));
    await openPanel(tester, 'space-section');
    await tester.tap(find.byKey(const ValueKey('space-section-switch')));
    await tester.pumpAndSettle();
    expect(c.sectionPlane, isNull);
    await closePanel(tester);
    expect(handle, findsNothing);
    expect(space(tester).renderer!.stats.poche, 0);
  });

  testWidgets('Style: drawing, stone, night under lamp chrome; perspective', (
    tester,
  ) async {
    await openStudy(tester);
    final c = space(tester).controller!;
    await openPanel(tester, 'space-style');
    await tester.tap(find.byKey(const ValueKey('space-style-night')));
    await tester.pumpAndSettle();
    expect(c.style, SpaceStyle.night);
    await tester.tap(find.byKey(const ValueKey('space-perspective')));
    await tester.pumpAndSettle();
    expect(c.view.projection, SpaceProjection.perspective);
    await closePanel(tester);
    expect(
      Theme.of(tester.element(find.byKey(const ValueKey('space-viewport'))))
          .scaffoldBackgroundColor,
      const Color(0xFF151314),
    );
    expect(space(tester).renderer!.stats.edges, 0);
  });

  testWidgets('reduced motion: no play button, stills only, nothing ticks', (
    tester,
  ) async {
    await openStudy(tester, reduced: true);
    final player = space(tester), c = player.controller!;
    await openPanel(tester, 'space-assemble');
    expect(find.byKey(const ValueKey('space-play')), findsNothing);
    expect(find.byKey(const ValueKey('space-reveal')), findsNothing);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const ValueKey('space-next')));
      await tester.pump();
      expect(player.ticking, isFalse);
    }
    expect(c.sample!.beat.step.id, 'pendentives');
    expect(c.moment.assembly, 3, reason: 'a still, not a tween');
    await closePanel(tester);
    // TalkBack's custom action steps the same story.
    final node = tester.getSemantics(
      find.byKey(const ValueKey('space-viewport')),
    );
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      node.getSemanticsData().customSemanticsActionIds!.first,
    );
    await tester.pump();
    expect(c.sample!.beat.step.id, 'ring');
  });

  testWidgets('the reveal plays, then the player disposes cleanly', (
    tester,
  ) async {
    await openStudy(tester);
    final player = space(tester), c = player.controller!;
    await openPanel(tester, 'space-assemble');
    await tester.tap(find.byKey(const ValueKey('space-reveal')));
    await tester.pump();
    // A playing reveal is a clean shot: no section handle or outline.
    expect(c.playing, isTrue);
    expect(find.byKey(const ValueKey('space-section-handle')), findsNothing);
    await closePanel(tester);
    expect(c.reveal, isTrue);
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(c.playing, isFalse);
    expect(player.ticking, isFalse);
    expect(find.textContaining('how a 31 m dome stands'), findsOneWidget);
    expect(find.byKey(const ValueKey('space-section-handle')), findsOneWidget);
    final renderer = player.renderer!;
    await tester.pumpWidget(const SizedBox.shrink());
    expect(renderer.disposed, isTrue);
    expect(c.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Turkish: labels and captions are native', (tester) async {
    await openStudy(tester, locale: const Locale('tr'));
    expect(find.text('Ayasofya, 537'), findsOneWidget);
    expect(find.text('Kur'), findsOneWidget);
    expect(find.text('Kesit'), findsOneWidget);
    expect(find.text('Görünüm'), findsOneWidget);
    expect(find.text('Kubbe nasıl ayakta durur'), findsOneWidget);
  });
}
