import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../fan/models/question_model.dart';
import '../../auth/models/user_model.dart';

/// 매니저용 질문 카드 위젯
/// 
/// WP-4.1: 매니저 대시보드 및 질문 모니터링
/// 
/// 매니저가 모든 질문을 모니터링할 때 사용하는 카드 컴포넌트입니다.
/// 숨김 상태, 작성자 정보, 위험도 등을 표시합니다.
class ManagerQuestionCard extends StatelessWidget {
  const ManagerQuestionCard({
    super.key,
    required this.question,
    this.author,
    this.hiddenBy, // 숨김 처리한 매니저 정보
    this.onTap,
    this.riskLevel, // 'low', 'medium', 'high' (WP-4.3과 연동, 선택)
    this.onHide,
    this.onUnhide,
    this.onUpdateReason,
  });

  final QuestionModel question;
  final UserModel? author;
  final UserModel? hiddenBy; // 숨김 처리한 매니저 정보
  final VoidCallback? onTap;
  final String? riskLevel; // 위험도 레벨 (WP-4.3과 연동)
  final VoidCallback? onHide; // 숨기기 콜백
  final VoidCallback? onUnhide; // 복구 콜백
  final VoidCallback? onUpdateReason; // 숨김 사유 수정 콜백

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

  /// 위험도에 따른 색상 반환
  Color _getRiskColor(String? riskLevel) {
    switch (riskLevel) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow.shade700;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: question.isHidden ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: question.isHidden
            ? const BorderSide(color: Colors.red, width: 2)
            : riskLevel != null
                ? BorderSide(color: _getRiskColor(riskLevel), width: 1.5)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 작성자 정보 및 상태 배지
              Row(
                children: [
                  // 작성자 프로필 이미지 또는 기본 아이콘
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage: author?.avatarUrl != null
                        ? NetworkImage(author!.avatarUrl!)
                        : null,
                    child: author?.avatarUrl == null
                        ? Icon(
                            Icons.person,
                            size: 20,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  
                  // 작성자 이름
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author?.displayName ?? author?.email ?? '알 수 없음',
                          style: AppTypography.body2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (author?.email != null)
                          Text(
                            author!.email,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // 상태 배지들
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      // 숨김 상태 배지
                      if (question.isHidden)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '숨김',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      // 답변 상태 배지
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: question.isAnswered
                              ? Colors.green
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          question.isAnswered ? '답변완료' : '미답변',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // 위험도 배지 (WP-4.3과 연동)
                      if (riskLevel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getRiskColor(riskLevel),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            riskLevel == 'high'
                                ? '위험'
                                : riskLevel == 'medium'
                                    ? '주의'
                                    : '낮음',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // 질문 내용
              Text(
                question.content,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: AppSpacing.sm),
              
              // 숨김 정보 (숨김 처리된 경우)
              if (question.isHidden && question.hiddenReason != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '숨김 사유',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              question.hiddenReason!,
                              style: AppTypography.caption.copyWith(
                                color: Colors.red.shade700,
                              ),
                            ),
                            if (question.hiddenAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '숨김 일시: ${_formatTime(question.hiddenAt!)}',
                                style: AppTypography.caption.copyWith(
                                  color: Colors.red.shade600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              
              // 하단: 좋아요 수 및 작성 시간
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 16,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${question.likeCount}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatTime(question.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              
              // 액션 버튼 (숨기기/복구)
              if (onHide != null || onUnhide != null || onUpdateReason != null) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 숨김 사유 수정 버튼 (숨김 처리된 경우)
                    if (question.isHidden && onUpdateReason != null)
                      TextButton.icon(
                        onPressed: onUpdateReason,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('사유 수정'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    
                    // 복구 버튼 (숨김 처리된 경우)
                    if (question.isHidden && onUnhide != null)
                      TextButton.icon(
                        onPressed: onUnhide,
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('복구'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                    
                    // 숨기기 버튼 (숨김 처리되지 않은 경우)
                    if (!question.isHidden && onHide != null)
                      TextButton.icon(
                        onPressed: onHide,
                        icon: const Icon(Icons.visibility_off, size: 16),
                        label: const Text('숨기기'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

