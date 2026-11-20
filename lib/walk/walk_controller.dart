import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../content/models.dart';
import 'walk.dart';

/// What the walk is doing: the 10-second reveal, the story through its
/// stops, the stills (reduced motion), or free walking on the deck.
enum WalkMode { explore, reveal, story, stills }

/// An interactive stepping circle placed along the visitors' walkway.
@immutable
class WalkWaypoint {
  const WalkWaypoint({required this.s, required this.point, this.stop});
  final double s;
  final WalkPoint point;
  final WalkStop? stop;
}

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

double _wrapAngle(double a) {
  var x = a;
  while (x > math.pi) {
    x -= 2 * math.pi;
  }
  while (x < -math.pi) {
    x += 2 * math.pi;
  }
  return x;
}

/// One owner for a walk's camera, timeline, interactive moving circles,
/// tappable callout cards, and lights.
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
    waypoints = _buildWaypoints();
  }
  final WalkManifest manifest;

  /// Interactive stepping circles laid out along the deck (~1 per vault bay)
  /// plus every stop so visitors can tap directly onto the walkway to move.
  late final List<WalkWaypoint> waypoints;

  List<WalkWaypoint> _buildWaypoints() {
    final out = <WalkWaypoint>[];
    final y = manifest.grid.deckHeight + 0.04;
    final total = manifest.routeLength;
    final step = manifest.grid.pitchX;
    // Named stop circles on the deck first.
    final stopS = <(double, WalkStop)>[];
    for (final st in manifest.stops) {
      if ((st.eye.y - manifest.grid.eye).abs() > 0.4) continue;
      final s = manifest.nearest(st.eye.x, st.eye.z);
      stopS.add((s, st));
      final (x, z, _) = manifest.along(s);
      out.add(WalkWaypoint(s: s, point: WalkPoint(x, y, z), stop: st));
    }
    // Regular stepping circles every ~1 bay wherever no stop is already within 2.5 m.
    for (var s = 0.0; s <= total; s += step) {
      if (stopS.any((e) => (e.$1 - s).abs() < 2.5)) continue;
      final (x, z, _) = manifest.along(s);
      out.add(WalkWaypoint(s: s, point: WalkPoint(x, y, z)));
    }
    out.sort((a, b) => a.s.compareTo(b.s));
    return List.unmodifiable(out);
  }

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
      _cancelGlide();
      _padForward = 0;
      _padTurn = 0;
      if (playing) stills();
    }
    notifyListeners();
  }

  // Walking on the deck: metres along the route, and full X/Y head angles.
  double _s = 0, _yaw = 0, _pitch = 0;
  WalkPoint? _standEye;
  double get position => _s;
  double get yaw => _yaw;
  double get pitch => _pitch;

  // Smooth waypoint glide when tapping an interactive moving circle.
  double? _glideFromS, _glideToS, _glideYawDelta, _glidePitchDelta;
  double _glideStartYaw = 0, _glideStartPitch = 0;
  WalkPoint? _glideFromEye;
  double _glideElapsed = 0, _glideDuration = 0;
  bool get gliding => _glideToS != null;

  // Continuous virtual movement-circle input (forward m/s, turn rad/s).
  double _padForward = 0, _padTurn = 0;
  bool get padActive => _padForward.abs() > 1e-3 || _padTurn.abs() > 1e-3;

  // Currently selected tappable architectural callout card.
  WalkCallout? _selectedCallout;
  WalkCallout? get selectedCallout => _selectedCallout;
  void selectCallout(WalkCallout? callout) {
    if (_selectedCallout?.id == callout?.id) return;
    _selectedCallout = callout;
    notifyListeners();
  }

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
    if (!value) _selectedCallout = null;
    notifyListeners();
  }

  Honesty get honesty => _fish ? Honesty.IMAGINED : manifest.honesty;

  /// The frame needs ticking: timeline, gliding between circles, pad input, or fish.
  bool get needsTicker => playing || _fish || gliding || padActive;

  void _cancelGlide() {
    _glideFromS = null;
    _glideToS = null;
    _glideFromEye = null;
    _glideYawDelta = null;
    _glidePitchDelta = null;
  }

  void play() {
    _cancelGlide();
    _selectedCallout = null;
    if (_reduced) return stills();
    _mode = WalkMode.reveal;
    _t = 0;
    notifyListeners();
  }

  void playStory() {
    _cancelGlide();
    _selectedCallout = null;
    if (_reduced) return stills();
    _mode = WalkMode.story;
    _t = 0;
    notifyListeners();
  }

  void stills([int index = 0]) {
    _cancelGlide();
    _selectedCallout = null;
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
    _cancelGlide();
    _selectedCallout = null;
    _mode = WalkMode.explore;
    _s = manifest.nearest(stop.eye.x, stop.eye.z);
    _standEye = (stop.eye.y - manifest.grid.eye).abs() > 0.2 ? stop.eye : null;
    final c = WalkCamera(stop.eye, stop.look);
    _yaw = c.yaw;
    _pitch = c.pitch;
    notifyListeners();
  }

  /// Smoothly glides along the walkway to an interactive stepping circle.
  void glideToWaypoint(WalkWaypoint wp) {
    if (_mode != WalkMode.explore) explore();
    _selectedCallout = null;
    final targetS = wp.s.clamp(0.0, manifest.routeLength);
    final dist = (targetS - _s).abs();
    if (_reduced || (dist < 0.15 && _standEye == null)) {
      _cancelGlide();
      _s = targetS;
      _standEye = null;
      if (wp.stop case final st?) {
        final c = WalkCamera(st.eye, st.look);
        _yaw = c.yaw;
        _pitch = c.pitch;
      }
      notifyListeners();
      return;
    }
    _glideFromS = _s;
    _glideToS = targetS;
    _glideFromEye = _standEye;
    _standEye = null;
    _glideElapsed = 0;
    _glideDuration = (dist / 5.5).clamp(0.45, 2.4);
    _glideStartYaw = _yaw;
    _glideStartPitch = _pitch;
    if (wp.stop case final st?) {
      final c = WalkCamera(st.eye, st.look);
      _glideYawDelta = _wrapAngle(c.yaw - _yaw);
      _glidePitchDelta = c.pitch - _pitch;
    } else {
      final (_, _, heading) = manifest.along(targetS);
      final targetYaw = targetS >= _s ? heading : heading + math.pi;
      _glideYawDelta = _wrapAngle(targetYaw - _yaw) * 0.55;
      _glidePitchDelta = (0.0 - _pitch) * 0.35;
    }
    notifyListeners();
  }

  /// Steps one bay forward (+1) or backward (-1) along the facing direction.
  void stepAlongFacing(int direction) {
    if (_mode != WalkMode.explore) explore();
    final heading = manifest.along(_s).$3;
    final facing = math.cos(_yaw - heading) >= 0 ? 1.0 : -1.0;
    final targetS = (_s + direction * facing * manifest.grid.pitchX).clamp(
      0.0,
      manifest.routeLength,
    );
    final (x, z, _) = manifest.along(targetS);
    glideToWaypoint(
      WalkWaypoint(
        s: targetS,
        point: WalkPoint(x, manifest.grid.deckHeight + 0.04, z),
      ),
    );
  }

  /// Sets continuous joystick movement from the interactive move circle.
  void setPadInput(double forward, double turn) {
    if (_reduced) return;
    if ((forward.abs() > 1e-3 || turn.abs() > 1e-3) &&
        _mode != WalkMode.explore) {
      explore();
    }
    if (forward.abs() > 1e-3) {
      _cancelGlide();
      _standEye = null;
    }
    if ((_padForward - forward).abs() < 1e-4 &&
        (_padTurn - turn).abs() < 1e-4) {
      return;
    }
    _padForward = forward.clamp(-1.0, 1.0);
    _padTurn = turn.clamp(-1.0, 1.0);
    notifyListeners();
  }

  /// A touch hands the reveal or story back: walking continues from where
  /// the camera was.
  void explore() {
    if (_mode == WalkMode.explore) return;
    final c = camera;
    _s = manifest.nearest(c.eye.x, c.eye.z);
    _standEye = (c.eye.y - manifest.grid.eye).abs() > 0.2 ? c.eye : null;
    _yaw = c.yaw;
    _pitch = c.pitch.clamp(-1.15, 1.15);
    _mode = WalkMode.explore;
    notifyListeners();
  }

  /// Free 360° horizontal (X) and vertical (Y) head rotation by touch drag.
  void lookBy(double dYaw, double dPitch) {
    if (_mode != WalkMode.explore) explore();
    _cancelGlide();
    _yaw += dYaw;
    _pitch = (_pitch + dPitch).clamp(-1.15, 1.15);
    notifyListeners();
  }

  /// A thumb on the deck: [forward] metres along the route, turning by
  /// [turn] radians and tipping by [tip] radians (Y-axis pitch).
  void walk({double forward = 0, double turn = 0, double tip = 0}) {
    if (_mode != WalkMode.explore) explore();
    _cancelGlide();
    if (forward.abs() > 1e-4) _standEye = null;
    final heading = manifest.along(_s).$3;
    // Forward follows where the head points: facing back down the deck,
    // pushing forward walks back.
    final facing = math.cos(_yaw - heading) >= 0 ? 1.0 : -1.0;
    _s = (_s + forward * facing).clamp(0.0, manifest.routeLength);
    _yaw += turn;
    _pitch = (_pitch + tip).clamp(-1.15, 1.15);
    notifyListeners();
  }

  /// The look sensor (after opt-in) sets the head directly.
  void look(double yaw, double pitch) {
    if (_mode != WalkMode.explore) explore();
    _cancelGlide();
    _yaw = yaw;
    _pitch = pitch.clamp(-1.2, 1.2);
    notifyListeners();
  }

  void advance(double dt) {
    if (playing) {
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
      return;
    }
    var changed = false;
    if (gliding) {
      _glideElapsed += dt;
      final k = _smooth(_glideElapsed / math.max(0.05, _glideDuration));
      _s = _glideFromS! + (_glideToS! - _glideFromS!) * k;
      if (_glideYawDelta != null) {
        _yaw = _glideStartYaw + _glideYawDelta! * k;
      }
      if (_glidePitchDelta != null) {
        _pitch = (_glideStartPitch + _glidePitchDelta! * k).clamp(-1.15, 1.15);
      }
      if (_glideElapsed >= _glideDuration) {
        _s = _glideToS!;
        _cancelGlide();
      }
      changed = true;
    }
    if (padActive) {
      final safeDt = dt.clamp(0.0, 0.1);
      final heading = manifest.along(_s).$3;
      final facing = math.cos(_yaw - heading) >= 0 ? 1.0 : -1.0;
      _s = (_s + _padForward * 5.2 * safeDt * facing).clamp(
        0.0,
        manifest.routeLength,
      );
      _yaw += _padTurn * 1.45 * safeDt;
      changed = true;
    }
    if (changed) notifyListeners();
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
        // Follow the visitors' walkway route between stops so the story camera
        // turns cleanly around corners and never flies through solid columns.
        final sFrom = manifest.nearest(from.eye.x, from.eye.z);
        final sTo = manifest.nearest(to.eye.x, to.eye.z);
        final s = sFrom + (sTo - sFrom) * k;
        final (rx, rz, heading) = manifest.along(s);
        final (rfx, rfz, _) = manifest.along(sFrom);
        final (rtx, rtz, _) = manifest.along(sTo);
        final wf = (1 - k) * (1 - k) * (1 - k);
        final wt = k * k * k;
        final ex = rx + (from.eye.x - rfx) * wf + (to.eye.x - rtx) * wt;
        final ez = rz + (from.eye.z - rfz) * wf + (to.eye.z - rtz) * wt;
        final ey = from.eye.y + (to.eye.y - from.eye.y) * k;
        final eye = WalkPoint(ex, ey, ez);
        var look = WalkPoint.lerp(from.look, to.look, k);
        if ((sTo - sFrom).abs() >= 8.0) {
          final dir = sTo >= sFrom ? heading : heading + math.pi;
          final ahead = WalkPoint(
            ex + math.cos(dir) * 10.0,
            ey - 0.15,
            ez + math.sin(dir) * 10.0,
          );
          look = WalkPoint.lerp(look, ahead, math.sin(math.pi * k) * 0.75);
        }
        return WalkCamera(eye, look);
      case WalkMode.reveal:
        // From a close look at the head out to the stop's view.
        final stop = manifest.stop(manifest.revealStop);
        final k = _smooth((_t - 2.5) / 4.5);
        final near = WalkPoint.lerp(stop.look, stop.eye, .38);
        return WalkCamera(WalkPoint.lerp(near, stop.eye, k), stop.look);
      case WalkMode.explore:
        final (x, z, _) = manifest.along(_s);
        WalkPoint eye;
        if (_standEye != null) {
          eye = _standEye!;
        } else if (_glideFromEye != null && gliding) {
          final k = _smooth(_glideElapsed / math.max(0.05, _glideDuration));
          eye = WalkPoint.lerp(
            _glideFromEye!,
            WalkPoint(x, manifest.grid.eye, z),
            k,
          );
        } else {
          eye = WalkPoint(x, manifest.grid.eye, z);
        }
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
        if ((c.anchor - eye).length < 22) c,
    ];
  }
}
