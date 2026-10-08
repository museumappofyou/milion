import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Local, mask-authored joints on the photograph's continuous pixel surface.
/// Only sparse figure vertices move. Camera, borders and distant paint stay put.
class FigureRig {
  /// Bilinear resampling preserves normalized displacement while respecting
  /// the plate vertex budget. Used once at load, never in the paint loop.
  factory FigureRig.resample(FigureRig source, int cols, int rows) {
    if (cols < 2 || rows < 2 || cols * rows > 60000 || source.frameCount < 2) {
      throw const FormatException('Invalid resampled rig');
    }
    final sparse = {
      for (var k = 0; k < source.vertices.length; k++) source.vertices[k]: k,
    };
    final vertices = <int>[];
    final weights = <List<(int, double)>>[];
    for (var y = 0; y < rows; y++) {
      final sy = y / (rows - 1) * (source.rows - 1),
          y0 = sy.floor(),
          y1 = sy.ceil();
      for (var x = 0; x < cols; x++) {
        final sx = x / (cols - 1) * (source.cols - 1),
            x0 = sx.floor(),
            x1 = sx.ceil();
        final corners = <int, double>{};
        for (final (index, weight) in [
          (y0 * source.cols + x0, (1 - (sx - x0)) * (1 - (sy - y0))),
          (y0 * source.cols + x1, (sx - x0) * (1 - (sy - y0))),
          (y1 * source.cols + x0, (1 - (sx - x0)) * (sy - y0)),
          (y1 * source.cols + x1, (sx - x0) * (sy - y0)),
        ]) {
          corners[index] = (corners[index] ?? 0) + weight;
        }
        final w = [
          for (final entry in corners.entries)
            if (entry.value > 0 && sparse.containsKey(entry.key))
              (sparse[entry.key]!, entry.value),
        ];
        if (w.isEmpty) continue;
        vertices.add(y * cols + x);
        weights.add(w);
      }
    }
    final data = ByteData(source.frameCount * vertices.length * 2 * 4);
    for (var frame = 0; frame < source.frameCount; frame++) {
      for (var k = 0; k < vertices.length; k++) {
        var dx = 0.0, dy = 0.0;
        for (final (index, weight) in weights[k]) {
          final p = (frame * source.vertices.length + index) * 2;
          dx += source._poses[p] * weight;
          dy += source._poses[p + 1] * weight;
        }
        final p = (frame * vertices.length + k) * 8;
        data.setFloat32(p, dx, Endian.little);
        data.setFloat32(p + 4, dy, Endian.little);
      }
    }
    return FigureRig({
      'cols': cols,
      'rows': rows,
      'vertices': vertices,
      'frames': source.frameCount,
      'gestures': source.gestures,
    }, poseData: data);
  }
  FigureRig(Map<String, dynamic> value, {ByteData? poseData})
    : cols = value['cols'] as int,
      rows = value['rows'] as int,
      vertices = Uint16List.fromList((value['vertices'] as List).cast<int>()),
      offsets = Float32List.fromList(
        ((value['offsets'] as List?) ?? const [])
            .cast<num>()
            .map((v) => v.toDouble())
            .toList(),
      ),
      gestures = (value['gestures'] as List).cast<String>(),
      frameCount = (value['frames'] as int?) ?? 0,
      _poses = _decodePoses(poseData) {
    if (cols < 2 ||
        rows < 2 ||
        cols * rows > 65535 ||
        (frameCount == 0 && offsets.length != vertices.length * 4) ||
        (frameCount > 0 &&
            (frameCount < 2 ||
                _poses.length != frameCount * vertices.length * 2)) ||
        vertices.any((v) => v >= cols * rows)) {
      throw const FormatException('Invalid figure rig');
    }
    coordinates = Float32List(cols * rows * 2);
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final i = (y * cols + x) * 2;
        coordinates[i] = x / (cols - 1);
        coordinates[i + 1] = y / (rows - 1);
      }
    }
    indices = Uint16List((cols - 1) * (rows - 1) * 6);
    var k = 0;
    for (var y = 0; y < rows - 1; y++) {
      for (var x = 0; x < cols - 1; x++) {
        final a = y * cols + x, b = a + 1, c = a + cols, d = c + 1;
        for (final i in [a, b, c, b, d, c]) {
          indices[k++] = i;
        }
      }
    }
  }

  final int cols, rows;
  final Uint16List vertices;
  final Float32List offsets;
  final List<String> gestures;
  final int frameCount;
  final Float32List _poses;
  late final Float32List coordinates;
  late final Uint16List indices;
  final _textureCoordinates = <(int, int), Float32List>{};
  final _shaders = <ui.Image, ui.ImageShader>{};
  bool _disposed = false;
  static final _identity = Float64List.fromList([
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
  ]);

  /// One shader per scene texture, shared across poses and paused repaints.
  ui.ImageShader shaderFor(ui.Image image) {
    if (_disposed) throw StateError('Figure rig has been disposed');
    return _shaders.putIfAbsent(
      image,
      () => ui.ImageShader(
        image,
        ui.TileMode.clamp,
        ui.TileMode.clamp,
        _identity,
        filterQuality: ui.FilterQuality.high,
      ),
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    // This SDK's CanvasKit ImageShader.dispose() also disposes its borrowed
    // Image handle. Explicitly disposing it would invalidate PlateAssets'
    // texture (or double-dispose it when the screen closes). On web, release
    // this bounded cache and let the engine's native finalizer free shaders
    // after their last reference. Never allocate a new shader on each frame.
    // Native Flutter does not consume the borrowed image and can dispose here.
    if (!kIsWeb) {
      for (final shader in _shaders.values) {
        shader.dispose();
      }
    }
    _shaders.clear();
    _textureCoordinates.clear();
  }

  static Float32List _decodePoses(ByteData? data) {
    if (data == null) return Float32List(0);
    if (data.lengthInBytes % 4 != 0) {
      throw const FormatException('Invalid pose data');
    }
    final values = Float32List(data.lengthInBytes ~/ 4);
    for (var i = 0; i < values.length; i++) {
      values[i] = data.getFloat32(i * 4, Endian.little);
    }
    return values;
  }

  Float32List positions(
    double phase,
    ui.Rect frame, {
    double intensity = 1,
    List<ui.Rect> windows = const [],
  }) {
    final points = Float32List(coordinates.length);
    for (var i = 0; i < points.length; i += 2) {
      points[i] = frame.left + coordinates[i] * frame.width;
      points[i + 1] = frame.top + coordinates[i + 1] * frame.height;
    }
    intensity = intensity.clamp(0.0, 1.0);
    double scope(int vertex) {
      if (windows.isEmpty) return 1;
      final p = ui.Offset(coordinates[vertex * 2], coordinates[vertex * 2 + 1]);
      var weight = 0.0;
      for (final w in windows) {
        if (!w.contains(p)) continue;
        final edge = math.min(
          math.min(p.dx - w.left, w.right - p.dx),
          math.min(p.dy - w.top, w.bottom - p.dy),
        );
        weight = math.max(weight, (edge / .018).clamp(0, 1));
      }
      return weight;
    }

    if (frameCount > 0) {
      final cursor = (phase % 1) * frameCount;
      final a = cursor.floor(), b = (a + 1) % frameCount;
      final blend = cursor - a;
      final stride = vertices.length * 2;
      for (var k = 0; k < vertices.length; k++) {
        final i = vertices[k] * 2,
            p = a * stride + k * 2,
            q = b * stride + k * 2;
        final amount = intensity * scope(vertices[k]);
        points[i] +=
            (_poses[p] * (1 - blend) + _poses[q] * blend) *
            frame.width *
            amount;
        points[i + 1] +=
            (_poses[p + 1] * (1 - blend) + _poses[q + 1] * blend) *
            frame.height *
            amount;
      }
      return points;
    }
    final reach = math.sin(phase * math.pi * 2) * intensity;
    final follow = math.sin(phase * math.pi * 4) * intensity;
    for (var k = 0; k < vertices.length; k++) {
      final i = vertices[k] * 2, j = k * 4;
      final weight = scope(vertices[k]);
      points[i] +=
          (offsets[j] * reach + offsets[j + 2] * follow) * frame.width * weight;
      points[i + 1] +=
          (offsets[j + 1] * reach + offsets[j + 3] * follow) *
          frame.height *
          weight;
    }
    return points;
  }

  Float32List textureCoordinates(ui.Image image) =>
      _textureCoordinates.putIfAbsent((image.width, image.height), () {
        final points = Float32List(coordinates.length);
        for (var i = 0; i < points.length; i += 2) {
          points[i] = coordinates[i] * image.width;
          points[i + 1] = coordinates[i + 1] * image.height;
        }
        return points;
      });
}
