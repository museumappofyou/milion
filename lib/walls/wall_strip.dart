import 'dart:convert';
import 'dart:math' as math;

import '../content/json_reader.dart';
import '../content/models.dart';
import '../content/registry.dart';
import '../content/repository.dart';

/// One band of the wall's cross-section, measured from the outside in
/// (metres from the field edge of the moat), with its height above (or
/// depth below) the field. P15, Milestone XVIII.
class WallLayer {
  WallLayer(JsonReader r)
    : id = r.string('id'),
      kind = WallLayerKind.values.byName(r.string('kind')),
      from = r.number('from'),
      to = r.number('to'),
      height = r.number('height'),
      estimated = r.optionalBoolean('estimated'),
      label = Localized.fromJson(r.object('label')),
      note = Localized.fromJson(r.object('note')),
      sourceIds = r.strings('sources');
  final String id;
  final WallLayerKind kind;

  /// Across the defences, metres from the field edge.
  final double from, to;

  /// Metres above the field (negative: below it, the moat).
  final double height;

  /// Set in proportion; no source read here gives the figure.
  final bool estimated;
  final Localized label, note;
  final List<String> sourceIds;
  double get width => to - from;
}

enum WallLayerKind {
  moat,
  breastwork,
  terrace,
  outerWall,
  peribolos,
  innerWall,
}

/// A stretch of the line with one kind of defence.
class WallSegment {
  WallSegment(JsonReader r)
    : id = r.string('id'),
      from = r.number('from'),
      to = r.number('to'),
      kind = WallSegmentKind.values.byName(r.string('kind')),
      label = Localized.fromJson(r.object('label')),
      note = Localized.fromJson(r.object('note')),
      sourceIds = r.strings('sources');
  final String id;

  /// Chainage, metres from the Marmara end.
  final double from, to;
  final WallSegmentKind kind;
  final Localized label, note;
  final List<String> sourceIds;
  bool contains(double at) => at >= from && at <= to;
}

/// `triple`: moat, outer wall and inner wall (the Theodosian line);
/// `double`: both walls, the moat run out (north of Edirnekapı);
/// `single`: one wall without a moat (Blachernae).
enum WallSegmentKind {
  triple,
  double,
  single;

  bool get hasMoat => this == triple;
  bool get hasOuterWall => this != single;

  /// Whether the cross-section here has [layer].
  bool shows(WallLayerKind layer) => switch (layer) {
    WallLayerKind.moat || WallLayerKind.breastwork => hasMoat,
    WallLayerKind.terrace ||
    WallLayerKind.outerWall ||
    WallLayerKind.peribolos => hasOuterWall,
    WallLayerKind.innerWall => true,
  };
}

/// A tower of the inner or outer wall at its chainage.
class WallTower {
  WallTower(JsonReader r)
    : at = r.number('at'),
      wall = r.string('wall'),
      number = r.optionalInteger('number'),
      surveyed = r.boolean('surveyed');
  final double at;

  /// 'inner' or 'outer'.
  final String wall;

  /// The inventory's number for an inner tower.
  final int? number;

  /// Placed from a surveyed position; otherwise set between two that are.
  final bool surveyed;
}

/// A gate (or the Kerkoporta) as a stop on the strip.
class WallGate {
  WallGate(JsonReader r)
    : id = r.string('id'),
      at = r.number('at'),
      lat = r.number('lat'),
      lng = r.number('lng'),
      kind = r.string('kind'),
      names = Localized.fromJson(r.object('names')),
      greek = r.optionalString('greek'),
      year = r.optionalString('year'),
      legend = r.optionalBoolean('legend'),
      positionNote = switch (r.optionalObject('positionNote')) {
        null => null,
        final o => Localized.fromJson(o),
      },
      placeId = r.optionalString('placeId'),
      caption = Localized.fromJson(r.object('caption')),
      photo = r.optionalString('photo'),
      sourceIds = r.strings('sources');
  final String id;
  final double at, lat, lng;

  /// 'public', 'military', 'palace' or 'postern'.
  final String kind;
  final Localized names;
  final String? greek, year;

  /// A legend's stop (the Kerkoporta): its marker is a mapped convention,
  /// not a surveyed gate (O21).
  final bool legend;
  final Localized? positionNote;
  final String? placeId;
  final Localized caption;
  final String? photo;
  final List<String> sourceIds;
}

