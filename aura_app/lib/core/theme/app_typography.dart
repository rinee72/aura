import 'package:flutter/material.dart';

/// AURA 앱의 타이포그래피 디자인 토큰
/// 
/// 일관된 텍스트 스타일을 정의합니다.
/// 모든 텍스트 스타일은 이 클래스를 통해 접근해야 합니다.
class AppTypography {
  AppTypography._(); // 인스턴스 생성 방지

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: -0.5,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );

  // Body Text
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle body3 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0,
  );

  // Caption & Label
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
    letterSpacing: 0.4,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // Button Text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // Overline
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.5,
  );
}

