import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

/// Layer ids shared with tool/atlas/build_atlas.py.
enum AtlasLayer {
  land(1),
  water(2),
  districts(3),
  province(4),
  roads(5),
  rail(6),
  ferry(7),
  stops(8),
  parks(9),
  buildings(10),
  districtLabels(11),

  /// The peninsula's land before the 20th-century fills, for the Byzantine
  /// and Ottoman manners; replaces the land features of class 1.
  landThen(12);

  const AtlasLayer(this.id);
  final int id;
  static AtlasLayer byId(int id) => values.firstWhere((l) => l.id == id);
}

enum AtlasLod { fine, coarse }

enum AtlasGeometry { points, lines, polygons }

/// One OSM feature in metres east (x) and north (y) of the Milion.
class AtlasFeature {
  AtlasFeature(this.cls, this.name, this.bounds, this.rings);

  /// Layer-specific class: road rank, rail kind (bit 3: underground), stop
  /// kind, building kind (1: mosque or church).
  final int cls;
  final String? name;

  /// In metres; top is the south edge (smaller y), as stored.
  final Rect bounds;

  /// x, y pairs per ring (or one point per ring for point layers).
  final List<Float32List> rings;
}

class AtlasLayerData {
  AtlasLayerData(this.layer, this.lod, this.geometry, this.features);
  final AtlasLayer layer;
  final AtlasLod lod;
  final AtlasGeometry geometry;
  final List<AtlasFeature> features;
  late final Rect bounds = features.isEmpty
      ? Rect.zero
      : features.map((f) => f.bounds).reduce((a, b) => a.expandToInclude(b));
}

/// The OSM half of the Atlas, decoded from assets/atlas/atlas.bin (format in
/// tool/atlas/build_atlas.py). Data © OpenStreetMap contributors, ODbL 1.0.
class AtlasData {
  AtlasData._(this._layers);
  final Map<(AtlasLayer, AtlasLod), AtlasLayerData> _layers;

  static const assetPath = 'assets/atlas/atlas.bin';

  /// The layer at [lod], falling back to the fine one (some layers have one).
  AtlasLayerData? layer(AtlasLayer layer, [AtlasLod lod = AtlasLod.fine]) =>
      _layers[(layer, lod)] ?? _layers[(layer, AtlasLod.fine)];

  Iterable<AtlasLayerData> get layers => _layers.values;

  /// Everything drawn, in metres.
  late final Rect bounds = layer(AtlasLayer.land)!.bounds;

  factory AtlasData.decode(ByteData data) {
    final r = _Reader(data);
    if (r.byte() != 0x4D ||
        r.byte() != 0x4C ||
        r.byte() != 0x41 ||
        r.byte() != 0x54) {
      throw const FormatException('atlas.bin: bad magic');
    }
    final version = r.byte();
    if (version != 1) throw FormatException('atlas.bin: version $version');
    final strings = List.generate(r.uvar(), (_) {
      final n = r.uvar();
      return utf8.decode(r.bytes(n));
    });
    final layers = <(AtlasLayer, AtlasLod), AtlasLayerData>{};
    final count = r.uvar();
    for (var l = 0; l < count; l++) {
      final layer = AtlasLayer.byId(r.byte());
      final lod = AtlasLod.values[r.byte()];
      final geometry = AtlasGeometry.values[r.byte()];
      final features = List<AtlasFeature>.generate(r.uvar(), (_) {
        final cls = r.byte();
        final name = r.uvar();
        final x0 = r.zvar(), y0 = r.zvar(), x1 = r.zvar(), y1 = r.zvar();
        final rings = List<Float32List>.generate(r.uvar(), (_) {
          final n = r.uvar();
          final pts = Float32List(n * 2);
          var x = x0, y = y0;
          for (var i = 0; i < n; i++) {
            x += r.zvar();
            y += r.zvar();
            pts[i * 2] = x.toDouble();
            pts[i * 2 + 1] = y.toDouble();
          }
          return pts;
        }, growable: false);
        return AtlasFeature(
          cls,
          name == 0 ? null : strings[name - 1],
          Rect.fromLTRB(
            x0.toDouble(),
            y0.toDouble(),
            x1.toDouble(),
            y1.toDouble(),
          ),
          rings,
        );
      }, growable: false);
      layers[(layer, lod)] = AtlasLayerData(layer, lod, geometry, features);
    }
    if (r.offset != data.lengthInBytes) {
      throw const FormatException('atlas.bin: trailing bytes');
    }
    if (layers[(AtlasLayer.land, AtlasLod.fine)] == null) {
      throw const FormatException('atlas.bin: no land');
    }
    return AtlasData._(layers);
  }
}

class _Reader {
  _Reader(this.data);
  final ByteData data;
  int offset = 0;
  int byte() => data.getUint8(offset++);
  Uint8List bytes(int n) {
    final b = data.buffer.asUint8List(data.offsetInBytes + offset, n);
    offset += n;
    return b;
  }

  int uvar() {
    var result = 0, shift = 0;
    while (true) {
      final b = byte();
      result |= (b & 0x7F) << shift;
      if (b & 0x80 == 0) return result;
      shift += 7;
      if (shift > 49) throw const FormatException('atlas.bin: varint');
    }
  }

  int zvar() {
    final n = uvar();
    return (n >> 1) ^ -(n & 1);
  }
}
