import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/permission_error_handler.dart';
import '../../auth/providers/auth_provider.dart';
import '../../fan/models/answer_model.dart';
import '../../fan/models/question_model.dart';
import '../../fan/services/question_service.dart';
import '../services/answer_service.dart';
import '../widgets/celebrity_bottom_navigation.dart';

/// 내 답변 목록 화면
/// 
/// WP-3.3: 답변 관리
/// 
/// 셀럽이 자신이 작성한 답변 목록을 확인하고 관리할 수 있는 화면입니다.
class MyAnswersScreen extends StatefulWidget {
  const MyAnswersScreen({super.key});

  @override
  State<MyAnswersScreen> createState() => _MyAnswersScreenState();
}

class _MyAnswersScreenState extends State<MyAnswersScreen> {
  List<_AnswerWithQuestion> _answers = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // 필터 상태
  String _statusFilter = 'all'; // 'all', 'published', 'draft'
  String _sortBy = 'newest'; // 'newest', 'oldest'
  String _dateFilter = 'all'; // 'all', 'today', 'week', 'month'
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim();
      });
    });
    _loadAnswers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 답변 목록 로드
  Future<void> _loadAnswers() async {
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
            _errorMessage = '답변 관리는 셀럽만 사용할 수 있습니다.';
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

      // 날짜 필터 계산
      DateTime? startDate;
      final now = DateTime.now();
      if (_dateFilter == 'today') {
        startDate = DateTime(now.year, now.month, now.day);
      } else if (_dateFilter == 'week') {
        startDate = now.subtract(const Duration(days: 7));
      } else if (_dateFilter == 'month') {
        startDate = DateTime(now.year, now.month, 1);
      }

      // AnswerService.getMyAnswers() 사용
      final answersData = await AnswerService.getMyAnswers(
        statusFilter: _statusFilter,
        sortBy: _sortBy,
        startDate: startDate,
        searchQuery: _searchQuery,
      );

      // 질문 정보와 함께 조회
      final answersWithQuestions = <_AnswerWithQuestion>[];
      for (final item in answersData) {
        final answerData = item['answer'] as Map<String, dynamic>;
        final answer = AnswerModel.fromJson(answerData);
        
        // 질문 정보 조회
        QuestionModel? question;
        try {
          question = await QuestionService.getQuestionById(answer.questionId);
        } catch (e) {
          print('⚠️ 질문 조회 실패: $e (계속 진행)');
        }

        // 검색어가 있으면 질문 내용도 검색 (서비스 레벨에서 답변 내용만 검색했으므로 여기서 추가 필터링)
        if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
          final queryLower = _searchQuery!.toLowerCase().trim();
          final answerContent = answer.content.toLowerCase();
          final questionContent = question?.content.toLowerCase() ?? '';
          
          // 답변 내용과 질문 내용 모두에 검색어가 없으면 건너뛰기
          if (!answerContent.contains(queryLower) && !questionContent.contains(queryLower)) {
            continue;
          }
        }

        answersWithQuestions.add(_AnswerWithQuestion(
          answer: answer,
          question: question,
        ));
      }

      if (mounted) {
        setState(() {
          _answers = answersWithQuestions;
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

  /// 답변 삭제 처리
  Future<void> _handleDeleteAnswer(AnswerModel answer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('답변 삭제'),
        content: const Text('정말로 이 답변을 삭제하시겠습니까?'),
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

    try {
      await AnswerService.deleteAnswer(answer.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변이 삭제되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 목록 새로고침
        _loadAnswers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('답변 삭제 실패: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '내 답변',
        role: 'celebrity',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnswers,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnswers,
        child: CustomScrollView(
          slivers: [
            // 필터 섹션
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.textTertiary.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 검색 필드
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '답변 내용 검색...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radius),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      onSubmitted: (_) => _loadAnswers(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    // 상태 필터
                    Text(
                      '상태',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _buildFilterChip(
                          label: '전체',
                          value: 'all',
                          selected: _statusFilter == 'all',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _statusFilter = 'all';
                              });
                              _loadAnswers();
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip(
                          label: '게시됨',
                          value: 'published',
                          selected: _statusFilter == 'published',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _statusFilter = 'published';
                              });
                              _loadAnswers();
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip(
                          label: '임시저장',
                          value: 'draft',
                          selected: _statusFilter == 'draft',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _statusFilter = 'draft';
                              });
                              _loadAnswers();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    // 날짜 필터
                    Text(
                      '날짜',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _buildFilterChip(
                          label: '전체',
                          value: 'all',
                          selected: _dateFilter == 'all',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _dateFilter = 'all';
                              });
                              _loadAnswers();
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip(
                          label: '오늘',
                          value: 'today',
                          selected: _dateFilter == 'today',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _dateFilter = 'today';
                              });
                              _loadAnswers();
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip(
                          label: '이번 주',
                          value: 'week',
                          selected: _dateFilter == 'week',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _dateFilter = 'week';
                              });
                              _loadAnswers();
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip(
                          label: '이번 달',
                          value: 'month',
                          selected: _dateFilter == 'month',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _dateFilter = 'month';
                              });
                              _loadAnswers();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    
                    // 정렬 옵션
                    Text(
                      '정렬',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _buildFilterChip(
                          label: '최신순',
                          value: 'newest',
                          selected: _sortBy == 'newest',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _sortBy = 'newest';
                              });
                              _loadAnswers();
                            }
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip(
                          label: '오래된순',
                          value: 'oldest',
                          selected: _sortBy == 'oldest',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _sortBy = 'oldest';
                              });
                              _loadAnswers();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 에러 메시지
            if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
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
                ),
              ),

            // 답변 목록
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_answers.isEmpty)
              SliverFillRemaining(
                child: Center(
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
                        '작성한 답변이 없습니다.',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final answerWithQuestion = _answers[index];
                    return _AnswerCard(
                      answer: answerWithQuestion.answer,
                      question: answerWithQuestion.question,
                      onTap: () {
                        context.push(
                          '/celebrity/answers/${answerWithQuestion.answer.id}',
                        );
                      },
                      onEdit: () {
                        context.push(
                          '/celebrity/questions/${answerWithQuestion.answer.questionId}/answer',
                        );
                      },
                      onDelete: () {
                        _handleDeleteAnswer(answerWithQuestion.answer);
                      },
                    );
                  },
                  childCount: _answers.length,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CelebrityBottomNavigation(),
    );
  }

  /// 필터 칩 위젯
  Widget _buildFilterChip({
    required String label,
    required String value,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: AppTypography.body2.copyWith(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

/// 답변과 질문을 함께 저장하는 모델
class _AnswerWithQuestion {
  final AnswerModel answer;
  final QuestionModel? question;

  _AnswerWithQuestion({
    required this.answer,
    this.question,
  });
}

/// 답변 카드 위젯
class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.answer,
    this.question,
    this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final AnswerModel answer;
  final QuestionModel? question;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더: 상태 배지 및 시간
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 상태 배지
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: answer.isDraft
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Text(
                    answer.isDraft ? '임시저장' : '게시됨',
                    style: AppTypography.caption.copyWith(
                      color: answer.isDraft ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // 작성 시간
                Text(
                  _formatTime(answer.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 질문 내용
            if (question != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.question_answer,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      question!.content,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // 답변 내용 미리보기
            Text(
              answer.content,
              style: AppTypography.body1.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),

            // 액션 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('수정'),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('삭제'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
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

