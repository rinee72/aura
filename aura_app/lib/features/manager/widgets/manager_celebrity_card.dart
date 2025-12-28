import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/models/user_model.dart';
import '../services/celebrity_management_service.dart';

/// 매니저용 셀럽 카드 위젯
/// 
/// WP-4.4: 셀럽 계정 관리
/// 
/// 매니저가 셀럽 목록을 볼 때 사용하는 카드 컴포넌트입니다.
/// 프로필 이미지, 이름, 구독자 수, 답변 수, 최근 활동 일시 등을 표시합니다.
class ManagerCelebrityCard extends StatelessWidget {
  const ManagerCelebrityCard({
    super.key,
    required this.celebrity,
    required this.stats,
    this.onTap,
  });

  final UserModel celebrity;
  final CelebrityStats stats;
  final VoidCallback? onTap;

  /// 시간 표시 포맷
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '활동 없음';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      final year = dateTime.year;
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      return '$year.$month.$day';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                child: celebrity.avatarUrl != null && celebrity.avatarUrl!.isNotEmpty
                    ? Image.network(
                        celebrity.avatarUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: AppColors.surfaceVariant,
                            child: Icon(
                              Icons.person,
                              color: AppColors.textSecondary,
                              size: 30,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: AppColors.surfaceVariant,
                        child: Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                          size: 30,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              
              // 셀럽 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름
                    Text(
                      celebrity.displayName ?? celebrity.email,
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    
                    // 이메일
                    Text(
                      celebrity.email,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    // 통계 정보
                    Row(
                      children: [
                        // 구독자 수
                        _buildStatItem(
                          icon: Icons.people,
                          label: '구독자',
                          value: '${stats.subscriberCount}',
                        ),
                        const SizedBox(width: AppSpacing.md),
                        
                        // 답변 수
                        _buildStatItem(
                          icon: Icons.question_answer,
                          label: '답변',
                          value: '${stats.answerCount}',
                        ),
                        const SizedBox(width: AppSpacing.md),
                        
                        // 피드 수
                        _buildStatItem(
                          icon: Icons.feed,
                          label: '피드',
                          value: '${stats.feedCount}',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    
                    // 최근 활동 일시
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '최근 활동: ${_formatTime(stats.lastActivityAt)}',
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

  /// 통계 항목 위젯
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '$label $value',
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

