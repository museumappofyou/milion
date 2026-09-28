import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class DesignTheme {
  static ThemeData get marble => build(MeasureColors.marble, Brightness.light);
  static ThemeData get lamp => build(MeasureColors.lamp, Brightness.dark);
  static ThemeData build(MeasureColors c, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: Pigment.porphyry,
          brightness: brightness,
        ).copyWith(
          primary: c.accent,
          onPrimary: c.ground,
          secondary: c.accent,
          onSecondary: c.ground,
          surface: c.ground,
          onSurface: c.ink,
          onSurfaceVariant: c.secondary,
          surfaceContainerHighest: c.poche,
          outline: c.line,
          outlineVariant: c.line,
          error: brightness == Brightness.light
              ? Pigment.bole
              : const Color(0xFFF0B0A5),
          onError: c.ground,
          surfaceTint: Colors.transparent,
        );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: TypeRole.bodyFamily,
    );
    final square = RoundedRectangleBorder(
      borderRadius: Space.radius,
      side: BorderSide(color: c.line),
    );
    final text = base.textTheme
        .apply(bodyColor: c.ink, displayColor: c.ink)
        .copyWith(
          displayLarge: TypeRole.inscription(48, color: c.ink),
          displayMedium: TypeRole.inscription(40, color: c.ink),
          displaySmall: TypeRole.inscription(32, color: c.ink),
          headlineLarge: TypeRole.inscription(28, color: c.ink),
          headlineMedium: TypeRole.inscription(24, color: c.ink),
          headlineSmall: TypeRole.inscription(20, color: c.ink),
          bodyLarge: TextStyle(
            fontFamily: TypeRole.bodyFamily,
            fontSize: 16,
            height: 1.5,
            color: c.ink,
          ),
          bodyMedium: TextStyle(
            fontFamily: TypeRole.bodyFamily,
            fontSize: 14,
            height: 1.5,
            color: c.ink,
          ),
          bodySmall: TextStyle(
            fontFamily: TypeRole.bodyFamily,
            fontSize: 12,
            height: 1.5,
            color: c.secondary,
          ),
        );
    final button = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      shape: WidgetStatePropertyAll(square),
      elevation: const WidgetStatePropertyAll(0),
    );
    return base.copyWith(
      extensions: [c],
      scaffoldBackgroundColor: c.ground,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: c.ground,
        foregroundColor: c.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TypeRole.inscription(20, color: c.ink),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      cardTheme: CardThemeData(
        color: c.ground,
        shape: square,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(style: button),
      outlinedButtonTheme: OutlinedButtonThemeData(style: button),
      textButtonTheme: TextButtonThemeData(
        style: button.copyWith(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: Space.radius),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: button),
      chipTheme: ChipThemeData(
        shape: square,
        backgroundColor: c.ground,
        selectedColor: c.poche,
        labelStyle: TextStyle(fontFamily: TypeRole.bodyFamily, color: c.ink),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: button.copyWith(
          foregroundColor: WidgetStatePropertyAll(c.ink),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.poche : c.ground,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 80,
        indicatorColor: c.poche,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: Space.radius,
        ),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: c.ink)),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontFamily: TypeRole.bodyFamily,
            fontSize: 12,
            color: c.ink,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.ground,
        hintStyle: TextStyle(color: c.secondary),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: Space.radius,
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Space.radius,
          borderSide: BorderSide(color: c.line),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: square,
        showDragHandle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: square,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.ground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: square,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(
          fontFamily: TypeRole.bodyFamily,
          color: c.ground,
        ),
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: c.accent,
        thumbColor: c.accent,
        inactiveTrackColor: c.line,
        overlayColor: Colors.transparent,
      ),
    );
  }
}
