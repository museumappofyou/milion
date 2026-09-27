import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:image/image.dart' as img;

import '../models/scene.dart';

class SceneMatch {
  const SceneMatch(this.scene, this.probability);

  final Scene scene;
  final double probability;
}

class LivePrediction {
  const LivePrediction({required this.top, required this.probabilities});

  final List<SceneMatch> top;
  final List<double> probabilities;
}

class Classifier {
  static const String modelAsset = 'assets/model/chora_scene_classifier.onnx';
  static const String classesAsset = 'assets/model/classes.json';
  static const String mapAsset = 'assets/model/class_map.json';
  static const String infoAsset = 'assets/data/scene_info.json';

  static const String _inputName = 'image';
  static const String _outputName = 'logits';
  static const int _inputSize = 224;
  static const int _resizeSide = 256;
  static const double _temperature = 1.3;

  static const List<double> _mean = [0.485, 0.456, 0.406];
  static const List<double> _std = [0.229, 0.224, 0.225];

  OnnxRuntime? _ort;
  OrtSession? _session;
  List<Scene> _scenes = const [];
  bool _ready = false;
  Future<void>? _catalogLoading;

  bool get isReady => _ready;
  List<Scene> get scenes => _scenes;

  Future<void> loadCatalog() => _catalogLoading ??= _readCatalog();

  Future<void> _readCatalog() async {
    final classes = (jsonDecode(
      await rootBundle.loadString(classesAsset),
    ) as List).cast<String>();
    final records = (jsonDecode(await rootBundle.loadString(mapAsset)) as List)
        .cast<Map<String, dynamic>>();
    final info = (jsonDecode(await rootBundle.loadString(infoAsset)) as Map)
        .cast<String, dynamic>();
    final byId = {
      for (final record in records) record['scene_id'] as String: record,
    };

    _scenes = [
      for (final id in classes)
        Scene(
          id: id,
          title: (byId[id]?['title'] as String?) ?? id,
          room: (byId[id]?['room'] as String?) ?? '',
          surface: (byId[id]?['surface'] as String?) ?? '',
          folder: (byId[id]?['scene_folder'] as String?) ?? '',
          summary: (info[id]?['summary'] as String?) ?? '',
          cues: ((info[id]?['cues'] as List?) ?? const []).cast<String>(),
          position: (info[id]?['position'] as String?) ?? '',
          artworkType: (info[id]?['artwork_type'] as String?) ?? '',
        ),
    ];
  }

  Future<void> load() async {
    if (_ready) return;
    await loadCatalog();
    _ort = OnnxRuntime();
    try {
      // On web the session takes a URL, and Flutter serves bundled assets
      // under an extra "assets/" prefix (rootBundle adds it too).
      final source = kIsWeb ? 'assets/$modelAsset' : modelAsset;
      _session = await _ort!.createSessionFromAsset(source);
    } catch (_) {
      // On web the asset is fetched directly by onnxruntime-web, so there is
      // no temporary file to fall back to.
      if (kIsWeb) rethrow;
      final bytes = await rootBundle.load(modelAsset);
      final temp = File(
        '${Directory.systemTemp.path}/chora_scene_classifier_static.onnx',
      );
      await temp.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      _session = await _ort!.createSession(temp.path);
    }
    _ready = true;
  }

  Future<List<SceneMatch>> classifyBytes(Uint8List bytes) async {
    final input = await _preprocessImage(bytes);
    final probabilities = await _infer(input);
    return _topMatches(probabilities);
  }

  Future<LivePrediction?> classifyCameraImage(
    CameraImage image,
    int sensorOrientation,
  ) async {
    final input = _preprocessFrame(image, sensorOrientation);
    if (input == null) {
      return null;
    }
    final probabilities = await _infer(input);
    return LivePrediction(
      top: _topMatches(probabilities),
      probabilities: probabilities,
    );
  }

  Future<void> close() async {
    await _session?.close();
    _session = null;
    _ready = false;
  }

  Future<List<double>> _infer(Float32List input) async {
    final session = _session;
    if (session == null) {
      throw StateError('Classifier is not loaded');
    }
    final tensor = await OrtValue.fromList(input, [
      1,
      3,
      _inputSize,
      _inputSize,
    ]);
    try {
      final outputs = await session.run({_inputName: tensor});
      try {
        final output = outputs[_outputName];
        if (output == null) {
          throw StateError('Model did not return "$_outputName"');
        }
        final logits = (await output.asFlattenedList())
            .map((value) => (value as num).toDouble())
            .toList();
        return _softmax(logits);
      } finally {
        for (final value in outputs.values) {
          await value.dispose();
        }
      }
    } finally {
      await tensor.dispose();
    }
  }

