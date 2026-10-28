import 'package:flutter/material.dart';

@immutable
class VistaraPalette extends ThemeExtension<VistaraPalette> {
  const VistaraPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.accent,
    required this.muted,
    required this.line,
    required this.onBackground,
    required this.onAccent,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color accent;
  final Color muted;
  final Color line;
  final Color onBackground;
  final Color onAccent;

  @override
  VistaraPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? accent,
    Color? muted,
    Color? line,
    Color? onBackground,
    Color? onAccent,
  }) {
    return VistaraPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      accent: accent ?? this.accent,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      onBackground: onBackground ?? this.onBackground,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  VistaraPalette lerp(covariant VistaraPalette? other, double t) {
    if (other == null) return this;
    return VistaraPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

extension VistaraThemeContext on BuildContext {
  VistaraPalette get vistara => Theme.of(this).extension<VistaraPalette>()!;
}

class AppTheme {
  static const _lightPalette = VistaraPalette(
    background: Color(0xFFF8F7FC),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF0EEF7),
    accent: Color(0xFF6847E8),
    muted: Color(0xFF696778),
    line: Color(0xFFDFDCE9),
    onBackground: Color(0xFF191727),
    onAccent: Colors.white,
  );

  static const _darkPalette = VistaraPalette(
    background: Color(0xFF08091B),
    surface: Color(0xFF10122A),
    surfaceRaised: Color(0xFF1A1D3D),
    accent: Color(0xFF9A80FF),
    muted: Color(0xFFAAA8BC),
    line: Color(0x2FFFFFFF),
    onBackground: Color(0xFFF4F1FF),
    onAccent: Color(0xFF100B24),
  );

  static final light = _createTheme(_lightPalette, Brightness.light);
  static final dark = _createTheme(_darkPalette, Brightness.dark);

  static ThemeData _createTheme(VistaraPalette palette, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.onAccent,
      secondary: palette.accent,
      onSecondary: palette.onAccent,
      error: brightness == Brightness.dark
          ? const Color(0xFFFFB4AB)
          : const Color(0xFFBA1A1A),
      onError: brightness == Brightness.dark
          ? const Color(0xFF690005)
          : Colors.white,
      surface: palette.surface,
      onSurface: palette.onBackground,
      surfaceContainerHighest: palette.surfaceRaised,
      outline: palette.line,
    );
    final textColor = palette.onBackground;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      colorScheme: scheme,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceRaised,
        contentTextStyle: TextStyle(color: textColor),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.background,
        elevation: 0,
        indicatorColor: palette.accent.withValues(alpha: 0.12),
        height: 66,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? palette.accent
                : palette.muted,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? palette.onBackground
                : palette.muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: TextStyle(color: palette.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: palette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: palette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: palette.accent),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textColor,
          fontSize: 38,
          fontWeight: FontWeight.w800,
          height: 1.05,
          letterSpacing: -1.7,
        ),
        headlineMedium: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: textColor, height: 1.45),
        bodySmall: TextStyle(color: palette.muted, height: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          disabledBackgroundColor: palette.surfaceRaised,
          disabledForegroundColor: palette.muted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: textColor,
          side: BorderSide(color: palette.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      dividerColor: palette.line,
      useMaterial3: true,
    );
  }
}
