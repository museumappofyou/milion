import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;

import 'conch_geometry.dart';

class ReliefLayer {
  ReliefLayer({
    required this.id,
    required this.kind,
    required this.depth,
    required this.relief,
    required this.crop,
    required this.color,
    required this.texture,
    required this.litTexture,
    required this.shadowTexture,
    required this.normalTexture,
    required this.aoTexture,
    required this.aoOverlay,
    required this.heightViz,
    required this.combinedViz,
    required this.edge,
    required this.heights,
    required this.normalData,
  });
  final String id;
  final String kind;
  final double depth;
  final double relief;
  final ui.Rect crop;
  final ui.Color color;
  final ui.Image texture;
  final ui.Image litTexture;
  final ui.Image shadowTexture;
  final ui.Image normalTexture;
  final ui.Image aoTexture;
  final ui.Image aoOverlay;
  final ui.Image heightViz;
  final ui.Image combinedViz;
  final ui.Image edge;
  final img.Image heights;
  final img.Image normalData;

  double heightAt(double x, double y) {
    final xx = x.floor().clamp(0, heights.width - 1);
    final yy = y.floor().clamp(0, heights.height - 1);
    return heights.getPixel(xx, yy).r / 255.0;
  }

  (double, double, double) normalAt(double x, double y) {
    final xx = x.floor().clamp(0, normalData.width - 1);
    final yy = y.floor().clamp(0, normalData.height - 1);
    final pixel = normalData.getPixel(xx, yy);
    return (pixel.r / 127.5 - 1, pixel.g / 127.5 - 1, pixel.b / 127.5 - 1);
  }
}

class AnastasisReliefAssets {
  final List<ReliefLayer> layers = [];
  static const manifestPath = 'assets/anastasis/relief_v3/manifest.json';

  Future<void> load() async {
    final manifest = jsonDecode(
      await rootBundle.loadString(manifestPath),
    ) as Map<String, dynamic>;
    for (final raw in manifest['layers'] as List) {
      final item = raw as Map<String, dynamic>;
      final rect = (item['crop'] as List).cast<num>();
      final texture = await _decode(item['texture'] as String);
      final litTexture = await _decode(item['litTexture'] as String);
      final shadowTexture = await _decode(item['contactShadow'] as String);
      final normalTexture = await _decode(item['normal'] as String);
      final aoTexture = await _decode(item['ao'] as String);
      final aoOverlay = await _decode(item['aoOverlay'] as String);
      final heightViz = await _decode(item['heightViz'] as String);
      final combinedViz = await _decode(item['combinedViz'] as String);
      final edge = await _decode(item['edge'] as String);
      final bytes = await rootBundle.load(item['height'] as String);
      final heights = img.decodePng(bytes.buffer.asUint8List())!;
      final normalBytes = await rootBundle.load(item['normal'] as String);
      final normalData = img.decodePng(normalBytes.buffer.asUint8List())!;
      final hex = (item['color'] as String).substring(1);
      layers.add(
        ReliefLayer(
          id: item['id'] as String,
          kind: item['kind'] as String,
          depth: (item['depth'] as num).toDouble(),
          relief: (item['reliefStrength'] as num).toDouble(),
          crop: ui.Rect.fromLTWH(
            rect[0].toDouble(),
            rect[1].toDouble(),
            rect[2].toDouble(),
            rect[3].toDouble(),
          ),
          color: ui.Color(int.parse('FF$hex', radix: 16)),
          texture: texture,
          litTexture: litTexture,
          shadowTexture: shadowTexture,
          normalTexture: normalTexture,
          aoTexture: aoTexture,
          aoOverlay: aoOverlay,
          heightViz: heightViz,
          combinedViz: combinedViz,
          edge: edge,
          heights: heights,
          normalData: normalData,
        ),
      );
    }
  }

  Future<ui.Image> _decode(String path) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  void dispose() {
    for (final layer in layers) {
      layer.texture.dispose();
      layer.litTexture.dispose();
      layer.shadowTexture.dispose();
      layer.normalTexture.dispose();
      layer.aoTexture.dispose();
      layer.aoOverlay.dispose();
      layer.heightViz.dispose();
      layer.combinedViz.dispose();
      layer.edge.dispose();
    }
    layers.clear();
  }
}

