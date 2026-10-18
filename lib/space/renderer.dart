import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'camera.dart';
import 'model.dart';
import 'scene.dart';
import 'style.dart';

export 'scene.dart';

/// Candidate (a) of the P08 spike: projected triangles drawn with one
/// `drawVertices` call, sorted back to front (painter's algorithm). Lines are
/// thin quads in the same sort, so nearer faces hide them; hatching is a
/// line-screen texture whose row is the shade and whose column runs along
/// world height, so the lines read as coursing that follows the building.
///
/// Section cuts (poché) are filled on the plane itself: everything the cut
/// keeps lies beyond the plane, so each cut part's section, outlined by the
/// segments where its triangles cross the plane, is painted after the faces
/// (even-odd, so holes stay open). Drawing the solids' inside faces instead
/// (P08) let them sort over thin solids' own outsides and let parts embedded
/// in one another show through each other's fill.
class SpaceRenderer {
  /// Records pack the part index into 8 bits.
  static const maxParts = 256;
  SpaceRenderer(this.model)
    : assert(model.parts.length <= maxParts),
      _screen = [for (final p in model.parts) Float32List(p.vertexCount * 3)],
      _side = [for (final p in model.parts) Float32List(p.vertexCount)],
      _facing = [for (final p in model.parts) Uint8List(p.triangleCount)],
      _key = [for (final p in model.parts) Float32List(p.triangleCount)],
      _aoMean = [
        for (final p in model.parts)
          Float32List.fromList([
            for (var t = 0; t < p.triangleCount; t++)
              (p.ao[p.triangles[t * 3]] +
                      p.ao[p.triangles[t * 3 + 1]] +
                      p.ao[p.triangles[t * 3 + 2]]) /
                  3,
          ]),
      ];
  final SpaceModel model;
  final List<Float32List> _screen, _side, _key, _aoMean;

  /// Per triangle: 0 removed, 1 front, 2 back of a cut part (it bounds the
  /// section for silhouettes, not drawn), 3 back culled.
  final List<Uint8List> _facing;
  SpaceStats stats = const SpaceStats();

  static const _period = 5.0, _tile = 16.0, _rows = 64;
  static const _edgeBias = .25;
  final _images = <SpaceStyle, ui.Image>{};
  SpaceStyle? _colorsFor;
  List<Int32List> _colors = const [];

  /// Visible work for this frame, one record per triangle, edge or cut line:
  /// kind (2 bits), part (8 bits) and index, with its depth key.
  int _r = 0;
  Int32List _rec = Int32List(0), _bucket = Int32List(0), _order = Int32List(0);
  Float32List _recKey = Float32List(0);
  static const _buckets = 16384, _tri = 0, _edgeLine = 1;
  final _counts = Int32List(_buckets + 1);

  /// Output, written once in depth order.
  int _n = 0;
  Float32List _outPos = Float32List(0), _outTex = Float32List(0);
  Int32List _outCol = Int32List(0);

  /// Per part for this frame.
  late final _alphaOf = Int32List(model.parts.length);
  late final _cutOf = Uint8List(model.parts.length);
  late final _offset = Float64List(model.parts.length * 3);

  /// Section segments for this frame (x0, y0, x1, y1 on screen), part by
  /// part: part i owns [_segFrom[i], _segTo[i]).
  Float32List _seg = Float32List(0);
  int _segN = 0;
  late final _segFrom = Int32List(model.parts.length);
  late final _segTo = Int32List(model.parts.length);
  final _clip = Float64List(4 * 3), _clipScreen = Float32List(4 * 3);
  final _clipColor = Int32List(4), _ids = Int32List(3), _cols = Int32List(3);
  final _shaders = <SpaceStyle, ImageShader>{};
  bool disposed = false;

  void dispose() {
    disposed = true;
    for (final image in _images.values) {
      image.dispose();
    }
    for (final shader in _shaders.values) {
      shader.dispose();
    }
    _images.clear();
    _shaders.clear();
  }

  ui.Image _hatch(SpaceStyle style) =>
      _images.putIfAbsent(style, () => hatchTexture(style, _tile, _rows));

  /// Static per-style colours per triangle corner (the drawing style's
  /// shading lives in the hatch row, recomputed per frame).
  void _shade(SpaceStyle style) {
    if (_colorsFor == style) return;
    _colorsFor = style;
    _colors = [
      for (final part in model.parts) cornerColors(style, part, model.bounds),
    ];
  }

