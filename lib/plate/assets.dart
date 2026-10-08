import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../services/figure_rig.dart';
import 'manifest.dart';

class PlateGeometry {
  PlateGeometry(Map<String, dynamic> value)
    : cols = value['cols'] as int,
      rows = value['rows'] as int,
      height = (value['height'] as List)
          .cast<num>()
          .map((n) => n.toDouble())
          .toList() {
    if (cols < 2 ||
        rows < 2 ||
        cols * rows > 60000 ||
        height.length != cols * rows ||
        height.any((n) => !n.isFinite)) {
      throw const FormatException('Invalid plate geometry');
    }
  }
  final int cols, rows;
  final List<double> height;
}

/// A player owns its images, shaders and rig. Late loads cannot outlive it.
class PlateAssets {
  PlateAssets({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  final _pending = <String, Future<ui.Image>>{};
  final images = <String, ui.Image>{};
  final _shaders = <int, ui.FragmentShader>{};
  FigureRig? rig;
  PlateGeometry? geometry;
  ui.FragmentProgram? _program;
  bool disposed = false;
  int get textureBytes =>
      images.values.fold(0, (sum, i) => sum + i.width * i.height * 4);
  ui.Size get sourceSize =>
      ui.Size(_manifest!.width.toDouble(), _manifest!.height.toDouble());
  PlateManifest? _manifest;

  Future<ui.Image> image(String path) => _pending.putIfAbsent(path, () async {
    final data = await _bundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    late ui.Image img;
    try {
      img = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
    if (disposed) {
      img.dispose();
      throw StateError('Plate closed while loading');
    }
    images[path] = img;
    return img;
  });
  Future<PlateGeometry> readGeometry(String path) async => PlateGeometry(
    jsonDecode(await _bundle.loadString(path, cache: false))
        as Map<String, dynamic>,
  );
  Future<FigureRig> readRig(String path, {int maxVertices = 60000}) async {
    final value = jsonDecode(
      await _bundle.loadString(path, cache: false),
    ) as Map<String, dynamic>;
    final poses = value['poses'] as String?;
    final data = poses == null ? null : await _bundle.load(poses);
    var valueRig = FigureRig(value, poseData: data);
    if (valueRig.cols * valueRig.rows > maxVertices) {
      final resampled = FigureRig.resample(valueRig, 299, 200);
      valueRig.dispose();
      valueRig = resampled;
    }
    if (valueRig.cols * valueRig.rows > maxVertices) {
      valueRig.dispose();
      throw const FormatException('Plate rig exceeds vertex budget');
    }
    if (disposed) {
      valueRig.dispose();
      throw StateError('Plate closed while loading');
    }
    rig = valueRig;
    return valueRig;
  }

  Future<void> load(PlateManifest manifest) async {
    _manifest = manifest;
    await Future.wait<Object>([
      ...manifest.imagePaths.map(image),
      readRig(manifest.mesh.figures, maxVertices: manifest.mesh.maxVertices),
      readGeometry(manifest.mesh.geometry).then((value) {
        geometry = value;
        return value;
      }),
      ui.FragmentProgram.fromAsset('shaders/plate.frag').then((value) {
        _program = value;
        return value;
      }),
    ]);
    if (disposed) throw StateError('Plate closed while loading');
    if (textureBytes > 150000000) {
      throw const FormatException('Plate texture budget exceeds 150 MB');
    }
    for (final entry in images.entries) {
      final i = entry.value;
      final reconstruction =
          manifest.layer(PlateLayerId.reconstruction).asset == entry.key;
      if (reconstruction) {
        if ((i.width / i.height - manifest.width / manifest.height).abs() >
            .002) {
          throw const FormatException(
            'Reconstruction grid does not match the master',
          );
        }
      } else if (i.width != manifest.width || i.height != manifest.height) {
        throw FormatException('Image grid mismatch: ${entry.key}');
      }
    }
  }

  ui.FragmentShader shader(int slot) {
    if (disposed) throw StateError('Plate assets disposed');
    return _shaders.putIfAbsent(slot, () => _program!.fragmentShader());
  }

  void dispose() {
    if (disposed) return;
    disposed = true;
    for (final shader in _shaders.values) {
      shader.dispose();
    }
    _shaders.clear();
    rig?.dispose();
    for (final image in images.values) {
      image.dispose();
    }
    images.clear();
    _pending.clear();
  }
}
