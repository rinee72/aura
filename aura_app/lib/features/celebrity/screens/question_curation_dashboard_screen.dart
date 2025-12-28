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
import '../models/curated_question_model.dart';
import '../services/question_curation_service.dart';
import '../widgets/curated_question_card.dart';

/// 질문 큐레이션 대시보드 화면
/// 
/// WP-3.1: 질문 큐레이션 대시보드
/// 
/// 셀럽이 좋아요 기반으로 정제된 Top 질문을 확인할 수 있는 대시보드입니다.
class QuestionCurationDashboardScreen extends StatefulWidget {
  const QuestionCurationDashboardScreen({super.key});

  @override
  State<QuestionCurationDashboardScreen> createState() => _QuestionCurationDashboardScreenState();
}

class _QuestionCurationDashboardScreenState extends State<QuestionCurationDashboardScreen> {
  List<CuratedQuestionModel> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 필터 상태
  String _dateFilter = 'all'; // 'today', 'week', 'month', 'all'
  String _statusFilter = 'all'; // 'all', 'pending', 'answered'
  int _limit = 10; // 기본 Top 10

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  /// 질문 목록 로드
  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 권한 검증 (클라이언트 사이드)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleCelebrity);
      } on PermissionException catch (e) {
        if (mounted) {
          PermissionErrorHandler.handleError(context, e);
          setState(() {
            _errorMessage = '질문 큐레이션은 셀럽만 사용할 수 있습니다.';
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

      final questions = await QuestionCurationService.getTopQuestions(
        limit: _limit,
        dateFilter: _dateFilter,
        statusFilter: _statusFilter,
      );

      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorString = e.toString();
          if (errorString.contains('permission') || errorString.contains('권한')) {
            _errorMessage = '질문 큐레이션은 셀럽만 사용할 수 있습니다.';
          } else if (errorString.contains('network') || errorString.contains('연결')) {
            _errorMessage = '네트워크 연결을 확인해주세요.';
          } else {
            _errorMessage = '질문을 불러오는 중 오류가 발생했습니다: $e';
          }
          _isLoading = false;
        });
      }
    }
  }

  /// 새로고침 처리
  Future<void> _handleRefresh() async {
    await _loadQuestions();
  }

  /// 날짜 필터 변경
  void _onDateFilterChanged(String filter) {
    setState(() {
      _dateFilter = filter;
    });
    _loadQuestions();
  }

  /// 상태 필터 변경
  void _onStatusFilterChanged(String filter) {
    setState(() {
      _statusFilter = filter;
    });
    _loadQuestions();
  }

  /// 질문 선택 처리 (답변 작성 화면으로 이동)
  void _onQuestionTap(CuratedQuestionModel curatedQuestion) {
    // WP-3.2에서 구현될 답변 작성 화면으로 이동
    context.push('/celebrity/questions/${curatedQuestion.id}/answer');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '질문 큐레이션',
        role: 'celebrity',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
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
                    // 날짜 필터 탭
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
                            if (selected) _onDateFilterChanged('all');
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip(
                          label: '오늘',
                          value: 'today',
                          selected: _dateFilter == 'today',
                          onSelected: (selected) {
                            if (selected) _onDateFilterChanged('today');
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip(
                          label: '이번 주',
                          value: 'week',
                          selected: _dateFilter == 'week',
                          onSelected: (selected) {
                            if (selected) _onDateFilterChanged('week');
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip(
                          label: '이번 달',
                          value: 'month',
                          selected: _dateFilter == 'month',
                          onSelected: (selected) {
                            if (selected) _onDateFilterChanged('month');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 상태 필터 탭
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
                            if (selected) _onStatusFilterChanged('all');
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip(
                          label: '답변대기',
                          value: 'pending',
                          selected: _statusFilter == 'pending',
                          onSelected: (selected) {
                            if (selected) _onStatusFilterChanged('pending');
                          },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _buildFilterChip(
                          label: '답변완료',
                          value: 'answered',
                          selected: _statusFilter == 'answered',
                          onSelected: (selected) {
                            if (selected) _onStatusFilterChanged('answered');
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

            // 질문 목록
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_questions.isEmpty)
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
                        '조건에 맞는 질문이 없습니다',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '필터를 변경하거나 나중에 다시 확인해주세요.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final curatedQuestion = _questions[index];
                    return CuratedQuestionCard(
                      curatedQuestion: curatedQuestion,
                      onTap: () => _onQuestionTap(curatedQuestion),
                    );
                  },
                  childCount: _questions.length,
                ),
              ),
          ],
        ),
      ),
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

