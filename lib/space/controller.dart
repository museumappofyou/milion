import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../content/models.dart';
import 'camera.dart';
import 'model.dart';
import 'renderer.dart';
import 'study.dart';
import 'style.dart';

double _smooth(double x) => x * x * (3 - 2 * x);

class SpaceBeat {
  const SpaceBeat(this.index, this.step, this.epoch, this.start, this.duration);
  final int index, epoch;
  final SpaceStep step;
  final double start, duration;
  double get end => start + duration;

  /// The still for this beat: its parts fully in place.
  double get still => start + duration * .6;
}

/// The assembly at one moment: [assembly] counts steps of [epoch] (an index
/// into the study's epochs), optionally blending in from an earlier moment.
class SpaceMoment {
  const SpaceMoment(
    this.epoch,
    this.assembly, {
    this.fromEpoch,
    this.fromAssembly = 0,
    this.blend = 1,
  });
  final int epoch;
  final double assembly;
  final int? fromEpoch;
  final double fromAssembly, blend;
}

class SpaceSample {
  const SpaceSample(this.beat, this.moment, this.turn);
  final SpaceBeat beat;
  final SpaceMoment moment;

  /// The reveal's slow camera turn, in radians.
  final double turn;
}

/// Seekable, frame-rate independent story: each step's parts settle in the
/// first 60% of its beat; a step from a later epoch switches the time scrubber
/// and cross-fades the parts that differ.
class SpaceTimeline {
  SpaceTimeline(this.study) {
    beats = _beats(study.steps, 1);
    final through = study.steps.indexWhere((s) => s.id == study.reveal.through);
    final steps = study.steps.take(through + 1).toList();
    revealBeats = _beats(
      steps,
      study.reveal.seconds / steps.fold(0.0, (t, s) => t + s.seconds),
    );
  }
  final SpaceStudy study;
  late final List<SpaceBeat> beats, revealBeats;

  List<SpaceBeat> _beats(List<SpaceStep> steps, double scale) {
    var epoch = 0;
    var t = 0.0;
    final out = <SpaceBeat>[];
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      if (!s.inEpoch(study.epochs[epoch].year)) {
        epoch = study.epochs.indexWhere((e) => s.inEpoch(e.year));
      }
      out.add(SpaceBeat(i, s, epoch, t, s.seconds * scale));
      t += s.seconds * scale;
    }
    return List.unmodifiable(out);
  }

  int stepIndex(SpaceStep s, int epoch) =>
      study.stepsIn(study.epochs[epoch].year).indexOf(s);

  SpaceSample at(double seconds, {bool reveal = false, bool reduced = false}) {
    if (!seconds.isFinite) throw const FormatException('Non-finite story time');
    final beats = reveal ? revealBeats : this.beats;
    final total = beats.last.end;
    final t = seconds.clamp(0.0, total);
    var i = beats.indexWhere((b) => t < b.end);
    if (i < 0) i = beats.length - 1;
    final b = beats[i];
    final x = reduced
        ? 1.0
        : ((t - b.start) / (b.duration * .6)).clamp(0.0, 1.0);
    final assembly = stepIndex(b.step, b.epoch) + _smooth(x);
    final previous = i > 0 ? beats[i - 1] : null;
    final SpaceMoment moment;
    if (previous != null && previous.epoch != b.epoch) {
      final y = reduced
          ? 1.0
          : ((t - b.start) / (b.duration * .3)).clamp(0.0, 1.0);
      moment = SpaceMoment(
        b.epoch,
        assembly,
        fromEpoch: previous.epoch,
        fromAssembly: stepIndex(previous.step, previous.epoch) + 1.0,
        blend: _smooth(y),
      );
    } else {
      moment = SpaceMoment(b.epoch, assembly);
    }
    final turn = reveal && !reduced
        ? study.reveal.turnDegrees * math.pi / 180 * (t / total)
        : 0.0;
    return SpaceSample(b, moment, turn);
  }
}

/// Playback and exploration state for one study. Nothing plays until asked.
class SpaceController extends ChangeNotifier {
  SpaceController(this.study, this.model)
    : timeline = SpaceTimeline(study),
      limits = SpaceLimits(model.bounds) {
    _index = [
      for (final e in study.epochs)
        Int32List.fromList([
          for (final p in model.parts)
            study.stepsIn(e.year).indexWhere((s) => s.parts.contains(p.id)),
        ]),
    ];
    // Opens in Choisy's view: from below, the plan cut through the piers.
    view = choisyView;
    assembly = _assemblyTarget = steps.length.toDouble();
    section = true;
    sectionAxis = 2;
    sectionOffset = model.bounds.minZ + study.choisy.sectionHeight;
  }
  final SpaceStudy study;
  final SpaceModel model;
  final SpaceTimeline timeline;
  final SpaceLimits limits;
  late final List<Int32List> _index;

  SpaceStyle style = SpaceStyle.drawing;
  late SpaceView view;
  int epoch = 0;
  late double assembly;
  late double _assemblyTarget;
  double explode = 0, seconds = 0, sectionOffset = 0;
  bool section = false, playing = false, storyActive = false, reveal = false;
  bool reduced = false, active = true, disposed = false;
  int sectionAxis = 1;

