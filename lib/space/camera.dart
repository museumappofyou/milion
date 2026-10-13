import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'model.dart';

enum SpaceProjection { axonometric, perspective }

const _degree = math.pi / 180;

/// An orbit camera around a target, in the building's own frame (Z up).
/// [azimuth] is the compass direction from the target to the camera,
/// anticlockwise from east; a negative [elevation] looks up from below.
@immutable
class SpaceView {
  const SpaceView({
    this.azimuth = 225 * _degree,
    this.elevation = 30 * _degree,
    this.zoom = 1,
    this.targetX = 0,
    this.targetY = 0,
    this.targetZ = 0,
    this.projection = SpaceProjection.axonometric,
  });
  final double azimuth, elevation, zoom, targetX, targetY, targetZ;
  final SpaceProjection projection;

  /// Choisy's worm's-eye axonometric: the bay seen from below at the
  /// isometric angle (35.26°), from the south-west.
  static const choisyElevation = -35.26 * _degree;
  factory SpaceView.choisy(SpaceBounds b) => SpaceView(
    elevation: choisyElevation,
    targetX: b.centerX,
    targetY: b.centerY,
    targetZ: b.centerZ,
  );

  SpaceView copyWith({
    double? azimuth,
    double? elevation,
    double? zoom,
    double? targetX,
    double? targetY,
    double? targetZ,
    SpaceProjection? projection,
  }) => SpaceView(
    azimuth: azimuth ?? this.azimuth,
    elevation: elevation ?? this.elevation,
    zoom: zoom ?? this.zoom,
    targetX: targetX ?? this.targetX,
    targetY: targetY ?? this.targetY,
    targetZ: targetZ ?? this.targetZ,
    projection: projection ?? this.projection,
  );

  SpaceView orbit(double dAzimuth, double dElevation) =>
      copyWith(azimuth: azimuth + dAzimuth, elevation: elevation + dElevation);