  Future<Float32List> _preprocessImage(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Could not decode the image');
    }
    final oriented = img.bakeOrientation(decoded);
    final shortest = math.min(oriented.width, oriented.height);
    final scale = _resizeSide / shortest;
    final resized = img.copyResize(
      oriented,
      width: (oriented.width * scale).round(),
      height: (oriented.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
    final cropped = img.copyCrop(
      resized,
      x: ((resized.width - _inputSize) / 2).round(),
      y: ((resized.height - _inputSize) / 2).round(),
      width: _inputSize,
      height: _inputSize,
    );

    final plane = _inputSize * _inputSize;
    final input = Float32List(3 * plane);
    var index = 0;
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = cropped.getPixel(x, y);
        input[index] = (pixel.r / 255.0 - _mean[0]) / _std[0];
        input[plane + index] = (pixel.g / 255.0 - _mean[1]) / _std[1];
        input[2 * plane + index] = (pixel.b / 255.0 - _mean[2]) / _std[2];
        index++;
      }
    }
    return input;
  }

  Float32List? _preprocessFrame(CameraImage image, int sensorOrientation) {
    if (image.planes.length < 3) {
      return null;
    }
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final width = image.width;
    final height = image.height;
    final rotation = ((sensorOrientation % 360) + 360) % 360;

    final swapped = rotation == 90 || rotation == 270;
    final uprightWidth = swapped ? height : width;
    final uprightHeight = swapped ? width : height;
    final side = math.min(uprightWidth, uprightHeight);
    final x0 = (uprightWidth - side) / 2.0;
    final y0 = (uprightHeight - side) / 2.0;
    final step = side / _inputSize;

    final yRow = yPlane.bytesPerRow;
    final yPixel = yPlane.bytesPerPixel ?? 1;
    final uRow = uPlane.bytesPerRow;
    final uPixel = uPlane.bytesPerPixel ?? 1;
    final vRow = vPlane.bytesPerRow;
    final vPixel = vPlane.bytesPerPixel ?? 1;

    final plane = _inputSize * _inputSize;
    final input = Float32List(3 * plane);
    var index = 0;
    var lumaSum = 0.0;
    var lumaSquareSum = 0.0;
    for (var oy = 0; oy < _inputSize; oy++) {
      final uy = y0 + (oy + 0.5) * step;
      for (var ox = 0; ox < _inputSize; ox++) {
        final ux = x0 + (ox + 0.5) * step;
        final int sx;
        final int sy;
        switch (rotation) {
          case 90:
            sx = uy.round();
            sy = (height - 1 - ux).round();
          case 180:
            sx = (width - 1 - ux).round();
            sy = (height - 1 - uy).round();
          case 270:
            sx = (width - 1 - uy).round();
            sy = ux.round();
          default:
            sx = ux.round();
            sy = uy.round();
        }
        final cx = sx.clamp(0, width - 1).toInt();
        final cy = sy.clamp(0, height - 1).toInt();

        final yValue = yPlane.bytes[cy * yRow + cx * yPixel];
        lumaSum += yValue;
        lumaSquareSum += yValue * yValue;
        final uvx = cx >> 1;
        final uvy = cy >> 1;
        final uValue = uPlane.bytes[uvy * uRow + uvx * uPixel];
        final vValue = vPlane.bytes[uvy * vRow + uvx * vPixel];

        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255) / 255.0;
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .clamp(0, 255) /
            255.0;
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255) / 255.0;

        input[index] = (r - _mean[0]) / _std[0];
        input[plane + index] = (g - _mean[1]) / _std[1];
        input[2 * plane + index] = (b - _mean[2]) / _std[2];
        index++;
      }
    }

    // Skip frames that carry no scene: too dark, or too flat (empty wall,
    // ceiling, floor). The closed-set model would otherwise always name
    // something. Thresholds are on raw luma (0-255): mean >= 18 and std >= 5.
    final count = plane.toDouble();
    final lumaMean = lumaSum / count;
    final variance = (lumaSquareSum / count) - (lumaMean * lumaMean);
    if (lumaMean < 18.0 || variance < 25.0) {
      return null;
    }
    return input;
  }

  List<double> _softmax(List<double> logits) {
    final scaled = [for (final value in logits) value / _temperature];
    final peak = scaled.reduce(math.max);
    final exps = [for (final value in scaled) math.exp(value - peak)];
    final total = exps.reduce((a, b) => a + b);
    return [for (final value in exps) value / total];
  }

  List<SceneMatch> _topMatches(List<double> probabilities) {
    final order = List<int>.generate(probabilities.length, (i) => i)
      ..sort((a, b) => probabilities[b].compareTo(probabilities[a]));
    return [
      for (final i in order.take(3)) SceneMatch(_scenes[i], probabilities[i]),
    ];
  }
}
