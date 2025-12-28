import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/community_post_model.dart';
import '../../auth/models/user_model.dart';

/// 커뮤니티 게시글 카드 위젯
/// 
/// WP-2.5: 팬 커뮤니티 (게시글/댓글)
/// 
/// 커뮤니티 목록에서 각 게시글을 표시하는 카드 컴포넌트입니다.
class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    this.author,
    this.onTap,
  });

  final CommunityPostModel post;
  final UserModel? author;
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
                    _formatTime(post.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 게시글 제목
              Text(
                post.title,
                style: AppTypography.h6.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),

              // 게시글 내용 미리보기
              Text(
                post.content,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),

              // 하단 정보 (조회수, 댓글 수)
              Row(
                children: [
                  // 조회수
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${post.viewCount}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // 댓글 수
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.comment,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${post.commentCount}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

