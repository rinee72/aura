import 'package:flutter/material.dart';

/// AURA 앱의 색상 디자인 토큰
/// 
/// 일관된 UI를 위한 색상 팔레트를 정의합니다.
/// 모든 색상은 이 클래스를 통해 접근해야 합니다.
class AppColors {
  AppColors._(); // 인스턴스 생성 방지

  // Primary Colors (Indigo 계열)
  static const Color primary = Color(0xFF6366F1); // Indigo-500
  static const Color primaryLight = Color(0xFF818CF8); // Indigo-400
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo-600
  static const Color primaryContainer = Color(0xFFE0E7FF); // Indigo-100

  // Secondary Colors (Amber 계열)
  static const Color secondary = Color(0xFFF59E0B); // Amber-500
  static const Color secondaryLight = Color(0xFFFBBF24); // Amber-400
  static const Color secondaryDark = Color(0xFFD97706); // Amber-600
  static const Color secondaryContainer = Color(0xFFFEF3C7); // Amber-100

  // Background & Surface
  static const Color background = Color(0xFFF9FAFB); // Gray-50
  static const Color surface = Color(0xFFFFFFFF); // White
  static const Color surfaceVariant = Color(0xFFF3F4F6); // Gray-100

  // Error & Status Colors
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color errorLight = Color(0xFFFEE2E2); // Red-100
  static const Color success = Color(0xFF10B981); // Green-500
  static const Color successLight = Color(0xFFD1FAE5); // Green-100
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber-100
  static const Color info = Color(0xFF3B82F6); // Blue-500
  static const Color infoLight = Color(0xFFDBEAFE); // Blue-100

  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // Gray-900
  static const Color textSecondary = Color(0xFF6B7280); // Gray-500
  static const Color textTertiary = Color(0xFF9CA3AF); // Gray-400
  static const Color textDisabled = Color(0xFFD1D5DB); // Gray-300
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White
  static const Color textOnSecondary = Color(0xFFFFFFFF); // White

  // Border & Divider
  static const Color border = Color(0xFFE5E7EB); // Gray-200
  static const Color divider = Color(0xFFE5E7EB); // Gray-200

  // Overlay
  static const Color overlay = Color(0x80000000); // Black with 50% opacity
  static const Color overlayLight = Color(0x40000000); // Black with 25% opacity
}

