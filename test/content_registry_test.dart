import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/bundled_content.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/prediction_map.dart';
import 'package:milion/content/registry.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/services/notes_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> fixture(String name) async =>
    jsonDecode(await File('test/fixtures/content/$name.json').readAsString())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'seed identity, coordinate evidence and phase coverage stay linked',
    () async {
      final registry = await ContentRepository((p) => File(p).readAsString())
          .load();
      Future<Map<String, dynamic>> audit(String name) async =>
          jsonDecode(await File('tool/content/$name.json').readAsString())
              as Map<String, dynamic>;
      final verified = (await audit('verification'))['places'] as List;
      final coverage = await audit('phase_place_coverage');
      final ids = registry.places.map((p) => p.id).toSet();
      expect((coverage['places'] as List).map((p) => p['id']).toSet(), ids);
      expect(verified.map((p) => p['id']).toSet(), ids);
      for (final alias in [...coverage['aliases'], ...coverage['components']]) {
        expect(ids, contains(alias['place']));
      }
      for (final place in registry.places) {
        final evidence = verified.singleWhere((p) => p['id'] == place.id);
        final entity = jsonDecode(
          await File('tool/content/evidence/${place.qid}.json').readAsString(),
        ) as Map<String, dynamic>;
        expect(entity['id'], place.qid);
        expect(entity['lastrevid'], evidence['revision']);
        expect(evidence['coordinates'], {
          'lat': place.coordinates.lat,
          'lng': place.coordinates.lng,
        });
        if ((evidence['coordinateSource'] as String).contains('wikidata.org')) {
          final claims = entity['claims']['P625'] as List;
          expect(
            claims.any((c) {
              final value = c['mainsnak']['datavalue']?['value'];
              return value?['latitude'] == place.coordinates.lat &&
                  value?['longitude'] == place.coordinates.lng;
            }),
            isTrue,
            reason: place.id,
          );
        }
        expect(place.names.tr, isNotEmpty);
        expect(place.hook.tr, isNotEmpty);
      }
      final seeds = await audit('editorial_seeds');
      final sourceIds = registry.sources.map((s) => s.id).toSet();
      for (final pool in ['daily', 'onThisDay']) {
        expect((seeds[pool] as List).length, greaterThanOrEqualTo(3));
        for (final seed in seeds[pool]) {
          expect(ids, contains(seed['place']));
          expect(sourceIds, containsAll(seed['sources']));
          expect(seed['review'], 'draft');
          expect(seed['text']['en'], isNotEmpty);
          expect(seed['text']['tr'], isNotEmpty);
        }
      }
    },
  );

  test(
    'valid fixture exercises every typed record and missing TR is counted',
    () async {
      final data = await fixture('valid');
      final report = validateContent(data);
      expect(report.errors, isEmpty);
      expect(report.missingTurkish.length, 1);
      final registry = ContentRegistry.fromJson(data);
      expect(registry.hunts.single.routeId, registry.routes.single.id);
      expect(registry.places.single.strata.single.era, Era.byzantine);
      expect(registry.media.single.historicalPhoto, isFalse);
      expect(registry.artworks.single.title.inLanguage('tr'), 'Anastasis');
    },
  );

  test(
    'invalid fixture reports duplicates, district, bounds, EN and references',
    () async {
      final report = validateContent(await fixture('invalid'));
      expect(report.isValid, isFalse);
      for (final message in [
        'duplicate global id',
        'district',
        'outside Istanbul',
        'en',
        'unknown sources',
      ]) {
        expect(report.errors.join('\n'), contains(message));
      }
    },
  );

  test(
    'rejects unknown schema, unsafe paths, invalid dates and codes',
    () async {
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (j) => j['schemaVersion'] = 99,
        (j) => j['places'][0]['unexpected'] = true,
        (j) => j['places'][0]['status'] = {'value': 'open', 'checkedAt': null},
        (j) => j['places'][0]['status'] = {
          'value': 'open',
          'checkedAt': '2026-02-30',
        },
        (j) => j['places'][0]['entrance'] = {'lat': 0, 'lng': 0},
        (j) => j['places'][0]['coordinates']['lat'] = double.infinity,
        (j) => j['places'][0]['strata'][0]['toYear'] = 1,
        (j) => j['milestones'][0]['techniques'] = ['NOPE'],
        (j) => j['milestones'][0]['honesty'] = ['DEPTH'],
        (j) => j['media'][0]['path'] = 'assets/../secret',
        (j) => j['sources'][0]['url'] = 'file:///secret',
      ]) {
        final data = await fixture('valid');
        mutate(data);
        expect(validateContent(data).isValid, isFalse);
        expect(() => ContentRegistry.fromJson(data), throwsFormatException);
      }
    },
  );

  test(
    'outside bonus requires a flag and no fabricated Istanbul district',
    () async {
      final data = await fixture('valid');
      final place = data['places'][0];
      place['coordinates'] = {'lat': 45.434, 'lng': 12.339};
      place['outsideProvince'] = true;
      place['district'] = null;
      expect(validateContent(data).errors, isEmpty);
      place['district'] = 'fatih';
      expect(validateContent(data).isValid, isFalse);
    },
  );

  test(
    '103 Chora artworks load without any model asset or ONNX session',
    () async {
      final requested = <String>[];
      final repository = ContentRepository((path) {
        requested.add(path);
        expect(path, startsWith('assets/content/'));
        return File(path).readAsString();
      });
      final registry = await repository.load();
      expect(identical(await repository.load(), registry), isTrue);
      expect(registry.artworks.length, 103);
      expect(registry.artworks.every((a) => a.placeId == 'chora'), isTrue);
      expect(
        registry.places.where((p) => p.review == ReviewStatus.draft).length,
        greaterThanOrEqualTo(90),
      );
      expect(
        registry.places.every((p) => RegExp(r'^Q\d+$').hasMatch(p.qid)),
        isTrue,
      );
      expect(registry.placesByDistance(), isEmpty);
      expect(registry.placesByDistance(includeDrafts: true).first.id, 'milion');
      expect(District.values.length, 39);
      expect(requested.where((p) => p.contains('model')), isEmpty);
      expect(
        registry.milestones.singleWhere((m) => m.numeral == 'I').artworkIds,
        ['F02'],
      );
      expect(
        registry.milestones.singleWhere((m) => m.numeral == 'II').artworkIds,
        ['F05'],
      );
      final legacy = await fixture('legacy_chora');
      for (final row in legacy['map']) {
        final artwork = registry.artwork(row['scene_id']);
        final scene = sceneForArtwork(artwork);
        final info = legacy['info'][scene.id];
        expect(scene.title, row['title']);
        expect(scene.room, row['room']);
        expect(scene.surface, row['surface']);
        expect(scene.folder, row['scene_folder']);
        expect(scene.summary, info['summary']);
        expect(scene.cues, info['cues']);
        expect(scene.position, info['position']);
        expect(scene.artworkType, info['artwork_type']);
      }
      final classes = (jsonDecode(
        await File('assets/model/classes.json').readAsString(),
      ) as List).cast<String>();
      final map = PredictionMap(classes, registry);
      expect(map.artworkIdAt(0), classes.first);
      final reordered = PredictionMap(classes.reversed.toList(), registry);
      expect(reordered.artworkIdAt(0), classes.last);
      expect(map.artworkIdAt(0), classes.first);
      expect(registry.artworks.length, 103);
      expect(() => PredictionMap(['missing'], registry), throwsFormatException);
      expect(
        () => PredictionMap(['F02', 'F02'], registry),
        throwsFormatException,
      );
    },
  );

  test(
    'v0 notes survive migration for every artwork, including I and II',
    () async {
      final registry = await ContentRepository((p) => File(p).readAsString())
          .load();
      final before = {
        for (final a in registry.artworks)
          'scene_note_${a.id}': '  ${a.id} İstanbul Η Χώρα\nNote  ',
      };
      SharedPreferences.setMockInitialValues({...before, 'unrelated': 'keep'});
      final notes = NotesService();
      for (final a in registry.artworks) {
        expect(await notes.noteFor(a.id), before['scene_note_${a.id}']);
      }
      expect(
        await notes.notedSceneIds(),
        registry.artworks.map((a) => a.id).toSet(),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('scene_notes_schema_version'), 1);
      for (final entry in before.entries) {
        expect(prefs.getString(entry.key), entry.value);
      }
      expect(await NotesService().noteFor('F02'), before['scene_note_F02']);
      await notes.saveNote('F05', ' Updated İ ');
      expect(await NotesService().noteFor('F05'), 'Updated İ');
      await notes.saveNote('F05', ' ');
      expect(await notes.noteFor('F05'), '');
      expect(prefs.getString('unrelated'), 'keep');
    },
  );

  test('future notes schema is rejected without overwriting data', () async {
    SharedPreferences.setMockInitialValues({
      'scene_notes_schema_version': 2,
      'scene_note_F02': 'Keep',
    });
    await expectLater(
      NotesService().saveNote('F02', 'Changed'),
      throwsStateError,
    );
    expect(
      (await SharedPreferences.getInstance()).getString('scene_note_F02'),
      'Keep',
    );
  });

  test(
    'repository rejects invalid index and document versions before parsing',
    () async {
      final base = jsonDecode(
        await File('assets/content/index.json').readAsString(),
      ) as Map<String, dynamic>;
      base['files']['places'] = ['assets/content/../secret.json'];
      await expectLater(
        readContent((p) async => jsonEncode(base)),
        throwsFormatException,
      );
      var calls = 0;
      final repository = ContentRepository((p) async {
        calls++;
        if (calls == 1) throw const FormatException('corrupt download');
        return File(p).readAsString();
      });
      await expectLater(repository.load(), throwsFormatException);
      expect((await repository.load()).artworks.length, 103);
    },
  );
}
