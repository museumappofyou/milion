import 'dart:ui';

import '../design/tokens.dart';

/// The three cartographic manners of P10. Tiles are rendered once per manner;
/// the slider crossfades between neighbouring manners. No paper, grain or
/// aged textures (§2): each manner is a drawing convention in the app's
/// pigments.
enum AtlasManner {
  /// Byzantine years: Buondelmonti-like. Verdigris sea with pen wave marks,
  /// an ink shore, walls with towers; no modern streets.
  manuscript,

  /// Ottoman years: Matrakçı-inspired. Cobalt sea of scale-like waves, a bole
  /// shore, coloured building glyphs for the places.
  ottoman,

  /// Today: a precise line map from OpenStreetMap.
  modern,
}

class MannerStyle {
  const MannerStyle({
    required this.land,
    required this.water,
    required this.waterMark,
    required this.shore,
    required this.shoreWidth,
    required this.wall,
    required this.street,
    required this.label,
  });
  final Color land, water, waterMark, shore, wall, street, label;
  final double shoreWidth;

  static const manuscript = MannerStyle(
    land: Pigment.marble,
    water: Color(0xFFCAD3C8),
    waterMark: Color(0xB33A655B),
    shore: Pigment.lamp,
    shoreWidth: 1.4,
    wall: Pigment.porphyry,
    street: Color(0xFF85382D),
    label: Pigment.lamp,
  );
  static const ottoman = MannerStyle(
    land: Color(0xFFF0E7D6),
    water: Color(0xFFBCCEDA),
    waterMark: Color(0x8C194F78),
    shore: Pigment.bole,
    shoreWidth: 1.6,
    wall: Pigment.bole,
    street: Color(0xFF805A35),
    label: Pigment.lamp,
  );
  static const modern = MannerStyle(
    land: Pigment.marble,
    water: Color(0xFFD3DCE0),
    waterMark: Color(0x00000000),
    shore: Color(0xFF847770),
    shoreWidth: 0.8,
    wall: Pigment.porphyry,
    street: Color(0xFF635B58),
    label: Pigment.lamp,
  );

  static MannerStyle of(AtlasManner m) => switch (m) {
    AtlasManner.manuscript => manuscript,
    AtlasManner.ottoman => ottoman,
    AtlasManner.modern => modern,
  };

  static MannerStyle lerp(MannerStyle a, MannerStyle b, double t) =>
      MannerStyle(
        land: Color.lerp(a.land, b.land, t)!,
        water: Color.lerp(a.water, b.water, t)!,
        waterMark: Color.lerp(a.waterMark, b.waterMark, t)!,
        shore: Color.lerp(a.shore, b.shore, t)!,
        shoreWidth: a.shoreWidth + (b.shoreWidth - a.shoreWidth) * t,
        wall: Color.lerp(a.wall, b.wall, t)!,
        street: Color.lerp(a.street, b.street, t)!,
        label: Color.lerp(a.label, b.label, t)!,
      );
}

/// Which manners show at [year] and how much of the second one: Byzantine
/// up to 1453, Ottoman from 1560 to 1900, modern today, crossfading between.
({AtlasManner from, AtlasManner to, double t}) mannersAt(double year) {
  if (year <= 1453) {
    return (from: AtlasManner.manuscript, to: AtlasManner.manuscript, t: 0);
  }
  if (year < 1560) {
    return (
      from: AtlasManner.manuscript,
      to: AtlasManner.ottoman,
      t: (year - 1453) / (1560 - 1453),
    );
  }
  if (year <= 1900) {
    return (from: AtlasManner.ottoman, to: AtlasManner.ottoman, t: 0);
  }
  return (
    from: AtlasManner.ottoman,
    to: AtlasManner.modern,
    t: ((year - 1900) / (2026 - 1900)).clamp(0.0, 1.0),
  );
}

MannerStyle styleAt(double year) {
  final m = mannersAt(year);
  return MannerStyle.lerp(MannerStyle.of(m.from), MannerStyle.of(m.to), m.t);
}
