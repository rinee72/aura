import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/shared/widgets/custom_button.dart';
import 'package:aura_app/shared/widgets/custom_card.dart';
import 'package:aura_app/shared/widgets/custom_error.dart';
import 'package:aura_app/shared/widgets/custom_loading.dart';
import 'package:aura_app/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WP-0.5 디자인 시스템 단위 테스트
/// 
/// Flutter 테스트 엔진 없이도 실행 가능한 단위 테스트입니다.
void main() {
  group('WP-0.5 디자인 토큰 검증', () {
    test('AppColors: 모든 색상이 정의되어 있음', () {
      expect(AppColors.primary, isNotNull);
      expect(AppColors.secondary, isNotNull);
      expect(AppColors.error, isNotNull);
      expect(AppColors.success, isNotNull);
      expect(AppColors.warning, isNotNull);
      expect(AppColors.info, isNotNull);
      expect(AppColors.textPrimary, isNotNull);
      expect(AppColors.textSecondary, isNotNull);
      expect(AppColors.background, isNotNull);
      expect(AppColors.surface, isNotNull);
    });

    test('AppTypography: 모든 텍스트 스타일이 정의되어 있음', () {
      expect(AppTypography.h1, isNotNull);
      expect(AppTypography.h2, isNotNull);
      expect(AppTypography.h3, isNotNull);
      expect(AppTypography.h4, isNotNull);
      expect(AppTypography.h5, isNotNull);
      expect(AppTypography.h6, isNotNull);
      expect(AppTypography.body1, isNotNull);
      expect(AppTypography.body2, isNotNull);
      expect(AppTypography.body3, isNotNull);
      expect(AppTypography.button, isNotNull);
      expect(AppTypography.label, isNotNull);
      expect(AppTypography.caption, isNotNull);
    });

    test('AppSpacing: 모든 간격 값이 정의되어 있고 순서가 올바름', () {
      expect(AppSpacing.xs, greaterThan(0));
      expect(AppSpacing.sm, greaterThan(AppSpacing.xs));
      expect(AppSpacing.md, greaterThan(AppSpacing.sm));
      expect(AppSpacing.lg, greaterThan(AppSpacing.md));
      expect(AppSpacing.xl, greaterThan(AppSpacing.lg));
      expect(AppSpacing.xxl, greaterThan(AppSpacing.xl));
      expect(AppSpacing.radius, greaterThan(0));
    });

    test('AppTheme: lightTheme이 정상 생성되고 Material 3 사용', () {
      final theme = AppTheme.lightTheme;
      expect(theme, isNotNull);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.secondary);
      expect(theme.colorScheme.error, AppColors.error);
    });
  });

  group('WP-0.5 컴포넌트 인스턴스 검증', () {
    test('CustomButton: 모든 변형의 인스턴스 생성 가능', () {
      final primary = CustomButton(
        label: 'Primary',
        onPressed: () {},
        variant: ButtonVariant.primary,
      );
      expect(primary.label, 'Primary');
      expect(primary.variant, ButtonVariant.primary);

      final secondary = CustomButton(
        label: 'Secondary',
        onPressed: () {},
        variant: ButtonVariant.secondary,
      );
      expect(secondary.variant, ButtonVariant.secondary);

      final outlined = CustomButton(
        label: 'Outlined',
        onPressed: () {},
        variant: ButtonVariant.outlined,
      );
      expect(outlined.variant, ButtonVariant.outlined);

      final text = CustomButton(
        label: 'Text',
        onPressed: () {},
        variant: ButtonVariant.text,
      );
      expect(text.variant, ButtonVariant.text);
    });

    test('CustomButton: loading 및 disabled 상태 처리', () {
      final loading = CustomButton(
        label: 'Loading',
        onPressed: () {},
        isLoading: true,
      );
      expect(loading.isLoading, isTrue);

      const disabled = CustomButton(
        label: 'Disabled',
        onPressed: null,
      );
      expect(disabled.onPressed, isNull);
    });

    test('CustomTextField: 인스턴스 생성 및 속성 확인', () {
      // TextEditingController는 Flutter 위젯이므로 테스트에서는 null 허용
      const field = CustomTextField(
        label: '이메일',
        hint: 'name@example.com',
        controller: null, // 테스트에서는 null 허용
        errorText: '필수 입력',
      );
      expect(field.label, '이메일');
      expect(field.hint, 'name@example.com');
      expect(field.errorText, '필수 입력');
    });

    test('CustomCard: 인스턴스 생성 및 onTap 지원', () {
      var tapped = false;
      final card = CustomCard(
        child: Container(), // Text 대신 Container 사용
        onTap: () => tapped = true,
      );
      expect(card.child, isNotNull);
      expect(card.onTap, isNotNull);
      
      // onTap 호출 가능한지 확인
      card.onTap?.call();
      expect(tapped, isTrue);
    });

    test('CustomLoading: 인스턴스 생성 및 메시지 지원', () {
      const loading = CustomLoading(message: '로딩 중', size: 32.0);
      expect(loading.message, '로딩 중');
      expect(loading.size, 32.0);
    });

    test('CustomError: 인스턴스 생성 및 retry 콜백 지원', () {
      var retried = false;
      final error = CustomError(
        message: '에러 발생',
        title: '오류',
        onRetry: () => retried = true,
      );
      expect(error.message, '에러 발생');
      expect(error.title, '오류');
      expect(error.onRetry, isNotNull);
      
      // onRetry 호출 가능한지 확인
      error.onRetry?.call();
      expect(retried, isTrue);
    });
  });
}
