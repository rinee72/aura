import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// AURA 커스텀 카드 컴포넌트
/// 
/// 일관된 카드 스타일을 제공하는 공통 컴포넌트입니다.
class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final double? elevation;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppSpacing.radius,
        ),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppSpacing.radius,
        ),
        child: card,
      );
    }

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: card,
      );
    }

    return card;
  }
}

