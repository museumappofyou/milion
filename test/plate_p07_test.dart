import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/json_reader.dart';
import 'package:milion/content/models.dart';
import 'package:milion/content/repository.dart';
import 'package:milion/plate/catalog.dart';
import 'package:milion/plate/controller.dart';
import 'package:milion/plate/look_up.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/plate/tilt.dart';
import 'package:milion/today/detail_crop.dart';
import 'package:sensors_plus/sensors_plus.dart';

PlateManifest plate(String name) => PlateManifest.fromJson(
  jsonDecode(File('assets/plates/$name/manifest.json').readAsStringSync())
      as Map<String, dynamic>,
);

double dot(List<double> a, List<double> b) =>
    a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

void main() {
  group('look-up projection', () {
    final dome = PlateLookUp(
      JsonReader({
        'center': [.5, .5],
        'rimCenter': [.5, .5],
        'rimRadii': [.3, .3],
        'rimElevation': 50,
      }),
    );
    const aspect = 1.5;
    test('the zenith is the centre and the rim sits at its elevation', () {
      expect(
        dome.anglesAt(.5, .5, aspect).elevation,
        closeTo(math.pi / 2, 1e-9),
      );
      final rim = dome.anglesAt(.8, .5, aspect);
      expect(rim.elevation, closeTo(50 * math.pi / 180, 1e-9));
      // Image right is world -X; image top is world +Y.
      expect(rim.azimuth.abs(), closeTo(math.pi, 1e-9));
      expect(dome.anglesAt(.5, .3, aspect).azimuth, closeTo(math.pi / 2, 1e-9));
    });
    test('uvAt inverts anglesAt across the dome', () {
      for (final (u, v) in [(.6, .4), (.35, .62), (.71, .5), (.5, .7)]) {
        final back = dome.uvAt(dome.anglesAt(u, v, aspect), aspect);
        expect(back.dx, closeTo(u, 1e-9));
        expect(back.dy, closeTo(v, 1e-9));
      }
    });
    test(
      'camera bases are orthonormal, right-handed and keep the zenith up',
      () {
        for (final a in [
          const LookAngles(-math.pi / 2, math.pi / 2),
          const LookAngles(.4, .9),
          const LookAngles(2.5, .2),
        ]) {
          final b = LookBasis.angles(a);
          expect(dot(b.forward, b.forward), closeTo(1, 1e-9));
          expect(dot(b.up, b.up), closeTo(1, 1e-9));
          expect(dot(b.forward, b.up), closeTo(0, 1e-9));
          expect(dot(b.right, b.forward), closeTo(0, 1e-9));
          expect(b.up[2], greaterThanOrEqualTo(-1e-9));
          expect(b.angles.azimuth, closeTo(a.azimuth, 1e-9));
          expect(b.angles.elevation, closeTo(a.elevation, 1e-9));
        }
        // Home: straight up with the photograph's top (+Y) at the screen top
        // and its right (-X) at the screen right.
        final home = LookBasis.angles(PlateOrientation.home);
        expect(home.forward[2], closeTo(1, 1e-9));
        expect(home.up[1], closeTo(1, 1e-9));
        expect(home.right[0], closeTo(-1, 1e-9));
      },
    );
    test('a phone held overhead, screen down, looks at the zenith', () {
      // Device -Z points up: the rotation flips Y and Z.
      const overhead = [1.0, 0.0, 0.0, 0.0, -1.0, 0.0, 0.0, 0.0, -1.0];
      final b = LookBasis.device(overhead, 0);
      expect(b.forward[2], closeTo(1, 1e-9));
      expect(dot(b.right, b.forward), closeTo(0, 1e-9));
    });
  });

  test('an off-axis crown: the measured rim ellipse sits at the rim elevation all round', () {
    final g = plate('genealogy'), dome = g.lookUp!;
    final aspect = g.width / g.height;
    for (var i = 0; i < 12; i++) {
      final az = i * math.pi / 6;
      final uv = dome.uvAt(
        LookAngles(az, dome.rimElevation * math.pi / 180),
        aspect,
      );
      final ex = (uv.dx - dome.rimCenter[0]) / dome.rimRadii[0];
      final ey = (uv.dy - dome.rimCenter[1]) / aspect / dome.rimRadii[1];
      expect(ex * ex + ey * ey, closeTo(1, 1e-9));
      final back = dome.anglesAt(uv.dx, uv.dy, aspect);
      expect(back.elevation, closeTo(dome.rimElevation * math.pi / 180, 1e-9));
    }
    final crown = dome.anglesAt(dome.center[0], dome.center[1], aspect);
    expect(crown.elevation, closeTo(math.pi / 2, 1e-9));
  });

  test('the story looks upright at the crown and the LU reveal turns', () {
    final c = PlateController(plate('genealogy'))..playReveal();
    final start = storyLook(c.manifest, c)!;
    expect(start.forward[2], greaterThan(.99));
    expect(start.up[1], greaterThan(.95)); // the photograph's top stays up
    c.advance(9.9);
    final end = storyLook(c.manifest, c)!;
    expect(end.angles.elevation, lessThan(start.angles.elevation));
    expect(
      (end.angles.azimuth - start.angles.azimuth).abs(),
      greaterThan(math.pi / 3),
    );
    c.dispose();
  });

  test('III–V: generic plates from the P07 line', () {
    for (final (name, lu) in [
      ('metochites', false),
      ('genealogy', true),
      ('enrollment', false),
    ]) {
      final p = plate(name);
      expect(p.details.length, greaterThanOrEqualTo(5), reason: name);
      expect(p.revealMoment, inInclusiveRange(0, p.revealSeconds));
      expect(p.lookUp != null, lu, reason: name);
      expect(p.rig, isNull);
      expect(p.layers.single.id, PlateLayerId.original);
      expect(
        p.originalSourceUrl,
        startsWith('https://cdn.kulturenvanteri.com/'),
      );
      expect(p.maps.surface, endsWith('.webp'));
      final c = PlateController(p)..play();
      expect(c.honesty, Honesty.DEPTH, reason: name);
      c.dispose();
    }
  });

  group('look-up orientation', () {
    test(
      'the sensor is opt-in, re-centred, unsubscribed on lifecycle and exit',
      () async {
        final events = StreamController<List<double>>.broadcast(sync: true);
        final o = PlateOrientation(events: () => events.stream);
        expect(events.hasListener, isFalse);
        o.setEnabled(true);
        expect(events.hasListener, isTrue);
        // A phone held upright facing some arbitrary heading.
        events.add([0, 0, 1, 1, 0, 0, 0, 1, 0]);
        final first = o.basis.angles;
        expect(first.azimuth, closeTo(PlateOrientation.home.azimuth, 1e-9));
        o.suspend();
        expect(events.hasListener, isFalse);
        o.resume();
        expect(events.hasListener, isTrue);
        events.addError(StateError('no sensor'));
        expect(o.unavailable, isTrue);
        expect(o.enabled, isFalse);
        o.dispose();
        expect(events.hasListener, isFalse);
        await events.close();
      },
    );
    test('the flat pan follows the finger, stops at the zenith and zooms within limits', () {
      final o = PlateOrientation(events: () => const Stream.empty());
      o.lookAt(const LookAngles(0, .5));
      o.pan(const Offset(0, 10000), const Size(400, 800));
      expect(o.basis.angles.elevation, closeTo(math.pi / 2, 1e-6));
      o.beginZoom();
      o.zoom(100);
      expect(o.fov, PlateOrientation.minFov);
      o.zoom(.01);
      expect(o.fov, PlateOrientation.maxFov);
      o.recenter();
      expect(o.basis.angles.elevation, closeTo(math.pi / 2, 1e-9));
      o.dispose();
    });
  });

  group('controller honesty and camera', () {
    test(
      'flow and spiral are IMAGINED; the gesture beat is IMAGINED throughout',
      () {
        final c = PlateController(plate('judgment'))
          ..setLayer(PlateLayerId.depth);
        expect(c.honesty, Honesty.DEPTH);
        c.setPaintMotion(river: true);
        expect(c.honesty, Honesty.IMAGINED);
        c.original();
        expect(c.honesty, Honesty.ORIGINAL);
        c.dispose();
        final a = PlateController(plate('anastasis'));
        final beat = a.manifest.beats.firstWhere((b) => b.gesture != null);
        a.seek(beat.start + .1); // well before the 1.2 s gesture itself
        expect(a.visibleGesture, 0);
        expect(a.honesty, Honesty.IMAGINED);
        a.seek(beat.end + .1);
        expect(a.honesty, Honesty.DEPTH);
        a.dispose();
      },
    );
    test('only the story moves the camera; pause and peek leave it alone', () {
      final c = PlateController(plate('anastasis'));
      var r = c.cameraRevision;
      c.play();
      expect(c.cameraRevision, greaterThan(r));
      r = c.cameraRevision;
      c.advance(.5);
      expect(c.cameraRevision, greaterThan(r));
      r = c.cameraRevision;
      c.pause();
      c.peek(true);
      c.peek(false);
      c.pause();
      expect(c.cameraRevision, r);
      c.seek(3);
      expect(c.cameraRevision, greaterThan(r));
      c.dispose();
    });
    test('scrubbing the reveal stays in the reveal', () {
      final c = PlateController(plate('judgment'))..playReveal();
      c.seekReveal(7);
      expect(c.reveal, isTrue);
      expect(c.seconds, 7);
      expect(c.sample!.beat.id, c.manifest.reveal.id);
      c.dispose();
    });
    test('reduced motion opens the reveal as its still, not the story', () {
      final c = PlateController(plate('judgment'))..setReduced(true);
      c.playReveal();
      expect(c.reveal, isTrue);
      expect(c.playing, isFalse);
      c.dispose();
    });
  });

  test('gyro tilt relaxes to centre when the phone is held still', () async {
    final events = StreamController<GyroscopeEvent>.broadcast(sync: true);
    final tilt = PlateTilt(events: () => events.stream)..setEnabled(true);
    final t = DateTime(2026);
    var i = 0;
    void send(double rate, int count) {
      for (var k = 0; k < count; k++, i++) {
        events.add(
          GyroscopeEvent(rate, rate, 0, t.add(Duration(milliseconds: i * 20))),
        );
      }
    }

    send(10, 50);
    expect(tilt.normalized.dx, closeTo(1, .01));
    send(0, 500); // ten seconds still
    expect(tilt.normalized.dx.abs(), lessThan(.05));
    tilt.dispose();
    await events.close();
  });

  test(
    'one broken plate is dropped by the app and fails the validator',
    () async {
      final registry = await ContentRepository(
        (path) => File(path).readAsString(),
      ).load();
      Future<String> broken(String path) async {
        final text = await File(path).readAsString();
        return path.contains('judgment')
            ? text.replaceFirst('"kind"', '"knd"')
            : text;
      }

      final lenient = await PlateCatalog.load(registry, broken, strict: false);
      expect(lenient.errors, hasLength(1));
      expect(
        lenient.plates.map((p) => p.id),
        isNot(contains('plate-judgment')),
      );
      expect(lenient.plates.map((p) => p.id), contains('plate-anastasis'));
      expect(() => PlateCatalog.load(registry, broken), throwsFormatException);
      final playable = detailOfDay(
        registry,
        DateTime(2026, 10, 12),
        playable: (d) =>
            lenient.forMilestone(registry.milestone(d.milestoneId)!) != null,
      )!;
      expect(playable.milestoneId, isNot('milestone-ii'));
      expect(
        detailOfDay(registry, DateTime(2026), playable: (_) => false),
        isNull,
      );
    },
  );
}
