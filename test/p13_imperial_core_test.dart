import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:milion/city/dig_sections.dart';
import 'package:milion/city/visit_card.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/design/theme.dart';
import 'package:milion/first_run/milion_intro.dart';
import 'package:milion/l10n/app_localizations_en.dart';
import 'package:milion/l10n/app_localizations_tr.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/plate/controller.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/shell/app_scope.dart';
import 'package:milion/space/study.dart';

import 'p04_content_test.dart' show loadRegistry;
import 'space_engine_test.dart' show signedVolume;
import 'space_kit_test.dart' show kitModel, kitStudy;

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
PlateManifest _plate(String id) =>
    PlateManifest.fromJson(_json('assets/plates/$id/manifest.json'));

/// P13's kit studies: Milestones 0 (the Milion), XII (the Hippodrome through
/// time) and XIV (the Serpent Column).
const p13Studies = ['milion', 'hippodrome', 'serpent-column'];

/// P13 against the shipped content: the imperial core's studies, plates,
/// roads and Milestones.
void main() {
  late ContentRegistry registry;
  setUpAll(() async => registry = await loadRegistry());

  group('the kit studies', () {
    test('load closed, within budget, as the builder reported', () {
      for (final id in p13Studies) {
        final study = kitStudy(id), model = kitModel(study);
        study.checkModel(model);
        expect(
          model.triangleCount,
          lessThanOrEqualTo(SpaceStudy.triangleBudget),
        );
        for (final p in model.parts) {
          expect(p.closed, isTrue, reason: '$id ${p.id}');
          expect(signedVolume(p), greaterThan(0), reason: '$id ${p.id}');
        }
        final report = _json('studio/space/$id.report.json');
        expect({
          for (final p in model.parts) p.id: p.triangleCount,
        }, report['byPart']);
        for (final d in (report['dimensions'] as List).cast<Map>()) {
          expect(
            (d['error'] as num).abs(),
            lessThanOrEqualTo(d['tolerance'] as num),
            reason: '$id ${d['id']}',
          );
        }
        expect(study.honesty, Honesty.RECONSTRUCTION);
        expect(study.reveal.seconds, lessThanOrEqualTo(10));
      }
    });

    test('the Milion and the Hippodrome sit on cited axes; the Serpent '
        'Column is an object', () {
      final milion = kitStudy('milion'), hippodrome = kitStudy('hippodrome');
      expect(milion.orientation!.axis, closeTo(271.5, .5));
      expect(hippodrome.orientation!.axis, closeTo(38.97, .5));
      for (final s in [milion, hippodrome]) {
        expect(s.citations.map((c) => c.id), contains(s.orientation!.sourceId));
      }
      expect(kitStudy('serpent-column').orientation, isNull);
    });

    test(
      'the Hippodrome scrubs from 330 to today, its stands gone by 1582',
      () {
        final s = kitStudy('hippodrome');
        expect(s.epochs.map((e) => e.year), [330, 1200, 1582, 2026]);
        Set<String> shown(int year) => {
          for (final step in s.stepsIn(year)) ...step.parts,
        };
        expect(shown(330), contains('kathisma'));
        expect(shown(330), isNot(contains('obelisk-shaft')));
        expect(shown(1200), containsAll(['obelisk-shaft', 'walled-obelisk']));
        expect(shown(1582), isNot(contains('stands-west')));
        expect(shown(1582), containsAll(['palace-ranges-west', 'serpent']));
        expect(shown(2026), containsAll(['serpent-today', 'mosque-hall']));
        expect(shown(2026), isNot(contains('serpent')));
      },
    );

    test('the Serpent Column keeps its heads until today', () {
      final s = kitStudy('serpent-column');
      expect(s.epochs.map((e) => e.year), [-479, 330, 2026]);
      final today = {for (final step in s.stepsIn(2026)) ...step.parts};
      expect(today, containsAll(['column-today', 'jaw']));
      expect(today, isNot(contains('coils-heads')));
      expect(s.reveal.turnDegrees, 360);
    });
  });

  group('Milestone 0', () {
    test('the roads leave the Milion toward their ends with the '
        'itinerary\'s miles', () {
      final byName = {for (final r in firstRunRoads) r.name.en: r};
      expect(byName.keys, ['Hebdomon', 'Serdica', 'Nicomedia', 'Jerusalem']);
      expect(byName.values.map((r) => r.miles), [7, 413, 58, 1164]);
      expect(byName['Hebdomon']!.bearing, inInclusiveRange(240, 260));
      expect(byName['Serdica']!.bearing, inInclusiveRange(285, 300));
      expect(byName['Nicomedia']!.bearing, inInclusiveRange(100, 115));
      expect(byName['Jerusalem']!.bearing, inInclusiveRange(145, 160));
      for (final r in firstRunRoads) {
        expect(r.name.tr, isNotEmpty);
      }
    });
  });

  group('the plates', () {
    test('XIII is raking light and candle on the base, six details', () {
      final p = _plate('obelisk-base');
      expect(p.details, hasLength(6));
      expect(p.beats.map((b) => b.light).toSet(), {
        PlateLight.raking,
        PlateLight.candle,
      });
      expect(p.flowEffect, isNull);
      expect(p.reveal.light, PlateLight.raking);
      final artwork = registry.artwork('ic-obelisk-base');
      expect(artwork.inscriptions.map((i) => i.script), [
        InscriptionScript.latin,
        InscriptionScript.greek,
      ]);
    });

    test('XV sways inside its animals and reads IMAGINED while it moves', () {
      final p = _plate('palace-animals');
      final flow = p.flowEffect!;
      expect(flow.sway, isTrue);
      final moving = p.beats.where((b) => b.flow).toList();
      expect(moving, hasLength(2));
      for (final beat in moving) {
        expect(beat.caption.en, startsWith('IMAGINED'));
        expect(beat.caption.tr, startsWith('HAYALÎ'));
        final c = PlateController(p)..seek(beat.start + 1);
        expect(c.visibleFlow, isTrue);
        expect(c.honesty, Honesty.IMAGINED);
        // Reduced motion: nothing moves, and nothing claims to.
        c.setReduced(true);
        expect(c.visibleFlow, isFalse);
        expect(c.honesty, isNot(Honesty.IMAGINED));
        c.dispose();
      }
      final still = p.beats.firstWhere((b) => !b.flow);
      final c = PlateController(p)..seek(still.start + 1);
      expect(c.honesty, isNot(Honesty.IMAGINED));
      c.dispose();
    });

    test('XV\'s mask covers the animals only, its directions unit length', () {
      final mask = img.decodePng(
        File('assets/plates/palace-animals/animals.png').readAsBytesSync(),
      )!;
      var covered = 0;
      for (final px in mask) {
        if (px.r < 128) continue;
        covered++;
        final dx = px.g / 255 * 2 - 1, dy = px.b / 255 * 2 - 1;
        expect(math.sqrt(dx * dx + dy * dy), closeTo(1, .02));
      }
      final share = covered / (mask.width * mask.height);
      expect(share, inExclusiveRange(.02, .2));
      // The hunter does not move: his detail's anchor is outside the mask.
      final hunter = p13Detail(
        _plate('palace-animals'),
        'detail-palace-hunter',
      );
      final px = mask.getPixel(
        (hunter.anchorX * mask.width).round(),
        (hunter.anchorY * mask.height).round(),
      );
      expect(px.r, lessThan(16));
    });
  });

  group('the five places', () {
    test(
      'are reviewed with dated status, an entrance and a cited visit card',
      () {
        const expected = {
          'hippodrome': PlaceStatus.open,
          'milion': PlaceStatus.open,
          'column-of-constantine': PlaceStatus.open,
          'great-palace-mosaic-museum': PlaceStatus.closed,
          'boukoleon': PlaceStatus.restoration,
        };
        for (final MapEntry(key: id, value: status) in expected.entries) {
          final p = registry.place(id)!;
          expect(p.review, ReviewStatus.reviewed, reason: id);
          expect(p.status.value, status, reason: id);
          expect(p.status.checkedAt, DateTime(2026, 11, 19), reason: id);
          expect(p.entrance, isNotNull, reason: id);
          expect(p.tags, isNot(contains('entrance-unverified')), reason: id);
          expect(p.strata.length, inInclusiveRange(3, 4), reason: id);
          expect(p.visit!.sourceIds, isNotEmpty, reason: id);
          expect(p.visit!.entry!.tr, isNotEmpty, reason: id);
        }
        // Closed or fenced: no hours are claimed.
        expect(
          registry.place('great-palace-mosaic-museum')!.visit!.hours,
          isNull,
        );
        expect(
          registry.place('great-palace-mosaic-museum')!.visit!.entry!.en,
          contains('July 2023'),
        );
        expect(registry.place('boukoleon')!.visit!.hours, isNull);
      },
    );

    testWidgets('a visit card lists Getting there only over cited stops', (
      tester,
    ) async {
      Future<void> card(String id) => tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: DesignTheme.marble,
          home: Scaffold(
            body: SingleChildScrollView(
              child: VisitCard(place: registry.place(id)!, registry: registry),
            ),
          ),
        ),
      );
      // The Hippodrome's entrance text names its tram stop; it lists none.
      expect(registry.place('hippodrome')!.visit!.transit, isEmpty);
      await card('hippodrome');
      expect(find.text('GETTING THERE'), findsNothing);
      expect(find.text('Visit'), findsOneWidget);
      await card('column-of-constantine');
      expect(find.text('GETTING THERE'), findsOneWidget);
      expect(find.text('T1 Çemberlitaş'), findsOneWidget);
    });

    testWidgets('a layer lists its artwork by title, without its record id', (
      tester,
    ) async {
      // A52s 2026-11-19: the museum's 1935 layer showed
      // "ic-palace-floor-mosaic" in Chora's catalogue-code column, and the
      // page said "1 artworks".
      final stratum = registry
          .place('great-palace-mosaic-museum')!
          .strata
          .firstWhere((s) => s.artworkIds.isNotEmpty);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: DesignTheme.marble,
          home: Scaffold(
            body: SingleChildScrollView(
              child: AppScope(
                registry: registry,
                error: null,
                retry: () {},
                clock: DateTime.now,
                recognised: const {},
                child: DigStratumView(
                  registry: registry,
                  stratum: stratum,
                  opened: (_) => false,
                  onOpenArtwork: (_) {},
                  onOpenMilestone: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('The palace peristyle floor'), findsOneWidget);
      expect(find.text('ic-palace-floor-mosaic'), findsNothing);
      expect(AppLocalizationsEn().artworksHere(1), '1 artwork');
      expect(AppLocalizationsEn().artworksHere(103), '103 artworks');
      expect(AppLocalizationsTr().artworksHere(1), '1 eser');
    });

    test('the Hippodrome and the Milion read with their studies', () {
      final hippodrome = registry.place('hippodrome')!.strata;
      expect(hippodrome.map((s) => s.gaugeYear), [2026, 1582, 1204, 330]);
      expect(hippodrome.last.studyIds, ['hippodrome']);
      final milion = registry.place('milion')!.strata;
      expect(milion.last.studyIds, ['milion']);
      final museum = registry.place('great-palace-mosaic-museum')!.strata;
      expect(
        museum.expand((s) => s.artworkIds),
        contains('ic-palace-floor-mosaic'),
      );
    });
  });

  group('Milestones 0 and XII–XV', () {
    test('play from their manifests with honest labels', () {
      Milestone m(String id) =>
          registry.milestones.firstWhere((x) => x.id == id);
      expect(m('milestone-0').manifestPath, 'assets/space/milion/study.json');
      expect(
        m('milestone-xii').manifestPath,
        'assets/space/hippodrome/study.json',
      );
      expect(
        m('milestone-xiii').manifestPath,
        'assets/plates/obelisk-base/manifest.json',
      );
      expect(
        m('milestone-xiv').manifestPath,
        'assets/space/serpent-column/study.json',
      );
      expect(
        m('milestone-xv').manifestPath,
        'assets/plates/palace-animals/manifest.json',
      );
      expect(m('milestone-xv').honesty, contains(Honesty.IMAGINED));
      expect(m('milestone-xii').honesty, contains(Honesty.RECONSTRUCTION));
      for (final id in ['0', 'xii', 'xiii', 'xiv', 'xv']) {
        expect(m('milestone-$id').status, MilestoneStatus.prototype);
      }
    });
  });
}

Detail p13Detail(PlateManifest p, String id) =>
    p.details.firstWhere((d) => d.id == id);
