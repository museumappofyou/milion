// Offline software renderer for the Anastasis conch reconstruction.
//
// It uses exactly the same geometry as the app (lib/services/conch_geometry.dart)
// but rasterizes with the `image` package so the reconstruction can be checked
// without a device: the default view must reproduce the reference photograph,
// and orbiting the viewpoint must reveal the parallax of the bowl.
//
// This file is a tool, not part of the app's test suite: plain `flutter test`
// does not pick it up because it lives outside test/. Run it explicitly:
//
//   flutter test tool/render_anastasis_preview_test.dart
//
// It writes default.png, yaw.png, pitch.png, curvature.png and grid.png into
// build/anastasis-preview.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:milion/models/anastasis_capture.dart';
import 'package:milion/services/conch_geometry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const String texturePath = 'assets/anastasis/conch_reference.jpg';
const String outPath = 'build/anastasis-preview';

void main() {
  test('renders the conch reconstruction previews', () {
    final outDir = Directory(outPath)..createSync(recursive: true);

    final texture = img.decodeImage(File(texturePath).readAsBytesSync())!;
    final textureSize = Size(
      texture.width.toDouble(),
      texture.height.toDouble(),
    );

    const params = ConchParams();
    final renderer = ConchRenderer(params: params, textureSize: textureSize);
    stdout.writeln(
      'calibrated capture half-FOV: '
      '${renderer.surface.captureHalfFovDeg.toStringAsFixed(1)}°',
    );
    stdout.writeln(
      'triangles: ${renderer.triangleCount}, '
      'grid: ${renderer.columns}x${renderer.rows}',
    );

    _render(
      renderer,
      texture,
      const Size(1100, 660),
      File('${outDir.path}/default.png'),
      yaw: 0,
      pitch: 0,
      drawGrid: false,
    );
    _render(
      renderer,
      texture,
      const Size(1100, 660),
      File('${outDir.path}/yaw.png'),
      yaw: 0.28,
      pitch: 0,
      drawGrid: false,
    );
    _render(
      renderer,
      texture,
      const Size(1100, 660),
      File('${outDir.path}/pitch.png'),
      yaw: 0,
      pitch: -0.22,
      drawGrid: false,
    );
    _render(
      ConchRenderer(
        params: params.copyWith(radius: 0.5),
        textureSize: textureSize,
      ),
      texture,
      const Size(1100, 660),
      File('${outDir.path}/curvature-tight.png'),
      yaw: 0,
      pitch: 0,
      drawGrid: false,
    );
    _render(
      ConchRenderer(
        params: params.copyWith(radius: 1.9),
        textureSize: textureSize,
      ),
      texture,
      const Size(1100, 660),
      File('${outDir.path}/curvature-flat.png'),
      yaw: 0,
      pitch: 0,
      drawGrid: false,
    );
    _render(
      renderer,
      texture,
      const Size(1400, 840),
      File('${outDir.path}/grid.png'),
      yaw: 0,
      pitch: 0,
      drawGrid: true,
    );

    // Hotspot anchors: draw them where the app would, to verify that they
    // land on the right figures.
    _render(
      renderer,
      texture,
      const Size(1100, 660),
      File('${outDir.path}/markers.png'),
      yaw: 0,
      pitch: 0,
      drawGrid: false,
      markers: anastasisHotspots,
    );

    // The in-situ photograph for curvature comparison.
    final inSitu = img.decodeImage(
      File('assets/anastasis/apse_context_2014.jpg').readAsBytesSync(),
    )!;
    File('${outDir.path}/in_situ.png')
        .writeAsBytesSync(img.encodePng(img.copyResize(inSitu, width: 1100)));

    // The source capture with the same 10% grid, for tracing the painted
    // field's outline in normalized photograph coordinates.
    final sourceGrid = img.copyResize(
      texture,
      width: 1400,
      interpolation: img.Interpolation.linear,
    );
    _drawGrid(
      sourceGrid,
      Size(sourceGrid.width.toDouble(), sourceGrid.height.toDouble()),
    );
    File('${outDir.path}/source_grid.png')
        .writeAsBytesSync(img.encodePng(sourceGrid));
    stdout.writeln('${outDir.path}/source_grid.png: source with 10% grid');
  });
}

