import 'package:flutter/material.dart';

/// Four-dp construction grid. Hairlines are the sole sub-grid exception.
abstract final class Space {
  static const unit = 4.0;
  static const xs = 4.0, sm = 8.0, md = 16.0, lg = 24.0, xl = 32.0, xxl = 48.0;
  static const radius = BorderRadius.all(Radius.circular(2));
}

abstract final class Pigment {
  static const porphyry = Color(0xFF4E1B2B);
  static const gold = Color(0xFFC9A04C);
  static const marble = Color(0xFFEEE7DB);
  static const lamp = Color(0xFF151314);
  static const cobalt = Color(0xFF194F78);
  static const bole = Color(0xFF85382D);
  static const turquoise = Color(0xFF237B79);
  static const verdigris = Color(0xFF3A655B);
  static const bronze = Color(0xFF805A35);
  static const byzantine = (ground: porphyry, material: gold);
  static const mosques = (ground: cobalt, material: turquoise);
  static const museums = (ground: verdigris, material: bronze);
}

@immutable
class MeasureColors extends ThemeExtension<MeasureColors> {
  const MeasureColors({
    required this.ground,
    required this.ink,
    required this.secondary,
    required this.line,
    required this.poche,
    required this.accent,
  });
  final Color ground, ink, secondary, line, poche, accent;
  static const marble = MeasureColors(
    ground: Pigment.marble,
    ink: Pigment.lamp,
    secondary: Color(0xFF635B58),
    line: Color(0xFF847770),
    poche: Color(0xFFE1D7C7),
    accent: Pigment.porphyry,
  );
  static const lamp = MeasureColors(
    ground: Pigment.lamp,
    ink: Pigment.marble,
    secondary: Color(0xFFBEB3A8),
    line: Color(0xFF827872),
    poche: Color(0xFF2B2427),
    accent: Color(0xFFD8A5B6),
  );
  static MeasureColors of(BuildContext context) =>
      Theme.of(context).extension<MeasureColors>() ?? marble;
  @override
  MeasureColors copyWith({
    Color? ground,
    Color? ink,
    Color? secondary,
    Color? line,
    Color? poche,
    Color? accent,
  }) => MeasureColors(
    ground: ground ?? this.ground,
    ink: ink ?? this.ink,
    secondary: secondary ?? this.secondary,
    line: line ?? this.line,
    poche: poche ?? this.poche,
    accent: accent ?? this.accent,
  );
  @override
  MeasureColors lerp(covariant MeasureColors? other, double t) => other == null
      ? this
      : MeasureColors(
          ground: Color.lerp(ground, other.ground, t)!,
          ink: Color.lerp(ink, other.ink, t)!,
          secondary: Color.lerp(secondary, other.secondary, t)!,
          line: Color.lerp(line, other.line, t)!,
          poche: Color.lerp(poche, other.poche, t)!,
          accent: Color.lerp(accent, other.accent, t)!,
        );
}

abstract final class TypeRole {
  static const displayFamily = 'Cinzel';
  static const bodyFamily = 'NotoSans';
  static const displayFallback = ['NotoSerifDisplay'];
  static TextStyle inscription(double size, {Color? color}) => TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: displayFallback,
    fontSize: size,
    height: 1.2,
    letterSpacing: .8,
    color: color,
  );
  static const measurement = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: .4,
  );
  static String capitals(String text, String language) =>
      (language == 'tr' ? text.replaceAll('i', 'İ').replaceAll('ı', 'I') : text)
          .toUpperCase();
}
