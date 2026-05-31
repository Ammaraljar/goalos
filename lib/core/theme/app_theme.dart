import 'package:flutter/material.dart';

class AppColors {
  static const Color priorityRed = Color(0xFFE53935);
  static const Color priorityOrange = Color(0xFFFB8C00);
  static const Color priorityYellow = Color(0xFFFDD835);
  static const Color priorityGreen = Color(0xFF43A047);
  static const Color priorityGray = Color(0xFF9E9E9E);
  static const Color primary = Color(0xFF1A1A2E);
  static const Color secondary = Color(0xFF16213E);
  static const Color accent = Color(0xFF0F3460);
  static const Color highlight = Color(0xFFE94560);
  static const Color surface = Color(0xFF1F2B47);
  static const Color card = Color(0xFF243050);
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8E9AC0);
  static const Color textMuted = Color(0xFF4A5580);
  static const Color background = Color(0xFF0D1117);
  static const Color backgroundLight = Color(0xFF161B27);
  static const Color success = Color(0xFF00BFA5);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF448AFF);
  static const List<Color> categoryColors = [
    Color(0xFF7C4DFF), Color(0xFF00BCD4), Color(0xFF4CAF50),
    Color(0xFFFF9800), Color(0xFFE91E63), Color(0xFF2196F3),
  ];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.highlight, secondary: AppColors.accent,
        surface: AppColors.surface, error: AppColors.error,
        onPrimary: Colors.white, onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background, elevation: 0, centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardTheme(color: AppColors.card, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highlight, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textMuted),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
    );
  }
}

class AppConstants {
  static const String hiveGoalBox = 'goals';
  static const String hiveTaskBox = 'tasks';
  static const String hiveHabitBox = 'habits';
  static const String hiveTimeBlockBox = 'time_blocks';
  static const String hiveSubGoalBox = 'sub_goals';
  static const String hiveBehaviorBox = 'behaviors';
  static const String settingsLanguage = 'language';
  static const String settingsOnboarded = 'onboarded';
  static const List<String> categories = ['health', 'career', 'finance', 'learning', 'relationships', 'personal'];
}