  /// Bumped when the story moves the camera itself.
  int cameraRevision = 0;
  bool _captioned = false;
  int? _fromEpoch;
  double _fromAssembly = 0, _blend = 1, _viewT = 1;
  SpaceView? _viewFrom, _viewTo;

  SpaceView get choisyView => limits.clamp(
    SpaceView.choisy(
      model.bounds,
      elevation: study.choisy.elevationDegrees * math.pi / 180,
      azimuth: study.choisy.azimuthDegrees * math.pi / 180,
    ),
  );

  /// The reveal frames only the parts it assembles: their bounds' centre,
  /// zoomed so they fill about as much as the whole model does, a little
  /// less (P08's bay, 0.92 × 58.2 / 41.3 m, gives the 1.3 it was tuned to).
  static const revealFill = .92;
  late final SpaceBounds revealBounds = () {
    final through = study.steps.indexWhere((s) => s.id == study.reveal.through);
    final ids = {for (final s in study.steps.take(through + 1)) ...s.parts};
    return SpaceBounds.of([
      for (final p in model.parts)
        if (ids.contains(p.id)) p.positions,
    ]);
  }();
  SpaceView get revealView {
    final b = revealBounds;
    return limits.clamp(
      choisyView.copyWith(
        zoom: math.max(1.0, revealFill * model.bounds.radius / b.radius),
        targetX: b.centerX,
        targetY: b.centerY,
        targetZ: b.centerZ,
      ),
    );
  }

  int get epochYear => study.epochs[epoch].year;
  List<SpaceStep> get steps => study.stepsIn(epochYear);
  double get duration => reveal ? study.reveal.seconds : study.storySeconds;
  SpaceSample? get sample => storyActive
      ? timeline.at(seconds, reveal: reveal, reduced: reduced)
      : null;
  SpaceMoment get moment =>
      sample?.moment ??
      SpaceMoment(
        epoch,
        assembly,
        fromEpoch: _blend < 1 ? _fromEpoch : null,
        fromAssembly: _fromAssembly,
        blend: _blend,
      );
  int get visibleEpoch => moment.epoch;
  Honesty get honesty => study.honesty;
  SpaceSection? get sectionPlane =>
      section ? SpaceSection(sectionAxis, sectionOffset) : null;
  SpaceView get visibleView {
    final turn = sample?.turn ?? 0;
    return turn == 0 ? view : limits.clamp(view.orbit(turn, 0));
  }

  /// The step whose caption is read: the story's beat, or the last step the
  /// reader assembled by hand.
  SpaceStep? get currentStep {
    final s = sample;
    if (s != null) return s.beat.step;
    if (!_captioned) return null;
    final i = assembly.ceil() - 1;
    return i >= 0 && i < steps.length ? steps[i] : null;
  }

  Localized? get caption =>
      reveal && storyActive ? study.reveal.caption : currentStep?.caption;

  bool get needsTicker =>
      active &&
      !reduced &&
      (playing || _viewT < 1 || _blend < 1 || assembly != _assemblyTarget);

  List<SpacePartState> partStates() {
    final m = moment, bounds = model.bounds;
    // Scaled to the building: P08's 56 m bay in eight steps drops parts
    // from 7 m and lifts each step 6 m when exploded.
    final height = math.max(bounds.maxZ - bounds.minZ, 1.0);
    final drop = reduced ? 0.0 : height * .125;
    final lift = height * .75 / math.max(1, steps.length - 1);
    return [
      for (var i = 0; i < model.parts.length; i++)
        () {
          final j = _index[m.epoch][i];
          final to = j < 0 ? 0.0 : (m.assembly - j).clamp(0.0, 1.0);
          var p = to;
          final from = m.fromEpoch;
          if (from != null && m.blend < 1) {
            final k = _index[from][i];
            final was = k < 0 ? 0.0 : (m.fromAssembly - k).clamp(0.0, 1.0);
            p = was + (to - was) * m.blend;
          }
          if (p <= 0) return SpacePartState.hidden;
          final rank = j >= 0 ? j : _index[from ?? m.epoch][i];
          final part = model.parts[i];
          var dz = explode * math.max(rank, 0) * lift;
          if (j >= 0 && to < 1) dz += (1 - _smooth(to)) * drop;
          return SpacePartState(
            progress: p,
            dx: explode * (part.bounds.centerX - bounds.centerX) * .35,
            dy: explode * (part.bounds.centerY - bounds.centerY) * .35,
            dz: dz,
          );
        }(),
    ];
  }

  SpaceScene scene() => SpaceScene(
    view: visibleView,
    style: style,
    parts: partStates(),
    section: sectionPlane,
  );

  /// A finger moved the camera: the story stops where it is.
  void setView(SpaceView value) {
    explore();
    _viewT = 1;
    view = limits.clamp(value);
    notifyListeners();
  }

  void animateView(SpaceView value) {
    _viewFrom = view;
    _viewTo = limits.clamp(value);
    _viewT = reduced ? 1 : 0;
    if (reduced) view = _viewTo!;
    cameraRevision++;
    notifyListeners();
  }

