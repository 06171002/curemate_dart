// lib/config/theme/app_themes.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  // 폰트 스타일 정의 (Pretendard 기준)
  static const _fontFamily = 'Pretendard';

  static const _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 57,
      fontWeight: FontWeight.w800,
    ),
    displayMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 42,
      fontWeight: FontWeight.w800,
    ),
    displaySmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),

    headlineLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    ),

    titleLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),

    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.5,
      letterSpacing: 0.4,
    ),

    labelLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
  );

  // --- 🎨 CureMate 라이트 모드 테마 ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: AppColors.lightBackground,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.white,
      secondary: AppColors.lightTextSecondary,
      onSecondary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      outline: AppColors.lightOutline,
      background: AppColors.lightBackground,
      onBackground: AppColors.lightTextPrimary, // 텍스트 기본 색상
    ),
    textTheme: _textTheme.apply(
      bodyColor: AppColors.lightTextPrimary,
      displayColor: AppColors.lightTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 0,
    ),
    inputDecorationTheme: _buildInputDecoration(isDark: false),
    elevatedButtonTheme: _buildElevatedButtonTheme(isDark: false),
    outlinedButtonTheme: _buildOutlinedButtonTheme(isDark: false),
    textButtonTheme: _buildTextButtonTheme(isDark: false),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFD1D5DB),
      thickness: 1,
    ),
  );

  // --- 🌙 CureMate 다크 모드 테마 ---
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: AppColors.darkBackground,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.black,
      secondary: AppColors.darkTextSecondary,
      onSecondary: AppColors.black,
      error: AppColors.error,
      onError: AppColors.black,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      outline: AppColors.darkOutline,
      background: AppColors.darkBackground,
      onBackground: AppColors.darkTextPrimary, // 텍스트 기본 색상
    ),
    textTheme: _textTheme.apply(
      bodyColor: AppColors.darkTextPrimary,
      displayColor: AppColors.darkTextPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
    ),
    inputDecorationTheme: _buildInputDecoration(isDark: true),
    elevatedButtonTheme: _buildElevatedButtonTheme(isDark: true),
    outlinedButtonTheme: _buildOutlinedButtonTheme(isDark: true),
    textButtonTheme: _buildTextButtonTheme(isDark: true),
    dividerTheme: DividerThemeData(
      color: AppColors.darkOutline.withOpacity(0.8),
      thickness: 1,
    ),
  );

  // --- 테마 재사용을 위한 Helper 함수들 ---

  static InputDecorationTheme _buildInputDecoration({required bool isDark}) {
    final Color hintColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary.withOpacity(0.8);

    return InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          // Primary Pastel Blue 사용
          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
          width: 2.0,
        ),
      ),
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      hintStyle: _textTheme.bodyLarge?.copyWith(
        color: hintColor,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme({
    required bool isDark,
  }) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        // Primary Pastel Blue 사용
        backgroundColor: AppColors.mainBtn,
        foregroundColor: isDark ? AppColors.black : AppColors.white,
        textStyle: _textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 0,
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme({
    required bool isDark,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        // 텍스트 색상 및 테두리 색상 부드럽게 조정
        foregroundColor: isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary,
        textStyle: _textTheme.labelLarge,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        side: BorderSide(
          color: isDark ? AppColors.darkOutline : AppColors.lightOutline,
          width: 1.0,
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.white,
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme({required bool isDark}) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        // 텍스트 색상을 보조 텍스트 색상으로 변경하여 부드러움 확보
        foregroundColor: isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
        textStyle: _textTheme.bodyMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }
}