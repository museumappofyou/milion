import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../services/figure_rig.dart';
import 'manifest.dart';

/// A player owns its images, shaders and rig. Late loads cannot outlive it.
class PlateAssets {
  PlateAssets({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  static const plateShader = 'shaders/plate.frag';
  static const lookUpShader = 'shaders/lookup.frag';
  final AssetBundle _bundle;
  final _pending = <String, Future<ui.Image>>{};
  final images = <String, ui.Image>{};
  final _programs = <String, ui.FragmentProgram>{};
  final _shaders = <(String, int), ui.FragmentShader>{};
  FigureRig? rig;
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

  /// Rigs larger than the budget are bilinearly resampled at their aspect.
  Future<FigureRig> readRig(String path, {int maxVertices = 60000}) async {
    final value = jsonDecode(
      await _bundle.loadString(path, cache: false),
    ) as Map<String, dynamic>;
    final poses = value['poses'] as String?;
    final data = poses == null ? null : await _bundle.load(poses);
    var valueRig = FigureRig(value, poseData: data);
    final count = valueRig.cols * valueRig.rows;
    if (count > maxVertices) {
      final f = math.sqrt(maxVertices / count);
      final resampled = FigureRig.resample(
        valueRig,
        (valueRig.cols * f).floor(),
        (valueRig.rows * f).floor(),
      );
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

  Future<ui.FragmentProgram> _program(String asset) async =>
      _programs[asset] ??= await ui.FragmentProgram.fromAsset(asset);

  Future<void> load(PlateManifest manifest) async {
    _manifest = manifest;
    final rigSpec = manifest.rig;
    await Future.wait<Object>([
      ...manifest.imagePaths.map(image),
      if (rigSpec != null)
        readRig(rigSpec.path, maxVertices: rigSpec.maxVertices),
      _program(plateShader),
      if (manifest.lookUp != null) _program(lookUpShader),
    ]);
    if (disposed) throw StateError('Plate closed while loading');
    if (textureBytes > 150000000) {
      throw const FormatException('Plate texture budget exceeds 150 MB');
    }
    final reconstruction = manifest.layer(PlateLayerId.reconstruction)?.asset;
    for (final entry in images.entries) {
      final i = entry.value;
      if (entry.key == reconstruction) {
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

  /// One cached instance per slot keeps masked passes composable.
  ui.FragmentShader shader(int slot, {String asset = plateShader}) {
    if (disposed) throw StateError('Plate assets disposed');
    return _shaders.putIfAbsent((
      asset,
      slot,
    ), () => _programs[asset]!.fragmentShader());
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
