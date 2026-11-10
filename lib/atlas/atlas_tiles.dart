import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'atlas_data.dart';
import 'atlas_style.dart';
import 'atlas_view.dart';

/// A square of the map at zoom [z]: [atlasTileSpan] / 2^z metres a side.
@immutable
class TileKey {
  const TileKey(this.manner, this.z, this.x, this.y);
  final AtlasManner manner;
  final int z, x, y;

  TileKey? get parent => z == 0 ? null : TileKey(manner, z - 1, x >> 1, y >> 1);

  @override
  bool operator ==(Object other) =>
      other is TileKey &&
      other.manner == manner &&
      other.z == z &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(manner, z, x, y);

  @override
  String toString() => '${manner.name}/$z/$x/$y';
}

/// Tile 0/0/0 covers the whole province: 262 km a side.
const atlasTileSpan = 262144.0;
const atlasMaxZoom = 11;

/// A tile shows between [tileMinPx] and twice that many logical pixels; its
/// line widths are drawn for the geometric mean, so they vary ±41%.
const tileMinPx = 192.0;
const tileLogicalPx = tileMinPx * math.sqrt2;

/// The tile grid's south-west corner (metres): below and left of the
/// province (CLIP in tool/atlas/build_atlas.py).
const atlasTileOrigin = ui.Offset(-90000, -40000);

double tileSpan(int z) => atlasTileSpan / (1 << z);

ui.Rect tileRect(int z, int x, int y) {
  final s = tileSpan(z);
  return ui.Rect.fromLTWH(
    atlasTileOrigin.dx + x * s,
    atlasTileOrigin.dy + y * s,
    s,
    s,
  );
}

/// The zoom whose tiles show between [minPx] and twice that on screen.
int zoomFor(double scale, {double minPx = tileMinPx}) {
  final z = (math.log(atlasTileSpan * scale / minPx) / math.ln2).floor();
  return z.clamp(0, atlasMaxZoom);
}

/// The tiles of [manner] that cover [view] on a screen of [size].
List<TileKey> visibleTiles(AtlasView view, ui.Size size, AtlasManner manner) {
  final z = zoomFor(view.scale);
  final world = view.visibleWorld(size);
  final span = tileSpan(z), n = 1 << z;
  int col(double x) =>
      ((x - atlasTileOrigin.dx) / span).floor().clamp(0, n - 1);
  int row(double y) =>
      ((y - atlasTileOrigin.dy) / span).floor().clamp(0, n - 1);
  return [
    for (var y = row(world.top); y <= row(world.bottom); y++)
      for (var x = col(world.left); x <= col(world.right); x++)
        TileKey(manner, z, x, y),
  ];
}

/// Features of one layer by grid cell, so a tile reads only what is near.
class LayerIndex {
  LayerIndex(this.data, {this.cell = 2000}) {
    for (var i = 0; i < data.features.length; i++) {
      final b = data.features[i].bounds;
      for (var cx = _c(b.left); cx <= _c(b.right); cx++) {
        for (var cy = _c(b.top); cy <= _c(b.bottom); cy++) {
          (_cells[(cx, cy)] ??= []).add(i);
        }
      }
    }
  }
  final AtlasLayerData data;
  final double cell;
  final _cells = <(int, int), List<int>>{};
  int _c(double v) => (v / cell).floor();

  Iterable<AtlasFeature> query(ui.Rect r) sync* {
    final seen = <int>{};
    for (var cx = _c(r.left); cx <= _c(r.right); cx++) {
      for (var cy = _c(r.top); cy <= _c(r.bottom); cy++) {
        for (final i in _cells[(cx, cy)] ?? const <int>[]) {
          if (seen.add(i) && data.features[i].bounds.overlaps(r)) {
            yield data.features[i];
          }
        }
      }
    }
  }
}

