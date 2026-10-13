import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Axis-aligned bounds in metres; Z is up, Y is north.
class SpaceBounds {
  const SpaceBounds(
    this.minX,
    this.minY,
    this.minZ,
    this.maxX,
    this.maxY,
    this.maxZ,
  );
  final double minX, minY, minZ, maxX, maxY, maxZ;
  double get centerX => (minX + maxX) / 2;
  double get centerY => (minY + maxY) / 2;
  double get centerZ => (minZ + maxZ) / 2;
  double get radius =>
      math.sqrt(
        math.pow(maxX - minX, 2) +
            math.pow(maxY - minY, 2) +
            math.pow(maxZ - minZ, 2),
      ) /
      2;
  double min(int axis) => [minX, minY, minZ][axis];
  double max(int axis) => [maxX, maxY, maxZ][axis];

  static SpaceBounds of(Iterable<Float32List> positions) {
    var lo = [double.infinity, double.infinity, double.infinity];
    var hi = [-double.infinity, -double.infinity, -double.infinity];
    for (final p in positions) {
      for (var i = 0; i < p.length; i += 3) {
        for (var a = 0; a < 3; a++) {
          lo[a] = math.min(lo[a], p[i + a]);
          hi[a] = math.max(hi[a], p[i + a]);
        }
      }
    }
    if (lo[0] > hi[0]) lo = hi = [0, 0, 0];
    return SpaceBounds(lo[0], lo[1], lo[2], hi[0], hi[1], hi[2]);
  }
}

/// One named, closed solid (or several) that appears as a unit in the
/// assembly timeline. Derived data (face normals, edge adjacency) is built
/// once at load; the renderer only reads it.
class SpacePart {
  SpacePart(this.id, this.material, this.positions, this.triangles, this.ao)
    : assert(positions.length % 3 == 0 && triangles.length % 3 == 0) {
    _derive();
  }
  final String id, material;

  /// x, y, z per vertex in metres, Z up.
  final Float32List positions;
  final Uint32List triangles;

  /// Baked ambient occlusion per vertex, 1 = open sky.
  final Float32List ao;
  late final Float32List normals;
  late final SpaceBounds bounds;

  /// Two vertices and two faces per undirected edge (face −1: open edge).
  late final Uint32List edgeVertices;
  late final Int32List edgeFaces;

  /// 1 where the faces meet at more than [creaseDegrees], or the edge is open.
  late final Uint8List edgeSharp;
  static const creaseDegrees = 30.0;
  int get triangleCount => triangles.length ~/ 3;
  int get vertexCount => positions.length ~/ 3;
  bool get closed => !edgeFaces.any((f) => f < 0);

  void _derive() {
    final n = triangleCount;
    normals = Float32List(n * 3);
    for (var t = 0; t < n; t++) {
      final a = triangles[t * 3] * 3,
          b = triangles[t * 3 + 1] * 3,
          c = triangles[t * 3 + 2] * 3;
      final ux = positions[b] - positions[a],
          uy = positions[b + 1] - positions[a + 1],
          uz = positions[b + 2] - positions[a + 2];
      final vx = positions[c] - positions[a],
          vy = positions[c + 1] - positions[a + 1],
          vz = positions[c + 2] - positions[a + 2];
      var nx = uy * vz - uz * vy,
          ny = uz * vx - ux * vz,
          nz = ux * vy - uy * vx;
      final l = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (l > 0) {
        nx /= l;
        ny /= l;
        nz /= l;
      }
      normals[t * 3] = nx;
      normals[t * 3 + 1] = ny;
      normals[t * 3 + 2] = nz;
    }
    bounds = SpaceBounds.of([positions]);
    final vertices = vertexCount;
    final index = <int, int>{};
    final ev = <int>[], ef = <int>[];
    for (var t = 0; t < n; t++) {
      for (var k = 0; k < 3; k++) {
        final a = triangles[t * 3 + k], b = triangles[t * 3 + (k + 1) % 3];
        final key = a < b ? a * vertices + b : b * vertices + a;
        final e = index[key];
        if (e == null) {
          index[key] = ev.length ~/ 2;
          ev
            ..add(math.min(a, b))
            ..add(math.max(a, b));
          ef
            ..add(t)
            ..add(-1);
        } else if (ef[e * 2 + 1] < 0) {
          ef[e * 2 + 1] = t;
        } else {
          throw FormatException('$id: an edge is shared by three faces');
        }
      }
    }
    edgeVertices = Uint32List.fromList(ev);
    edgeFaces = Int32List.fromList(ef);
    final crease = math.cos(creaseDegrees * math.pi / 180);
    edgeSharp = Uint8List(ef.length ~/ 2);
    for (var e = 0; e < edgeSharp.length; e++) {
      final f = ef[e * 2], g = ef[e * 2 + 1];
      edgeSharp[e] =
          g < 0 ||
              normals[f * 3] * normals[g * 3] +
                      normals[f * 3 + 1] * normals[g * 3 + 1] +
                      normals[f * 3 + 2] * normals[g * 3 + 2] <
                  crease
          ? 1
          : 0;
    }
  }
}

