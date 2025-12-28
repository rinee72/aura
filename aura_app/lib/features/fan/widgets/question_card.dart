import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/question_model.dart';
import '../../auth/models/user_model.dart';

/// 질문 카드 위젯
/// 
/// WP-2.1: 질문 작성 및 기본 목록 화면
/// WP-2.2: 질문 좋아요 기능 및 정렬
/// 
/// 질문 목록에서 각 질문을 표시하는 카드 컴포넌트입니다.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    this.author,
    this.onTap,
    this.onLikeTap,
  });

  final QuestionModel question;
  final UserModel? author;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;

  /// 시간 표시 포맷
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      // yyyy.MM.dd 형식으로 변환
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 작성자 정보 및 시간
              Row(
                children: [
                  // 작성자 프로필 이미지 또는 기본 아이콘
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  
                  // 작성자 이름
                  Expanded(
                    child: Text(
                      author?.displayName ?? author?.email ?? '익명',
                      style: AppTypography.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  
                  // 작성 시간
                  Text(
                    _formatTime(question.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 질문 내용
              Text(
                question.content,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),

              // 하단 정보 (좋아요 버튼, 답변 상태)
              Row(
                children: [
                  // 좋아요 버튼
                  InkWell(
                    onTap: onLikeTap,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            question.isLiked ? Icons.favorite : Icons.favorite_outline,
                            size: 20,
                            color: question.isLiked ? Colors.red : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '${question.likeCount}',
                            style: AppTypography.caption.copyWith(
                              color: question.isLiked ? Colors.red : AppColors.textSecondary,
                              fontWeight: question.isLiked ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // 답변 상태
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: question.isAnswered
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Text(
                      question.isAnswered ? '답변완료' : '답변대기',
                      style: AppTypography.caption.copyWith(
                        color: question.isAnswered ? Colors.green : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