  static SpaceView lerp(SpaceView a, SpaceView b, double t) {
    var turn = (b.azimuth - a.azimuth) % (2 * math.pi);
    if (turn > math.pi) turn -= 2 * math.pi;
    double mix(double x, double y) => x + (y - x) * t;
    return SpaceView(
      azimuth: a.azimuth + turn * t,
      elevation: mix(a.elevation, b.elevation),
      zoom: math.exp(mix(math.log(a.zoom), math.log(b.zoom))),
      targetX: mix(a.targetX, b.targetX),
      targetY: mix(a.targetY, b.targetY),
      targetZ: mix(a.targetZ, b.targetZ),
      projection: t < .5 ? a.projection : b.projection,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SpaceView &&
      other.azimuth == azimuth &&
      other.elevation == elevation &&
      other.zoom == zoom &&
      other.targetX == targetX &&
      other.targetY == targetY &&
      other.targetZ == targetZ &&
      other.projection == projection;
  @override
  int get hashCode => Object.hash(
    azimuth,
    elevation,
    zoom,
    targetX,
    targetY,
    targetZ,
    projection,
  );
}

/// The camera may look up from below (Choisy) but never through the zenith,
/// and the target stays inside the model's bounds.
class SpaceLimits {
  const SpaceLimits(
    this.bounds, {
    this.minElevation = -70 * _degree,
    this.maxElevation = 85 * _degree,
    this.minZoom = .6,
    this.maxZoom = 6,
  });
  final SpaceBounds bounds;
  final double minElevation, maxElevation, minZoom, maxZoom;

  SpaceView clamp(SpaceView v) {
    double finite(double x, double fallback) => x.isFinite ? x : fallback;
    final azimuth = finite(v.azimuth, 0) % (2 * math.pi);
    return v.copyWith(
      azimuth: azimuth < 0 ? azimuth + 2 * math.pi : azimuth,
      elevation: finite(v.elevation, 0).clamp(minElevation, maxElevation),
      zoom: finite(v.zoom, 1).clamp(minZoom, maxZoom),
      targetX: finite(
        v.targetX,
        bounds.centerX,
      ).clamp(bounds.minX, bounds.maxX),
      targetY: finite(
        v.targetY,
        bounds.centerY,
      ).clamp(bounds.minY, bounds.maxY),
      targetZ: finite(
        v.targetZ,
        bounds.centerZ,
      ).clamp(bounds.minZ, bounds.maxZ),
    );
  }
}

/// World → screen for one frame. Depth grows away from the camera.
class SpaceProjector {
  SpaceProjector(this.view, this.size, SpaceBounds bounds) {
    final ce = math.cos(view.elevation), se = math.sin(view.elevation);
    final ca = math.cos(view.azimuth), sa = math.sin(view.azimuth);
    // Forward points from the camera to the target.
    fx = -ce * ca;
    fy = -ce * sa;
    fz = -se;
    // Right = forward × Z, normalised (|forward × Z| = cos elevation).
    rx = fy / ce;
    ry = -fx / ce;
    rz = 0;
    ux = ry * fz - rz * fy;
    uy = rz * fx - rx * fz;
    uz = rx * fy - ry * fx;
    cx = size.width / 2;
    cy = size.height / 2;
    final fit = math.min(size.width, size.height) * .66 / bounds.radius;
    if (axonometric) {
      scale = fit * view.zoom;
    } else {
      final distance = bounds.radius / math.sin(fov / 2) / view.zoom;
      ex = view.targetX - fx * distance;
      ey = view.targetY - fy * distance;
      ez = view.targetZ - fz * distance;
      focal = math.min(size.width, size.height) / 2 / math.tan(fov / 2);
      scale = focal / distance;
    }
  }
  final SpaceView view;
  final Size size;
  static const fov = 40 * _degree, near = .5;
  late final double rx, ry, rz, ux, uy, uz, fx, fy, fz, cx, cy;
  late final double scale;
  double ex = 0, ey = 0, ez = 0, focal = 0;
  bool get axonometric => view.projection == SpaceProjection.axonometric;

  /// Screen pixels per metre at the target.
  double get pixelsPerMetre => scale;

  /// Writes screen x, y and depth at out[o..o+2]; depth is NaN behind the
  /// near plane of a perspective camera.
  @pragma('vm:prefer-inline')
  void project(double x, double y, double z, Float32List out, int o) {
    if (axonometric) {
      final dx = x - view.targetX, dy = y - view.targetY, dz = z - view.targetZ;
      out[o] = cx + scale * (dx * rx + dy * ry + dz * rz);
      out[o + 1] = cy - scale * (dx * ux + dy * uy + dz * uz);
      out[o + 2] = dx * fx + dy * fy + dz * fz;
    } else {
      final dx = x - ex, dy = y - ey, dz = z - ez;
      final depth = dx * fx + dy * fy + dz * fz;
      if (depth < near) {
        out[o + 2] = double.nan;
        return;
      }
      final k = focal / depth;
      out[o] = cx + k * (dx * rx + dy * ry + dz * rz);
      out[o + 1] = cy - k * (dx * ux + dy * uy + dz * uz);
      out[o + 2] = depth;
    }
  }

  final _one = Float32List(3);
  Offset toScreen(double x, double y, double z) {
    project(x, y, z, _one, 0);
    return Offset(_one[0], _one[1]);
  }

  /// Where a unit step along a world direction moves on screen, at the
  /// target (the section handle drags along this).
  Offset screenDirection(double dx, double dy, double dz) => Offset(
    scale * (dx * rx + dy * ry + dz * rz),
    -scale * (dx * ux + dy * uy + dz * uz),
  );

  /// Moves the target so the scene follows a finger by [delta] pixels.
  SpaceView pan(Offset delta) {
    final k = 1 / scale;
    return view.copyWith(
      targetX: view.targetX - k * (delta.dx * rx - delta.dy * ux),
      targetY: view.targetY - k * (delta.dx * ry - delta.dy * uy),
      targetZ: view.targetZ - k * (delta.dx * rz - delta.dy * uz),
    );
  }
}
