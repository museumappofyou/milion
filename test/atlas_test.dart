import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/atlas/atlas_assets.dart';
import 'package:milion/atlas/atlas_controller.dart';
import 'package:milion/atlas/atlas_data.dart';
import 'package:milion/atlas/atlas_filter.dart';
import 'package:milion/atlas/atlas_map.dart';
import 'package:milion/atlas/atlas_markers.dart';
import 'package:milion/atlas/atlas_style.dart';
import 'package:milion/atlas/atlas_tiles.dart';
import 'package:milion/atlas/atlas_view.dart';
import 'package:milion/atlas/historic.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/design/theme.dart';

import 'helpers.dart';

Future<ContentRegistry> _registry() async => ContentRegistry.fromJson(
  await readContent((path) => File(path).readAsString()),
);

AtlasAssets _assets() => AtlasAssets.decodeSync(
  ByteData.sublistView(File(AtlasData.assetPath).readAsBytesSync()),
  File(HistoricAtlas.assetPath).readAsStringSync(),
  File(PlaceYears.assetPath).readAsStringSync(),
);

void main() {
  group('data', () {
    late AtlasAssets assets;
    late ContentRegistry registry;
    setUpAll(() async {
      assets = _assets();
      registry = await _registry();
    });

    test(
      'atlas.bin decodes with land, the shore then, and stays in budget',
      () {
        expect(File(AtlasData.assetPath).lengthSync(), lessThan(12000000));
        final land = assets.data.layer(AtlasLayer.land)!;
        expect(land.features, isNotEmpty);
        // The province is about 165 km across; the Milion lies inside it.
        expect(assets.data.bounds.width, inInclusiveRange(150000, 180000));
        expect(assets.data.bounds.contains(Offset.zero), isTrue);
        final then = assets.data.layer(AtlasLayer.landThen)!;
        expect(then.features, isNotEmpty);
        expect(
          land.features.where((f) => f.cls == 1),
          hasLength(then.features.length),
        );
        for (final l in AtlasLayer.values) {
          expect(assets.data.layer(l), isNotNull, reason: '$l');
        }
      },
    );

    test('historic features are dated, sourced and on the peninsula', () {
      final features = assets.historic.features;
      expect(features.length, greaterThanOrEqualTo(40));
      for (final layer in HistoricLayer.values) {
        expect(assets.historic.inLayer(layer), isNotEmpty, reason: '$layer');
      }
      final peninsula = const Rect.fromLTRB(-9000, -3000, 14000, 12000);
      for (final f in features) {
        expect(f.sourceIds, isNotEmpty, reason: f.id);
        for (final id in f.sourceIds) {
          expect(registry.source(id), isNotNull, reason: '${f.id}: $id');
        }
        expect(f.to == null || f.to! >= f.from, isTrue, reason: f.id);
        expect(peninsula.overlaps(f.bounds.inflate(1)), isTrue, reason: f.id);
        expect(f.names.en, isNotEmpty);
        expect(f.names.tr, isNotEmpty, reason: f.id);
        expect(f.note.tr, isNotEmpty, reason: f.id);
      }
      // Walls appear and vanish with the slider.
      final galata = features.firstWhere((f) => f.id == 'galata-walls');
      expect(galata.presence(1453), 1);
      expect(galata.presence(1200), 0);
      expect(galata.presence(1900), 0);
      final theodosian = features.firstWhere(
        (f) => f.id == 'theodosian-land-walls',
      );
      expect(theodosian.presence(330), 0);
      expect(theodosian.presence(537), 1);
      expect(theodosian.presence(2026), 1);
    });

    test('every plottable place has a year to stand from', () {
      for (final p in registry.plottablePlaces) {
        expect(assets.years.standsFrom(p), lessThanOrEqualTo(2026));
      }
    });
  });

  group('view', () {
    test('screen and world round-trip at any rotation; matrix agrees', () {
      const size = Size(390, 700);
      for (final r in [0.0, .7, -2.1, math.pi]) {
        final v = AtlasView(
          center: const Offset(-1500, 900),
          scale: .05,
          rotation: r,
        );
        for (final p in [Offset.zero, const Offset(120, 610)]) {
          final w = v.toWorld(p, size);
          expect((v.toScreen(w, size) - p).distance, lessThan(1e-6));
          final m = v.matrix(size);
          final mx = m[0] * w.dx + m[4] * w.dy + m[12];
          final my = m[1] * w.dx + m[5] * w.dy + m[13];
          expect((Offset(mx, my) - p).distance, lessThan(1e-6));
        }
      }
    });

    test('north is up: a point north of the centre is above it', () {
      const size = Size(400, 400);
      final p = AtlasView.peninsula.toScreen(
        AtlasView.peninsula.center + const Offset(0, 1000),
        size,
      );
      expect(p.dy, lessThan(200));
    });

    test('zooming keeps the focal point fixed', () {
      const size = Size(390, 700);
      const focal = Offset(100, 200);
      final v = AtlasView.peninsula;
      final before = v.toWorld(focal, size);
      final after = v
          .transformAround(focal, size, factor: 2.5, turn: .4)
          .toWorld(focal, size);
      expect((before - after).distance, lessThan(1e-6));
    });

    test('tile zoom keeps tiles between 192 and 384 pixels', () {
      for (final scale in [1 / 500, 1 / 40, 1 / 3, 1.5]) {
        final z = zoomFor(scale);
        final px = tileSpan(z) * scale;
        if (z > 0 && z < atlasMaxZoom) {
          expect(px, inInclusiveRange(tileMinPx, tileMinPx * 2));
        }
      }
    });

    test('manners crossfade between the eras', () {
      expect(mannersAt(537).from, AtlasManner.manuscript);
      expect(mannersAt(1560).from, AtlasManner.ottoman);
      expect(mannersAt(1500).t, inExclusiveRange(0, 1));
      final today = mannersAt(2026);
      expect((today.to, today.t), (AtlasManner.modern, 1.0));
    });
  });

  group('hours and filters', () {
    test('open now reads Istanbul time (UTC+3)', () {
      final week = [
        OpeningSpan(
          {Weekday.mon, Weekday.tue, Weekday.wed, Weekday.thu, Weekday.sat},
          9 * 60,
          18 * 60,
        ),
      ];
      // Monday 10 November 2026, 06:30 UTC = 09:30 in Istanbul.
      expect(isOpenAt(week, DateTime.utc(2026, 11, 9, 6, 30)), isTrue);
      expect(isOpenAt(week, DateTime.utc(2026, 11, 9, 5, 59)), isFalse);
      expect(isOpenAt(week, DateTime.utc(2026, 11, 9, 15)), isFalse); // 18:00
      expect(isOpenAt(week, DateTime.utc(2026, 11, 13, 10)), isFalse); // Fri
      expect(isOpenAt(const [], DateTime.utc(2026, 11, 9, 10)), isNull);
    });

    test('Chora carries its week; open now never guesses', () async {
      final registry = await _registry();
      final chora = registry.place('chora')!;
      expect(chora.visit!.weekly, isNotEmpty);
      final open = atlasPlaces(
        registry,
        const AtlasFilter(openNow: true),
        DateTime.utc(2026, 11, 9, 9), // Monday noon in Istanbul
      );
      expect(open.map((p) => p.id), ['chora']);
      final friday = atlasPlaces(
        registry,
        const AtlasFilter(openNow: true),
        DateTime.utc(2026, 11, 13, 9),
      );
      expect(friday, isEmpty);
    });

    test('filters combine, and survive encoding', () async {
      final registry = await _registry();
      final all = atlasPlaces(registry, AtlasFilter.none, DateTime(2026));
      expect(all, registry.plottablePlaces);
      final f = AtlasFilter(
        waves: {Wave.byzantine},
        categories: {Category.cistern},
        districts: {District.fatih},
        hasMilestone: false,
      );
      final some = atlasPlaces(registry, f, DateTime(2026));
      expect(some, isNotEmpty);
      for (final p in some) {
        expect(p.wave, Wave.byzantine);
        expect(p.categories, contains(Category.cistern));
        expect(p.district, District.fatih);
      }
      expect(AtlasFilter.decode(f.encode()), f);
      expect(AtlasFilter.decode('not json'), AtlasFilter.none);
      final milestones = atlasPlaces(
        registry,
        const AtlasFilter(hasMilestone: true),
        DateTime(2026),
      );
      final ids = {for (final m in registry.milestones) ...m.placeIds};
      expect(
        milestones.map((p) => p.id).toSet(),
        ids.intersection({for (final p in registry.plottablePlaces) p.id}),
      );
    });

    test('clusters partition the places at every zoom', () async {
      final registry = await _registry();
      final places = registry.plottablePlaces;
      for (final scale in [1 / 600, 1 / 60, 1 / 8, 1.0]) {
        final markers = clusterPlaces(
          places,
          AtlasView.peninsula.copyWith(scale: scale),
        );
        final ids = [
          for (final m in markers)
            for (final p in m.places) p.id,
        ];
        expect(ids.length, places.length);
        expect(ids.toSet(), {for (final p in places) p.id});
      }
    });
  });

  group('City tab', () {
    testWidgets('map and list show the same places under the same filter', (
      tester,
    ) async {
      await pumpShell(tester);
      await tester.tap(destination('City'));
      await tester.pump();
      await waitForAtlas(tester);
      expect(find.byType(AtlasMap), findsOneWidget);
      final map = tester.widget<AtlasMap>(find.byType(AtlasMap));
      final onMap = {
        for (final m in clusterPlaces(map.places, map.controller.view))
          for (final p in m.places) p.id,
      };

      await tester.tap(find.byKey(const ValueKey('city-mode')));
      await tester.pumpAndSettle();
      final listed = map.places.map((p) => p.id).toSet();
      expect(onMap, listed);
      expect(await _listedIds(tester, listed.length), listed);
    });

    testWidgets('a filter narrows map and list alike', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpShell(tester);
      await tester.tap(destination('City'));
      await tester.pump();
      await waitForAtlas(tester);
      await tester.tap(find.byKey(const ValueKey('city-filters')));
      await tester.pumpAndSettle();
      final cistern = find.widgetWithText(FilterChip, 'Cistern');
      await tester.ensureVisible(cistern);
      await tester.pumpAndSettle();
      await tester.tap(cistern);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter-show')));
      await tester.pumpAndSettle();
      // The button says how many filters are on; the badge is not read
      // alone (the A52s read it as "1").
      final button = tester
          .getSemantics(find.byKey(const ValueKey('city-filters')))
          .getSemanticsData();
      expect(button.tooltip, 'Filters · 1 on');
      expect(button.label, isEmpty);
      final map = tester.widget<AtlasMap>(find.byType(AtlasMap));
      expect(map.places, isNotEmpty);
      expect(
        map.places.every((p) => p.categories.contains(Category.cistern)),
        isTrue,
      );
      final onMap = {
        for (final m in clusterPlaces(map.places, map.controller.view))
          for (final p in m.places) p.id,
      };
      expect(onMap, map.places.map((p) => p.id).toSet());
      await tester.tap(find.byKey(const ValueKey('city-mode')));
      await tester.pumpAndSettle();
      expect(await _listedIds(tester, map.places.length), onMap);
      semantics.dispose();
    });

    testWidgets('the era slider animates through the years', (tester) async {
      await pumpShell(tester);
      await tester.tap(destination('City'));
      await tester.pump();
      await waitForAtlas(tester);
      final map = tester.widget<AtlasMap>(find.byType(AtlasMap));
      final c = map.controller;
      expect(c.year, 2026);
      final slider = tester.getRect(find.byKey(const ValueKey('atlas-time')));
      await tester.tapAt(Offset(slider.left + 30, slider.center.dy));
      await tester.pump();
      expect(c.stop, 0);
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.year, inExclusiveRange(330, 2026)); // under way
      await tester.pumpAndSettle();
      expect(c.year, 330);
      expect(find.textContaining('Constantine’s new city'), findsOneWidget);
    });

    testWidgets('the layers sheet lists what stands, with sources', (
      tester,
    ) async {
      await pumpShell(tester);
      await tester.tap(destination('City'));
      await tester.pump();
      await waitForAtlas(tester);
      await tester.tap(find.byKey(const ValueKey('atlas-layers')));
      await tester.pumpAndSettle();
      expect(find.text('Wall of Manuel Komnenos'), findsOneWidget);
      expect(
        find.textContaining('Walls of Constantinople — Wikipedia'),
        findsWidgets,
      );
      await tester.scrollUntilVisible(
        find.text('Theodosian Walls'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      // Below, today: the cisterns.
      await tester.tap(find.byKey(const ValueKey('atlas-below')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('atlas-layers')));
      await tester.pumpAndSettle();
      expect(find.text('Basilica Cistern'), findsOneWidget);
      expect(find.text('Theodosian Walls'), findsNothing);
    });

    testWidgets('map markers are buttons for TalkBack', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpShell(tester);
      await tester.tap(destination('City'));
      await tester.pump();
      await waitForAtlas(tester);
      final map = tester.widget<AtlasMap>(find.byType(AtlasMap));
      map.controller.settle();
      await tester.pump();
      final buttons = <String>[];
      void visit(SemanticsNode n) {
        final d = n.getSemanticsData();
        if (d.flagsCollection.isButton && d.hasAction(SemanticsAction.tap)) {
          buttons.add(d.label);
        }
        n.visitChildren((c) {
          visit(c);
          return true;
        });
      }

      // The canvas's node and its descendants: the markers the painter adds.
      var root = tester.getSemantics(
        find.byKey(const ValueKey('atlas-canvas')),
      );
      while (root.parent != null) {
        root = root.parent!;
      }
      visit(root);
      expect(buttons.where((l) => l.contains('places here')), isNotEmpty);
      // Single places read their name, kind and distance in Roman miles.
      expect(buttons.where((l) => l.contains('Cistern of Mocius')), isNotEmpty);
      expect(
        buttons.where((l) => l.contains(' mil · ')).length,
        greaterThan(5),
      );
      semantics.dispose();
    });
  });

  // Visual check, off by default: ATLAS_RENDER=1 flutter test test/atlas_test.dart
  // writes the peninsula in each era to studio/cache/atlas/render/.
  testWidgets('render the peninsula by era', (tester) async {
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await loadThemeFonts(tester);
    final assets = _assets();
    final controller = AtlasController();
    final registry = await tester.runAsync(_registry);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: DesignTheme.marble,
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: AtlasMap(
              assets: assets,
              controller: controller,
              places: registry!.plottablePlaces,
            ),
          ),
        ),
      ),
    );
    final out = Directory('studio/cache/atlas/render')
      ..createSync(recursive: true);
    for (final year in [330, 537, 1453, 1560, 1900, 2026]) {
      controller.year = year.toDouble();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return data!.buffer.asUint8List();
      });
      File('${out.path}/peninsula_$year.png').writeAsBytesSync(bytes!);
    }
    controller.dispose();
  }, skip: Platform.environment['ATLAS_RENDER'] != '1');
}

/// The ids of the list's rows, scrolling until [count] have been built.
Future<Set<String>> _listedIds(WidgetTester tester, int count) async {
  final rows = find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('city-place-'),
  );
  final seen = <String>{};
  for (var i = 0; i < 80; i++) {
    for (final e in rows.evaluate()) {
      seen.add((e.widget.key! as ValueKey<String>).value.substring(11));
    }
    if (seen.length >= count) break;
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pump();
  }
  return seen;
}
