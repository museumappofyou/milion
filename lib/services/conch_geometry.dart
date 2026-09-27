import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

/// Pure-Dart geometry for the Anastasis 2.5D reconstruction.
///
/// The Anastasis is painted on the semi-dome (conch) of the Parekklesion apse:
/// the inside of a quarter sphere rising from the springing line to the crown
/// of the apse arch. A flat photograph of that surface compresses the field
/// towards its left and right ends and hides the depth of the bowl.
///
/// This model puts the panel back on the conch:
///
///  * the outer edge of the painted panel was traced on the reference capture
///    ([anastasisFieldOutline]); within that outline a texel's position is
///    unwrapped linearly across the panel's azimuth and elevation on the
///    semi-dome;
///  * the panel spans a fixed angular window of the conch ([ConchParams.thetaPanelDeg],
///    [ConchParams.alphaTopDeg], [ConchParams.alphaBottomDeg]), so the curl of
///    the surface, the parallax under a moving viewpoint, and the lunette
///    silhouette all follow from the geometry rather than from the image;
///  * the viewer orbits a solved default viewpoint; because panel and camera
///    scale together with [ConchParams.radius], the curvature control changes
///    the depth of the bowl without changing the framing.
///
/// The unwrap is an approximation: a single photograph cannot fix the true
/// relief of the painted surface, and the panel edge is traced by hand. The
/// artifact tab states this; the tests pin the geometry invariants.
///
/// All lengths are in conch radii ([ConchParams.radius] = 1 for the reference
/// semi-dome). Apart from [Offset]/[Size]/[Rect] this file is plain Dart, so
/// the offline renderer and the tests use exactly the app's math.

/// The outer edge of the painted Anastasis panel, traced on the reference
/// capture and given in normalized photograph coordinates. Texels outside it
/// belong to the surrounding vault, arch and cornice and are never painted
/// onto the conch. The list starts at the top and runs down the left side.
const List<Offset> anastasisFieldOutline = [
  Offset(0.500, 0.046),
  Offset(0.300, 0.075),
  Offset(0.150, 0.170),
  Offset(0.060, 0.300),
  Offset(0.024, 0.430),
  Offset(0.060, 0.560),
  Offset(0.170, 0.700),
  Offset(0.300, 0.800),
  Offset(0.430, 0.870),
  Offset(0.500, 0.886),
  Offset(0.570, 0.870),
  Offset(0.700, 0.800),
  Offset(0.830, 0.685),
  Offset(0.940, 0.560),
  Offset(0.988, 0.420),
  Offset(0.940, 0.290),
  Offset(0.840, 0.160),
  Offset(0.700, 0.080),
];

class Vec3 {
  const Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  static const Vec3 zero = Vec3(0, 0, 0);

  Vec3 operator +(Vec3 other) => Vec3(x + other.x, y + other.y, z + other.z);
  Vec3 operator -(Vec3 other) => Vec3(x - other.x, y - other.y, z - other.z);
  Vec3 operator *(double f) => Vec3(x * f, y * f, z * f);
  Vec3 operator -() => Vec3(-x, -y, -z);

  double dot(Vec3 other) => x * other.x + y * other.y + z * other.z;
  Vec3 cross(Vec3 other) => Vec3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  double get length => math.sqrt(x * x + y * y + z * z);
  Vec3 get normalized {
    final l = length;
    return l == 0 ? this : Vec3(x / l, y / l, z / l);
  }

  @override
  String toString() =>
      '(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, '
      '${z.toStringAsFixed(3)})';
}

/// Parameters of the reconstruction. The defaults are the reference
/// semi-dome: a quarter sphere whose painted panel spans most of the conch.
class ConchParams {
  const ConchParams({
    this.radius = 1.0,
    this.thetaPanelDeg = 78.0,
    this.alphaTopDeg = 60.0,
    this.alphaBottomDeg = 2.0,
    this.cameraY = -0.55,
    this.cameraZ = 3.10,
    this.viewFill = 0.94,
    this.ambient = 0.74,
    this.relief = 0.30,
    this.grazing = 0.08,
  });