class ReliefControls {
  const ReliefControls({
    this.preset = 'BALANCED',
    this.depthScale = .65,
    this.reliefScale = 1,
    this.parallax = 1,
    this.maxYaw = .08726646,
    this.maxPitch = .05235988,
    this.light = 1,
    this.saturation = 1,
    this.contrast = 1,
    this.brightness = 0,
    this.feather = 1,
    this.mode = 'relief',
    this.solo = '',
    this.depths = const {},
    this.reliefs = const {},
    this.opacities = const {},
    this.visibility = const {},
    this.projection = 'photo',
    this.christContrast = 1,
    this.christSaturation = 1,
    this.christBrightness = 0,
    this.christEdgeSeparation = 1,
    this.lightAngle = -20,
    this.lightIntensity = 1,
    this.ambientIntensity = 1,
    this.aoIntensity = 1,
    this.contactShadow = 1,
    this.bevel = 1,
    this.fov = 1,
    this.meshQuality = 1,
    this.textureQuality = 1,
    this.lightInspection = false,
  });
  final String preset;
  final double depthScale, reliefScale, parallax, maxYaw, maxPitch, light;
  final double saturation, contrast, brightness, feather;
  final String mode, solo;
  final Map<String, double> depths, reliefs, opacities;
  final Map<String, bool> visibility;
  final String projection;
  final double christContrast,
      christSaturation,
      christBrightness,
      christEdgeSeparation;
  final double lightAngle, lightIntensity, ambientIntensity, aoIntensity;
  final double contactShadow, bevel, fov, meshQuality, textureQuality;
  final bool lightInspection;

  ReliefControls copyWith({
    String? preset,
    double? depthScale,
    double? reliefScale,
    double? parallax,
    double? maxYaw,
    double? maxPitch,
    double? light,
    double? saturation,
    double? contrast,
    double? brightness,
    double? feather,
    String? mode,
    String? solo,
    Map<String, double>? depths,
    Map<String, double>? reliefs,
    Map<String, double>? opacities,
    Map<String, bool>? visibility,
    String? projection,
    double? christContrast,
    double? christSaturation,
    double? christBrightness,
    double? christEdgeSeparation,
    double? lightAngle,
    double? lightIntensity,
    double? ambientIntensity,
    double? aoIntensity,
    double? contactShadow,
    double? bevel,
    double? fov,
    double? meshQuality,
    double? textureQuality,
    bool? lightInspection,
  }) => ReliefControls(
    preset: preset ?? this.preset,
    depthScale: depthScale ?? this.depthScale,
    reliefScale: reliefScale ?? this.reliefScale,
    parallax: parallax ?? this.parallax,
    maxYaw: maxYaw ?? this.maxYaw,
    maxPitch: maxPitch ?? this.maxPitch,
    light: light ?? this.light,
    saturation: saturation ?? this.saturation,
    contrast: contrast ?? this.contrast,
    brightness: brightness ?? this.brightness,
    feather: feather ?? this.feather,
    mode: mode ?? this.mode,
    solo: solo ?? this.solo,
    depths: depths ?? this.depths,
    reliefs: reliefs ?? this.reliefs,
    opacities: opacities ?? this.opacities,
    visibility: visibility ?? this.visibility,
    projection: projection ?? this.projection,
    christContrast: christContrast ?? this.christContrast,
    christSaturation: christSaturation ?? this.christSaturation,
    christBrightness: christBrightness ?? this.christBrightness,
    christEdgeSeparation: christEdgeSeparation ?? this.christEdgeSeparation,
    lightAngle: lightAngle ?? this.lightAngle,
    lightIntensity: lightIntensity ?? this.lightIntensity,
    ambientIntensity: ambientIntensity ?? this.ambientIntensity,
    aoIntensity: aoIntensity ?? this.aoIntensity,
    contactShadow: contactShadow ?? this.contactShadow,
    bevel: bevel ?? this.bevel,
    fov: fov ?? this.fov,
    meshQuality: meshQuality ?? this.meshQuality,
    textureQuality: textureQuality ?? this.textureQuality,
    lightInspection: lightInspection ?? this.lightInspection,
  );

  static ReliefControls fromPreset(String name) => switch (name) {
    'FLAT_ORIGINAL' => const ReliefControls(
      preset: 'FLAT_ORIGINAL',
      depthScale: 0,
      reliefScale: 0,
      parallax: 0,
    ),
    'SUBTLE_RELIEF' => const ReliefControls(
      preset: 'SUBTLE_RELIEF',
      depthScale: .45,
      reliefScale: .75,
      parallax: .8,
    ),
    'STRONG_DEPTH' => const ReliefControls(
      preset: 'STRONG_DEPTH',
      depthScale: .8,
      reliefScale: 1.35,
      parallax: 1.1,
    ),
    'DEBUG_EXAGGERATED' => const ReliefControls(
      preset: 'DEBUG_EXAGGERATED',
      depthScale: 1.4,
      reliefScale: 2.2,
      parallax: 1.4,
    ),
    _ => const ReliefControls(),
  };
}

