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
import '../services/question_service.dart';

/// 질문 작성 화면
/// 
/// WP-2.1: 질문 작성 및 기본 목록 화면
/// 
/// 팬이 셀럽에게 질문을 작성할 수 있는 화면입니다.
class CreateQuestionScreen extends StatefulWidget {
  const CreateQuestionScreen({super.key});

  @override
  State<CreateQuestionScreen> createState() => _CreateQuestionScreenState();
}

class _CreateQuestionScreenState extends State<CreateQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // 최대 글자수 제한
  static const int _maxLength = 500;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 질문 제출 처리
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final content = _contentController.text.trim();

    // 빈 질문 검증
    if (content.isEmpty) {
      setState(() {
        _errorMessage = '질문 내용을 입력해주세요.';
      });
      return;
    }

    // 권한 검증 (클라이언트 사이드)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    try {
      PermissionChecker.canCreateQuestion(user);
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

    // 욕설 필터링 검사
    if (ProfanityFilter.containsProfanity(content)) {
      final foundProfanities = ProfanityFilter.findProfanity(content);
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
      await QuestionService.createQuestion(content: content);

      if (mounted) {
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('질문이 등록되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 질문 목록 화면으로 pop (목록 화면의 await context.push()가 완료되어 새로고침이 트리거됨)
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // 사용자 친화적인 에러 메시지 표시
          final errorString = e.toString();
          if (errorString.contains('부적절한 표현') || 
              errorString.contains('질문을 등록할 수 없습니다')) {
            // WP-4.3: 욕설 필터링 차단 메시지
            _errorMessage = errorString
                .replaceAll('Exception: ', '')
                .replaceAll('Exception:', '');
            
            // 경고 다이얼로그 표시
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('질문 등록 불가'),
                content: Text(_errorMessage!),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          } else if (errorString.contains('permission') || errorString.contains('권한')) {
            _errorMessage = '질문 작성 권한이 없습니다. 팬 계정으로 로그인해주세요.';
          } else if (errorString.contains('network') || errorString.contains('연결')) {
            _errorMessage = '네트워크 연결을 확인해주세요.';
          } else {
            _errorMessage = '질문 등록에 실패했습니다. 다시 시도해주세요.';
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('질문 작성'),
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
                          '셀럽에게 궁금한 것을 질문해보세요.',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 질문 내용 입력 필드
                CustomTextField(
                  label: '질문 내용',
                  hint: '질문을 입력해주세요...',
                  controller: _contentController,
                  maxLines: 8,
                  maxLength: _maxLength,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '질문 내용을 입력해주세요.';
                    }
                    if (value.trim().length < 10) {
                      return '질문은 최소 10자 이상 입력해주세요.';
                    }
                    if (value.length > _maxLength) {
                      return '질문은 $_maxLength자 이하여야 합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // 글자수 표시 (Listener 추가 필요)
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _contentController,
                  builder: (context, value, child) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${value.text.length} / $_maxLength',
                        style: AppTypography.caption.copyWith(
                          color: value.text.length > _maxLength
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
                  label: '질문 등록',
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

