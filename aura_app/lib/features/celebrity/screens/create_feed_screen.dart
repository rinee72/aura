import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../services/feed_service.dart';

/// 피드 작성/수정 화면
/// 
/// WP-3.5: 셀럽 피드 작성
/// 
/// 셀럽이 일반 피드를 작성하거나 수정할 수 있는 화면입니다.
class CreateFeedScreen extends StatefulWidget {
  const CreateFeedScreen({
    super.key,
    this.feedId, // 수정 모드일 때 피드 ID
  });

  final String? feedId; // null이면 작성 모드, 값이 있으면 수정 모드

  @override
  State<CreateFeedScreen> createState() => _CreateFeedScreenState();
}

class _CreateFeedScreenState extends State<CreateFeedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isLoadingFeed = false;
  bool _isUploadingImages = false; // 이미지 업로드 중 상태
  String? _errorMessage;
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = []; // 수정 모드에서 기존 이미지 URL
  static const int _maxImages = 5;
  static const int _maxContentLength = 2000;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {}); // 글자수 업데이트를 위해 상태 갱신
    });
    if (widget.feedId != null) {
      _loadFeed();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 피드 로드 (수정 모드)
  Future<void> _loadFeed() async {
    if (widget.feedId == null) return;

    setState(() {
      _isLoadingFeed = true;
    });

    try {
      final feed = await FeedService.getFeedById(widget.feedId!);
      if (feed != null && mounted) {
        setState(() {
          _contentController.text = feed.content;
          _existingImageUrls = List.from(feed.imageUrls);
          _isLoadingFeed = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingFeed = false;
            _errorMessage = '피드를 찾을 수 없습니다.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFeed = false;
          _errorMessage = '피드를 불러오는 중 오류가 발생했습니다: $e';
        });
      }
    }
  }

  /// 이미지 선택
  Future<void> _pickImages() async {
    try {
      // 최대 이미지 개수 확인
      final totalImages = _selectedImages.length + _existingImageUrls.length;
      if (totalImages >= _maxImages) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미지는 최대 $_maxImages개까지 업로드할 수 있습니다.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // 이미지 소스 선택
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

      // 여러 이미지 선택 (갤러리만 지원, 카메라는 1개만)
      if (source == ImageSource.gallery) {
        // 갤러리에서 여러 이미지 선택
        final remainingSlots = _maxImages - totalImages;
        final pickedFiles = await _imagePicker.pickMultiImage();
        
        if (pickedFiles.isNotEmpty) {
          final filesToAdd = pickedFiles
              .take(remainingSlots)
              .map((file) => File(file.path))
              .toList();
          
          setState(() {
            _selectedImages.addAll(filesToAdd);
          });

          if (pickedFiles.length > remainingSlots && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('최대 $_maxImages개까지만 선택할 수 있습니다. ${remainingSlots}개만 추가되었습니다.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        // 카메라로 촬영 (1개만)
        final pickedFile = await _imagePicker.pickImage(source: source);
        if (pickedFile != null) {
          setState(() {
            _selectedImages.add(File(pickedFile.path));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 선택한 이미지 삭제
  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// 기존 이미지 삭제 (수정 모드)
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  /// 피드 제출 처리
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final content = _contentController.text.trim();

    setState(() {
      _isLoading = true;
      _isUploadingImages = _selectedImages.isNotEmpty;
      _errorMessage = null;
    });

    try {
      if (widget.feedId != null) {
        // 수정 모드
        await FeedService.updateFeed(
          feedId: widget.feedId!,
          content: content,
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        );
      } else {
        // 작성 모드
        await FeedService.createFeed(
          content: content,
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.feedId != null ? '피드가 수정되었습니다.' : '피드가 게시되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // 이전 화면으로 돌아가기
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: widget.feedId != null ? '피드 수정' : '피드 작성',
        role: 'celebrity',
      ),
      body: _isLoadingFeed
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && widget.feedId != null
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
                          onPressed: () => context.pop(),
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
                        // 피드 내용 입력
                        TextFormField(
                          controller: _contentController,
                          decoration: InputDecoration(
                            labelText: '피드 내용',
                            hintText: '무엇을 공유하고 싶으신가요?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radius),
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                          ),
                          maxLines: 10,
                          maxLength: _maxContentLength,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '피드 내용을 입력해주세요.';
                            }
                            if (value.trim().length < 10) {
                              return '최소 10자 이상 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // 글자수 표시
                        Text(
                          '${_contentController.text.length} / $_maxContentLength',
                          style: AppTypography.caption.copyWith(
                            color: _contentController.text.length > _maxContentLength
                                ? Colors.red
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // 이미지 섹션
                        Text(
                          '이미지 (최대 $_maxImages개)',
                          style: AppTypography.h6.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        
                        // 기존 이미지 표시 (수정 모드)
                        if (_existingImageUrls.isNotEmpty)
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: _existingImageUrls.asMap().entries.map((entry) {
                              final index = entry.key;
                              final url = entry.value;
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.broken_image);
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeExistingImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        
                        // 선택한 이미지 표시
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: _selectedImages.asMap().entries.map((entry) {
                              final index = entry.key;
                              final file = entry.value;
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                                      child: Image.file(
                                        file,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeSelectedImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.sm),
                        // 이미지 추가 버튼
                        if (_selectedImages.length + _existingImageUrls.length < _maxImages)
                          OutlinedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('이미지 추가'),
                          ),

                        const SizedBox(height: AppSpacing.lg),

                        // 오류 메시지
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.body2.copyWith(
                                color: Colors.red,
                              ),
                            ),
                          ),

                        // 이미지 업로드 중 표시
                        if (_isUploadingImages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '이미지 업로드 중...',
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 버튼 영역 (취소 및 제출)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => context.pop(),
                                child: const Text('취소'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
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
                                    : Text(
                                        widget.feedId != null ? '수정하기' : '게시하기',
                                        style: AppTypography.button,
                                      ),
                              ),
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

