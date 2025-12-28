import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

/// AURA 커스텀 버튼 컴포넌트
/// 
/// 일관된 버튼 스타일을 제공하는 공통 컴포넌트입니다.
enum ButtonVariant {
  primary,
  secondary,
  outlined,
  text,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    Widget button;

    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _getElevatedButtonStyle(),
          child: _buildButtonContent(),
        );
        break;
      case ButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _getSecondaryButtonStyle(),
          child: _buildButtonContent(),
        );
        break;
      case ButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: _getOutlinedButtonStyle(),
          child: _buildButtonContent(),
        );
        break;
      case ButtonVariant.text:
        button = TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: _getTextButtonStyle(),
          child: _buildButtonContent(),
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          SizedBox(width: AppSpacing.sm),
          Text(label, style: _getTextStyle()),
        ],
      );
    }

    return Text(label, style: _getTextStyle());
  }

  ButtonStyle _getElevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      disabledBackgroundColor: AppColors.textDisabled,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
    );
  }

  ButtonStyle _getSecondaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.textOnSecondary,
      disabledBackgroundColor: AppColors.textDisabled,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
    );
  }

  ButtonStyle _getOutlinedButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary),
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
    );
  }

  ButtonStyle _getTextButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: _getPadding(),
      minimumSize: Size(0, _getHeight()),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 32.0;
      case ButtonSize.medium:
        return 44.0;
      case ButtonSize.large:
        return 52.0;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16.0;
      case ButtonSize.medium:
        return 20.0;
      case ButtonSize.large:
        return 24.0;
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return AppTypography.buttonSmall;
      case ButtonSize.medium:
        return AppTypography.button;
      case ButtonSize.large:
        return AppTypography.button.copyWith(fontSize: 18);
    }
  }
}

