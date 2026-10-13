import 'package:flutter/painting.dart';

import 'camera.dart';
import 'model.dart';
import 'style.dart';

/// How one part stands in this frame: [progress] 0 is absent, 1 in place
/// and opaque; the offset is its assembly drop and exploded displacement.
class SpacePartState {
  const SpacePartState({
    this.progress = 1,
    this.dx = 0,
    this.dy = 0,
    this.dz = 0,
  });
  static const hidden = SpacePartState(progress: 0);
  final double progress, dx, dy, dz;
}

/// An axis-aligned section plane at [offset] metres along [axis] (0 x,
/// 1 y, 2 z). The half facing the camera is removed, so the cut always faces
/// the viewer; cut solids show their inside faces as poché.
class SpaceSection {
  const SpaceSection(this.axis, this.offset);
  final int axis;
  final double offset;
  @override
  bool operator ==(Object other) =>
      other is SpaceSection && other.axis == axis && other.offset == offset;
  @override
  int get hashCode => Object.hash(axis, offset);
}

class SpaceScene {
  const SpaceScene({
    required this.view,
    required this.style,
    required this.parts,
    this.section,
  });
  final SpaceView view;
  final SpaceStyle style;

  /// One state per model part, in model order.
  final List<SpacePartState> parts;
  final SpaceSection? section;
}

class SpaceStats {
  const SpaceStats({
    this.faces = 0,
    this.poche = 0,
    this.edges = 0,
    this.cuts = 0,
    this.micros = 0,
    this.geometryMicros = 0,
    this.sortMicros = 0,
    this.writeMicros = 0,
    this.drawMicros = 0,
  });
  final int faces, poche, edges, cuts;

  /// CPU per frame: all of it; projection, culling and clipping; the depth
  /// sort; writing the buffers; building the vertices and the draw call.
  final int micros, geometryMicros, sortMicros, writeMicros, drawMicros;
  int get triangles => faces + poche + 2 * (edges + cuts);
}

/// The section plane's rectangle inside the model bounds, on screen.
List<Offset> sectionOutline(SpaceProjector p, SpaceBounds b, SpaceSection s) {
  final corners = <List<double>>[];
  final a1 = (s.axis + 1) % 3, a2 = (s.axis + 2) % 3;
  for (final (u, v) in [(0, 0), (1, 0), (1, 1), (0, 1)]) {
    final point = [0.0, 0.0, 0.0];
    point[s.axis] = s.offset;
    point[a1] = u == 0 ? b.min(a1) : b.max(a1);
    point[a2] = v == 0 ? b.min(a2) : b.max(a2);
    corners.add(point);
  }
  return [for (final c in corners) p.toScreen(c[0], c[1], c[2])];
}
