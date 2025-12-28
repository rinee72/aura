import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../models/question_model.dart';
import '../models/answer_model.dart';
import '../services/question_service.dart';
import '../services/answer_service.dart';
import '../../auth/models/user_model.dart';

/// 질문 상세 화면
/// 
/// WP-2.1: 질문 작성 및 기본 목록 화면
/// 
/// 질문의 상세 내용을 보여주는 화면입니다.
class QuestionDetailScreen extends StatefulWidget {
  const QuestionDetailScreen({
    super.key,
    required this.questionId,
  });

  final String questionId;

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  QuestionModel? _question;
  UserModel? _author;
  AnswerModel? _answer;
  UserModel? _celebrity; // 답변 작성자 (셀럽)
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  /// 질문 상세 정보 로드
  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final question = await QuestionService.getQuestionById(widget.questionId);
      
      if (question == null) {
        setState(() {
          _errorMessage = '질문을 찾을 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      final author = await QuestionService.getQuestionAuthor(question.userId);
      
      // 답변이 있는 경우 답변 정보도 가져오기
      AnswerModel? answer;
      UserModel? celebrity;
      if (question.isAnswered) {
        answer = await AnswerService.getAnswerByQuestionId(question.id);
        if (answer != null) {
          // 답변 작성자 (셀럽) 정보 조회
          celebrity = await QuestionService.getQuestionAuthor(answer.celebrityId);
        }
      }

      setState(() {
        _question = question;
        _author = author;
        _answer = answer;
        _celebrity = celebrity;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          // 사용자 친화적인 에러 메시지
          final errorString = e.toString();
          if (errorString.contains('permission') || errorString.contains('권한')) {
            _errorMessage = '질문을 볼 권한이 없습니다.';
          } else if (errorString.contains('network') || errorString.contains('연결')) {
            _errorMessage = '네트워크 연결을 확인해주세요.';
          } else if (errorString.contains('not found') || errorString.contains('찾을 수')) {
            _errorMessage = '질문을 찾을 수 없습니다.';
          } else {
            _errorMessage = '질문을 불러오는데 실패했습니다. 다시 시도해주세요.';
          }
          _isLoading = false;
        });
      }
    }
  }

  /// 시간 표시 포맷
  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year년 $month월 $day일 $hour:$minute';
  }

  /// 좋아요 토글 처리
  Future<void> _handleLikeToggle() async {
    if (_question == null) return;

    try {
      // 낙관적 UI 업데이트
      final currentLiked = _question!.isLiked;
      final newLikeCount = currentLiked ? _question!.likeCount - 1 : _question!.likeCount + 1;
      
      setState(() {
        _question = _question!.copyWith(
          isLiked: !currentLiked,
          likeCount: newLikeCount,
        );
      });

      // 서버에 좋아요 토글 요청
      await QuestionService.toggleLike(_question!.id);
      
      // 서버에서 최신 데이터 가져오기
      final updatedQuestion = await QuestionService.getQuestionById(_question!.id);
      if (updatedQuestion != null && mounted) {
        setState(() {
          _question = updatedQuestion;
        });
      }
    } catch (e) {
      // 에러 발생 시 원래 상태로 되돌리기
      if (mounted) {
        setState(() {
          // 원래 질문 다시 로드
          _loadQuestion();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('좋아요 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '질문 상세',
        role: 'fan',
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
                        onPressed: () => context.go('/fan/questions'),
                        child: const Text('목록으로 돌아가기'),
                      ),
                    ],
                  ),
                )
              : _question == null
                  ? const Center(child: Text('질문을 찾을 수 없습니다.'))
                  : SingleChildScrollView(
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
                                      _formatDateTime(_question!.createdAt),
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 답변 상태
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: _question!.isAnswered
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                                ),
                                child: Text(
                                  _question!.isAnswered ? '답변완료' : '답변대기',
                                  style: AppTypography.caption.copyWith(
                                    color: _question!.isAnswered ? Colors.green : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 질문 내용
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radius),
                            ),
                            child: Text(
                              _question!.content,
                              style: AppTypography.body1.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 좋아요 버튼
                          InkWell(
                            onTap: _handleLikeToggle,
                            borderRadius: BorderRadius.circular(AppSpacing.radius),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: _question!.isLiked
                                    ? Colors.red.withOpacity(0.1)
                                    : AppColors.textTertiary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.radius),
                                border: Border.all(
                                  color: _question!.isLiked
                                      ? Colors.red.withOpacity(0.3)
                                      : AppColors.textTertiary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _question!.isLiked ? Icons.favorite : Icons.favorite_outline,
                                    size: 24,
                                    color: _question!.isLiked ? Colors.red : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    '${_question!.likeCount}',
                                    style: AppTypography.body1.copyWith(
                                      color: _question!.isLiked ? Colors.red : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // 답변 영역
                          Divider(height: AppSpacing.xl),
                          Text(
                            '답변',
                            style: AppTypography.h5.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // 답변이 있는 경우
                          if (_question!.isAnswered && _answer != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(AppSpacing.radius),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 셀럽 정보 및 답변 시간
                                  Row(
                                    children: [
                                      // 셀럽 프로필 이미지
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.primary.withOpacity(0.2),
                                        backgroundImage: _celebrity?.avatarUrl != null
                                            ? NetworkImage(_celebrity!.avatarUrl!)
                                            : null,
                                        child: _celebrity?.avatarUrl == null
                                            ? Icon(
                                                Icons.person,
                                                size: 24,
                                                color: AppColors.primary,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      
                                      // 셀럽 이름
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _celebrity?.displayName ?? _celebrity?.email ?? '셀럽',
                                              style: AppTypography.h6.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              _formatDateTime(_answer!.createdAt),
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  
                                  // 답변 내용
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                                    ),
                                    child: Text(
                                      _answer!.content,
                                      style: AppTypography.body1.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_question!.isAnswered)
                            // 답변 상태는 있지만 답변 데이터를 불러오지 못한 경우
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.radius),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '답변을 불러오는데 실패했습니다.',
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          else
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
                                    Icons.schedule,
                                    size: 48,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    '아직 답변이 등록되지 않았습니다.',
                                    style: AppTypography.body1.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    '셀럽이 답변을 등록하면 여기에 표시됩니다.',
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}

