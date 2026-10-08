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
  double seconds = 0, effectSeconds = 0, wipe = .5, restoration = 1;
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
  Honesty get honesty => peekOriginal
      ? Honesty.ORIGINAL
      : visibleGesture > 0 && visibleGesture < 1
      ? Honesty.IMAGINED
      : layer == PlateLayerId.reconstruction
      ? Honesty.RECONSTRUCTION
      : storyActive || layer == PlateLayerId.depth
      ? Honesty.DEPTH
      : Honesty.ORIGINAL;

  void original() {
    playing = gesturePlaying = storyActive = flow = spiral = peekOriginal =
        false;
    reveal = _resumeAfterPeek = false;
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

  void seek(double value) {
    if (!value.isFinite) return;
    seconds = value.clamp(0, manifest.storySeconds);
    reveal = false;
    playing = gesturePlaying = false;
    gesturePose = 0;
    storyActive = true;
    layer = PlateLayerId.depth;
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
    notifyListeners();
  }

  void playReveal() {
    if (reduced) {
      seek(0);
      return;
    }
    seconds = 0;
    reveal = true;
    storyActive = playing = true;
    gesturePlaying = false;
    gesturePose = 0;
    layer = PlateLayerId.depth;
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
