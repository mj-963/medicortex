import 'package:flutter/material.dart';

/// Professional research workspace theme
/// Light: Warm note-taking inspired with yellowish tones
/// Dark: Professional slate theme for focus
class AppTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color accentTeal = Color(0xFF06B6D4);
  static const Color accentAmber = Color(0xFFF59E0B);

  // Light Theme - Warm Note-Taking Feel
  static const Color lightBackground = Color(0xFFFFF9E6); // Warm cream
  static const Color lightSurface = Color(0xFFFFFDF0); // Note paper color
  static const Color lightSurfaceVariant = Color(0xFFFFF4D6); // Slightly darker note
  static const Color lightBorder = Color(0xFFE8D9B5); // Soft tan border
  static const Color lightText = Color(0xFF3E3222); // Warm dark brown
  static const Color lightTextSecondary = Color(0xFF6B5E4F); // Medium brown
  static const Color lightTextTertiary = Color(0xFF9C8B7A); // Light brown
  static const Color lightAccent = Color(0xFFD97706); // Warm amber

  // Dark Theme - Professional Slate
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF475569);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF94A3B8);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  /// Light Theme - Warm Note-Taking Style
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: lightAccent,
      secondary: accentTeal,
      tertiary: primaryBlue,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightText,
      error: error,
      outline: lightBorder,
    ),
    scaffoldBackgroundColor: lightBackground,

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: lightSurface,
      foregroundColor: lightText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: lightText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: lightTextSecondary),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
      margin: const EdgeInsets.all(8),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: lightSurfaceVariant,
      selectedColor: lightAccent.withValues(alpha: 0.15),
      deleteIconColor: lightTextSecondary,
      labelStyle: const TextStyle(
        color: lightText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(color: lightTextSecondary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: lightBorder),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: lightTextTertiary),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightText,
        side: const BorderSide(color: lightBorder, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
    ),

    iconTheme: const IconThemeData(
      color: lightTextSecondary,
      size: 20,
    ),

    dividerTheme: const DividerThemeData(
      color: lightBorder,
      thickness: 1,
      space: 1,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: lightText,
        letterSpacing: -1,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: lightText,
        letterSpacing: -0.8,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: lightText,
        letterSpacing: -0.6,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: lightText,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: lightText,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: lightText,
        letterSpacing: -0.2,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: lightText,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: lightText,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: lightTextSecondary,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: lightText,
        letterSpacing: -0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: lightTextSecondary,
      ),
    ),
  );

  /// Dark Theme - Professional Slate
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: accentTeal,
      tertiary: accentAmber,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: darkBackground,
      onSurface: darkText,
      error: error,
      outline: darkBorder,
    ),
    scaffoldBackgroundColor: darkBackground,

    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkText,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: darkText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: darkTextSecondary),
    ),

    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
      margin: const EdgeInsets.all(8),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceVariant,
      selectedColor: primaryBlue.withValues(alpha: 0.2),
      deleteIconColor: darkTextSecondary,
      labelStyle: const TextStyle(
        color: darkText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(color: darkTextSecondary),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: darkBorder),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: darkTextTertiary),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkText,
        side: const BorderSide(color: darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
    ),

    iconTheme: const IconThemeData(
      color: darkTextSecondary,
      size: 20,
    ),

    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 1,
      space: 1,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkText,
        letterSpacing: -1,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkText,
        letterSpacing: -0.8,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkText,
        letterSpacing: -0.6,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkText,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkText,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: darkText,
        letterSpacing: -0.2,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: darkText,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: darkText,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: darkTextSecondary,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: darkText,
        letterSpacing: -0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: darkTextSecondary,
      ),
    ),
  );
}
