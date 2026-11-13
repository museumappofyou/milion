import 'json_reader.dart';
import 'models.dart';

/// A place's guide (P11): its measured plan, where each artwork sits on it
/// and the walking orders of its cycles. Plan coordinates are metres in the
/// building's own frame: +x along the main axis towards the apse, +y to the
/// left of that axis (north for an east-facing church). [axisDeg] turns the
/// frame onto true north for the map and the compass.
class PlaceGuide {
  PlaceGuide({
    required this.id,
    required this.placeId,
    required this.axisDeg,
    required this.rooms,
    required this.vaults,
    required this.anchors,
    required this.cycles,
    required this.sourceIds,
  });
  final String id;
  final String placeId;
  final double axisDeg;
  final List<PlanRoom> rooms;
  final List<PlanVault> vaults;
  final Map<String, PlanAnchor> anchors;
  final List<GuideCycle> cycles;
  final List<String> sourceIds;

  PlanRoom? room(String id) {
    for (final r in rooms) {
      if (r.id == id) return r;
    }
    return null;
  }

  late final PlanBounds bounds = rooms
      .map((r) => r.bounds)
      .reduce((a, b) => a.include(b));

  factory PlaceGuide.fromJson(Json j) => decode(j, (r) {
    final anchors = <String, PlanAnchor>{};
    final raw = r.object('anchors');
    for (final e in raw.entries) {
      anchors[e.key] = PlanAnchor.fromJson(e.key, e.value as Json);
    }
    return PlaceGuide(
      id: r.string('id'),
      placeId: r.string('place'),
      axisDeg: r.number('axisDeg'),
      rooms: r.list('rooms', (v) => PlanRoom.fromJson(v as Json)),
      vaults: r.list('vaults', (v) => PlanVault.fromJson(v as Json)),
      anchors: anchors,
      cycles: r.list('cycles', (v) => GuideCycle.fromJson(v as Json)),
      sourceIds: r.strings('sources'),
    );
  });
}

/// A point on a plan, in metres (pure Dart: the validator runs without
/// Flutter).
class PlanPoint {
  const PlanPoint(this.x, this.y);
  final double x, y;
  @override
  bool operator ==(Object other) =>
      other is PlanPoint && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}

/// Axis-aligned extent of plan points, in metres.
class PlanBounds {
  const PlanBounds(this.left, this.bottom, this.right, this.top);
  final double left, bottom, right, top;
  double get width => right - left;
  double get height => top - bottom;
  PlanBounds include(PlanBounds o) => PlanBounds(
    o.left < left ? o.left : left,
    o.bottom < bottom ? o.bottom : bottom,
    o.right > right ? o.right : right,
    o.top > top ? o.top : top,
  );
}

PlanPoint _point(dynamic v) {
  if (v is! List || v.length != 2 || v.any((n) => n is! num)) {
    throw FormatException('a plan point is [x, y] in metres, not $v');
  }
  return PlanPoint((v[0] as num).toDouble(), (v[1] as num).toDouble());
}

/// A space on the plan, by its inner outline.
class PlanRoom {
  PlanRoom(this.id, this.name, this.outline, this.label);
  final String id;
  final Localized name;
  final List<PlanPoint> outline;
  final PlanPoint label;

  late final PlanBounds bounds = outline.fold(
    PlanBounds(
      outline.first.x,
      outline.first.y,
      outline.first.x,
      outline.first.y,
    ),
    (b, p) => b.include(PlanBounds(p.x, p.y, p.x, p.y)),
  );

  /// Even–odd point-in-polygon.
  bool contains(PlanPoint p) {
    var inside = false;
    for (var i = 0, j = outline.length - 1; i < outline.length; j = i++) {
      final a = outline[i], b = outline[j];
      if ((a.y > p.y) != (b.y > p.y) &&
          p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) {
        inside = !inside;
      }
    }
    return inside;
  }

  factory PlanRoom.fromJson(Json j) => decode(j, (r) {
    final outline = r.list('outline', _point);
    if (outline.length < 3) {
      throw const FormatException('a room outline needs three points');
    }
    return PlanRoom(
      r.string('id'),
      Localized.fromJson(r.object('name')),
      outline,
      _point(r.value('label')),
    );
  });
}

enum VaultKind { dome, vault, apse }

/// A dome, vault or apse drawn on the plan in dashed reflected-ceiling
/// manner; [ribs] are a dome's flutes or ribs, if it has them.
class PlanVault {
  PlanVault(this.room, this.kind, this.center, this.radius, this.ribs);
  final String room;
  final VaultKind kind;
  final PlanPoint center;
  final double radius;
  final int ribs;

  factory PlanVault.fromJson(Json j) => decode(
    j,
    (r) => PlanVault(
      r.string('room'),
      r.enumeration('kind', VaultKind.values),
      _point(r.value('center')),
      r.number('radius'),
      r.optionalInteger('ribs') ?? 0,
    ),
  );
}

/// Where an artwork is drawn on the plan.
class PlanAnchor {
  PlanAnchor(this.artworkId, this.room, this.at);
  final String artworkId;
  final String room;
  final PlanPoint at;
  factory PlanAnchor.fromJson(String id, Json j) =>
      decode(j, (r) => PlanAnchor(id, r.string('room'), _point(r.value('at'))));
}

/// A guided cycle: artworks in walking order.
class GuideCycle {
  GuideCycle(this.id, this.title, this.intro, this.artworkIds, this.sourceIds);
  final String id;
  final Localized title;
  final Localized intro;
  final List<String> artworkIds;
  final List<String> sourceIds;
  factory GuideCycle.fromJson(Json j) => decode(
    j,
    (r) => GuideCycle(
      r.string('id'),
      Localized.fromJson(r.object('title')),
      Localized.fromJson(r.object('intro')),
      r.strings('artworks'),
      r.strings('sources'),
    ),
  );
}
