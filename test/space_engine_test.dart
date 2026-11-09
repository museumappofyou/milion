import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/models.dart';
import 'package:milion/space/camera.dart';
import 'package:milion/space/capture.dart';
import 'package:milion/space/catalog.dart';
import 'package:milion/space/controller.dart';
import 'package:milion/space/model.dart';
import 'package:milion/space/renderer.dart';
import 'package:milion/space/study.dart';
import 'package:milion/space/style.dart';

import 'p05_dig_test.dart' show loadRegistry;

const _studyPath = 'assets/space/how-a-dome-stands/study.json';
Map<String, dynamic> studyJson() =>
    jsonDecode(File(_studyPath).readAsStringSync()) as Map<String, dynamic>;
SpaceStudy loadStudy() => SpaceStudy.fromJson(studyJson());
SpaceModel loadModel([
  String path = 'assets/space/how-a-dome-stands/model.glb',
]) => SpaceModel.fromGlb(ByteData.sublistView(File(path).readAsBytesSync()));

const _degree = math.pi / 180;

/// A one-node glb: a unit tetrahedron with a node transform, for the loader.
ByteData tetrahedronGlb({
  Map<String, Object?> node = const {},
  List<String> required = const [],
  int? aoCount,
}) {
  // Y-up glTF positions; counter-clockwise from outside.
  final positions = Float32List.fromList([0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1]);
  final indices = Uint16List.fromList([0, 2, 1, 0, 1, 3, 0, 3, 2, 1, 2, 3]);
  final ao = Float32List.fromList(List.filled(aoCount ?? 0, 1));
  final bin = BytesBuilder()
    ..add(positions.buffer.asUint8List())
    ..add(indices.buffer.asUint8List())
    ..add(ao.buffer.asUint8List());
  final length = 72 + ao.lengthInBytes;
  final doc = {
    'asset': {'version': '2.0'},
    'extensionsRequired': ?(required.isEmpty ? null : required),
    'scenes': [
      {
        'nodes': [0],
      },
    ],
    'nodes': [
      {'name': 'tet', 'mesh': 0, ...node},
    ],
    'meshes': [
      {
        'primitives': [
          {
            'attributes': {'POSITION': 0, '_AO': ?(aoCount == null ? null : 2)},
            'indices': 1,
          },
        ],
      },
    ],
    'accessors': [
      {'bufferView': 0, 'componentType': 5126, 'count': 4, 'type': 'VEC3'},
      {'bufferView': 1, 'componentType': 5123, 'count': 12, 'type': 'SCALAR'},
      if (aoCount != null)
        {
          'bufferView': 2,
          'componentType': 5126,
          'count': aoCount,
          'type': 'SCALAR',
        },
    ],
    'bufferViews': [
      {'buffer': 0, 'byteOffset': 0, 'byteLength': 48},
      {'buffer': 0, 'byteOffset': 48, 'byteLength': 24},
      if (aoCount != null)
        {'buffer': 0, 'byteOffset': 72, 'byteLength': ao.lengthInBytes},
    ],
    'buffers': [
      {'byteLength': length},
    ],
  };
  var json = utf8.encode(jsonEncode(doc));
  json = Uint8List.fromList([...json, ...List.filled(-json.length % 4, 0x20)]);
  final out = BytesBuilder();
  void u32(int v) => out.add(
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List(),
  );
  u32(0x46546C67);
  u32(2);
  u32(12 + 8 + json.length + 8 + length);
  u32(json.length);
  u32(0x4E4F534A);
  out.add(json);
  u32(length);
  u32(0x004E4942);
  out.add(bin.toBytes());
  return ByteData.sublistView(out.toBytes());
}

