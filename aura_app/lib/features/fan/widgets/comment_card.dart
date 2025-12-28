import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/community_comment_model.dart';
import '../../auth/models/user_model.dart';

/// 댓글 카드 위젯
/// 
/// WP-2.5: 팬 커뮤니티 (게시글/댓글)
/// 
/// 게시글 상세 화면에서 각 댓글을 표시하는 카드 컴포넌트입니다.
class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.comment,
    this.author,
    this.isAuthor = false,
    this.onDelete,
  });

  final CommunityCommentModel comment;
  final UserModel? author;
  final bool isAuthor; // 현재 사용자가 작성자인지 여부
  final VoidCallback? onDelete;

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
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 작성자 정보 및 시간, 삭제 버튼
            Row(
              children: [
                // 작성자 프로필 이미지 또는 기본 아이콘
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 18,
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
                  _formatTime(comment.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                // 삭제 버튼 (작성자만 표시)
                if (isAuthor && onDelete != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.error,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // 댓글 내용
            Text(
              comment.content,
              style: AppTypography.body1.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

