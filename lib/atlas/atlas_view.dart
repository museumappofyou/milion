import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

/// Where the Atlas looks: a centre in metres east/north of the Milion, a
/// scale in logical pixels per metre and a rotation (radians, clockwise on
/// screen). North is up at rotation 0; y grows north in metres and down on
/// screen, so the transform flips it.
class AtlasView {
  const AtlasView({
    required this.center,
    required this.scale,
    this.rotation = 0,
  });
  final Offset center;
  final double scale;
  final double rotation;

  /// From a whole-province view to about 0.25 m per pixel.
  static const minScale = 1 / 600, maxScale = 4.0;

  /// The historic peninsula filling a phone, the Milion a little below centre.
  static const peninsula = AtlasView(
    center: Offset(-2400, 1400),
    scale: 390 / 8200,
  );

  double get metresPerPixel => 1 / scale;

  Offset toScreen(Offset m, Size size) {
    final dx = (m.dx - center.dx) * scale, dy = -(m.dy - center.dy) * scale;
    final c = math.cos(rotation), s = math.sin(rotation);
    return Offset(
      size.width / 2 + dx * c - dy * s,
      size.height / 2 + dx * s + dy * c,
    );
  }

  Offset toWorld(Offset p, Size size) {
    final dx = p.dx - size.width / 2, dy = p.dy - size.height / 2;
    final c = math.cos(rotation), s = math.sin(rotation);
    final ux = dx * c + dy * s, uy = -dx * s + dy * c;
    return Offset(center.dx + ux / scale, center.dy - uy / scale);
  }

  /// World-to-screen as a canvas matrix (column-major 4×4).
  Float64List matrix(Size size) {
    final c = math.cos(rotation), s = math.sin(rotation);
    final a = scale * c, b = scale * s; // x axis
    final cc = scale * s, d = -scale * c; // y axis (flipped)
    // screen.x = a*x + cc*y + tx ; screen.y = b*x + d*y + ty (as toScreen)
    final tx = size.width / 2 - (a * center.dx + cc * center.dy);
    final ty = size.height / 2 - (b * center.dx + d * center.dy);
    return Float64List.fromList([
      a, b, 0, 0, //
      cc, d, 0, 0, //
      0, 0, 1, 0, //
      tx, ty, 0, 1,
    ]);
  }

  /// The world rectangle covering the screen at any rotation.
  Rect visibleWorld(Size size) {
    final corners = [
      toWorld(Offset.zero, size),
      toWorld(Offset(size.width, 0), size),
      toWorld(Offset(0, size.height), size),
      toWorld(Offset(size.width, size.height), size),
    ];
    var r = Rect.fromPoints(corners[0], corners[1]);
    for (final p in corners.skip(2)) {
      r = r.expandToInclude(Rect.fromLTWH(p.dx, p.dy, 0, 0));
    }
    return r;
  }

  AtlasView copyWith({Offset? center, double? scale, double? rotation}) =>
      AtlasView(
        center: center ?? this.center,
        scale: scale ?? this.scale,
        rotation: rotation ?? this.rotation,
      );

  /// Drag by a screen delta.
  AtlasView panBy(Offset delta) {
    final c = math.cos(rotation), s = math.sin(rotation);
    final ux = delta.dx * c + delta.dy * s, uy = -delta.dx * s + delta.dy * c;
    return copyWith(center: center - Offset(ux / scale, -uy / scale));
  }

  /// Zoom by [factor] and rotate by [turn] keeping [focal] (screen) fixed.
  AtlasView transformAround(
    Offset focal,
    Size size, {
    double factor = 1,
    double turn = 0,
  }) {
    final anchor = toWorld(focal, size);
    final next = copyWith(
      scale: (scale * factor).clamp(minScale, maxScale),
      rotation: rotation + turn,
    );
    final moved = next.toWorld(focal, size);
    return next.copyWith(center: next.center + (anchor - moved));
  }

  /// The centre kept inside [bounds] (metres).
  AtlasView clampTo(Rect bounds) => copyWith(
    center: Offset(
      center.dx.clamp(bounds.left, bounds.right),
      center.dy.clamp(bounds.top, bounds.bottom),
    ),
    scale: scale.clamp(minScale, maxScale),
  );

  static AtlasView lerp(AtlasView a, AtlasView b, double t) {
    var turn = (b.rotation - a.rotation) % (2 * math.pi);
    if (turn > math.pi) turn -= 2 * math.pi;
    return AtlasView(
      center: Offset.lerp(a.center, b.center, t)!,
      scale: math.exp(
        math.log(a.scale) + (math.log(b.scale) - math.log(a.scale)) * t,
      ),
      rotation: a.rotation + turn * t,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AtlasView &&
      other.center == center &&
      other.scale == scale &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(center, scale, rotation);
}
