import 'package:flutter/foundation.dart';

import '../content/models.dart';
import 'wall_strip.dart';

enum WallMode { explore, reveal, story, stills }

double _smooth(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// One owner for the strip's position (metres along the wall from the Sea
/// of Marmara), its timeline and what it shows (P15, Milestone XVIII). The
/// reveal is one continuous fling, Marmara to the Golden Horn.
class WallController extends ChangeNotifier {
  WallController(this.manifest) : _at = manifest.beats.first.at;
  final WallStripManifest manifest;

  WallMode _mode = WallMode.explore;
  WallMode get mode => _mode;
  double _t = 0;
  double get seconds => _t;
  bool get playing => _mode == WallMode.reveal || _mode == WallMode.story;
  bool get needsTicker => playing;

  bool _reduced = false;
  bool get reduced => _reduced;
  void setReduced(bool value) {
    if (_reduced == value) return;
    _reduced = value;
    if (value && playing) stills();
    notifyListeners();
  }

  double _at;

  /// Metres along the wall under the reading line.
  double get at => switch (_mode) {
    WallMode.reveal => _revealAt(_t),
    WallMode.story => _storyAt(),
    WallMode.stills => currentStill.at,
    WallMode.explore => _at,
  };

  /// The fling: a quick start, a long glide and a soft stop at the Horn.
  double _revealAt(double t) {
    final x = (t / manifest.revealSeconds).clamp(0.0, 1.0);
    // Quadratic, not cubic: a cubic tail spent its last five seconds on the
    // final 200 m (seen on the A52s, 2026-11-20).
    final eased = 1 - (1 - x) * (1 - x);
    return manifest.length * eased;
  }

  int _still = 0;
  int get stillIndex => _still;
  WallBeat get currentStill => manifest.beat(manifest.stills[_still]);
  Honesty get honesty => manifest.honesty;

  WallSegment get segment => manifest.segmentAt(at);
  WallGate? get gate => manifest.gateNear(at);

  void play() {
    if (_reduced) return stills();
    _mode = WallMode.reveal;
    _t = 0;
    notifyListeners();
  }

  void playStory() {
    if (_reduced) return stills();
    _mode = WallMode.story;
    _t = 0;
    notifyListeners();
  }

  void stills([int index = 0]) {
    _mode = WallMode.stills;
    _still = index.clamp(0, manifest.stills.length - 1);
    notifyListeners();
  }

  /// Next or previous: the story's beats in stills, the gates otherwise.
  void step(int delta) {
    if (_mode == WallMode.stills) {
      final n = manifest.stills.length;
      _still = ((_still + delta) % n + n) % n;
      notifyListeners();
      return;
    }
    final here = at;
    final gates = manifest.gates;
    WallGate? target;
    if (delta > 0) {
      for (final g in gates) {
        if (g.at > here + 1) {
          target = g;
          break;
        }
      }
    } else {
      for (final g in gates.reversed) {
        if (g.at < here - 1) {
          target = g;
          break;
        }
      }
    }
    if (target != null) goTo(target.at);
  }

  void goTo(double metres) {
    _mode = WallMode.explore;
    _at = metres.clamp(0.0, manifest.length);
    notifyListeners();
  }

  void explore() {
    if (_mode == WallMode.explore) return;
    _at = at;
    _mode = WallMode.explore;
    notifyListeners();
  }

  /// A finger or a fling sets the position directly.
  void scrollTo(double metres) {
    if (_mode != WallMode.explore) explore();
    final v = metres.clamp(0.0, manifest.length);
    if (v == _at) return;
    _at = v;
    notifyListeners();
  }

  void advance(double dt) {
    if (!playing) return;
    _t += dt;
    final end = _mode == WallMode.reveal
        ? manifest.revealSeconds
        : manifest.storySeconds;
    if (_t >= end) {
      _t = end;
      _at = at;
      _mode = WallMode.explore;
    }
    notifyListeners();
  }

  /// The beat at [seconds] and how far the glide into it has gone.
  (int, double) storyAt(double seconds) {
    var t = seconds;
    final beats = manifest.beats;
    for (var i = 0; i < beats.length; i++) {
      if (t < beats[i].seconds || i == beats.length - 1) {
        return (i, i == 0 ? 1.0 : _smooth(t / (beats[i].seconds * .4)));
      }
      t -= beats[i].seconds;
    }
    return (beats.length - 1, 1.0);
  }

  double _storyAt() {
    final (i, k) = storyAt(_t);
    final beats = manifest.beats;
    if (i == 0) return beats[0].at;
    return beats[i - 1].at + (beats[i].at - beats[i - 1].at) * k;
  }

  WallBeat? get currentBeat => switch (_mode) {
    WallMode.story => manifest.beats[storyAt(_t).$1],
    WallMode.stills => currentStill,
    _ => null,
  };

  Localized? get caption => switch (_mode) {
    WallMode.reveal => manifest.revealCaption,
    WallMode.story || WallMode.stills => currentBeat?.caption,
    WallMode.explore => null,
  };
}
