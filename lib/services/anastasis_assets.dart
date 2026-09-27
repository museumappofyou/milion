import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

import '../models/anastasis_capture.dart';
import 'anastasis_relief.dart';

/// Loads the prepared Anastasis artifact: the capture manifest and the
/// reference texture used by the 2.5D viewer.
class AnastasisAssets {
  static const String manifestAsset = 'assets/anastasis/captures.json';

  AnastasisArtifact? _artifact;
  ui.Image? _texture;
  final AnastasisReliefAssets relief = AnastasisReliefAssets();

  AnastasisArtifact? get artifact => _artifact;
  ui.Image? get texture => _texture;

  bool get isReady => _artifact != null && _texture != null;

  Future<void> load({bool includeRelief = true}) async {
    final json = jsonDecode(await rootBundle.loadString(manifestAsset));
    final artifact = AnastasisArtifact.fromJson(
      (json as Map).cast<String, dynamic>(),
    );
    _artifact = artifact;
    final bytes = await rootBundle.load(artifact.textureFile);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _texture = frame.image;
    if (includeRelief) await relief.load();
  }

  void dispose() {
    _texture?.dispose();
    _texture = null;
    _artifact = null;
    relief.dispose();
  }
}
