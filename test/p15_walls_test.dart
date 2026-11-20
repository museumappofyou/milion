import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/atlas/atlas_assets.dart';
import 'package:milion/atlas/atlas_data.dart';
import 'package:milion/atlas/atlas_filter.dart' show PlaceYears;
import 'package:milion/atlas/historic.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/l10n/app_localizations.dart';
import 'package:milion/shell/app_scope.dart';
import 'package:milion/siege/siege.dart';
import 'package:milion/siege/siege_controller.dart';
import 'package:milion/siege/siege_player.dart';
import 'package:milion/walls/wall_controller.dart';
import 'package:milion/walls/wall_player.dart';
import 'package:milion/walls/wall_strip.dart';

import 'helpers.dart' show loadThemeFonts;
import 'p04_content_test.dart' show loadRegistry;

Future<String> _read(String path) => File(path).readAsString();

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

/// P15 against the shipped content: XVIII's strip, XIX's map sequence, the
/// six places and the "Walk the walls" seed.
void main() {
  late ContentRegistry registry;
  late WallStripManifest strip;
  late SiegeManifest siege;
  setUpAll(() async {
    registry = await loadRegistry();
    strip = (await WallStripCatalog.load(registry, _read)).strip('land-walls')!;
    siege = (await SiegeCatalog.load(registry, _read)).map('1453')!;
  });

  group('XVIII, the land walls as a strip', () {
    test('the line runs about 6.5 km, Theodosian then Komnenian, chainage '
        'rising', () {
      expect(strip.length, inInclusiveRange(6400, 6700));
      for (var i = 1; i < strip.line.length; i++) {
        expect(strip.line[i].at, greaterThanOrEqualTo(strip.line[i - 1].at));
      }
      final kinds = strip.segments.map((s) => s.kind).toList();
      expect(kinds, [
        WallSegmentKind.triple,
        WallSegmentKind.triple,
        WallSegmentKind.double,
        WallSegmentKind.single,
      ]);
      expect(strip.segments.first.from, 0);
      expect(strip.segments.last.to, strip.length);
      for (var i = 1; i < strip.segments.length; i++) {
        expect(strip.segments[i].from, strip.segments[i - 1].to);
      }
      // The double wall ends at the palace, about 5.7–5.8 km.
      expect(strip.segments[2].to, inInclusiveRange(5600, 5900));
    });

    test('the cross-section is contiguous, outside in, with the moat '
        'below the field', () {
      final l = strip.layers;
      expect(l.map((x) => x.kind), [
        WallLayerKind.moat,
        WallLayerKind.breastwork,
        WallLayerKind.terrace,
        WallLayerKind.outerWall,
        WallLayerKind.peribolos,
        WallLayerKind.innerWall,
      ]);
      for (var i = 1; i < l.length; i++) {
        expect(l[i].from, l[i - 1].to);
      }
      // About 60 m deep (van Millingen: 58–63 m); the moat about 7 m deep,
      // not the popular 10 m.
      expect(l.last.to, inInclusiveRange(58, 63));
      expect(l.first.height, -7);
      expect(WallSegmentKind.single.shows(WallLayerKind.moat), isFalse);
      expect(WallSegmentKind.double.shows(WallLayerKind.outerWall), isTrue);
    });

    test('98 great towers from the survey; the outer ones placed, never at a '
        'gate', () {
      final inner = strip.towers.where((t) => t.wall == 'inner').toList();
      final outer = strip.towers.where((t) => t.wall == 'outer').toList();
      expect(inner.length, 98);
      expect(inner.every((t) => t.surveyed && t.number != null), isTrue);
      expect(outer, isNotEmpty);
      expect(outer.every((t) => !t.surveyed), isTrue);
      final openings = strip.gates
          .where((g) => g.kind == 'public' || g.kind == 'military')
          .map((g) => g.at);
      for (final t in outer) {
        for (final o in openings) {
          expect((t.at - o).abs(), greaterThan(25), reason: '${t.at}');
        }
      }
    });

    test('the gates run in order; the Kerkoporta is a legend\'s marker', () {
      final ids = strip.gates.map((g) => g.id).toList();
      expect(ids.indexOf('golden-gate'), lessThan(ids.indexOf('xylokerkos')));
      expect(ids.indexOf('st-romanus'), lessThan(ids.indexOf('pempton')));
      expect(ids.indexOf('pempton'), lessThan(ids.indexOf('charisius')));
      expect(ids.indexOf('charisius'), lessThan(ids.indexOf('kerkoporta')));
      final k = strip.gate('kerkoporta');
      expect(k.legend, isTrue);
      expect(k.positionNote, isNotNull);
      expect(strip.gate('golden-gate').placeId, 'yedikule');
      expect(strip.gate('tekfur').placeId, 'tekfur-palace');
      for (final id in ['golden-gate', 'rhegion', 'st-romanus']) {
        expect(registry.mediaItem(strip.gate(id).photo!), isNotNull);
      }
    });

    test('a GPS fix at a gate scrolls the strip to it; far away it does '
        'not', () {
      for (final g in strip.gates) {
        final hit = strip.locate(Coordinates(g.lat, g.lng));
        expect(hit.at, closeTo(g.at, 2), reason: g.id);
        expect(hit.off, lessThan(WallPlayerState.onSiteMetres));
      }
      final hagiaSophia = strip.locate(const Coordinates(41.0086, 28.98));
      expect(hagiaSophia.off, greaterThan(WallPlayerState.onSiteMetres));
    });

    test('the reveal flings the whole wall, Marmara to Golden Horn; steps '
        'go gate to gate', () {
      final c = WallController(strip)..play();
      var last = c.at;
      for (var t = 0.0; t < strip.revealSeconds; t += .5) {
        c.advance(.5);
        expect(c.at, greaterThanOrEqualTo(last));
        last = c.at;
      }
      expect(c.mode, WallMode.explore);
      expect(c.at, closeTo(strip.length, 1));
      // The glide still travels in its last five seconds (a cubic tail sat
      // on the last 200 m).
      final tail = WallController(strip)
        ..play()
        ..advance(strip.revealSeconds - 5);
      expect(tail.at, lessThan(strip.length - 600));
      c.goTo(0);
      c.step(1);
      expect(c.at, strip.gates.first.at);
      c.step(1);
      expect(c.at, strip.gates[1].at);
      c.step(-1);
      expect(c.at, strip.gates.first.at);
    });

    testWidgets('the strip opens, names its honesty and opens a gate', (
      tester,
    ) async {
      await loadThemeFonts(tester);
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(registry, WallPlayer(strip: strip)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('walls-honesty')), findsOneWidget);
      expect(find.byKey(const ValueKey('walls-scale-note')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('walls-gates')));
      await tester.pumpAndSettle();
      // Kerkoporta is the thirteenth of fifteen: built, but below the fold.
      final kerkoporta = find.byKey(const ValueKey('walls-gate-kerkoporta'));
      await tester.scrollUntilVisible(
        kerkoporta,
        120,
        scrollable: find
            .descendant(
              of: find.byType(WallSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(kerkoporta);
      await tester.pumpAndSettle();
      await tester.tap(kerkoporta);
      await tester.pumpAndSettle();
      final player = tester.state<WallPlayerState>(find.byType(WallPlayer));
      expect(player.controller.at, strip.gate('kerkoporta').at);
    });
  });

  group('XIX, 1453 in 53 days', () {
    test('6 April to 29 May: 54 days on the scale, 53 days on', () {
      expect(siege.days, 54);
      expect(siege.dateOf(1), DateTime(1453, 4, 6));
      expect(siege.dateOf(17), DateTime(1453, 4, 22));
      expect(siege.dateOf(siege.days), DateTime(1453, 5, 29));
    });

    test('every event is attributed; each side speaks', () {
      final sides = <AccountSide>{};
      for (final e in siege.events) {
        expect(e.accounts, isNotEmpty, reason: e.id);
        sides.addAll(e.accounts.map((a) => a.side));
      }
      expect(
        sides,
        containsAll([
          AccountSide.byzantine,
          AccountSide.venetian,
          AccountSide.genoese,
          AccountSide.ottoman,
          AccountSide.ottomanGreek,
          AccountSide.modern,
        ]),
      );
      final ships = siege.event('ships-overland');
      expect(ships.certainty, Certainty.conjectural);
      expect(registry.mediaItem(ships.photo!), isNotNull);
      final k = siege.event('kerkoporta');
      expect((k.kind, k.certainty), ('legend', Certainty.conjectural));
      expect(k.accounts.map((a) => a.side), contains(AccountSide.byzantine));
    });

    test('no view, beat or finger shows past the drawn base', () {
      final frame = siegeFrameMetres(siege);
      void inside(SiegeView v, Size size, String why) {
        final f = fitView(v, size, siege);
        final c = projectMetres(f.lat, f.lng);
        final h = f.width * size.height / size.width;
        expect(
          c.dx - f.width / 2,
          greaterThanOrEqualTo(frame.left - .5),
          reason: why,
        );
        expect(
          c.dx + f.width / 2,
          lessThanOrEqualTo(frame.right + .5),
          reason: why,
        );
        expect(c.dy - h / 2, greaterThanOrEqualTo(frame.top - .5), reason: why);
        expect(c.dy + h / 2, lessThanOrEqualTo(frame.bottom + .5), reason: why);
      }

      // The A52s's map (1080 × 1814 px) and a squat landscape one.
      for (final size in const [Size(412, 692), Size(800, 360)]) {
        inside(siege.home, size, 'home $size');
        inside(siege.revealView, size, 'reveal $size');
        for (final b in siege.beats) {
          inside(b.view, size, '${b.id} $size');
        }
        inside(SiegeView.of(41.2, 29.3, 40000), size, 'far out $size');
      }
      // On the phone the home view needs no change: the frame covers it.
      final home = fitView(siege.home, const Size(412, 692), siege);
      expect(home, same(siege.home));
      // Fingers stop at the edge.
      final c = SiegeController(siege)..viewport = const Size(412, 692);
      for (var i = 0; i < 20; i++) {
        c.zoomBy(.5);
        c.panBy(-5000, -5000);
      }
      inside(c.view, const Size(412, 692), 'after pinching out');
      expect(c.view.width, lessThan(16000));
    });

    test('the reveal hauls the ships over the hill; the day scale clamps', () {
      final c = SiegeController(siege)..play();
      final ships = siege.event('ships-overland');
      expect(c.day, ships.day);
      expect(c.progress(ships), 0);
      c.advance(siege.revealSeconds / 2);
      expect(c.progress(ships), inExclusiveRange(0, 1));
      c.advance(siege.revealSeconds);
      expect(c.mode, SiegeMode.explore);
      c.setDay(999);
      expect(c.day, siege.days);
      expect(c.shown.map((e) => e.id), contains('final-assault'));
      c.setDay(13);
      expect(c.shown.map((e) => e.id), contains('assault-18-april'));
      c.setDay(14);
      expect(c.shown.map((e) => e.id), isNot(contains('assault-18-april')));
    });

    testWidgets('the map draws over the Atlas and lists the accounts', (
      tester,
    ) async {
      await loadThemeFonts(tester);
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final atlas = AtlasAssets.decodeSync(
        ByteData.sublistView(File(AtlasData.assetPath).readAsBytesSync()),
        File(HistoricAtlas.assetPath).readAsStringSync(),
        File(PlaceYears.assetPath).readAsStringSync(),
      );
      await tester.pumpWidget(
        _host(registry, SiegePlayer(siege: siege, atlas: Future.value(atlas))),
      );
      final player = tester.state<SiegePlayerState>(find.byType(SiegePlayer));
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && player.base == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pumpAndSettle();
      expect(player.base, isNotNull);
      expect(find.byKey(const ValueKey('siege-honesty')), findsOneWidget);
      expect(find.text('The siege begins'), findsOneWidget);
      player.controller.goTo(siege.beat('overland'));
      await tester.tap(find.byKey(const ValueKey('siege-accounts')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('siege-event-ships-overland')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('siege-original-ships-overland')),
        findsOneWidget,
      );
      expect(find.textContaining('Venetian'), findsWidgets);
      // No witness gives the route: the line is marked as one reading.
      expect(
        find.byKey(const ValueKey('siege-imagined-ships-overland')),
        findsOneWidget,
      );
      expect(find.text('16 days in'), findsOneWidget);
    });
  });

  group('the walls\' places and the walk', () {
    test(
      'six places with dated strata; two reviewed with pinned entrances',
      () {
        const ids = [
          'land-walls',
          'yedikule',
          'tekfur-palace',
          'anemas-prisons',
          'rumeli-hisari',
          'anadolu-hisari',
        ];
        for (final id in ids) {
          final p = registry.place(id)!;
          expect(p.strata.length, greaterThanOrEqualTo(2), reason: id);
        }
        for (final id in ['land-walls', 'yedikule']) {
          final p = registry.place(id)!;
          expect(p.review, ReviewStatus.reviewed, reason: id);
          expect(p.entrance, isNotNull);
          expect(p.status.checkedAt, isNotNull);
        }
        for (final id in ids.skip(2)) {
          final p = registry.place(id)!;
          expect(p.review, ReviewStatus.draft, reason: id);
          expect(p.tags, contains('entrance-unverified'), reason: id);
        }
        expect(registry.place('tekfur-palace')!.visit?.weekly, isNotEmpty);
      },
    );

    test('"Walk the walls" is seeded in three sections for P21', () {
      final walls = registry.routes.where((r) => r.id.startsWith('walls-'));
      expect(walls.map((r) => r.id), [
        'walls-1-marmara-topkapi',
        'walls-2-topkapi-edirnekapi',
        'walls-3-edirnekapi-ayvansaray',
      ]);
      expect(walls.every((r) => r.placeIds.contains('land-walls')), isTrue);
    });

    test('XVIII and XIX play from their manifests', () {
      final xviii = registry.milestone('milestone-xviii')!;
      final xix = registry.milestone('milestone-xix')!;
      expect(xviii.manifestPath, 'assets/walls/land-walls/strip.json');
      expect(xix.manifestPath, 'assets/siege/1453/siege.json');
      for (final m in [xviii, xix]) {
        expect(m.status, MilestoneStatus.prototype);
        expect(m.honesty, contains(Honesty.ORIGINAL));
      }
    });
  });
}
