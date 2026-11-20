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
/// What `light` parts are drawn in, in every style: daylight through a ring
/// of windows (P12), not a surface, so it is neither hatched nor lit.
const lightColor = Color(0xFFF1C66B);

Color materialColor(String material) => switch (material) {
  'light' => lightColor,
  'marble' => const Color(0xFFDDD6C9),
  'brick' => const Color(0xFFB0705A),
  'ochre' => const Color(0xFFD5B698),
  'lead' => const Color(0xFF8A9096),
  // P13: the Serpent Column's bronze and the lost gold of its tripod.
  'bronze' => const Color(0xFF7D6B4C),
  'gold' => Pigment.gold,
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
/// occlusion (drawing), smooth crease-aware sun and sky on marble and brick
/// (stone), or per-corner interior lamps and a little moonlight (night).
Int32List cornerColors(
  SpaceStyle style,
  SpacePart part,
  SpaceBounds b, {
  List<(double, double, double)> lamps = const [],
}) {
  final palette = SpacePalette.of(style);
  const sun = [-.37, -.46, .81];
  final out = Int32List(part.triangleCount * 3);
  final base = materialColor(part.material);
  if (part.material == 'light') {
    return out..fillRange(0, out.length, lightColor.toARGB32());
  }
  final cn = part.cornerNormals;
  final span = math.max(b.maxX - b.minX, b.maxY - b.minY).clamp(4.0, 1e4);
  final scale = span / nightLampSpan;
  final falloff = 260.0 * scale * scale;
  final floorZ = math.max(0.0, b.minZ);
  final resolvedLamps = lamps.isNotEmpty
      ? lamps
      : [
          for (final (lx, ly, lz) in nightLamps)
            (
              b.centerX + lx * scale,
              b.centerY + ly * scale,
              floorZ + lz * scale,
            ),
        ];
  for (var t = 0; t < part.triangleCount; t++) {
    for (var k = 0; k < 3; k++) {
      final vi = part.triangles[t * 3 + k];
      final ao = part.ao[vi];
      final no = (t * 3 + k) * 3;
      final nx = cn[no], ny = cn[no + 1], nz = cn[no + 2];
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
          final px = part.positions[vi * 3],
              py = part.positions[vi * 3 + 1],
              pz = part.positions[vi * 3 + 2];
          var lamp = 0.0;
          for (final (lx, ly, lz) in resolvedLamps) {
            final dx = lx - px, dy = ly - py, dz = lz - pz;
            final d = math.sqrt(dx * dx + dy * dy + dz * dz);
            if (d < 1e-6) continue;
            final lambert = math.max(0.0, (nx * dx + ny * dy + nz * dz) / d);
            lamp += 1.4 * lambert / (1 + d * d / falloff);
          }
          final moon = .05 + .2 * math.max(0.0, nx * .3 + ny * .45 + nz * .84);
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
