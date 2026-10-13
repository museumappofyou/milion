// Milion P08 spike, candidate (c): thermion_flutter 0.5.0 (Filament 1.69.1).
//
// Self-measuring benchmark. On launch it:
//   1. creates a Thermion viewer (engine + swapchain + Flutter texture),
//   2. loads the bench glb (derived copy) with loadGltfFromBuffer (timed),
//   3. auto-orbits the camera for 10 s, driven from Thermion's per-frame
//      request hook (one camera update per Filament frame),
//   4. prints ONE line: `MILION_SPIKE {json}` (logcat tag `flutter`).
//
// Flutter frame timings come from SchedulerBinding.addTimingsCallback.
// Filament-side timings: interval between consecutive Thermion render
// requests (render cadence) and Thermion's own FrameScheduler diagnostics
// ("120-frame avg=..ms", the Dart->render-thread->endFrame round trip).
//
// --dart-define=MILION_EXIT=true exits the process after printing (desktop
// runs only; leave it off on Android so the log can be read at leisure).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:thermion_flutter/thermion_flutter.dart' hide Transform;

// Derived copy of studio/spikes/p08/bench-50k.glb: Filament's gltfio rejects
// the custom `_AO` attribute, so `_AO` -> COLOR_0 (ao,ao,ao,1). See notes.
const _assetPath = String.fromEnvironment(
  'MILION_GLB',
  defaultValue: 'assets/bench-50k-color0.glb',
);
const _orbitSeconds = 10;
const _exitWhenDone = bool.fromEnvironment('MILION_EXIT');

final List<String> _schedulerDiag = <String>[];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((r) {
    if (r.loggerName == 'FrameScheduler' && r.message.contains('120-frame')) {
      _schedulerDiag.add(r.message);
    }
    if (r.level >= Level.WARNING && !r.message.contains('JANK')) {
      debugPrint('[${r.loggerName}] ${r.level.name}: ${r.message}');
    }
  });
  runApp(const BenchApp());
}

class BenchApp extends StatelessWidget {
  const BenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: const Color(0xFFE8E4DC),
      debugShowCheckedModeBanner: false,
      builder: (_, _) => const BenchPage(),
    );
  }
}

class BenchPage extends StatefulWidget {
  const BenchPage({super.key});

  @override
  State<BenchPage> createState() => _BenchPageState();
}

double _percentile(List<double> xs, double p) {
  if (xs.isEmpty) return double.nan;
  final s = List<double>.of(xs)..sort();
  final idx = ((s.length - 1) * p).round().clamp(0, s.length - 1);
  return s[idx];
}

double _r2(double v) => v.isFinite ? (v * 100).roundToDouble() / 100 : -1;

/// Triangle count straight from the glb JSON chunk (sum of index counts / 3).
int _countTriangles(Uint8List glb) {
  final bd = ByteData.sublistView(glb);
  final jsonLen = bd.getUint32(12, Endian.little);
  final j = jsonDecode(utf8.decode(glb.sublist(20, 20 + jsonLen))) as Map;
  final accessors = j['accessors'] as List;
  var tris = 0;
  for (final m in j['meshes'] as List) {
    for (final p in (m as Map)['primitives'] as List) {
      final idx = (p as Map)['indices'];
      if (idx is int) tris += ((accessors[idx] as Map)['count'] as int) ~/ 3;
    }
  }
  return tris;
}