class SpaceModel {
  SpaceModel(List<SpacePart> parts)
    : parts = List.unmodifiable(parts),
      bounds = SpaceBounds.of(parts.map((p) => p.positions)) {
    final ids = <String>{};
    for (final p in parts) {
      if (!ids.add(p.id)) throw FormatException('duplicate part ${p.id}');
    }
  }
  final List<SpacePart> parts;
  final SpaceBounds bounds;
  int get triangleCount => parts.fold(0, (n, p) => n + p.triangleCount);
  SpacePart? part(String id) => parts.where((p) => p.id == id).firstOrNull;

  /// glTF 2.0 binary: one part per named mesh node (children and node
  /// transforms applied), Y-up converted to Z-up. Reads POSITION, indices and
  /// the optional `_AO` attribute; refuses required extensions (meshopt comes
  /// with the P09 kit) and sparse accessors.
  factory SpaceModel.fromGlb(ByteData data) {
    if (data.lengthInBytes < 20 ||
        data.getUint32(0, Endian.little) != 0x46546C67 ||
        data.getUint32(4, Endian.little) != 2 ||
        data.getUint32(8, Endian.little) != data.lengthInBytes) {
      throw const FormatException('not a glTF 2.0 binary');
    }
    final jsonLength = data.getUint32(12, Endian.little);
    if (data.getUint32(16, Endian.little) != 0x4E4F534A) {
      throw const FormatException('glb: the first chunk must be JSON');
    }
    final doc = jsonDecode(
      utf8.decode(data.buffer.asUint8List(data.offsetInBytes + 20, jsonLength)),
    ) as Map<String, dynamic>;
    final binStart = 20 + jsonLength;
    if (data.lengthInBytes < binStart + 8 ||
        data.getUint32(binStart + 4, Endian.little) != 0x004E4942) {
      throw const FormatException('glb: missing BIN chunk');
    }
    final bin = ByteData.sublistView(
      data,
      binStart + 8,
      binStart + 8 + data.getUint32(binStart, Endian.little),
    );
    final required = (doc['extensionsRequired'] as List?) ?? const [];
    if (required.isNotEmpty) {
      throw FormatException('glb: unsupported extensions $required');
    }
    return SpaceModel(_GltfReader(doc, bin).parts());
  }
}

class _GltfReader {
  _GltfReader(this.doc, this.bin);
  final Map<String, dynamic> doc;
  final ByteData bin;
  List<dynamic> list(String key) => (doc[key] as List?) ?? const [];

  List<SpacePart> parts() {
    final scenes = list('scenes');
    final roots = scenes.isEmpty
        ? List.generate(list('nodes').length, (i) => i)
        : ((scenes[(doc['scene'] as int?) ?? 0] as Map)['nodes'] as List)
              .cast<int>();
    final out = <SpacePart>[];
    void visit(int index, List<double> parent) {
      final node = list('nodes')[index] as Map<String, dynamic>;
      final world = _multiply(parent, _local(node));
      final mesh = node['mesh'] as int?;
      if (mesh != null) out.add(_part(node, mesh, world));
      for (final child in (node['children'] as List?) ?? const []) {
        visit(child as int, world);
      }
    }

    for (final root in roots) {
      visit(root, _identity);
    }
    return out;
  }

  SpacePart _part(Map<String, dynamic> node, int mesh, List<double> m) {
    final name = node['name'] as String?;
    if (name == null || name.isEmpty) {
      throw const FormatException('glb: every mesh node needs a part name');
    }
    final positions = <double>[], ao = <double>[];
    final triangles = <int>[];
    final primitives =
        (list('meshes')[mesh] as Map<String, dynamic>)['primitives'] as List;
    for (final p in primitives.cast<Map<String, dynamic>>()) {
      if (((p['mode'] as int?) ?? 4) != 4) {
        throw FormatException('$name: only triangle lists are supported');
      }
      final attributes = p['attributes'] as Map<String, dynamic>;
      final base = positions.length ~/ 3;
      final xyz = _floats(attributes['POSITION'] as int, 3);
      for (var i = 0; i < xyz.length; i += 3) {
        // glTF is Y-up: (x, y, z) → (x, −z, y), then the node transform.
        final x = xyz[i], y = xyz[i + 1], z = xyz[i + 2];
        final wx = m[0] * x + m[4] * y + m[8] * z + m[12];
        final wy = m[1] * x + m[5] * y + m[9] * z + m[13];
        final wz = m[2] * x + m[6] * y + m[10] * z + m[14];
        positions
          ..add(wx)
          ..add(-wz)
          ..add(wy);
      }
      final count = xyz.length ~/ 3;
      final occlusion = attributes['_AO'] as int?;
      ao.addAll(
        occlusion == null ? List.filled(count, 1.0) : _floats(occlusion, 1),
      );
      final indices = p['indices'] as int?;
      final local = indices == null
          ? List.generate(count, (i) => i)
          : _indices(indices);
      if (local.length % 3 != 0 || local.any((i) => i >= count)) {
        throw FormatException('$name: bad triangle indices');
      }
      // A mirroring node transform flips the winding.
      final flip = _determinant(m) < 0;
      for (var i = 0; i < local.length; i += 3) {
        triangles
          ..add(base + local[i])
          ..add(base + local[flip ? i + 2 : i + 1])
          ..add(base + local[flip ? i + 1 : i + 2]);
      }
    }
    final extras = (node['extras'] as Map?) ?? const {};
    return SpacePart(
      name,
      (extras['material'] as String?) ?? 'stone',
      Float32List.fromList(positions),
      Uint32List.fromList(triangles),
      Float32List.fromList(ao),
    );
  }

