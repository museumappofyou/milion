import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/screens/about_tab.dart';
import 'package:milion/screens/registry_screen.dart';

import 'frontier_navigation_test.dart' show ready;

void main() {
  testWidgets(
    'About version long-press opens the debug registry and language switch',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AboutTab()));
      await tester.scrollUntilVisible(
        find.byKey(const Key('about-version')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.longPress(find.byKey(const Key('about-version')));
      await ready(tester);
      expect(find.byType(RegistryScreen), findsOneWidget);
      expect(find.text('Registry'), findsOneWidget);
      expect(find.textContaining('155 places'), findsOneWidget);
      await tester.tap(find.text('TR'));
      await tester.pumpAndSettle();
      expect(find.text('İçerik kaydı'), findsOneWidget);
      expect(find.textContaining('0 mil · 0,0 km'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
