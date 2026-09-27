import 'package:flutter/material.dart';

abstract final class MilionTheme {
  static const paper = Color(0xFFF6F2E9);
  static const parchment = Color(0xFFECE5D8);
  static const ink = Color(0xFF253D35);
  static const muted = Color(0xFF69716A);
  static const gold = Color(0xFF8C6935);
  static const line = Color(0xFFDCD6CA);
  static const night = Color(0xFF17251F);
  static const lightGold = Color(0xFFE7D3A5);

  // Brand colours of the mark and launcher: imperial porphyry, gold tesserae
  // and Proconnesian marble. The full palette is replaced in P03.
  static const porphyry = Color(0xFF4E1B2B);
  static const tesseraGold = Color(0xFFC9A04C);
  static const marble = Color(0xFFEEE7DB);

  static TextStyle display(double size, {Color color = ink}) => TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: size,
    fontWeight: FontWeight.w500,
    height: 1.02,
    letterSpacing: -.7,
    color: color,
  );

  static const eyebrow = TextStyle(
    fontFamily: 'DMSans',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.1,
    color: gold,
  );

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: ink,
      primary: ink,
      onPrimary: paper,
      secondary: gold,
      secondaryContainer: parchment,
      onSecondaryContainer: ink,
      onSecondary: Colors.white,
      surface: paper,
      onSurface: ink,
      outline: line,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'DMSans',
    );
    return base.copyWith(
      scaffoldBackgroundColor: paper,
      textTheme: base.textTheme.copyWith(
        displayLarge: display(76),
        displayMedium: display(60),
        displaySmall: display(48),
        headlineLarge: display(40),
        headlineMedium: display(34),
        headlineSmall: display(28),
        bodyLarge: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 16,
          height: 1.6,
          color: ink,
        ),
        bodyMedium: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 14,
          height: 1.5,
          color: ink,
        ),
        bodySmall: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          height: 1.5,
          color: muted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: display(30),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        indicatorColor: parchment,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? ink : muted,
          ),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: ink, size: 22),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFCFAF5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          textStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paper,
        selectedColor: parchment,
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          color: ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFCFAF5),
        hintStyle: const TextStyle(color: muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ink),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: line,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: paper),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: gold),
    );
  }
}

/// An inscriptional M with the gilded zero of the Milion stone held in its
/// vertex: M + 0, the zero-mile point of Constantinople.
/// Geometry matches tool/build_milion_identity.py (64-unit grid).
class MilionMark extends StatelessWidget {
  const MilionMark({super.key, this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _MilionMarkPainter()),
  );
}

class MilionWordmark extends StatelessWidget {
  const MilionWordmark({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Milion. Istanbul from mile zero.',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MilionMark(size: 34),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MILION',
                style: MilionTheme.display(27).copyWith(letterSpacing: 3.2),
              ),
              if (!compact)
                const Text(
                  'ISTANBUL FROM MILE ZERO',
                  style: TextStyle(
                    fontSize: 7,
                    letterSpacing: 1.2,
                    color: MilionTheme.muted,
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MilionMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    canvas.drawCircle(
      const Offset(32, 35),
      5.175,
      Paint()
        ..color = MilionTheme.tesseraGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.45,
    );
    canvas.drawPath(
      Path()
        ..moveTo(12, 51)
        ..lineTo(18.4, 51)
        ..lineTo(22.8, 17)
        ..lineTo(32, 31)
        ..lineTo(41.2, 17)
        ..lineTo(45.6, 51)
        ..lineTo(52, 51)
        ..lineTo(45.6, 12)
        ..lineTo(41.2, 12)
        ..lineTo(32, 27)
        ..lineTo(22.8, 12)
        ..lineTo(18.4, 12)
        ..close(),
      Paint()..color = MilionTheme.porphyry,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MilionMarkPainter oldDelegate) => false;
}
