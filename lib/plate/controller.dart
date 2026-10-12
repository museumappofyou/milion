import 'package:flutter/foundation.dart';

import '../content/models.dart';
import 'manifest.dart';
import 'timeline.dart';

/// Playback state is explicit: no autoplay, no looping figure gestures.
class PlateController extends ChangeNotifier {
  PlateController(this.manifest) : timeline = PlateTimeline(manifest);
  final PlateManifest manifest;
  final PlateTimeline timeline;
  PlateLayerId layer = PlateLayerId.original;
  PlateLight light = PlateLight.none;
  bool flow = false, spiral = false, playing = false, storyActive = false;
  bool reduced = false, active = true, peekOriginal = false;
  bool gesturePlaying = false;
  bool reveal = false;

  /// LU: the dome photograph mapped back overhead (plates with a projection).
  bool lookUp = false;
  double seconds = 0, effectSeconds = 0, wipe = .5, restoration = 1;

  /// Bumped whenever the story moves its camera (play, seek, step, tick);
  /// pausing, peeking or exploring leave the user's camera alone.
  int cameraRevision = 0;
  double gesturePose = 0, gestureStrength = .25;
  String? selectedDetail;
  bool _resumeAfterPeek = false;
  bool disposed = false;

  double get duration =>
      reveal ? manifest.revealSeconds : manifest.storySeconds;
  PlateSample? get sample => storyActive
      ? timeline.at(seconds, reduced: reduced, reveal: reveal)
      : null;
  PlateLight get visibleLight =>
      peekOriginal ? PlateLight.none : sample?.beat.light ?? light;
  bool get visibleFlow =>
      !peekOriginal && !reduced && (sample?.beat.flow ?? flow);
  bool get visibleSpiral =>
      !peekOriginal && !reduced && (sample?.beat.spiral ?? spiral);
  double get visibleGesture =>
      peekOriginal ? 0 : sample?.gesturePhase ?? gesturePose;
  bool get needsTicker =>
      active &&
      !reduced &&
      !peekOriginal &&
      (playing ||
          gesturePlaying ||
          (!storyActive &&
              layer == PlateLayerId.depth &&
              (visibleLight == PlateLight.candle ||
                  visibleFlow ||
                  visibleSpiral)));
  bool get canLookUp => manifest.lookUp != null;

  /// §3: moving painted pixels (a gesture, flowing fire, a rolling scroll) is
  /// invention, so the whole beat that carries it reads IMAGINED.
  Honesty get honesty => peekOriginal
      ? Honesty.ORIGINAL
      : (visibleGesture > 0 && visibleGesture < 1) ||
            sample?.beat.gesture != null ||
            visibleFlow ||
            visibleSpiral
      ? Honesty.IMAGINED
      : layer == PlateLayerId.reconstruction
      ? Honesty.RECONSTRUCTION
      : storyActive || lookUp || layer == PlateLayerId.depth
      ? Honesty.DEPTH
      : Honesty.ORIGINAL;

  void original() {
    playing = gesturePlaying = storyActive = flow = spiral = peekOriginal =
        false;
    reveal = _resumeAfterPeek = lookUp = false;
    layer = PlateLayerId.original;
    light = PlateLight.none;
    gesturePose = 0;
    notifyListeners();
  }

  void setLayer(PlateLayerId value) {
    if (value == PlateLayerId.original) {
      original();
      return;
    }
    if (!manifest.has(value) && value != PlateLayerId.depth) return;
    playing = gesturePlaying = storyActive = false;
    gesturePose = 0;
    layer = value;
    if (value == PlateLayerId.reconstruction) {
      light = PlateLight.none;
      flow = spiral = false;
    }
    notifyListeners();
  }

  void setLight(PlateLight value) {
    playing = gesturePlaying = storyActive = false;
    gesturePose = 0;
    light = value;
    if (value != PlateLight.none) layer = PlateLayerId.depth;
    notifyListeners();
  }

  void setPaintMotion({bool? river, bool? scroll}) {
    playing = storyActive = false;
    flow = river ?? flow;
    spiral = scroll ?? spiral;
    if (flow || spiral) layer = PlateLayerId.depth;
    notifyListeners();
  }

