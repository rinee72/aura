import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/permission_error_handler.dart';
import '../../../shared/utils/profanity_filter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../fan/models/question_model.dart';
import '../../fan/models/answer_model.dart';
import '../../fan/services/question_service.dart';
import '../services/answer_service.dart';

/// 답변 작성 화면
/// 
/// WP-3.2: 답변 작성 시스템
/// 
/// 셀럽이 질문에 대한 답변을 작성하고 게시할 수 있는 화면입니다.
class CreateAnswerScreen extends StatefulWidget {
  final String questionId;

  const CreateAnswerScreen({
    super.key,
    required this.questionId,
  });

  @override
  State<CreateAnswerScreen> createState() => _CreateAnswerScreenState();
}

class _CreateAnswerScreenState extends State<CreateAnswerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  
  QuestionModel? _question;
  AnswerModel? _existingAnswer;
  bool _isLoading = false;
  bool _isLoadingQuestion = true;
  String? _errorMessage;
  
  // 글자수 제한
  static const int _minLength = 10;
  static const int _maxLength = 5000;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() {}); // 글자수 업데이트를 위해 상태 갱신
    });
    _loadQuestionAndAnswer();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 질문 및 기존 답변 로드
  Future<void> _loadQuestionAndAnswer() async {
    setState(() {
      _isLoadingQuestion = true;
      _errorMessage = null;
    });

    try {
      // 권한 검증
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleCelebrity);
      } on PermissionException catch (e) {
        if (mounted) {
          PermissionErrorHandler.handleError(context, e);
          setState(() {
            _errorMessage = '답변 작성은 셀럽만 가능합니다.';
            _isLoadingQuestion = false;
          });
        }
        return;
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = '권한 확인 중 오류가 발생했습니다: $e';
            _isLoadingQuestion = false;
          });
        }
        return;
      }

      // 질문 조회
      final question = await QuestionService.getQuestionById(widget.questionId);
      
      if (question == null) {
        if (mounted) {
          setState(() {
            _errorMessage = '질문을 찾을 수 없습니다.';
            _isLoadingQuestion = false;
          });
        }
        return;
      }

      // 숨김 처리된 질문인지 확인
      if (question.isHidden) {
        if (mounted) {
          setState(() {
            _errorMessage = '숨김 처리된 질문에는 답변할 수 없습니다.';
            _isLoadingQuestion = false;
          });
        }
        return;
      }

      // 기존 답변 조회
      AnswerModel? existingAnswer;
      try {
        existingAnswer = await AnswerService.getAnswerByQuestionId(widget.questionId);
      } catch (e) {
        // 답변이 없으면 null (정상)
        print('ℹ️ 기존 답변 없음: $e');
      }

      if (mounted) {
        setState(() {
          _question = question;
          _existingAnswer = existingAnswer;
          if (existingAnswer != null) {
            _contentController.text = existingAnswer.content;
          }
          _isLoadingQuestion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '질문을 불러오는 중 오류가 발생했습니다: $e';
          _isLoadingQuestion = false;
        });
      }
    }
  }

  /// 임시저장 처리
  Future<void> _handleSaveDraft() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = _contentController.text.trim();

      if (_existingAnswer != null) {
        // 기존 답변 수정
        await AnswerService.updateAnswer(
          answerId: _existingAnswer!.id,
          content: content,
          isDraft: true,
        );
      } else {
        // 새 답변 생성 (임시저장)
        await AnswerService.createAnswer(
          questionId: widget.questionId,
          content: content,
          isDraft: true,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('임시저장되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 기존 답변 정보 업데이트
        _loadQuestionAndAnswer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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

  /// 게시 처리
  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = _contentController.text.trim();

      if (_existingAnswer != null) {
        if (_existingAnswer!.isDraft) {
          // 임시저장 답변을 게시로 전환
          await AnswerService.publishAnswer(_existingAnswer!.id);
        } else {
          // 이미 게시된 답변 수정
          await AnswerService.updateAnswer(
            answerId: _existingAnswer!.id,
            content: content,
            isDraft: false,
          );
        }
      } else {
        // 새 답변 생성 (게시)
        await AnswerService.createAnswer(
          questionId: widget.questionId,
          content: content,
          isDraft: false,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변이 게시되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 이전 화면으로 돌아가기
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: _existingAnswer != null ? '답변 수정' : '답변 작성',
        role: 'celebrity',
      ),
      body: _isLoadingQuestion
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _question == null
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
              : _question == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 질문 내용 표시
                            Card(
                              color: AppColors.surface,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.question_answer,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Text(
                                          '질문',
                                          style: AppTypography.h6.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      _question!.content,
                                      style: AppTypography.body1.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // 답변 입력 필드
                            Text(
                              '답변',
                              style: AppTypography.h6.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _contentController,
                              maxLines: 15,
                              maxLength: _maxLength,
                              decoration: InputDecoration(
                                hintText: '답변을 입력해주세요 (최소 $_minLength자, 최대 $_maxLength자)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                                ),
                                filled: true,
                                fillColor: AppColors.surface,
                              ),
                              style: AppTypography.body1,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '답변 내용을 입력해주세요.';
                                }
                                final trimmed = value.trim();
                                if (trimmed.length < _minLength) {
                                  return '답변은 최소 $_minLength자 이상 입력해주세요.';
                                }
                                if (trimmed.length > _maxLength) {
                                  return '답변은 최대 $_maxLength자까지 입력 가능합니다.';
                                }
                                if (ProfanityFilter.containsProfanity(trimmed)) {
                                  return '답변에 부적절한 단어가 포함되어 있습니다.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),

                            // 글자수 표시
                            Text(
                              '${_contentController.text.length} / $_maxLength',
                              style: AppTypography.caption.copyWith(
                                color: _contentController.text.length > _maxLength
                                    ? Colors.red
                                    : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: AppSpacing.lg),

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

                            // 기존 답변 상태 표시
                            if (_existingAnswer != null)
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: _existingAnswer!.isDraft
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _existingAnswer!.isDraft
                                          ? Icons.save_alt
                                          : Icons.check_circle,
                                      color: _existingAnswer!.isDraft
                                          ? Colors.orange
                                          : Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      _existingAnswer!.isDraft
                                          ? '임시저장된 답변이 있습니다.'
                                          : '이미 게시된 답변이 있습니다.',
                                      style: AppTypography.body2.copyWith(
                                        color: _existingAnswer!.isDraft
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: AppSpacing.lg),

                            // 버튼 영역
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
                                  child: OutlinedButton(
                                    onPressed: _isLoading ? null : _handleSaveDraft,
                                    child: const Text('임시저장'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handlePublish,
                                    style: ElevatedButton.styleFrom(
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
                                        : const Text('게시'),
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

