import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/curated_question_model.dart';

/// 질문 큐레이션 카드 위젯
/// 
/// WP-3.1: 질문 큐레이션 대시보드
/// 
/// 셀럽 대시보드에서 각 질문을 표시하는 카드 컴포넌트입니다.
class CuratedQuestionCard extends StatelessWidget {
  const CuratedQuestionCard({
    super.key,
    required this.curatedQuestion,
    this.onTap,
  });

  final CuratedQuestionModel curatedQuestion;
  final VoidCallback? onTap;

  /// 시간 표시 포맷
  String _formatTime(DateTime dateTime) {
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
    final question = curatedQuestion.question;
    final author = curatedQuestion.author;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: BorderSide(
          color: question.isAnswered
              ? Colors.green.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 좋아요 수 및 상태 배지
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 좋아요 수
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${question.likeCount}',
                        style: AppTypography.body2.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // 답변 상태 배지
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: question.isAnswered
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Text(
                      question.isAnswered ? '답변완료' : '답변대기',
                      style: AppTypography.caption.copyWith(
                        color: question.isAnswered ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
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
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),

              // 하단 정보: 작성자 및 시간
              Row(
                children: [
                  // 작성자 정보
                  if (author != null) ...[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        author.displayName ?? author.email,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],

                  // 작성 시간
                  Text(
                    _formatTime(question.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // 답변 작성 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(
                    question.isAnswered ? '답변 수정' : '답변 작성',
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

