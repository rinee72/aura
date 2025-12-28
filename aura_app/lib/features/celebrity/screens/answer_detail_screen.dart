import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/permission_error_handler.dart';
import '../../../core/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../fan/models/answer_model.dart';
import '../../fan/models/question_model.dart';
import '../../fan/services/question_service.dart';
import '../services/answer_service.dart';

/// 답변 상세 화면
/// 
/// WP-3.3: 답변 관리
/// 
/// 셀럽이 자신의 답변을 상세히 확인하고 수정/삭제할 수 있는 화면입니다.
class AnswerDetailScreen extends StatefulWidget {
  final String answerId;

  const AnswerDetailScreen({
    super.key,
    required this.answerId,
  });

  @override
  State<AnswerDetailScreen> createState() => _AnswerDetailScreenState();
}

class _AnswerDetailScreenState extends State<AnswerDetailScreen> {
  AnswerModel? _answer;
  QuestionModel? _question;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnswer();
  }

  /// 답변 및 질문 로드
  Future<void> _loadAnswer() async {
    setState(() {
      _isLoading = true;
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
            _errorMessage = '답변 조회는 셀럽만 가능합니다.';
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = '권한 확인 중 오류가 발생했습니다: $e';
            _isLoading = false;
          });
        }
        return;
      }

      // 답변 조회 (RLS 정책에 의해 자신의 답변만 조회 가능)
      final client = SupabaseConfig.client;
      final answerResponse = await client
          .from('answers')
          .select()
          .eq('id', widget.answerId)
          .maybeSingle();

      if (answerResponse == null) {
        if (mounted) {
          setState(() {
            _errorMessage = '답변을 찾을 수 없습니다.';
            _isLoading = false;
          });
        }
        return;
      }

      final answer = AnswerModel.fromJson(answerResponse);

      // 자신의 답변인지 확인
      if (answer.celebrityId != user!.id) {
        if (mounted) {
          setState(() {
            _errorMessage = '자신의 답변만 조회할 수 있습니다.';
            _isLoading = false;
          });
        }
        return;
      }

      // 질문 정보 조회
      QuestionModel? question;
      try {
        question = await QuestionService.getQuestionById(answer.questionId);
      } catch (e) {
        print('⚠️ 질문 조회 실패: $e (계속 진행)');
      }

      if (mounted) {
        setState(() {
          _answer = answer;
          _question = question;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '답변을 불러오는 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 답변 수정 화면으로 이동
  void _handleEdit() {
    if (_answer == null) return;
    context.push(
      '/celebrity/questions/${_answer!.questionId}/answer',
    );
  }

  /// 답변 삭제 처리
  Future<void> _handleDelete() async {
    if (_answer == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('답변 삭제'),
        content: const Text('정말로 이 답변을 삭제하시겠습니까?\n삭제된 답변은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await AnswerService.deleteAnswer(_answer!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변이 삭제되었습니다.'),
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
          _errorMessage = '답변 삭제 실패: $e';
          _isProcessing = false;
        });
      }
    }
  }

  /// 임시저장 → 게시 전환
  Future<void> _handlePublish() async {
    if (_answer == null || !_answer!.isDraft) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await AnswerService.publishAnswer(_answer!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변이 게시되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 답변 정보 새로고침
        _loadAnswer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '답변 게시 실패: $e';
          _isProcessing = false;
        });
      }
    }
  }

  /// 게시 → 임시저장 전환
  Future<void> _handleUnpublish() async {
    if (_answer == null || _answer!.isDraft) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('답변 임시저장 전환'),
        content: const Text('게시된 답변을 임시저장으로 전환하시겠습니까?\n팬들에게 더 이상 표시되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('전환'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await AnswerService.updateAnswer(
        answerId: _answer!.id,
        content: _answer!.content,
        isDraft: true,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변이 임시저장으로 전환되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 답변 정보 새로고침
        _loadAnswer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '답변 전환 실패: $e';
          _isProcessing = false;
        });
      }
    }
  }

  /// 시간 표시 포맷
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
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
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '답변 상세',
        role: 'celebrity',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _answer == null
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
              : _answer == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상태 배지
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _answer!.isDraft
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            ),
                            child: Text(
                              _answer!.isDraft ? '임시저장' : '게시됨',
                              style: AppTypography.caption.copyWith(
                                color: _answer!.isDraft ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // 질문 섹션
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
                                  if (_question != null)
                                    Text(
                                      _question!.content,
                                      style: AppTypography.body1.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.6,
                                      ),
                                    )
                                  else
                                    Text(
                                      '질문 정보를 불러올 수 없습니다.',
                                      style: AppTypography.body2.copyWith(
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 답변 섹션
                          Text(
                            '답변',
                            style: AppTypography.h6.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Card(
                            color: AppColors.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _answer!.content,
                                    style: AppTypography.body1.copyWith(
                                      color: AppColors.textPrimary,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Divider(color: AppColors.divider),
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        '작성: ${_formatTime(_answer!.createdAt)}',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (_answer!.updatedAt != _answer!.createdAt) ...[
                                        const SizedBox(width: AppSpacing.md),
                                        Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Text(
                                          '수정: ${_formatTime(_answer!.updatedAt)}',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textSecondary,
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

                          // 액션 버튼
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isProcessing ? null : _handleEdit,
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('수정'),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isProcessing
                                      ? null
                                      : _answer!.isDraft
                                          ? _handlePublish
                                          : _handleUnpublish,
                                  icon: Icon(
                                    _answer!.isDraft ? Icons.publish : Icons.save_alt,
                                    size: 18,
                                  ),
                                  label: Text(_answer!.isDraft ? '게시' : '임시저장 전환'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _answer!.isDraft
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing ? null : _handleDelete,
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('삭제'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

