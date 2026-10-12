import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content/models.dart';
import 'assets.dart';
import 'controller.dart';
import 'manifest.dart';

typedef RotationStream = Stream<List<double>> Function();

/// A view direction in the world frame (Z up): azimuth from +X towards +Y.
@immutable
class LookAngles {
  const LookAngles(this.azimuth, this.elevation);
  final double azimuth, elevation;
}

/// Camera basis for shaders/lookup.frag.
@immutable
class LookBasis {
  const LookBasis(this.forward, this.up, this.right);
  final List<double> forward, up, right;

  /// Screen up points at the zenith, so the ancestors stand upright.
  factory LookBasis.angles(LookAngles a) {
    final ce = math.cos(a.elevation), se = math.sin(a.elevation);
    final ca = math.cos(a.azimuth), sa = math.sin(a.azimuth);
    final f = [ce * ca, ce * sa, se];
    final u = [-se * ca, -se * sa, ce];
    return LookBasis(f, u, _cross(f, u));
  }

  /// Device-to-world rotation (row-major): the view leaves the back of the
  /// phone (-Z), screen up is +Y and right is +X. [heading] re-centres the
  /// arbitrary game-rotation azimuth.
  factory LookBasis.device(List<double> m, double heading) {
    List<double> column(int c, double sign) {
      final x = m[c] * sign, y = m[3 + c] * sign, z = m[6 + c] * sign;
      final ch = math.cos(-heading), sh = math.sin(-heading);
      return [x * ch - y * sh, x * sh + y * ch, z];
    }

    return LookBasis(column(2, -1), column(1, 1), column(0, 1));
  }

  /// Azimuth from the forward minus up horizontals, which never vanishes for
  /// views at or above the horizon, so it holds at the zenith too.
  LookAngles get angles => LookAngles(
    math.atan2(forward[1] - up[1], forward[0] - up[0]),
    math.asin(forward[2].clamp(-1.0, 1.0)),
  );
}

List<double> _cross(List<double> a, List<double> b) => [
  a[1] * b[2] - a[2] * b[1],
  a[2] * b[0] - a[0] * b[2],
  a[0] * b[1] - a[1] * b[0],
];

/// The lens model of [PlateLookUp], shared by the story and the tests.
/// Offsets are in image-width units (v scaled by the [aspect] W/H).
extension LookUpProjection on PlateLookUp {
  /// tan of the rim's zenith angle: distance in the photograph grows with
  /// tan(zenith angle), as through an ordinary lens.
  double get _rim => math.tan(math.pi / 2 - rimElevation * math.pi / 180);

  /// Distance from the crown to the rim ellipse along unit direction (x, y),
  /// the positive root of |crown + s·dir − rimCenter| = 1 in ellipse units.
  double rimDistance(double x, double y, double aspect) {
    final a = rimRadii[0], b = rimRadii[1];
    final px = (center[0] - rimCenter[0]) / a;
    final py = (center[1] - rimCenter[1]) / aspect / b;
    final dx = x / a, dy = y / b;
    final qa = dx * dx + dy * dy, qb = 2 * (px * dx + py * dy);
    final qc = px * px + py * py - 1;
    return (-qb + math.sqrt(qb * qb - 4 * qa * qc)) / (2 * qa);
  }

  /// Where a point of the photograph ([u], [v] in 0..1) sits overhead.
  LookAngles anglesAt(double u, double v, double aspect) {
    final ox = u - center[0], oy = (v - center[1]) / aspect;
    final d = math.sqrt(ox * ox + oy * oy);
    if (d < 1e-12) return const LookAngles(-math.pi / 2, math.pi / 2);
    final r = rimDistance(ox / d, oy / d, aspect);
    return LookAngles(
      math.atan2(-oy, -ox),
      math.pi / 2 - math.atan(d / r * _rim),
    );
  }

  /// The inverse of [anglesAt].
  Offset uvAt(LookAngles a, double aspect) {
    final x = -math.cos(a.azimuth), y = -math.sin(a.azimuth);
    final d =
        math.tan(math.pi / 2 - a.elevation) / _rim * rimDistance(x, y, aspect);
    return Offset(center[0] + x * d, center[1] + y * d * aspect);
  }
}

