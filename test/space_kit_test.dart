import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/design/components.dart';
import 'package:milion/l10n/strings.dart';
import 'package:milion/space/catalog.dart';
import 'package:milion/space/model.dart';
import 'package:milion/space/player.dart';
import 'package:milion/space/study.dart';

import 'helpers.dart' show loadThemeFonts;
import 'p05_dig_test.dart' show loadRegistry;
import 'space_engine_test.dart' show signedVolume;
import 'space_player_test.dart' show fileBytes, space, openPanel;

/// The kit buildings (`studio/space/<id>.yaml`): P09's three and P11's Chora.
const kit = ['bodrum-camii', 'kucuk-ayasofya', 'sehzade-camii', 'kariye-camii'];

Map<String, dynamic> manifestJson(String id) =>
    jsonDecode(File('assets/space/$id/study.json').readAsStringSync())
        as Map<String, dynamic>;
SpaceStudy kitStudy(String id) => SpaceStudy.fromJson(manifestJson(id));
SpaceModel kitModel(SpaceStudy s) =>
    SpaceModel.fromGlb(ByteData.sublistView(File(s.model).readAsBytesSync()));

Future<void> openSpace(WidgetTester tester, SpaceStudy study) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await loadThemeFonts(tester);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SpacePlayer(study: study, loadBytes: fileBytes),
    ),
  );
  await tester.runAsync(() async {
    for (var i = 0; i < 150; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump();
      if (find.byType(TesseraLoader).evaluate().isEmpty) break;
    }
  });
  await tester.pump();
}

void main() {
  test(
    'each kit building loads from its meshopt glb: closed, within budget',
    () {
      for (final id in kit) {
        final study = kitStudy(id), model = kitModel(study);
        study.checkModel(model);
        expect(
          model.triangleCount,
          lessThanOrEqualTo(SpaceStudy.triangleBudget),
        );
        for (final p in model.parts) {
          expect(p.closed, isTrue, reason: '$id ${p.id}');
          expect(signedVolume(p), greaterThan(0), reason: '$id ${p.id}');
          expect(p.ao.every((a) => a >= 0 && a <= 1), isTrue, reason: p.id);
        }
        // The same parts and triangles the Python builder reported.
        final report = jsonDecode(
          File('studio/space/$id.report.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        expect({
          for (final p in model.parts) p.id: p.triangleCount,
        }, report['byPart']);
        // Drawn in the building's own frame, its axis cited.
        final o = study.orientation!;
        expect(study.citations.map((c) => c.id), contains(o.sourceId));
        expect(study.choisy.elevationDegrees, -50);
        expect(study.placeId, isNotNull);
      }
    },
  );

  test('the kit models really are compressed', () {
    for (final id in kit) {
      final bytes = File('assets/space/$id/model.glb').readAsBytesSync();
      final data = ByteData.sublistView(bytes);
      final json = utf8.decode(
        bytes.sublist(20, 20 + data.getUint32(12, Endian.little)),
      );
      final doc = jsonDecode(json) as Map<String, dynamic>;
      expect(doc['extensionsRequired'], ['EXT_meshopt_compression']);
      final views = (doc['bufferViews'] as List).cast<Map<String, dynamic>>();
      expect(
        views.every((v) => (v['extensions'] as Map).isNotEmpty),
        isTrue,
        reason: id,
      );
    }
  });

  test('the index lists every study and places own the kit ones', () async {
    final registry = await loadRegistry();
    final catalog = await SpaceCatalog.load(
      registry,
      (p) => File(p).readAsString(),
    );
    expect(catalog.studies.map((s) => s.id).toSet(), {
      'how-a-dome-stands',
      ...kit,
    });
    expect(catalog.forPlace('sehzade').single.id, 'sehzade-camii');
    expect(catalog.forPlace('little-hagia-sophia').single.id, 'kucuk-ayasofya');
    expect(catalog.forPlace('bodrum-mosque').single.id, 'bodrum-camii');
    expect(catalog.forPlace('chora').single.id, 'kariye-camii');
    expect(catalog.study('how-a-dome-stands')!.placeId, isNull);
    // A study that names no registry place is refused.
    final orphan = await SpaceCatalog.load(
      registry,
      (p) async => (await File(p).readAsString()).replaceFirst(
        '"place": "sehzade"',
        '"place": "nowhere"',
      ),
      strict: false,
    );
    expect(orphan.study('sehzade-camii'), isNull);
    expect(orphan.errors.single, contains('unknown place'));
  });

  testWidgets('a kit study opens in its Choisy view and cuts along its axes', (
    tester,
  ) async {
    await openSpace(tester, kitStudy('sehzade-camii'));
    final c = space(tester).controller!;
    expect(c.view.elevation, closeTo(-50 * math.pi / 180, 1e-9));
    expect(c.section, isTrue);
    expect(c.sectionOffset, closeTo(c.model.bounds.minZ + 8.5, 1e-6));
    expect(space(tester).renderer!.stats.poche, greaterThan(0));
    await openPanel(tester, 'space-section');
    expect(find.text('Long section'), findsOneWidget);
    expect(find.text('Cross section'), findsOneWidget);
    expect(find.text('North–south cut'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a study with one epoch has no time scrubber (P08 asserted)', (
    tester,
  ) async {
    final json = manifestJson('sehzade-camii');
    json['epochs'] = [(json['epochs'] as List).first];
    json['steps'] = [
      for (final s in (json['steps'] as List).cast<Map<String, dynamic>>())
        if ((s['epochs'] as List).isEmpty) s,
    ];
    final study = SpaceStudy.fromJson(json);
    expect(study.epochs, hasLength(1));
    await openSpace(tester, study);
    await openPanel(tester, 'space-assemble');
    expect(find.byKey(const ValueKey('space-assembly')), findsOneWidget);
    expect(find.byKey(const ValueKey('space-time')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('a study whose epoch has no steps is refused', () {
    final json = manifestJson('kucuk-ayasofya');
    json['steps'] = [
      for (final s in (json['steps'] as List).cast<Map<String, dynamic>>())
        if ((s['epochs'] as List).isEmpty) s,
    ];
    // 2026 still has the shared steps; empty it by giving them all to 536.
    for (final s in (json['steps'] as List).cast<Map<String, dynamic>>()) {
      s['epochs'] = [536];
    }
    expect(() => SpaceStudy.fromJson(json), throwsFormatException);
  });
}
