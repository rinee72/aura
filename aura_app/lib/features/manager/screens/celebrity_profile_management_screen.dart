import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/widgets/custom_button.dart';
import '../services/celebrity_management_service.dart';

/// 셀럽 프로필 관리 화면 (매니저용)
/// 
/// WP-4.4: 셀럽 계정 관리
/// 
/// 매니저가 특정 셀럽의 프로필을 수정할 수 있는 화면입니다.
class CelebrityProfileManagementScreen extends StatefulWidget {
  const CelebrityProfileManagementScreen({
    super.key,
    required this.celebrityId,
  });

  final String celebrityId;

  @override
  State<CelebrityProfileManagementScreen> createState() => _CelebrityProfileManagementScreenState();
}

class _CelebrityProfileManagementScreenState extends State<CelebrityProfileManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _isUploadingImage = false;
  String? _errorMessage;
  CelebrityWithStats? _celebrityData;
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
      final celebrityData = await CelebrityManagementService.getCelebrityProfile(
        widget.celebrityId,
      );

      if (celebrityData == null) {
        if (mounted) {
          setState(() {
            _errorMessage = '셀럽을 찾을 수 없습니다.';
            _isLoadingProfile = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _celebrityData = celebrityData;
          _displayNameController.text = celebrityData.celebrity.displayName ?? '';
          _bioController.text = celebrityData.celebrity.bio ?? '';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorString = e.toString();
        String errorMessage = '프로필을 불러오는 중 오류가 발생했습니다: $e';
        
        // 권한 관련 에러 처리
        if (errorString.contains('권한') || errorString.contains('매니저만')) {
          errorMessage = '셀럽 프로필 조회는 매니저만 가능합니다.';
        } else if (errorString.contains('찾을 수 없습니다')) {
          errorMessage = '셀럽을 찾을 수 없습니다.';
        } else if (errorString.contains('로그인')) {
          errorMessage = '로그인이 필요합니다.';
        } else if (errorString.contains('네트워크') || errorString.contains('연결')) {
          errorMessage = '네트워크 연결을 확인해주세요.';
        }
        
        setState(() {
          _errorMessage = errorMessage;
          _isLoadingProfile = false;
        });
      }
    }
  }

  /// 이미지 선택
  Future<void> _handleImageSelection() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 프로필 이미지 업로드
  Future<void> _handleImageUpload() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
      _errorMessage = null;
    });

    try {
      await CelebrityManagementService.updateCelebrityProfileImage(
        celebrityId: widget.celebrityId,
        imageFile: _selectedImage!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 이미지가 업로드되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 프로필 다시 로드
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '이미지 업로드 중 오류가 발생했습니다: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  /// 프로필 이미지 삭제
  Future<void> _handleImageDelete() async {
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
      await CelebrityManagementService.deleteCelebrityProfileImage(
        widget.celebrityId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필 이미지가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          _selectedImage = null;
        });
        
        // 프로필 다시 로드
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '이미지 삭제 중 오류가 발생했습니다: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
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
      // 프로필 이미지가 선택되었으면 먼저 업로드
      if (_selectedImage != null) {
        try {
          await _handleImageUpload();
        } catch (e) {
          // 이미지 업로드 실패 시에도 프로필 정보는 업데이트 가능하도록
          // 하지만 사용자에게 알림
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미지 업로드 실패: $e\n프로필 정보는 저장됩니다.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }

      // 프로필 정보 업데이트
      await CelebrityManagementService.updateCelebrityProfile(
        celebrityId: widget.celebrityId,
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 저장되었습니다. 셀럽 화면에 반영됩니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 프로필 다시 로드하여 최신 정보 표시
        await _loadProfile();
        
        // 선택한 이미지 초기화 (서버에서 로드한 이미지 사용)
        setState(() {
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorString = e.toString();
        String errorMessage = '프로필 저장 중 오류가 발생했습니다: $e';
        
        // 권한 관련 에러 처리
        if (errorString.contains('권한') || errorString.contains('매니저만')) {
          errorMessage = '셀럽 프로필 수정은 매니저만 가능합니다.';
        } else if (errorString.contains('찾을 수 없습니다')) {
          errorMessage = '셀럽을 찾을 수 없습니다.';
        }
        
        setState(() {
          _errorMessage = errorMessage;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '셀럽 프로필 관리',
        role: 'manager',
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _celebrityData == null
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
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 프로필 이미지 섹션
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: AppColors.surfaceVariant,
                                    backgroundImage: _selectedImage != null
                                        ? FileImage(_selectedImage!) as ImageProvider
                                        : (_celebrityData?.celebrity.avatarUrl != null &&
                                                _celebrityData!.celebrity.avatarUrl!.isNotEmpty
                                            ? NetworkImage(_celebrityData!.celebrity.avatarUrl!) as ImageProvider
                                            : null),
                                    child: _selectedImage == null &&
                                            (_celebrityData?.celebrity.avatarUrl == null ||
                                                _celebrityData!.celebrity.avatarUrl!.isEmpty)
                                        ? Icon(
                                            Icons.person,
                                            size: 60,
                                            color: AppColors.textSecondary,
                                          )
                                        : null,
                                  ),
                                  if (_isUploadingImage)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(60),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _isUploadingImage ? null : _handleImageSelection,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('이미지 선택'),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  if (_celebrityData?.celebrity.avatarUrl != null &&
                                      _celebrityData!.celebrity.avatarUrl!.isNotEmpty)
                                    ElevatedButton.icon(
                                      onPressed: _isUploadingImage ? null : _handleImageDelete,
                                      icon: const Icon(Icons.delete),
                                      label: const Text('삭제'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // 통계 섹션
                        if (_celebrityData != null) ...[
                          Text(
                            '통계',
                            style: AppTypography.h6.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.people,
                                  label: '구독자',
                                  value: '${_celebrityData!.stats.subscriberCount}',
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.question_answer,
                                  label: '답변',
                                  value: '${_celebrityData!.stats.answerCount}',
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.feed,
                                  label: '피드',
                                  value: '${_celebrityData!.stats.feedCount}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],

                        // 프로필 정보 섹션
                        Text(
                          '프로필 정보',
                          style: AppTypography.h6.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 이름/닉네임
                        TextFormField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            labelText: '이름/닉네임',
                            hintText: '셀럽 이름을 입력하세요',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '이름을 입력해주세요';
                            }
                            if (value.trim().length > 50) {
                              return '이름은 50자 이하여야 합니다';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 자기소개
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: '자기소개',
                            hintText: '셀럽 소개를 입력하세요',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                          maxLength: 500,
                          validator: (value) {
                            if (value != null && value.trim().length > 500) {
                              return '자기소개는 500자 이하여야 합니다';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // 에러 메시지
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(AppSpacing.radius),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTypography.body2.copyWith(
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 저장 버튼
                        CustomButton(
                          onPressed: _isLoading ? null : _handleSave,
                          label: '저장',
                          isLoading: _isLoading,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 취소 버튼
                        OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: const Text('취소'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// 통계 카드 위젯
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTypography.h5.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

