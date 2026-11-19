import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/l10n/app_localizations.dart';
import 'package:milion/section/section.dart';
import 'package:milion/section/section_controller.dart';
import 'package:milion/section/section_painter.dart';
import 'package:milion/section/section_player.dart';
import 'package:milion/shell/app_scope.dart';
import 'package:milion/shell/original_photo.dart';
import 'package:milion/walk/walk.dart';
import 'package:milion/walk/walk_catalog.dart';
import 'package:milion/walk/walk_controller.dart';
import 'package:milion/walk/walk_player.dart';
import 'package:milion/walk/walk_scene.dart';

import 'helpers.dart' show loadThemeFonts;
import 'p04_content_test.dart' show loadRegistry;

Future<String> _read(String path) => File(path).readAsString();

const _underground = [
  'basilica-cistern',
  'theodosius-cistern',
  'binbirdirek',
  'aetius-cistern',
  'aspar-cistern',
  'mocius-cistern',
  'nakilbent',
  'yenikapi',
];

Widget _host(ContentRegistry registry, Widget child) => AppScope(
  registry: registry,
  error: null,
  retry: () {},
  clock: DateTime.now,
  recognised: const {},
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

/// P14 against the shipped content: XVI's walk, XVII's section, the eight
/// underground places and the Atlas Below layer.
void main() {
  late ContentRegistry registry;
  late WalkManifest walk;
  late SectionManifest section;
  setUpAll(() async {
    registry = await loadRegistry();
    walk = (await WalkCatalog.load(registry, _read)).walk('basilica-cistern')!;
    section = (await SectionCatalog.load(registry, _read)).section('yenikapi')!;
  });

  group('XVI, the cistern walk', () {
    test('336 columns in 12 rows of 28, about 98 carved Corinthian', () {
      final g = walk.grid;
      expect((g.along, g.across, g.columns), (28, 12, 336));
      expect(walk.capitals.length, 336);
      expect(walk.capitals.split('').where((c) => c == 'C').length, 98);
      expect(walk.specials.map((s) => s.id), [
        'medusa-sideways',
        'medusa-inverted',
        'weeping-column',
      ]);
    });

    test('the model is the one the manifest pins, the faces are photographs '
        'of the heads', () {
      final bytes = File(walk.model).readAsBytesSync();
      expect(bytes.length, greaterThan(1000));
      for (final head in ['medusa-inverted', 'medusa-sideways']) {
        expect(File(walk.photos[head]!).existsSync(), isTrue, reason: head);
        final stop = walk.stop(head);
        final media = registry.mediaItem(stop.photo!)!;
        expect(File(media.path).existsSync(), isTrue);
        expect(stop.sourceIds, contains(media.sourceId));
      }
    });

    test('opens on the aisle; the reveal ends at the upside-down head', () {
      final c = WalkController(walk);
      expect(c.mode, WalkMode.explore);
      final aisle = walk.stop('aisle');
      expect(c.camera.eye.x, closeTo(aisle.eye.x, 1.5));
      c.play();
      expect(c.hallLight, 0);
      expect(c.visibleCallouts(), isEmpty);
      c.advance(1.5);
      expect(c.headLight, greaterThan(0));
      expect(c.hallLight, 0, reason: 'the head lights first, then the hall');
      c.advance(walk.revealSeconds);
      expect(c.mode, WalkMode.explore);
      expect(c.hallLight, 1);
      final end = c.camera;
      final head = walk.stop('medusa-inverted');
      expect(end.yaw, closeTo(WalkCamera(head.eye, head.look).yaw, 1e-6));
    });

    test('reduced motion: stills, no fish; fish read IMAGINED', () {
      final c = WalkController(walk)..setFish(true);
      expect(c.honesty, Honesty.IMAGINED);
      c.setReduced(true);
      expect(c.fish, isFalse);
      expect(c.honesty, walk.honesty);
      c.play();
      expect(c.mode, WalkMode.stills);
      c.step(-1);
      expect(c.currentStill.id, walk.stills.last);
    });

    test('leader lines project right-handed: +x to the right when looking '
        'down -z', () {
      const camera = WalkCamera(WalkPoint(0, 0, 0), WalkPoint(0, 0, -1));
      final p = WalkProjector(camera, 400, 800);
      final (x, _) = p.project(const WalkPoint(1, 0, -5))!;
      expect(x, greaterThan(200));
      expect(p.project(const WalkPoint(0, 0, 5)), isNull);
    });

    testWidgets('without Flutter GPU it shows the plan, and a stop opens its '
        'photograph as ORIGINAL', (tester) async {
      await loadThemeFonts(tester);
      await tester.pumpWidget(
        _host(registry, WalkPlayer(walk: walk, backend: false)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('walk-honesty')), findsOneWidget);
      final player = tester.state<WalkPlayerState>(find.byType(WalkPlayer));
      player.controller.stills(walk.stills.indexOf('medusa-inverted'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('walk-still-photo')));
      await tester.pumpAndSettle();
      expect(find.byType(OriginalPhotoPage), findsOneWidget);
      expect(find.text('ORIGINAL'), findsOneWidget);
      expect(find.textContaining('Carlos Reusser Monsalvez'), findsOneWidget);
    });
  });

  group('XVII, the harbour under the metro', () {
    test('37 wrecks, YK 1 to 37; the six galleys typed', () {
      expect(section.ships.map((s) => s.yk), [for (var i = 1; i <= 37; i++) i]);
      expect(
        section.ships
            .where((s) => s.type == ShipType.galley)
            .map((s) => s.yk)
            .toSet(),
        {2, 4, 13, 16, 25, 36},
      );
      final footprints = section.finds.firstWhere((f) => f.id == 'footprints');
      expect(registry.mediaItem(footprints.photo!), isNotNull);
    });

    test('the strata run from the station to the Neolithic without gaps', () {
      final s = section.strata;
      expect(s.first.from, section.top);
      expect(s.last.to, section.bottom);
      for (var i = 1; i < s.length; i++) {
        expect(s[i].from, s[i - 1].to, reason: s[i].id);
      }
    });

    test('the reveal digs down and lifts the ships; exploring lifts what '
        'the reading line passes', () {
      final c = SectionController(section)..play();
      final start = c.depth;
      c.advance(8);
      expect(c.depth, lessThan(start));
      final ship = section.ships.first;
      expect(c.lift('ship-${ship.yk}', ship.depth, ship: true), greaterThan(0));
      c.advance(section.revealSeconds);
      expect(c.mode, SectionMode.explore);
      final footprints = section.finds.firstWhere((f) => f.id == 'footprints');
      c.scroll(c.depth - footprints.depth);
      expect(c.lift(footprints.id, footprints.depth), 1);
    });

    testWidgets('a ship taps open its type; the ground is drawn once', (
      tester,
    ) async {
      await loadThemeFonts(tester);
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(registry, SectionPlayer(section: section)));
      await tester.pumpAndSettle();
      final player = tester.state<SectionPlayerState>(
        find.byType(SectionPlayer),
      );
      final c = player.controller;
      final yk4 = section.ships.firstWhere((s) => s.yk == 4);
      c.scroll(c.depth - yk4.depth);
      await tester.pump();
      final paint = find.byKey(const ValueKey('section-paint'));
      final box = tester.getRect(paint);
      final layout = SectionLayout(box.size, c.depth);
      final at = layout
          .ship(yk4)
          .shift(
            layout.raise(c.lift('ship-4', yk4.depth, ship: true), Offset.zero),
          )
          .center;
      expect(shipAt(c, box.size, at)?.yk, 4);
      await tester.tapAt(box.topLeft + at);
      await tester.pumpAndSettle();
      expect(find.text('YK 4'), findsWidgets);
      expect(find.textContaining('Galley'), findsOneWidget);
    });
  });

  group('the underground places', () {
    test('all eight reviewed, with dated, sourced strata in EN and TR', () {
      for (final id in _underground) {
        final place = registry.place(id)!;
        expect(place.review, ReviewStatus.reviewed, reason: id);
        expect(place.strata.length, greaterThanOrEqualTo(2), reason: id);
        for (final s in place.strata) {
          expect(s.sourceIds, isNotEmpty, reason: s.id);
          expect(s.body.tr?.trim(), isNotEmpty, reason: s.id);
        }
      }
    });

    test('Yenikapı is the Theodosian Harbour; Eleutherios is not asserted', () {
      final yk = registry.place('yenikapi')!;
      expect(yk.names.en, contains('Theodosian Harbour'));
      final harbour = yk.strata.firstWhere((s) => s.id == 'yk-harbour');
      expect(harbour.body.en, contains('disputed'));
    });

    test('every one is in the Atlas Below layer', () {
      final atlas = jsonDecode(
        File('assets/atlas/historic.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final below = jsonEncode(atlas);
      for (final id in [
        'below-basilica-cistern',
        'below-theodosius-cistern',
        'below-philoxenos',
        'below-aetius',
        'below-aspar',
        'below-mocius',
        'below-nakilbent',
        'below-yenikapi',
      ]) {
        expect(below, contains('"$id"'), reason: id);
      }
    });
  });
}
