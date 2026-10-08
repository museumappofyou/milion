import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/geography.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/plate/catalog.dart';
import 'package:milion/today/detail_crop.dart';
import 'package:milion/today/mile_zero_dial.dart';

Future<ContentRegistry> loadRegistry() =>
    ContentRepository((p) => File(p).readAsString()).load();

void main() {
  late ContentRegistry registry;
  late PlateCatalog plates;
  setUpAll(() async {
    registry = await loadRegistry();
    plates = await PlateCatalog.load(registry, (p) => File(p).readAsString());
  });

  test(
    'register: 48 numerals 0–XLVII in order, nine flagships, I–II playable',
    () {
      final register = registry.register;
      expect(register.map((m) => m.numeral), [
        for (var n = 0; n < 48; n++) romanNumeral(n),
      ]);
      expect(register.where((m) => m.flagship).map((m) => m.numeral).toSet(), {
        '0',
        'I',
        'VII',
        'IX',
        'XVI',
        'XVIII',
        'XXIII',
        'XXXIII',
        'XXXVI',
      });
      expect(
        register
            .where((m) => plates.forMilestone(m) != null)
            .map((m) => m.numeral),
        ['I', 'II'],
      );
      for (final m in register) {
        expect(m.honesty, contains(Honesty.ORIGINAL), reason: m.numeral);
        expect(m.title.tr, isNotEmpty, reason: m.numeral);
        if (m.status == MilestoneStatus.planned) {
          expect(m.manifestPath, isNull, reason: m.numeral);
        }
      }
      expect(romanValue('XLVII'), 47);
      expect(romanValue('0'), 0);
    },
  );

  test('detail pool: ≥ 14 curated Chora details, EN+TR, on playable Milestones', () {
    final pool = registry.details;
    expect(pool.length, greaterThanOrEqualTo(14));
    expect(pool.map((d) => d.id).toSet().length, pool.length);
    for (final d in pool) {
      final m = registry.milestone(d.milestoneId)!;
      expect(
        plates.forMilestone(m),
        isNotNull,
        reason: '${d.id} must open a playable Milestone',
      );
      expect(registry.artwork(d.artworkId).placeId, 'chora');
      expect(d.sentence.tr, isNotEmpty);
      expect(d.title.tr, isNotEmpty);
      expect(d.honesty, Honesty.ORIGINAL);
      expect(d.sourceIds, isNotEmpty);
      // One checkable sentence: a single terminal full stop, no filler words.
      for (final text in [d.sentence.en, d.sentence.tr!]) {
        expect(RegExp(r'[.!?]["”]?$').hasMatch(text), isTrue, reason: text);
        expect(
          text
              .split(RegExp(r'[.!?](\s|$)'))
              .where((x) => x.trim().isNotEmpty)
              .length,
          1,
          reason: text,
        );
      }
      expect(
        d.sentence.en.toLowerCase(),
        isNot(
          matches(
            RegExp(
              r'discover|journey|timeless|step into|magic|hidden gem|rich history|beyond the surface',
            ),
          ),
        ),
      );
    }
    // Consecutive entries alternate artworks, so consecutive days change plate.
    for (var i = 1; i < pool.length; i++) {
      expect(
        pool[i].artworkId,
        isNot(pool[i - 1].artworkId),
        reason: pool[i].id,
      );
    }
  });

  test(
    'detail of the day is deterministic by local date and covers the pool',
    () {
      final day = DateTime(2026, 10, 1, 8);
      expect(
        detailOfDay(registry, day).id,
        detailOfDay(registry, DateTime(2026, 10, 1, 23, 59)).id,
      );
      expect(
        detailOfDay(registry, day).id,
        isNot(detailOfDay(registry, DateTime(2026, 10, 2)).id),
      );
      final seen = {
        for (var i = 0; i < registry.details.length; i++)
          detailOfDay(registry, DateTime(2026, 10, 1 + i)).id,
      };
      expect(seen.length, registry.details.length);
      // Across a DST change (TR has none; the rule must not depend on it).
      expect(
        detailOfDay(registry, DateTime(2027, 3, 28)).id,
        detailOfDay(registry, DateTime(2027, 3, 28, 23)).id,
      );
    },
  );

  test('crop geometry covers the box and keeps the anchor inside it', () {
    for (final d in registry.details) {
      final scene = plates.forMilestone(registry.milestone(d.milestoneId)!)!;
      for (final box in [
        const Size(390, 437),
        const Size(360, 403),
        const Size(430, 481),
      ]) {
        final g = CropGeometry(
          box,
          Size(scene.width.toDouble(), scene.height.toDouble()),
          d.window,
        );
        final a = g.toBox(d.anchorX, d.anchorY);
        expect(a.dx, inInclusiveRange(0, box.width), reason: d.id);
        expect(a.dy, inInclusiveRange(0, box.height), reason: d.id);
        expect(scene.width * g.scale, greaterThanOrEqualTo(box.width - .001));
      }
    }
  });

  test(
    'plottable places are single points inside the province with checked QIDs',
    () {
      final plotted = registry.plottablePlaces;
      expect(plotted, isNotEmpty);
      for (final p in plotted) {
        expect(p.outsideProvince, isFalse);
        expect(
          p.tags.toSet().intersection(nonPointTags),
          isEmpty,
          reason: p.id,
        );
        expect(p.qid, startsWith('Q'));
      }
      final ids = plotted.map((p) => p.id).toSet();
      expect(ids, containsAll(['milion', 'chora', 'hagia-sophia', 'yedikule']));
      expect(ids, isNot(contains('bosphorus')));
      expect(ids, isNot(contains('sariyer')));
      expect(ids, isNot(contains('venice')));
      // Sorted by distance from mile zero.
      final km = plotted.map((p) => fromMilion(p).km).toList();
      expect(km, [...km]..sort());
    },
  );

  test('dial scale: zero at the stone, monotonic, the outer ring is L mil', () {
    expect(DialScale.unit(0), 0);
    expect(DialScale.unit(50 * romanMileKm), closeTo(1, 1e-9));
    expect(DialScale.unit(500), 1);
    var last = 0.0;
    for (final miles in DialScale.rings) {
      final u = DialScale.unit(miles * romanMileKm);
      expect(u, greaterThan(last));
      last = u;
    }
    final places = dialPlaces(registry.plottablePlaces);
    expect(
      places.any((p) => p.place.id == 'milion'),
      isFalse,
      reason: 'the origin has no bearing',
    );
    final bearings = places.map((p) => p.bearing).toList();
    expect(bearings, [...bearings]..sort());
    expect(DialScale.coast, isNotEmpty);
  });
}
