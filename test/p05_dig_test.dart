import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/city/dig_gauge.dart';
import 'package:milion/city/dig_plate.dart';
import 'package:milion/city/visit_card.dart';
import 'package:milion/city/external_links.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';

import 'helpers.dart';

Future<ContentRegistry> loadRegistry() =>
    ContentRepository((p) => File(p).readAsString()).load();

Era eraFor(String name) => Era.values.byName(name);

void main() {
  group('P05 dig content', () {
    late ContentRegistry registry;
    setUpAll(() async => registry = await loadRegistry());

    test('Chora has six sourced layers, newest to oldest', () {
      final chora = registry.place('chora')!;
      expect(chora.strata.map((s) => s.id), [
        'kariye-mosque-today',
        'museum-years',
        'kariye-mosque-1511',
        'metochites',
        'komnenian',
        'first-monastery',
      ]);
      expect(chora.strata.map((s) => s.gaugeYear), [
        2026,
        1948,
        1511,
        1321,
        1077,
        330,
      ]);
      for (final stratum in chora.strata) {
        for (final language in ['en', 'tr']) {
          final paragraphs = stratum.paragraphs(language);
          expect(paragraphs.length, inInclusiveRange(2, 4), reason: stratum.id);
          for (final paragraph in paragraphs) {
            expect(paragraph.trim(), isNotEmpty, reason: stratum.id);
          }
        }
        expect(stratum.sourceIds, isNotEmpty, reason: stratum.id);
        for (final source in stratum.sourceIds) {
          expect(
            registry.source(source),
            isNotNull,
            reason: '$stratum: $source',
          );
        }
      }
      // The Metochites layer is the entry point of the Chora Milestones.
      final metochites = chora.strata[3];
      expect(registry.milestonesIn(metochites).map((m) => m.numeral), [
        'I',
        'II',
        'III',
        'IV',
        'V',
      ]);
      expect(registry.artworksIn(metochites).first.id, 'F02');
      expect(
        registry.artworksIn(metochites).map((a) => a.id),
        containsAll(['F02', 'F05']),
      );
      // The Komnenian walls and the fourteenth-century decoration are
      // separate building campaigns (Ousterhout, Introduction pp. 1–4).
      expect(
        registry.artworksIn(metochites).map((a) => a.id),
        containsAll(['M01', 'M02', 'M03', 'M12']),
      );
      expect(registry.artworksIn(chora.strata[4]), isEmpty);
      // Milestones only enter a layer through its own artworks.
      expect(registry.milestonesIn(chora.strata[0]), isEmpty);
    });

    test('the Hagia Sophia draft page is two JSON layers only', () {
      final hagia = registry.place('hagia-sophia')!;
      expect(hagia.strata.map((s) => s.id), [
        'mosque-after-1453',
        'justinian-church',
      ]);
      for (final stratum in hagia.strata) {
        expect(stratum.paragraphs('en').length, inInclusiveRange(2, 4));
        expect(stratum.paragraphs('tr').length, inInclusiveRange(2, 4));
        expect(stratum.artworkIds, isEmpty);
        expect(stratum.mediaIds, isEmpty);
        expect(stratum.sourceIds, isNotEmpty);
      }
    });

    test('the visit card is remotely checked and cited', () {
      final visit = registry.place('chora')!.visit!;
      expect(visit.checkedAt, DateTime(2026, 10, 8));
      expect(visit.hoursCheckedAt, DateTime(2026, 10, 8));
      expect(visit.hours!.en, startsWith('Daily except Friday'));
      expect(visit.hours!.tr, startsWith('Cuma hariç her gün'));
      expect(visit.hours!.tr, isNotEmpty);
      expect(visit.entry!.tr, isNotEmpty);
      expect(visit.etiquette!.tr, isNotEmpty);
      expect(visit.transit.map((t) => t.kind), contains(TransitKind.tram));
      expect(visit.transit.map((t) => t.kind), contains(TransitKind.metrobus));
      for (final stop in visit.transit) {
        expect(stop.minutes, inInclusiveRange(1, 60));
        expect(stop.stop.tr, isNotEmpty);
      }
      for (final source in visit.sourceIds) {
        expect(registry.source(source), isNotNull);
      }
      // Every other place carries no visit card yet; nothing was invented.
      expect(registry.places.where((p) => p.visit != null).map((p) => p.id), [
        'chora',
      ]);
      // Accessibility is honestly absent for Chora and renders unverified.
      expect(visit.accessibility, isNull);
    });

    test('dig copy passes the §2 filler-word rule', () {
      final banned = RegExp(
        r'discover|journey|timeless|step into|magic|hidden gem|rich history|beyond the surface',
        caseSensitive: false,
      );
      for (final place in registry.places) {
        for (final stratum in place.strata) {
          expect(
            banned.hasMatch(stratum.title.en),
            isFalse,
            reason: stratum.id,
          );
          expect(banned.hasMatch(stratum.body.en), isFalse, reason: stratum.id);
          expect(
            banned.hasMatch(stratum.title.tr ?? ''),
            isFalse,
            reason: stratum.id,
          );
          expect(
            banned.hasMatch(stratum.body.tr ?? ''),
            isFalse,
            reason: stratum.id,
          );
        }
      }
    });

    test('P05 facts entered the Daily and On-this-day pools', () {
      final seeds = File('tool/content/editorial_seeds.json')
          .readAsStringSync();
      for (final id in [
        'p05-wrist',
        'p05-metochites-hat',
        'p05-curtains',
        'p05-reopening',
        'p05-decree',
        'p05-opening-postponed',
      ]) {
        expect(seeds, contains(id));
      }
    });

    test('the postponed opening is not published as a completed event', () {
      final seeds = jsonDecode(
        File('tool/content/editorial_seeds.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final event = (seeds['onThisDay'] as List).singleWhere(
        (entry) => entry['id'] == 'p05-opening-postponed',
      );
      expect(event['date'], '2020-10-29');
      expect(event['sources'], contains('aa-kariye-postponed-2020'));
      expect(event['text']['en'], contains('postponed'));
      for (final language in ['en', 'tr']) {
        final text = registry
            .place('chora')!
            .strata
            .first
            .body
            .inLanguage(language);
        expect(
          text,
          isNot(contains('first Friday prayer in 72 years was held')),
        );
        expect(text, isNot(contains('72 yıl sonra ilk cuma namazı kılındı')));
      }
    });
  });

  group('P05 dig page', () {
    Future<void> openChora(WidgetTester tester) async {
      await pumpShell(tester);
      await tester.tap(destination('City'));
      await ready(tester);
      final chora = find.text('Kariye Mosque (Chora)');
      await tester.scrollUntilVisible(
        chora,
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(chora);
      await ready(tester);
    }

    testWidgets('Chora digs from the present to 330 under a pinned plate', (
      tester,
    ) async {
      await openChora(tester);
      expect(find.byType(DigGauge), findsOneWidget);
      // The hero opens on the present layer and its readout.
      await tester.scrollUntilVisible(
        find.text('The mosque again, 2020–'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Year 2026 · Modern'), findsOneWidget);
      // The visit card is sourced and shows the checked date.
      expect(find.byType(VisitCard, skipOffstage: false), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Visit'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('HOURS'), findsOneWidget);
      expect(find.text('T4 Edirnekapı'), findsOneWidget);
      // Scroll into the Metochites layer: the plate crossfades to 1321 and
      // the two prototype Milestones become the entry point.
      await tester.scrollUntilVisible(
        find.text('Theodore Metochites, 1315–1321'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      // The pinned plate crossfades once the layer passes the reading line.
      await tester.scrollUntilVisible(
        find.text('Year 1321 · Byzantine'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Year 1321 · Byzantine'), findsOneWidget);
      expect(find.text('Enter the Milestones here'), findsOneWidget);
      expect(find.text('Anastasis'), findsWidgets);
      expect(find.text('The Last Judgment'), findsWidgets);
      expect(find.text('Artworks in this layer'), findsOneWidget);
    });

    // P07 audit: a short last layer never reaches the reading line, so the
    // page end must select it; Hagia Sophia is the JSON-only proof page.
    for (final (name, last) in [
      ('Kariye Mosque (Chora)', 'Year 330 · Byzantine'),
      ('Hagia Sophia Mosque', 'Year 537 · Byzantine'),
    ]) {
      testWidgets('$name: the page end selects the oldest layer', (
        tester,
      ) async {
        await pumpShell(tester);
        await tester.tap(destination('City'));
        await ready(tester);
        final row = find.text(name);
        await tester.scrollUntilVisible(
          row,
          400,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(row);
        await ready(tester);
        expect(find.byType(DigGauge), findsOneWidget);
        final page = find.byType(Scrollable).first;
        for (var i = 0; i < 40; i++) {
          await tester.drag(page, const Offset(0, -600));
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(find.text(last), findsOneWidget);
      });
    }

    testWidgets('a draft without layers keeps the P04 header only', (
      tester,
    ) async {
      await pumpShell(tester);
      await tester.tap(destination('City'));
      await ready(tester);
      final suleymaniye = find.text('Süleymaniye Mosque');
      await tester.scrollUntilVisible(
        suleymaniye,
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(suleymaniye);
      await ready(tester);
      expect(find.byType(DigGauge), findsNothing);
      expect(find.text('Not reviewed yet'), findsOneWidget);
      expect(find.text('Visit'), findsNothing);
    });

    testWidgets('reduced motion swaps plates without a transition', (
      tester,
    ) async {
      final stratum = Stratum(
        'test',
        1500,
        2020,
        Era.ottoman,
        const Localized(en: 'Test layer'),
        const Localized(en: 'First paragraph.\n\nSecond paragraph.'),
        const [],
        const [],
        const [],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              size: Size(390, 200),
            ),
            child: DigHero(stratum: stratum, media: null),
          ),
        ),
      );
      final switcher = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(switcher.duration, Duration.zero);
    });

    testWidgets('the gauge announces years and commits through semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      int? committed;
      final strata = [
        for (final (from, anchor) in [(2020, 2026), (1945, 1948), (1511, 1511)])
          Stratum(
            'gauge-$anchor',
            from,
            null,
            Era.modern,
            const Localized(en: 'Layer'),
            const Localized(en: 'One.\n\nTwo.'),
            const [],
            const [],
            const [],
            anchorYear: anchor,
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                DigGauge(
                  strata: strata,
                  selected: 0,
                  displayYear: 2026,
                  onPreview: (_) {},
                  onCommit: (index) => committed = index,
                ),
              ],
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(DigGauge));
      expect(node.label, 'Depth gauge');
      expect(node.value, '2026');
      expect(node.decreasedValue, '1948');
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.decrease),
        isTrue,
      );
      tester.semantics.performAction(
        find.semantics.byLabel('Depth gauge'),
        SemanticsAction.decrease,
      );
      await tester.pump();
      expect(committed, 1);
      semantics.dispose();
    });
  });

  group('P05 links', () {
    test(
      'walking directions prefer the entrance and ask for walking mode',
      () async {
        final registry = await loadRegistry();
        final chora = registry.place('chora')!;
        final uri = walkingDirectionsUri(chora);
        expect(uri.host, 'www.google.com');
        expect(uri.path, '/maps/dir/');
        expect(uri.query, contains('travelmode=walking'));
        expect(uri.query, contains('destination=${chora.coordinates.lat},'));
      },
    );

    test('Report a change stays hidden while O17 is open', () async {
      expect(milionSupportEmail, isEmpty);
      final registry = await loadRegistry();
      expect(
        reportChangeUri(registry.place('chora')!, subject: 's', body: 'b'),
        isNull,
      );
    });
  });
}
