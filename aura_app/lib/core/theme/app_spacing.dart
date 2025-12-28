/// AURA 앱의 간격(Spacing) 디자인 토큰
/// 
/// 일관된 레이아웃 간격을 정의합니다.
/// 모든 간격은 이 클래스를 통해 접근해야 합니다.
class AppSpacing {
  AppSpacing._(); // 인스턴스 생성 방지

  // Base unit: 4px
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Specific spacing
  static const double padding = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double margin = 16.0;
  static const double marginSmall = 8.0;
  static const double marginLarge = 24.0;
  static const double marginXLarge = 32.0;

  // Border radius
  static const double radiusSmall = 4.0;
  static const double radius = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusRound = 999.0; // 완전한 원형

  // Icon sizes
  static const double iconSmall = 16.0;
  static const double icon = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
}