/// LU orientation: the rotation-vector sensor after an explicit opt-in,
/// otherwise a flat pan with a finger. Looking up starts at the zenith with
/// the photograph's top (+Y) at the top of the screen, i.e. facing azimuth
/// -pi/2 with the head tipped back.
class PlateOrientation extends ChangeNotifier {
  PlateOrientation({RotationStream? events}) : _events = events ?? _platform;
  static const _channel = EventChannel('milion/rotation');
  static Stream<List<double>> _platform() => _channel
      .receiveBroadcastStream()
      .map((e) => (e as List).cast<num>().map((n) => n.toDouble()).toList());
  final RotationStream _events;
  StreamSubscription<List<double>>? _subscription;
  bool enabled = false, unavailable = false, _active = true, _disposed = false;
  static const home = LookAngles(-math.pi / 2, math.pi / 2);
  LookAngles _manual = home;
  double _fovAtGesture = 42 * math.pi / 180;
  List<double>? _matrix;
  double? _heading;

  /// About what a phone held overhead covers: the 3.74 m dome, ~30° across
  /// from the floor, does not fit at once, so you look around to meet it.
  double fov = 42 * math.pi / 180;
  static const minFov = 20 * math.pi / 180, maxFov = 90 * math.pi / 180;
  bool get subscribed => _subscription != null;

  LookBasis get basis {
    final m = _matrix;
    if (enabled && m != null) return LookBasis.device(m, _heading ?? 0);
    return LookBasis.angles(_manual);
  }

  void setEnabled(bool value) {
    enabled = value;
    unavailable = false;
    _heading = null;
    _matrix = null;
    if (enabled && _active) {
      _start();
    } else {
      _stop();
    }
    notifyListeners();
  }

  void _start() {
    if (_disposed || _subscription != null) return;
    try {
      _subscription = _events().listen(accept, onError: (Object _) => _fail());
    } catch (_) {
      _fail();
    }
  }

  void _fail() {
    if (_disposed) return;
    unavailable = true;
    enabled = false;
    _stop();
    notifyListeners();
  }

  void _stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void accept(List<double> m) {
    if (_disposed || !enabled || !_active || m.length != 9) return;
    if (m.any((v) => !v.isFinite)) return;
    _matrix = m;
    // The first reading becomes [home]'s heading, however the phone is held.
    _heading ??= LookBasis.device(m, 0).angles.azimuth - home.azimuth;
    notifyListeners();
  }

  /// Continue by hand from wherever the story or the sensor was looking.
  void lookAt(LookAngles a) {
    _manual = LookAngles(
      a.azimuth,
      a.elevation.clamp(-math.pi / 6, math.pi / 2),
    );
    notifyListeners();
  }

  /// Flat pan: the dome follows the finger.
  void pan(Offset delta, Size viewport) {
    if (_disposed || viewport.height <= 0) return;
    final k = fov / viewport.height;
    _manual = LookAngles(
      _manual.azimuth + delta.dx * k,
      (_manual.elevation + delta.dy * k).clamp(-math.pi / 6, math.pi / 2),
    );
    if (enabled) setEnabled(false);
    notifyListeners();
  }

  void beginZoom() => _fovAtGesture = fov;

  /// [scale] is cumulative since [beginZoom], as a pinch reports it.
  void zoom(double scale) {
    if (scale <= 0 || !scale.isFinite) return;
    fov = (_fovAtGesture / scale).clamp(minFov, maxFov);
    notifyListeners();
  }

  void recenter() {
    _manual = home;
    _heading = null;
    if (!_disposed) notifyListeners();
  }

  void suspend() {
    _active = false;
    _stop();
  }

  void resume() {
    _active = true;
    if (enabled) _start();
  }

  @override
  void dispose() {
    _disposed = true;
    _stop();
    super.dispose();
  }
}

