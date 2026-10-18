import '../content/json_reader.dart';
import '../content/models.dart';
import 'model.dart';

/// A stop on the time scrubber: the same parts read at a given year.
class SpaceEpoch {
  SpaceEpoch(JsonReader r)
    : year = r.integer('year'),
      label = Localized.fromJson(r.object('label'));
  final int year;
  final Localized label;
}

/// One labelled step of the assembly timeline.
class SpaceStep {
  SpaceStep(JsonReader r)
    : id = r.string('id'),
      parts = r.strings('parts'),
      label = Localized.fromJson(r.object('label')),
      caption = Localized.fromJson(r.object('caption')),
      seconds = r.number('seconds'),
      epochs = r.list('epochs', (v) {
        if (v is! int) throw const FormatException('epochs must be years');
        return v;
      }),
      sourceIds = r.strings('sources');
  final String id;
  final List<String> parts;
  final Localized label, caption;
  final double seconds;

  /// Years this step belongs to; empty means every epoch.
  final List<int> epochs;
  final List<String> sourceIds;
  bool inEpoch(int year) => epochs.isEmpty || epochs.contains(year);
}

/// The 10-second hook: the steps up to [through], at [seconds].
class SpaceReveal {
  SpaceReveal(JsonReader r)
    : through = r.string('through'),
      seconds = r.number('seconds'),
      turnDegrees = r.number('turnDegrees'),
      caption = Localized.fromJson(r.object('caption'));
  final String through;
  final double seconds, turnDegrees;
  final Localized caption;
}

/// Choisy's view: worm's-eye axonometric with a horizontal plan cut
/// [sectionHeight] above the model's lowest point. A walled building is cut
/// just under its vaults and seen more steeply, so its near walls do not hide
/// them: [elevation] and [azimuth] (degrees, the camera's compass direction
/// in the model's frame, anticlockwise from +x) default to P08's isometric
/// angle from the south-west.
class SpaceChoisy {
  SpaceChoisy(JsonReader r)
    : sectionHeight = r.number('sectionHeight'),
      elevationDegrees = r.optionalNumber('elevation') ?? -35.26,
      azimuthDegrees = r.optionalNumber('azimuth') ?? 225;
  final double sectionHeight, elevationDegrees, azimuthDegrees;
}

/// Where the drawing sits on the earth: [axis] is the azimuth (degrees from
/// true north, clockwise) of the model's +y, the building's main axis, from
/// a cited outline ([sourceId]). Kit models are drawn in the building's own
/// frame, so sections cut along its axes; P10 and P20 turn them onto a map.
class SpaceOrientation {
  SpaceOrientation(JsonReader r)
    : axis = r.number('axis'),
      sourceId = r.string('source');
  final double axis;
  final String sourceId;
}

/// A SpacePlayer manifest (`assets/space/<id>/study.json`).
class SpaceStudy {
  SpaceStudy._(JsonReader r)
    : schemaVersion = r.integer('schemaVersion'),
      kind = r.string('kind'),
      id = r.string('id'),
      title = Localized.fromJson(r.object('title')),
      description = Localized.fromJson(r.object('description')),
      model = r.string('model'),
      triangles = r.integer('triangles'),
      honesty = r.enumeration('honesty', Honesty.values),
      epochs = r.list('epochs', (j) => decode(j as Json, SpaceEpoch.new)),
      steps = r.list('steps', (j) => decode(j as Json, SpaceStep.new)),
      reveal = decode(r.object('reveal'), SpaceReveal.new),
      choisy = decode(r.object('choisy'), SpaceChoisy.new),
      sourceIds = r.strings('sources'),
      citations = r.list('citations', (j) => Source.fromJson(j as Json)),
      placeId = r.optionalString('place'),
      orientation = switch (r.optionalObject('orientation')) {
        final Json o => decode(o, SpaceOrientation.new),
        null => null,
      };

  factory SpaceStudy.fromJson(Json j) {
    final study = decode(j, SpaceStudy._);
    study._validate();
    return study;
  }
  static const version = 1;

