import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/city/dig_gauge.dart';
import 'package:milion/content/models.dart';

final strata = [
  for (final year in [2026, 1948, 1511])
    Stratum(
      'year-$year',
      year,
      null,
      Era.modern,
      const Localized(en: 'Layer', tr: 'Katman'),
      const Localized(en: 'One.\n\nTwo.', tr: 'Bir.\n\nİki.'),
      const [],
      const [],
      const [],
    ),
];

void main() {
  testWidgets('a cancelled drag clears the preview without committing', (
    tester,
  ) async {
    final commits = <int>[];
    int? preview;
    var cancelled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                height: 400,
                child: DigGauge(
                  strata: strata,
                  selected: 0,
                  displayYear: strata[preview ?? 0].gaugeYear,
                  onPreview: (index) => setState(() => preview = index),
                  onCommit: commits.add,
                  onCancel: () => setState(() {
                    preview = null;
                    cancelled = true;
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final rail = find.descendant(
      of: find.byType(DigGauge),
      matching: find.byType(GestureDetector),
    );
    final gesture = await tester.startGesture(tester.getCenter(rail));
    await gesture.moveBy(const Offset(0, 90));
    await tester.pump();
    expect(preview, isNotNull);
    await gesture.cancel();
    await tester.pump();
    expect(cancelled, isTrue);
    expect(preview, isNull);
    expect(commits, isEmpty);
    expect(tester.widget<DigGauge>(find.byType(DigGauge)).displayYear, 2026);
  });

  testWidgets('holding then dragging previews without moving the page', (
    tester,
  ) async {
    final commits = <int>[];
    final previews = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              height: 400,
              child: DigGauge(
                strata: strata,
                selected: 0,
                displayYear: 2026,
                onPreview: previews.add,
                onCommit: commits.add,
              ),
            ),
          ),
        ),
      ),
    );
    final rail = find.descendant(
      of: find.byType(DigGauge),
      matching: find.byType(GestureDetector),
    );
    final gesture = await tester.startGesture(tester.getCenter(rail));
    // A touch held past the tap-down deadline is still only a preview.
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();
    expect(previews, isNotEmpty);
    expect(commits, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(commits, [previews.last]);
  });
}
