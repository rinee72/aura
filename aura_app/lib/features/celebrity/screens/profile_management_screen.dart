import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../services/celebrity_profile_service.dart';
import '../widgets/celebrity_bottom_navigation.dart';

/// 셀럽 프로필 관리 화면
/// 
/// WP-3.4: 셀럽 프로필 관리
/// 
/// 셀럽이 자신의 프로필 정보를 관리할 수 있는 화면입니다.
class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _isUploadingImage = false;
  String? _errorMessage;
  UserModel? _currentUser;
  int _subscriberCount = 0;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// 프로필 로드
  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _errorMessage = '로그인이 필요합니다.';
            _isLoadingProfile = false;
          });
        }
        return;
      }

      // 프로필 정보 로드
      final profile = await CelebrityProfileService.getMyProfile();

      // 구독자 수 조회
      int subscriberCount = 0;
      try {
        subscriberCount = await CelebrityProfileService.getSubscriberCount();
      } catch (e) {
        print('⚠️ 구독자 수 조회 실패: $e (계속 진행)');
      }

      if (mounted) {
        setState(() {
          _currentUser = profile;
          _displayNameController.text = _currentUser?.displayName ?? '';
          _bioController.text = _currentUser?.bio ?? '';
          _subscriberCount = subscriberCount;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '프로필을 불러오는 중 오류가 발생했습니다: $e';
          _isLoadingProfile = false;
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      await CelebrityProfileService.updateProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      // 프로필 새로고침
      await authProvider.refreshUserProfile();
      
      // 구독자 수 다시 조회
      try {
        final subscriberCount = await CelebrityProfileService.getSubscriberCount();
        if (mounted) {
          setState(() {
            _subscriberCount = subscriberCount;
          });
        }
      } catch (e) {
        print('⚠️ 구독자 수 조회 실패: $e (계속 진행)');
      }

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
      await CelebrityProfileService.deleteProfileImage();

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
      await CelebrityProfileService.updateProfileImage(imageFile);

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
        title: '프로필 관리',
        role: 'celebrity',
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 프로필 이미지 섹션
                        Card(
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.lg),
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
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                                SizedBox(height: AppSpacing.xs),
                                                Text(
                                                  '업로드 중...',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  '프로필 이미지',
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
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
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 구독자 수 표시
                        Card(
                          color: AppColors.surface,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '구독자',
                                  style: AppTypography.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$_subscriberCount명',
                                  style: AppTypography.h6.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

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
                ),
      bottomNavigationBar: CelebrityBottomNavigation(),
    );
  }
}