  /// Choisy's worm's-eye axonometric with the plan cut through the piers.
  void choisy() {
    section = true;
    sectionAxis = 2;
    sectionOffset = model.bounds.minZ + study.choisy.sectionHeight;
    animateView(choisyView);
  }

  void setStyle(SpaceStyle value) {
    style = value;
    notifyListeners();
  }

  void setSection(bool value) {
    section = value;
    notifyListeners();
  }

  void setSectionAxis(int axis) {
    if (axis == sectionAxis) return;
    sectionAxis = axis;
    sectionOffset = [
      model.bounds.centerX,
      model.bounds.centerY,
      model.bounds.minZ + study.choisy.sectionHeight,
    ][axis];
    section = true;
    notifyListeners();
  }

  void setSectionOffset(double value) {
    if (!value.isFinite) return;
    sectionOffset = value.clamp(
      model.bounds.min(sectionAxis),
      model.bounds.max(sectionAxis),
    );
    section = true;
    notifyListeners();
  }

  void setExplode(double value) {
    explore();
    explode = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// The time scrubber: the same bay at another year.
  void setEpoch(int value) {
    if (value == epoch || value < 0 || value >= study.epochs.length) return;
    explore();
    final full = assembly >= steps.length - 1e-9;
    _fromEpoch = epoch;
    _fromAssembly = assembly;
    epoch = value;
    assembly = _assemblyTarget = full
        ? steps.length.toDouble()
        : math.min(assembly, steps.length.toDouble());
    _blend = reduced ? 1 : 0;
    _captioned = true;
    notifyListeners();
  }

  /// The assembly scrubber, in steps of the current epoch.
  void seekAssembly(double value) {
    if (!value.isFinite) return;
    explore();
    assembly = _assemblyTarget = value.clamp(0.0, steps.length.toDouble());
    _captioned = true;
    notifyListeners();
  }

  void seek(double value) => _seek(value, reveal: false);
  void seekReveal(double value) => _seek(value, reveal: true);

  void _seek(double value, {required bool reveal}) {
    if (!value.isFinite) return;
    this.reveal = reveal;
    seconds = value.clamp(0.0, duration);
    playing = false;
    storyActive = true;
    notifyListeners();
  }

  /// Next and Previous walk the story as stills (the reduced-motion story).
  void step(int delta) {
    final beats = timeline.beats;
    final i = !storyActive || reveal
        ? (delta > 0 ? 0 : beats.length - 1)
        : (sample!.beat.index + delta).clamp(0, beats.length - 1);
    seek(beats[i].still);
  }

  void play() {
    if (reduced) {
      step(1);
      return;
    }
    if (reveal || seconds >= study.storySeconds) seconds = 0;
    reveal = false;
    if (seconds == 0) animateView(choisyView);
    storyActive = playing = true;
    notifyListeners();
  }

  /// The hook: the bay assembling in Choisy's view, with the plan cut,
  /// framed closer because only the bay stands.
  void playReveal() {
    section = true;
    sectionAxis = 2;
    sectionOffset = model.bounds.minZ + study.choisy.sectionHeight;
    view = revealView;
    _viewT = 1;
    cameraRevision++;
    if (reduced) {
      seekReveal(study.reveal.seconds);
      return;
    }
    seconds = 0;
    reveal = true;
    storyActive = playing = true;
    notifyListeners();
  }

  void pause() {
    playing = false;
    notifyListeners();
  }

  /// Leaves the story where it stands and hands the controls back.
  void explore() {
    final s = sample;
    if (s != null) {
      epoch = s.moment.epoch;
      assembly = _assemblyTarget = s.moment.assembly;
      _fromEpoch = s.moment.fromEpoch;
      _fromAssembly = s.moment.fromAssembly;
      _blend = s.moment.fromEpoch == null ? 1 : s.moment.blend;
      view = visibleView;
      _captioned = true;
    }
    playing = storyActive = reveal = false;
  }

  void advance(double delta) {
    if (!needsTicker || !delta.isFinite || delta <= 0) return;
    if (playing) {
      seconds = math.min(seconds + delta, duration);
      if (seconds >= duration) playing = false;
    }
    if (_viewT < 1) {
      _viewT = math.min(1, _viewT + delta / .6);
      view = _viewT >= 1
          ? _viewTo!
          : SpaceView.lerp(_viewFrom!, _viewTo!, _smooth(_viewT));
    }
    if (_blend < 1) _blend = math.min(1, _blend + delta / .8);
    if (assembly != _assemblyTarget) {
      final d = _assemblyTarget - assembly;
      final move = delta * 1.5;
      assembly = d.abs() <= move ? _assemblyTarget : assembly + move * d.sign;
    }
    notifyListeners();
  }

  void setReduced(bool value) {
    if (reduced == value) return;
    reduced = value;
    if (value) {
      playing = false;
      if (_viewT < 1) view = _viewTo!;
      _viewT = _blend = 1;
      assembly = _assemblyTarget;
      if (storyActive) seconds = sample!.beat.still;
    }
    notifyListeners();
  }

  void suspend() {
    active = playing = false;
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
