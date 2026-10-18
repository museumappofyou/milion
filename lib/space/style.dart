import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../design/tokens.dart';
import 'model.dart';

/// §2 signature 5: a measured drawing come alive, not a game engine.
enum SpaceStyle { drawing, stone, night }

/// Colours and line weights for one style (logical pixels).
class SpacePalette {
  const SpacePalette({
    required this.ground,
    required this.face,
    required this.ink,
    required this.poche,
    required this.hatch,
    required this.edgeWidth,
    required this.silhouetteWidth,
    required this.cutWidth,
    required this.edgeAlpha,
  });
  final Color ground, face, ink, poche, hatch;
  final double edgeWidth, silhouetteWidth, cutWidth, edgeAlpha;
  bool get edges => edgeAlpha > 0;

  /// Drawing: hairline edges, porphyry poché on cut faces, hatch shading.
  static const drawing = SpacePalette(
    ground: Pigment.marble,
    face: Color(0xFFF7F3EC),
    ink: Pigment.lamp,
    poche: Pigment.porphyry,
    hatch: Color(0xFF5A504B),
    edgeWidth: .7,
    silhouetteWidth: 1.2,
    cutWidth: 2.2,
    edgeAlpha: 1,
  );

  /// Stone: flat-shaded marble and brick with baked occlusion.
  static const stone = SpacePalette(
    ground: Color(0xFFE6DFD3),
    face: Color(0xFFDCD5C8),
    ink: Color(0xFF3B302C),
    poche: Color(0xFF2B2427),
    hatch: Color(0xFFFFFFFF),
    edgeWidth: .6,
    silhouetteWidth: .9,
    cutWidth: 1.6,
    edgeAlpha: .35,
  );

  /// Night: the bay under warm lamps, no line work.
  static const night = SpacePalette(
    ground: Pigment.lamp,
    face: Color(0xFF8A6A4A),
    ink: Color(0xFF000000),
    poche: Color(0xFF070606),
    hatch: Color(0xFFFFFFFF),
    edgeWidth: 0,
    silhouetteWidth: 0,
    cutWidth: 1.2,
    edgeAlpha: 0,
  );

  static SpacePalette of(SpaceStyle style) => switch (style) {
    SpaceStyle.drawing => drawing,
    SpaceStyle.stone => stone,
    SpaceStyle.night => night,
  };
}

/// Base colours of the materials named in a model's node extras.
Color materialColor(String material) => switch (material) {
  'marble' => const Color(0xFFDDD6C9),
  'brick' => const Color(0xFFB0705A),
  'lead' => const Color(0xFF8A9096),
  _ => const Color(0xFFC9C0B2),
};

/// Night: lamps hung low in the bay (x, y, z in metres, relative to the
/// model's centre and floor), warm. They were set for P08's bay, 72.4 m across
/// with its semi-domes ([nightLampSpan]); other buildings scale them.
const nightLamps = [
  (0.0, 0.0, 9.0),
  (7.0, 0.0, 7.5),
  (-7.0, 0.0, 7.5),
  (0.0, 7.0, 7.5),
  (0.0, -7.0, 7.5),
];
const nightLampSpan = 72.4;
const nightLampColor = Color(0xFFFFB45E);

/// The drawing style's line screen: one hatch line per [tile]-pixel column,
/// [rows] rows from blank (row 0) to nearly solid; row = shade.
Image hatchTexture(SpaceStyle style, double tile, int rows) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, tile, rows.toDouble()),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final ink = Paint()..color = SpacePalette.of(style).hatch;
  for (var r = 1; r < rows; r++) {
    final w = r / (rows - 1) * 10;
    canvas.drawRect(Rect.fromLTWH(tile / 2 - w / 2, r.toDouble(), w, 1), ink);
  }
  final picture = recorder.endRecording();
  final image = picture.toImageSync(tile.toInt(), rows);
  picture.dispose();
  return image;
}

/// Opaque ARGB per triangle corner for [style]: paper with a touch of
/// occlusion (drawing), sun and sky on marble and brick (stone), or lamps
/// and a little moonlight (night).
Int32List cornerColors(SpaceStyle style, SpacePart part, SpaceBounds b) {
  final palette = SpacePalette.of(style);
  const sun = [-.37, -.46, .81];
  final out = Int32List(part.triangleCount * 3);
  final base = materialColor(part.material);
  for (var t = 0; t < part.triangleCount; t++) {
    final nx = part.normals[t * 3],
        ny = part.normals[t * 3 + 1],
        nz = part.normals[t * 3 + 2];
    var lamp = 0.0, moon = 0.0;
    final k =
        math.max(b.maxX - b.minX, b.maxY - b.minY).clamp(1.0, 1e4) /
        nightLampSpan;
    if (style == SpaceStyle.night) {
      final i0 = part.triangles[t * 3] * 3;
      final px = part.positions[i0],
          py = part.positions[i0 + 1],
          pz = part.positions[i0 + 2];
      for (final (lx, ly, lz) in nightLamps) {
        final dx = b.centerX + lx * k - px,
            dy = b.centerY + ly * k - py,
            dz = b.minZ + lz * k - pz;
        final d = math.sqrt(dx * dx + dy * dy + dz * dz);
        if (d < 1e-6) continue;
        final lambert = math.max(0.0, (nx * dx + ny * dy + nz * dz) / d);
        lamp += 1.4 * lambert / (1 + d * d / (260 * k * k));
      }
      moon = .05 + .2 * math.max(0.0, nx * .3 + ny * .45 + nz * .84);
    }
    for (var k = 0; k < 3; k++) {
      final ao = part.ao[part.triangles[t * 3 + k]];
      double r, g, bl;
      switch (style) {
        case SpaceStyle.drawing:
          final f = .9 + .1 * ao;
          r = palette.face.r * f;
          g = palette.face.g * f;
          bl = palette.face.b * f;
        case SpaceStyle.stone:
          final light =
              (.34 +
                  .5 * math.max(0, nx * sun[0] + ny * sun[1] + nz * sun[2]) +
                  .16 * (.5 + .5 * nz)) *
              (.42 + .58 * ao);
          r = base.r * light;
          g = base.g * light;
          bl = base.b * light;
        case SpaceStyle.night:
          // A little cool moonlight outside, so the masses still read.
          final warm = lamp * math.pow(ao, 1.4), cool = moon * ao;
          r = base.r * (nightLampColor.r * warm + .55 * cool);
          g = base.g * (nightLampColor.g * warm + .64 * cool);
          bl = base.b * (nightLampColor.b * warm + .9 * cool);
      }
      int channel(double v) => (v.clamp(0.0, 1.0) * 255).round();
      out[t * 3 + k] =
          0xFF000000 | channel(r) << 16 | channel(g) << 8 | channel(bl);
    }
  }
  return out;
}
