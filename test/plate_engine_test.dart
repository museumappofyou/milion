import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:milion/content/models.dart';
import 'package:milion/plate/controller.dart';
import 'package:milion/plate/manifest.dart';
import 'package:milion/plate/timeline.dart';
import 'package:milion/plate/tilt.dart';
import 'package:sensors_plus/sensors_plus.dart';

Map<String, dynamic> plateJson() =>
    jsonDecode(File('assets/plates/anastasis/manifest.json').readAsStringSync())
        as Map<String, dynamic>;
PlateManifest plate() => PlateManifest.fromJson(plateJson());
void main() {
  test('strict manifests reject malformed schemas, claims, timeline and gesture budgets', () {
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (j) => j['typo'] = true,
      (j) => j['schemaVersion'] = 2,
      (j) => j['mesh']['maxVertices'] = 60001,
      (j) => j['layers'][2]['mask'] = null,
      (j) => j['beats'][1]['start'] = 6,
      (j) => j['beats'][1]['gesture']['duration'] = 2,
      (j) => j['beats'][0]['sources'] = ['missing'],
      (j) => j['beats'][0]['flow'] = true,
      (j) => j['originalSourceUrl'] = 'file:///tmp/a',
      (j) => j['details'][0]['window']['left'] = -.1,
      (j) => j['details'][0]['sentence']['tr'] = null,
      (j) => j['reveal']['detail'] = 'unknown',
    ]) {
      final j = plateJson();
      mutate(j);
      expect(() => PlateManifest.fromJson(j), throwsFormatException);
    }
  });
  test('timeline seeks exactly, converges on every window and scopes the gesture to 1.2s', () {
    final p = plate(), timeline = PlateTimeline(p);
    for (final beat in p.beats) {
      final s = timeline.at(beat.start + 2);
      expect(s.beat.id, beat.id);
      expect(s.window.left, beat.window.left);
      expect(
        timeline.at(beat.start, reduced: true).window.left,
        beat.window.left,
      );
    }
    expect(timeline.at(10).gesturePhase, 0);
    expect(timeline.at(10.6).gesturePhase, closeTo(.5, .0001));
    expect(timeline.at(11.2).gesturePhase, 0);
    expect(timeline.at(10.6, reduced: true).gesturePhase, 0);
    expect(timeline.at(100).beat.id, p.beats.last.id);
    expect(() => timeline.at(double.nan), throwsFormatException);
  });
  test('original-first controller pauses, peeks, stops once and disposes', () {
    final c = PlateController(plate());
    expect(c.honesty, Honesty.ORIGINAL);
    expect(c.needsTicker, isFalse);
    c.playReveal();
    c.advance(10);
    expect(c.seconds, 10);
    expect(c.playing, isFalse);
    c.play();
    c.advance(10.6);
    expect(c.honesty, Honesty.IMAGINED);
    c.peek(true);
    final t = c.seconds;
    c.advance(2);
    expect(c.seconds, t);
    expect(c.honesty, Honesty.ORIGINAL);
    c.peek(false);
    expect(c.playing, isTrue);
    c.advance(30);
    expect(c.seconds, 32);
    expect(c.playing, isFalse);
    c.seek(8);
    c.pause();
    c.advance(30);
    expect(c.seconds, 8);
    c.playGesture();
    c.advance(7);
    expect(c.gesturePose, 1);
    expect(c.gesturePlaying, isFalse);
    c.original();
    expect(c.needsTicker, isFalse);
    expect(c.visibleGesture, 0);
    c.setLight(PlateLight.candle);
    c.setLayer(PlateLayerId.reconstruction);
    expect(c.needsTicker, isFalse);
    expect(c.visibleLight, PlateLight.none);
    c.dispose();
    expect(c.disposed, isTrue);
  });
  test('reduced motion is a complete manual still sequence; resume does not autoplay', () {
    final c = PlateController(plate())..setReduced(true);
    for (final b in c.manifest.beats) {
      c.step(1);
      expect(c.sample!.beat.id, b.id);
      expect(c.needsTicker, isFalse);
    }
    c.seek(10.6);
    expect(c.visibleGesture, 0);
    c.setLight(PlateLight.candle);
    expect(c.needsTicker, isFalse);
    c.suspend();
    c.resume();
    expect(c.playing, isFalse);
    c.dispose();
  });
  test('gyroscope is opt-in, low-pass, bounded, re-centred and unsubscribed on lifecycle/exit', () async {
    final events = StreamController<GyroscopeEvent>.broadcast(sync: true);
    final tilt = PlateTilt(events: () => events.stream);
    expect(events.hasListener, isFalse);
    tilt.setEnabled(true);
    expect(events.hasListener, isTrue);
    final t = DateTime(2026);
    for (var i = 0; i < 100; i++) {
      events.add(
        GyroscopeEvent(10, 10, 0, t.add(Duration(milliseconds: i * 20))),
      );
    }
    expect(tilt.normalized.dx, closeTo(1, .001));
    expect(tilt.normalized.dy, closeTo(1, .001));
    tilt.recenter();
    expect(tilt.normalized, Offset.zero);
    tilt.drag(const Offset(-4, 3));
    expect(tilt.normalized, const Offset(-1, 1));
    tilt.suspend();
    expect(events.hasListener, isFalse);
    tilt.resume();
    expect(events.hasListener, isTrue);
    tilt.dispose();
    expect(events.hasListener, isFalse);
    await events.close();
  });
  test('sensor errors retain an operable drag fallback', () async {
    final events = StreamController<GyroscopeEvent>.broadcast(sync: true);
    final tilt = PlateTilt(events: () => events.stream)..setEnabled(true);
    events.addError(StateError('no sensor'));
    expect(tilt.unavailable, isTrue);
    expect(tilt.subscribed, isFalse);
    tilt.drag(const Offset(.3, -.5));
    expect(tilt.normalized.dx, closeTo(.3, .001));
    tilt.dispose();
    await events.close();
  });
}
