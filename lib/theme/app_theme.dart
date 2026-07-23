import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const surfaceElevated = Color(0xFF1C1C1C);
  static const border = Color(0xFF2E2E2E);
  static const borderFocus = Color(0xFF4A4A4A);
  static const accent = Color(0xFF3DFF7A);
  static const accentDim = Color(0xFF1A4D2E);
  static const deviceImageBackdrop = Color(0xFFF2F3F7);
  static const deviceImageBackdropEnd = Color(0xFFD9DCE4);
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF8E8E8E);
  static const textMuted = Color(0xFF5C5C5C);
  static const error = Color(0xFFFF6B6B);
  static const success = Color(0xFF3DFF7A);
}

class AppTheme {
  static ThemeData get dark {
    const fontFamily = 'SF Pro Display';

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.accent,
        onPrimary: Colors.black,
        secondary: AppColors.accent,
        error: AppColors.error,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
