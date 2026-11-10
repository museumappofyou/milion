import 'dart:typed_data';
import 'dart:ui';

import 'atlas_data.dart';
import 'historic.dart';

/// A historic feature's world-space drawing, built once.
class HistoricShape {
  HistoricShape(this.feature);
  final HistoricFeature feature;

  late final Rect bounds = feature.bounds;

  late final Path path = () {
    final p = Path()..fillType = PathFillType.evenOdd;
    for (final part in feature.parts) {
      if (part.length < 4) continue;
      p.moveTo(part[0], part[1]);
      for (var i = 2; i < part.length; i += 2) {
        p.lineTo(part[i], part[i + 1]);
      }
      if (feature.geometry == HistoricGeometry.polygon) p.close();
    }
    return p;
  }();

  /// Where a label or point symbol goes: the point, or the middle vertex
  /// of the longest part.
  late final Offset anchor = () {
    final part = feature.parts.reduce((a, b) => a.length >= b.length ? a : b);
    final i = (part.length ~/ 4) * 2;
    if (feature.geometry == HistoricGeometry.polygon) {
      var x = 0.0, y = 0.0;
      for (var k = 0; k < part.length; k += 2) {
        x += part[k];
        y += part[k + 1];
      }
      return Offset(x / (part.length / 2), y / (part.length / 2));
    }
    return Offset(part[i], part[i + 1]);
  }();

  /// Points every ~55 m along the line: the towers of the walls.
  late final Float32List? towers = () {
    if (feature.geometry != HistoricGeometry.line) return null;
    final out = <double>[];
    for (final metric in path.computeMetrics()) {
      for (var d = 20.0; d < metric.length; d += 55) {
        final t = metric.getTangentForOffset(d);
        if (t != null) out.addAll([t.position.dx, t.position.dy]);
      }
    }
    return Float32List.fromList(out);
  }();

  final _dashes = <int, Path>{};
  Path dashed(int level, double dash, double gap) =>
      _dashes.putIfAbsent(level, () {
        final out = Path();
        for (final metric in path.computeMetrics()) {
          for (var d = 0.0; d < metric.length; d += dash + gap) {
            out.addPath(metric.extractPath(d, d + dash), Offset.zero);
          }
        }
        return out;
      });

  final _labels = <String, String>{};
  String label(String language) =>
      _labels.putIfAbsent(language, () => feature.names.inLanguage(language));
}

/// Shapes for every historic feature, grouped by kind, and today's tunnels.
class HistoricGeometryCache {
  HistoricGeometryCache(HistoricAtlas atlas, {AtlasData? data}) {
    for (final f in atlas.features) {
      (_byKind[f.kind] ??= []).add(HistoricShape(f));
    }
    for (final f in data?.layer(AtlasLayer.rail)?.features ?? const []) {
      if (f.cls & 8 == 0) continue; // above ground
      final path = f.cls & 7 == 4 ? tunel : network;
      for (final line in f.rings) {
        if (line.length < 4) continue;
        path.moveTo(line[0], line[1]);
        for (var i = 2; i < line.length; i += 2) {
          path.lineTo(line[i], line[i + 1]);
        }
      }
    }
  }
  final _byKind = <HistoricKind, List<HistoricShape>>{};
  List<HistoricShape> byKind(HistoricKind k) => _byKind[k] ?? const [];

  /// Underground rail from OSM for the Below layer: the 1875 Tünel
  /// funicular, and the metro and Marmaray tunnels (from 2000 on the map).
  final tunel = Path(), network = Path();
  static const tunelYear = 1875, networkYear = 2000;
}