/// A story beat: the strip glides to [at] and holds.
class WallBeat {
  WallBeat(JsonReader r)
    : id = r.string('id'),
      at = r.number('at'),
      seconds = r.number('seconds'),
      label = Localized.fromJson(r.object('label')),
      caption = Localized.fromJson(r.object('caption')),
      sourceIds = r.strings('sources');
  final String id;
  final double at, seconds;
  final Localized label, caption;
  final List<String> sourceIds;
}

/// A point of the wall's line: where it is, and how far along.
typedef WallPoint = ({double lat, double lng, double at});

/// The land walls as one continuous strip (`assets/walls/<id>/strip.json`,
/// P15): the line from the Sea of Marmara to the Golden Horn with its
/// chainage, the cross-section's layers, the towers, the gates and the
/// story.
class WallStripManifest {
  WallStripManifest._(JsonReader r)
    : id = r.string('id'),
      placeId = r.string('placeId'),
      milestoneId = r.string('milestoneId'),
      honesty = Honesty.values.byName(r.string('honesty')),
      title = Localized.fromJson(r.object('title')),
      description = Localized.fromJson(r.object('description')),
      talkback = Localized.fromJson(r.object('talkback')),
      sourceIds = r.strings('sources'),
      length = r.number('length'),
      heightScale = r.number('heightScale'),
      line = r.list('line', (v) {
        final p = (v as List).cast<num>();
        return (
          lat: p[0].toDouble(),
          lng: p[1].toDouble(),
          at: p[2].toDouble(),
        );
      }),
      lineSourceIds = r.strings('lineSources'),
      layers = r.list('layers', (v) => decode(v as Json, WallLayer.new)),
      innerTowerHeight = r.number('innerTowerHeight'),
      outerTowerHeight = r.number('outerTowerHeight'),
      segments = r.list('segments', (v) => decode(v as Json, WallSegment.new)),
      towers = r.list('towers', (v) => decode(v as Json, WallTower.new)),
      gates = r.list('gates', (v) => decode(v as Json, WallGate.new)),
      revealSeconds = (r.object('reveal')['seconds'] as num).toDouble(),
      revealCaption = Localized.fromJson(r.object('reveal')['caption'] as Json),
      beats = r.list('beats', (v) => decode(v as Json, WallBeat.new)),
      stills = r.strings('stills') {
    for (final s in stills) {
      beat(s);
    }
    for (var i = 1; i < line.length; i++) {
      if (line[i].at < line[i - 1].at) {
        throw FormatException('$id: the line\'s chainage goes backwards');
      }
    }
  }

  factory WallStripManifest.fromJson(Json json) {
    if (json['schemaVersion'] != 1 || json['kind'] != 'strip') {
      throw const FormatException('not a wall strip manifest');
    }
    return decode(json, (r) {
      r.integer('schemaVersion');
      r.string('kind');
      return WallStripManifest._(r);
    });
  }

  final String id, placeId, milestoneId;
  final Honesty honesty;
  final Localized title, description, talkback;
  final List<String> sourceIds, lineSourceIds;

  /// Metres along the line, Marmara to the Golden Horn.
  final double length;

  /// The drawing's vertical exaggeration (heights × this), stated on screen.
  final double heightScale;
  final List<WallPoint> line;
  final List<WallLayer> layers;
  final double innerTowerHeight, outerTowerHeight;
  final List<WallSegment> segments;
  final List<WallTower> towers;
  final List<WallGate> gates;
  final double revealSeconds;
  final Localized revealCaption;
  final List<WallBeat> beats;
  final List<String> stills;

  double get storySeconds => beats.fold(0.0, (t, b) => t + b.seconds);
  WallBeat beat(String id) => beats.firstWhere(
    (b) => b.id == id,
    orElse: () => throw FormatException('${this.id}: unknown beat $id'),
  );
  WallGate gate(String id) => gates.firstWhere(
    (g) => g.id == id,
    orElse: () => throw FormatException('${this.id}: unknown gate $id'),
  );
  WallSegment segmentAt(double at) => segments.firstWhere(
    (s) => s.contains(at),
    orElse: () => at <= 0 ? segments.first : segments.last,
  );

  /// The nearest gate to [at] within [within] metres, if any.
  WallGate? gateNear(double at, {double within = 60}) {
    WallGate? best;
    for (final g in gates) {
      final d = (g.at - at).abs();
      if (d <= within && (best == null || d < (best.at - at).abs())) best = g;
    }
    return best;
  }

