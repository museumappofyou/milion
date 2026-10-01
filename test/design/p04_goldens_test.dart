import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/geography.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/design/components.dart';
import 'package:milion/design/design_sheet.dart';
import 'package:milion/design/plan_icon.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/first_run/first_run_painter.dart';
import 'package:milion/first_run/first_run_screen.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/today/mile_zero_dial.dart';

import '../helpers.dart' show loadThemeFonts;

Widget frame(
  bool lamp,
  Widget Function(BuildContext) child, {
  double width = 342,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('tr'),
  theme: lamp ? DesignTheme.lamp : DesignTheme.marble,
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: RepaintBoundary(
          key: const Key('sample'),
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(width: width, child: child(context)),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  final samples = [
    ...PlanSymbol.values.skip(13).map((s) => 'plan-${s.name}'),
    for (final state in SlotState.values) 'tessera-slot-${state.name}',
    'flagship',
    'honesty-range',
  ];
  for (final lamp in [false, true]) {
    for (final sample in samples) {
      final name = '${lamp ? 'lamp' : 'marble'}-$sample';
      testWidgets('$name golden', (tester) async {
        tester.view.physicalSize = const Size(390, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await loadThemeFonts(tester);
        await tester.pumpWidget(
          frame(lamp, (context) => designSamples(context)[sample]!),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const Key('sample')),
          matchesGoldenFile('../goldens/P04/$name.png'),
        );
      });
    }
    testWidgets('${lamp ? 'lamp' : 'marble'}-dial golden', (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await loadThemeFonts(tester);
      final registry = (await tester.runAsync(
        () => ContentRepository((p) => File(p).readAsString()).load(),
      ))!;
      final places = dialPlaces(registry.plottablePlaces);
      final chora = places.indexWhere((p) => p.place.id == 'chora');
      await tester.pumpWidget(
        frame(
          lamp,
          (_) => SizedBox.square(
            dimension: 342,
            child: MileZeroDial(
              places: places,
              selected: chora,
              onSelected: (_) {},
              onOpen: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const Key('sample')),
        matchesGoldenFile(
          '../goldens/P04/${lamp ? 'lamp' : 'marble'}-dial.png',
        ),
      );
    });
  }
  // The reduced-motion equivalent of Milestone 0 lite: three stills.
  for (final (i, t) in FirstRunScreen.stills.indexed) {
    testWidgets('first-run still ${i + 1} golden', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await loadThemeFonts(tester);
      final registry = (await tester.runAsync(
        () => ContentRepository((p) => File(p).readAsString()).load(),
      ))!;
      final places = [
        for (final (id, left, below) in firstRunPlaces)
          LitPlace(
            registry.place(id)!.names.en,
            formatMilDistance(fromMilion(registry.place(id)!).km),
            metresFromMilion(registry.place(id)!.coordinates),
            left: left,
            below: below,
          ),
      ];
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('sample'),
          child: CustomPaint(
            size: const Size(390, 844),
            painter: FirstRunPainter(
              t: t,
              line: 'Every road started here.',
              stone: 'MILION',
              street: 'Divanyolu, beside the Basilica Cistern',
              coordinates: '41.008043° N · 28.978066° E',
              places: places,
              scaler: TextScaler.noScaling,
              still: true,
            ),
          ),
        ),
      );
      await expectLater(
        find.byKey(const Key('sample')),
        matchesGoldenFile('../goldens/P04/first-run-still-${i + 1}.png'),
      );
    });
  }
}
