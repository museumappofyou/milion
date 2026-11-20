import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

abstract final class DesignTheme {
  static ThemeData get marble => build(MeasureColors.marble, Brightness.light);
  static ThemeData get lamp => build(MeasureColors.lamp, Brightness.dark);

  /// Edge-to-edge: transparent bars, icons contrasting with the ground below.
  static SystemUiOverlayStyle overlay(Brightness ground) {
    final icons = ground == Brightness.light
        ? Brightness.dark
        : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: ground,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: icons,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static ThemeData build(MeasureColors c, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: Pigment.porphyry,
          brightness: brightness,
        ).copyWith(
          primary: c.accent,
          onPrimary: c.ground,
          primaryContainer: c.poche,
          onPrimaryContainer: c.ink,
          secondary: c.accent,
          onSecondary: c.ground,
          secondaryContainer: c.poche,
          onSecondaryContainer: c.ink,
          surface: c.ground,
          onSurface: c.ink,
          onSurfaceVariant: c.secondary,
          surfaceContainerLow: c.ground,
          surfaceContainer: c.poche,
          surfaceContainerHigh: c.poche,
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
    const controlRadius = BorderRadius.all(Radius.circular(3));
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
    // Filled buttons: porphyry on marble, marble on lamp. Gold stays reserved
    // for gold, collected items and rewards (PHASES §2), and the lamp accent
    // is too pale to carry a fill.
    final filledBg = brightness == Brightness.dark ? c.ink : c.accent;
    final filledFg = c.ground;
    final filledStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? c.poche : filledBg,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? c.secondary : filledFg,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? c.secondary : filledFg,
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: TypeRole.bodyFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: .3,
        ),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: controlRadius),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
    final outlinedStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? c.secondary : c.ink,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? c.secondary : c.ink,
      ),
      overlayColor: WidgetStatePropertyAll(c.poche.withValues(alpha: .7)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: TypeRole.bodyFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: .2,
        ),
      ),
      side: WidgetStateProperty.resolveWith(
        (s) => BorderSide(
          color: s.contains(WidgetState.disabled)
              ? c.line.withValues(alpha: .45)
              : s.contains(WidgetState.pressed) ||
                    s.contains(WidgetState.focused)
              ? c.accent
              : c.line,
        ),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: controlRadius),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
    final textButtonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? c.secondary : c.accent,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? c.secondary : c.accent,
      ),
      overlayColor: WidgetStatePropertyAll(c.poche.withValues(alpha: .6)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: TypeRole.bodyFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: .2,
        ),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: controlRadius),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
    // Navigation & utility icons sit cleanly without heavy framing boxes;
    // explicit framed icons use IconButton.filled / filledTonal / outlined.
    final iconStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(10)),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? c.secondary.withValues(alpha: .5)
            : c.ink,
      ),
      overlayColor: WidgetStatePropertyAll(c.poche.withValues(alpha: .7)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: controlRadius),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );
    return base.copyWith(
      extensions: [c],
      scaffoldBackgroundColor: c.ground,
      textTheme: text,
      // Android 14 predictive back previews the page underneath.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(
            fallbackColor: c.ground,
          ),
        },
      ),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: overlay(brightness),
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
      filledButtonTheme: FilledButtonThemeData(style: filledStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedStyle),
      textButtonTheme: TextButtonThemeData(style: textButtonStyle),
      iconButtonTheme: IconButtonThemeData(style: iconStyle),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: Space.radius),
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.selected) ? c.accent : c.line,
            width: s.contains(WidgetState.selected) ? 1.5 : 1,
          ),
        ),
        backgroundColor: c.ground,
        selectedColor: c.poche,
        checkmarkColor: c.accent,
        labelStyle: TextStyle(
          fontFamily: TypeRole.bodyFamily,
          fontSize: 13,
          color: c.ink,
        ),
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
