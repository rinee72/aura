import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/qa_model.dart';

/// Q&A 카드 위젯
/// 
/// WP-2.4: 답변 피드 (Q&A 연결)
/// 
/// 질문과 답변을 함께 표시하는 카드 컴포넌트입니다.
class QACard extends StatelessWidget {
  const QACard({
    super.key,
    required this.qa,
    this.onTap,
  });

  final QAModel qa;
  final VoidCallback? onTap;

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
              // 질문 섹션
              _buildQuestionSection(),
              const SizedBox(height: AppSpacing.md),
              
              // 구분선
              Divider(
                color: AppColors.divider,
                height: 1,
              ),
              const SizedBox(height: AppSpacing.md),
              
              // 답변 섹션
              _buildAnswerSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// 질문 섹션 빌드
  Widget _buildQuestionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 질문 작성자 정보 및 시간
        Row(
          children: [
            // 질문 아이콘
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.help_outline,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            
            // 질문 작성자 이름
            Expanded(
              child: Text(
                '질문',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            
            // 질문 작성 시간
            Text(
              _formatTime(qa.question.createdAt),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // 질문 내용
        Text(
          qa.question.content,
          style: AppTypography.body1.copyWith(
            color: AppColors.textPrimary,
            height: 1.5,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 답변 섹션 빌드
  Widget _buildAnswerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 셀럽 정보 및 답변 시간
        Row(
          children: [
            // 셀럽 프로필 이미지
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              backgroundImage: qa.celebrity?.avatarUrl != null
                  ? NetworkImage(qa.celebrity!.avatarUrl!)
                  : null,
              child: qa.celebrity?.avatarUrl == null
                  ? Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.primary,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            
            // 셀럽 이름
            Expanded(
              child: Text(
                qa.celebrity?.displayName ?? qa.celebrity?.email ?? '셀럽',
                style: AppTypography.body2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            
            // 답변 시간
            Text(
              _formatTime(qa.answer.createdAt),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // 답변 내용
        Text(
          qa.answer.content,
          style: AppTypography.body1.copyWith(
            color: AppColors.textPrimary,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
