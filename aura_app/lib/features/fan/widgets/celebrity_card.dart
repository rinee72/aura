import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/models/user_model.dart';

/// 셀럽 카드 위젯
/// 
/// WP-2.3: 셀럽 프로필 및 구독 시스템
/// 
/// 셀럽 목록에서 각 셀럽을 표시하는 카드 컴포넌트입니다.
class CelebrityCard extends StatelessWidget {
  const CelebrityCard({
    super.key,
    required this.celebrity,
    required this.subscriberCount,
    this.onTap,
  });

  final UserModel celebrity;
  final int subscriberCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // 프로필 이미지
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                backgroundImage: celebrity.avatarUrl != null
                    ? NetworkImage(celebrity.avatarUrl!)
                    : null,
                child: celebrity.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: 32,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),

              // 셀럽 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 셀럽 이름
                    Text(
                      celebrity.displayName ?? celebrity.email,
                      style: AppTypography.h6.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // 간단 소개 (bio가 있으면 표시)
                    if (celebrity.bio != null && celebrity.bio!.isNotEmpty)
                      Text(
                        celebrity.bio!,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: AppSpacing.xs),

                    // 구독자 수
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '구독자 $subscriberCount명',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 화살표 아이콘
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

