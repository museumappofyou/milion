// Milion P08 spike, candidate (b): flutter_scene / Flutter GPU.
//
// Self-measuring benchmark. On launch it:
//   1. initialises flutter_scene's static resources (timed),
//   2. imports assets/bench-50k.glb at runtime with Node.fromGlbBytes (timed),
//   3. auto-orbits the camera for 10 s around the bay (phase "orbit"),
//   4. then walks a 10 s eye-height loop inside it (phase "interiorWalk"),
//   5. prints exactly ONE line: `MILION_SPIKE {json}`.
//
// Frame times come from SchedulerBinding.addTimingsCallback (FrameTiming
// build/raster durations); fps is UI frames counted over wall-clock time.
// Requires Flutter GPU to be enabled (AndroidManifest meta-data
// io.flutter.embedding.android.EnableFlutterGPU / macOS FLTEnableFlutterGPU).

import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui show ImageByteFormat;
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

const String kModel = 'assets/bench-50k.glb';
// Reported in the JSON so A/B logs are distinguishable; the 0.24.3 variant is
// built with --dart-define=SPIKE_FS_VERSION=0.24.3 (pubspec pin changed too).
const String kFsVersion =
    String.fromEnvironment('SPIKE_FS_VERSION', defaultValue: '0.23.0');
const Duration kPhase = Duration(seconds: 10);
// Debug aid (off by default, so it never perturbs timings): save PNG snapshots
// of the view 3 s into each phase. Build with --dart-define=SPIKE_CAPTURE=true.
const bool kCapture = bool.fromEnvironment('SPIKE_CAPTURE');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SpikePage(),
  ));
}

class SpikePage extends StatefulWidget {
  const SpikePage({super.key});
  @override
  State<SpikePage> createState() => _SpikePageState();
}

class _Phase {
  _Phase(this.name);
  final String name;
  int? startStampUs; // engine frame timestamp (same clock as FrameTiming)
  int? endStampUs;
  final Stopwatch wall = Stopwatch();
  int uiFrames = 0;
}

