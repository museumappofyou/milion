import 'package:milion/screens/anastasis_tab.dart';
import 'package:milion/widgets/anastasis_dome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test for the artifact tab: it loads the prepared assets, renders the
/// 2.5D viewer, and the controls and hotspot sheets work.
Future<void> _pumpTab(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(const MaterialApp(home: AnastasisTab()));
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
      if (find.text('The Anastasis on its semi-dome').evaluate().isNotEmpty) {
        break;
      }
    }
  });
  await tester.pump();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

void main() {
  testWidgets('loads the artifact and exposes its sections', (tester) async {
    await _pumpTab(tester);

    expect(find.text('The Anastasis on its semi-dome'), findsOneWidget);
    expect(find.text('EXAMINABLE ARTIFACT'), findsOneWidget);
    expect(find.text('Explore painted relief'), findsOneWidget);

    expect(find.byType(Slider), findsNothing);

    await _scrollTo(tester, find.text('Anchor points'));
    expect(find.text('Anchor points'), findsOneWidget);

    await _scrollTo(tester, find.text('Conch reference capture'));
    expect(find.textContaining('Source captures'), findsOneWidget);
    expect(find.text('Conch reference capture'), findsOneWidget);

    await _scrollTo(tester, find.text('Provenance and method'));
    expect(find.textContaining('single-view shallow relief'), findsOneWidget);
    expect(find.textContaining('Caner Cangül'), findsWidgets);
  });

  testWidgets('hotspot chips open their interpretation and capture', (
    tester,
  ) async {
    await _pumpTab(tester);
    await _scrollTo(tester, find.text('Anchor points'));

    await tester.tap(find.text('Christ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('rayed mandorla'), findsOneWidget);

    await tester.tap(find.text('Open capture'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Christ in the mandorla'), findsWidgets);
    expect(find.textContaining('Reference capture'), findsWidgets);
  });

  testWidgets('technical viewer loads only after a title long press', (
    tester,
  ) async {
    await _pumpTab(tester);
    expect(find.byType(AnastasisDomeView), findsNothing);

    await tester.longPress(find.text('Anastasis'));
    await tester.runAsync(() async {
      for (var i = 0; i < 70; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
        if (find.byType(AnastasisDomeView).evaluate().isNotEmpty) break;
      }
    });
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.byType(AnastasisDomeView), findsOneWidget);
  });
}
