import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../content/geography.dart';
import '../content/json_reader.dart';
import '../content/models.dart';
import '../space/camera.dart';
import '../space/controller.dart';
import '../space/model.dart';
import '../space/renderer.dart';
import '../space/study.dart';
import '../space/style.dart';

/// Milestone 0's kit study (P13), drawn inside the first run's 12-second
/// clock: the fragment on Divanyolu, then the domed tetrapylon assembling
/// around it while the camera pulls back, then the camera tips over to the
/// plan and shrinks to the street plan's scale, north up, so the drawing
/// hands over to the map where it stands.
class MilionIntro {
  MilionIntro(this.study, this.model)
    : renderer = SpaceRenderer(model),
      controller = SpaceController(study, model) {
    final extent = SpaceBounds.of([
      for (final p in model.parts)
        if (_monument.contains(p.id)) p.positions,
    ]);
    monument = extent;
  }
  static const asset = 'assets/space/milion/study.json';

  /// The parts that frame the closing view of the assembly: the tetrapylon
  /// and its fragment, not the streets.
  static const _monument = {
    'fragment',
    'pier-fragment',
    'pier-fragment-back',
    'pier-fragment-top',
    'piers',
    'arches',
    'pendentives',
    'vault',
  };

  static Future<MilionIntro> load(
    Future<ByteData> Function(String) bytes,
  ) async {
    final json = utf8.decode((await bytes(asset)).buffer.asUint8List());
    final study = SpaceStudy.fromJson(jsonDecode(json) as Json);
    final model = SpaceModel.fromGlb(await bytes(study.model));
    study.checkModel(model);
    return MilionIntro(study, model);
  }

  final SpaceStudy study;
  final SpaceModel model;
  final SpaceRenderer renderer;
  final SpaceController controller;
  late final SpaceBounds monument;

  /// The model's +y runs along Divanyolu toward the west (the study's axis,
  /// 271.5°), so true north is 90° − (axis − 270°) anticlockwise from +x in
  /// the model's frame; the camera looks from the south to put it up.
  double get _north => (360 - (study.orientation?.axis ?? 270) + 90) % 360;

  /// Metres east and north of the Milion as model x and y.
  (double, double) model2(double east, double north) {
    final a = _north * math.pi / 180;
    final ex = math.sin(a), ey = -math.cos(a); // model coords of east
    final nx = math.cos(a), ny = math.sin(a); // model coords of north
    return (east * ex + north * nx, east * ey + north * ny);
  }

  double _zoomFor(Size size, double pixelsPerMetre) =>
      pixelsPerMetre /
      (math.min(size.width, size.height) * .66 / model.bounds.radius);

  /// The camera at [t] seconds into the first run. [planScale] and
  /// [planCentre] are the street plan's pixels per metre and centre (metres
  /// east, north), which the plan view lands on.
  SpaceView view(
    Size size,
    double t, {
    required double planScale,
    required Offset planCentre,
  }) {
    double span(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
    double ease(double x) => Curves.easeInOutCubic.transform(x);
    final north = _north * math.pi / 180;
    final close = SpaceView(
      azimuth: north + math.pi - 40 * math.pi / 180,
      elevation: 18 * math.pi / 180,
      zoom: _zoomFor(size, .3 * size.height / 4.2),
      targetZ: 2.1,
    );
    final m = monument;
    final wide = SpaceView(
      azimuth: north + math.pi - 25 * math.pi / 180,
      elevation: 26 * math.pi / 180,
      zoom: _zoomFor(size, .6 * size.width / (m.maxX - m.minX + 4)),
      targetX: m.centerX,
      targetY: m.centerY,
      targetZ: m.centerZ * .8,
    );
    final (x, y) = model2(planCentre.dx, planCentre.dy);
    final plan = SpaceView(
      azimuth: north + math.pi,
      elevation: 89.5 * math.pi / 180,
      zoom: _zoomFor(size, planScale),
      targetX: x,
      targetY: y,
    );
    final tip = ease(span(4.6, 5.3));
    return tip > 0
        ? SpaceView.lerp(wide, plan, tip)
        : SpaceView.lerp(close, wide, ease(span(2.2, 4.6)));
  }

  /// Every part as it stands [t] seconds into the first run: the reveal
  /// (fragment, piers, arches, vault) compressed into 2.2–4.4 s, whole in a
  /// still.
  List<SpacePartState> parts(double t, {bool still = false}) {
    controller
      ..storyActive = true
      ..reveal = true
      ..reduced = still
      ..seconds = still
          ? study.reveal.seconds
          : study.reveal.seconds * ((t - 2.2) / 2.2).clamp(0.0, 1.0);
    return controller.partStates();
  }

  /// Marble hairlines on lamp black: the drawing style with marble and lamp
  /// swapped channel by channel (#EEE7DB ↔ #151314), so its paper ground
  /// becomes the first run's black exactly.
  static const _inverse = ColorFilter.matrix([
    -1, 0, 0, 0, 259, //
    0, -1, 0, 0, 250, //
    0, 0, -1, 0, 239, //
    0, 0, 0, 1, 0,
  ]);

  /// Draws the scene at [opacity] and returns its projector.
  SpaceProjector paint(
    Canvas canvas,
    Size size,
    SpaceView view,
    List<SpacePartState> parts,
    double opacity,
  ) {
    canvas.saveLayer(
      Offset.zero & size,
      Paint()
        ..colorFilter = _inverse
        ..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0)),
    );
    final p = renderer.paint(
      canvas,
      size,
      SpaceScene(view: view, style: SpaceStyle.drawing, parts: parts),
    );
    canvas.restore();
    return p;
  }

  void dispose() {
    renderer.dispose();
    controller.dispose();
  }
}

/// A road out of the city with the distance an itinerary gives for it, drawn
/// as a ray from mile zero toward its end (P13, Milestone 0).
class FirstRunRoad {
  const FirstRunRoad(this.name, this.miles, this.to);
  final Localized name;

  /// Roman miles as the source states them.
  final int miles;

  /// Where the road ends, for the ray's initial bearing from the Milion.
  final Coordinates to;
  double get bearing => measure(milion, to).bearing!;
}

/// The four roads (P13). Distances are the Bordeaux pilgrim's
/// (Itinerarium Burdigalense, AD 333; source `csel39-geyer-1898`): Jerusalem
/// 1,164 and Serdica 413 miles as its own totals from Constantinople,
/// Nicomedia 58 as codex P reads it (V has 50); the Hebdomon, the suburb
/// named for the seventh mile west (`byzleg-hebdomon`). Ends at today's
/// Sofia, İzmit, Jerusalem's Old City and Bakırköy's shore.
const firstRunRoads = [
  FirstRunRoad(
    Localized(en: 'Hebdomon', tr: 'Hebdomon'),
    7,
    Coordinates(40.978, 28.869),
  ),
  FirstRunRoad(
    Localized(en: 'Serdica', tr: 'Serdika'),
    413,
    Coordinates(42.6977, 23.3219),
  ),
  FirstRunRoad(
    Localized(en: 'Nicomedia', tr: 'Nikomedeia'),
    58,
    Coordinates(40.7654, 29.9408),
  ),
  FirstRunRoad(
    Localized(en: 'Jerusalem', tr: 'Kudüs'),
    1164,
    Coordinates(31.7767, 35.2345),
  ),
];