class _SpikePageState extends State<SpikePage> {
  final Scene scene = Scene();
  bool ready = false;
  String status = 'loading';
  final Map<String, Object?> result = {};
  final List<FrameTiming> timings = [];
  final List<_Phase> phases = [_Phase('orbit'), _Phase('interiorWalk')];
  int phaseIndex = -1;
  Duration? revealElapsed;
  bool done = false;
  final GlobalKey boundaryKey = GlobalKey();
  final Set<int> captured = {};

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _load();
  }

  void _onTimings(List<FrameTiming> t) => timings.addAll(t);

  Future<void> _load() async {
    try {
      final total = Stopwatch()..start();
      final sw = Stopwatch()..start();
      await Scene.initializeStaticResources();
      result['staticResourcesMs'] = sw.elapsedMicroseconds / 1000.0;

      // Source triangle/vertex counts, read straight from the GLB JSON chunk.
      sw.reset();
      final bd = await rootBundle.load(kModel);
      final bytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
      result['assetReadMs'] = sw.elapsedMicroseconds / 1000.0;
      _countGeometry(bytes);

      // The measured load: parse + pack + GPU upload of the whole GLB.
      sw.reset();
      final warnings = <String>[];
      final node = await Node.fromGlbBytes(
        bytes,
        onWarning: (w) => warnings.add('$w'),
      );
      result['importWarnings'] = warnings;
      result['glbImportMs'] = sw.elapsedMicroseconds / 1000.0;
      // The GLB has no materials, so the importer assigns UnlitMaterial (flat
      // white). Swap in one shared matte PBR material so the benchmark pays
      // for real lighting (IBL + studio environment).
      final matte = PhysicallyBasedMaterial()
        ..baseColorFactor = vm.Vector4(0.78, 0.74, 0.68, 1)
        ..metallicFactor = 0.0
        ..roughnessFactor = 0.85;
      var swapped = 0;
      void visit(Node n) {
        for (final p in n.mesh?.primitives ?? const <MeshPrimitive>[]) {
          p.material = matte;
          swapped++;
        }
        n.children.forEach(visit);
      }
      visit(node);
      result['primitivesRematerialed'] = swapped;
      scene.add(node);
      result['glbLoadMs'] = total.elapsedMicroseconds / 1000.0;

      // Time until the first frame containing the model has been built.
      sw.reset();
      setState(() {
        ready = true;
        status = 'running';
      });
      await SchedulerBinding.instance.endOfFrame;
      await SchedulerBinding.instance.endOfFrame;
      result['firstTwoFramesUiMs'] = sw.elapsedMicroseconds / 1000.0;
    } catch (e, st) {
      result['error'] = '$e';
      result['stack'] = '$st'.split('\n').take(8).join(' | ');
      _emit();
    }
  }

  void _countGeometry(Uint8List b) {
    final bd = ByteData.sublistView(b);
    final jsonLen = bd.getUint32(12, Endian.little);
    final j = jsonDecode(utf8.decode(b.sublist(20, 20 + jsonLen))) as Map;
    final acc = j['accessors'] as List;
    var tris = 0, verts = 0, prims = 0;
    final attrs = <String>{};
    for (final m in j['meshes'] as List) {
      for (final p in m['primitives'] as List) {
        prims++;
        final a = p['attributes'] as Map;
        attrs.addAll(a.keys.cast<String>());
        verts += (acc[a['POSITION'] as int] as Map)['count'] as int;
        tris += ((acc[p['indices'] as int] as Map)['count'] as int) ~/ 3;
      }
    }
    result['triangles'] = tris;
    result['sourceVertices'] = verts;
    result['primitives'] = prims;
    result['sourceAttributes'] = attrs.toList()..sort();
  }

  // Called by SceneView once per frame while ticking.
  void _onTick(Duration elapsed, double dt) {
    if (done) return;
    revealElapsed ??= elapsed;
    final t = elapsed - revealElapsed!;
    final want = t < kPhase ? 0 : (t < kPhase * 2 ? 1 : 2);
    final stamp =
        SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    if (want != phaseIndex) {
      if (phaseIndex >= 0) {
        phases[phaseIndex]
          ..endStampUs = stamp
          ..wall.stop();
      }
      phaseIndex = want;
      if (want < phases.length) {
        phases[want]
          ..startStampUs = stamp
          ..wall.start();
      } else {
        done = true;
        // Let the last batch of FrameTimings arrive (release mode batches
        // them roughly once per second).
        Future.delayed(const Duration(milliseconds: 1500), _emit);
        return;
      }
    }
    phases[phaseIndex].uiFrames++;
    if (kCapture && t.inMilliseconds > kPhase.inMilliseconds * phaseIndex + 3000 &&
        captured.add(phaseIndex)) {
      _capture(phases[phaseIndex].name);
    }
  }

  Future<void> _capture(String name) async {
    final b = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (b == null) return;
    final img = await b.toImage(pixelRatio: 1.0);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    final f = File('${Directory.systemTemp.path}/milion_spike_$name.png');
    await f.writeAsBytes(png!.buffer.asUint8List());
    // ignore: avoid_print
    print('MILION_SPIKE_CAPTURE ${f.path}');
  }

  Camera _camera(Duration elapsed) {
    final t = revealElapsed == null
        ? 0.0
        : (elapsed - revealElapsed!).inMicroseconds / 1e6;
    if (t < kPhase.inSeconds) {
      // Orbit: one revolution in 10 s, framing the ~72 x 56 m bay.
      final a = t / kPhase.inSeconds * 2 * math.pi;
      return PerspectiveCamera(
        position: vm.Vector3(math.sin(a) * 95, 38, math.cos(a) * 95),
        target: vm.Vector3(0, 22, 0),
        fovNear: 0.5,
        fovFar: 500,
      );
    }
    // Interior walk: eye height 1.7 m on a 14 m circle, looking along the path
    // and slightly up, so the vaulting fills the screen (walkable-space proxy).
    final a = (t - kPhase.inSeconds) / kPhase.inSeconds * 2 * math.pi;
    final pos = vm.Vector3(math.sin(a) * 14, 1.7, math.cos(a) * 14);
    final ahead = vm.Vector3(
        math.sin(a + 0.6) * 14, 6.0, math.cos(a + 0.6) * 14);
    return PerspectiveCamera(
      position: pos,
      target: ahead,
      fovRadiansY: 60 * vm.degrees2Radians,
      fovNear: 0.1,
      fovFar: 300,
    );
  }

  Map<String, Object?> _stats(_Phase p) {
    if (p.startStampUs == null || p.endStampUs == null) {
      return {'error': 'phase did not run'};
    }
    final inWin = timings.where((f) {
      final v = f.timestampInMicroseconds(FramePhase.vsyncStart);
      return v >= p.startStampUs! - 2000 && v < p.endStampUs!;
    }).toList();
    double pct(List<double> xs, double q) {
      if (xs.isEmpty) return double.nan;
      final s = [...xs]..sort();
      final i = ((s.length - 1) * q).round();
      return s[i];
    }

    double r(double x) => (x * 100).roundToDouble() / 100;
    final build =
        inWin.map((f) => f.buildDuration.inMicroseconds / 1000.0).toList();
    final raster =
        inWin.map((f) => f.rasterDuration.inMicroseconds / 1000.0).toList();
    final total =
        inWin.map((f) => f.totalSpan.inMicroseconds / 1000.0).toList();
    final secs = p.wall.elapsedMicroseconds / 1e6;
    return {
      'seconds': r(secs),
      'uiFrames': p.uiFrames,
      'frameTimings': inWin.length,
      'fps': r(p.uiFrames / secs),
      'buildMsMedian': r(pct(build, 0.5)),
      'buildMsP90': r(pct(build, 0.9)),
      'buildMsMax': r(pct(build, 1.0)),
      'rasterMsMedian': r(pct(raster, 0.5)),
      'rasterMsP90': r(pct(raster, 0.9)),
      'rasterMsMax': r(pct(raster, 1.0)),
      'totalSpanMsMedian': r(pct(total, 0.5)),
      'totalSpanMsP90': r(pct(total, 0.9)),
    };
  }

  String _backend() {
    final ctx = gpu.gpuContext;
    if (Platform.isAndroid) {
      // Flutter GPU exposes no backend enum; doesSupportFramebufferRenderMipmap
      // is documented as true on Metal/Vulkan and false on GLES.
      return ctx.doesSupportFramebufferRenderMipmap
          ? 'Impeller Vulkan (inferred)'
          : 'Impeller GLES (inferred)';
    }
    if (Platform.isMacOS || Platform.isIOS) return 'Impeller Metal';
    return 'Impeller (unknown backend)';
  }

  void _emit() {
    final orbit = _stats(phases[0]);
    try {
      final ctx = gpu.gpuContext;
      result['backend'] = _backend();
      result['gpuCaps'] = {
        'offscreenMSAA': ctx.doesSupportOffscreenMSAA,
        'framebufferRenderMipmap': ctx.doesSupportFramebufferRenderMipmap,
        'maxSamplerAnisotropy': ctx.maxSamplerAnisotropy,
        'depthStencilFormat': ctx.defaultDepthStencilFormat.name,
      };
    } catch (e) {
      result['backend'] = 'Flutter GPU unavailable: $e';
    }
    final view = View.of(context);
    final out = <String, Object?>{
      'candidate': 'flutter_scene',
      'packageVersion': kFsVersion,
      'platform': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'antiAliasing': scene.effectiveAntiAliasingMode.name,
      'viewPhysicalPx': [
        view.physicalSize.width.round(),
        view.physicalSize.height.round(),
      ],
      'devicePixelRatio': view.devicePixelRatio,
      ...result,
      // Requested headline numbers (orbit phase).
      'frameCount': orbit['uiFrames'],
      'fps': orbit['fps'],
      'buildMsMedian': orbit['buildMsMedian'],
      'buildMsP90': orbit['buildMsP90'],
      'rasterMsMedian': orbit['rasterMsMedian'],
      'rasterMsP90': orbit['rasterMsP90'],
      'orbit': orbit,
      'interiorWalk': _stats(phases[1]),
    };
    // ignore: avoid_print
    print('MILION_SPIKE ${jsonEncode(out)}');
    if (mounted) setState(() => status = 'done');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (ready)
            Positioned.fill(
              child: RepaintBoundary(
                key: boundaryKey,
                child: SceneView(
                  scene,
                  cameraBuilder: _camera,
                  onTick: _onTick,
                ),
              ),
            ),
          Positioned(
            left: 12,
            top: 36,
            child: Text(
              'flutter_scene spike: $status',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