  /// Semi-dome radius, in units of the reference conch.
  ///
  /// This is what the tab's curvature control changes: 1.0 is the semi-dome
  /// read off the reference material, smaller values are a tighter apse with
  /// stronger curvature and parallax, larger values flatten it. The capture
  /// camera scales with the radius so the framing stays put.
  final double radius;

  /// Azimuthal half-extent of the painted panel on the conch: how far around
  /// the apse the Anastasis reaches from its central meridian.
  final double thetaPanelDeg;

  /// Elevation of the painted panel's top and bottom edges above the
  /// springing plane, in degrees.
  final double alphaTopDeg;
  final double alphaBottomDeg;

  /// Default viewpoint: height below the springing plane and distance in
  /// front of the mouth plane, in radii. The in-situ photographs show a
  /// visitor standing on the floor a little off the apse axis.
  final double cameraY;
  final double cameraZ;

  /// Fraction of the viewer width the panel occupies at the default
  /// viewpoint.
  final double viewFill;

  /// Shading: base level and Lambert strength. The reference photographs carry
  /// their own painted light, so this stays subtle; it only re-reads the
  /// curvature.
  final double ambient;
  final double relief;

  /// Cosine between the inward surface normal and the view direction below
  /// which a texel is dropped (grazing limb).
  final double grazing;

  double get thetaPanel => thetaPanelDeg * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      other is ConchParams &&
      other.radius == radius &&
      other.thetaPanelDeg == thetaPanelDeg &&
      other.alphaTopDeg == alphaTopDeg &&
      other.alphaBottomDeg == alphaBottomDeg &&
      other.cameraY == cameraY &&
      other.cameraZ == cameraZ &&
      other.viewFill == viewFill &&
      other.ambient == ambient &&
      other.relief == relief &&
      other.grazing == grazing;

  @override
  int get hashCode => Object.hash(
    radius,
    thetaPanelDeg,
    alphaTopDeg,
    alphaBottomDeg,
    cameraY,
    cameraZ,
    viewFill,
    ambient,
    relief,
    grazing,
  );
  double get alphaTop => alphaTopDeg * math.pi / 180;
  double get alphaBottom => alphaBottomDeg * math.pi / 180;

  ConchParams copyWith({
    double? radius,
    double? thetaPanelDeg,
    double? alphaTopDeg,
    double? alphaBottomDeg,
    double? cameraY,
    double? cameraZ,
    double? viewFill,
    double? ambient,
    double? relief,
    double? grazing,
  }) {
    return ConchParams(
      radius: radius ?? this.radius,
      thetaPanelDeg: thetaPanelDeg ?? this.thetaPanelDeg,
      alphaTopDeg: alphaTopDeg ?? this.alphaTopDeg,
      alphaBottomDeg: alphaBottomDeg ?? this.alphaBottomDeg,
      cameraY: cameraY ?? this.cameraY,
      cameraZ: cameraZ ?? this.cameraZ,
      viewFill: viewFill ?? this.viewFill,
      ambient: ambient ?? this.ambient,
      relief: relief ?? this.relief,
      grazing: grazing ?? this.grazing,
    );
  }
}

/// A texel of the reference photograph resolved onto the conch.
class ConchTexel {
  const ConchTexel({
    required this.world,
    required this.normal,
    required this.alpha,
    required this.theta,
    required this.shade,
  });

  /// Surface point in conch space (radii).
  final Vec3 world;

  /// Inward surface normal (unit length).
  final Vec3 normal;

  /// Elevation above the springing plane, radians.
  final double alpha;

  /// Azimuth from the vertical meridian (positive towards +x), radians.
  final double theta;

  /// Shading factor to modulate the photographic colour with.
  final double shade;
}

/// A hotspot anchor in normalized reference-photograph coordinates.
class ConchAnchor {
  const ConchAnchor(this.id, this.u, this.v);

  final String id;
  final double u;
  final double v;
}

/// Orthonormal camera frame looking along [forward].
class _Frame {
  _Frame(this.position, this.forward, this.right, this.up);

  final Vec3 position;
  final Vec3 forward;
  final Vec3 right;
  final Vec3 up;

