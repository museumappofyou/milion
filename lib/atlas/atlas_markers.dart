import 'dart:math' as math;
import 'dart:ui';

import '../content/models.dart';
import 'atlas_view.dart';
import 'historic.dart';

/// One marker on the map: a place, or several close places as a cluster.
class AtlasMarker {
  AtlasMarker(this.world, this.places);

  /// In metres.
  final Offset world;
  final List<Place> places;
  bool get isCluster => places.length > 1;
}

/// Places grouped on a grid fixed in metres, its cell the power of two
/// nearest [cellPx] screen pixels at this zoom: clusters stay put while the
/// map pans and change only when the zoom crosses a level.
List<AtlasMarker> clusterPlaces(
  List<Place> places,
  AtlasView view, {
  double cellPx = 56,
}) {
  final cell = math
      .pow(2, (math.log(cellPx / view.scale) / math.ln2).round())
      .toDouble();
  final cells = <(int, int), List<(Place, Offset)>>{};
  for (final p in places) {
    final m = projectMetres(p.coordinates.lat, p.coordinates.lng);
    (cells[((m.dx / cell).floor(), (m.dy / cell).floor())] ??= []).add((p, m));
  }
  return [
    for (final group in cells.values)
      AtlasMarker(
        group.map((e) => e.$2).reduce((a, b) => a + b) /
            group.length.toDouble(),
        [for (final e in group) e.$1],
      ),
  ];
}

/// The marker under [screen], within [slop] pixels of its centre.
AtlasMarker? markerAt(
  List<AtlasMarker> markers,
  AtlasView view,
  Size size,
  Offset screen, {
  double slop = 28,
}) {
  AtlasMarker? best;
  var bestD = slop;
  for (final m in markers) {
    final d = (view.toScreen(m.world, size) - screen).distance;
    if (d <= bestD) {
      best = m;
      bestD = d;
    }
  }
  return best;
}

/// The view that fits [marker]'s places with some margin.
AtlasView zoomToMarker(AtlasMarker marker, AtlasView view, Size size) {
  var r = Rect.fromCenter(center: marker.world, width: 0, height: 0);
  for (final p in marker.places) {
    final m = projectMetres(p.coordinates.lat, p.coordinates.lng);
    r = r.expandToInclude(Rect.fromCenter(center: m, width: 0, height: 0));
  }
  final span = math.max(math.max(r.width, r.height), 120.0);
  final fit = math.min(size.width, size.height) * .6 / span;
  final scale = math
      .max(fit, view.scale * 2.2)
      .clamp(AtlasView.minScale, AtlasView.maxScale);
  return view.copyWith(center: r.center, scale: scale);
}
