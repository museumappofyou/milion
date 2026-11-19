import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../content/models.dart';
import 'walk.dart';

/// What the walk is doing: the 10-second reveal, the story through its
/// stops, the stills (reduced motion), or free walking on the deck.
enum WalkMode { explore, reveal, story, stills }

/// Where the eye is and what it looks at, in the walk's frame.
@immutable
class WalkCamera {
  const WalkCamera(this.eye, this.look, {this.fovY = 62 * math.pi / 180});
  final WalkPoint eye, look;
  final double fovY;
  double get yaw => math.atan2(look.z - eye.z, look.x - eye.x);
  double get pitch {
    final d = look - eye;
    return math.atan2(d.y, math.sqrt(d.x * d.x + d.z * d.z));
  }
}

double _smooth(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// One owner for a walk's camera, timeline and lights. The scene and the
/// overlays read it; gestures, the docks and TalkBack drive it.
class WalkController extends ChangeNotifier {
  WalkController(this.manifest) {
    final first = switch (manifest.start) {
      final id? => manifest.stop(id),
      null => manifest.stops.first,
    };
    _s = manifest.nearest(first.eye.x, first.eye.z);
    final cam = WalkCamera(first.eye, first.look);
    _yaw = cam.yaw;
    _pitch = cam.pitch;
  }
  final WalkManifest manifest;

  WalkMode _mode = WalkMode.explore;
  WalkMode get mode => _mode;
  double _t = 0;

  /// Seconds into the reveal or the story.
  double get seconds => _t;
  bool get playing => _mode == WalkMode.reveal || _mode == WalkMode.story;

  bool _reduced = false;
  bool get reduced => _reduced;

  /// Reduced motion: no reveal or story in motion, no fish; the stops are
  /// stills, one tap apart.
  void setReduced(bool value) {
    if (_reduced == value) return;
    _reduced = value;
    if (value) {
      _fish = false;
      if (playing) stills();
    }
    notifyListeners();
  }

  // Walking on the deck: metres along the route, and where the head turns.
  double _s = 0, _yaw = 0, _pitch = 0;
  double get position => _s;
  double get yaw => _yaw;
  double get pitch => _pitch;

  int _still = 0;
  int get stillIndex => _still;
  WalkStop get currentStill => manifest.stop(manifest.stills[_still]);

  bool _fish = false;

  /// Fish swim only on request; while they move the walk reads IMAGINED
  /// (P13's XV: animals in motion are invented).
  bool get fish => _fish;
  void setFish(bool value) {
    if (_reduced && value) return;
    if (_fish == value) return;
    _fish = value;
    notifyListeners();
  }

  bool _labels = true;
  bool get labels => _labels;
  void setLabels(bool value) {
    if (_labels == value) return;
    _labels = value;
    notifyListeners();
  }

  Honesty get honesty => _fish ? Honesty.IMAGINED : manifest.honesty;

  /// The frame needs ticking: the timeline runs or fish swim.
  bool get needsTicker => playing || _fish;

  void play() {
    if (_reduced) return stills();
    _mode = WalkMode.reveal;
    _t = 0;
    notifyListeners();
  }

  void playStory() {
    if (_reduced) return stills();
    _mode = WalkMode.story;
    _t = 0;
    notifyListeners();
  }

  void stills([int index = 0]) {
    _mode = WalkMode.stills;
    _still = index.clamp(0, manifest.stills.length - 1);
    notifyListeners();
  }

  /// Next or previous stop: a still in reduced motion, otherwise the deck
  /// position nearest that stop, facing what it looks at.
  void step(int delta) {
    if (_mode == WalkMode.stills) {
      _still = (_still + delta) % manifest.stills.length;
      if (_still < 0) _still += manifest.stills.length;
      notifyListeners();
      return;
    }
    final stops = manifest.stops;
    var i = _nearestStop();
    i = (i + delta).clamp(0, stops.length - 1);
    goTo(stops[i]);
  }

  int _nearestStop() {
    final stops = manifest.stops;
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < stops.length; i++) {
      final d = (manifest.nearest(stops[i].eye.x, stops[i].eye.z) - _s).abs();
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  void goTo(WalkStop stop) {
    _mode = WalkMode.explore;
    _s = manifest.nearest(stop.eye.x, stop.eye.z);
    final c = WalkCamera(stop.eye, stop.look);
    _yaw = c.yaw;
    _pitch = c.pitch;
    notifyListeners();
  }

  /// A touch hands the reveal or story back: walking continues from where
  /// the camera was.
  void explore() {
    if (_mode == WalkMode.explore) return;
    final c = camera;
    _s = manifest.nearest(c.eye.x, c.eye.z);
    _yaw = c.yaw;
    _pitch = c.pitch.clamp(-.9, .9);
    _mode = WalkMode.explore;
    notifyListeners();
  }

  /// A thumb on the deck: [forward] metres along the route, turning by
  /// [turn] radians and tipping by [tip].
  void walk({double forward = 0, double turn = 0, double tip = 0}) {
    if (_mode != WalkMode.explore) explore();
    final heading = manifest.along(_s).$3;
    // Forward follows where the head points: facing back down the deck,
    // pushing forward walks back.
    final facing = math.cos(_yaw - heading) >= 0 ? 1.0 : -1.0;
    _s = (_s + forward * facing).clamp(0.0, manifest.routeLength);
    _yaw += turn;
    _pitch = (_pitch + tip).clamp(-.9, .9);
    notifyListeners();
  }

  /// The look sensor (after opt-in) sets the head directly.
  void look(double yaw, double pitch) {
    if (_mode != WalkMode.explore) explore();
    _yaw = yaw;
    _pitch = pitch.clamp(-1.2, 1.2);
    notifyListeners();
  }

  void advance(double dt) {
    if (!playing) return;
    _t += dt;
    final end = _mode == WalkMode.reveal
        ? manifest.revealSeconds
        : manifest.storySeconds;
    if (_t >= end) {
      _t = end;
      final last = _mode == WalkMode.reveal
          ? manifest.stop(manifest.revealStop)
          : manifest.stops.last;
      goTo(last);
      return;
    }
    notifyListeners();
  }

  /// The story's stop at [seconds], and how far the move into it has gone.
  (int, double) storyAt(double seconds) {
    var t = seconds;
    final stops = manifest.stops;
    for (var i = 0; i < stops.length; i++) {
      if (t < stops[i].seconds || i == stops.length - 1) {
        // The first 40% of a stop's time is the move from the previous one.
        return (i, i == 0 ? 1.0 : _smooth(t / (stops[i].seconds * .4)));
      }
      t -= stops[i].seconds;
    }
    return (stops.length - 1, 1.0);
  }

  /// The stop the timeline or the stills show, if any.
  WalkStop? get currentStop => switch (_mode) {
    WalkMode.story => manifest.stops[storyAt(_t).$1],
    WalkMode.reveal => manifest.stop(manifest.revealStop),
    WalkMode.stills => currentStill,
    WalkMode.explore => null,
  };

  /// The caption under the view: the reveal's line, the story's or the
  /// still's stop.
  Localized? get caption => switch (_mode) {
    WalkMode.reveal => manifest.revealCaption,
    WalkMode.story || WalkMode.stills => currentStop?.caption,
    WalkMode.explore => null,
  };

  WalkCamera get camera {
    switch (_mode) {
      case WalkMode.stills:
        return WalkCamera(currentStill.eye, currentStill.look);
      case WalkMode.story:
        final (i, k) = storyAt(_t);
        final stops = manifest.stops;
        final to = stops[i];
        if (i == 0 || k >= 1) return WalkCamera(to.eye, to.look);
        final from = stops[i - 1];
        return WalkCamera(
          WalkPoint.lerp(from.eye, to.eye, k),
          WalkPoint.lerp(from.look, to.look, k),
        );
      case WalkMode.reveal:
        // From a close look at the head out to the stop's view.
        final stop = manifest.stop(manifest.revealStop);
        final k = _smooth((_t - 2.5) / 4.5);
        final near = WalkPoint.lerp(stop.look, stop.eye, .38);
        return WalkCamera(WalkPoint.lerp(near, stop.eye, k), stop.look);
      case WalkMode.explore:
        final (x, z, _) = manifest.along(_s);
        final eye = WalkPoint(x, manifest.grid.eye, z);
        final cp = math.cos(_pitch);
        return WalkCamera(
          eye,
          eye +
              WalkPoint(
                math.cos(_yaw) * cp,
                math.sin(_pitch),
                math.sin(_yaw) * cp,
              ),
        );
    }
  }

  /// The hall's lights (0 dark, 1 today's installation).
  double get hallLight =>
      _mode == WalkMode.reveal ? _smooth((_t - 3.0) / 4.0) : 1.0;

  /// The light on the carved heads: first on in the reveal.
  double get headLight =>
      _mode == WalkMode.reveal ? _smooth((_t - .4) / 2.4) : 1.0;

  /// Callouts to show: the stop's own while the story or a still holds,
  /// otherwise every callout near enough to the eye.
  List<WalkCallout> visibleCallouts() {
    if (!_labels) return const [];
    final stop = currentStop;
    if (_mode == WalkMode.reveal) return const [];
    if (stop != null) {
      if (_mode == WalkMode.story && storyAt(_t).$2 < 1) return const [];
      return [for (final id in stop.callouts) manifest.callout(id)];
    }
    final eye = camera.eye;
    return [
      for (final c in manifest.callouts)
        if ((c.anchor - eye).length < 14) c,
    ];
  }
}
