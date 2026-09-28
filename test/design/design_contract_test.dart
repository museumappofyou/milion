import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/design/motion.dart';
import 'package:milion/design/settings.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/design/tokens.dart';
import 'package:milion/main.dart';
import 'package:milion/screens/about_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../frontier_navigation_test.dart'
    show loadThemeFonts, ready, destination;

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (max(x, y) + .05) / (min(x, y) + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('body, muted, action and collected text all exceed 4.5:1', () {
    for (final theme in [DesignTheme.marble, DesignTheme.lamp]) {
      final c = theme.extension<MeasureColors>()!, s = theme.colorScheme;
      for (final bg in [c.ground, c.poche]) {
        for (final fg in [c.ink, c.secondary, c.accent]) {
          expect(
            contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$fg on $bg',
          );
        }
      }
      for (final pair in [
        (s.primary, s.onPrimary),
        (s.error, s.onError),
        (Pigment.gold, Pigment.lamp),
        (Pigment.porphyry, Pigment.gold),
      ]) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
    }
  });
  test('Turkish inscription capitals preserve dotted and dotless i', () {
    expect(TypeRole.capitals('İstanbul ığüşöç i', 'tr'), 'İSTANBUL IĞÜŞÖÇ İ');
  });
  test('every ARB key and placeholder has a nonempty Turkish counterpart', () {
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    final tr =
        jsonDecode(File('lib/l10n/app_tr.arb').readAsStringSync()) as Map;
    expect(
      tr.keys.where((k) => !k.startsWith('@')).toSet(),
      en.keys.where((k) => !k.startsWith('@')).toSet(),
    );
    for (final key in en.keys.where((k) => !k.startsWith('@'))) {
      expect(tr[key], isA<String>());
      expect((tr[key] as String).trim(), isNotEmpty);
      Set<String> placeholders(String text) =>
          RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m[1]!).toSet();
      expect(placeholders(tr[key]), placeholders(en[key]), reason: key);
    }
  });
  test(
    'reduced motion is immediate; light detents and medium collection ticks',
    () async {
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
      for (final motion in MeasureMotion.values) {
        expect(MotionToken.duration(motion, reduced: true), Duration.zero);
        expect(
          MotionToken.duration(motion, reduced: false).inMilliseconds,
          inInclusiveRange(100, 600),
        );
      }
      await MotionToken.detent();
      await MotionToken.collect();
      await MotionToken.detent(enabled: false);
      expect(calls.map((c) => c.arguments), [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
      ]);
    },
  );
  test(
    'language and scheme persist, system-language reset survives restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = AppSettings();
      await first.load();
      await first.setLanguage('tr');
      await first.setScheme(ThemeMode.dark);
      final second = AppSettings();
      await second.load();
      expect(second.locale, const Locale('tr'));
      expect(second.themeMode, ThemeMode.dark);
      await second.setLanguage(null);
      final third = AppSettings();
      await third.load();
      expect(third.locale, isNull);
      first.dispose();
      second.dispose();
      third.dispose();
    },
  );
  testWidgets('About changes actual app language; hidden design route opens', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await loadThemeFonts(tester);
    await tester.pumpWidget(const MilionApp());
    await ready(tester);
    await tester.tap(destination('About'));
    await tester.pumpAndSettle();
    final language = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(language);
    await tester.tap(language);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Türkçe').last);
    await tester.pumpAndSettle();
    expect(find.text('Dil'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('milion_language'),
      'tr',
    );
    final about = find.byType(AboutTab);
    final scroll = find
        .descendant(of: about, matching: find.byType(Scrollable))
        .first;
    await tester.drag(scroll, const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('MİLİON'));
    await tester.pumpAndSettle();
    expect(find.text('Porfir ve Tessera'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
