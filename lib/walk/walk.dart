import 'dart:math' as math;

import '../content/json_reader.dart';
import '../content/models.dart';

/// A point in a walk's frame: metres, y up, x along the hall, z across it.
class WalkPoint {
  const WalkPoint(this.x, this.y, this.z);
  factory WalkPoint.fromJson(dynamic v) {
    if (v is! List || v.length != 3 || v.any((e) => e is! num)) {
      throw const FormatException('a point is [x, y, z]');
    }
    return WalkPoint(
      (v[0] as num).toDouble(),
      (v[1] as num).toDouble(),
      (v[2] as num).toDouble(),
    );
  }
  final double x, y, z;
  WalkPoint operator +(WalkPoint o) => WalkPoint(x + o.x, y + o.y, z + o.z);
  WalkPoint operator -(WalkPoint o) => WalkPoint(x - o.x, y - o.y, z - o.z);
  WalkPoint operator *(double k) => WalkPoint(x * k, y * k, z * k);
  double get length => math.sqrt(x * x + y * y + z * z);
  static WalkPoint lerp(WalkPoint a, WalkPoint b, double t) => a + (b - a) * t;
  @override
  String toString() => '($x, $y, $z)';
}

/// The hall the prototypes are instanced on (`grid` in walk.json).
class WalkGrid {
  WalkGrid(JsonReader r)
    : length = r.number('length'),
      width = r.number('width'),
      along = r.integer('along'),
      across = r.integer('across'),
      pitchX = (r.value('pitch') as List)[0].toDouble(),
      pitchZ = (r.value('pitch') as List)[1].toDouble(),
      columnHeight = r.number('columnHeight'),
      springing = r.number('springing'),
      vaultRise = r.number('vaultRise'),
      waterLevel = r.number('waterLevel'),
      deckHeight = r.number('deckHeight'),
      eyeHeight = r.number('eyeHeight');
  final double length, width, pitchX, pitchZ;
  final int along, across;
  final double columnHeight, springing, vaultRise;
  final double waterLevel, deckHeight, eyeHeight;
  int get columns => along * across;

  /// Where column [a], [b] (1-based from the x = 0 and z = 0 walls) stands.
  (double, double) column(int a, int b) => (a * pitchX, b * pitchZ);
  double get eye => deckHeight + eyeHeight;
}

/// A column that is not the grid's ordinary kind: a carved base under it
/// (the Medusa heads) or a patterned shaft (the weeping column).
class WalkSpecial {
  WalkSpecial(JsonReader r)
    : id = r.string('id'),
      along = (r.value('column') as List)[0] as int,
      across = (r.value('column') as List)[1] as int,
      prototype = r.string('prototype');
  final String id, prototype;
  final int along, across;
  bool get carvedBase => prototype.startsWith('medusa');
}

/// A place the story stops and the stills show: where the eye stands and
/// what it looks at.
class WalkStop {
  WalkStop(JsonReader r)
    : id = r.string('id'),
      eye = WalkPoint.fromJson(r.value('eye')),
      look = WalkPoint.fromJson(r.value('look')),
      seconds = r.number('seconds'),
      label = Localized.fromJson(r.object('label')),
      caption = Localized.fromJson(r.object('caption')),
      callouts = r.optionalStrings('callouts'),
      photo = r.optionalString('photo'),
      sourceIds = r.strings('sources');
  final String id;
  final WalkPoint eye, look;

  /// A media id: the photograph of what this stop looks at (ORIGINAL).
  final String? photo;

  /// How long the story holds here, the move to the next stop included.
  final double seconds;
  final Localized label, caption;

  /// Callouts the story shows at this stop.
  final List<String> callouts;
  final List<String> sourceIds;
}

/// A leader-line note on something in the hall.
class WalkCallout {
  WalkCallout(JsonReader r)
    : id = r.string('id'),
      anchor = WalkPoint.fromJson(r.value('anchor')),
      label = Localized.fromJson(r.object('label')),
      note = Localized.fromJson(r.object('note')),
      sourceIds = r.strings('sources');
  final String id;
  final WalkPoint anchor;
  final Localized label, note;
  final List<String> sourceIds;
}