  @pragma('vm:prefer-inline')
  void _record(int kind, int part, int index, double key) {
    if (_r == _rec.length) {
      final n = math.max(1024, _r * 2);
      _rec = Int32List(n)..setAll(0, _rec);
      _recKey = Float32List(n)..setAll(0, _recKey);
    }
    _rec[_r] = index << 10 | part << 2 | kind;
    _recKey[_r] = key;
    _r++;
  }

  @pragma('vm:prefer-inline')
  void _emit(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
    double ua,
    double ub,
    double uc,
    double row,
    int ca,
    int cb,
    int cc,
  ) {
    final o = _n * 6;
    final pos = _outPos, tex = _outTex, col = _outCol;
    pos[o] = ax;
    pos[o + 1] = ay;
    pos[o + 2] = bx;
    pos[o + 3] = by;
    pos[o + 4] = cx;
    pos[o + 5] = cy;
    if (_textured) {
      tex[o] = ua;
      tex[o + 1] = row;
      tex[o + 2] = ub;
      tex[o + 3] = row;
      tex[o + 4] = uc;
      tex[o + 5] = row;
    }
    col[_n * 3] = ca;
    col[_n * 3 + 1] = cb;
    col[_n * 3 + 2] = cc;
    _n++;
  }

  @pragma('vm:prefer-inline')
  void _line(
    double x0,
    double y0,
    double x1,
    double y1,
    double width,
    int color,
  ) {
    final dx = x1 - x0, dy = y1 - y0;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length < .01 || width <= 0) return;
    final h = width / 2, tx = dx / length * h, ty = dy / length * h;
    final ax = x0 - tx - ty, ay = y0 - ty + tx;
    final bx = x1 + tx - ty, by = y1 + ty + tx;
    final cx = x1 + tx + ty, cy = y1 + ty - tx;
    final ex = x0 - tx + ty, ey = y0 - ty - tx;
    _emit(ax, ay, bx, by, cx, cy, 0, 0, 0, .5, color, color, color);
    _emit(ax, ay, cx, cy, ex, ey, 0, 0, 0, .5, color, color, color);
  }

  static int _alpha(int color, int alpha) => alpha == 255
      ? color
      : (color & 0x00FFFFFF) | ((((color >> 24) & 0xFF) * alpha ~/ 255) << 24);

  static int _mix(int a, int b, double t) {
    int lerp(int shift) {
      final x = (a >>> shift) & 0xFF, y = (b >>> shift) & 0xFF;
      return (x + (y - x) * t).round() & 0xFF;
    }

    return lerp(24) << 24 | lerp(16) << 16 | lerp(8) << 8 | lerp(0);
  }

  /// Clips triangle [t] of part [i] to the kept side into [_clip] (world)
  /// and [_clipScreen]; returns the vertex count and stores the two cut
  /// points' indices in [_cutA]/[_cutB] (−1 when the triangle is whole).
  int _clipTriangle(SpaceProjector p, int i, int t, int ca, int cb, int cc) {
    final part = model.parts[i], pos = part.positions, side = _side[i];
    final tris = part.triangles;
    _ids[0] = tris[t * 3];
    _ids[1] = tris[t * 3 + 1];
    _ids[2] = tris[t * 3 + 2];
    _cols[0] = ca;
    _cols[1] = cb;
    _cols[2] = cc;
    final ox = _offset[i * 3], oy = _offset[i * 3 + 1], oz = _offset[i * 3 + 2];
    var m = 0;
    _cutA = _cutB = -1;
    for (var k = 0; k < 3; k++) {
      final v = _ids[k], w = _ids[(k + 1) % 3];
      final sv = side[v], sw = side[w];
      if (sv <= 0) {
        _clip[m * 3] = pos[v * 3] + ox;
        _clip[m * 3 + 1] = pos[v * 3 + 1] + oy;
        _clip[m * 3 + 2] = pos[v * 3 + 2] + oz;
        _clipColor[m] = _cols[k];
        m++;
      }
      if ((sv <= 0) != (sw <= 0)) {
        final f = sv / (sv - sw);
        _clip[m * 3] = pos[v * 3] + (pos[w * 3] - pos[v * 3]) * f + ox;
        _clip[m * 3 + 1] =
            pos[v * 3 + 1] + (pos[w * 3 + 1] - pos[v * 3 + 1]) * f + oy;
        _clip[m * 3 + 2] =
            pos[v * 3 + 2] + (pos[w * 3 + 2] - pos[v * 3 + 2]) * f + oz;
        _clipColor[m] = _mix(_cols[k], _cols[(k + 1) % 3], f);
        if (_cutA < 0) {
          _cutA = m;
        } else {
          _cutB = m;
        }
        m++;
      }
    }
    for (var k = 0; k < m; k++) {
      p.project(
        _clip[k * 3],
        _clip[k * 3 + 1],
        _clip[k * 3 + 2],
        _clipScreen,
        k * 3,
      );
    }
    return m;
  }

  int _cutA = -1, _cutB = -1;

  double _clipU(int k, bool steep, double scale) =>
      (steep ? _clip[k * 3 + 2] : (_clip[k * 3] + _clip[k * 3 + 1]) * .7071) *
      scale;

  /// Paints the scene; returns the projector used (for overlays).
  SpaceProjector paint(Canvas canvas, Size size, SpaceScene scene) {
    final watch = Stopwatch()..start();
    final palette = SpacePalette.of(scene.style);
    final p = SpaceProjector(scene.view, size, model.bounds);
    canvas.drawRect(Offset.zero & size, Paint()..color = palette.ground);
    if (size.isEmpty || disposed) return p;
    _shade(scene.style);
    final drawing = scene.style == SpaceStyle.drawing;
    final section = scene.section;
    final axis = section?.axis ?? 0;
    final toward = axis == 0
        ? -p.fx
        : axis == 1
        ? -p.fy
        : -p.fz;
    final sign = toward >= 0 ? 1.0 : -1.0;
    var faces = 0, pocheCount = 0, edges = 0, cuts = 0;
    _r = 0;
    _segN = 0;
    // Pass 1: project, cull, clip-test and record what is visible.
    for (var i = 0; i < model.parts.length; i++) {
      final state = scene.parts[i];
      _alphaOf[i] = 0;
      _segFrom[i] = _segTo[i] = _segN;
      if (state.progress <= 0) continue;
      final part = model.parts[i];
      _alphaOf[i] = (state.progress.clamp(0.0, 1.0) * 255).round();
      _offset[i * 3] = state.dx;
      _offset[i * 3 + 1] = state.dy;
      _offset[i * 3 + 2] = state.dz;
      final pos = part.positions, scr = _screen[i], side = _side[i];
      final facing = _facing[i], key = _key[i];
      var kept = section == null, removedAny = false;
      for (var v = 0; v < part.vertexCount; v++) {
        final x = pos[v * 3] + state.dx,
            y = pos[v * 3 + 1] + state.dy,
            z = pos[v * 3 + 2] + state.dz;
        p.project(x, y, z, scr, v * 3);
        if (section != null) {
          final s =
              ((axis == 0
                      ? x
                      : axis == 1
                      ? y
                      : z) -
                  section.offset) *
              sign;
          side[v] = s;
          if (s > 0) {
            removedAny = true;
          } else {
            kept = true;
          }
        }
      }
      if (!kept) {
        _alphaOf[i] = 0;
        continue;
      }
      final cut = removedAny;
      _cutOf[i] = cut ? 1 : 0;
      final tris = part.triangles;
      for (var t = 0; t < part.triangleCount; t++) {
        final a = tris[t * 3], b = tris[t * 3 + 1], c = tris[t * 3 + 2];
        final az = scr[a * 3 + 2], bz = scr[b * 3 + 2], cz = scr[c * 3 + 2];
        if (az.isNaN || bz.isNaN || cz.isNaN) {
          facing[t] = 0;
          continue;
        }
        final removed = cut
            ? (side[a] > 0 ? 1 : 0) +
                  (side[b] > 0 ? 1 : 0) +
                  (side[c] > 0 ? 1 : 0)
            : 0;
        if (removed == 3) {
          facing[t] = 0;
          continue;
        }
        final ax = scr[a * 3], ay = scr[a * 3 + 1];
        final front =
            (scr[b * 3] - ax) * (scr[c * 3 + 1] - ay) -
                (scr[b * 3 + 1] - ay) * (scr[c * 3] - ax) <
            0;
        if (!front && !cut) {
          facing[t] = 3;
          continue;
        }
        facing[t] = front ? 1 : 2;
        final depth = (az + bz + cz) / 3;
        key[t] = depth;
        if (front) {
          _record(_tri, i, t, depth);
          faces++;
        }
        if (removed > 0) {
          _segment(p, i, t);
          cuts++;
        }
      }
      _segTo[i] = _segN;
      if (!palette.edges) continue;
      final ev = part.edgeVertices, ef = part.edgeFaces, sharp = part.edgeSharp;
      for (var e = 0; e < sharp.length; e++) {
        final f = ef[e * 2], g = ef[e * 2 + 1];
        final ff = facing[f], fg = g < 0 ? 0 : facing[g];
        final silhouette = (ff == 1 && fg >= 2) || (fg == 1 && ff >= 2);
        if (!silhouette && !(sharp[e] == 1 && (ff == 1 || fg == 1))) continue;
        final v0 = ev[e * 2], v1 = ev[e * 2 + 1];
        if (cut && side[v0] > 0 && side[v1] > 0) continue;
        var depth = (scr[v0 * 3 + 2] + scr[v1 * 3 + 2]) / 2;
        if (ff == 1 && key[f] < depth) depth = key[f];
        if (fg == 1 && key[g] < depth) depth = key[g];
        _record(_edgeLine, i, e, depth - _edgeBias);
        edges++;
      }
    }
    final geometry = watch.elapsedMicroseconds;
    if (_r > 0) {
      _sort();
      final t0 = watch.elapsedMicroseconds;
      _write(p, scene, palette, drawing);
      final t1 = watch.elapsedMicroseconds;
      _draw(canvas, drawing ? _hatchShader(scene.style) : null);
      pocheCount = _sections(canvas, palette);
      _writeMicros = t1 - t0;
      _drawMicros = watch.elapsedMicroseconds - t1;
    }
    stats = SpaceStats(
      faces: faces,
      poche: pocheCount,
      edges: edges,
      cuts: cuts,
      micros: watch.elapsedMicroseconds,
      geometryMicros: geometry,
      sortMicros: _sortMicros,
      writeMicros: _writeMicros,
      drawMicros: _drawMicros,
    );
    return p;
  }

  int _sortMicros = 0, _writeMicros = 0, _drawMicros = 0;

  /// Stores where triangle [t] of part [i] crosses the section plane.
  void _segment(SpaceProjector p, int i, int t) {
    _clipTriangle(p, i, t, 0, 0, 0);
    if (_cutB < 0) return;
    if (_segN * 4 + 4 > _seg.length) {
      _seg = Float32List(math.max(1024, _seg.length * 2))..setAll(0, _seg);
    }
    final a = _cutA * 3, b = _cutB * 3, o = _segN * 4;
    _seg[o] = _clipScreen[a];
    _seg[o + 1] = _clipScreen[a + 1];
    _seg[o + 2] = _clipScreen[b];
    _seg[o + 3] = _clipScreen[b + 1];
    _segN++;
  }

  /// Fills each cut part's section, then outlines all of them; returns the
  /// fan triangles filled. A fan from any point over closed outlines covers
  /// a point once per outline crossing beyond it, so even-odd fills exactly
  /// the section.
  int _sections(Canvas canvas, SpacePalette palette) {
    if (_segN == 0) return 0;
    final poche = palette.poche.toARGB32(), ink = palette.ink.toARGB32();
    final seg = _seg;
    var filled = 0;
    for (var i = 0; i < model.parts.length; i++) {
      final from = _segFrom[i], to = _segTo[i];
      if (to <= from || _alphaOf[i] == 0) continue;
      final ox = seg[from * 4], oy = seg[from * 4 + 1];
      final path = Path()..fillType = PathFillType.evenOdd;
      for (var k = from; k < to; k++) {
        path
          ..moveTo(ox, oy)
          ..lineTo(seg[k * 4], seg[k * 4 + 1])
          ..lineTo(seg[k * 4 + 2], seg[k * 4 + 3])
          ..close();
      }
      filled += to - from;
      canvas.drawPath(path, Paint()..color = Color(_alpha(poche, _alphaOf[i])));
    }
    if (palette.cutWidth <= 0) return filled;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = palette.cutWidth
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < model.parts.length; i++) {
      final from = _segFrom[i], to = _segTo[i];
      if (to <= from || _alphaOf[i] == 0) continue;
      final path = Path();
      for (var k = from; k < to; k++) {
        path
          ..moveTo(seg[k * 4], seg[k * 4 + 1])
          ..lineTo(seg[k * 4 + 2], seg[k * 4 + 3]);
      }
      canvas.drawPath(path, stroke..color = Color(_alpha(ink, _alphaOf[i])));
    }
    return filled;
  }

  /// Only the drawing style samples the hatch texture.
  bool _textured = false;

  /// Counting sort of the records on depth, far to near.
  void _sort() {
    final watch = Stopwatch()..start();
    final n = _r;
    var lo = double.infinity, hi = -double.infinity;
    for (var i = 0; i < n; i++) {
      final d = _recKey[i];
      if (d < lo) lo = d;
      if (d > hi) hi = d;
    }
    final k = hi > lo ? (_buckets - 1) / (hi - lo) : 0.0;
    if (_order.length < n) {
      _order = Int32List(_rec.length);
      _bucket = Int32List(_rec.length);
    }
    final counts = _counts..fillRange(0, _counts.length, 0);
    for (var i = 0; i < n; i++) {
      final b = ((hi - _recKey[i]) * k).toInt();
      _bucket[i] = b;
      counts[b + 1]++;
    }
    for (var j = 1; j < counts.length; j++) {
      counts[j] += counts[j - 1];
    }
    for (var i = 0; i < n; i++) {
      _order[counts[_bucket[i]]++] = i;
    }
    _sortMicros = watch.elapsedMicroseconds;
  }

  /// Pass 2: write each record's triangles straight into the draw buffers,
  /// in depth order (no staging copy).
  void _write(
    SpaceProjector p,
    SpaceScene scene,
    SpacePalette palette,
    bool drawing,
  ) {
    final need = _r * 2;
    if (_outCol.length < need * 3) {
      final n = math.max(need, _outCol.length ~/ 3 * 2);
      _outPos = Float32List(n * 6);
      _outTex = Float32List(n * 6);
      _outCol = Int32List(n * 3);
    }
    _n = 0;
    _textured = drawing;
    // Drawing light: over the viewer's left shoulder, so undersides seen
    // from below still model their curvature.
    var lx = -.42 * p.rx + .5 * p.ux - .76 * p.fx;
    var ly = -.42 * p.ry + .5 * p.uy - .76 * p.fy;
    var lz = -.42 * p.rz + .5 * p.uz - .76 * p.fz;
    final ll = math.sqrt(lx * lx + ly * ly + lz * lz);
    lx /= ll;
    ly /= ll;
    lz /= ll;
    final hatchScale = p.pixelsPerMetre / _period * _tile;
    final ink = palette.ink.toARGB32();
    for (var j = 0; j < _r; j++) {
      final rec = _rec[_order[j]];
      final kind = rec & 3, i = (rec >> 2) & 0xFF, index = rec >> 10;
      final part = model.parts[i], scr = _screen[i], alpha = _alphaOf[i];
      if (kind == _edgeLine) {
        final ev = part.edgeVertices, side = _side[i];
        final v0 = ev[index * 2], v1 = ev[index * 2 + 1];
        var x0 = scr[v0 * 3], y0 = scr[v0 * 3 + 1];
        var x1 = scr[v1 * 3], y1 = scr[v1 * 3 + 1];
        if (_cutOf[i] == 1) {
          final s0 = side[v0], s1 = side[v1];
          if (s0 > 0 || s1 > 0) {
            final keep = s0 > 0 ? v1 : v0, lose = s0 > 0 ? v0 : v1;
            final f = side[keep] / (side[keep] - side[lose]);
            final pos = part.positions;
            p.project(
              pos[keep * 3] +
                  (pos[lose * 3] - pos[keep * 3]) * f +
                  _offset[i * 3],
              pos[keep * 3 + 1] +
                  (pos[lose * 3 + 1] - pos[keep * 3 + 1]) * f +
                  _offset[i * 3 + 1],
              pos[keep * 3 + 2] +
                  (pos[lose * 3 + 2] - pos[keep * 3 + 2]) * f +
                  _offset[i * 3 + 2],
              _clipScreen,
              0,
            );
            if (s0 > 0) {
              x0 = _clipScreen[0];
              y0 = _clipScreen[1];
            } else {
              x1 = _clipScreen[0];
              y1 = _clipScreen[1];
            }
          }
        }
        final f = part.edgeFaces[index * 2], g = part.edgeFaces[index * 2 + 1];
        final facing = _facing[i];
        final ff = facing[f], fg = g < 0 ? 0 : facing[g];
        final silhouette = (ff == 1 && fg >= 2) || (fg == 1 && ff >= 2);
        _line(
          x0,
          y0,
          x1,
          y1,
          silhouette ? palette.silhouetteWidth : palette.edgeWidth,
          _alpha(ink, (alpha * palette.edgeAlpha).round()),
        );
        continue;
      }
      final t = index, tris = part.triangles, colors = _colors[i];
      final a = tris[t * 3], b = tris[t * 3 + 1], c = tris[t * 3 + 2];
      // Only front faces are recorded; cut faces are filled by _sections.
      var row = .5;
      final normals = part.normals;
      final nx = normals[t * 3],
          ny = normals[t * 3 + 1],
          nz = normals[t * 3 + 2];
      final ca = _alpha(colors[t * 3], alpha),
          cb = _alpha(colors[t * 3 + 1], alpha),
          cc = _alpha(colors[t * 3 + 2], alpha);
      if (drawing) {
        final lit = nx * lx + ny * ly + nz * lz;
        final tone =
            (.32 + .68 * (lit > 0 ? lit : 0)) * (.6 + .4 * _aoMean[i][t]);
        final level = (.78 - tone) / .58;
        if (level > .04) row = 1.5 + (level < 1 ? level : 1) * (_rows - 2);
      }
      final steep = nz.abs() < .85;
      final side = _side[i];
      final whole =
          _cutOf[i] == 0 || (side[a] <= 0 && side[b] <= 0 && side[c] <= 0);
      if (whole) {
        var ua = 0.0, ub = 0.0, uc = 0.0;
        if (row > .5) {
          final pos = part.positions;
          if (steep) {
            final oz = _offset[i * 3 + 2];
            ua = (pos[a * 3 + 2] + oz) * hatchScale;
            ub = (pos[b * 3 + 2] + oz) * hatchScale;
            uc = (pos[c * 3 + 2] + oz) * hatchScale;
          } else {
            final o = (_offset[i * 3] + _offset[i * 3 + 1]) * .7071;
            ua = ((pos[a * 3] + pos[a * 3 + 1]) * .7071 + o) * hatchScale;
            ub = ((pos[b * 3] + pos[b * 3 + 1]) * .7071 + o) * hatchScale;
            uc = ((pos[c * 3] + pos[c * 3 + 1]) * .7071 + o) * hatchScale;
          }
        }
        _emit(
          scr[a * 3],
          scr[a * 3 + 1],
          scr[b * 3],
          scr[b * 3 + 1],
          scr[c * 3],
          scr[c * 3 + 1],
          ua,
          ub,
          uc,
          row,
          ca,
          cb,
          cc,
        );
        continue;
      }
      final m = _clipTriangle(p, i, t, ca, cb, cc);
      for (var k = 1; k + 1 < m; k++) {
        _emit(
          _clipScreen[0],
          _clipScreen[1],
          _clipScreen[k * 3],
          _clipScreen[k * 3 + 1],
          _clipScreen[k * 3 + 3],
          _clipScreen[k * 3 + 4],
          _clipU(0, steep, hatchScale),
          _clipU(k, steep, hatchScale),
          _clipU(k + 1, steep, hatchScale),
          row,
          _clipColor[0],
          _clipColor[k],
          _clipColor[k + 1],
        );
      }
    }
  }

  ImageShader _hatchShader(SpaceStyle style) => _shaders.putIfAbsent(
    style,
    () => ImageShader(
      _hatch(style),
      TileMode.repeated,
      TileMode.clamp,
      Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
      filterQuality: FilterQuality.medium,
    ),
  );

  /// One draw call. Modulate: white paint keeps the vertex colours; the
  /// hatch texture multiplies them.
  void _draw(Canvas canvas, ImageShader? hatch) {
    final n = _n;
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      Float32List.sublistView(_outPos, 0, n * 6),
      textureCoordinates: hatch == null
          ? null
          : Float32List.sublistView(_outTex, 0, n * 6),
      colors: Int32List.sublistView(_outCol, 0, n * 3),
    );
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    if (hatch != null) paint.shader = hatch;
    canvas.drawVertices(vertices, BlendMode.modulate, paint);
    vertices.dispose();
  }
}
