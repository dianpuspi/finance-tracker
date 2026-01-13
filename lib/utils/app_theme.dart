import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color darkBlue = Color(0xFF1E3A5F);
  static const Color mediumBlue = Color(0xFF2E5984);
  static const Color lightBlue = Color(0xFF4A90E2);
  
  // Accent Colors
  static const Color orange = Color(0xFFFF6B35);
  static const Color coral = Color(0xFFFF8C61);
  static const Color peach = Color(0xFFFFB088);
  
  // Success & Income
  static const Color green = Color(0xFF06D6A0);
  static const Color lightGreen = Color(0xFFE8F8F5);
  static const Color darkGreen = Color(0xFF05B085);
  
  // Danger & Expense
  static const Color red = Color(0xFFEF476F);
  static const Color lightRed = Color(0xFFFFF0F3);
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF8B97A6);
  static const Color lightGrey = Color(0xFFF7F9FC);
  static const Color darkGrey = Color(0xFF5A6674);
  
  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF1E3A5F),
    Color(0xFF2E5984),
  ];
  
  static const List<Color> accentGradient = [
    Color(0xFFFF6B35),
    Color(0xFFFF8C61),
  ];
  
  static const List<Color> successGradient = [
    Color(0xFF06D6A0),
    Color(0xFF1DE5B8),
  ];
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.darkBlue,
    scaffoldBackgroundColor: AppColors.lightGrey,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.darkBlue,
      primary: AppColors.darkBlue,
      secondary: AppColors.orange,
      tertiary: AppColors.lightBlue,
      error: AppColors.red,
      surface: AppColors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      toolbarHeight: 60,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.orange,
      foregroundColor: Colors.white,
      elevation: 6,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 4,
        shadowColor: AppColors.orange.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.darkBlue,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.darkBlue,
        letterSpacing: -0.3,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.darkBlue,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkBlue,
        letterSpacing: 0.15,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.darkBlue,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.darkGrey,
        letterSpacing: 0.25,
      ),
    ),
  );
}