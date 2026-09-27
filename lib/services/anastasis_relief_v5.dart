import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

/// One fixed-camera view of the fifth-pass relief. Only the relief view is
/// decoded up front; diagnostic views decode when first selected.
class ReliefV5View {
  ReliefV5View(this.id, this.label, this.file);
  final String id;
  final String label;
  final String file;
  ui.Image? image;

  Future<ui.Image> ensureLoaded() async {
    if (image != null) return image!;
    final bytes = await rootBundle.load(file);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    return image = (await codec.getNextFrame()).image;
  }
}

/// Fifth-pass painted relief. Every view is rendered offline by
/// `tool/build_anastasis_v5.py` from one authored height field, centered and
/// orthographic, so it keeps the master photograph's pixel grid: the relief
/// view is the original RGB multiplied by a restrained raking light, contact
/// shadow and occlusion. Motion stays disabled for this pass.
class AnastasisReliefV5 {
  static const manifestPath = 'assets/anastasis/relief_v5/manifest.json';
  final List<ReliefV5View> views = [];

  ReliefV5View? view(String id) {
    for (final view in views) {
      if (view.id == id) return view;
    }
    return null;
  }

  Future<void> load() async {
    final manifest = jsonDecode(
      await rootBundle.loadString(manifestPath),
    ) as Map<String, dynamic>;
    for (final raw in manifest['views'] as List) {
      final item = raw as Map<String, dynamic>;
      views.add(
        ReliefV5View(
          item['id'] as String,
          item['label'] as String,
          item['file'] as String,
        ),
      );
    }
    await views.first.ensureLoaded();
  }

  void dispose() {
    for (final view in views) {
      view.image?.dispose();
    }
    views.clear();
  }
}