  factory _Frame.lookAlong(Vec3 position, Vec3 forward) {
    var right = forward.cross(const Vec3(0, 1, 0)).normalized;
    if (right.length < 1e-9) {
      right = const Vec3(1, 0, 0);
    }
    final up = right.cross(forward);
    return _Frame(position, forward, right, up);
  }
}

class ConchSurface {
  ConchSurface({
    required this.params,
    required this.textureSize,
    this.fieldOutline = anastasisFieldOutline,
  }) : assert(params.radius > 0),
       assert(params.thetaPanel > 0 && params.thetaPanel < math.pi / 2),
       _radius = params.radius,
       _center = Vec3.zero {
    _panelCenter = conchPoint((params.alphaTop + params.alphaBottom) / 2, 0);
    panelExtent = _extentOfOutline();
    _solveCaptureCamera();
  }

  final ConchParams params;
  final Size textureSize;

  /// Outer edge of the painted panel in normalized photograph coordinates.
  final List<Offset> fieldOutline;

  final double _radius;
  final Vec3 _center;
  late final Vec3 _panelCenter;
  late Vec3 _camera;
  late _Frame _frame;
  late double _tanHalfFov;

  static const Vec3 lightDirection = Vec3(-0.40, 0.74, 0.42);

  Vec3 get cameraPosition => _camera;
  Vec3 get panelCenter => _panelCenter;
  Vec3 get center => _center;
  double get radius => _radius;
  double get tanHalfFov => _tanHalfFov;

  /// Half horizontal field of view of the default viewpoint, in degrees.
  double get captureHalfFovDeg => math.atan(_tanHalfFov) * 180 / math.pi;

  /// Point on the conch at elevation [alpha] above the springing plane and
  /// azimuth [theta] from the vertical meridian.
  Vec3 conchPoint(double alpha, double theta) {
    return Vec3(
      _radius * math.cos(alpha) * math.sin(theta),
      _radius * math.sin(alpha),
      -_radius * math.cos(alpha) * math.cos(theta),
    );
  }

  /// Direction of the ray through normalized photograph coordinates (u, v),
  /// with (0, 0) at the image's top-left corner.
  Vec3 rayForPhoto(double u, double v) {
    final aspect = textureSize.height / textureSize.width;
    final lx = (2 * u - 1) * _tanHalfFov;
    final ly = (1 - 2 * v) * _tanHalfFov * aspect;
    return (_frame.right * lx + _frame.up * ly + _frame.forward).normalized;
  }

  /// Resolves a photograph texel onto the conch, or null when the texel lies
  /// outside the traced panel or on a grazing part of the surface.
  ///
  /// The horizontal position is normalized per scanline against the panel
  /// outline, then unwrapped linearly across the panel's azimuth; the vertical
  /// position unwraps linearly from the panel's bottom to its top edge.
  ConchTexel? texelForPhoto(double u, double v) {
    final bounds = panelExtent;
    if (v < bounds.top || v > bounds.bottom) {
      return null;
    }
    final row = _panelRowSpan(v);
    if (row == null) {
      return null;
    }
    final s = (u - row.$1) / (row.$2 - row.$1);
    if (s < 0 || s > 1) {
      return null;
    }
    final t = (v - bounds.top) / (bounds.bottom - bounds.top);
    final theta = params.thetaPanel * (2 * s - 1);
    // The top row of the photograph is the top of the panel.
    final alpha = params.alphaTop - t * (params.alphaTop - params.alphaBottom);
    final world = conchPoint(alpha, theta);
    final normal = -(world * (1 / _radius));
    final viewDir = (_camera - world).normalized;
    if (normal.dot(viewDir) < params.grazing) {
      return null;
    }
    final lambert = math.max(0.0, normal.dot(lightDirection));
    final falloff = 1 - 0.10 * math.pow(alpha / (math.pi / 2), 2).toDouble();
    final shade = (params.ambient + params.relief * lambert) * falloff;
    return ConchTexel(
      world: world,
      normal: normal,
      alpha: alpha,
      theta: theta,
      shade: shade.clamp(0.35, 1.25),
    );
  }

  /// Bounding box of the traced panel outline, cached at construction.
  late final Rect panelExtent;