/// A sound P22 will add; until then only named (P14: drips, echo).
class WalkAmbient {
  WalkAmbient(JsonReader r)
    : id = r.string('id'),
      status = r.string('status'),
      note = Localized.fromJson(r.object('note'));
  final String id, status;
  final Localized note;
}

/// An immersive walk manifest (`assets/walk/<id>/walk.json`, P14).
class WalkManifest {
  WalkManifest._(JsonReader r)
    : id = r.string('id'),
      placeId = r.string('placeId'),
      milestoneId = r.string('milestoneId'),
      honesty = Honesty.values.byName(r.string('honesty')),
      model = r.string('model'),
      modelSha256 = r.string('modelSha256'),
      textures = (r.object('textures')).cast<String, String>(),
      photos = (r.optionalObject('photos') ?? const {}).cast<String, String>(),
      grid = decode(r.object('grid'), WalkGrid.new),
      capitals = r.string('capitals'),
      turns = r.string('turns'),
      specials = r.list('specials', (v) => decode(v as Json, WalkSpecial.new)),
      route = r.list('route', (v) {
        final p = (v as List).cast<num>();
        return (p[0].toDouble(), p[1].toDouble());
      }),
      fogColour = _vec3(r.object('lighting')['fog']['colour']),
      fogDensity = (r.object('lighting')['fog']['density'] as num).toDouble(),
      fogFar = (r.object('lighting')['fog']['far'] as num).toDouble(),
      waterColour = _vec3(r.object('lighting')['water']['colour']),
      waterAlpha = (r.object('lighting')['water']['alpha'] as num).toDouble(),
      mirrorDim = _vec3(r.object('lighting')['water']['mirrorDim']),
      prototypes = r.object('prototypes').cast<String, int>(),
      estimated = r.strings('estimated'),
      title = Localized.fromJson(r.object('title')),
      description = Localized.fromJson(r.object('description')),
      talkback = Localized.fromJson(r.object('talkback')),
      stops = r.list('stops', (v) => decode(v as Json, WalkStop.new)),
      callouts = r.list('callouts', (v) => decode(v as Json, WalkCallout.new)),
      revealSeconds = (r.object('reveal')['seconds'] as num).toDouble(),
      revealCaption = Localized.fromJson(r.object('reveal')['caption'] as Json),
      revealStop = r.object('reveal')['stop'] as String,
      stills = r.strings('stills'),
      start = r.optionalString('start'),
      ambient = r.list('ambient', (v) => decode(v as Json, WalkAmbient.new)),
      fishCount = (r.object('fish')['count'] as num).toInt(),
      fishNote = Localized.fromJson(r.object('fish')['note'] as Json),
      sourceIds = r.strings('sources') {
    if (capitals.length != grid.columns || turns.length != grid.columns) {
      throw FormatException('$id: one capital and one turn per column');
    }
    if (route.length < 2) throw FormatException('$id: a route needs 2 points');
    for (final s in stills) {
      stop(s);
    }
    stop(revealStop);
    if (start case final s?) stop(s);
    for (final s in stops) {
      for (final c in s.callouts) {
        callout(c);
      }
    }
  }

  factory WalkManifest.fromJson(Json json) {
    if (json['schemaVersion'] != 1 || json['kind'] != 'walk') {
      throw const FormatException('not a walk manifest');
    }
    return decode(json, (r) {
      r.integer('schemaVersion');
      r.string('kind');
      return WalkManifest._(r);
    });
  }

  static List<double> _vec3(dynamic v) {
    if (v is! List || v.length != 3) {
      throw const FormatException('a colour is [r, g, b]');
    }
    return [for (final e in v) (e as num).toDouble()];
  }