double signedVolume(SpacePart p) {
  var v = 0.0;
  final x = p.positions, t = p.triangles;
  for (var i = 0; i < t.length; i += 3) {
    final a = t[i] * 3, b = t[i + 1] * 3, c = t[i + 2] * 3;
    v +=
        x[a] * (x[b + 1] * x[c + 2] - x[b + 2] * x[c + 1]) -
        x[a + 1] * (x[b] * x[c + 2] - x[b + 2] * x[c]) +
        x[a + 2] * (x[b] * x[c + 1] - x[b + 1] * x[c]);
  }
  return v / 6;
}

void main() {
  group('model', () {
    test(
      'the shipped glb: closed solids, Z up, as many triangles as declared',
      () {
        final m = loadModel(), study = loadStudy();
        study.checkModel(m);
        expect(m.parts, hasLength(25));
        expect(m.triangleCount, study.triangles);
        expect(m.triangleCount, lessThanOrEqualTo(SpaceStudy.triangleBudget));
        for (final p in m.parts) {
          expect(p.closed, isTrue, reason: p.id);
          expect(signedVolume(p), greaterThan(0), reason: '${p.id} inside out');
          expect(p.ao.every((a) => a >= 0 && a <= 1), isTrue, reason: p.id);
        }
        // glTF is Y-up; the dome must come back on top, the piers on the floor.
        expect(m.part('dome')!.bounds.maxZ, m.bounds.maxZ);
        expect(m.part('pier-ne')!.bounds.minZ, closeTo(0, 1e-4));
        expect(m.bounds.maxZ, closeTo(56.4, .1));
        // The pendentive sphere meets the pier corner: (15.5, 15.5, 22).
        expect(m.part('pendentive-ne')!.bounds.maxX, closeTo(15.5, 1e-3));
        expect(m.part('pendentive-ne')!.bounds.minZ, closeTo(22, 1e-3));
      },
    );

    test(
      'node transforms apply, mirroring flips the winding, extensions refuse',
      () {
        final moved = SpaceModel.fromGlb(
          tetrahedronGlb(
            node: {
              'translation': [10, 0, 0],
            },
          ),
        ).parts.single;
        expect(moved.bounds.minX, 10);
        expect(signedVolume(moved), closeTo(1 / 6, 1e-6));
        // glTF +Y is our +Z, glTF +Z our −Y.
        expect(moved.bounds.maxZ, 1);
        expect(moved.bounds.minY, -1);
        final mirrored = SpaceModel.fromGlb(
          tetrahedronGlb(
            node: {
              'scale': [-1, 1, 1],
            },
          ),
        ).parts.single;
        expect(signedVolume(mirrored), closeTo(1 / 6, 1e-6));
        expect(
          () => SpaceModel.fromGlb(
            tetrahedronGlb(required: ['KHR_draco_mesh_compression']),
          ),
          throwsFormatException,
        );
        expect(() => SpaceModel.fromGlb(ByteData(24)), throwsFormatException);
        // An `_AO` accessor must give one value per vertex.
        expect(
          () => SpaceModel.fromGlb(tetrahedronGlb(aoCount: 3)),
          throwsFormatException,
        );
      },
    );
  });

  group('camera', () {
    final bounds = loadModel().bounds;
    final limits = SpaceLimits(bounds);

    test('limits: no view through the zenith, zoom and target bounded', () {
      final v = limits.clamp(
        const SpaceView(
          azimuth: -math.pi / 2,
          elevation: 2,
          zoom: 40,
          targetX: 1e4,
          targetZ: -50,
        ),
      );
      expect(v.elevation, closeTo(85 * _degree, 1e-9));
      expect(v.zoom, 6);
      expect(v.azimuth, closeTo(3 * math.pi / 2, 1e-9));
      expect(v.targetX, bounds.maxX);
      expect(v.targetZ, bounds.minZ);
      final low = limits.clamp(
        const SpaceView(elevation: -2, zoom: .01, azimuth: double.nan),
      );
      expect(low.elevation, closeTo(-70 * _degree, 1e-9));
      expect(low.zoom, .6);
      expect(low.azimuth, 0);
    });

    test("Choisy's preset looks up from below at the isometric angle", () {
      final v = SpaceView.choisy(bounds);
      expect(v.elevation, closeTo(-35.26 * _degree, 1e-9));
      expect(v.projection, SpaceProjection.axonometric);
      expect(limits.clamp(v), v);
      // From below, world up is still screen up, and undersides face us.
      final p = SpaceProjector(v, const Size(390, 700), bounds);
      expect(p.toScreen(0, 0, 50).dy, lessThan(p.toScreen(0, 0, 0).dy));
      expect(p.fz, greaterThan(0), reason: 'looking upward');
    });

    test('lerp takes the short way round and pan follows the finger', () {
      final a = const SpaceView(azimuth: 350 * _degree);
      final b = const SpaceView(azimuth: 10 * _degree);
      expect(SpaceView.lerp(a, b, .5).azimuth, closeTo(360 * _degree, 1e-9));
      final p = SpaceProjector(
        SpaceView.choisy(bounds),
        const Size(390, 700),
        bounds,
      );
      final before = p.toScreen(5, 5, 20);
      final moved = SpaceProjector(
        p.pan(const Offset(30, -12)),
        p.size,
        bounds,
      );
      final after = moved.toScreen(5, 5, 20);
      expect((after - before - const Offset(30, -12)).distance, lessThan(1e-3));
    });
  });

  group('timeline', () {
    final study = loadStudy();
    final timeline = SpaceTimeline(study);

    test(
      'one beat per step; a 35 s story and an 8 s reveal up to the dome',
      () {
        expect(timeline.beats, hasLength(study.steps.length));
        expect(study.storySeconds, 35);
        expect(timeline.revealBeats.last.step.id, 'dome');
        expect(timeline.revealBeats.last.end, closeTo(8, 1e-9));
        expect(timeline.at(0).moment.assembly, 0);
        for (final b in timeline.beats) {
          final m = timeline.at(b.still).moment;
          expect(
            m.assembly,
            timeline.stepIndex(b.step, b.epoch) + 1,
            reason: b.step.id,
          );
        }
        expect(() => timeline.at(double.nan), throwsFormatException);
      },
    );

    test(
      'the last step switches the time scrubber to 1548 and cross-fades',
      () {
        final last = timeline.beats.last;
        expect(last.step.id, 'four-semidomes');
        expect(study.epochs[last.epoch].year, 1548);
        final start = timeline.at(last.start + .01).moment;
        expect(study.epochs[start.fromEpoch!].year, 537);
        expect(start.blend, lessThan(.1));
        expect(timeline.at(last.still, reduced: true).moment.blend, 1);
        // The reveal turns the camera 30° and reduced motion does not.
        expect(timeline.at(8, reveal: true).turn, closeTo(30 * _degree, 1e-9));
        expect(timeline.at(8, reveal: true, reduced: true).turn, 0);
      },
    );
  });

  group('controller', () {
    final study = loadStudy(), model = loadModel();
    int index(String id) => model.parts.indexWhere((p) => p.id == id);

    test(
      'opens assembled, in Choisy view, with the plan cut and no caption',
      () {
        final c = SpaceController(study, model);
        expect(c.view, c.choisyView);
        expect(c.sectionPlane, SpaceSection(2, 3));
        expect(c.honesty, Honesty.RECONSTRUCTION);
        expect(c.caption, isNull);
        expect(c.needsTicker, isFalse, reason: 'nothing plays until asked');
        final parts = c.partStates();
        expect(parts[index('tympanum-n')].progress, 1);
        expect(parts[index('semidome-n')].progress, 0);
        expect(parts[index('semidome-e')].progress, 1);
      },
    );

    test('the time scrubber swaps walls for semi-domes, animated or not', () {
      final c = SpaceController(study, model)..setEpoch(1);
      expect(c.needsTicker, isTrue);
      var parts = c.partStates();
      expect(parts[index('tympanum-n')].progress, 1, reason: 'fades out');
      for (var i = 0; i < 20; i++) {
        c.advance(.1);
      }
      parts = c.partStates();
      expect(parts[index('tympanum-n')].progress, 0);
      expect(parts[index('semidome-n')].progress, 1);
      expect(c.needsTicker, isFalse);
      final reduced = SpaceController(study, model)
        ..setReduced(true)
        ..setEpoch(1);
      expect(reduced.partStates()[index('semidome-s')].progress, 1);
      expect(reduced.needsTicker, isFalse);
    });

    test(
      'assembly scrubbing drops parts in; the exploded view lifts by step',
      () {
        final c = SpaceController(study, model)..seekAssembly(2.5);
        var parts = c.partStates();
        expect(parts[index('arch-n')].progress, 1);
        final pendentive = parts[index('pendentive-ne')];
        expect(pendentive.progress, .5);
        expect(pendentive.dz, greaterThan(0), reason: 'still settling');
        expect(parts[index('ring')].progress, 0);
        expect(c.currentStep!.id, 'pendentives');
        c
          ..seekAssembly(c.steps.length.toDouble())
          ..setExplode(1);
        parts = c.partStates();
        expect(parts[index('pier-ne')].dz, 0);
        expect(parts[index('dome')].dz, greaterThan(parts[index('ring')].dz));
        expect(parts[index('pier-ne')].dx, greaterThan(0), reason: 'outward');
        c.seekAssembly(double.nan);
        expect(c.assembly, c.steps.length, reason: 'non-finite input ignored');
      },
    );

    test(
      'Next and Previous walk the story as stills; a drag hands it back',
      () {
        final c = SpaceController(study, model)..setReduced(true);
        c.play();
        expect(c.playing, isFalse);
        expect(c.sample!.beat.step.id, 'bay');
        expect(c.caption!.en, startsWith('A square bay 31 m wide'));
        for (var i = 1; i < study.steps.length; i++) {
          c.step(1);
        }
        expect(c.sample!.beat.step.id, 'four-semidomes');
        expect(c.visibleEpoch, 1);
        c.step(1);
        expect(c.sample!.beat.step.id, 'four-semidomes', reason: 'clamped');
        c.setView(c.view.orbit(.2, 0));
        expect(c.storyActive, isFalse);
        expect(c.epoch, 1);
        expect(c.assembly, c.steps.length);
      },
    );

    test('the reveal restores Choisy view and plays only when asked', () {
      final c = SpaceController(study, model)
        ..setSection(false)
        ..setView(const SpaceView(elevation: .8));
      c.playReveal();
      expect(c.playing, isTrue);
      expect(c.view, c.revealView);
      // P08's bay keeps the framing it was tuned to: Choisy's view at 1.3×.
      expect(c.view.zoom, closeTo(1.3, .01));
      expect(c.view.targetX, closeTo(c.choisyView.targetX, 1e-3));
      expect(c.view.targetZ, closeTo(c.choisyView.targetZ, 1e-3));
      expect(c.sectionPlane, SpaceSection(2, 3));
      expect(c.caption, study.reveal.caption);
      for (var i = 0; i < 90; i++) {
        c.advance(.1);
      }
      expect(c.playing, isFalse);
      expect(c.seconds, 8);
      expect(c.partStates()[index('dome')].progress, 1);
      expect(c.partStates()[index('semidome-e')].progress, 0);
      c.suspend();
      expect(c.needsTicker, isFalse);
    });
  });

  group('renderer', () {
    final study = loadStudy(), model = loadModel();

    test(
      'culls back faces; a cut keeps inside faces as poché and draws the cut',
      () {
        final c = SpaceController(study, model)..setSection(false);
        final r = SpaceRenderer(model);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        r.paint(canvas, const Size(390, 700), c.scene());
        final whole = r.stats;
        expect(whole.poche, 0);
        expect(whole.cuts, 0);
        expect(whole.faces, lessThan(model.triangleCount * .6));
        expect(whole.edges, greaterThan(0));
        c.setSection(true);
        r.paint(canvas, const Size(390, 700), c.scene());
        expect(r.stats.poche, greaterThan(0));
        expect(r.stats.cuts, greaterThan(0));
        // Night draws no line work but keeps the cut line.
        c.setStyle(SpaceStyle.night);
        r.paint(canvas, const Size(390, 700), c.scene());
        expect(r.stats.edges, 0);
        expect(r.stats.cuts, greaterThan(0));
        recorder.endRecording().dispose();
        r.dispose();
      },
    );

    // On the A52s (2026-11-09) the drawing vanished twice: orbiting above
    // the plan cut kept only the 3 m stubs under it, and dragging the cut's
    // handle up past the roof kept nothing at all.
    SpaceStats draw(SpaceRenderer r, SpaceController c, SpaceView view) {
      final recorder = ui.PictureRecorder();
      r.paint(
        Canvas(recorder),
        const Size(390, 700),
        SpaceScene(
          view: view,
          style: c.style,
          parts: c.partStates(),
          section: c.sectionPlane,
        ),
      );
      recorder.endRecording().dispose();
      return r.stats;
    }

    test('a plan cut keeps the building above it from every angle', () {
      final c = SpaceController(study, model), r = SpaceRenderer(model);
      expect(c.sectionAxis, 2);
      for (final deg in [-60, -35, -5, 0, 5, 30, 60, 85]) {
        final view = c.limits.clamp(
          c.choisyView.copyWith(elevation: deg * math.pi / 180),
        );
        c.setSection(false);
        final whole = draw(r, c, view).faces;
        c.setSection(true);
        final cut = draw(r, c, view);
        expect(cut.faces, greaterThan(whole * .8), reason: '$deg°');
        // The cut faces down: its poché shows only from below.
        if (deg < 0) {
          expect(cut.poche, greaterThan(0), reason: '$deg°');
        } else {
          expect(cut.poche, 0, reason: '$deg°');
        }
      }
      r.dispose();
      c.dispose();
    });

    test('no section plane position leaves an empty drawing', () {
      final c = SpaceController(study, model), r = SpaceRenderer(model);
      for (final axis in [0, 1, 2]) {
        c.setSectionAxis(axis);
        for (final far in [-1e9, 1e9]) {
          c.setSectionOffset(far);
          final (lo, hi) = c.sectionRange();
          expect(c.sectionOffset, far < 0 ? lo : hi);
          for (final azimuth in [0, 90, 180, 270]) {
            for (final deg in [-35, 30]) {
              final view = c.limits.clamp(
                c.choisyView.copyWith(
                  azimuth: azimuth * math.pi / 180,
                  elevation: deg * math.pi / 180,
                ),
              );
              expect(
                draw(r, c, view).faces,
                // A fifth of the building, seen from its cut side.
                greaterThan(model.triangleCount * .02),
                reason: 'axis $axis at $far, $azimuth°/$deg°',
              );
            }
          }
        }
      }
      r.dispose();
      c.dispose();
    });

    test('a plane set in one epoch is kept on what the next one draws', () {
      final c = SpaceController(study, model), r = SpaceRenderer(model);
      final last = study.epochs.length - 1;
      expect(last, greaterThan(0));
      c
        ..setEpoch(last)
        ..setSectionAxis(1)
        ..setSectionOffset(1e9);
      final wide = c.sectionOffset;
      c.setEpoch(0);
      final (_, hi) = c.sectionRange();
      expect(hi, lessThan(wide), reason: '537 is narrower than 1548');
      expect(c.sectionPlane!.offset, hi);
      for (final azimuth in [0, 90, 180, 270]) {
        final view = c.limits.clamp(
          c.choisyView.copyWith(azimuth: azimuth * math.pi / 180),
        );
        expect(
          draw(r, c, view).faces,
          greaterThan(model.triangleCount * .02),
          reason: '$azimuth°',
        );
      }
      r.dispose();
      c.dispose();
    });

    test('the 50k-triangle spike model stays within the drawing budget', () {
      final bench = loadModel('studio/spikes/p08/bench-50k.glb');
      expect(bench.triangleCount, inInclusiveRange(49000, 51000));
      final r = SpaceRenderer(bench);
      final recorder = ui.PictureRecorder();
      r.paint(
        Canvas(recorder),
        const Size(390, 844),
        SpaceScene(
          view: SpaceView.choisy(bench.bounds),
          style: SpaceStyle.drawing,
          parts: [for (final _ in bench.parts) const SpacePartState()],
          section: const SpaceSection(2, 3),
        ),
      );
      // The spike's ceiling for drawn records, not a study's budget.
      expect(r.stats.triangles, lessThan(150000));
      recorder.endRecording().dispose();
      r.dispose();
    });

    testWidgets('stills and frames for the share studio (P17 hooks)', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final r = SpaceRenderer(model);
        final c = SpaceController(study, model);
        final image = await renderSpaceStill(
          r,
          c.scene(),
          const Size(180, 320),
          pixelRatio: 2,
        );
        expect([image.width, image.height], [360, 640]);
        expect((await encodePng(image)).length, greaterThan(1000));
        image.dispose();
        var frames = 0;
        await for (final frame in spaceFrames(
          study,
          model,
          const Size(90, 160),
          fps: 2,
        )) {
          frames++;
          frame.dispose();
        }
        expect(frames, 16, reason: '8 s at 2 fps');
        expect(c.storyActive, isFalse, reason: 'capture never moves the view');
        r.dispose();
      });
    });
  });

  group('manifest', () {
    test('rejects broken studies and models that do not match', () {
      void broken(void Function(Map<String, dynamic>) edit) {
        final j = studyJson();
        edit(j);
        expect(() => SpaceStudy.fromJson(j), throwsFormatException);
      }

      Map<String, dynamic> step(Map<String, dynamic> j, int i) =>
          (j['steps'] as List)[i] as Map<String, dynamic>;
      broken((j) => j['honesty'] = 'ORIGINAL');
      broken((j) => j['triangles'] = 200000);
      broken((j) => step(j, 7)['epochs'] = [1600]);
      broken((j) => step(j, 7)['parts'] = ['pier-ne']);
      broken((j) => (step(j, 0)['caption'] as Map).remove('tr'));
      broken((j) => step(j, 0)['seconds'] = 30);
      broken((j) => (j['reveal'] as Map)['through'] = 'four-semidomes');
      broken((j) => (j['citations'] as List).removeLast());
      broken((j) => j['model'] = 'assets/space/other/model.glb');
      final j = studyJson();
      step(j, 0)['parts'] = [...step(j, 0)['parts'] as List, 'pier-x'];
      expect(
        () => SpaceStudy.fromJson(j).checkModel(loadModel()),
        throwsFormatException,
      );
    });

    test(
      "Hagia Sophia's 537 layer names the study; the catalogue checks it",
      () async {
        final registry = await loadRegistry();
        final layer = registry
            .place('hagia-sophia')!
            .strata
            .firstWhere((s) => s.id == 'justinian-church');
        expect(layer.studyIds, ['how-a-dome-stands']);
        final catalog = await SpaceCatalog.load(
          registry,
          (p) => File(p).readAsString(),
        );
        expect(catalog.study('how-a-dome-stands')!.steps, hasLength(8));
        final stale = await SpaceCatalog.load(
          registry,
          (p) async => (await File(p).readAsString()).replaceFirst(
            'https://www.britannica.com/technology/pendentive',
            'https://example.com/pendentive',
          ),
          strict: false,
        );
        // A stale citation drops the studies that cite it (the Şehzade
        // shares this one), not the others.
        expect(stale.study('how-a-dome-stands'), isNull);
        expect(stale.study('bodrum-camii'), isNotNull);
        expect(
          stale.errors.firstWhere((e) => e.startsWith('how-a-dome-stands')),
          contains('stale study citation'),
        );
      },
    );
  });
}
