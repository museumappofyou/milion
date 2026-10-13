// P08 spike, candidate (a) on a device: the Canvas renderer orbiting for 10 s
// per case, measured with Flutter's own frame timings.
//   (bench build only: list studio/spikes/p08/bench-50k.glb under
//    flutter: assets: in pubspec.yaml, build, then revert)
//   flutter build apk --profile --split-per-abi \
//     --target-platform android-arm64 -t tool/space/device_bench.dart
//   adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-profile.apk
//   adb shell am start -n app.milion/.MainActivity
//   adb logcat -d -s flutter | grep MILION_SPIKE
// Prints one `MILION_SPIKE {json}` line when all cases have run.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:milion/space/camera.dart';
import 'package:milion/space/model.dart';
import 'package:milion/space/renderer.dart';
import 'package:milion/space/style.dart';

const benchPath =
    '/storage/emulated/0/Android/data/app.milion/files/bench-50k.glb';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: _Bench()));
}

class _Case {
  const _Case(this.name, this.model, this.style, this.section);
  final String name;
  final SpaceModel model;
  final SpaceStyle style;
  final SpaceSection? section;
}

class _Bench extends StatefulWidget {
  const _Bench();
  @override
  State<_Bench> createState() => _BenchState();
}

class _BenchState extends State<_Bench> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _timings = <FrameTiming>[];
  final _cpu = <int>[], _geometry = <int>[], _sort = <int>[];
  final _write = <int>[], _draw = <int>[];
  final _results = <String, Object>{};
  final _cases = <_Case>[];
  SpaceRenderer? _renderer;
  int _index = -1;
  double _t = 0;
  Duration _start = Duration.zero;
  String _status = 'loading';

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timings.addAll);
    _load();
  }

  Future<void> _load() async {
    final watch = Stopwatch()..start();
    final study = SpaceModel.fromGlb(
      await rootBundle.load('assets/space/how-a-dome-stands/model.glb'),
    );
    _results['studyLoadMs'] = watch.elapsedMicroseconds / 1000;
    const cut = SpaceSection(2, 3);
    // A fixed order: on the A52s the clock the governor settles at, not the
    // code, set most of the variation between runs (P08).
    _cases.addAll([
      _Case('study-drawing-cut', study, SpaceStyle.drawing, cut),
      _Case('study-drawing', study, SpaceStyle.drawing, null),
      _Case('study-stone-cut', study, SpaceStyle.stone, cut),
      _Case('study-night-cut', study, SpaceStyle.night, cut),
    ]);
    // The 50k model: bundled into a bench-only build (see the header), else
    // read from the app's external files.
    ByteData? bytes;
    try {
      bytes = await rootBundle.load('studio/spikes/p08/bench-50k.glb');
    } catch (_) {
      final file = File(benchPath);
      if (file.existsSync()) {
        bytes = (await file.readAsBytes()).buffer.asByteData();
      }
    }
    if (bytes != null) {
      watch.reset();
      final bench = SpaceModel.fromGlb(bytes);
      _results['benchLoadMs'] = watch.elapsedMicroseconds / 1000;
      _results['benchTriangles'] = bench.triangleCount;
      _cases.add(_Case('bench50k-drawing-cut', bench, SpaceStyle.drawing, cut));
    } else {
      _results['bench'] = 'missing: push bench-50k.glb to $benchPath';
    }
    _next();
  }

  void _next() {
    if (_index >= 0) _summarise(_cases[_index]);
    _index++;
    _renderer?.dispose();
    if (_index >= _cases.length) {
      _ticker.stop();
      // One line per case: logcat truncates long lines.
      for (final entry in _results.entries) {
        debugPrint('MILION_SPIKE ${jsonEncode({entry.key: entry.value})}');
      }
      debugPrint('MILION_SPIKE_DONE');
      setState(() => _status = 'done');
      return;
    }
    _renderer = SpaceRenderer(_cases[_index].model);
    _timings.clear();
    _cpu.clear();
    _geometry.clear();
    _sort.clear();
    _write.clear();
    _draw.clear();
    _start = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
    setState(() => _status = _cases[_index].name);
  }

  void _tick(Duration elapsed) {
    if (_start == Duration.zero) _start = elapsed;
    final seconds = (elapsed - _start).inMicroseconds / 1e6;
    if (seconds > 10.5) {
      _next();
      return;
    }
    setState(() => _t = seconds);
  }

  void _summarise(_Case c) {
    // Skip the first half-second (shader and buffer warm-up).
    final frames = _timings.skip(30).toList();
    double q(List<double> xs, double p) {
      if (xs.isEmpty) return double.nan;
      final s = [...xs]..sort();
      return s[((s.length - 1) * p).round()];
    }

    final build = [
      for (final f in frames) f.buildDuration.inMicroseconds / 1000,
    ];
    final raster = [
      for (final f in frames) f.rasterDuration.inMicroseconds / 1000,
    ];
    final total = [for (final f in frames) f.totalSpan.inMicroseconds / 1000];
    final cpu = [for (final m in _cpu.skip(30)) m / 1000];
    final geometry = [for (final m in _geometry.skip(30)) m / 1000];
    final sort = [for (final m in _sort.skip(30)) m / 1000];
    final write = [for (final m in _write.skip(30)) m / 1000];
    final draw = [for (final m in _draw.skip(30)) m / 1000];
    final span = frames.isEmpty
        ? 0
        : (frames.last.timestampInMicroseconds(ui.FramePhase.rasterFinish) -
                  frames.first.timestampInMicroseconds(
                    ui.FramePhase.vsyncStart,
                  )) /
              1e6;
    String r(double v) => v.toStringAsFixed(2);
    _results[c.name] = {
      'frames': frames.length,
      'fps': span > 0 ? r(frames.length / span) : 'n/a',
      'buildMedianMs': r(q(build, .5)),
      'buildP90Ms': r(q(build, .9)),
      'rasterMedianMs': r(q(raster, .5)),
      'rasterP90Ms': r(q(raster, .9)),
      'totalP90Ms': r(q(total, .9)),
      'rendererCpuMedianMs': r(q(cpu, .5)),
      'rendererCpuP90Ms': r(q(cpu, .9)),
      'rendererCpuMaxMs': r(q(cpu, 1)),
      'geometryMedianMs': r(q(geometry, .5)),
      'geometryP90Ms': r(q(geometry, .9)),
      'sortGatherMedianMs': r(q(sort, .5)),
      'sortGatherP90Ms': r(q(sort, .9)),
      'writeMedianMs': r(q(write, .5)),
      'writeP90Ms': r(q(write, .9)),
      'drawMedianMs': r(q(draw, .5)),
      'drawP90Ms': r(q(draw, .9)),
      'triangles': _renderer?.stats.triangles,
      'over20ms': total.where((t) => t > 20).length,
    };
  }

  @override
  void dispose() {
    _ticker.dispose();
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = _index, renderer = _renderer;
    return Scaffold(
      body: Stack(
        children: [
          if (renderer != null && i >= 0 && i < _cases.length)
            Positioned.fill(
              child: CustomPaint(
                painter: _Painter(renderer, _cases[i], _t, this),
              ),
            ),
          Positioned(
            left: 12,
            top: 40,
            child: Text(_status, style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter(this.renderer, this.c, this.t, this.bench);
  final SpaceRenderer renderer;
  final _Case c;
  final double t;
  final _BenchState bench;
  @override
  void paint(ui.Canvas canvas, Size size) {
    renderer.paint(
      canvas,
      size,
      SpaceScene(
        view: SpaceView.choisy(c.model.bounds).orbit(t * 2 * math.pi / 10, 0),
        style: c.style,
        parts: [for (final _ in c.model.parts) const SpacePartState()],
        section: c.section,
      ),
    );
    bench._cpu.add(renderer.stats.micros);
    bench._geometry.add(renderer.stats.geometryMicros);
    bench._sort.add(renderer.stats.sortMicros);
    bench._write.add(renderer.stats.writeMicros);
    bench._draw.add(renderer.stats.drawMicros);
  }

  @override
  bool shouldRepaint(_Painter old) => true;
}