/// Every layer's index, built once per decoded atlas.
class AtlasIndex {
  AtlasIndex(this.data) {
    for (final l in data.layers) {
      // Footprints are dense (~3,500 per km² in the walled city): a finer
      // grid keeps a close-in tile from scanning thousands it does not touch.
      _layers[(l.layer, l.lod)] = LayerIndex(
        l,
        cell: l.layer == AtlasLayer.buildings ? 250 : 2000,
      );
    }
  }
  final AtlasData data;
  final _layers = <(AtlasLayer, AtlasLod), LayerIndex>{};
  LayerIndex? layer(AtlasLayer layer, AtlasLod lod) =>
      _layers[(layer, lod)] ?? _layers[(layer, AtlasLod.fine)];
}

/// Draws one tile in one manner into a picture.
class TileRenderer {
  TileRenderer(this.index);
  final AtlasIndex index;
  late final ui.Rect _box = index.data.bounds;

  ui.Picture record(TileKey key, int resolution) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    paint(canvas, key, resolution.toDouble());
    return recorder.endRecording();
  }

  /// [px] pixels a side; metres are mapped with north up.
  void paint(ui.Canvas canvas, TileKey key, double px) {
    final world = tileRect(key.z, key.x, key.y);
    final k = px / world.width; // pixels per metre
    final mpp = 1 / k;
    final style = MannerStyle.of(key.manner);
    final modern = key.manner == AtlasManner.modern;
    final lod = mpp > 8 ? AtlasLod.coarse : AtlasLod.fine;
    // A margin so strokes on a tile's edge continue into the next tile.
    final pad = 4 * mpp;
    final query = world.inflate(pad);
    double sx(double x) => (x - world.left) * k;
    double sy(double y) => (world.bottom - y) * k;

    canvas.clipRect(ui.Rect.fromLTWH(0, 0, px, px));
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, px, px),
      ui.Paint()..color = style.water,
    );
    if (!modern) _waterMarks(canvas, key, world, k, style);

    final fill = ui.Paint()..style = ui.PaintingStyle.fill;
    final stroke = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeJoin = ui.StrokeJoin.round
      ..strokeCap = ui.StrokeCap.round;

    // Land, clipped to the tile; its shore stroked where it is real coast.
    // Before today the peninsula's Marmara shore ran along the sea walls:
    // the older manners swap the land that has been filled since (class 1)
    // for its shape then.
    final land = ui.Path()..fillType = ui.PathFillType.evenOdd;
    final shore = ui.Path();
    final landFeatures = [
      for (final f in index.layer(AtlasLayer.land, lod)!.query(query))
        if (modern || f.cls != 1) f,
      if (!modern) ...?index.layer(AtlasLayer.landThen, lod)?.query(query),
    ];
    for (final f in landFeatures) {
      for (final ring in f.rings) {
        _addClipped(land, ring, query, sx, sy);
        _addShore(shore, ring, query, sx, sy, _box);
      }
    }
    canvas.drawPath(land, fill..color = style.land);

    // Lakes and lagoons in every manner; reservoirs (class 1) are modern.
    final lakes = ui.Path()..fillType = ui.PathFillType.evenOdd;
    final lakeShore = ui.Path();
    for (final f
        in index.layer(AtlasLayer.water, lod)?.query(query) ??
            const <AtlasFeature>[]) {
      if (f.cls == 1 && !modern) continue;
      for (final ring in f.rings) {
        _addClipped(lakes, ring, query, sx, sy);
        _addShore(lakeShore, ring, query, sx, sy, null);
      }
    }
    canvas.drawPath(lakes, fill..color = style.water);

    if (modern) _modernLayers(canvas, query, lod, mpp, k, sx, sy);

    final shoreWidth = style.shoreWidth * _pxPerLogical;
    if (!modern) {
      // Pen shore: a pale wash on the water side under the ink line.
      canvas.drawPath(
        shore,
        stroke
          ..color = style.waterMark.withValues(alpha: .18)
          ..strokeWidth = shoreWidth * 5,
      );
    }
    canvas.drawPath(
      shore,
      stroke
        ..color = style.shore
        ..strokeWidth = shoreWidth,
    );
    canvas.drawPath(
      lakeShore,
      stroke
        ..color = style.shore
        ..strokeWidth = shoreWidth * .7,
    );
  }

  void _modernLayers(
    ui.Canvas canvas,
    ui.Rect query,
    AtlasLod lod,
    double mpp,
    double k,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    final unit = _pxPerLogical; // one logical pixel in tile pixels
    final fill = ui.Paint()..style = ui.PaintingStyle.fill;
    final stroke = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeJoin = ui.StrokeJoin.round
      ..strokeCap = ui.StrokeCap.round;

    if (mpp < 120) {
      final parks = ui.Path()..fillType = ui.PathFillType.evenOdd;
      for (final f
          in index.layer(AtlasLayer.parks, lod)?.query(query) ??
              const <AtlasFeature>[]) {
        for (final ring in f.rings) {
          _addClipped(parks, ring, query, sx, sy);
        }
      }
      canvas.drawPath(parks, fill..color = const ui.Color(0x2E3A655B));
    }

    if (mpp < 2.6) {
      final plain = ui.Path(), worship = ui.Path();
      for (final f
          in index.layer(AtlasLayer.buildings, lod)?.query(query) ??
              const <AtlasFeature>[]) {
        for (final ring in f.rings) {
          _addRing(f.cls == 1 ? worship : plain, ring, sx, sy);
        }
      }
      canvas.drawPath(plain, fill..color = const ui.Color(0xFFE1D7C7));
      canvas.drawPath(worship, fill..color = const ui.Color(0x664E1B2B));
      canvas.drawPath(
        plain,
        stroke
          ..color = const ui.Color(0x99847770)
          ..strokeWidth = .4 * unit,
      );
    }

    if (mpp > 8 && mpp < 220) {
      final districts = ui.Path();
      for (final f
          in index.layer(AtlasLayer.districts, lod)?.query(query) ??
              const <AtlasFeature>[]) {
        for (final ring in f.rings) {
          _addLine(districts, ring, sx, sy);
        }
      }
      _dashed(
        canvas,
        districts,
        stroke
          ..color = const ui.Color(0xB3847770)
          ..strokeWidth = .7 * unit,
        [4 * unit, 3 * unit],
      );
    }
    final province = ui.Path();
    for (final f
        in index.layer(AtlasLayer.province, lod)?.query(query) ??
            const <AtlasFeature>[]) {
      for (final ring in f.rings) {
        _addLine(province, ring, sx, sy);
      }
    }
    canvas.drawPath(
      province,
      stroke
        ..color = const ui.Color(0xFF635B58)
        ..strokeWidth = 1.1 * unit,
    );

    // Roads: rank 0 motorway … 4 tertiary; minor ranks only zoomed in.
    const maxMpp = [400.0, 400.0, 60.0, 14.0, 5.0];
    const widths = [1.7, 1.5, 1.15, .9, .7];
    final roads = List.generate(5, (_) => ui.Path());
    for (final f
        in index.layer(AtlasLayer.roads, lod)?.query(query) ??
            const <AtlasFeature>[]) {
      final rank = f.cls.clamp(0, 4);
      if (mpp > maxMpp[rank]) continue;
      for (final ring in f.rings) {
        _addLine(roads[rank], ring, sx, sy);
      }
    }
    for (var rank = 4; rank >= 0; rank--) {
      canvas.drawPath(
        roads[rank],
        stroke
          ..color = rank <= 1
              ? const ui.Color(0xFF151314)
              : const ui.Color(0xFF635B58)
          ..strokeWidth = widths[rank] * unit,
      );
    }

    if (mpp < 80) {
      final ferry = ui.Path();
      for (final f
          in index.layer(AtlasLayer.ferry, lod)?.query(query) ??
              const <AtlasFeature>[]) {
        for (final ring in f.rings) {
          _addLine(ferry, ring, sx, sy);
        }
      }
      _dashed(
        canvas,
        ferry,
        stroke
          ..color = const ui.Color(0xB3194F78)
          ..strokeWidth = .8 * unit,
        [3 * unit, 3 * unit],
      );
    }
    if (mpp < 120) {
      // Rails above ground; tunnels belong to the Below layer.
      final rail = ui.Path(), tram = ui.Path();
      for (final f
          in index.layer(AtlasLayer.rail, lod)?.query(query) ??
              const <AtlasFeature>[]) {
        if (f.cls & 8 != 0) continue;
        final kind = f.cls & 7;
        for (final ring in f.rings) {
          _addLine(kind == 3 ? tram : rail, ring, sx, sy);
        }
      }
      canvas.drawPath(
        rail,
        stroke
          ..color = const ui.Color(0xFF4E1B2B)
          ..strokeWidth = 1.2 * unit,
      );
      canvas.drawPath(
        tram,
        stroke
          ..color = const ui.Color(0xCC4E1B2B)
          ..strokeWidth = .8 * unit,
      );
    }
  }

  /// Tile pixels per logical pixel, for line widths and pattern spacing.
  double _pxPerLogical = 1;

  /// Pen marks on the water, on a grid fixed in metres for this zoom so
  /// neighbouring tiles agree. Land is painted over them afterwards.
  void _waterMarks(
    ui.Canvas canvas,
    TileKey key,
    ui.Rect world,
    double k,
    MannerStyle style,
  ) {
    final logical = world.width / tileLogicalPx; // metres per logical px
    final spacing = (key.manner == AtlasManner.ottoman ? 14 : 22) * logical;
    final paint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round
      ..color = style.waterMark
      ..strokeWidth = .9 * _pxPerLogical;
    final i0 = (world.left / spacing).floor() - 1,
        i1 = (world.right / spacing).ceil() + 1;
    final j0 = (world.top / spacing).floor() - 1,
        j1 = (world.bottom / spacing).ceil() + 1;
    final path = ui.Path();
    for (var j = j0; j <= j1; j++) {
      for (var i = i0; i <= i1; i++) {
        // Stagger rows; jitter manuscript marks by a hash of the cell.
        final h = _hash(i, j, key.z);
        final ox = key.manner == AtlasManner.ottoman
            ? (j.isOdd ? .5 : 0)
            : (h & 0xFF) / 255 * .6;
        final oy = key.manner == AtlasManner.ottoman
            ? 0
            : ((h >> 8) & 0xFF) / 255 * .6;
        final x = ((i + ox) * spacing - world.left) * k;
        final y = (world.bottom - (j + oy) * spacing) * k;
        final w = spacing * k * (key.manner == AtlasManner.ottoman ? .5 : .32);
        if (key.manner == AtlasManner.ottoman) {
          // A scale: half a ring opening downwards.
          path.addArc(
            ui.Rect.fromCenter(
              center: ui.Offset(x, y),
              width: w * 2,
              height: w * 1.4,
            ),
            math.pi,
            math.pi,
          );
        } else {
          // A pen wave: two shallow humps.
          path
            ..moveTo(x - w, y)
            ..quadraticBezierTo(x - w / 2, y - w * .45, x, y)
            ..quadraticBezierTo(x + w / 2, y - w * .45, x + w, y);
        }
      }
    }
    canvas.drawPath(path, paint);
  }

  static int _hash(int i, int j, int z) {
    var h = i * 73856093 ^ j * 19349663 ^ z * 83492791;
    h = (h ^ (h >> 13)) * 0x5bd1e995;
    return (h ^ (h >> 15)) & 0x7fffffff;
  }

  static void _addRing(
    ui.Path path,
    Float32List ring,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    if (ring.length < 6) return;
    path.moveTo(sx(ring[0]), sy(ring[1]));
    for (var i = 2; i < ring.length; i += 2) {
      path.lineTo(sx(ring[i]), sy(ring[i + 1]));
    }
    path.close();
  }

  static void _addLine(
    ui.Path path,
    Float32List line,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    if (line.length < 4) return;
    path.moveTo(sx(line[0]), sy(line[1]));
    for (var i = 2; i < line.length; i += 2) {
      path.lineTo(sx(line[i]), sy(line[i + 1]));
    }
  }

  /// Sutherland–Hodgman against [r]; small rings are added whole.
  static void _addClipped(
    ui.Path path,
    Float32List ring,
    ui.Rect r,
    double Function(double) sx,
    double Function(double) sy,
  ) {
    final n = ring.length ~/ 2;
    if (n < 3) return;
    if (n < 48) {
      _addRing(path, ring, sx, sy);
      return;
    }
    var pts = <double>[...ring];
    for (var edge = 0; edge < 4; edge++) {
      if (pts.length < 6) return;
      final out = <double>[];
      bool inside(double x, double y) => switch (edge) {
        0 => x >= r.left,
        1 => x <= r.right,
        2 => y >= r.top,
        _ => y <= r.bottom,
      };
      (double, double) cut(double ax, double ay, double bx, double by) {
        final t = switch (edge) {
          0 => (r.left - ax) / (bx - ax),
          1 => (r.right - ax) / (bx - ax),
          2 => (r.top - ay) / (by - ay),
          _ => (r.bottom - ay) / (by - ay),
        };
        return (ax + (bx - ax) * t, ay + (by - ay) * t);
      }

      var px = pts[pts.length - 2], py = pts[pts.length - 1];
      var pin = inside(px, py);
      for (var i = 0; i < pts.length; i += 2) {
        final x = pts[i], y = pts[i + 1];
        final cin = inside(x, y);
        if (cin) {
          if (!pin) {
            final (cx, cy) = cut(px, py, x, y);
            out.add(cx);
            out.add(cy);
          }
          out.add(x);
          out.add(y);
        } else if (pin) {
          final (cx, cy) = cut(px, py, x, y);
          out.add(cx);
          out.add(cy);
        }
        px = x;
        py = y;
        pin = cin;
      }
      pts = out;
    }
    if (pts.length < 6) return;
    path.moveTo(sx(pts[0]), sy(pts[1]));
    for (var i = 2; i < pts.length; i += 2) {
      path.lineTo(sx(pts[i]), sy(pts[i + 1]));
    }
    path.close();
  }

  /// The ring's segments near [r], skipping edges along [box] (the clip box
  /// that closes land, not a shore).
  static void _addShore(
    ui.Path path,
    Float32List ring,
    ui.Rect r,
    double Function(double) sx,
    double Function(double) sy,
    ui.Rect? box,
  ) {
    final n = ring.length ~/ 2;
    if (n < 2) return;
    bool onBox(double x, double y) =>
        box != null &&
        ((x - box.left).abs() < 1.5 ||
            (x - box.right).abs() < 1.5 ||
            (y - box.top).abs() < 1.5 ||
            (y - box.bottom).abs() < 1.5);
    var open = false;
    for (var i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final ax = ring[i * 2], ay = ring[i * 2 + 1];
      final bx = ring[j * 2], by = ring[j * 2 + 1];
      final visible =
          !(math.max(ax, bx) < r.left ||
              math.min(ax, bx) > r.right ||
              math.max(ay, by) < r.top ||
              math.min(ay, by) > r.bottom) &&
          !(onBox(ax, ay) && onBox(bx, by));
      if (!visible) {
        open = false;
        continue;
      }
      if (!open) path.moveTo(sx(ax), sy(ay));
      path.lineTo(sx(bx), sy(by));
      open = true;
    }
  }

  static void _dashed(
    ui.Canvas canvas,
    ui.Path path,
    ui.Paint paint,
    List<double> pattern,
  ) {
    final dashed = ui.Path();
    for (final metric in path.computeMetrics()) {
      var d = 0.0, on = true, k = 0;
      while (d < metric.length) {
        final len = pattern[k % pattern.length];
        if (on) dashed.addPath(metric.extractPath(d, d + len), ui.Offset.zero);
        d += len;
        on = !on;
        k++;
      }
    }
    canvas.drawPath(dashed, paint);
  }
}