class _BenchPageState extends State<BenchPage>
    with SingleTickerProviderStateMixin {
  ThermionViewer? _viewer;
  String _status = 'creating viewer';
  late final Ticker _ticker;
  int _hudTick = 0;

  // Measurements.
  final List<FrameTiming> _timings = <FrameTiming>[];
  bool _collecting = false;
  final List<double> _filamentIntervalsMs = <double>[];
  int _filamentFrames = 0;

  @override
  void initState() {
    super.initState();
    // The ticker keeps Flutter producing a frame every vsync during the orbit
    // (a HUD text updates), like an app with live UI over the 3D view.
    _ticker = createTicker((_) {
      if (_collecting) setState(() => _hudTick++);
    });
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    unawaited(
      _run().catchError((Object e, StackTrace st) {
        final line = jsonEncode({
          'candidate': 'thermion',
          'error': e.toString(),
          'stack': st.toString().split('\n').take(8).join(' | '),
        });
        debugPrint('MILION_SPIKE $line');
        if (mounted) setState(() => _status = 'error: $e');
      }),
    );
  }

  void _onTimings(List<FrameTiming> ts) {
    if (_collecting) _timings.addAll(ts);
  }

  Future<void> _waitFilamentFrames(int n) async {
    final c = Completer<void>();
    var seen = 0;
    Future<void> hook() async {
      seen++;
      if (seen >= n && !c.isCompleted) c.complete();
    }

    await FilamentApp.instance!.registerRequestFrameHook(hook);
    await c.future.timeout(const Duration(seconds: 20));
    await FilamentApp.instance!.unregisterRequestFrameHook(hook);
  }

  Future<void> _run() async {
    final total = Stopwatch()..start();

    final viewer = await ThermionFlutterPlugin.createViewer();
    final createViewerMs = total.elapsedMicroseconds / 1000;
    setState(() {
      _viewer = viewer;
      _status = 'loading glb';
    });

    await viewer.setBackgroundColor(0.91, 0.89, 0.86, 1.0);
    await viewer.setPostProcessing(true);
    await viewer.addDirectLight(
      DirectLight.sun(
        direction: Vector3(0.45, -1.0, -0.35).normalized(),
        intensity: 100000,
      ),
    );

    // Read bytes (asset bundle) separately from the glTF parse/upload.
    final readSw = Stopwatch()..start();
    final data = await rootBundle.load(_assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final assetReadMs = readSw.elapsedMicroseconds / 1000;
    final triangles = _countTriangles(bytes);

    final loadSw = Stopwatch()..start();
    final asset = await viewer.loadGltfFromBuffer(bytes);
    final glbLoadMs = loadSw.elapsedMicroseconds / 1000;

    // Two Filament frames after load ~ first frame with the model on screen.
    final ffSw = Stopwatch()..start();
    await _waitFilamentFrames(2);
    final firstFramesAfterLoadMs = ffSw.elapsedMicroseconds / 1000;

    final camera = await viewer.getActiveCamera();
    // The Flutter texture (and so the Filament viewport) is created once the
    // ThermionWidget is laid out; wait for it before fixing the lens aspect.
    var vp = await viewer.view.getViewport();
    final vpSw = Stopwatch()..start();
    while ((vp.width == 0 || vp.height == 0) &&
        vpSw.elapsedMilliseconds < 10000) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      vp = await viewer.view.getViewport();
    }
    final aspect = (vp.width > 0 && vp.height > 0) ? vp.width / vp.height : 1.0;
    // Model is ~72 m wide, 56 m tall: widen the lens and push far plane out.
    await camera.setLensProjection(
      near: 0.5,
      far: 500,
      aspect: aspect,
      focalLength: 24,
    );

    final focus = Vector3(0, 22, 0);
    const radius = 90.0;
    const height = 38.0;

    // Orbit: one camera update per Filament frame, from the render hook.
    final orbitSw = Stopwatch();
    int? lastUs;
    Future<void> orbitHook() async {
      final nowUs = orbitSw.elapsedMicroseconds;
      if (lastUs != null) _filamentIntervalsMs.add((nowUs - lastUs!) / 1000);
      lastUs = nowUs;
      _filamentFrames++;
      final a = 2 * math.pi * (nowUs / 1e6) / _orbitSeconds;
      await camera.lookAt(
        Vector3(radius * math.cos(a), height, radius * math.sin(a)),
        focus: focus,
      );
    }

    setState(() => _status = 'orbiting');
    _schedulerDiag.clear();
    _timings.clear();
    _collecting = true;
    _ticker.start();
    orbitSw.start();
    await FilamentApp.instance!.registerRequestFrameHook(orbitHook);
    await Future<void>.delayed(const Duration(seconds: _orbitSeconds));
    await FilamentApp.instance!.unregisterRequestFrameHook(orbitHook);
    final orbitMs = orbitSw.elapsedMicroseconds / 1000;
    _collecting = false;
    _ticker.stop();
    // Let the last timings batch arrive (they are delivered ~every 100 ms).
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final build = _timings
        .map((t) => t.buildDuration.inMicroseconds / 1000)
        .toList();
    final raster = _timings
        .map((t) => t.rasterDuration.inMicroseconds / 1000)
        .toList();
    final totalSpan = _timings
        .map((t) => t.totalSpan.inMicroseconds / 1000)
        .toList();

    // Parse Thermion's own FrameScheduler diagnostics.
    final rx = RegExp(r'avg=([\d.]+)ms max=([\d.]+)ms jank=(\d+) drop=(\d+)');
    final diagAvg = <double>[];
    var diagDrops = 0;
    var diagJank = 0;
    for (final s in _schedulerDiag) {
      final m = rx.firstMatch(s);
      if (m == null) continue;
      diagAvg.add(double.parse(m.group(1)!));
      diagJank += int.parse(m.group(3)!);
      diagDrops += int.parse(m.group(4)!);
    }

    // Sanity check that the model is actually on screen: read back one frame
    // and count pixels that differ from the corner (background) pixel.
    Object coverage = 'unmeasured';
    try {
      final caps = await FilamentApp.instance!.capture(
        null,
        view: viewer.view,
        captureRenderTarget: Platform.isMacOS || Platform.isIOS,
      );
      final raw = caps.first.$2;
      final px = raw.buffer.asFloat32List(
        raw.offsetInBytes,
        raw.lengthInBytes ~/ 4,
      );
      final n = px.length ~/ 4;
      final br = px[0], bg = px[1], bb = px[2];
      var hit = 0;
      for (var i = 0; i < n; i++) {
        final d =
            (px[i * 4] - br).abs() +
            (px[i * 4 + 1] - bg).abs() +
            (px[i * 4 + 2] - bb).abs();
        if (d > 0.06) hit++;
      }
      coverage = _r2(100.0 * hit / n);
      const ppm = String.fromEnvironment('MILION_PPM');
      if (ppm.isNotEmpty && vp.width * vp.height == n) {
        try {
          final out = BytesBuilder()
            ..add(ascii.encode('P6 ${vp.width} ${vp.height} 255\n'));
          final rgb = Uint8List(n * 3);
          for (var i = 0; i < n; i++) {
            for (var c = 0; c < 3; c++) {
              rgb[i * 3 + c] = (px[i * 4 + c].clamp(0.0, 1.0) * 255).round();
            }
          }
          out.add(rgb);
          File(ppm).writeAsBytesSync(out.takeBytes());
        } catch (e) {
          debugPrint('ppm write failed: $e');
        }
      }
    } catch (e) {
      coverage = 'capture failed: $e';
    }

    final String backend;
    if (Platform.isAndroid) {
      backend =
          'filament=OpenGL ES (thermion hard-wires OPENGL on Android); '
          'flutter compositor: see logcat "Using the Impeller rendering backend"';
    } else if (Platform.isMacOS || Platform.isIOS) {
      backend = 'filament=Metal; flutter=Impeller Metal';
    } else {
      backend = 'filament=${Platform.operatingSystem} default';
    }

    final result = <String, Object?>{
      'candidate': 'thermion',
      'package':
          'thermion_flutter 0.5.0 / thermion_dart 0.5.0 (Filament v1.69.1)',
      'platform': Platform.operatingSystem,
      'os': Platform.operatingSystemVersion,
      'release': kReleaseMode,
      'backend': backend,
      'asset': _assetPath,
      'triangles': triangles,
      'createViewerMs': _r2(createViewerMs),
      'assetReadMs': _r2(assetReadMs),
      'glbLoadMs': _r2(glbLoadMs),
      'firstFramesAfterLoadMs': _r2(firstFramesAfterLoadMs),
      'viewport': '${vp.width}x${vp.height}',
      'orbitMs': _r2(orbitMs),
      'flutterFrames': _timings.length,
      'flutterFps': _r2(_timings.length / (orbitMs / 1000)),
      'flutterBuildMs': {
        'median': _r2(_percentile(build, .5)),
        'p90': _r2(_percentile(build, .9)),
      },
      'flutterRasterMs': {
        'median': _r2(_percentile(raster, .5)),
        'p90': _r2(_percentile(raster, .9)),
      },
      'flutterTotalSpanMs': {
        'median': _r2(_percentile(totalSpan, .5)),
        'p90': _r2(_percentile(totalSpan, .9)),
      },
      'filamentFrames': _filamentFrames,
      'filamentFps': _r2(_filamentFrames / (orbitMs / 1000)),
      'filamentIntervalMs': {
        'median': _r2(_percentile(_filamentIntervalsMs, .5)),
        'p90': _r2(_percentile(_filamentIntervalsMs, .9)),
        'max': _r2(
          _filamentIntervalsMs.isEmpty
              ? double.nan
              : _filamentIntervalsMs.reduce(math.max),
        ),
      },
      'thermionRenderRoundTripAvgMs': diagAvg.map(_r2).toList(),
      'thermionDroppedVsyncs': diagDrops,
      'thermionJankOver20ms': diagJank,
      'nonBackgroundPixelPct': coverage,
      'totalMs': _r2(total.elapsedMicroseconds / 1000),
    };
    // ONE line, greppable: adb logcat -s flutter | grep MILION_SPIKE
    debugPrint('MILION_SPIKE ${jsonEncode(result)}');
    if (mounted) setState(() => _status = 'done (see log)');
    if (asset.entity < 0) debugPrint('unexpected entity');
    if (_exitWhenDone) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      exit(0);
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewer = _viewer;
    return Stack(
      children: [
        Positioned.fill(
          child: viewer == null
              ? const ColoredBox(color: Color(0xFFE8E4DC))
              : ThermionWidget(viewer: viewer),
        ),
        Positioned(
          left: 16,
          top: 48,
          child: Text(
            'thermion spike: $_status  f=$_hudTick',
            style: const TextStyle(color: Color(0xFF202020), fontSize: 14),
          ),
        ),
      ],
    );
  }
}
