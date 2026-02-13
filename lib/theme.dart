import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const background = Color(0xFF1C1F24);
  const cardColor = Color(0xFF2A2F36);
  const accent = Color(0xFFFF6A00); // Ferrit orange
  const textPrimary = Color(0xFFECEFF1);
  const textSecondary = Color(0xFF9EA7B3);

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      secondary: accent,
      surface: cardColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      centerTitle: true,
      elevation: 0,
    ),
    cardColor: cardColor,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textPrimary, fontSize: 18),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      titleLarge: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
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
    dividerColor: const Color(0xFF3A4049),
  );
}
