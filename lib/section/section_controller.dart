import 'package:flutter/foundation.dart';

import '../content/models.dart';
import 'section.dart';

enum SectionMode { explore, reveal, story, stills }

double _smooth(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// One owner for a section's depth, timeline and pop-ups. The reading line
/// is the depth under the eye; finds near it, or named by the story's beat,
/// lift out of the drawing (PU).
class SectionController extends ChangeNotifier {
  SectionController(this.manifest) : _depth = manifest.beats.first.depth;
  final SectionManifest manifest;

  SectionMode _mode = SectionMode.explore;
  SectionMode get mode => _mode;
  double _t = 0;
  double get seconds => _t;
  bool get playing => _mode == SectionMode.reveal || _mode == SectionMode.story;

  bool _reduced = false;
  bool get reduced => _reduced;
  void setReduced(bool value) {
    if (_reduced == value) return;
    _reduced = value;
    if (value && playing) stills();
    notifyListeners();
  }

  double _depth;

  /// The depth (m, relative to sea level) under the reading line.
  double get depth => switch (_mode) {
    SectionMode.reveal =>
      manifest.revealFrom +
          (manifest.revealTo - manifest.revealFrom) * _smooth((_t - .6) / 6.4),
    SectionMode.story => _storyDepth(),
    SectionMode.stills => currentStill.depth,
    SectionMode.explore => _depth,
  };

  int _still = 0;
  int get stillIndex => _still;
  SectionBeat get currentStill => manifest.beat(manifest.stills[_still]);

  Honesty get honesty => manifest.honesty;
  bool get needsTicker => playing;

  void play() {
    if (_reduced) return stills();
    _mode = SectionMode.reveal;
    _t = 0;
    notifyListeners();
  }

  void playStory() {
    if (_reduced) return stills();
    _mode = SectionMode.story;
    _t = 0;
    notifyListeners();
  }

  void stills([int index = 0]) {
    _mode = SectionMode.stills;
    _still = index.clamp(0, manifest.stills.length - 1);
    notifyListeners();
  }

  void step(int delta) {
    if (_mode == SectionMode.stills) {
      final n = manifest.stills.length;
      _still = ((_still + delta) % n + n) % n;
      notifyListeners();
      return;
    }
    final beats = manifest.beats;
    var nearest = 0;
    for (var i = 0; i < beats.length; i++) {
      if ((beats[i].depth - depth).abs() <
          (beats[nearest].depth - depth).abs()) {
        nearest = i;
      }
    }
    goTo(beats[(nearest + delta).clamp(0, beats.length - 1)]);
  }

  void goTo(SectionBeat beat) {
    _mode = SectionMode.explore;
    _depth = beat.depth;
    notifyListeners();
  }

  void explore() {
    if (_mode == SectionMode.explore) return;
    _depth = depth;
    _mode = SectionMode.explore;
    notifyListeners();
  }

  /// A finger moves the section by [metres] (down positive: deeper).
  void scroll(double metres) {
    if (_mode != SectionMode.explore) explore();
    _depth = (_depth - metres).clamp(manifest.bottom + .3, manifest.top - .3);
    notifyListeners();
  }

  void advance(double dt) {
    if (!playing) return;
    _t += dt;
    final end = _mode == SectionMode.reveal
        ? manifest.revealSeconds
        : manifest.storySeconds;
    if (_t >= end) {
      _t = end;
      _depth = depth;
      _mode = SectionMode.explore;
    }
    notifyListeners();
  }

  /// The beat at [seconds] and how far the move into it has gone.
  (int, double) storyAt(double seconds) {
    var t = seconds;
    final beats = manifest.beats;
    for (var i = 0; i < beats.length; i++) {
      if (t < beats[i].seconds || i == beats.length - 1) {
        return (i, i == 0 ? 1.0 : _smooth(t / (beats[i].seconds * .35)));
      }
      t -= beats[i].seconds;
    }
    return (beats.length - 1, 1.0);
  }

  double _storyDepth() {
    final (i, k) = storyAt(_t);
    final beats = manifest.beats;
    if (i == 0) return beats[0].depth;
    return beats[i - 1].depth + (beats[i].depth - beats[i - 1].depth) * k;
  }

  SectionBeat? get currentBeat => switch (_mode) {
    SectionMode.story => manifest.beats[storyAt(_t).$1],
    SectionMode.stills => currentStill,
    _ => null,
  };

  Localized? get caption => switch (_mode) {
    SectionMode.reveal => manifest.revealCaption,
    SectionMode.story || SectionMode.stills => currentBeat?.caption,
    SectionMode.explore => null,
  };

  /// How far a find or ship stands out of the drawing (0 flat, 1 up).
  /// The story lifts what its beat names; while exploring, what is near
  /// the reading line; the reveal lifts the ships as the dig reaches them.
  double lift(String id, double at, {bool ship = false}) {
    switch (_mode) {
      case SectionMode.reveal:
        if (!ship) return 0;
        return _smooth((_t - 5.4 - (at + 1.9).abs() * .25) / 1.4);
      case SectionMode.story:
      case SectionMode.stills:
        final beat = currentBeat!;
        final named =
            beat.lift.contains(id) || (ship && beat.lift.contains('ships'));
        if (!named) return 0;
        if (_mode == SectionMode.stills) return 1;
        final (i, k) = storyAt(_t);
        var into = _t;
        for (var j = 0; j < i; j++) {
          into -= manifest.beats[j].seconds;
        }
        return k < 1 ? 0 : _smooth((into - beat.seconds * .35) / 1.2);
      case SectionMode.explore:
        final d = (at - _depth).abs();
        return _smooth((1.6 - d) / .8);
    }
  }
}