/// Photo-aligned 2.5D projection. Centered vertices stay on their source
/// pixels, avoiding invented content and disocclusion in the still image.
class PhotoReliefProjector {
  PhotoReliefProjector(this.masterSize, {ui.Rect? sourceWindow})
    : sourceWindow =
          sourceWindow ??
          ui.Rect.fromLTWH(0, 0, masterSize.width, masterSize.height);
  final ui.Size masterSize;
  final ui.Rect sourceWindow;

  ReliefMesh? build(
    ReliefLayer layer,
    ui.Size viewSize,
    double yaw,
    double pitch,
    ReliefControls controls,
  ) {
    final crop = layer.crop;
    if (!crop.overlaps(sourceWindow)) return null;
    final scale =
        math.min(
          viewSize.width / sourceWindow.width,
          viewSize.height / sourceWindow.height,
        ) /
        controls.fov;
    final originX =
        (viewSize.width - sourceWindow.width * scale) / 2 -
        sourceWindow.left * scale;
    final originY =
        (viewSize.height - sourceWindow.height * scale) / 2 -
        sourceWindow.top * scale;
    final step =
        (layer.kind == 'mountain'
            ? 13.0
            : layer.id == 'christ' || layer.id == 'adam' || layer.id == 'eve'
            ? 19.0
            : 30.0) /
        controls.meshQuality;
    final cols = math.max(8, (crop.width / step).ceil());
    final rows = math.max(8, (crop.height / step).ceil());
    final count = (cols + 1) * (rows + 1);
    final positions = Float32List(count * 2),
        uv = Float32List(count * 2),
        colors = Int32List(count);
    final depth = controls.depths[layer.id] ?? layer.depth;
    final relief = controls.reliefs[layer.id] ?? layer.relief;
    final yawFraction = controls.maxYaw == 0
        ? 0
        : yaw / controls.maxYaw * controls.parallax;
    final pitchFraction = controls.maxPitch == 0
        ? 0
        : pitch / controls.maxPitch * controls.parallax;
    for (var j = 0; j <= rows; j++) {
      for (var i = 0; i <= cols; i++) {
        final k = j * (cols + 1) + i;
        final lx = crop.width * i / cols, ly = crop.height * j / rows;
        final h = layer.heightAt(lx, ly);
        final localMotion = layer.kind == 'mountain' ? .20 : .24;
        final depthAmount =
            depth * controls.depthScale +
            h * relief * controls.reliefScale * localMotion;
        // A mild quadratic background curvature follows the documented conch;
        // it changes parallax only and never warps the frontal source image.
        final normalizedX = (crop.left + lx) / masterSize.width * 2 - 1;
        final curvature = .018 * normalizedX * normalizedX;
        final parallax = math.max(0, depthAmount - curvature);
        final flatX = originX + (crop.left + lx) * scale;
        final flatY = originY + (crop.top + ly) * scale;
        if (controls.mode == 'sideAngle') {
          const sideCos = .573576436; // 55-degree developer view.
          positions[k * 2] =
              viewSize.width / 2 +
              (flatX - viewSize.width / 2) * sideCos +
              depthAmount * viewSize.width * .58;
          positions[k * 2 + 1] = flatY - depthAmount * viewSize.height * .025;
        } else {
          positions[k * 2] = flatX + yawFraction * parallax * 170 * scale;
          positions[k * 2 + 1] = flatY + pitchFraction * parallax * 145 * scale;
        }
        uv[k * 2] = lx;
        uv[k * 2 + 1] = ly;
        final (nx, ny, nz) = layer.normalAt(lx, ly);
        final angle =
            (controls.lightAngle +
                (controls.lightInspection ? yaw * 180 / math.pi * .25 : 0)) *
            math.pi /
            180;
        final dot =
            (nx * math.sin(angle) * .53 -
                ny * math.cos(angle) * .53 +
                nz * .75) /
            .987;
        final flatDot = .75 / .987;
        // Explicit planes carry the still-image form. Clean normals only
        // modulate each plane when the inspection light changes direction.
        final planeBase = layer.kind == 'mountain'
            ? (layer.id.endsWith('_back')
                  ? .87
                  : layer.id.endsWith('_mid')
                  ? .955
                  : 1.02)
            : (layer.id.endsWith('_rear_group')
                  ? .91
                  : layer.id.endsWith('_mid_group')
                  ? .96
                  : layer.id.endsWith('_front_group')
                  ? 1.0
                  : 1.0);
        final response =
            planeBase +
            (dot - flatDot) *
                (layer.kind == 'mountain'
                    ? .35
                    : layer.id == 'christ' ||
                          layer.id == 'adam' ||
                          layer.id == 'eve' ||
                          layer.id.endsWith('_front_group')
                    ? .16
                    : .08) *
                controls.lightIntensity;
        final shade =
            (255 *
                    (response * controls.ambientIntensity).clamp(
                      layer.kind == 'mountain' ? .83 : .90,
                      1.0,
                    ))
                .round();
        final debugShade =
            controls.mode == 'relief' || controls.mode == 'sideAngle'
            ? shade
            : 255;
        colors[k] =
            0xFF000000 | (debugShade << 16) | (debugShade << 8) | debugShade;
      }
    }
    final indices = <int>[];
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final a = j * (cols + 1) + i, b = a + 1, c = a + cols + 1, d = c + 1;
        indices.addAll([a, c, b, b, c, d]);
      }
    }
    return ReliefMesh(
      ui.Vertices.raw(
        ui.VertexMode.triangles,
        positions,
        textureCoordinates: uv,
        colors: colors,
        indices: Uint16List.fromList(indices),
      ),
      positions,
      cols,
      rows,
    );
  }
}

