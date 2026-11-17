import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/plate/controller.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/screens/artworks_tab.dart';
import 'package:milion/space/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'p04_content_test.dart' show loadRegistry;
import 'space_kit_test.dart' show kitModel, kitStudy;

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
PlateManifest _plate(String id) =>
    PlateManifest.fromJson(_json('assets/plates/$id/manifest.json'));

/// P12 against the shipped content: Hagia Sophia reviewed, its dig, the
/// things to look at, Milestones VII–X and the engine additions they use.
void main() {
  late ContentRegistry registry;
  setUpAll(() async => registry = await loadRegistry());

  group('the Hagia Sophia page', () {
    test('is reviewed: entrance, dated status and a cited visit card', () {
      final p = registry.place('hagia-sophia')!;
      expect(p.review, ReviewStatus.reviewed);
      expect(p.entrance, isNotNull);
      expect(p.status.value, PlaceStatus.open);
      expect(p.status.checkedAt, DateTime(2026, 11, 16));
      expect(p.tags, isNot(contains('entrance-unverified')));
      final visit = p.visit!;
      expect(visit.hoursCheckedAt, DateTime(2026, 11, 16));
      expect(visit.hours!.en, contains('Friday'));
      expect(visit.entry!.en, contains('€25'));
      expect(visit.entry!.tr, contains('25 avro'));
      expect(visit.etiquette!.tr, isNotEmpty);
      // No official timetable: no structured week, so no "Open now" claim.
      expect(visit.weekly, isEmpty);
      expect(visit.transit.map((t) => t.stop.en), contains('T1 Sultanahmet'));
      expect(visit.sourceIds, contains('osm-node-12102726893'));
    });

    test('the dig runs 2020 back to 360, every layer dated and cited', () {
      final strata = registry.place('hagia-sophia')!.strata;
      expect(strata.map((s) => s.gaugeYear), [
        2024,
        1935,
        1849,
        1453,
        1261,
        1204,
        1042,
        562,
        537,
        415,
        360,
      ]);
      for (final s in strata) {
        expect(s.sourceIds, isNotEmpty, reason: s.id);
        expect(s.paragraphs('en').length, inInclusiveRange(2, 4));
        expect(s.paragraphs('tr').length, inInclusiveRange(2, 4));
      }
      String body(String id) => strata.firstWhere((s) => s.id == id).body.en;
      // The dates the phase asks for, as the sources give them.
      expect(body('great-church-360'), contains('15 February 360'));
      expect(body('theodosian-church'), contains('10 October 415'));
      expect(body('theodosian-church'), contains('lambs'));
      expect(body('justinian-church'), contains('27 December 537'));
      expect(body('dome-of-562'), contains('7 May 558'));
      expect(body('dome-of-562'), contains('24 December 562'));
      expect(body('latin-cathedral'), contains('nineteenth-century marker'));
      expect(body('ayasofya-mosque-1453'), contains('29 May 1453'));
      expect(body('fossati-repair'), contains('1847'));
      expect(body('ayasofya-museum'), contains('24 November 1934'));
      expect(body('ayasofya-museum'), contains('1 February 1935'));
      expect(body('ayasofya-mosque-2020'), contains('24 July 2020'));
      // 558: only part of the dome fell, and the sources disagree which.
      expect(body('dome-of-562'), contains('part of it fell'));
      // Each Milestone opens from its layer.
      final layer562 = strata.firstWhere((s) => s.id == 'dome-of-562');
      expect(layer562.studyIds, ['ayasofya']);
      expect(
        registry
            .milestonesIn(
              strata.firstWhere((s) => s.id == 'palaiologan-deesis'),
            )
            .map((m) => m.id),
        ['milestone-vii'],
      );
      expect(
        registry
            .milestonesIn(
              strata.firstWhere((s) => s.id == 'middle-byzantine-galleries'),
            )
            .map((m) => m.id),
        containsAll(['milestone-viii', 'milestone-x']),
      );
      for (final s in strata) {
        for (final id in s.mediaIds) {
          expect(File(registry.mediaItem(id)!.path).existsSync(), isTrue);
        }
      }
    });

    test('nine things to look at, complete, with their scripts', () {
      final art = registry.artworks
          .where((a) => a.placeId == 'hagia-sophia')
          .toList();
      expect(art.map((a) => a.id).toSet(), {
        'hs-deesis',
        'hs-zoe-panel',
        'hs-halvdan-runes',
        'hs-dandolo-marker',
        'hs-lamb-frieze',
        'hs-omphalion',
        'hs-weeping-column',
        'hs-empress-loggia',
        'hs-roundels',
      });
      for (final a in art) {
        expect(a.complete, isTrue, reason: a.id);
      }
      Artwork a(String id) => art.firstWhere((x) => x.id == id);
      expect(
        a('hs-halvdan-runes').inscriptions.single.script,
        InscriptionScript.runic,
      );
      expect(
        a('hs-dandolo-marker').inscriptions.single.script,
        InscriptionScript.latin,
      );
      expect(a('hs-roundels').inscriptions, hasLength(8));
      expect(
        a('hs-roundels').inscriptions
            .every((i) => i.script == InscriptionScript.arabic),
        isTrue,
      );
      expect(
        a('hs-zoe-panel').inscriptions
            .every((i) => i.script == InscriptionScript.greek),
        isTrue,
      );
    });

    testWidgets('its artworks list names the place and shows no slugs', (
      tester,
    ) async {
      // A52s 2026-11-17: the list said "9 artworks · Chora / Kariye" and
      // showed record ids (hs-deesis) where Chora shows catalogue codes.
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          home: ArtworksTab(
            artworks: [
              for (final a in registry.artworks)
                if (a.placeId == 'hagia-sophia') a,
            ],
            place: registry.place('hagia-sophia')!.names,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('9 artworks · Hagia Sophia Mosque'), findsOneWidget);
      expect(find.text('The Deesis'), findsOneWidget);
      expect(find.text('hs-deesis'), findsNothing);
      // Nor does its sheet, which keeps Chora's codes as its eyebrow.
      await tester.tap(find.text('The Deesis'));
      await tester.pumpAndSettle();
      expect(find.text('The Deesis'), findsNWidgets(2));
      expect(find.text('hs-deesis'), findsNothing);
      expect(registry.artwork('F02').code, 'F02');
    });

    test('an inscription must be written in its script', () async {
      final data = await readContent((p) => File(p).readAsString());
      final rune = (data['artworks'] as List).firstWhere(
        (r) => r['id'] == 'hs-halvdan-runes',
      ) as Map<String, dynamic>;
      final inscription =
          (rune['inscriptions'] as List).single as Map<String, dynamic>;
      inscription['greek'] = 'alftan';
      final report = validateContent(data);
      expect(
        report.errors,
        contains('hs-halvdan-runes.inscriptions[0] has no runes'),
      );
    });
  });

  group('Milestones VII–X', () {
    test('play from their manifests with honest labels', () {
      Milestone m(String id) =>
          registry.milestones.firstWhere((x) => x.id == id);
      expect(
        m('milestone-vii').manifestPath,
        'assets/plates/deesis/manifest.json',
      );
      expect(m('milestone-vii').honesty, contains(Honesty.RECONSTRUCTION));
      expect(
        m('milestone-viii').manifestPath,
        'assets/plates/zoe/manifest.json',
      );
      expect(m('milestone-viii').honesty, contains(Honesty.IMAGINED));
      expect(
        m('milestone-ix').manifestPath,
        'assets/space/ayasofya/study.json',
      );
      expect(
        m('milestone-x').manifestPath,
        'assets/plates/halvdan/manifest.json',
      );
      for (final id in ['vii', 'viii', 'ix', 'x']) {
        expect(m('milestone-$id').status, MilestoneStatus.prototype);
      }
    });

    test('VII wipes the RECONSTRUCTION in during its story beat', () {
      final p = _plate('deesis');
      final beat = p.beats.firstWhere((b) => b.layer != null);
      expect(beat.layer, PlateLayerId.reconstruction);
      final c = PlateController(p)..seek(beat.start + .05);
      expect(c.visibleLayer, PlateLayerId.reconstruction);
      expect(c.honesty, Honesty.RECONSTRUCTION);
      final early = c.visibleWipe;
      c.seek(beat.start + beat.duration * .7);
      expect(c.visibleWipe, 1);
      expect(early, lessThan(.1));
      c.peek(true);
      expect(c.honesty, Honesty.ORIGINAL);
      c.dispose();
      // The reveal (the tilt hook) is the gold, under gilded light.
      expect(p.reveal.light, PlateLight.gilded);
      expect(p.revealSeconds, 10);
    });

    test('VIII empties the reset head as IMAGINED; no face is invented', () {
      final p = _plate('zoe');
      final layer = p.layer(PlateLayerId.imagined)!;
      expect(layer.honesty, Honesty.IMAGINED);
      expect(layer.mask, isNotNull);
      final beat = p.beats.firstWhere((b) => b.layer != null);
      expect(beat.layer, PlateLayerId.imagined);
      final c = PlateController(p)..seek(beat.start + beat.duration / 2);
      expect(c.honesty, Honesty.IMAGINED);
      c.setReduced(true);
      expect(c.visibleWipe, 1);
      c.dispose();
    });

    test('a still of a wipe beat shows the layer its label names', () {
      // A52s 2026-11-17: "Previous still" landed on the beat's first frame,
      // where VIII still showed the emperor's face under an IMAGINED label.
      for (final id in ['deesis', 'zoe']) {
        final p = _plate(id);
        final i = p.beats.indexWhere((b) => b.layer != null);
        final beat = p.beats[i];
        final c = PlateController(p)..seek(p.beats[i - 1].start);
        c.step(1);
        expect(c.sample!.beat.id, beat.id, reason: id);
        expect(c.visibleWipe, 1, reason: id);
        expect(c.visibleLayer, beat.layer, reason: id);
        // On the beat's first frame nothing is wiped in yet, and the label
        // says what is on screen.
        c.seek(beat.start);
        expect(c.visibleWipe, 0, reason: id);
        expect(c.honesty, Honesty.DEPTH, reason: id);
        c.dispose();
      }
    });

    test('a beat may only wipe in a masked layer the plate has', () {
      final j = _json('assets/plates/halvdan/manifest.json');
      (j['beats'] as List).first['layer'] = 'reconstruction';
      expect(() => PlateManifest.fromJson(j), throwsFormatException);
      final z = _json('assets/plates/zoe/manifest.json');
      final wipe = (z['beats'] as List).firstWhere((b) => b['layer'] != null);
      wipe['flow'] = true;
      expect(() => PlateManifest.fromJson(z), throwsFormatException);
    });

    test('X is a raking and candle plate of the runes', () {
      final p = _plate('halvdan');
      expect(p.beats.map((b) => b.light).toSet(), {
        PlateLight.raking,
        PlateLight.candle,
      });
      expect(p.details.length, greaterThanOrEqualTo(5));
    });
  });

  group('Milestone IX, the dome that fell', () {
    test('558 sinks the east half with dust; the west half stays', () {
      final study = kitStudy('ayasofya'), model = kitModel(study);
      expect(study.epochs.map((e) => e.year), [537, 558, 562, 1573]);
      expect(study.epochs[1].collapse, isTrue);
      final c = SpaceController(study, model);
      final fall = c.timeline.beats.firstWhere((b) => b.step.id == 'collapse');
      int part(String id) => model.parts.indexWhere((p) => p.id == id);
      c.seek(fall.start + fall.duration * .3);
      var s = c.partStates();
      expect(s[part('dome-537-east')].dust, greaterThan(0));
      expect(s[part('dome-537-east')].dz, lessThan(0));
      expect(s[part('dome-537-west')].dust, 0);
      expect(s[part('dome-537-west')].progress, 1);
      c.seek(fall.start + fall.duration * .99);
      s = c.partStates();
      expect(s[part('dome-537-east')].progress, 0);
      expect(s[part('dome-537-east')].dust, lessThan(.1));
      c.dispose();
    });

    test('the ring of windows lights in turn; the fall is slow', () {
      final study = kitStudy('ayasofya'), model = kitModel(study);
      final c = SpaceController(study, model);
      final light = c.timeline.beats.firstWhere((b) => b.step.id == 'light');
      final i = model.parts.indexWhere((p) => p.id == 'dome-562-light');
      expect(model.parts[i].material, 'light');
      c.seek(light.start + light.duration * .4);
      final mid = c.partStates()[i].progress;
      expect(mid, inExclusiveRange(0, 1));
      c.seek(light.start + light.duration * .95);
      expect(c.partStates()[i].progress, greaterThan(mid));
      final fall = c.timeline.beats.firstWhere((b) => b.step.id == 'collapse');
      expect(fall.duration, greaterThanOrEqualTo(2.4));
      expect(study.storySeconds, inInclusiveRange(20, 40));
      c.dispose();
    });
  });
}
