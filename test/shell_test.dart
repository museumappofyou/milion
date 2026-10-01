import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/city/city_tab.dart';
import 'package:milion/city/place_screen.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/design/plan_icon.dart';
import 'package:milion/first_run/first_run_screen.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/mosaic/mosaic_tab.dart';
import 'package:milion/screens/about_tab.dart';
import 'package:milion/screens/scan_screen.dart';
import 'package:milion/screens/scan_tab.dart';
import 'package:milion/screens/scene_explorer_screen.dart';
import 'package:milion/screens/scenes_tab.dart';
import 'package:milion/shell/app_shell.dart';
import 'package:milion/today/detail_crop.dart';
import 'package:milion/today/mile_zero_dial.dart';
import 'package:milion/today/today_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'scene_explorer_test.dart' show assetsReady;

/// Records platform calls: haptics and SystemNavigator.pop.
List<MethodCall> recordPlatform() {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}

Future<void> firstLaunch(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await loadThemeFonts(tester);
  await tester.pumpWidget(testApp());
  await tester.runAsync(() async {
    for (
      var i = 0;
      i < 40 && find.byType(FirstRunScreen).evaluate().isEmpty;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  });
  // Let the registry arrive so the five places can light up.
  await waitForContent(tester);
}

AppShellState shell(WidgetTester tester) =>
    tester.state<AppShellState>(find.byType(AppShell));

ScrollPosition scrollOf(WidgetTester tester, Type page) => tester
    .state<ScrollableState>(
      find
          .descendant(of: find.byType(page), matching: find.byType(Scrollable))
          .first,
    )
    .position;

void main() {
  late ContentRegistry registry;
  setUpAll(() async {
    registry = await ContentRepository((p) => File(p).readAsString()).load();
  });

  group('first run (Milestone 0 lite)', () {
    testWidgets(
      'plays once, Skip only after 2 s, lands on Today, then never again',
      (tester) async {
        await firstLaunch(tester);
        expect(find.byType(FirstRunScreen), findsOneWidget);
        expect(find.byType(AppShell), findsNothing);
        IgnorePointer gate() => tester.widget<IgnorePointer>(
          find
              .ancestor(
                of: find.byKey(const ValueKey('first-run-skip')),
                matching: find.byType(IgnorePointer),
              )
              .first,
        );
        await tester.pump(const Duration(seconds: 1));
        expect(gate().ignoring, isTrue);
        await tester.pump(const Duration(milliseconds: 1100));
        expect(gate().ignoring, isFalse);
        await tester.tap(find.byKey(const ValueKey('first-run-skip')));
        await tester.pumpAndSettle();
        expect(find.byType(TodayScreen), findsOneWidget);
        expect(
          (await SharedPreferences.getInstance()).getBool(
            'milion_first_run_seen',
          ),
          isTrue,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(testApp());
        await ready(tester);
        expect(find.byType(FirstRunScreen), findsNothing);
        expect(find.byType(TodayScreen), findsOneWidget);
        // Nothing on the way asked for the camera or loaded the classifier.
        expect(find.byType(ScanTab), findsNothing);
        expect(find.byType(ScanScreen), findsNothing);
      },
    );

    testWidgets('the 12-second sequence ends on Today by itself', (
      tester,
    ) async {
      await firstLaunch(tester);
      final state = tester.state<FirstRunScreenState>(
        find.byType(FirstRunScreen),
      );
      expect(state.mode, FirstRunMode.animated);
      await tester.pump(const Duration(seconds: 6));
      expect(find.byType(FirstRunScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 6, milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('reduced motion shows three stills, advanced by hand', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await firstLaunch(tester);
      final state = tester.state<FirstRunScreenState>(
        find.byType(FirstRunScreen),
      );
      expect(state.mode, FirstRunMode.stills);
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('first-run-still-$i')), findsOneWidget);
        expect(state.clock.isAnimating, isFalse);
        await tester.pump(const Duration(seconds: 5));
        expect(
          find.byKey(ValueKey('first-run-still-$i')),
          findsOneWidget,
          reason: 'no auto-advance',
        );
        await tester.tap(find.byKey(const ValueKey('first-run-next')));
        await tester.pumpAndSettle();
      }
      expect(find.byType(TodayScreen), findsOneWidget);
    });

    testWidgets('TalkBack reads one sentence, then Open Today', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final semantics = tester.ensureSemantics();
      await firstLaunch(tester);
      final state = tester.state<FirstRunScreenState>(
        find.byType(FirstRunScreen),
      );
      expect(state.mode, FirstRunMode.spoken);
      final sentence = lookupAppLocalizations(const Locale('en'))
          .firstRunSentence;
      expect(find.bySemanticsLabel(sentence), findsOneWidget);
      expect(
        sentence
            .split(RegExp(r'[.!?](\s|$)'))
            .where((s) => s.isNotEmpty)
            .length,
        1,
      );
      await tester.tap(find.byKey(const ValueKey('first-run-continue')));
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a screen reader arriving mid-sequence stays spoken', (
      tester,
    ) async {
      await firstLaunch(tester);
      final state = tester.state<FirstRunScreenState>(
        find.byType(FirstRunScreen),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(state.mode, FirstRunMode.animated);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      await tester.pump();
      expect(state.mode, FirstRunMode.spoken);
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await tester.pump(const Duration(seconds: 12));
      expect(state.mode, FirstRunMode.spoken, reason: 'no flip back to motion');
      expect(state.clock.isAnimating, isFalse);
      expect(find.byType(FirstRunScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('first-run-continue')), findsOneWidget);
    });

    testWidgets('About replays the sequence without resetting the flag', (
      tester,
    ) async {
      await pumpShell(tester);
      await tester.tap(find.byTooltip('About'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('about-replay')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('about-replay')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(FirstRunScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 2, milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('first-run-skip')));
      await tester.pumpAndSettle();
      expect(find.byType(AboutTab), findsOneWidget);
      expect(find.byType(FirstRunScreen), findsNothing);
    });
  });

  group('Today', () {
    testWidgets(
      'the date’s detail, numeral and label; tap flies to that detail',
      (tester) async {
        await pumpShell(tester);
        final detail = detailOfDay(registry, p04Date);
        final milestone = registry.milestone(detail.milestoneId)!;
        expect(find.text(detail.sentence.en), findsOneWidget);
        expect(find.text(milestone.numeral), findsWidgets);
        expect(find.text('ORIGINAL'), findsWidgets);
        await tester.tap(find.byKey(const ValueKey('detail-of-day')));
        await tester.pump();
        await tester.pump();
        Finder landing() => find.descendant(
          of: find.byType(SceneExplorerScreen),
          matching: find.byWidgetPredicate(
            (w) => w is Hero && w.tag == detailHeroTag(detail),
          ),
        );
        expect(
          landing(),
          findsOneWidget,
          reason: 'shared element lands in the Milestone',
        );
        await assetsReady(tester);
        final explorer = tester.state<SceneExplorerScreenState>(
          find.byType(SceneExplorerScreen),
        );
        expect(
          explorer.zoom,
          greaterThan(1.5),
          reason: 'opens at the detail, not the overview',
        );
        expect(find.text(detail.sentence.en), findsOneWidget);
        expect(
          landing(),
          findsNothing,
          reason: 'the plate takes over after landing',
        );
        expect(
          (await SharedPreferences.getInstance()).getStringList(
            'milion_opened_milestones',
          ),
          [milestone.id],
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(TodayScreen), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('1 of 48 Milestones opened'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
      },
    );

    testWidgets('a different day shows a different detail', (tester) async {
      await pumpShell(tester, date: DateTime(2026, 10, 2));
      expect(
        find.text(detailOfDay(registry, DateTime(2026, 10, 2)).sentence.en),
        findsOneWidget,
      );
      expect(
        find.text(detailOfDay(registry, p04Date).sentence.en),
        findsNothing,
      );
    });

    testWidgets(
      'dial: a thumb turn detents with light haptics; TalkBack steps; tap opens',
      (tester) async {
        final calls = recordPlatform();
        final semantics = tester.ensureSemantics();
        await pumpShell(tester);
        final dial = find.byKey(const ValueKey('mile-zero-dial'));
        await tester.scrollUntilVisible(
          dial,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(dial);
        await tester.pumpAndSettle();
        final state = tester.state<MileZeroDialState>(dial);
        final before = state.widget.selected;
        expect(
          state.widget.places[before].place.id,
          'chora',
          reason: 'starts on today’s place',
        );
        // Turn along the right-hand side of the ring: tangential, so it rotates.
        final box = tester.getRect(dial);
        final gesture = await tester.startGesture(
          box.center + Offset(box.width * .38, -box.height * .1),
        );
        for (var i = 0; i < 12; i++) {
          await gesture.moveBy(const Offset(-2, 12));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pumpAndSettle();
        expect(state.widget.selected, isNot(before));
        expect(
          calls.where((c) => c.arguments == 'HapticFeedbackType.lightImpact'),
          isNotEmpty,
        );
        // A radial drag through the centre scrolls the page instead.
        final position = scrollOf(tester, TodayScreen).pixels;
        final turned = state.widget.selected;
        await tester.dragFrom(
          box.center + Offset(0, box.height * .3),
          const Offset(0, -150),
        );
        await tester.pumpAndSettle();
        expect(scrollOf(tester, TodayScreen).pixels, greaterThan(position));
        expect(state.widget.selected, turned);
        // TalkBack: increase moves exactly one place clockwise.
        final node = tester.getSemantics(dial);
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.increase),
          isTrue,
        );
        tester.semantics.performAction(
          find.semantics.byLabel('Mile Zero dial'),
          SemanticsAction.increase,
        );
        await tester.pumpAndSettle();
        expect(
          state.widget.selected,
          (turned + 1) % state.widget.places.length,
        );
        tester.semantics.performAction(
          find.semantics.byLabel('Mile Zero dial'),
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();
        expect(find.byType(PlaceScreen), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('list alternative, mosaic strip and the current chapter', (
      tester,
    ) async {
      await pumpShell(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('dial-toggle')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('dial-toggle')));
      await tester.pumpAndSettle();
      final count = dialPlaces(registry.plottablePlaces).length;
      expect(
        find.text('$count places by bearing from true north'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('308°'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('dial-toggle')),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('dial-toggle')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('mosaic-strip')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('0 of 48 Milestones opened'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('CHAPTER I · BYZANTINE'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('2 of 23 playable · 0 approved'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('mosaic-strip')));
      await tester.pumpAndSettle();
      expect(shell(tester).current, Destination.mosaic);
    });
  });

  group('shell', () {
    testWidgets('four PlanIcon destinations and no Scan tab', (tester) async {
      await pumpShell(tester);
      final destinations = tester.widgetList<NavigationDestination>(
        find.byType(NavigationDestination),
      );
      expect(destinations.map((d) => d.label), [
        'Today',
        'City',
        'Milestones',
        'Mosaic',
      ]);
      expect(destinations.every((d) => d.icon is PlanIcon), isTrue);
      expect(destination('Scan'), findsNothing);
    });

    testWidgets(
      'back on a tab returns to Today; back on Today leaves the app',
      (tester) async {
        final calls = recordPlatform();
        await pumpShell(tester);
        await tester.tap(destination('City'));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(shell(tester).current, Destination.today);
        expect(calls.where((c) => c.method == 'SystemNavigator.pop'), isEmpty);
        await tester.tap(find.byTooltip('About'));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(AboutTab), findsNothing);
        expect(calls.where((c) => c.method == 'SystemNavigator.pop'), isEmpty);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(
          calls.where((c) => c.method == 'SystemNavigator.pop'),
          hasLength(1),
        );
      },
    );

    testWidgets('tab and scroll state survive switching and process death', (
      tester,
    ) async {
      await pumpShell(tester);
      await tester.tap(destination('City'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -900));
      await tester.pumpAndSettle();
      final offset = scrollOf(tester, CityTab).pixels;
      expect(offset, greaterThan(0));
      await tester.tap(destination('Today'));
      await tester.pumpAndSettle();
      await tester.tap(destination('City'));
      await tester.pumpAndSettle();
      expect(scrollOf(tester, CityTab).pixels, offset);
      await tester.restartAndRestore();
      await ready(tester);
      expect(shell(tester).current, Destination.city);
      expect(scrollOf(tester, CityTab).pixels, offset);
    });

    testWidgets(
      'register: outlined planned slots, planned sheet, playable opens',
      (tester) async {
        await pumpShell(tester);
        await tester.tap(destination('Milestones'));
        await tester.pumpAndSettle();
        expect(
          find.text('48 Milestones · 2 playable · 0 approved · 46 planned'),
          findsOneWidget,
        );
        final last = find.byKey(const ValueKey('milestone-XLVII'));
        await tester.scrollUntilVisible(
          last,
          500,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(last);
        await tester.pumpAndSettle();
        expect(find.textContaining('Planned: its reveal'), findsOneWidget);
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
        final first = find.byKey(const ValueKey('milestone-I'));
        await tester.scrollUntilVisible(
          first,
          -500,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(first);
        await assetsReady(tester);
        expect(find.byType(SceneExplorerScreen), findsOneWidget);
      },
    );

    testWidgets(
      'City by mil distance; camera-eye only where recognition exists',
      (tester) async {
        await pumpShell(tester);
        await tester.tap(destination('City'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            'places · positions checked on Wikidata · 0 reviewed',
          ),
          findsOneWidget,
        );
        final chora = find.text('Kariye Mosque (Chora)');
        await tester.scrollUntilVisible(
          chora,
          400,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(chora);
        await tester.pumpAndSettle();
        expect(find.byType(PlaceScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('place-camera-eye')), findsOneWidget);
        expect(find.text('Not reviewed yet'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('place-artworks')));
        await tester.pumpAndSettle();
        expect(find.byType(ScenesTab), findsOneWidget);
        expect(find.text('103 artworks · Chora / Kariye'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        final sophia = find.text('Hagia Sophia Mosque');
        await tester.scrollUntilVisible(
          sophia,
          -400,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(sophia);
        await tester.pumpAndSettle();
        expect(find.byType(PlaceScreen), findsOneWidget);
        expect(find.byKey(const ValueKey('place-camera-eye')), findsNothing);
      },
    );

    testWidgets('Mosaic shows saved notes until P19', (tester) async {
      await pumpShell(
        tester,
        prefs: {
          'scene_note_F02': 'Wrist, not hand.',
          'scene_notes_schema_version': 1,
        },
      );
      await tester.tap(destination('Mosaic'));
      await ready(tester);
      expect(find.byType(MosaicTab), findsOneWidget);
      expect(find.text('Wrist, not hand.'), findsOneWidget);
      expect(find.text('1 notes on Chora artworks'), findsOneWidget);
    });

    for (final language in ['en', 'tr']) {
      testWidgets('layout holds at 200% text, 360 dp, $language', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpShell(
          tester,
          size: const Size(360, 780),
          prefs: {'milion_language': language},
        );
        final labels = language == 'en'
            ? ['Today', 'City', 'Milestones', 'Mosaic']
            : ['Bugün', 'Şehir', 'Taşlar', 'Mozaik'];
        for (final label in labels) {
          await tester.tap(destination(label));
          await ready(tester);
          final scrollable = find.byType(Scrollable).last;
          for (var i = 0; i < 8; i++) {
            await tester.drag(
              scrollable,
              const Offset(0, -500),
              warnIfMissed: false,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$label scroll $i');
          }
        }
      });
    }
  });
}