/// Small, independently projected meshes follow the existing conch. Their
/// transparent cropped textures preserve the master photograph's pixels.
class ReliefProjector {
  ReliefProjector(this.surface);
  final ConchSurface surface;

  ReliefMesh? build(
    ReliefLayer layer,
    ui.Size size,
    double yaw,
    double pitch,
    ReliefControls controls,
  ) {
    final bounds = layer.crop;
    final cols = math.max(8, (bounds.width / 24).ceil());
    final rows = math.max(8, (bounds.height / 24).ceil());
    final n = (cols + 1) * (rows + 1);
    final positions = Float32List(n * 2), uv = Float32List(n * 2);
    final colors = Int32List(n);
    final valid = List<bool>.filled(n, false);
    final masterWidth = surface.textureSize.width,
        masterHeight = surface.textureSize.height;
    final depth = controls.depths[layer.id] ?? layer.depth;
    final relief = controls.reliefs[layer.id] ?? layer.relief;
    final actualYaw = yaw * controls.parallax,
        actualPitch = pitch * controls.parallax;
    for (var j = 0; j <= rows; j++) {
      for (var i = 0; i <= cols; i++) {
        final k = j * (cols + 1) + i;
        final lx = i / cols * bounds.width, ly = j / rows * bounds.height;
        final u = (bounds.left + lx) / masterWidth,
            v = (bounds.top + ly) / masterHeight;
        final texel = surface.texelForPhoto(u, v);
        if (texel == null) continue;
        final height = layer.heightAt(lx, ly);
        final offset =
            (depth * controls.depthScale +
                height * relief * controls.reliefScale) *
            surface.radius;
        final world = texel.world + texel.normal * offset;
        final projected = surface.project(
          world,
          size,
          yaw: actualYaw,
          pitch: actualPitch,
        );
        if (projected == null) continue;
        positions[k * 2] = projected.dx;
        positions[k * 2 + 1] = projected.dy;
        uv[k * 2] = lx;
        uv[k * 2 + 1] = ly;
        final shade = (235 + 20 * height * controls.light).round().clamp(
          0,
          255,
        );
        colors[k] = 0xFF000000 | (shade << 16) | (shade << 8) | shade;
        valid[k] = true;
      }
    }
    final indices = <int>[];
    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < cols; i++) {
        final a = j * (cols + 1) + i, b = a + 1, c = a + cols + 1, d = c + 1;
        if (valid[a] && valid[b] && valid[c] && valid[d]) {
          indices.addAll([a, c, b, b, c, d]);
        }
      }
    }
    if (indices.isEmpty) return null;
    return ReliefMesh(
      ui.Vertices.raw(
        ui.VertexMode.triangles,
        positions,
        textureCoordinates: uv,
        colors: colors,
        indices: Uint16List.fromList(indices),
      ),
      positions,
      cols,
      rows,
    );
  }
}

class ReliefMesh {
  const ReliefMesh(this.vertices, this.positions, this.columns, this.rows);
  final ui.Vertices vertices;
  final Float32List positions;
  final int columns, rows;
}
