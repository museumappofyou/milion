import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/design/design_sheet.dart';
import 'package:milion/design/plan_icon.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/l10n/strings.dart';

import '../frontier_navigation_test.dart' show loadThemeFonts;

void main() {
  for (final lamp in [false, true]) {
    for (final sample in [
      'milestone-numeral',
      'milestone-collected',
      'mil-distance',
      'honesty-original',
      'honesty-depth',
      'honesty-reconstruction',
      'honesty-imagined',
      'strata-band',
      'depth-gauge',
      'leader-line',
      ...PlanSymbol.values.map((s) => 'plan-${s.name}'),
      'scale-bar',
      'north-arrow',
      'tessera-loader',
      'tessera-chip',
      'empty',
      'error',
      'dimension-sheet',
    ]) {
      final name = '${lamp ? 'lamp' : 'marble'}-$sample';
      testWidgets('$name golden', (tester) async {
        tester.view.physicalSize = const Size(390, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await loadThemeFonts(tester);
        await tester.pumpWidget(
          MaterialApp(
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
                        child: SizedBox(
                          width: 342,
                          child: designSamples(context)[sample],
                        ),
                      ),
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
          matchesGoldenFile('../goldens/P03/$name.png'),
        );
      });
    }
  }
}
