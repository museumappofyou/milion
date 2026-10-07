import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/city/dig_gauge.dart';
import 'package:milion/city/dig_plate.dart';
import 'package:milion/city/visit_card.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/l10n/strings.dart';

import '../helpers.dart' show loadThemeFonts;

Widget frame(bool lamp, Widget child, {double width = 342}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: lamp ? DesignTheme.lamp : DesignTheme.marble,
  home: Scaffold(
    body: Center(
      child: RepaintBoundary(
        key: const Key('sample'),
        child: Builder(
          builder: (context) => ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  ),
);

Stratum stratumOf({
  required Era era,
  required Localized title,
  int fromYear = 1511,
  int? toYear = 1945,
  int? anchorYear = 1511,
}) => Stratum(
  'golden',
  fromYear,
  toYear,
  era,
  title,
  const Localized(en: 'One.\n\nTwo.'),
  const [],
  const [],
  const [],
  anchorYear: anchorYear,
);

void main() {
  for (final lamp in [false, true]) {
    final scheme = lamp ? 'lamp' : 'marble';
    testWidgets('$scheme dig gauge golden', (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await loadThemeFonts(tester);
      final strata = [
        for (final (from, anchor, era) in [
          (2020, 2026, Era.modern),
          (1945, 1948, Era.modern),
          (1511, 1511, Era.ottoman),
          (1315, 1321, Era.byzantine),
          (1077, 1077, Era.byzantine),
          (300, 330, Era.byzantine),
        ])
          stratumOf(
            era: era,
            title: const Localized(en: 'Layer'),
            fromYear: from,
            toYear: null,
            anchorYear: anchor,
          ),
      ];
      await tester.pumpWidget(
        frame(
          lamp,
          SizedBox(
            height: 400,
            child: Row(
              children: [
                Expanded(child: Container()),
                DigGauge(
                  strata: strata,
                  selected: 3,
                  displayYear: 1321,
                  onPreview: (_) {},
                  onCommit: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('sample')),
        matchesGoldenFile('../goldens/P05/$scheme-dig-gauge.png'),
      );
    });

    testWidgets('$scheme section diagram golden', (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await loadThemeFonts(tester);
      await tester.pumpWidget(
        frame(
          lamp,
          DigPlate(
            stratum: stratumOf(
              era: Era.ottoman,
              title: const Localized(en: 'Kariye Mosque'),
              anchorYear: 1511,
            ),
            media: null,
            height: 220,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('sample')),
        matchesGoldenFile('../goldens/P05/$scheme-section-diagram.png'),
      );
    });
  }

  testWidgets('marble visit card golden', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    final registry = (await tester.runAsync(
      () => ContentRepository((p) => File(p).readAsString()).load(),
    ))!;
    final chora = registry.place('chora')!;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        theme: DesignTheme.marble,
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: const Key('sample'),
              child: SizedBox(
                width: 342,
                child: SingleChildScrollView(
                  child: VisitCard(place: chora, registry: registry),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const Key('sample')),
      matchesGoldenFile('../goldens/P05/marble-visit-card.png'),
    );
  });
}
