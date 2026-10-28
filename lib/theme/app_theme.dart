import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF08090B);
  static const surface = Color(0xFF121315);
  static const surfaceRaised = Color(0xFF1B1C1F);
  static const accent = Color(0xFFF12D3D);
  static const muted = Color(0xFF929398);
  static const line = Color(0x1FFFFFFF);

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      onPrimary: Colors.white,
      surface: surface,
      onSurface: Color(0xFFF5F5F5),
      secondary: accent,
      error: Color(0xFFFF9C9C),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: Color(0xFFF5F5F5),
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: surfaceRaised,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: background,
      elevation: 0,
      indicatorColor: Colors.transparent,
      height: 66,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? accent : muted,
          size: 22,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          color: states.contains(WidgetState.selected) ? Colors.white : muted,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        );
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: const TextStyle(color: muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: accent),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Color(0xFFF5F5F5),
        fontSize: 38,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -1.7,
      ),
      headlineMedium: TextStyle(
        color: Color(0xFFF5F5F5),
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      titleLarge: TextStyle(
        color: Color(0xFFF5F5F5),
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(color: Color(0xFFE0E1E3), height: 1.45),
      bodySmall: TextStyle(color: muted, height: 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF292A2D),
        disabledForegroundColor: muted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: const Color(0xFFF3F3F0),
        side: const BorderSide(color: line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    dividerColor: line,
    useMaterial3: true,
  );
}
