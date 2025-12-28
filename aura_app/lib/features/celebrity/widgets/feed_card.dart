import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/celebrity_feed_model.dart';

/// 피드 카드 위젯
/// 
/// WP-3.5: 셀럽 피드 작성
/// 
/// 피드 목록에서 각 피드를 표시하는 카드 컴포넌트입니다.
class FeedCard extends StatelessWidget {
  const FeedCard({
    super.key,
    required this.feed,
    this.onEdit,
    this.onDelete,
  });

  final CelebrityFeedModel feed;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// 시간 포맷팅
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
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
        onTap: () {
          // 피드 상세 화면으로 이동 (향후 구현)
        },
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 피드 내용
              Text(
                feed.content,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              
              // 이미지 미리보기
              if (feed.imageUrls.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: feed.imageUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = feed.imageUrls[index];
                      return Container(
                        width: 200,
                        margin: EdgeInsets.only(
                          right: index < feed.imageUrls.length - 1
                              ? AppSpacing.sm
                              : 0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSpacing.radius),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.radius),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.surface,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),
              
              // 작성 시간 및 액션 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateTime(feed.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: onEdit,
                          tooltip: '수정',
                          color: AppColors.primary,
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: onDelete,
                          tooltip: '삭제',
                          color: Colors.red,
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

