import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'figure_rig.dart';

class ExplorerGeometry {
  ExplorerGeometry(Map<String, dynamic> value)
    : cols = value['cols'] as int,
      rows = value['rows'] as int,
      height = (value['height'] as List)
          .cast<num>()
          .map((n) => n.toDouble())
          .toList();
  final int cols, rows;
  final List<double> height;
}

/// Each screen owns its decoded textures. Late completions also get disposed.
class ExplorerAssets {
  final _pending = <String, Future<ui.Image>>{};
  final _images = <ui.Image>[];
  final _rigs = <FigureRig>[];
  bool _disposed = false;

  Future<ui.Image> image(String file) => _pending.putIfAbsent(file, () async {
    final bytes = await rootBundle.load(file);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    late ui.Image image;
    try {
      image = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
    if (_disposed) {
      image.dispose();
      throw StateError('Viewer closed while loading');
    }
    _images.add(image);
    return image;
  });

  Future<ExplorerGeometry> geometry(String file) async => ExplorerGeometry(
    jsonDecode(await rootBundle.loadString(file)) as Map<String, dynamic>,
  );

  Future<FigureRig> figures(String file) async {
    final data = await rootBundle.load(file);
    final value = jsonDecode(
      utf8.decode(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ),
    ) as Map<String, dynamic>;
    final poseFile = value['poses'] as String?;
    final poseData = poseFile == null ? null : await rootBundle.load(poseFile);
    final rig = FigureRig(value, poseData: poseData);
    if (_disposed) {
      rig.dispose();
      throw StateError('Viewer closed while loading');
    }
    _rigs.add(rig);
    return rig;
  }

  void dispose() {
    _disposed = true;
    for (final rig in _rigs) {
      rig.dispose();
    }
    _rigs.clear();
    for (final image in _images) {
      image.dispose();
    }
    _images.clear();
    _pending.clear();
  }
}
