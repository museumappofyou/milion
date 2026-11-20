import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../atlas/historic.dart' show projectMetres, unprojectMetres;
import '../content/models.dart';
import 'siege.dart';

enum SiegeMode { explore, reveal, story, stills }

double _smooth(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// The manifest's frame in metres east and north of the Milion: the area
/// the base map is drawn over.
Rect siegeFrameMetres(SiegeManifest m) {
  final sw = projectMetres(m.frame.south, m.frame.west);
  final ne = projectMetres(m.frame.north, m.frame.east);
  return Rect.fromLTRB(sw.dx, sw.dy, ne.dx, ne.dy);
}

double _within(double v, double lo, double hi) =>
    lo > hi ? (lo + hi) / 2 : v.clamp(lo, hi);

/// [v] as a screen of [size] can show it without looking past the base: a
/// view wider or taller than the frame is narrowed, and its centre moved in
/// until the screen's edges are inside the frame. (On a tall phone the home
/// view otherwise ran past the drawn sea, which ended in a straight edge.)
SiegeView fitView(SiegeView v, Size size, SiegeManifest m) {
  if (size.isEmpty) return v;
  final f = siegeFrameMetres(m);
  final aspect = size.height / size.width;
  final width = math.min(v.width, math.min(f.width, f.height / aspect));
  final height = width * aspect;
  final c = projectMetres(v.lat, v.lng);
  final x = _within(c.dx, f.left + width / 2, f.right - width / 2);
  final y = _within(c.dy, f.top + height / 2, f.bottom - height / 2);
  if (x == c.dx && y == c.dy && width == v.width) return v;
  final at = unprojectMetres(Offset(x, y));
  return SiegeView.of(at.lat, at.lng, width);
}

/// One owner for the map sequence's day, camera and timeline (P15, XIX).
/// The reveal follows the ships over the hill on 22 April; the story walks
/// the 53 days beat by beat; exploring, a finger picks the day.
class SiegeController extends ChangeNotifier {
  SiegeController(this.manifest)
    : _day = manifest.beats.first.day,
      _view = manifest.home;
  final SiegeManifest manifest;

  SiegeMode _mode = SiegeMode.explore;
  SiegeMode get mode => _mode;
  double _t = 0;
  double get seconds => _t;
  bool get playing => _mode == SiegeMode.reveal || _mode == SiegeMode.story;
  bool get needsTicker => playing;

  bool _reduced = false;
  bool get reduced => _reduced;
  void setReduced(bool value) {
    if (_reduced == value) return;
    _reduced = value;
    if (value && playing) stills();
    notifyListeners();
  }

  int _day;
  SiegeView _view;

  /// The day shown, 1 (6 April 1453) to [SiegeManifest.days] (29 May).
  int get day => switch (_mode) {
    SiegeMode.reveal => manifest.event(manifest.revealEvent).day,
    SiegeMode.story => manifest.beats[storyAt(_t).$1].day,
    SiegeMode.stills => currentStill.day,
    SiegeMode.explore => _day,
  };

  DateTime get date => manifest.dateOf(day);

  /// Where the camera looks.
  SiegeView get view => switch (_mode) {
    SiegeMode.reveal => manifest.revealView,
    SiegeMode.story => _storyView(),
    SiegeMode.stills => currentStill.view,
    SiegeMode.explore => _view,
  };

  /// How far along its path a moving event (the ships overland) has gone:
  /// the reveal and the beat that names it run it; otherwise it has arrived
  /// once its day has passed.
  double progress(SiegeEvent e) {
    switch (_mode) {
      case SiegeMode.reveal:
        if (e.id != manifest.revealEvent) return e.day <= day ? 1 : 0;
        return _smooth((_t - 1.2) / (manifest.revealSeconds - 2.4));
      case SiegeMode.story:
        final (i, _) = storyAt(_t);
        final beat = manifest.beats[i];
        if (!beat.focus.contains(e.id) || e.day != beat.day) {
          return e.day <= day ? 1 : 0;
        }
        var into = _t;
        for (var j = 0; j < i; j++) {
          into -= manifest.beats[j].seconds;
        }
        return _smooth((into - 1.0) / (beat.seconds - 2.0));
      case SiegeMode.stills:
      case SiegeMode.explore:
        return e.day <= day ? 1 : 0;
    }
  }

  int _still = 0;
  int get stillIndex => _still;
  SiegeBeat get currentStill => manifest.beat(manifest.stills[_still]);
  Honesty get honesty => manifest.honesty;

  /// Events on the map today.
  Iterable<SiegeEvent> get shown => manifest.events.where((e) {
    if (_mode == SiegeMode.reveal && e.id == manifest.revealEvent) {
      return true;
    }
    return e.shownOn(day);
  });

  /// Events the current beat names (strong on the map, their accounts
  /// listed); exploring, the events that begin on the day shown.
  List<SiegeEvent> get focused {
    final beat = currentBeat;
    if (beat != null) return [for (final id in beat.focus) manifest.event(id)];
    if (_mode == SiegeMode.reveal) {
      return [manifest.event(manifest.revealEvent)];
    }
    return [
      for (final e in manifest.events)
        if (e.day == day) e,
    ];
  }

  void play() {
    if (_reduced) return stills();
    _mode = SiegeMode.reveal;
    _t = 0;
    notifyListeners();
  }

  void playStory() {
    if (_reduced) return stills();
    _mode = SiegeMode.story;
    _t = 0;
    notifyListeners();
  }

  void stills([int index = 0]) {
    _mode = SiegeMode.stills;
    _still = index.clamp(0, manifest.stills.length - 1);
    notifyListeners();
  }

  void step(int delta) {
    if (_mode == SiegeMode.stills) {
      final n = manifest.stills.length;
      _still = ((_still + delta) % n + n) % n;
      notifyListeners();
      return;
    }
    final beats = manifest.beats;
    final here = day;
    SiegeBeat? target;
    if (delta > 0) {
      for (final b in beats) {
        if (b.day > here) {
          target = b;
          break;
        }
      }
    } else {
      for (final b in beats.reversed) {
        if (b.day < here) {
          target = b;
          break;
        }
      }
    }
    if (target != null) goTo(target);
  }

  void goTo(SiegeBeat beat) {
    _mode = SiegeMode.explore;
    _day = beat.day;
    _view = beat.view;
    notifyListeners();
  }

  /// A finger on the day scale.
  void setDay(int d) {
    if (_mode != SiegeMode.explore) explore();
    final v = d.clamp(1, manifest.days);
    if (v == _day) return;
    _day = v;
    notifyListeners();
  }

  /// The map's size on screen, set by the player as it lays out, so a
  /// finger cannot move or pinch the view past the base.
  Size viewport = Size.zero;

  /// A finger moves or pinches the map (metres east/north; a factor).
  void panBy(double east, double north) {
    if (_mode != SiegeMode.explore) explore();
    final v = fitView(_view, viewport, manifest);
    final dLat = north / 110574;
    final dLng = east / (111320 * math.cos(v.lat * math.pi / 180));
    _view = fitView(
      SiegeView.of(
        (v.lat + dLat).clamp(manifest.frame.south, manifest.frame.north),
        (v.lng + dLng).clamp(manifest.frame.west, manifest.frame.east),
        v.width,
      ),
      viewport,
      manifest,
    );
    notifyListeners();
  }

  void zoomBy(double factor) {
    if (_mode != SiegeMode.explore) explore();
    final v = fitView(_view, viewport, manifest);
    _view = fitView(
      SiegeView.of(v.lat, v.lng, (v.width / factor).clamp(1200.0, 16000.0)),
      viewport,
      manifest,
    );
    notifyListeners();
  }

  void explore() {
    if (_mode == SiegeMode.explore) return;
    _day = day;
    _view = view;
    _mode = SiegeMode.explore;
    notifyListeners();
  }

  void advance(double dt) {
    if (!playing) return;
    _t += dt;
    final end = _mode == SiegeMode.reveal
        ? manifest.revealSeconds
        : manifest.storySeconds;
    if (_t >= end) {
      _t = end;
      _day = day;
      _view = view;
      _mode = SiegeMode.explore;
    }
    notifyListeners();
  }

  (int, double) storyAt(double seconds) {
    var t = seconds;
    final beats = manifest.beats;
    for (var i = 0; i < beats.length; i++) {
      if (t < beats[i].seconds || i == beats.length - 1) {
        return (i, i == 0 ? 1.0 : _smooth(t / 1.6));
      }
      t -= beats[i].seconds;
    }
    return (beats.length - 1, 1.0);
  }

  SiegeView _storyView() {
    final (i, k) = storyAt(_t);
    final beats = manifest.beats;
    if (i == 0 || k >= 1) return beats[i].view;
    final a = beats[i - 1].view, b = beats[i].view;
    return SiegeView.of(
      a.lat + (b.lat - a.lat) * k,
      a.lng + (b.lng - a.lng) * k,
      a.width + (b.width - a.width) * k,
    );
  }

  SiegeBeat? get currentBeat => switch (_mode) {
    SiegeMode.story => manifest.beats[storyAt(_t).$1],
    SiegeMode.stills => currentStill,
    _ => null,
  };

  Localized? get caption => switch (_mode) {
    SiegeMode.reveal => manifest.revealCaption,
    SiegeMode.story || SiegeMode.stills => currentBeat?.caption,
    SiegeMode.explore => null,
  };
}
