import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../content/geography.dart';
import '../content/json_reader.dart';
import '../content/models.dart';

/// Metres east and north of the Milion, equirectangular about mile zero:
/// the projection tool/atlas/build_atlas.py and lib/first_run use.
const earthRadiusM = 6371008.8;
Offset projectMetres(double lat, double lng) => Offset(
  (lng - milion.lng) *
      math.pi /
      180 *
      math.cos(milion.lat * math.pi / 180) *
      earthRadiusM,
  (lat - milion.lat) * math.pi / 180 * earthRadiusM,
);

Coordinates unprojectMetres(Offset m) => Coordinates(
  milion.lat + m.dy / earthRadiusM * 180 / math.pi,
  milion.lng +
      m.dx /
          (earthRadiusM * math.cos(milion.lat * math.pi / 180)) *
          180 /
          math.pi,
);

/// The time slider's stops (P10).
const atlasYears = [330, 537, 1200, 1453, 1560, 1900, 2026];

enum HistoricLayer { walls, coast, streets, hills, siege1453, below }

enum HistoricKind {
  landWall('land-wall'),
  seaWall('sea-wall'),
  gate('gate'),
  waterThen('water-then'),
  shoreThen('shore-then'),
  street('street'),
  forum('forum'),
  hill('hill'),
  siege('siege'),
  cistern('cistern'),
  substructure('substructure'),
  excavation('excavation'),
  tunnel('tunnel');

  const HistoricKind(this.key);
  final String key;
  static HistoricKind byKey(String key) => values.firstWhere(
    (k) => k.key == key,
    orElse: () => throw FormatException('unknown historic kind $key'),
  );
}

enum Certainty { surviving, traced, approximate, conjectural }

enum HistoricGeometry { point, line, polygon }

/// One hand-authored, sourced feature of studio/atlas/historic/.
class HistoricFeature {
  HistoricFeature({
    required this.id,
    required this.layer,
    required this.kind,
    required this.names,
    required this.from,
    required this.to,
    required this.certainty,
    required this.sourceIds,
    required this.note,
    required this.geometry,
    required this.parts,
  });
  final String id;
  final HistoricLayer layer;
  final HistoricKind kind;
  final Localized names;
  final int from;

  /// Last year it stood (or was water); null if it still does.
  final int? to;
  final Certainty certainty;
  final List<String> sourceIds;
  final Localized note;
  final HistoricGeometry geometry;

  /// In metres: one entry per line or ring (x, y pairs); one point for points.
  final List<Float32List> parts;

  late final Rect bounds = () {
    var r = Rect.zero;
    var first = true;
    for (final p in parts) {
      for (var i = 0; i < p.length; i += 2) {
        final o = Rect.fromLTWH(p[i], p[i + 1], 0, 0);
        r = first ? o : r.expandToInclude(o);
        first = false;
      }
    }
    return r;
  }();

  bool standsIn(double year) => year >= from && (to == null || year <= to!);

  /// 0..1: how present the feature is at [year]: whole between its dates,
  /// rising over the [fadeIn] years before it and gone [fadeOut] years after
  /// it, so the animating slider shows things arrive and go while every stop
  /// shows exactly what stood then.
  double presence(double year, {double fadeIn = 40, double fadeOut = 20}) {
    final a = ((year - from) / fadeIn + 1).clamp(0.0, 1.0);
    final b = to == null ? 1.0 : ((to! - year) / fadeOut + 1).clamp(0.0, 1.0);
    return math.min(a, b);
  }

  static HistoricFeature fromJson(Json j) => decode(j, (r) {
    final type = r.string('type');
    final coords = r.value('coordinates');
    Float32List line(List<dynamic> pts) {
      final out = Float32List(pts.length * 2);
      for (var i = 0; i < pts.length; i++) {
        final p = pts[i] as List<dynamic>;
        final m = projectMetres(
          (p[1] as num).toDouble(),
          (p[0] as num).toDouble(),
        );
        out[i * 2] = m.dx;
        out[i * 2 + 1] = m.dy;
      }
      return out;
    }

    final (HistoricGeometry g, List<Float32List> parts) = switch (type) {
      'Point' => (
        HistoricGeometry.point,
        [
          line([coords]),
        ],
      ),
      'MultiPoint' => (
        HistoricGeometry.point,
        [
          for (final p in coords as List) line([p]),
        ],
      ),
      'LineString' => (HistoricGeometry.line, [line(coords as List)]),
      'MultiLineString' => (
        HistoricGeometry.line,
        [for (final l in coords as List) line(l as List)],
      ),
      'Polygon' => (
        HistoricGeometry.polygon,
        [for (final l in coords as List) line(l as List)],
      ),
      'MultiPolygon' => (
        HistoricGeometry.polygon,
        [
          for (final poly in coords as List)
            for (final l in poly as List) line(l as List),
        ],
      ),
      _ => throw FormatException('unsupported geometry $type'),
    };
    return HistoricFeature(
      id: r.string('id'),
      layer: HistoricLayer.values.byName(r.string('layer')),
      kind: HistoricKind.byKey(r.string('kind')),
      names: Localized.fromJson(r.object('names')),
      from: r.integer('from'),
      to: r.value('to') == null ? null : r.integer('to'),
      certainty: Certainty.values.byName(r.string('certainty')),
      sourceIds: r.strings('sources'),
      note: Localized.fromJson(r.object('note')),
      geometry: g,
      parts: parts,
    );
  });
}

class HistoricAtlas {
  HistoricAtlas(this.features);
  final List<HistoricFeature> features;
  static const assetPath = 'assets/atlas/historic.json';

  factory HistoricAtlas.fromJsonText(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    return decode(j, (r) {
      if (r.integer('schemaVersion') != 1 ||
          r.string('kind') != 'atlas-historic') {
        throw const FormatException('historic.json: not an atlas layer file');
      }
      return HistoricAtlas(
        r.list('features', (f) => HistoricFeature.fromJson(f as Json)),
      );
    });
  }

  Iterable<HistoricFeature> inLayer(HistoricLayer l) =>
      features.where((f) => f.layer == l);
}