  void setLookUp(bool value) {
    if (!canLookUp) return;
    playing = gesturePlaying = storyActive = false;
    lookUp = value;
    if (value) layer = PlateLayerId.depth;
    notifyListeners();
  }

  void focus(String? id) {
    playing = storyActive = false;
    selectedDetail = id;
    notifyListeners();
  }

  void explore() {
    if (storyActive) {
      light = visibleLight;
      flow = visibleFlow;
      spiral = visibleSpiral;
      selectedDetail = sample!.beat.detailId;
    }
    playing = gesturePlaying = storyActive = false;
    gesturePose = 0;
    notifyListeners();
  }

  void seek(double value) => _seek(value, reveal: false);

  /// Scrubbing the reveal stays inside the reveal.
  void seekReveal(double value) => _seek(value, reveal: true);

  void _seek(double value, {required bool reveal}) {
    if (!value.isFinite) return;
    this.reveal = reveal;
    seconds = value.clamp(0, duration);
    playing = gesturePlaying = false;
    gesturePose = 0;
    storyActive = true;
    layer = PlateLayerId.depth;
    lookUp = canLookUp;
    cameraRevision++;
    notifyListeners();
  }

  void play() {
    if (reduced) {
      step(1);
      return;
    }
    if (reveal || seconds >= manifest.storySeconds) seconds = 0;
    reveal = false;
    storyActive = playing = true;
    gesturePlaying = false;
    gesturePose = 0;
    layer = PlateLayerId.depth;
    lookUp = canLookUp;
    cameraRevision++;
    notifyListeners();
  }

  void playReveal() {
    if (reduced) {
      seekReveal(0);
      return;
    }
    seconds = 0;
    reveal = true;
    storyActive = playing = true;
    gesturePlaying = false;
    gesturePose = 0;
    layer = PlateLayerId.depth;
    lookUp = canLookUp;
    cameraRevision++;
    notifyListeners();
  }

  void pause() {
    playing = gesturePlaying = false;
    notifyListeners();
  }

  void step(int delta) {
    final i = !storyActive || reveal
        ? (delta > 0 ? 0 : manifest.beats.length - 1)
        : (sample!.index + delta).clamp(0, manifest.beats.length - 1);
    seek(manifest.beats[i].start);
  }

  void advance(double delta) {
    if (!needsTicker || !delta.isFinite || delta <= 0) return;
    if (playing) {
      seconds = (seconds + delta).clamp(0, duration);
      if (seconds >= duration) playing = false;
      cameraRevision++;
    }
    if (gesturePlaying) {
      gesturePose = (gesturePose + delta / 6).clamp(0, 1);
      if (gesturePose >= 1) gesturePlaying = false;
    }
    effectSeconds += delta;
    notifyListeners();
  }

  void setReduced(bool value) {
    if (reduced == value) return;
    reduced = value;
    if (value) {
      playing = gesturePlaying = false;
      gesturePose = 0;
      if (storyActive) seconds = sample!.beat.start;
      cameraRevision++;
    }
    notifyListeners();
  }

  void peek(bool value) {
    if (value) {
      _resumeAfterPeek = playing;
      playing = false;
    }
    peekOriginal = value;
    if (!value && _resumeAfterPeek && !reduced && active) playing = true;
    notifyListeners();
  }

  void setWipe(double value) {
    wipe = value.clamp(0, 1);
    notifyListeners();
  }

  void setRestoration(double value) {
    restoration = value.clamp(0, 1);
    notifyListeners();
  }

  void setStrength(double value) {
    gestureStrength = value.clamp(.1, .35);
    notifyListeners();
  }

  void scrubGesture(double value) {
    playing = gesturePlaying = storyActive = false;
    gesturePose = value.clamp(0, 1);
    notifyListeners();
  }

  void playGesture() {
    if (reduced) return;
    playing = storyActive = false;
    gesturePose = 0;
    gesturePlaying = true;
    notifyListeners();
  }

  void suspend() {
    active = playing = gesturePlaying = false;
    notifyListeners();
  }

  void resume() {
    active = true;
    notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
