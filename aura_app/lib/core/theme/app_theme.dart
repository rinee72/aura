import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// AURA 앱의 테마 설정
/// 
/// Material 3 디자인 시스템을 기반으로 한 일관된 테마를 제공합니다.
class AppTheme {
  AppTheme._(); // 인스턴스 생성 방지

  /// Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.h1.copyWith(color: AppColors.textPrimary),
        displayMedium: AppTypography.h2.copyWith(color: AppColors.textPrimary),
        displaySmall: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        headlineLarge: AppTypography.h4.copyWith(color: AppColors.textPrimary),
        headlineMedium: AppTypography.h5.copyWith(color: AppColors.textPrimary),
        headlineSmall: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        titleLarge: AppTypography.h6.copyWith(color: AppColors.textPrimary),
        titleMedium: AppTypography.body1.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: AppTypography.body2.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: AppTypography.body1.copyWith(color: AppColors.textPrimary),
        bodyMedium: AppTypography.body2.copyWith(color: AppColors.textPrimary),
        bodySmall: AppTypography.body3.copyWith(color: AppColors.textSecondary),
        labelLarge: AppTypography.label.copyWith(color: AppColors.textPrimary),
        labelMedium: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
        labelSmall: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        color: AppColors.surface,
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
          side: const BorderSide(color: AppColors.primary),
          textStyle: AppTypography.button,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2,
        shape: CircleBorder(),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: AppColors.background,
    );
  }
}

