import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

/// Taps a control in the dock, scrolling it into view first.
Future<void> tapControl(WidgetTester tester, String key) async {
  final control = find.byKey(ValueKey(key));
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
  await tester.tap(control);
}

/// Folds the docked panel away (or closes the Sources sheet).
Future<void> closePanel(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('space-dock-close')));
  await tester.pumpAndSettle();
}

void main() {
  // Playback ticks the controller every frame. Before 2026-11-09 the whole
  // viewport, its Semantics and the live caption rebuilt per frame, so
  // TalkBack got an update every frame of the reveal and assembly.
  testWidgets('with the Assemble sheet open, the reveal updates semantics '
      'when the slider moves a division, not every frame', (tester) async {
    final semantics = tester.ensureSemantics();
    await openStudy(tester);
    final c = space(tester).controller!;
    await openPanel(tester, 'space-assemble');
    final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
    var updates = 0, ticks = 0;
    final shown = <Object>{};
    void counted() => updates++;
    void watch() {
      ticks++;
      shown.add((
        (c.moment.assembly.clamp(0, c.steps.length) * 4).round(),
        c.caption,
        c.playing,
      ));
    }

    c.playReveal();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    owner.addListener(counted);
    c.addListener(watch);
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    owner.removeListener(counted);
    c.removeListener(watch);
    expect(ticks, greaterThan(100));
    expect(updates, lessThanOrEqualTo(shown.length + 2));
    expect(updates, lessThan(ticks ~/ 2));
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });

  testWidgets('a playing reveal paints every frame but updates semantics '
      'only when its caption changes', (tester) async {
    final semantics = tester.ensureSemantics();
    await openStudy(tester);
    final c = space(tester).controller!;
    final owner = tester.binding.renderViews.first.owner!.semanticsOwner!;
    var updates = 0, captions = 0, ticks = 0;
    void counted() => updates++;
    Object? lastCaption = c.caption;
    void watch() {
      ticks++;
      if (!identical(c.caption, lastCaption)) {
        lastCaption = c.caption;
        captions++;
      }
    }

    c.playReveal();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    owner.addListener(counted);
    c.addListener(watch);
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    owner.removeListener(counted);
    c.removeListener(watch);
    expect(ticks, greaterThan(100)); // the reveal animated every frame
    expect(updates, lessThanOrEqualTo(captions + 2));
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });

  // P12, IX on the A52s: the section handle's builder rebuilt on every tick
  // under the viewport's LayoutBuilder, which laid the page out again and
  // repainted all of it (app bar, buttons, caption) on every reveal frame.
  testWidgets('a playing reveal repaints only the drawing', (tester) async {
    await openStudy(tester);
    // Let the page's own transitions finish first.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    space(tester).controller!.playReveal();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    final painted = <Type>[];
    debugProfilePaintsEnabled = true;
    debugOnProfilePaint = (object) => painted.add(object.runtimeType);
    try {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    } finally {
      debugProfilePaintsEnabled = false;
      debugOnProfilePaint = null;
    }
    expect(painted, List.filled(6, RenderCustomPaint));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'opens on the drawing: RECONSTRUCTION, 537, whole from above, no autoplay',
    (tester) async {
      await openStudy(tester);
      final player = space(tester), c = player.controller!;
      expect(find.text('RECONSTRUCTION'), findsOneWidget);
      expect(find.text('Hagia Sophia, 537'), findsOneWidget);
      expect(find.byKey(const ValueKey('space-caption')), findsNothing);
      expect(player.ticking, isFalse);
      // The owner, 2026-11-16: not from underneath. Choisy's view is a
      // double-tap away.
      expect(c.view, c.overviewView);
      expect(c.view.elevation, greaterThan(0));
      expect(c.sectionPlane, isNull);
      expect(player.renderer!.stats.faces, greaterThan(0));
      expect(player.renderer!.stats.poche, 0, reason: 'no cut');
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

  testWidgets('a touch during the reveal keeps the camera where it turned', (
    tester,
  ) async {
    await openStudy(tester);
    final c = space(tester).controller!;
    c.playReveal();
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    final turned = c.visibleView.azimuth;
    expect((turned - c.choisyView.azimuth).abs(), greaterThan(.3));
    final finger = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('space-viewport'))) +
          const Offset(-80, 120),
    );
    await finger.moveBy(const Offset(20, 0));
    await tester.pump();
    await finger.moveBy(const Offset(1, 0));
    await tester.pump();
    await finger.up();
    await tester.pump();
    expect(c.playing, isFalse);
    // Before the fix the first drag frame jumped back by the reveal's turn.
    expect((c.view.azimuth - turned).abs(), lessThan(.1));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Assemble: steps with captions, scrubbing, the time scrubber', (
    tester,
  ) async {
    await openStudy(tester);
    final c = space(tester).controller!;
    await openPanel(tester, 'space-assemble');
    await tapControl(tester, 'space-next');
    await tester.pumpAndSettle();
    expect(c.sample!.beat.step.id, 'bay');
    await closePanel(tester);
    expect(find.textContaining('A square bay 31 m wide'), findsOneWidget);
    await openPanel(tester, 'space-assemble');
    await tapControl(tester, 'space-step-pendentives');
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

  testWidgets('Assemble docks under the drawing: + and − build while the '
      'drawing stays in view, and the element just added glows', (
    tester,
  ) async {
    // − and + must stay under the finger: a missed tap fails the test.
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    await openStudy(tester);
    final player = space(tester), c = player.controller!;
    final total = c.steps.length;
    await openPanel(tester, 'space-assemble');
    expect(player.openPanel, isNotNull);
    // The strip opens on the latest step built (on the A52s it opened on
    // the first two: a lazy list never built the last chip).
    final last = tester.getRect(
      find.byKey(ValueKey('space-step-${c.steps.last.id}')),
    );
    expect(last.left, greaterThanOrEqualTo(0));
    expect(last.right, lessThanOrEqualTo(390));
    // The drawing above the dock still answers a finger.
    final before = c.view.azimuth;
    await tester.drag(
      find.byKey(const ValueKey('space-viewport')),
      const Offset(-60, 0),
    );
    await tester.pump();
    expect(c.view.azimuth, isNot(before));
    expect(player.openPanel, isNotNull);

    await tester.tap(find.byKey(const ValueKey('space-build-less')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(player.ticking, isTrue, reason: 'the last step lifts away');
    await tester.pumpAndSettle();
    expect(c.assembly, total - 1);
    expect(find.text('${total - 1} of $total steps'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('space-build-more')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.assembly, inExclusiveRange(total - 1, total));
    expect(c.partStates().where((p) => p.highlight > 0), isNotEmpty);
    // The caption reads in the dock, not over the drawing.
    expect(find.byKey(const ValueKey('space-caption')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(c.assembly, total);
    expect(c.partStates().where((p) => p.highlight > 0), isEmpty);
    expect(player.ticking, isFalse);
    await tester.tap(find.byKey(const ValueKey('space-build-more')));
    await tester.pump();
    expect(c.assemblyTarget, total, reason: 'nothing more to add');

    // Building from nothing: the first chip builds one step.
    for (var i = 0; i < total; i++) {
      await tester.tap(find.byKey(const ValueKey('space-build-less')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(c.assembly, 0);
    expect(
      find.text('Nothing built yet: add the first element.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(ValueKey('space-step-${c.steps.first.id}')));
    await tester.pumpAndSettle();
    expect(c.assembly, 1);
    await closePanel(tester);
    expect(player.openPanel, isNull);
  });

  testWidgets('a plan cut chosen from above turns to Choisy\'s view', (
    tester,
  ) async {
    await openStudy(tester);
    final c = space(tester).controller!;
    await openPanel(tester, 'space-section');
    await tapControl(tester, 'space-cut-2');
    await tester.pumpAndSettle();
    expect(c.sectionPlane?.axis, 2);
    expect(c.view, c.choisyView);
    expect(space(tester).renderer!.stats.poche, greaterThan(0));
    await openPanel(tester, 'space-style');
    await tapControl(tester, 'space-overview');
    await tester.pumpAndSettle();
    expect(c.view, c.overviewView);
    expect(c.sectionPlane, isNull, reason: 'a plan cut reads only from below');
  });

  testWidgets('Section: off, other axes, and the handle drags the plane', (
    tester,
  ) async {
    await openStudy(tester);
    final c = space(tester).controller!;
    await openPanel(tester, 'space-section');
    await tapControl(tester, 'space-cut-1');
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
    await tapControl(tester, 'space-section-switch');
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
    await tapControl(tester, 'space-style-night');
    await tester.pumpAndSettle();
    expect(c.style, SpaceStyle.night);
    await tapControl(tester, 'space-perspective');
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
      await tapControl(tester, 'space-next');
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
    await tapControl(tester, 'space-reveal');
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