/// Where the story looks: each beat faces its window. Near the crown the
/// azimuth eases to [PlateOrientation.home] so the view stays upright instead
/// of taking the roll of a near-zero offset. The reveal is the hook, so it
/// moves: from the crown down to the beat's ring while turning a third of the
/// way round. Null outside the story.
LookBasis? storyLook(PlateManifest manifest, PlateController controller) {
  final sample = controller.sample, dome = manifest.lookUp;
  if (sample == null || dome == null) return null;
  final w = sample.window;
  var a = dome.anglesAt(
    (w.left + w.right) / 2,
    (w.top + w.bottom) / 2,
    manifest.width / manifest.height,
  );
  if (controller.reveal) {
    final ring = dome.anglesAt(
      dome.center[0],
      dome.center[1] +
          .45 * dome.rimRadii[1] * manifest.width / manifest.height,
      manifest.width / manifest.height,
    );
    final x = (controller.seconds / manifest.revealSeconds).clamp(0.0, 1.0);
    final t = x * x * (3 - 2 * x);
    a = LookAngles(
      PlateOrientation.home.azimuth + t * 2 * math.pi / 3,
      a.elevation + (ring.elevation - a.elevation) * t,
    );
  }
  final zenith = math.pi / 2 - a.elevation;
  final k = ((zenith - math.pi / 180) / (3 * math.pi / 180)).clamp(0.0, 1.0);
  var delta = a.azimuth - PlateOrientation.home.azimuth;
  delta = math.atan2(math.sin(delta), math.cos(delta));
  return LookBasis.angles(
    LookAngles(PlateOrientation.home.azimuth + delta * k, a.elevation),
  );
}

/// The dome, overhead. During the story the camera turns to face each beat's
/// window; otherwise the sensor or the finger steers it.
class PlateLookUpView extends StatelessWidget {
  const PlateLookUpView({
    super.key,
    required this.assets,
    required this.manifest,
    required this.controller,
    required this.orientation,
  });
  final PlateAssets assets;
  final PlateManifest manifest;
  final PlateController controller;
  final PlateOrientation orientation;

  LookBasis _basis() => storyLook(manifest, controller) ?? orientation.basis;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      return GestureDetector(
        key: const ValueKey('plate-look-up'),
        onScaleStart: (_) {
          if (controller.storyActive) orientation.lookAt(_basis().angles);
          controller.explore();
          orientation.beginZoom();
        },
        onScaleUpdate: (d) {
          if (d.pointerCount > 1) {
            orientation.zoom(d.scale);
          } else {
            orientation.pan(d.focalPointDelta, size);
          }
        },
        onDoubleTap: orientation.recenter,
        child: ListenableBuilder(
          listenable: Listenable.merge([controller, orientation]),
          builder: (context, _) => CustomPaint(
            size: size,
            painter: LookUpPainter(
              assets: assets,
              manifest: manifest,
              basis: _basis(),
              fov: orientation.fov,
              gilded: controller.visibleLight == PlateLight.gilded,
            ),
          ),
        ),
      );
    },
  );
}

class LookUpPainter extends CustomPainter {
  LookUpPainter({
    required this.assets,
    required this.manifest,
    required this.basis,
    required this.fov,
    required this.gilded,
  });
  final PlateAssets assets;
  final PlateManifest manifest;
  final LookBasis basis;
  final double fov;
  final bool gilded;

  @override
  void paint(Canvas canvas, Size size) {
    final spec = manifest.lookUp;
    if (assets.disposed || spec == null || size.isEmpty) return;
    final shader = assets.shader(0, asset: PlateAssets.lookUpShader);
    final floats = [
      size.width,
      size.height,
      ...basis.forward,
      ...basis.up,
      ...basis.right,
      math.tan(fov / 2),
      spec.center[0],
      spec.center[1],
      spec.rimCenter[0],
      spec.rimCenter[1],
      spec.rimRadii[0],
      spec.rimRadii[1],
      spec.rimElevation * math.pi / 180,
      manifest.width.toDouble(),
      manifest.height.toDouble(),
      gilded ? 1.0 : 0.0,
    ];
    for (var i = 0; i < floats.length; i++) {
      shader.setFloat(i, floats[i]);
    }
    shader.setImageSampler(
      0,
      assets.images[manifest.depthAsset]!,
      filterQuality: FilterQuality.medium,
    );
    shader.setImageSampler(
      1,
      assets.images[manifest.maps.surface]!,
      filterQuality: FilterQuality.low,
    );
    shader.setImageSampler(
      2,
      assets.images[manifest.maps.gold]!,
      filterQuality: FilterQuality.low,
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(LookUpPainter old) =>
      old.basis != basis ||
      old.fov != fov ||
      old.gilded != gilded ||
      old.assets != assets;
}

/// TalkBack and reduced motion read the look-up as the beat's still.
NormalRect lookUpWindow(PlateController c) =>
    c.sample?.window ?? const NormalRect(0, 0, 1, 1);