  /// §3 budget for drawing-style 3D: about 20k triangles per study, the
  /// most the Canvas renderer draws at ≥ 50 fps on the A52s (P08's
  /// 20,144-triangle study measured 54–57 fps).
  static const triangleBudget = 20500;
  final int schemaVersion, triangles;
  final String kind, id, model;
  final Localized title, description;
  final Honesty honesty;
  final List<SpaceEpoch> epochs;
  final List<SpaceStep> steps;
  final SpaceReveal reveal;
  final SpaceChoisy choisy;
  final List<String> sourceIds;
  final List<Source> citations;

  /// The registry place a kit study draws (P09 on); P08's study has none.
  final String? placeId;
  final SpaceOrientation? orientation;
  double get storySeconds => steps.fold(0, (t, s) => t + s.seconds);
  List<SpaceStep> stepsIn(int year) =>
      steps.where((s) => s.inEpoch(year)).toList();

  void _validate() {
    void check(bool ok, String message) {
      if (!ok) throw FormatException('$id: $message');
    }

    void bilingual(Localized text) =>
        check(text.tr?.trim().isNotEmpty ?? false, 'Turkish text required');
    check(schemaVersion == version && kind == 'space', 'not a space study');
    check(model == 'assets/space/$id/model.glb', 'model path');
    check(triangles > 0 && triangles <= triangleBudget, 'triangle budget');
    check(honesty != Honesty.ORIGINAL, 'a 3D study is never ORIGINAL');
    for (final text in [title, description, reveal.caption]) {
      bilingual(text);
    }
    check(epochs.isNotEmpty, 'at least one epoch');
    for (var i = 1; i < epochs.length; i++) {
      check(epochs[i].year > epochs[i - 1].year, 'epochs in order');
    }
    for (final e in epochs) {
      bilingual(e.label);
    }
    final years = epochs.map((e) => e.year).toSet();
    final ids = <String>{};
    for (final s in steps) {
      check(ids.add(s.id), 'duplicate step ${s.id}');
      check(s.parts.isNotEmpty && s.seconds > 0, '${s.id}: parts and seconds');
      check(years.containsAll(s.epochs), '${s.id}: unknown epoch');
      check(s.sourceIds.isNotEmpty, '${s.id}: sources required');
      bilingual(s.label);
      bilingual(s.caption);
    }
    for (final e in epochs) {
      check(stepsIn(e.year).isNotEmpty, '${e.year}: no steps');
      final parts = stepsIn(e.year).expand((s) => s.parts).toList();
      check(parts.length == parts.toSet().length, '${e.year}: a part twice');
    }
    final revealIndex = steps.indexWhere((s) => s.id == reveal.through);
    check(revealIndex >= 0, 'reveal.through');
    check(
      steps.take(revealIndex + 1).every((s) => s.inEpoch(epochs.first.year)),
      'the reveal plays in the first epoch',
    );
    check(reveal.seconds > 0 && reveal.seconds <= 10, 'reveal ≤ 10 s');
    check(
      choisy.elevationDegrees >= -70 && choisy.elevationDegrees < 0,
      "Choisy's view looks up",
    );
    check(storySeconds >= 20 && storySeconds <= 40, 'story 20–40 s');
    final cited = citations.map((c) => c.id).toSet();
    check(cited.length == citations.length, 'duplicate citation');
    check(
      cited.containsAll({
        ...sourceIds,
        ...steps.expand((s) => s.sourceIds),
        ?orientation?.sourceId,
      }),
      'citations required for every claim',
    );
    final o = orientation;
    check(o == null || (o.axis >= 0 && o.axis < 360), 'axis in degrees');
  }

  /// Every part named by a step exists in the model, and the model is within
  /// the declared triangle count.
  void checkModel(SpaceModel m) {
    if (m.parts.length > 256) throw FormatException('$id: over 256 parts');
    for (final s in steps) {
      for (final p in s.parts) {
        if (m.part(p) == null) throw FormatException('$id: no part $p');
      }
    }
    if (m.triangleCount != triangles) {
      throw FormatException(
        '$id: model has ${m.triangleCount} triangles, manifest $triangles',
      );
    }
  }
}