/// Rendered tiles, least recently used first out. Missing tiles are queued
/// and rendered a few per frame within [budget]; listeners repaint.
class TileCache extends ChangeNotifier {
  TileCache(this.renderer, {this.capacity = 96, this.resolution = 512});
  final TileRenderer renderer;
  final int capacity, resolution;
  final _tiles = <TileKey, ui.Image>{}; // insertion-ordered: LRU
  final _queue = <TileKey>[];
  final _queued = <TileKey>{};
  bool _scheduled = false, _disposed = false;

  /// Upper bound on rendering time per frame.
  Duration budget = const Duration(milliseconds: 6);

  int get length => _tiles.length;

  ui.Image? peek(TileKey key) {
    final image = _tiles.remove(key);
    if (image != null) _tiles[key] = image; // most recent
    return image;
  }

  /// Asks for [key]; tiles on screen go before [prefetch]ed ones.
  void request(TileKey key) {
    if (_disposed || _tiles.containsKey(key) || !_queued.add(key)) return;
    _queue.add(key);
    _schedule();
  }

  /// Tiles wanted soon but not on screen (the other manners at rest, so a
  /// crossfade finds them ready); rendered after visible ones, kept queued
  /// until the next call.
  void prefetch(Iterable<TileKey> keys) {
    _prefetched = keys.toSet();
    holdPrefetch = false;
    keys.forEach(request);
    _schedule();
  }

