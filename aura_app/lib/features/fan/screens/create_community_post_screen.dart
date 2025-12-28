import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/utils/profanity_filter.dart';
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/permission_error_handler.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/community_service.dart';

/// 커뮤니티 게시글 작성/수정 화면
/// 
/// WP-2.5: 팬 커뮤니티 (게시글/댓글)
/// 
/// 팬이 커뮤니티 게시글을 작성하거나 수정할 수 있는 화면입니다.
class CreateCommunityPostScreen extends StatefulWidget {
  const CreateCommunityPostScreen({
    super.key,
    this.postId, // 수정 모드일 때 게시글 ID
  });

  final String? postId; // null이면 작성 모드, 값이 있으면 수정 모드

  @override
  State<CreateCommunityPostScreen> createState() => _CreateCommunityPostScreenState();
}

class _CreateCommunityPostScreenState extends State<CreateCommunityPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingPost = false;
  String? _errorMessage;

  // 최대 글자수 제한
  static const int _maxTitleLength = 100;
  static const int _maxContentLength = 2000;

  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      _loadPost();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 게시글 로드 (수정 모드)
  Future<void> _loadPost() async {
    if (widget.postId == null) return;

    setState(() {
      _isLoadingPost = true;
    });

    try {
      final post = await CommunityService.getPostById(widget.postId!);
      if (post != null && mounted) {
        setState(() {
          _titleController.text = post.title;
          _contentController.text = post.content;
          _isLoadingPost = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingPost = false;
            _errorMessage = '게시글을 찾을 수 없습니다.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPost = false;
          _errorMessage = '게시글을 불러오는 중 오류가 발생했습니다: $e';
        });
      }
    }
  }

  /// 게시글 제출 처리
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // 빈 값 검증
    if (title.isEmpty || content.isEmpty) {
      setState(() {
        _errorMessage = '제목과 내용을 모두 입력해주세요.';
      });
      return;
    }

    // 권한 검증 (클라이언트 사이드)
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
      // 예상치 못한 에러 (권한 검증 이외의 에러)
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

    // 욕설 필터링 검사 (제목과 내용 모두)
    final titleProfanity = ProfanityFilter.containsProfanity(title);
    final contentProfanity = ProfanityFilter.containsProfanity(content);
    
    if (titleProfanity || contentProfanity) {
      final foundProfanities = <String>[];
      if (titleProfanity) {
        foundProfanities.addAll(ProfanityFilter.findProfanity(title));
      }
      if (contentProfanity) {
        foundProfanities.addAll(ProfanityFilter.findProfanity(content));
      }
      final errorMessage = ProfanityFilter.getErrorMessage(foundProfanities);
      
      setState(() {
        _errorMessage = errorMessage;
      });
      
      // 경고 다이얼로그 표시
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('부적절한 표현 감지'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.postId != null) {
        // 수정 모드
        await CommunityService.updatePost(
          postId: widget.postId!,
          title: title,
          content: content,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('게시글이 수정되었습니다.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // 작성 모드
        await CommunityService.createPost(
          title: title,
          content: content,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('게시글이 등록되었습니다.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // 사용자 친화적인 에러 메시지 표시
          final errorString = e.toString();
          if (errorString.contains('permission') || errorString.contains('권한')) {
            _errorMessage = '게시글 작성 권한이 없습니다. 팬 계정으로 로그인해주세요.';
          } else if (errorString.contains('network') || errorString.contains('연결')) {
            _errorMessage = '네트워크 연결을 확인해주세요.';
          } else {
            _errorMessage = widget.postId != null
                ? '게시글 수정에 실패했습니다. 다시 시도해주세요.'
                : '게시글 등록에 실패했습니다. 다시 시도해주세요.';
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPost) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.postId != null ? '게시글 수정' : '게시글 작성'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          automaticallyImplyLeading: true, // 뒤로 가기 버튼 자동 표시
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.postId != null ? '게시글 수정' : '게시글 작성'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        automaticallyImplyLeading: true, // 뒤로 가기 버튼 자동 표시
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 안내 메시지
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                        size: AppSpacing.icon,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '팬들과 자유롭게 소통해보세요.',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 제목 입력 필드
                CustomTextField(
                  label: '제목',
                  hint: '제목을 입력해주세요...',
                  controller: _titleController,
                  maxLines: 1,
                  maxLength: _maxTitleLength,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '제목을 입력해주세요.';
                    }
                    if (value.trim().length < 2) {
                      return '제목은 최소 2자 이상 입력해주세요.';
                    }
                    if (value.length > _maxTitleLength) {
                      return '제목은 $_maxTitleLength자 이하여야 합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 내용 입력 필드
                CustomTextField(
                  label: '내용',
                  hint: '내용을 입력해주세요...',
                  controller: _contentController,
                  maxLines: 12,
                  maxLength: _maxContentLength,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '내용을 입력해주세요.';
                    }
                    if (value.trim().length < 10) {
                      return '내용은 최소 10자 이상 입력해주세요.';
                    }
                    if (value.length > _maxContentLength) {
                      return '내용은 $_maxContentLength자 이하여야 합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // 글자수 표시
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _contentController,
                  builder: (context, value, child) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${value.text.length} / $_maxContentLength',
                        style: AppTypography.caption.copyWith(
                          color: value.text.length > _maxContentLength
                              ? Colors.red
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 에러 메시지
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.body2.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 제출 버튼
                CustomButton(
                  label: widget.postId != null ? '게시글 수정' : '게시글 등록',
                  onPressed: _isLoading ? null : _handleSubmit,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