  Rect _extentOfOutline() {
    var top = double.infinity, bottom = double.negativeInfinity;
    var left = double.infinity, right = double.negativeInfinity;
    for (final point in fieldOutline) {
      if (point.dy < top) top = point.dy;
      if (point.dy > bottom) bottom = point.dy;
      if (point.dx < left) left = point.dx;
      if (point.dx > right) right = point.dx;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Whether normalized photograph coordinates (u, v) lie inside the traced
  /// panel outline.
  bool isInsideField(double u, double v) {
    final bounds = panelExtent;
    if (v < bounds.top || v > bounds.bottom) {
      return false;
    }
    final row = _panelRowSpan(v);
    if (row == null) {
      return false;
    }
    return u >= row.$1 && u <= row.$2;
  }

  /// Left and right u of the panel outline at the row [v], or null when the
  /// row does not cross the outline.
  (double, double)? _panelRowSpan(double v) {
    final outline = fieldOutline;
    var left = double.infinity;
    var right = double.negativeInfinity;
    for (var i = 0, j = outline.length - 1; i < outline.length; j = i++) {
      final a = outline[j];
      final b = outline[i];
      if ((a.dy > v) == (b.dy > v)) {
        continue;
      }
      final x = a.dx + (b.dx - a.dx) * (v - a.dy) / (b.dy - a.dy);
      if (x < left) left = x;
      if (x > right) right = x;
    }
    if (left > right) {
      return null;
    }
    return (left, right);
  }

  /// Projects a conch point for a viewer looking at the default viewpoint,
  /// rotated about the panel centre by [yaw] and [pitch] radians.
  Offset? project(
    Vec3 world,
    Size viewSize, {
    double yaw = 0,
    double pitch = 0,
  }) {
    final rotated = orbit(world, yaw: yaw, pitch: pitch);
    return projectRaw(rotated, viewSize);
  }

  /// Rotates a conch point about the panel centre, so the framed panel stays
  /// put while the bowl shifts under the viewer.
  Vec3 orbit(Vec3 world, {double yaw = 0, double pitch = 0}) {
    final q = world - _panelCenter;
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final pitched = Vec3(q.x, q.y * cp - q.z * sp, q.y * sp + q.z * cp);
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final yawed = Vec3(
      pitched.x * cy + pitched.z * sy,
      pitched.y,
      -pitched.x * sy + pitched.z * cy,
    );
    return _panelCenter + yawed;
  }

  /// Projects an already-rotated world point with the default viewpoint.
  Offset? projectRaw(Vec3 world, Size viewSize) {
    final d = world - _camera;
    final z = d.dot(_frame.forward);
    if (z < 0.05) {
      return null;
    }
    final x = d.dot(_frame.right);
    final y = d.dot(_frame.up);
    final scale = focalLength(viewSize);
    return Offset(
      viewSize.width / 2 + scale * x / z,
      viewSize.height / 2 - scale * y / z,
    );
  }

  /// Focal length in view pixels that fits the panel into the view.
  double focalLength(Size viewSize) {
    final aspect = textureSize.height / textureSize.width;
    final byWidth = viewSize.width / (2 * _tanHalfFov);
    final byHeight = viewSize.height / (2 * _tanHalfFov * aspect);
    return math.min(byWidth, byHeight);
  }

  /// Establishes the default viewpoint and fits the field of view so the
  /// projected panel outline fills [ConchParams.viewFill] of the viewer.
  ///
  /// The panel's silhouette, its curvature and its parallax all come from the
  /// placement of the traced outline on the semi-dome; the field of view is
  /// only a framing, and it scales with [ConchParams.radius] like everything
  /// else, so the curvature control never changes the framing.
  void _solveCaptureCamera() {
    _applyCamera(params.cameraY, params.cameraZ, 0.30);
    var maxAbsX = 0.0;
    var maxAbsY = 0.0;
    // Dense sample of the panel plus its traced edge: the projected outline
    // of the bowl can fold past the edge points near the limb, so the
    // silhouette is measured from interior points too.
    const across = 25;
    const down = 17;
    for (var i = 0; i <= across; i++) {
      for (var j = 0; j <= down; j++) {
        final world = texelForPanelFraction(i / across, j / down).world;
        final d = world - _camera;
        final z = d.dot(_frame.forward);
        if (z < 0.05) {
          continue;
        }
        final nx = d.dot(_frame.right) / z;
        final ny = d.dot(_frame.up) / z;
        if (nx.abs() > maxAbsX) maxAbsX = nx.abs();
        if (ny.abs() > maxAbsY) maxAbsY = ny.abs();
      }
    }
    for (final point in fieldOutline) {
      final extent = panelExtent;
      final s = (point.dx - extent.left) / (extent.right - extent.left);
      final t = (point.dy - extent.top) / (extent.bottom - extent.top);
      final world = texelForPanelFraction(s, t).world;
      final d = world - _camera;
      final z = d.dot(_frame.forward);
      if (z < 0.05) {
        continue;
      }
      final nx = d.dot(_frame.right) / z;
      final ny = d.dot(_frame.up) / z;
      if (nx.abs() > maxAbsX) maxAbsX = nx.abs();
      if (ny.abs() > maxAbsY) maxAbsY = ny.abs();
    }
    final aspect = textureSize.height / textureSize.width;
    // Normalized image offsets are (x / z) / (2 tanF) horizontally and
    // (y / z) / (2 tanF aspect) vertically.
    final tanF = math.max(maxAbsX, maxAbsY / aspect) / params.viewFill;
    _applyCamera(params.cameraY, params.cameraZ, tanF);
  }

  void _applyCamera(double cameraY, double cameraZ, double tanHalfFov) {
    // The viewpoint is fixed in absolute units, not scaled with the radius:
    // tightening or flattening the apse then changes what a visitor standing
    // in the same place actually sees. Only the framing is re-fitted.
    _camera = Vec3(0, cameraY, cameraZ);
    _frame = _Frame.lookAlong(_camera, (_panelCenter - _camera).normalized);
    _tanHalfFov = tanHalfFov;
  }

  /// Resolves normalized panel coordinates (s across, t down) onto the
  /// conch: the inverse of the unwrap used by [texelForPhoto].
  ConchTexel texelForPanelFraction(double s, double t) {
    final theta = params.thetaPanel * (2 * s - 1);
    final alpha = params.alphaTop - t * (params.alphaTop - params.alphaBottom);
    final world = conchPoint(alpha, theta);
    return ConchTexel(
      world: world,
      normal: -(world * (1 / _radius)),
      alpha: alpha,
      theta: theta,
      shade: 1.0,
    );
  }
}

/// Plain mesh data for one rendered frame; the widget wraps it in a
/// [ui.Vertices], the offline renderer rasterizes it, and the tests inspect
/// it.
class ConchMeshData {
  ConchMeshData({
    required this.positions,
    required this.texCoords,
    required this.colors,
    required this.indices,
    required this.vertexCount,
    required this.visibleVertices,
    required this.bounds,
    required this.anchors,
  });

  /// Two floats per vertex: view pixel coordinates.
  final Float32List positions;

  /// Two floats per vertex: reference texture pixel coordinates.
  final Float32List texCoords;

  /// One ARGB colour per vertex (shading).
  final Int32List colors;

  /// Triangle indices.
  final Uint16List indices;

  final int vertexCount;
  final int visibleVertices;

  /// Bounds of the projected surface, or null when nothing is visible.
  final Rect? bounds;

  /// Projected hotspot anchors still on the visible surface.
  final Map<String, Offset> anchors;
}

class ConchRenderer {
  ConchRenderer({
    required this.params,
    required this.textureSize,
    this.columns = 96,
    this.rows = 64,
    this.fieldOutline = anastasisFieldOutline,
  }) : _surface = ConchSurface(
         params: params,
         textureSize: textureSize,
         fieldOutline: fieldOutline,
       ) {
    _buildBaseMesh();
  }

  final ConchParams params;
  final Size textureSize;
  final int columns;
  final int rows;
  final List<Offset> fieldOutline;

  final ConchSurface _surface;

  late final Float64List _world; // 3 per vertex
  late final Float64List _texel; // 2 per vertex
  late final Int32List _shade; // 1 per vertex
  late final Uint8List _valid; // 1 per vertex
  late final Uint16List _indices;

  ConchSurface get surface => _surface;

  int get vertexCount => (columns + 1) * (rows + 1);

  void _buildBaseMesh() {
    final count = vertexCount;
    final extent = _surface.panelExtent;
    _world = Float64List(count * 3);
    _texel = Float64List(count * 2);
    _shade = Int32List(count);
    _valid = Uint8List(count);
    final indices = <int>[];

    for (var j = 0; j <= rows; j++) {
      for (var i = 0; i <= columns; i++) {
        final index = j * (columns + 1) + i;
        final u = 0.003 + (i / columns) * 0.994;
        final v =
            extent.top +
            ((j / rows) * 0.994 + 0.003) * (extent.bottom - extent.top);
        final texel = _surface.texelForPhoto(u, v);
        _texel[index * 2] = u * textureSize.width;
        _texel[index * 2 + 1] = v * textureSize.height;
        if (texel == null) {
          continue;
        }
        _valid[index] = 1;
        _world[index * 3] = texel.world.x;
        _world[index * 3 + 1] = texel.world.y;
        _world[index * 3 + 2] = texel.world.z;
        final value = (texel.shade * 255).round().clamp(0, 255);
        _shade[index] = 0xFF000000 | (value << 16) | (value << 8) | value;
      }
    }

    for (var j = 0; j < rows; j++) {
      for (var i = 0; i < columns; i++) {
        final a = j * (columns + 1) + i;
        final b = a + 1;
        final c = a + columns + 1;
        final d = c + 1;
        if (_valid[a] == 0 ||
            _valid[b] == 0 ||
            _valid[c] == 0 ||
            _valid[d] == 0) {
          continue;
        }
        indices.addAll([a, c, b, b, c, d]);
      }
    }
    _indices = Uint16List.fromList(indices);
  }

  /// Builds the projected mesh for one frame.
  ConchMeshData build({
    required Size viewSize,
    double yaw = 0,
    double pitch = 0,
    List<ConchAnchor> anchors = const [],
  }) {
    final count = vertexCount;
    final positions = Float32List(count * 2);
    final anchorPoints = <String, Offset>{};
    final anchorTexels = <String, Vec3>{};

    for (final anchor in anchors) {
      final texel = _surface.texelForPhoto(anchor.u, anchor.v);
      if (texel != null) {
        anchorTexels[anchor.id] = texel.world;
      }
    }

    var visible = 0;
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (var index = 0; index < count; index++) {
      if (_valid[index] == 0) {
        positions[index * 2] = double.nan;
        positions[index * 2 + 1] = double.nan;
        continue;
      }
      final world = Vec3(
        _world[index * 3],
        _world[index * 3 + 1],
        _world[index * 3 + 2],
      );
      final projected = _surface.project(
        world,
        viewSize,
        yaw: yaw,
        pitch: pitch,
      );
      if (projected == null) {
        positions[index * 2] = double.nan;
        positions[index * 2 + 1] = double.nan;
        continue;
      }
      positions[index * 2] = projected.dx;
      positions[index * 2 + 1] = projected.dy;
      visible++;
      if (projected.dx < minX) minX = projected.dx;
      if (projected.dx > maxX) maxX = projected.dx;
      if (projected.dy < minY) minY = projected.dy;
      if (projected.dy > maxY) maxY = projected.dy;
    }

    for (final entry in anchorTexels.entries) {
      final projected = _surface.project(
        entry.value,
        viewSize,
        yaw: yaw,
        pitch: pitch,
      );
      if (projected != null) {
        anchorPoints[entry.key] = projected;
      }
    }

    return ConchMeshData(
      positions: positions,
      texCoords: _texel.toFloat32List(),
      colors: _shade,
      indices: _indices,
      vertexCount: count,
      visibleVertices: visible,
      bounds: visible == 0 ? null : Rect.fromLTRB(minX, minY, maxX, maxY),
      anchors: anchorPoints,
    );
  }

  /// Number of triangles that survive clipping; used by tests.
  int get triangleCount => _indices.length ~/ 3;
}

extension on Float64List {
  Float32List toFloat32List() {
    final out = Float32List(length);
    for (var i = 0; i < length; i++) {
      out[i] = this[i];
    }
    return out;
  }
}
