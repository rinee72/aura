import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_spacing.dart';
import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/core/theme/app_typography.dart';
import 'package:aura_app/dev/component_showcase.dart';
import 'package:aura_app/shared/widgets/custom_button.dart';
import 'package:aura_app/shared/widgets/custom_card.dart';
import 'package:aura_app/shared/widgets/custom_error.dart';
import 'package:aura_app/shared/widgets/custom_loading.dart';
import 'package:aura_app/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 단위 테스트: 디자인 토큰 검증 (엔진 불필요)
  group('WP-0.5 디자인 토큰 검증', () {
    test('AppColors: 모든 색상이 정의되어 있음', () {
      expect(AppColors.primary, isNotNull);
      expect(AppColors.secondary, isNotNull);
      expect(AppColors.error, isNotNull);
      expect(AppColors.success, isNotNull);
      expect(AppColors.textPrimary, isNotNull);
      expect(AppColors.textSecondary, isNotNull);
    });

    test('AppTypography: 모든 텍스트 스타일이 정의되어 있음', () {
      expect(AppTypography.h1, isNotNull);
      expect(AppTypography.h2, isNotNull);
      expect(AppTypography.body1, isNotNull);
      expect(AppTypography.body2, isNotNull);
      expect(AppTypography.button, isNotNull);
    });

    test('AppSpacing: 모든 간격 값이 정의되어 있음', () {
      expect(AppSpacing.xs, greaterThan(0));
      expect(AppSpacing.sm, greaterThan(AppSpacing.xs));
      expect(AppSpacing.md, greaterThan(AppSpacing.sm));
      expect(AppSpacing.radius, greaterThan(0));
    });

    test('AppTheme: lightTheme이 정상 생성됨', () {
      final theme = AppTheme.lightTheme;
      expect(theme, isNotNull);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
    });
  });

  // 컴포넌트 인스턴스 생성 테스트 (엔진 불필요)
  group('WP-0.5 컴포넌트 인스턴스 검증', () {
    test('CustomButton: 인스턴스 생성 가능', () {
      final button = CustomButton(
        label: '테스트',
        onPressed: () {},
      );
      expect(button.label, '테스트');
      expect(button.onPressed, isNotNull);
    });

    test('CustomTextField: 인스턴스 생성 가능', () {
      final field = CustomTextField(
        label: '테스트',
        controller: TextEditingController(),
      );
      expect(field.label, '테스트');
      expect(field.controller, isNotNull);
    });

    test('CustomCard: 인스턴스 생성 가능', () {
      const card = CustomCard(
        child: Text('테스트'),
      );
      expect(card.child, isNotNull);
    });

    test('CustomLoading: 인스턴스 생성 가능', () {
      const loading = CustomLoading(message: '로딩 중');
      expect(loading.message, '로딩 중');
    });

    test('CustomError: 인스턴스 생성 가능', () {
      const error = CustomError(message: '에러 발생');
      expect(error.message, '에러 발생');
    });

    test('ComponentShowcase: 인스턴스 생성 가능', () {
      const showcase = ComponentShowcase();
      expect(showcase, isNotNull);
    });
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
      routes: {
        '/showcase': (_) => const ComponentShowcase(),
      },
    );
  }

  // 위젯 테스트 (엔진 필요, 환경 문제 시 스킵 가능)
  group('WP-0.5 디자인 시스템 위젯 기본 동작', () {
    testWidgets('CustomButton: label 렌더링 및 disabled 처리', (tester) async {
      await tester.pumpWidget(
        wrap(
          const CustomButton(
            label: '확인',
            onPressed: null,
          ),
        ),
      );

      expect(find.text('확인'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('CustomButton: loading 시 progress 표시', (tester) async {
      await tester.pumpWidget(
        wrap(
          CustomButton(
            label: '로딩',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('CustomTextField: label/hint/error 렌더링', (tester) async {
      await tester.pumpWidget(
        wrap(
          CustomTextField(
            label: '이메일',
            hint: 'name@example.com',
            errorText: '필수 입력',
            controller: TextEditingController(),
          ),
        ),
      );

      expect(find.text('이메일'), findsOneWidget);
      expect(find.text('필수 입력'), findsOneWidget);
      // hint는 입력 전/후 렌더링 환경에 따라 다를 수 있어 최소 존재만 체크
      expect(find.text('name@example.com'), findsOneWidget);
    });

    testWidgets('CustomCard: onTap 호출', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          CustomCard(
            onTap: () => tapped = true,
            child: const Text('카드'),
          ),
        ),
      );

      await tester.tap(find.text('카드'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('CustomLoading: message 포함 시 텍스트 표시', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CustomLoading(message: 'Loading...')));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('CustomError: retry 버튼 클릭 시 콜백 호출', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        wrap(
          CustomError(
            message: '에러',
            onRetry: () => retried = true,
          ),
        ),
      );

      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('ComponentShowcase: 라우트로 진입 가능', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          initialRoute: '/showcase',
          routes: {
            '/showcase': (_) => const ComponentShowcase(),
          },
        ),
      );

      expect(find.text('AURA Component Showcase'), findsOneWidget);
      // 최소 한 개 컴포넌트 섹션이 보이는지 확인
      expect(find.text('Colors'), findsOneWidget);
      expect(find.text('Typography'), findsOneWidget);
    });
  });
}