  /// Where on the line chainage [at] lies.
  Coordinates pointAt(double at) {
    final a = at.clamp(0.0, length);
    for (var i = 1; i < line.length; i++) {
      final p = line[i - 1], q = line[i];
      if (a <= q.at) {
        final t = q.at == p.at ? 0.0 : (a - p.at) / (q.at - p.at);
        return Coordinates(
          p.lat + (q.lat - p.lat) * t,
          p.lng + (q.lng - p.lng) * t,
        );
      }
    }
    return Coordinates(line.last.lat, line.last.lng);
  }

  /// The chainage nearest [where] and how far from the line it is (m):
  /// on site, the strip scrolls to where you stand.
  ({double at, double off}) locate(Coordinates where) {
    final k = math.cos(where.lat * math.pi / 180);
    double x(double lng) => (lng - where.lng) * k * 111320;
    double y(double lat) => (lat - where.lat) * 110574;
    var best = (at: 0.0, off: double.infinity);
    for (var i = 1; i < line.length; i++) {
      final p = line[i - 1], q = line[i];
      final ax = x(p.lng), ay = y(p.lat), bx = x(q.lng), by = y(q.lat);
      final dx = bx - ax, dy = by - ay;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0 ? 0.0 : ((-ax * dx - ay * dy) / len2).clamp(0.0, 1.0);
      final cx = ax + dx * t, cy = ay + dy * t;
      final off = math.sqrt(cx * cx + cy * cy);
      if (off < best.off) best = (at: p.at + (q.at - p.at) * t, off: off);
    }
    return best;
  }

  Set<String> get allSourceIds => {
    ...sourceIds,
    ...lineSourceIds,
    for (final l in layers) ...l.sourceIds,
    for (final s in segments) ...s.sourceIds,
    for (final g in gates) ...g.sourceIds,
    for (final b in beats) ...b.sourceIds,
  };
}

/// Strips parsed once at start from `assets/walls/index.json`.
class WallStripCatalog {
  const WallStripCatalog.empty() : _strips = const {}, errors = const [];
  WallStripCatalog._(Map<String, WallStripManifest> s, this.errors)
    : _strips = Map.unmodifiable(s);
  final Map<String, WallStripManifest> _strips;
  final List<String> errors;
  Iterable<WallStripManifest> get strips => _strips.values;
  WallStripManifest? strip(String id) => _strips[id];
  static String manifestPath(String id) => 'assets/walls/$id/strip.json';
  static const indexPath = 'assets/walls/index.json';

  WallStripManifest? forMilestone(Milestone m) {
    final path = m.manifestPath;
    if (m.status == MilestoneStatus.planned || path == null) return null;
    for (final s in strips) {
      if (manifestPath(s.id) == path) return s;
    }
    return null;
  }

  static Future<WallStripCatalog> load(
    ContentRegistry registry,
    LoadText loadText, {
    bool strict = true,
  }) async {
    final out = <String, WallStripManifest>{};
    final errors = <String>[];
    List<String> ids;
    try {
      ids = decode(
        jsonDecode(await loadText(indexPath)) as Map<String, dynamic>,
        (r) {
          if (r.integer('schemaVersion') != 1 || r.string('kind') != 'strips') {
            throw const FormatException('not a strip index');
          }
          return r.strings('strips');
        },
      );
    } on Object catch (e) {
      if (strict) rethrow;
      return WallStripCatalog._(const {}, ['index: $e']);
    }
    for (final id in ids) {
      try {
        final s = WallStripManifest.fromJson(
          jsonDecode(await loadText(manifestPath(id))) as Map<String, dynamic>,
        );
        if (s.id != id) throw FormatException('$id: manifest id mismatch');
        if (registry.place(s.placeId) == null) {
          throw FormatException('$id: unknown place ${s.placeId}');
        }
        if (registry.milestone(s.milestoneId) == null) {
          throw FormatException('$id: unknown milestone ${s.milestoneId}');
        }
        for (final source in s.allSourceIds) {
          if (registry.source(source) == null) {
            throw FormatException('$id: unknown source $source');
          }
        }
        for (final g in s.gates) {
          if (g.placeId case final p? when registry.place(p) == null) {
            throw FormatException('$id: ${g.id} names unknown place $p');
          }
          if (g.photo case final m? when registry.mediaItem(m) == null) {
            throw FormatException('$id: ${g.id} names unknown media $m');
          }
        }
        out[id] = s;
      } on Object catch (e) {
        if (strict) rethrow;
        errors.add('$id: $e');
      }
    }
    return WallStripCatalog._(out, errors);
  }
}
