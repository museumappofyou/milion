import 'dart:math' as math;
import 'dart:typed_data';

/// Decoders for `EXT_meshopt_compression`: meshoptimizer's vertex codec
/// version 0 (`ATTRIBUTES`), triangle codec version 1 (`TRIANGLES`) and the
/// EXPONENTIAL filter. The P09 kit (`tool/space/meshopt.py`) writes these;
/// tests check this decoder against vectors from meshoptimizer's own encoder.
class Meshopt {
  Meshopt._();

  static const _group = 16;

  static int _dezig(int v) => (v >> 1) ^ -(v & 1);

  /// [count] × [stride] bytes from a version 0 vertex stream.
  static Uint8List decodeVertexBuffer(Uint8List src, int count, int stride) {
    if (stride % 4 != 0 || stride <= 0 || stride > 256) {
      throw const FormatException('meshopt: bad vertex stride');
    }
    final tail = math.max(32, stride);
    if (src.length < 1 + tail || src[0] != 0xa0) {
      throw const FormatException('meshopt: not a version 0 vertex stream');
    }
    final out = Uint8List(count * stride);
    final last = Uint8List.fromList(src.sublist(src.length - stride));
    final blockSize = math.min((8192 ~/ stride) & ~(_group - 1), 256);
    final lanes = Uint8List(blockSize * stride);
    final end = src.length - tail;
    var pos = 1;
    int byte(int i) {
      if (i >= end) throw const FormatException('meshopt: truncated stream');
      return src[i];
    }

    for (var base = 0; base < count; base += blockSize) {
      final n = math.min(count - base, blockSize);
      final groups = (n + _group - 1) ~/ _group;
      final headerSize = (groups + 3) ~/ 4;
      for (var k = 0; k < stride; k++) {
        final header = pos;
        pos += headerSize;
        final lane = k * blockSize;
        for (var g = 0; g < groups; g++) {
          final mode = (byte(header + (g >> 2)) >> ((g & 3) * 2)) & 3;
          final at = lane + g * _group;
          switch (mode) {
            case 0:
              lanes.fillRange(at, at + _group, 0);
            case 3:
              for (var m = 0; m < _group; m++) {
                lanes[at + m] = byte(pos + m);
              }
              pos += _group;
            default:
              final bits = mode == 1 ? 2 : 4;
              final per = 8 ~/ bits, sentinel = (1 << bits) - 1;
              final packed = pos;
              pos += _group ~/ per;
              for (var m = 0; m < _group; m++) {
                var v =
                    (byte(packed + m ~/ per) >> (8 - bits - (m % per) * bits)) &
                    sentinel;
                if (v == sentinel) v = byte(pos++);
                lanes[at + m] = v;
              }
          }
        }
      }
      for (var i = 0; i < n; i++) {
        final o = (base + i) * stride;
        for (var k = 0; k < stride; k++) {
          last[k] = (last[k] + _dezig(lanes[k * blockSize + i])) & 0xff;
          out[o + k] = last[k];
        }
      }
    }
    if (pos != end) throw const FormatException('meshopt: vertex stream size');
    return out;
  }

  /// Triangle indices from a version 1 index stream. Triangles may come back
  /// rotated; their winding is kept.
  static Uint32List decodeIndexBuffer(Uint8List src, int count) {
    final triangles = count ~/ 3;
    if (count % 3 != 0 || src.length < 1 + triangles + 16 || src[0] != 0xe1) {
      throw const FormatException('meshopt: not a version 1 triangle stream');
    }
    final out = Uint32List(count);
    final edges = Uint32List(32), verts = Uint32List(16);
    final table = src.length - 16;
    var eo = 0, vo = 0, next = 0, last = 0;
    var code = 1, data = 1 + triangles;
    int readData() {
      if (data >= table) throw const FormatException('meshopt: truncated');
      return src[data++];
    }

    int leb() {
      var n = 0;
      for (var shift = 0; ; shift += 7) {
        final b = readData();
        n |= (b & 127) << shift;
        if (b < 128 || shift >= 28) return n;
      }
    }

    int free() => last = (last + _dezig(leb())) & 0xffffffff;
    void pushEdge(int a, int b) {
      edges[eo] = a;
      edges[eo + 1] = b;
      eo = (eo + 2) & 31;
    }

    void pushVertex(int v) {
      verts[vo] = v;
      vo = (vo + 1) & 15;
    }

    int vertex(int n) => verts[(vo - 1 - n) & 15];
    for (var t = 0; t < triangles; t++) {
      final c0 = src[code++];
      final hi = c0 >> 4, lo = c0 & 15;
      int a, b, c;
      if (hi < 15) {
        a = edges[(eo - 1 - hi * 2) & 31];
        b = edges[(eo - 2 - hi * 2) & 31];
        if (lo == 0) {
          c = next++;
        } else if (lo < 13) {
          c = vertex(lo);
        } else if (lo < 15) {
          c = last = (last + (lo == 13 ? -1 : 1)) & 0xffffffff;
        } else {
          c = free();
        }
        if (lo == 0 || lo >= 13) pushVertex(c);
        pushEdge(b, c);
        pushEdge(c, a);
      } else {
        final int e;
        if (lo < 14) {
          e = src[table + lo];
          a = next++;
        } else {
          e = readData();
          if (e == 0) next = 0;
          a = lo == 14 ? next++ : free();
        }
        final z = e >> 4, w = e & 15;
        b = z == 0 ? next++ : (z == 15 ? free() : vertex(z - 1));
        c = w == 0 ? next++ : (w == 15 ? free() : vertex(w - 1));
        pushVertex(a);
        if (z == 0 || z == 15) pushVertex(b);
        if (w == 0 || w == 15) pushVertex(c);
        pushEdge(a, b);
        pushEdge(b, c);
        pushEdge(c, a);
      }
      out[t * 3] = a;
      out[t * 3 + 1] = b;
      out[t * 3 + 2] = c;
    }
    if (data != table) throw const FormatException('meshopt: index size');
    return out;
  }

  /// EXPONENTIAL filter in place: each 32-bit word m·2^e becomes a float.
  static void exponential(Uint8List bytes) {
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i + 4 <= bytes.length; i += 4) {
      final v = view.getInt32(i, Endian.little);
      final e = v >> 24, m = (v << 8).toSigned(32) >> 8;
      view.setFloat32(i, m * math.pow(2.0, e).toDouble(), Endian.little);
    }
  }
}
