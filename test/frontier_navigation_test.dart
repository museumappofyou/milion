import 'package:milion/main.dart';
import 'package:milion/screens/frontier_page.dart';
import 'package:milion/screens/scan_tab.dart';
import 'package:milion/screens/scenes_tab.dart';
import 'package:milion/screens/anastasis_relief_screen.dart';
import 'package:milion/screens/last_judgment_relief_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> loadThemeFonts(WidgetTester tester) async =>
    tester.runAsync(() async {
      for (final (family, asset) in [
        ('DMSans', 'assets/fonts/DMSans.ttf'),
        ('CormorantGaramond', 'assets/fonts/CormorantGaramond.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        final loader = FontLoader(family)..addFont(rootBundle.load(asset));
        await loader.load();
      }
    });

Future<void> ready(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 24; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  });
  await tester.pumpAndSettle();
}

Finder destination(String name) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('home and collection work without starting camera or inference', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    await tester.pumpWidget(const MilionApp());
    await ready(tester);
    expect(find.byType(FrontierPage), findsOneWidget);
    expect(find.byType(ScanTab), findsNothing);
    expect(find.text('Preparing the scanner'), findsNothing);

    await tester.tap(destination('Collection'));
    await ready(tester);
    expect(find.byType(ScenesTab), findsOneWidget);
    expect(find.text('103 scenes. Every wall has a story.'), findsOneWidget);
    await tester.tap(find.text('Interactive'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(2));
    await tester.enterText(find.byType(TextField), 'no matching fresco');
    await tester.pumpAndSettle();
    expect(find.text('No scenes found'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Interactive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('The Last Judgment'));
    await ready(tester);
    await tester.tap(find.text('Explore painted relief'));
    await ready(tester);
    expect(find.byType(LastJudgmentReliefScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('front page primary action opens Anastasis and returns home', (
    tester,
  ) async {
    await loadThemeFonts(tester);
    await tester.pumpWidget(const MilionApp());
    await ready(tester);
    await tester.tap(find.byKey(const ValueKey('frontier-enter')));
    await ready(tester);
    expect(find.byType(AnastasisReliefScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(FrontierPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
