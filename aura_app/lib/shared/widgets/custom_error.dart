import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import 'custom_button.dart';

/// AURA 커스텀 에러 컴포넌트
/// 
/// 일관된 에러 메시지 표시를 제공하는 공통 컴포넌트입니다.
class CustomError extends StatelessWidget {
  const CustomError({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.icon,
  });

  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            message,
            style: AppTypography.body1.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            CustomButton(
              label: '다시 시도',
              onPressed: onRetry,
              variant: ButtonVariant.primary,
            ),
          ],
        ],
      ),
    );
  }
}

/// 전체 화면 에러 표시
class CustomErrorScreen extends StatelessWidget {
  const CustomErrorScreen({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
  });

  final String message;
  final String? title;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CustomError(
          message: message,
          title: title,
          onRetry: onRetry,
        ),
      ),
    );
  }
}

