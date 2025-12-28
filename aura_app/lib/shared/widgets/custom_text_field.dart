import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

/// AURA 커스텀 텍스트 필드 컴포넌트
/// 
/// 일관된 입력 필드 스타일을 제공하는 공통 컴포넌트입니다.
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          style: AppTypography.body1.copyWith(
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body1.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorText: errorText,
            errorMaxLines: 2,
            counterText: maxLength != null ? null : '',
          ),
        ),
      ],
    );
  }
}