  final String id, placeId, milestoneId, model, modelSha256;
  final Honesty honesty;
  final Map<String, String> textures, photos;
  final WalkGrid grid;

  /// One letter per column (C Corinthian, I Ionic, D Doric) and one quarter
  /// turn per column, column-major from the x = 0 wall.
  final String capitals, turns;
  final List<WalkSpecial> specials;

  /// The visitors' deck, (x, z) in metres.
  final List<(double, double)> route;
  final List<double> fogColour, waterColour, mirrorDim;
  final double fogDensity, fogFar, waterAlpha;

  /// Triangles per prototype, for the budget.
  final Map<String, int> prototypes;

  /// Grid values set in proportion, not cited.
  final List<String> estimated;
  final Localized title, description, talkback;
  final List<WalkStop> stops;
  final List<WalkCallout> callouts;
  final double revealSeconds;
  final Localized revealCaption;
  final String revealStop;
  final List<String> stills;

  /// The stop the walk opens at (default the first).
  final String? start;
  final List<WalkAmbient> ambient;
  final int fishCount;
  final Localized fishNote;
  final List<String> sourceIds;

  WalkStop stop(String id) => stops.firstWhere(
    (s) => s.id == id,
    orElse: () => throw FormatException('${this.id}: unknown stop $id'),
  );
  WalkCallout callout(String id) => callouts.firstWhere(
    (c) => c.id == id,
    orElse: () => throw FormatException('${this.id}: unknown callout $id'),
  );
  double get storySeconds => stops.fold(0.0, (t, s) => t + s.seconds);

  /// Every source the walk cites.
  Set<String> get allSourceIds => {
    ...sourceIds,
    for (final s in stops) ...s.sourceIds,
    for (final c in callouts) ...c.sourceIds,
  };

  /// The special column at [a], [b], if any.
  WalkSpecial? specialAt(int a, int b) {
    for (final s in specials) {
      if (s.along == a && s.across == b) return s;
    }
    return null;
  }

  /// The route's length in metres.
  double get routeLength {
    var total = 0.0;
    for (var i = 1; i < route.length; i++) {
      final (x0, z0) = route[i - 1];
      final (x1, z1) = route[i];
      total += math.sqrt((x1 - x0) * (x1 - x0) + (z1 - z0) * (z1 - z0));
    }
    return total;
  }

  /// The deck point [s] metres along the route, and the route's heading
  /// there (radians, from +x toward +z).
  (double, double, double) along(double s) {
    var left = s.clamp(0.0, routeLength);
    for (var i = 1; i < route.length; i++) {
      final (x0, z0) = route[i - 1];
      final (x1, z1) = route[i];
      final l = math.sqrt((x1 - x0) * (x1 - x0) + (z1 - z0) * (z1 - z0));
      if (left <= l || i == route.length - 1) {
        final t = l == 0 ? 0.0 : (left / l).clamp(0.0, 1.0);
        return (
          x0 + (x1 - x0) * t,
          z0 + (z1 - z0) * t,
          math.atan2(z1 - z0, x1 - x0),
        );
      }
      left -= l;
    }
    final (x, z) = route.last;
    return (x, z, 0);
  }

  /// The route position nearest to (x, z).
  double nearest(double x, double z) {
    var best = double.infinity, at = 0.0, start = 0.0;
    for (var i = 1; i < route.length; i++) {
      final (x0, z0) = route[i - 1];
      final (x1, z1) = route[i];
      final dx = x1 - x0, dz = z1 - z0;
      final l2 = dx * dx + dz * dz;
      final t = l2 == 0
          ? 0.0
          : (((x - x0) * dx + (z - z0) * dz) / l2).clamp(0.0, 1.0);
      final px = x0 + dx * t, pz = z0 + dz * t;
      final d = (px - x) * (px - x) + (pz - z) * (pz - z);
      if (d < best) {
        best = d;
        at = start + math.sqrt(l2) * t;
      }
      start += math.sqrt(l2);
    }
    return at;
  }
}