  (int, int, Map<String, dynamic>) _view(int accessor, int width, int size) {
    final a = list('accessors')[accessor] as Map<String, dynamic>;
    if (a['sparse'] != null) {
      throw const FormatException('glb: sparse accessors are not supported');
    }
    final v =
        list('bufferViews')[a['bufferView'] as int] as Map<String, dynamic>;
    final offset =
        ((v['byteOffset'] as int?) ?? 0) + ((a['byteOffset'] as int?) ?? 0);
    final stride = (v['byteStride'] as int?) ?? width * size;
    final count = a['count'] as int;
    if (count > 0 &&
        offset + stride * (count - 1) + width * size > bin.lengthInBytes) {
      throw const FormatException('glb: accessor outside the buffer');
    }
    return (offset, stride, a);
  }

  List<double> _floats(int accessor, int width) {
    final (offset, stride, a) = _view(accessor, width, 4);
    if (a['componentType'] != 5126) {
      throw const FormatException('glb: float attributes expected');
    }
    final count = a['count'] as int;
    return [
      for (var i = 0; i < count; i++)
        for (var k = 0; k < width; k++)
          bin.getFloat32(offset + i * stride + k * 4, Endian.little),
    ];
  }

  List<int> _indices(int accessor) {
    final a = list('accessors')[accessor] as Map<String, dynamic>;
    final size = switch (a['componentType']) {
      5121 => 1,
      5123 => 2,
      5125 => 4,
      _ => throw const FormatException('glb: bad index type'),
    };
    final (offset, stride, _) = _view(accessor, 1, size);
    return [
      for (var i = 0; i < (a['count'] as int); i++)
        switch (size) {
          1 => bin.getUint8(offset + i * stride),
          2 => bin.getUint16(offset + i * stride, Endian.little),
          _ => bin.getUint32(offset + i * stride, Endian.little),
        },
    ];
  }

  static const _identity = <double>[
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    1,
  ];

  /// Column-major 4×4 from `matrix` or translation · rotation · scale.
  static List<double> _local(Map<String, dynamic> node) {
    final matrix = node['matrix'] as List?;
    if (matrix != null) {
      return matrix.map((v) => (v as num).toDouble()).toList();
    }
    List<double> read(String key, List<double> fallback) =>
        (node[key] as List?)?.map((v) => (v as num).toDouble()).toList() ??
        fallback;
    final t = read('translation', [0, 0, 0]);
    final q = read('rotation', [0, 0, 0, 1]);
    final s = read('scale', [1, 1, 1]);
    final x = q[0], y = q[1], z = q[2], w = q[3];
    return [
      (1 - 2 * (y * y + z * z)) * s[0],
      (2 * (x * y + z * w)) * s[0],
      (2 * (x * z - y * w)) * s[0],
      0,
      (2 * (x * y - z * w)) * s[1],
      (1 - 2 * (x * x + z * z)) * s[1],
      (2 * (y * z + x * w)) * s[1],
      0,
      (2 * (x * z + y * w)) * s[2],
      (2 * (y * z - x * w)) * s[2],
      (1 - 2 * (x * x + y * y)) * s[2],
      0,
      t[0],
      t[1],
      t[2],
      1,
    ];
  }

  static List<double> _multiply(List<double> a, List<double> b) => [
    for (var c = 0; c < 4; c++)
      for (var r = 0; r < 4; r++)
        a[r] * b[c * 4] +
            a[4 + r] * b[c * 4 + 1] +
            a[8 + r] * b[c * 4 + 2] +
            a[12 + r] * b[c * 4 + 3],
  ];

  static double _determinant(List<double> m) =>
      m[0] * (m[5] * m[10] - m[9] * m[6]) -
      m[4] * (m[1] * m[10] - m[9] * m[2]) +
      m[8] * (m[1] * m[6] - m[5] * m[2]);
}
