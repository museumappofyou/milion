import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart';

import '../design/tokens.dart';
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
  SpaceRenderer(this.model, {this.nightLamps = const []})
    : assert(model.parts.length <= maxParts),
      _edgeBias = (model.bounds.radius * 0.004).clamp(0.012, 0.25),
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
      ],
      _edgeCandidates = [for (final p in model.parts) _candidates(p)];
  final SpaceModel model;
  final List<(double, double, double)> nightLamps;
  final double _edgeBias;
  final List<Float32List> _screen, _side, _key, _aoMean;

  /// Per part, the edges that can ever be drawn: sharp creases, and edges
  /// whose two faces turn (they can be silhouettes). An edge between two
  /// coplanar faces that is not sharp never draws, because both faces always
  /// face the same way; the kit grids every face to `step`, so about half the
  /// edges are such (P12: IX looped over 21,000 edges a frame to draw 3,400).
  final List<Int32List> _edgeCandidates;

  static Int32List _candidates(SpacePart part) {
    final ef = part.edgeFaces, sharp = part.edgeSharp, n = part.normals;
    final out = <int>[];
    for (var e = 0; e < sharp.length; e++) {
      final f = ef[e * 2], g = ef[e * 2 + 1];
      if (sharp[e] == 1) {
        out.add(e);
      } else if (g >= 0 &&
          n[f * 3] * n[g * 3] +
                  n[f * 3 + 1] * n[g * 3 + 1] +
                  n[f * 3 + 2] * n[g * 3 + 2] <
              1 - 1e-6) {
        out.add(e);
      }
    }
    return Int32List.fromList(out);
  }

  /// Per triangle: 0 removed, 1 front, 2 back of a cut part (it bounds the
  /// section for silhouettes, not drawn), 3 back culled.
  final List<Uint8List> _facing;
  SpaceStats stats = const SpaceStats();

  static const _period = 5.0, _tile = 16.0, _rows = 64;
  final _images = <SpaceStyle, ui.Image>{};
  SpaceStyle? _colorsFor;
  List<Int32List> _colors = const [];

  /// Visible work for this frame, one record per triangle, edge or cut line:
  /// kind (2 bits), part (8 bits) and index, with its depth key.
  int _r = 0;
  Int32List _rec = Int32List(0), _bucket = Int32List(0), _order = Int32List(0);
  Float32List _recKey = Float32List(0);
  static const _buckets = 16384, _tri = 0, _edgeLine = 1, _silhouetteLine = 2;
  final _counts = Int32List(_buckets + 1);
  static final _zeros = Int32List(_buckets + 1);

  /// Output: [_n] corners written in record order, part by part, and the
  /// triangles' 16-bit indices in depth order; drawVertices draws triangles
  /// in index order. [_shape] holds each record's first corner and corner
  /// count (start << 3 | count: 0, 3, or 4 for a quad).
  int _n = 0, _indexCount = 0, _flatCount = -1;
  Float32List _outPos = Float32List(0), _outTex = Float32List(0);
  Int32List _outCol = Int32List(0), _shape = Int32List(0);
  Uint16List _outIndex = Uint16List(0);

  /// More corners than this and 16-bit indices cannot reach them; the
  /// corners are then copied out in depth order instead ([_flatten]).
  @visibleForTesting
  static int indexLimit = 0x10000;
  Float32List _flatPos = Float32List(0), _flatTex = Float32List(0);
  Int32List _flatCol = Int32List(0);
  static const _quad = [0, 1, 2, 0, 2, 3];

  /// Per part for this frame.
  late final _alphaOf = Int32List(model.parts.length);
  late final _cutOf = Uint8List(model.parts.length);
  late final _glowOf = Float32List(model.parts.length);
  late final _dustOf = Float32List(model.parts.length);

  /// Part i's records are [_recFrom[i], _recTo[i]): faces, then edges.
  late final _recFrom = Int32List(model.parts.length);
  late final _recTo = Int32List(model.parts.length);

  /// `light` parts (P12): each triangle's place round the part's vertical
  /// axis, 0–1 anticlockwise from +x, so a step's progress sweeps the ring.
  late final List<Float32List?> _sweep = [
    for (final part in model.parts)
      part.material == 'light' ? _azimuths(part) : null,
  ];

  /// Dust seeds per part, made the first time it falls: a vertex of the part
  /// jittered by up to a metre, and a 0–1 draw for how far each speck falls.
  final _dustSeeds = <int, Float32List>{};
  Float32List _pointBuffer = Float32List(0);

  static Float32List _azimuths(SpacePart part) {
    final out = Float32List(part.triangleCount);
    final b = part.bounds, pos = part.positions, tris = part.triangles;
    for (var t = 0; t < part.triangleCount; t++) {
      var x = 0.0, y = 0.0;
      for (var k = 0; k < 3; k++) {
        x += pos[tris[t * 3 + k] * 3];
        y += pos[tris[t * 3 + k] * 3 + 1];
      }
      final a = math.atan2(y / 3 - b.centerY, x / 3 - b.centerX);
      out[t] = (a < 0 ? a + 2 * math.pi : a) / (2 * math.pi);
    }
    return out;
  }

  Float32List _seeds(int i) => _dustSeeds.putIfAbsent(i, () {
    const n = 240;
    final part = model.parts[i], pos = part.positions;
    final random = math.Random(i * 7919 + 17);
    final out = Float32List(n * 4);
    for (var k = 0; k < n; k++) {
      final v = random.nextInt(part.vertexCount);
      out[k * 4] = pos[v * 3] + (random.nextDouble() * 2 - 1);
      out[k * 4 + 1] = pos[v * 3 + 1] + (random.nextDouble() * 2 - 1);
      out[k * 4 + 2] = pos[v * 3 + 2] + (random.nextDouble() * 2 - 1);
      out[k * 4 + 3] = random.nextDouble();
    }
    return out;
  });

  /// What a step just added by hand is tinted towards (P11 device pass).
  static final _gold = Pigment.gold.toARGB32();
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
      for (final part in model.parts)
        cornerColors(style, part, model.bounds, lamps: nightLamps),
    ];
  }

  /// Room for [n] more records.
  void _reserve(int n) {
    if (_r + n <= _rec.length) return;
    final size = math.max(1024, math.max(_r + n, _rec.length * 2));
    _rec = Int32List(size)..setAll(0, Int32List.sublistView(_rec, 0, _r));
    _recKey = Float32List(size)
      ..setAll(0, Float32List.sublistView(_recKey, 0, _r));
  }

  static int _alpha(int color, int alpha) => alpha == 255
      ? color
      : (color & 0x00FFFFFF) | ((((color >> 24) & 0xFF) * alpha ~/ 255) << 24);

  static int _tint(int color, double glow) =>
      glow > 0 ? _mix(color, _gold, glow) : color;

  // No local closure: one was allocated on every mix (P12 profile, 2.4%).
  static int _mix(int a, int b, double t) =>
      _lerp(a, b, 24, t) << 24 |
      _lerp(a, b, 16, t) << 16 |
      _lerp(a, b, 8, t) << 8 |
      _lerp(a, b, 0, t);

  @pragma('vm:prefer-inline')
  static int _lerp(int a, int b, int shift, double t) {
    final x = (a >>> shift) & 0xFF, y = (b >>> shift) & 0xFF;
    return (x + (y - x) * t).round() & 0xFF;
  }

  /// Clips triangle [t] of part [i] to the kept side into [_clip] (world)
  /// and [_clipScreen]; returns the vertex count.
  @pragma('vm:unsafe:no-bounds-checks')
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

  double _clipU(int k, bool steep, double scale) =>
      (steep ? _clip[k * 3 + 2] : (_clip[k * 3] + _clip[k * 3 + 1]) * .7071) *
      scale;

  /// Paints the scene; returns the projector used (for overlays).
  // Typed-array indices here come from validated parts (SpacePart refuses
  // out-of-range triangles), so the checks are dropped (P12: IX on the A52s).
  @pragma('vm:unsafe:no-bounds-checks')
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
    // A vertical cut removes the side toward the camera, so its cut faces
    // the camera from either side. A plan cut (axis 2) keeps what stands
    // above it from every angle: removing the camera's side from above left
    // only the stubs under the plane, the building gone (A52s, 2026-11-09).
    // Its cut faces down, so the poché shows only from below.
    final plan = section != null && axis == 2;
    final sign = plan ? -1.0 : (toward >= 0 ? 1.0 : -1.0);
    final showCut = !plan || toward < 0;
    var faces = 0, pocheCount = 0, edges = 0, cuts = 0;
    final axo = p.axonometric;
    final pcx = p.cx, pcy = p.cy, pScale = p.scale;
    final prx = p.rx, pry = p.ry, prz = p.rz;
    final pux = p.ux, puy = p.uy, puz = p.uz;
    final pfx = p.fx, pfy = p.fy, pfz = p.fz;
    _r = 0;
    _segN = 0;
    // Pass 1: project, cull, clip-test and record what is visible.
    for (var i = 0; i < model.parts.length; i++) {
      final state = scene.parts[i];
      _alphaOf[i] = 0;
      _segFrom[i] = _segTo[i] = _segN;
      _recFrom[i] = _recTo[i] = _r;
      if (state.progress <= 0) continue;
      final part = model.parts[i];
      final sweep = _sweep[i];
      // A light sweeps on at full strength rather than fading in.
      _alphaOf[i] = sweep != null
          ? 255
          : (state.progress.clamp(0.0, 1.0) * 255).round();
      _glowOf[i] = state.highlight.clamp(0.0, 1.0);
      _dustOf[i] = state.dust.clamp(0.0, 1.0);
      _offset[i * 3] = state.dx;
      _offset[i * 3 + 1] = state.dy;
      _offset[i * 3 + 2] = state.dz;
      final pos = part.positions, scr = _screen[i], side = _side[i];
      final facing = _facing[i], key = _key[i];
      var kept = section == null, removedAny = false;
      final count = part.vertexCount;
      final ox = state.dx, oy = state.dy, oz = state.dz;
      if (axo) {
        // SpaceProjector.project, inlined: this loop runs for every vertex.
        final tx = ox - p.targetX, ty = oy - p.targetY, tz = oz - p.targetZ;
        for (var v = 0, o = 0; v < count; v++, o += 3) {
          final dx = pos[o] + tx, dy = pos[o + 1] + ty, dz = pos[o + 2] + tz;
          scr[o] = pcx + pScale * (dx * prx + dy * pry + dz * prz);
          scr[o + 1] = pcy - pScale * (dx * pux + dy * puy + dz * puz);
          scr[o + 2] = dx * pfx + dy * pfy + dz * pfz;
        }
      } else {
        for (var v = 0, o = 0; v < count; v++, o += 3) {
          p.project(pos[o] + ox, pos[o + 1] + oy, pos[o + 2] + oz, scr, o);
        }
      }
      if (section != null) {
        final shift = axis == 0
            ? ox
            : axis == 1
            ? oy
            : oz;
        final plane = section.offset;
        for (var v = 0, o = axis; v < count; v++, o += 3) {
          final s = (pos[o] + shift - plane) * sign;
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
      final tris = part.triangles, triangles = part.triangleCount;
      final candidates = _edgeCandidates[i];
      // Records go through locals: one capacity check per part.
      _reserve(triangles + candidates.length);
      final rec = _rec, recKey = _recKey;
      var r = _r;
      for (var t = 0; t < triangles; t++) {
        final a = tris[t * 3], b = tris[t * 3 + 1], c = tris[t * 3 + 2];
        final az = scr[a * 3 + 2], bz = scr[b * 3 + 2], cz = scr[c * 3 + 2];
        if (!axo && (az.isNaN || bz.isNaN || cz.isNaN)) {
          facing[t] = 0;
          continue;
        }
        final removed = cut
            ? (side[a] > 0 ? 1 : 0) +
                  (side[b] > 0 ? 1 : 0) +
                  (side[c] > 0 ? 1 : 0)
            : 0;
        if (removed == 3 || (sweep != null && sweep[t] > state.progress)) {
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
          rec[r] = t << 10 | i << 2 | _tri;
          recKey[r++] = depth;
          faces++;
        }
        if (removed > 0 && showCut && sweep == null) {
          _segment(p, i, t);
          cuts++;
        }
      }
      _segTo[i] = _segN;
      _recTo[i] = _r = r;
      if (!palette.edges || sweep != null) continue;
      final ev = part.edgeVertices, ef = part.edgeFaces, sharp = part.edgeSharp;
      for (var c = 0; c < candidates.length; c++) {
        final e = candidates[c];
        final f = ef[e * 2], g = ef[e * 2 + 1];
        final ff = facing[f], fg = g < 0 ? 0 : facing[g];
        final silhouette = (ff == 1 && fg >= 2) || (fg == 1 && ff >= 2);
        if (!silhouette && !(sharp[e] == 1 && (ff == 1 || fg == 1))) continue;
        final v0 = ev[e * 2], v1 = ev[e * 2 + 1];
        if (cut && side[v0] > 0 && side[v1] > 0) continue;
        var depth = (scr[v0 * 3 + 2] + scr[v1 * 3 + 2]) / 2;
        if (ff == 1 && key[f] < depth) depth = key[f];
        if (fg == 1 && key[g] < depth) depth = key[g];
        rec[r] = e << 10 | i << 2 | (silhouette ? _silhouetteLine : _edgeLine);
        recKey[r++] = depth - _edgeBias;
        edges++;
      }
      _recTo[i] = _r = r;
    }
    final geometry = watch.elapsedMicroseconds;
    if (_r > 0) {
      _sort();
      final t0 = watch.elapsedMicroseconds;
      _write(p, scene, palette, drawing);
      final t1 = watch.elapsedMicroseconds;
      _draw(canvas, drawing ? _hatchShader(scene.style) : null);
      pocheCount = _sections(canvas, palette);
      _dust(canvas, p, palette);
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

  /// Specks of dust round each falling part, drifting down further than the
  /// part itself and spreading a little as they settle (Milestone IX).
  void _dust(Canvas canvas, SpaceProjector p, SpacePalette palette) {
    for (var i = 0; i < model.parts.length; i++) {
      final dust = _dustOf[i];
      if (dust <= 0 || _alphaOf[i] == 0) continue;
      final seeds = _seeds(i), n = seeds.length ~/ 4;
      if (_pointBuffer.length < n * 3) _pointBuffer = Float32List(n * 3);
      final out = Float32List(n * 2);
      final b = model.parts[i].bounds;
      final fall = -_offset[i * 3 + 2];
      for (var k = 0; k < n; k++) {
        final r = seeds[k * 4 + 3];
        final x = seeds[k * 4], y = seeds[k * 4 + 1];
        final spread = 1 + fall * .03 * r;
        p.project(
          b.centerX + (x - b.centerX) * spread + _offset[i * 3],
          b.centerY + (y - b.centerY) * spread + _offset[i * 3 + 1],
          seeds[k * 4 + 2] - fall * (.6 + 1.2 * r),
          _pointBuffer,
          k * 3,
        );
        out[k * 2] = _pointBuffer[k * 3];
        out[k * 2 + 1] = _pointBuffer[k * 3 + 1];
      }
      final color = palette.edges ? palette.ink : palette.hatch;
      canvas.drawRawPoints(
        ui.PointMode.points,
        out,
        Paint()
          ..color = color.withValues(alpha: .5 * dust)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Stores where triangle [t] of part [i] crosses the section plane,
  /// oriented from entry (`sv > 0 → sw <= 0`) to exit (`sv <= 0 → sw > 0`).
  /// Because every solid has outward CCW winding, all outer section loops run
  /// consistently in one direction while interior cavities run opposite, so
  /// [PathFillType.nonZero] fills overlapping solids solidly while keeping
  /// true rooms and window shafts open.
  @pragma('vm:unsafe:no-bounds-checks')
  void _segment(SpaceProjector p, int i, int t) {
    final part = model.parts[i], pos = part.positions, side = _side[i];
    final tris = part.triangles;
    final ox = _offset[i * 3], oy = _offset[i * 3 + 1], oz = _offset[i * 3 + 2];
    var hasIn = false, hasOut = false;
    for (var k = 0; k < 3; k++) {
      final v = tris[t * 3 + k], w = tris[t * 3 + (k + 1) % 3];
      final sv = side[v], sw = side[w];
      if ((sv <= 0) == (sw <= 0)) continue;
      final f = sv / (sv - sw);
      final slot = sv > 0
          ? 0
          : 1; // 0: removed→kept (in), 1: kept→removed (out)
      p.project(
        pos[v * 3] + (pos[w * 3] - pos[v * 3]) * f + ox,
        pos[v * 3 + 1] + (pos[w * 3 + 1] - pos[v * 3 + 1]) * f + oy,
        pos[v * 3 + 2] + (pos[w * 3 + 2] - pos[v * 3 + 2]) * f + oz,
        _clipScreen,
        slot * 3,
      );
      if (slot == 0) {
        hasIn = true;
      } else {
        hasOut = true;
      }
      if (hasIn && hasOut) break;
    }
    if (!hasIn || !hasOut) return;
    if (_segN * 4 + 4 > _seg.length) {
      _seg = Float32List(math.max(1024, _seg.length * 2))..setAll(0, _seg);
    }
    final o = _segN * 4;
    _seg[o] = _clipScreen[0];
    _seg[o + 1] = _clipScreen[1];
    _seg[o + 2] = _clipScreen[3];
    _seg[o + 3] = _clipScreen[4];
    _segN++;
  }

  /// Fills each cut part's section, then outlines all of them; returns the
  /// fan triangles filled. Every segment is oriented consistently from the
  /// solid's outward winding, so [PathFillType.nonZero] fills overlapping
  /// intra-part solids cleanly while leaving true hollow cavities open.
  int _sections(Canvas canvas, SpacePalette palette) {
    if (_segN == 0) return 0;
    final poche = palette.poche.toARGB32(), ink = palette.ink.toARGB32();
    final seg = _seg;
    var filled = 0;
    for (var i = 0; i < model.parts.length; i++) {
      final from = _segFrom[i], to = _segTo[i];
      if (to <= from || _alphaOf[i] == 0) continue;
      final o = Offset(seg[from * 4], seg[from * 4 + 1]);
      final points = List<Offset>.filled((to - from) * 3, o);
      for (var k = from, j = 0; k < to; k++, j += 3) {
        points[j + 1] = Offset(seg[k * 4], seg[k * 4 + 1]);
        points[j + 2] = Offset(seg[k * 4 + 2], seg[k * 4 + 3]);
      }
      final path = Path()
        ..fillType = PathFillType.nonZero
        ..addPolygon(points, true);
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

  /// Counting sort of the records on depth, far to near.
  @pragma('vm:unsafe:no-bounds-checks')
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
    // A copy of zeros is a memmove; fillRange wrote 16,385 ints one by one.
    final counts = _counts..setAll(0, _zeros);
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

  /// Pass 2: write the corners part by part, in record order, then the
  /// triangles' indices in depth order. Walking the records in depth order
  /// read each face's part data again on every face, and a line took 6
  /// corners where a quad needs 4 (P12: IX on the A52s).
  @pragma('vm:unsafe:no-bounds-checks')
  void _write(
    SpaceProjector p,
    SpaceScene scene,
    SpacePalette palette,
    bool drawing,
  ) {
    final r = _r;
    if (_outCol.length < r * 4) {
      final n = math.max(r * 4, _outCol.length * 2);
      _outPos = Float32List(n * 2);
      _outTex = Float32List(n * 2);
      _outCol = Int32List(n);
    }
    if (_shape.length < r) _shape = Int32List(math.max(r, _shape.length * 2));
    final out = _outPos, tex = _outTex, col = _outCol, shape = _shape;
    var n = 0;
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
    final silhouetteWidth = palette.silhouetteWidth;
    final edgeWidth = palette.edgeWidth;
    final records = _rec;
    // Part by part: what belongs to the part is read once, not per face.
    for (var i = 0; i < model.parts.length; i++) {
      final from = _recFrom[i], to = _recTo[i];
      if (from == to) continue;
      final part = model.parts[i], scr = _screen[i], side = _side[i];
      final alpha = _alphaOf[i], glowOf = _glowOf[i], cut = _cutOf[i] == 1;
      final tris = part.triangles, normals = part.normals;
      final pos = part.positions, ev = part.edgeVertices;
      final colors = _colors[i], ao = _aoMean[i];
      final ox = _offset[i * 3],
          oy = _offset[i * 3 + 1],
          oz = _offset[i * 3 + 2];
      final oxy = (ox + oy) * .7071;
      final glow = glowOf * .6;
      final plain = glow <= 0 && alpha == 255;
      final shaded = drawing && _sweep[i] == null;
      final lineColor = _alpha(
        glowOf > 0 ? _mix(ink, _gold, glowOf * .8) : ink,
        (alpha * palette.edgeAlpha).round(),
      );
      for (var j = from; j < to; j++) {
        final rec = records[j];
        final kind = rec & 3, index = rec >> 10;
        final start = n;
        if (kind != _tri) {
          final v0 = ev[index * 2], v1 = ev[index * 2 + 1];
          var x0 = scr[v0 * 3], y0 = scr[v0 * 3 + 1];
          var x1 = scr[v1 * 3], y1 = scr[v1 * 3 + 1];
          if (cut) {
            final s0 = side[v0], s1 = side[v1];
            if (s0 > 0 || s1 > 0) {
              final keep = s0 > 0 ? v1 : v0, lose = s0 > 0 ? v0 : v1;
              final f = side[keep] / (side[keep] - side[lose]);
              p.project(
                pos[keep * 3] + (pos[lose * 3] - pos[keep * 3]) * f + ox,
                pos[keep * 3 + 1] +
                    (pos[lose * 3 + 1] - pos[keep * 3 + 1]) * f +
                    oy,
                pos[keep * 3 + 2] +
                    (pos[lose * 3 + 2] - pos[keep * 3 + 2]) * f +
                    oz,
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
          // A line as a quad of 4 corners, drawn as triangles 0-1-2 and
          // 0-2-3.
          final width = kind == _silhouetteLine ? silhouetteWidth : edgeWidth;
          final dx = x1 - x0, dy = y1 - y0;
          final length = math.sqrt(dx * dx + dy * dy);
          if (length >= .01 && width > 0) {
            final h = width / 2, tx = dx / length * h, ty = dy / length * h;
            final o = n * 2;
            out[o] = x0 - tx - ty;
            out[o + 1] = y0 - ty + tx;
            out[o + 2] = x1 + tx - ty;
            out[o + 3] = y1 + ty + tx;
            out[o + 4] = x1 + tx + ty;
            out[o + 5] = y1 + ty - tx;
            out[o + 6] = x0 - tx + ty;
            out[o + 7] = y0 - ty - tx;
            if (drawing) {
              for (var k = 0; k < 8; k += 2) {
                tex[o + k] = 0;
                tex[o + k + 1] = .5;
              }
            }
            col[n] = lineColor;
            col[n + 1] = lineColor;
            col[n + 2] = lineColor;
            col[n + 3] = lineColor;
            n += 4;
          }
          shape[j] = start << 3 | (n - start);
          continue;
        }
        final t = index;
        final a = tris[t * 3], b = tris[t * 3 + 1], c = tris[t * 3 + 2];
        // Only front faces are recorded; cut faces are filled by _sections.
        var row = .5;
        final nz = normals[t * 3 + 2];
        final ca = plain
                ? colors[t * 3]
                : _alpha(_tint(colors[t * 3], glow), alpha),
            cb = plain
                ? colors[t * 3 + 1]
                : _alpha(_tint(colors[t * 3 + 1], glow), alpha),
            cc = plain
                ? colors[t * 3 + 2]
                : _alpha(_tint(colors[t * 3 + 2], glow), alpha);
        if (shaded) {
          final lit = normals[t * 3] * lx + normals[t * 3 + 1] * ly + nz * lz;
          final tone = (.32 + .68 * (lit > 0 ? lit : 0)) * (.6 + .4 * ao[t]);
          final level = (.78 - tone) / .58;
          if (level > .04) row = 1.5 + (level < 1 ? level : 1) * (_rows - 2);
        }
        final steep = nz.abs() < .97;
        if (!cut || (side[a] <= 0 && side[b] <= 0 && side[c] <= 0)) {
          final o = n * 2;
          out[o] = scr[a * 3];
          out[o + 1] = scr[a * 3 + 1];
          out[o + 2] = scr[b * 3];
          out[o + 3] = scr[b * 3 + 1];
          out[o + 4] = scr[c * 3];
          out[o + 5] = scr[c * 3 + 1];
          if (drawing) {
            var ua = 0.0, ub = 0.0, uc = 0.0;
            if (row > .5) {
              if (steep) {
                ua = (pos[a * 3 + 2] + oz) * hatchScale;
                ub = (pos[b * 3 + 2] + oz) * hatchScale;
                uc = (pos[c * 3 + 2] + oz) * hatchScale;
              } else {
                ua = ((pos[a * 3] + pos[a * 3 + 1]) * .7071 + oxy) * hatchScale;
                ub = ((pos[b * 3] + pos[b * 3 + 1]) * .7071 + oxy) * hatchScale;
                uc = ((pos[c * 3] + pos[c * 3 + 1]) * .7071 + oxy) * hatchScale;
              }
            }
            tex[o] = ua;
            tex[o + 1] = row;
            tex[o + 2] = ub;
            tex[o + 3] = row;
            tex[o + 4] = uc;
            tex[o + 5] = row;
          }
          col[n] = ca;
          col[n + 1] = cb;
          col[n + 2] = cc;
          n += 3;
        } else {
          // The kept side of a cut triangle: 3 corners, or a quad of 4.
          final m = _clipTriangle(p, i, t, ca, cb, cc);
          if (m >= 3) {
            for (var k = 0; k < m; k++) {
              final o = (n + k) * 2;
              out[o] = _clipScreen[k * 3];
              out[o + 1] = _clipScreen[k * 3 + 1];
              if (drawing) {
                tex[o] = _clipU(k, steep, hatchScale);
                tex[o + 1] = row;
              }
              col[n + k] = _clipColor[k];
            }
            n += m;
          }
        }
        shape[j] = start << 3 | (n - start);
      }
    }
    _n = n;
    if (n > indexLimit) {
      _flatten(drawing);
      return;
    }
    _flatCount = -1;
    if (_outIndex.length < r * 6) {
      _outIndex = Uint16List(math.max(r * 6, _outIndex.length * 2));
    }
    final index = _outIndex, order = _order;
    var k = 0;
    for (var j = 0; j < r; j++) {
      final s = shape[order[j]], v = s >> 3, count = s & 7;
      if (count < 3) continue;
      index[k] = v;
      index[k + 1] = v + 1;
      index[k + 2] = v + 2;
      if (count == 4) {
        index[k + 3] = v;
        index[k + 4] = v + 2;
        index[k + 5] = v + 3;
        k += 6;
      } else {
        k += 3;
      }
    }
    _indexCount = k;
  }

  /// Copies the corners out in depth order, three per triangle, for a frame
  /// with more corners than 16-bit indices reach.
  @pragma('vm:unsafe:no-bounds-checks')
  void _flatten(bool drawing) {
    final r = _r, shape = _shape, order = _order;
    if (_flatCol.length < r * 6) {
      final n = math.max(r * 6, _flatCol.length * 2);
      _flatPos = Float32List(n * 2);
      _flatTex = Float32List(n * 2);
      _flatCol = Int32List(n);
    }
    final pos = _outPos, tex = _outTex, col = _outCol;
    final flatPos = _flatPos, flatTex = _flatTex, flatCol = _flatCol;
    var k = 0;
    for (var j = 0; j < r; j++) {
      final s = shape[order[j]], v = s >> 3, count = s & 7;
      if (count < 3) continue;
      for (var q = 0, end = count == 4 ? 6 : 3; q < end; q++, k++) {
        final w = v + _quad[q];
        flatPos[k * 2] = pos[w * 2];
        flatPos[k * 2 + 1] = pos[w * 2 + 1];
        if (drawing) {
          flatTex[k * 2] = tex[w * 2];
          flatTex[k * 2 + 1] = tex[w * 2 + 1];
        }
        flatCol[k] = col[w];
      }
    }
    _flatCount = k;
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
    final flat = _flatCount >= 0, n = flat ? _flatCount : _n;
    final pos = flat ? _flatPos : _outPos, tex = flat ? _flatTex : _outTex;
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      Float32List.sublistView(pos, 0, n * 2),
      textureCoordinates: hatch == null
          ? null
          : Float32List.sublistView(tex, 0, n * 2),
      colors: Int32List.sublistView(flat ? _flatCol : _outCol, 0, n),
      indices: flat ? null : Uint16List.sublistView(_outIndex, 0, _indexCount),
    );
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    if (hatch != null) paint.shader = hatch;
    canvas.drawVertices(vertices, BlendMode.modulate, paint);
    vertices.dispose();
  }
}
