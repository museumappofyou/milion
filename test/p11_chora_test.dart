import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/guide.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/shell/app_scope.dart';
import 'package:milion/space/catalog.dart';

import 'p04_content_test.dart' show loadRegistry;

/// P11 against the shipped content: Chora complete, its plan, cycles and hunt.
void main() {
  late ContentRegistry registry;
  setUpAll(() async => registry = await loadRegistry());

  List<Artwork> chora() =>
      registry.artworks.where((a) => a.placeId == 'chora').toList();

  test('103 Chora artworks, every id kept, all complete in EN and TR', () {
    final art = chora();
    expect(art, hasLength(103));
    final ids = art.map((a) => a.id).toSet();
    for (var n = 1; n <= 68; n++) {
      if (n == 49) continue;
      expect(ids, contains('M${n.toString().padLeft(2, '0')}'));
    }
    expect(ids, containsAll(['M49_1', 'M49_2', 'M49_3', 'M49_4']));
    for (var n = 1; n <= 32; n++) {
      expect(ids, contains('F${n.toString().padLeft(2, '0')}'));
    }
    final incomplete = [
      for (final a in art)
        if (!a.complete) a.id,
    ];
    expect(incomplete, isEmpty);
    for (final a in art) {
      expect(a.lookFor, hasLength(3), reason: a.id);
      expect(registry.sourcesOf(a), isNotEmpty, reason: a.id);
      for (final i in a.inscriptions) {
        expect(i.greek, isNot(matches(RegExp('[A-Za-z]'))), reason: a.id);
      }
    }
  });

  test('the validator passes and counts 103/103 complete', () async {
    final data = await readContent((p) => File(p).readAsString());
    final report = validateContent(data);
    expect(report.errors, isEmpty);
    expect(report.completeArtworks, registry.artworks.length);
  });

  test('every artwork sits inside its room on the plan', () {
    final guide = registry.guideFor('chora')!;
    for (final a in chora()) {
      final anchor = guide.anchors[a.id];
      expect(anchor, isNotNull, reason: a.id);
      final room = guide.room(anchor!.room)!;
      expect(room.contains(anchor.at), isTrue, reason: a.id);
    }
    // The plan is oriented: the apse lies east (+u) of the naos dome, the
    // narthexes west, the parekklesion south (−v).
    PlanPoint at(String id) => guide.anchors[id]!.at;
    expect(at('F02').x, greaterThan(at('M01').x));
    expect(at('M11').x, lessThan(at('M01').x));
    expect(at('M50').x, lessThan(at('M11').x));
    expect(at('F12').y, lessThan(at('M13').y));
  });

  test('four guided cycles walk their scenes in order', () {
    final cycles = {
      for (final c in registry.guideFor('chora')!.cycles) c.id: c,
    };
    expect(cycles.keys, [
      'life-of-the-virgin',
      'infancy-of-christ',
      'ministry-of-christ',
      'parekklesion',
    ]);
    expect(cycles['life-of-the-virgin']!.artworkIds.first, 'M17');
    expect(cycles['infancy-of-christ']!.artworkIds.last, 'M46');
    expect(cycles['ministry-of-christ']!.artworkIds.first, 'M47');
    expect(cycles['ministry-of-christ']!.artworkIds, contains('M49_4'));
    expect(cycles['parekklesion']!.artworkIds, hasLength(32));
  });

  test('Chora is reviewed with an entrance; Milestone VI plays its study', () {
    final place = registry.place('chora')!;
    expect(place.review, ReviewStatus.reviewed);
    expect(place.entrance, isNotNull);
    expect(place.tags, isNot(contains('entrance-unverified')));
    final vi = registry.milestone('milestone-vi')!;
    expect(vi.status, MilestoneStatus.prototype);
    expect(File(vi.manifestPath!).existsSync(), isTrue);
  });

  test('Milestone VI is playable through its study, not a plate', () async {
    final spaces = await SpaceCatalog.load(
      registry,
      (p) => File(p).readAsString(),
    );
    final app = AppScope(
      registry: registry,
      error: null,
      retry: () {},
      clock: DateTime.now,
      recognised: const {},
      spaces: spaces,
      child: const SizedBox(),
    );
    final vi = registry.milestone('milestone-vi')!;
    expect(app.studyFor(vi)!.id, 'kariye-camii');
    expect(app.playable(vi), isTrue);
    expect(app.playable(registry.milestone('milestone-vii')!), isFalse);
  });

  test('the Chora hunt has eight sourced items', () {
    final hunt = registry.hunts.singleWhere((h) => h.id == 'chora-hunt');
    expect(hunt.items, hasLength(8));
    for (final item in hunt.items) {
      expect(item.sourceIds, isNotEmpty, reason: item.id);
      for (final a in item.artworkIds) {
        expect(registry.artwork(a).placeId, 'chora');
      }
    }
  });
}
