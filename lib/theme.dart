import 'package:flutter/material.dart';

ThemeData buildDarkAppTheme() {
  const background = Color(0xFF171A1F);
  const cardColor = Color(0xFF252B33);
  const accent = Color(0xFFFF7A1A);
  const textPrimary = Color(0xFFECEFF1);
  const textSecondary = Color(0xFF9EA7B3);

  return _buildTheme(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    cardColor: cardColor,
    accent: accent,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    appBarBackground: const Color(0xFF241E1A),
    dividerColor: const Color(0xFF39414B),
  );
}

ThemeData buildLightAppTheme() {
  const background = Color(0xFFF5F0EA);
  const cardColor = Color(0xFFFFFCF8);
  const accent = Color(0xFFE86A17);
  const textPrimary = Color(0xFF20252C);
  const textSecondary = Color(0xFF5C6673);

  return _buildTheme(
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    cardColor: cardColor,
    accent: accent,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    appBarBackground: const Color(0xFFF0E1D1),
    dividerColor: const Color(0xFFD8CABB),
  );
}

ThemeData _buildTheme({
  required Brightness brightness,
  required Color scaffoldBackgroundColor,
  required Color cardColor,
  required Color accent,
  required Color textPrimary,
  required Color textSecondary,
  required Color appBarBackground,
  required Color dividerColor,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: brightness,
  ).copyWith(
    primary: accent,
    secondary: accent,
    surface: cardColor,
  );

  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: appBarBackground,
      foregroundColor: textPrimary,
      centerTitle: true,
      elevation: 0,
    ),
    cardColor: cardColor,
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(
        color: textSecondary,
        fontSize: 14,
        height: 1.35,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      bodySmall: TextStyle(
        color: textSecondary,
        fontSize: 12,
        height: 1.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cardColor,
        foregroundColor: textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    dividerColor: dividerColor,
  );
}
