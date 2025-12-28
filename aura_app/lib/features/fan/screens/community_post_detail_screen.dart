import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/permission_error_handler.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/community_post_model.dart';
import '../models/community_comment_model.dart';
import '../services/community_service.dart';
import '../widgets/comment_card.dart';
import '../../auth/models/user_model.dart';

/// 커뮤니티 게시글 상세 화면
/// 
/// WP-2.5: 팬 커뮤니티 (게시글/댓글)
/// 
/// 게시글의 상세 내용과 댓글을 보여주는 화면입니다.
class CommunityPostDetailScreen extends StatefulWidget {
  const CommunityPostDetailScreen({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  CommunityPostModel? _post;
  UserModel? _author;
  List<CommunityCommentModel> _comments = [];
  Map<String, UserModel?> _commentAuthors = {}; // 댓글 ID -> 작성자 정보
  bool _isLoading = true;
  bool _isLoadingComments = false;
  String? _errorMessage;
  
  // 댓글 작성 관련
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// 게시글 상세 정보 로드
  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final post = await CommunityService.getPostById(widget.postId);
      
      if (post == null) {
        setState(() {
          _errorMessage = '게시글을 찾을 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      final author = await CommunityService.getPostAuthor(post.userId);

      setState(() {
        _post = post;
        _author = author;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorString = e.toString();
          if (errorString.contains('permission') || errorString.contains('권한')) {
            _errorMessage = '게시글을 볼 권한이 없습니다.';
          } else if (errorString.contains('network') || errorString.contains('연결')) {
            _errorMessage = '네트워크 연결을 확인해주세요.';
          } else if (errorString.contains('not found') || errorString.contains('찾을 수')) {
            _errorMessage = '게시글을 찾을 수 없습니다.';
          } else {
            _errorMessage = '게시글을 불러오는데 실패했습니다. 다시 시도해주세요.';
          }
          _isLoading = false;
        });
      }
    }
  }

  /// 댓글 목록 로드
  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final comments = await CommunityService.getComments(widget.postId);

      // 작성자 정보 조회
      final authorMap = <String, UserModel?>{};
      for (final comment in comments) {
        final author = await CommunityService.getCommentAuthor(comment.userId);
        authorMap[comment.id] = author;
      }

      setState(() {
        _comments = comments;
        _commentAuthors = authorMap;
        _isLoadingComments = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('댓글을 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 댓글 작성 처리
  Future<void> _handleCommentSubmit() async {
    final content = _commentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('댓글 내용을 입력해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 권한 검증
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    try {
      PermissionChecker.requireRole(user, PermissionChecker.roleFan);
    } on PermissionException catch (e) {
      if (mounted) {
        PermissionErrorHandler.handleError(context, e);
      }
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('권한 확인 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      await CommunityService.createComment(
        communityId: widget.postId,
        content: content,
      );

      // 댓글 입력 필드 초기화
      _commentController.clear();

      // 댓글 목록 새로고침
      await _loadComments();

      // 게시글 정보 새로고침 (댓글 수 업데이트)
      await _loadPost();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('댓글이 등록되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('댓글 등록에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  /// 댓글 삭제 처리
  Future<void> _handleCommentDelete(String commentId) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('정말로 이 댓글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await CommunityService.deleteComment(commentId);

      // 댓글 목록 새로고침
      await _loadComments();

      // 게시글 정보 새로고침 (댓글 수 업데이트)
      await _loadPost();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('댓글이 삭제되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('댓글 삭제에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 게시글 삭제 처리
  Future<void> _handlePostDelete() async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말로 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await CommunityService.deletePost(widget.postId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글이 삭제되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        context.go('/fan/community');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시글 삭제에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 현재 사용자가 게시글 작성자인지 확인
  bool _isPostAuthor() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    return currentUser != null && _post != null && currentUser.id == _post!.userId;
  }

  /// 현재 사용자가 댓글 작성자인지 확인
  bool _isCommentAuthor(String commentUserId) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    return currentUser != null && currentUser.id == commentUserId;
  }

  /// 시간 표시 포맷
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      final year = dateTime.year;
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      return '$year년 $month월 $day일';
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '게시글 상세',
        role: 'fan',
        actions: _isPostAuthor()
            ? [
                // 수정 버튼
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    context.push('/fan/community/${widget.postId}/edit');
                  },
                  tooltip: '수정',
                ),
                // 삭제 버튼
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _handlePostDelete,
                  tooltip: '삭제',
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _errorMessage!,
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () => context.go('/fan/community'),
                        child: const Text('목록으로 돌아가기'),
                      ),
                    ],
                  ),
                )
              : _post == null
                  ? const Center(child: Text('게시글을 찾을 수 없습니다.'))
                  : Column(
                      children: [
                        // 게시글 내용
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 작성자 정보
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.primary.withOpacity(0.2),
                                      child: Icon(
                                        Icons.person,
                                        size: 28,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _author?.displayName ?? _author?.email ?? '익명',
                                            style: AppTypography.h6.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            _formatDateTime(_post!.createdAt),
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // 게시글 제목
                                Text(
                                  _post!.title,
                                  style: AppTypography.h5.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // 게시글 내용
                                Text(
                                  _post!.content,
                                  style: AppTypography.body1.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // 하단 정보 (조회수, 댓글 수)
                                Row(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                          size: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          '${_post!.viewCount}',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.comment,
                                          size: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          '${_post!.commentCount}',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xl),

                                // 댓글 영역
                                Divider(height: AppSpacing.xl),
                                Row(
                                  children: [
                                    Text(
                                      '댓글',
                                      style: AppTypography.h5.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      '${_comments.length}',
                                      style: AppTypography.body2.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // 댓글 목록
                                if (_isLoadingComments)
                                  const Padding(
                                    padding: EdgeInsets.all(AppSpacing.xl),
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                else if (_comments.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    decoration: BoxDecoration(
                                      color: AppColors.textSecondary.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.comment_outlined,
                                          size: 48,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Text(
                                          '아직 댓글이 없습니다.',
                                          style: AppTypography.body1.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ..._comments.map((comment) {
                                    final author = _commentAuthors[comment.id];
                                    final isAuthor = _isCommentAuthor(comment.userId);
                                    return CommentCard(
                                      comment: comment,
                                      author: author,
                                      isAuthor: isAuthor,
                                      onDelete: isAuthor
                                          ? () => _handleCommentDelete(comment.id)
                                          : null,
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),

                        // 댓글 작성 영역
                        if (currentUser != null)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.textTertiary.withOpacity(0.2),
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: _commentController,
                                    hint: '댓글을 입력하세요...',
                                    maxLines: 3,
                                    enabled: !_isSubmittingComment,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                IconButton(
                                  icon: _isSubmittingComment
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.send),
                                  onPressed: _isSubmittingComment ? null : _handleCommentSubmit,
                                  tooltip: '댓글 작성',
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}