void _render(
  ConchRenderer renderer,
  img.Image texture,
  Size size,
  File output, {
  required double yaw,
  required double pitch,
  required bool drawGrid,
  List<AnastasisHotspot> markers = const [],
}) {
  final w = size.width.toInt();
  final h = size.height.toInt();
  final color = img.Image(width: w, height: h);
  img.fill(color, color: img.ColorRgb8(14, 13, 16));

  final mesh = renderer.build(
    viewSize: size,
    yaw: yaw,
    pitch: pitch,
    anchors: [
      for (final marker in markers) ConchAnchor(marker.id, marker.u, marker.v),
    ],
  );
  final depth = Float64ListBuffer(w * h);

  for (var t = 0; t < mesh.indices.length; t += 3) {
    final ia = mesh.indices[t];
    final ib = mesh.indices[t + 1];
    final ic = mesh.indices[t + 2];
    final ax = mesh.positions[ia * 2], ay = mesh.positions[ia * 2 + 1];
    final bx = mesh.positions[ib * 2], by = mesh.positions[ib * 2 + 1];
    final cx = mesh.positions[ic * 2], cy = mesh.positions[ic * 2 + 1];
    if (ax.isNaN || bx.isNaN || cx.isNaN) {
      continue;
    }
    final minX = [ax, bx, cx].reduce(math.min).floor().clamp(0, w - 1);
    final maxX = [ax, bx, cx].reduce(math.max).ceil().clamp(0, w - 1);
    final minY = [ay, by, cy].reduce(math.min).floor().clamp(0, h - 1);
    final maxY = [ay, by, cy].reduce(math.max).ceil().clamp(0, h - 1);
    if (maxX <= minX || maxY <= minY) {
      continue;
    }
    final area = (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
    if (area.abs() < 1e-6) {
      continue;
    }
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final px = x + 0.5;
        final py = y + 0.5;
        final w0 = ((bx - ax) * (py - ay) - (by - ay) * (px - ax)) / area;
        final w1 = ((px - ax) * (cy - ay) - (py - ay) * (cx - ax)) / area;
        final w2 = 1 - w0 - w1;
        if (w0 < 0 || w1 < 0 || w2 < 0) {
          continue;
        }
        // Barycentric: a -> w2, b -> w0, c -> w1 for this ordering.
        final u =
            w2 * mesh.texCoords[ia * 2] +
            w0 * mesh.texCoords[ib * 2] +
            w1 * mesh.texCoords[ic * 2];
        final v =
            w2 * mesh.texCoords[ia * 2 + 1] +
            w0 * mesh.texCoords[ib * 2 + 1] +
            w1 * mesh.texCoords[ic * 2 + 1];
        final shade =
            (w2 * ((mesh.colors[ia] >> 16) & 0xFF) +
                w0 * ((mesh.colors[ib] >> 16) & 0xFF) +
                w1 * ((mesh.colors[ic] >> 16) & 0xFF)) /
            255.0;
        final tx = u.round().clamp(0, texture.width - 1);
        final ty = v.round().clamp(0, texture.height - 1);
        final texel = texture.getPixel(tx, ty);
        final index = y * w + x;
        if (depth.get(index) > 0) {
          continue;
        }
        depth.set(index, 1);
        color.setPixelRgb(
          x,
          y,
          (texel.r * shade).clamp(0, 255).toInt(),
          (texel.g * shade).clamp(0, 255).toInt(),
          (texel.b * shade).clamp(0, 255).toInt(),
        );
      }
    }
  }

  if (drawGrid) {
    _drawGrid(color, size);
  }
  for (final marker in markers) {
    final anchor = mesh.anchors[marker.id];
    if (anchor == null) {
      continue;
    }
    _circle(
      color,
      anchor.dx.round(),
      anchor.dy.round(),
      5,
      img.ColorRgb8(255, 210, 90),
    );
    stdout.writeln(
      '  marker ${marker.id}: (${anchor.dx.toStringAsFixed(0)}, '
      '${anchor.dy.toStringAsFixed(0)})',
    );
  }
  File(output.path).writeAsBytesSync(img.encodePng(color));
  stdout.writeln(
    '${output.path}: ${mesh.visibleVertices}/${mesh.vertexCount} vertices, '
    'bounds ${mesh.bounds?.toString() ?? 'none'}',
  );
}

void _circle(img.Image image, int cx, int cy, int radius, img.Color color) {
  for (var y = cy - radius; y <= cy + radius; y++) {
    for (var x = cx - radius; x <= cx + radius; x++) {
      if (x < 0 || y < 0 || x >= image.width || y >= image.height) {
        continue;
      }
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= radius * radius) {
        image.setPixelRgb(
          x,
          y,
          color.r.toInt(),
          color.g.toInt(),
          color.b.toInt(),
        );
      }
    }
  }
}

void _drawGrid(img.Image image, Size size) {
  final minor = img.ColorRgb8(255, 210, 90);
  final axis = img.ColorRgb8(120, 220, 255);
  for (var i = 1; i < 10; i++) {
    final u = i / 10;
    final x = (u * size.width).round();
    final y = (u * size.height).round();
    final color = i == 5 ? axis : minor;
    for (var yy = 0; yy < image.height; yy++) {
      if (yy % 6 < 3) {
        image.setPixelRgb(
          x,
          yy,
          color.r.toInt(),
          color.g.toInt(),
          color.b.toInt(),
        );
      }
    }
    for (var xx = 0; xx < image.width; xx++) {
      if (xx % 6 < 3) {
        image.setPixelRgb(
          xx,
          y,
          color.r.toInt(),
          color.g.toInt(),
          color.b.toInt(),
        );
      }
    }
  }
}

/// Minimal growable double buffer to avoid dart:typed_data noise above.
class Float64ListBuffer {
  Float64ListBuffer(this.length) : _data = List<double>.filled(length, 0);

  final int length;
  final List<double> _data;

  double get(int index) => _data[index];
  void set(int index, double value) => _data[index] = value;
}
