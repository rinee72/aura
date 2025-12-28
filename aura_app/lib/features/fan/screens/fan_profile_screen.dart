import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../services/fan_profile_service.dart';
import '../services/question_service.dart';
import '../services/community_service.dart';
import '../models/question_model.dart';
import '../models/community_post_model.dart';
import '../widgets/question_card.dart';
import '../widgets/community_post_card.dart';

/// 팬 프로필 화면
/// 
/// 팬이 자신의 프로필 정보를 관리하고, 내가 작성한 질문과 게시글을 확인할 수 있는 화면입니다.
class FanProfileScreen extends StatefulWidget {
  const FanProfileScreen({super.key});

  @override
  State<FanProfileScreen> createState() => _FanProfileScreenState();
}

class _FanProfileScreenState extends State<FanProfileScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  late TabController _tabController;
  
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _isUploadingImage = false;
  String? _errorMessage;
  UserModel? _currentUser;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // 내 질문 목록
  List<QuestionModel> _myQuestions = [];
  bool _isLoadingQuestions = false;
  int _questionOffset = 0;
  static const int _questionPageSize = 10;

  // 내 게시글 목록
  List<CommunityPostModel> _myPosts = [];
  bool _isLoadingPosts = false;
  int _postOffset = 0;
  static const int _postPageSize = 10;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 프로필 로드
  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });

    try {
      final profile = await FanProfileService.getMyProfile();

      if (mounted) {
        setState(() {
          _currentUser = profile;
          _displayNameController.text = _currentUser?.displayName ?? '';
          _bioController.text = _currentUser?.bio ?? '';
          _isLoadingProfile = false;
        });
      }

      // 탭이 변경되면 해당 데이터 로드
      _tabController.addListener(_onTabChanged);
      _onTabChanged();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '프로필을 불러오는 중 오류가 발생했습니다: $e';
          _isLoadingProfile = false;
        });
      }
    }
  }

  /// 탭 변경 시 데이터 로드
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      if (_tabController.index == 1 && _myQuestions.isEmpty) {
        _loadMyQuestions();
      } else if (_tabController.index == 2 && _myPosts.isEmpty) {
        _loadMyPosts();
      }
    }
  }

  /// 내 질문 목록 로드
  Future<void> _loadMyQuestions({bool refresh = false}) async {
    if (_isLoadingQuestions) return;

    setState(() {
      _isLoadingQuestions = true;
      if (refresh) {
        _questionOffset = 0;
        _myQuestions = [];
      }
    });

    try {
      final questions = await QuestionService.getMyQuestions(
        limit: _questionPageSize,
        offset: _questionOffset,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _myQuestions = questions;
          } else {
            _myQuestions.addAll(questions);
          }
          _questionOffset += questions.length;
          _isLoadingQuestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuestions = false;
        });
      }
    }
  }

  /// 내 게시글 목록 로드
  Future<void> _loadMyPosts({bool refresh = false}) async {
    if (_isLoadingPosts) return;

    setState(() {
      _isLoadingPosts = true;
      if (refresh) {
        _postOffset = 0;
        _myPosts = [];
      }
    });

    try {
      final posts = await CommunityService.getMyPosts(
        limit: _postPageSize,
        offset: _postOffset,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _myPosts = posts;
          } else {
            _myPosts.addAll(posts);
          }
          _postOffset += posts.length;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  /// 프로필 저장
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FanProfileService.updateProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      // 프로필 새로고침
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 저장되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 프로필 다시 로드
        _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '프로필 저장 실패: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 이미지 삭제
  Future<void> _handleDeleteImage() async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이미지 삭제'),
        content: const Text('프로필 이미지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUploadingImage = true;
      _errorMessage = null;
    });

    try {
      // 이미지 삭제
      await FanProfileService.deleteProfileImage();

      // 프로필 새로고침
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();

      // 프로필 다시 로드
      await _loadProfile();
      
      // 선택한 이미지 초기화
      if (mounted) {
        setState(() {
          _selectedImage = null;
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 이미지가 삭제되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '이미지 삭제 실패: $e';
          _isUploadingImage = false;
        });
      }
    }
  }

  /// 이미지 선택 및 업로드
  Future<void> _handleImagePicker() async {
    try {
      // 이미지 선택 옵션 다이얼로그
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('이미지 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리에서 선택'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('카메라로 촬영'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // 이미지 선택
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);

      setState(() {
        _selectedImage = imageFile;
        _isUploadingImage = true;
        _errorMessage = null;
      });

      // 이미지 업로드
      await FanProfileService.updateProfileImage(imageFile);

      // 프로필 새로고침
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();

      // 프로필 다시 로드
      await _loadProfile();
      
      // 선택한 이미지 초기화 (서버에서 로드한 이미지 사용)
      setState(() {
        _selectedImage = null;
      });

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 이미지가 업로드되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '이미지 업로드 실패: $e';
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '프로필',
        role: 'fan',
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _currentUser == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _errorMessage!,
                          style: AppTypography.body1.copyWith(
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('돌아가기'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // 프로필 정보 섹션
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      color: AppColors.surface,
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.primary.withOpacity(0.2),
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!) as ImageProvider
                                    : (_currentUser?.avatarUrl != null && _currentUser!.avatarUrl!.isNotEmpty
                                        ? NetworkImage(_currentUser!.avatarUrl!) as ImageProvider
                                        : null),
                                child: _selectedImage == null && _currentUser?.avatarUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: AppColors.primary,
                                      )
                                    : null,
                              ),
                              if (_isUploadingImage)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _isUploadingImage ? null : _handleImagePicker,
                                icon: const Icon(Icons.upload),
                                label: const Text('이미지 업로드'),
                              ),
                              if (_currentUser?.avatarUrl != null && _currentUser!.avatarUrl!.isNotEmpty) ...[
                                const SizedBox(width: AppSpacing.sm),
                                OutlinedButton.icon(
                                  onPressed: _isUploadingImage ? null : _handleDeleteImage,
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('이미지 삭제'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _currentUser?.displayName ?? '이름 없음',
                            style: AppTypography.h5.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_currentUser?.bio != null && _currentUser!.bio!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              _currentUser!.bio!,
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // 탭 바
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: '프로필 수정'),
                        Tab(text: '내 질문'),
                        Tab(text: '내 게시글'),
                      ],
                    ),
                    // 탭 뷰
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // 프로필 수정 탭
                          _buildProfileEditTab(),
                          // 내 질문 탭
                          _buildMyQuestionsTab(),
                          // 내 게시글 탭
                          _buildMyPostsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _FanBottomNavigation(),
    );
  }

  /// 프로필 수정 탭
  Widget _buildProfileEditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이름 입력 필드
            Text(
              '이름',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _displayNameController,
              decoration: InputDecoration(
                hintText: '이름을 입력해주세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: AppTypography.body1,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '이름을 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // 소개글 입력 필드
            Text(
              '소개글',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _bioController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: '자신을 소개해주세요 (최대 500자)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: AppTypography.body1,
            ),
            const SizedBox(height: AppSpacing.lg),

            // 이메일 표시 (읽기 전용)
            if (_currentUser != null) ...[
              Text(
                '이메일',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  border: Border.all(
                    color: AppColors.textTertiary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _currentUser!.email,
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // 에러 메시지
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
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
            const SizedBox(height: AppSpacing.lg),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 내 질문 탭
  Widget _buildMyQuestionsTab() {
    if (_isLoadingQuestions && _myQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '작성한 질문이 없습니다.',
              style: AppTypography.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => context.push('/fan/questions/create'),
              icon: const Icon(Icons.add),
              label: const Text('질문 작성하기'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadMyQuestions(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _myQuestions.length + (_isLoadingQuestions ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _myQuestions.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final question = _myQuestions[index];
          return QuestionCard(
            question: question,
            onTap: () => context.push('/fan/questions/${question.id}'),
          );
        },
      ),
    );
  }

  /// 내 게시글 탭
  Widget _buildMyPostsTab() {
    if (_isLoadingPosts && _myPosts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '작성한 게시글이 없습니다.',
              style: AppTypography.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () => context.push('/fan/community/create'),
              icon: const Icon(Icons.add),
              label: const Text('게시글 작성하기'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadMyPosts(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _myPosts.length + (_isLoadingPosts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _myPosts.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = _myPosts[index];
          return CommunityPostCard(
            post: post,
            onTap: () => context.push('/fan/community/${post.id}'),
          );
        },
      ),
    );
  }
}

/// 팬용 Bottom Navigation
class _FanBottomNavigation extends StatelessWidget {
  const _FanBottomNavigation();

  /// 현재 경로에 따른 인덱스 반환
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    switch (location) {
      case '/fan/home':
        return 0;
      case '/fan/questions':
        return 1;
      case '/fan/community':
        return 2;
      case '/fan/profile':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(context),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.question_answer),
          label: '질문',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: '커뮤니티',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '프로필',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/fan/home');
            break;
          case 1:
            context.go('/fan/questions');
            break;
          case 2:
            context.go('/fan/community');
            break;
          case 3:
            context.go('/fan/profile');
            break;
        }
      },
    );
  }
}