  Set<TileKey> _prefetched = const {};

  /// While the camera moves, prefetched tiles wait: every frame's spare time
  /// goes to the tiles on screen.
  bool holdPrefetch = false;

  void _schedule() {
    if (_scheduled || _disposed) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      pump();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// Renders queued tiles until [budget] is spent; returns how many.
  int pump({bool all = false}) {
    if (_disposed) return 0;
    final watch = Stopwatch()..start();
    var made = 0;
    renderer._pxPerLogical = resolution / tileLogicalPx;
    // On-screen tiles first, coarse zooms first: they back up the rest.
    _queue.sort((a, b) {
      final pa = _prefetched.contains(a) ? 1 : 0;
      final pb = _prefetched.contains(b) ? 1 : 0;
      return pa != pb ? pa - pb : a.z.compareTo(b.z);
    });
    while (_queue.isNotEmpty && (all || watch.elapsed < budget || made == 0)) {
      if (!all && holdPrefetch && _prefetched.contains(_queue.first)) break;
      final key = _queue.removeAt(0);
      _queued.remove(key);
      if (_tiles.containsKey(key)) continue;
      final picture = renderer.record(key, resolution);
      final image = picture.toImageSync(resolution, resolution);
      picture.dispose();
      _tiles[key] = image;
      made++;
      while (_tiles.length > capacity) {
        final oldest = _tiles.keys.first;
        _tiles.remove(oldest)!.dispose();
      }
    }
    final waiting =
        _queue.isNotEmpty &&
        !(holdPrefetch && _prefetched.contains(_queue.first));
    if (waiting) _schedule();
    if (made > 0) notifyListeners();
    return made;
  }

  /// Drops queued work outside [keep] (the tiles now on screen).
  void retain(Set<TileKey> keep) {
    _queue.removeWhere((k) {
      final drop = !keep.contains(k) && !_prefetched.contains(k) && k.z > 2;
      if (drop) _queued.remove(k);
      return drop;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    for (final image in _tiles.values) {
      image.dispose();
    }
    _tiles.clear();
    super.dispose();
  }
}
