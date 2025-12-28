import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

/// AURA 커스텀 로딩 컴포넌트
/// 
/// 일관된 로딩 인디케이터를 제공하는 공통 컴포넌트입니다.
class CustomLoading extends StatelessWidget {
  const CustomLoading({
    super.key,
    this.message,
    this.size = 24.0,
    this.color,
  });

  final String? message;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final loadingIndicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary,
        ),
      ),
    );

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingIndicator,
          const SizedBox(height: AppSpacing.md),
          Text(
            message!,
            style: AppTypography.body2.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return loadingIndicator;
  }
}

/// 전체 화면 로딩 오버레이
class CustomLoadingOverlay extends StatelessWidget {
  const CustomLoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
  });

  final String? message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.overlayLight,
      child: Center(
        child: CustomLoading(
          message: message,
          size: 32.0,
        ),
      ),
    );
  }
}

