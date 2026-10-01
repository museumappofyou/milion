import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/main.dart';
import 'package:milion/shell/app_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> loadThemeFonts(WidgetTester tester) async =>
    tester.runAsync(() async {
      for (final (family, asset) in [
        ('Cinzel', 'assets/fonts/Cinzel.ttf'),
        ('NotoSans', 'assets/fonts/NotoSans.ttf'),
        ('NotoSerifDisplay', 'assets/fonts/NotoSerifDisplay.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        final loader = FontLoader(family)..addFont(rootBundle.load(asset));
        await loader.load();
      }
    });

/// Lets real asset I/O (content, images) finish without advancing fake time;
/// inside the app it also waits (up to 10 s) for the registry to arrive.
Future<void> waitForContent(WidgetTester tester) async {
  bool loading() {
    final scope = find.byType(AppScope, skipOffstage: false).evaluate();
    if (scope.isEmpty) return false;
    final app = scope.first.widget as AppScope;
    return app.registry == null && app.error == null;
  }

  await tester.runAsync(() async {
    for (var i = 0; i < 200 && (i < 24 || loading()); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  });
}

/// [waitForContent], then settles animations.
Future<void> ready(WidgetTester tester) async {
  await waitForContent(tester);
  await tester.pumpAndSettle();
}

Finder destination(String name) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(name));

/// The fixed date the P04 tests and captures are written against.
final p04Date = DateTime(2026, 10, 1, 9);

/// A fresh, file-backed repository per test: a cached load started in one
/// test's fake-async zone would never complete in the next.
MilionApp testApp({DateTime? date}) => MilionApp(
  clock: () => date ?? p04Date,
  content: ContentRepository((path) => File(path).readAsString()),
);

/// Opens the app past the first run, on a fixed date.
Future<void> pumpShell(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  DateTime? date,
  Size size = const Size(390, 844),
  GlobalKey? boundary,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'milion_first_run_seen': true,
    ...prefs,
  });
  await loadThemeFonts(tester);
  final app = testApp(date: date);
  await tester.pumpWidget(
    boundary == null ? app : RepaintBoundary(key: boundary, child: app),
  );
  await ready(tester);
}
