import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/guide/guide_screen.dart';
import 'package:milion/guide/plan_view.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/widgets/artwork_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'p11_fixture.dart';

/// The fixture with a second artwork and a two-stop cycle.
ContentRegistry _registry() {
  final data = p11Fixture();
  final art = Map<String, dynamic>.of(
    (data['artworks'] as List).single as Map<String, dynamic>,
  )..['id'] = 'F03';
  (data['artworks'] as List).add(art);
  final g = (data['guides'] as List).single as Map<String, dynamic>;
  (g['anchors'] as Map)['F03'] = {
    'room': 'naos',
    'at': [5, 12],
  };
  g['cycles'] = [
    {
      'id': 'walk',
      'title': {'en': 'The walk', 'tr': 'Yürüyüş'},
      'intro': {'en': 'Two stops.', 'tr': 'İki durak.'},
      'artworks': ['F02', 'F03'],
      'sources': g['sources'],
    },
  ];
  return ContentRegistry.fromJson(data);
}

Future<ContentRegistry> _pump(
  WidgetTester tester, {
  String? focus,
  Rect? flyFrom,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final registry = _registry();
  await tester.pumpWidget(
    MaterialApp(
      theme: DesignTheme.marble,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: GuideScreen(
        place: registry.place('chora')!,
        guide: registry.guideFor('chora')!,
        registry: registry,
        focus: focus,
        flyFrom: flyFrom,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return registry;
}

void main() {
  testWidgets('a room filters the list; a tessera opens its artwork', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byKey(const ValueKey('guide-artwork-F02')), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-artwork-F03')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('guide-room-naos')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guide-room-naos')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guide-artwork-F02')), findsNothing);
    expect(find.byKey(const ValueKey('guide-artwork-F03')), findsOneWidget);

    // Tap F02's tessera on the plan.
    final plan = find.byKey(const ValueKey('guide-plan'));
    final box = tester.renderObject<RenderBox>(plan);
    final registry = _registry();
    final frame = PlanFrame(registry.guideFor('chora')!, box.size);
    final at = frame.toScreen(registry.guideFor('chora')!.anchors['F02']!.at);
    await tester.tapAt(box.localToGlobal(at));
    await tester.pumpAndSettle();
    expect(find.byType(ArtworkSheet), findsOneWidget);
    expect(find.text('Three things to look for'), findsOneWidget);
    expect(find.text('Adam’s wrist.'), findsOneWidget);
    expect(find.text('Η ΑΝΑϹΤΑϹΙϹ'), findsOneWidget);
    expect(find.text('Read from a credited photograph'), findsOneWidget);
  });

  testWidgets('a cycle walks stop to stop, and "you" moves between them', (
    tester,
  ) async {
    await _pump(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('guide-cycle-walk')));
    await tester.tap(find.byKey(const ValueKey('guide-cycle-walk')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Stop 1 of 2'), findsOneWidget);
    PlanPainter painter() =>
        tester
                .widget<CustomPaint>(find.byKey(const ValueKey('guide-plan')))
                .painter!
            as PlanPainter;
    expect(painter().state.path, hasLength(2));
    final start = painter().state.you!;
    await tester.ensureVisible(find.byKey(const ValueKey('cycle-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cycle-next')));
    await tester.pump(); // the walk's first frame
    await tester.pump(const Duration(milliseconds: 450));
    final middle = painter().state.you!;
    // Under way from F02 (9, 2) to F03 (5, 12).
    expect(middle.x, inExclusiveRange(5, start.x));
    expect(middle.y, inExclusiveRange(start.y, 12));
    await tester.pumpAndSettle();
    expect(find.textContaining('Stop 2 of 2'), findsOneWidget);
    expect(painter().state.you!.y, 12);
    expect(painter().state.focus, 'F03');
    await tester.ensureVisible(find.byKey(const ValueKey('cycle-end')));
    await tester.tap(find.byKey(const ValueKey('cycle-end')));
    await tester.pumpAndSettle();
    expect(painter().state.you, isNull);
  });

  testWidgets('a camera find flies to its tessera and opens', (tester) async {
    await _pump(
      tester,
      focus: 'F02',
      flyFrom: const Rect.fromLTWH(85, 300, 220, 220),
    );
    expect(find.byType(ArtworkSheet), findsOneWidget);
    expect(find.textContaining('Found by the camera'), findsOneWidget);
  });

  testWidgets('the hunt lists its finds and reveals answers', (tester) async {
    await _pump(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('guide-hunt')));
    await tester.tap(find.byKey(const ValueKey('guide-hunt')));
    await tester.pumpAndSettle();
    expect(find.text('Look at the hands.'), findsOneWidget);
    expect(find.text('Wrists, not hands.'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('hunt-answer-0')));
    await tester.pumpAndSettle();
    expect(find.text('Wrists, not hands.'), findsOneWidget);
  });
}
