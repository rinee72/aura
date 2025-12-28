import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/permission_error_handler.dart';
import '../../auth/providers/auth_provider.dart';
import '../../fan/models/question_model.dart';
import '../../auth/models/user_model.dart';
import '../services/question_monitoring_service.dart';
import '../services/question_management_service.dart';
import '../widgets/manager_question_card.dart';
import '../widgets/hide_question_dialog.dart';

/// 질문 모니터링 화면
/// 
/// WP-4.1: 매니저 대시보드 및 질문 모니터링
/// 
/// 매니저가 모든 질문을 모니터링할 수 있는 화면입니다.
/// 필터링, 정렬, 검색 기능을 제공합니다.
class QuestionMonitoringScreen extends StatefulWidget {
  const QuestionMonitoringScreen({super.key});

  @override
  State<QuestionMonitoringScreen> createState() => _QuestionMonitoringScreenState();
}

class _QuestionMonitoringScreenState extends State<QuestionMonitoringScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 필터 상태
  String _statusFilter = 'all'; // 'all', 'pending', 'answered', 'hidden'
  String _dateFilter = 'all'; // 'all', 'today', 'week', 'month'
  String _sortBy = 'created_at'; // 'created_at', 'like_count', 'user_id'
  String _orderBy = 'desc'; // 'asc', 'desc'
  String? _searchQuery;

  // 검색 컨트롤러
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 질문 목록 로드
  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 권한 검증
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } on PermissionException catch (e) {
        if (mounted) {
          PermissionErrorHandler.handleError(context, e);
          setState(() {
            _errorMessage = '질문 모니터링은 매니저만 사용할 수 있습니다.';
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

      // 질문 목록 조회
      final questions = await QuestionMonitoringService.getAllQuestions(
        limit: 100, // 매니저는 더 많은 질문을 조회
        statusFilter: _statusFilter,
        dateFilter: _dateFilter,
        sortBy: _sortBy,
        orderBy: _orderBy,
        searchQuery: _searchQuery,
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
          _errorMessage = '질문을 불러오는 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 검색 실행
  void _handleSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
    });
    _loadQuestions();
  }

  /// 질문 숨기기 처리
  Future<void> _handleHideQuestion(QuestionModel question) async {
    final reason = await HideQuestionDialog.show(context);

    if (reason == null) {
      return; // 취소
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await QuestionManagementService.hideQuestion(
        questionId: question.id,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('질문이 숨김 처리되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // 목록 새로고침
        _loadQuestions();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('질문 숨기기 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 질문 복구 처리
  Future<void> _handleUnhideQuestion(QuestionModel question) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('질문 복구'),
        content: const Text('이 질문을 복구하시겠습니까? 복구된 질문은 셀럽 화면에 다시 표시됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('복구'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await QuestionManagementService.unhideQuestion(question.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('질문이 복구되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // 목록 새로고침
        _loadQuestions();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('질문 복구 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 숨김 사유 수정 처리
  Future<void> _handleUpdateHiddenReason(QuestionModel question) async {
    final newReason = await HideQuestionDialog.show(
      context,
      initialReason: question.hiddenReason,
    );

    if (newReason == null || newReason == question.hiddenReason) {
      return; // 취소 또는 변경 없음
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await QuestionManagementService.updateHiddenReason(
        questionId: question.id,
        reason: newReason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('숨김 사유가 수정되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // 목록 새로고침
        _loadQuestions();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('숨김 사유 수정 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '질문 모니터링',
        role: 'manager',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadQuestions,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 및 검색 영역
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surface,
            child: Column(
              children: [
                // 검색 바
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '질문 내용, 작성자 이름 또는 이메일로 검색',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                    _handleSearch();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radius),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _handleSearch(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _handleSearch,
                      child: const Text('검색'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // 필터 및 정렬
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 상태 필터
                      _buildFilterChip(
                        label: '전체',
                        isSelected: _statusFilter == 'all',
                        onTap: () {
                          setState(() => _statusFilter = 'all');
                          _loadQuestions();
                        },
                      ),
                      _buildFilterChip(
                        label: '미답변',
                        isSelected: _statusFilter == 'pending',
                        onTap: () {
                          setState(() => _statusFilter = 'pending');
                          _loadQuestions();
                        },
                      ),
                      _buildFilterChip(
                        label: '답변완료',
                        isSelected: _statusFilter == 'answered',
                        onTap: () {
                          setState(() => _statusFilter = 'answered');
                          _loadQuestions();
                        },
                      ),
                      _buildFilterChip(
                        label: '숨김',
                        isSelected: _statusFilter == 'hidden',
                        onTap: () {
                          setState(() => _statusFilter = 'hidden');
                          _loadQuestions();
                        },
                        color: Colors.red,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      
                      // 날짜 필터
                      _buildFilterChip(
                        label: '오늘',
                        isSelected: _dateFilter == 'today',
                        onTap: () {
                          setState(() => _dateFilter = 'today');
                          _loadQuestions();
                        },
                      ),
                      _buildFilterChip(
                        label: '이번 주',
                        isSelected: _dateFilter == 'week',
                        onTap: () {
                          setState(() => _dateFilter = 'week');
                          _loadQuestions();
                        },
                      ),
                      _buildFilterChip(
                        label: '이번 달',
                        isSelected: _dateFilter == 'month',
                        onTap: () {
                          setState(() => _dateFilter = 'month');
                          _loadQuestions();
                        },
                      ),
                      _buildFilterChip(
                        label: '전체',
                        isSelected: _dateFilter == 'all',
                        onTap: () {
                          setState(() => _dateFilter = 'all');
                          _loadQuestions();
                        },
                      ),
                      const SizedBox(width: AppSpacing.md),
                      
                      // 정렬 옵션
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.sort),
                        tooltip: '정렬',
                        onSelected: (value) {
                          final parts = value.split('_');
                          setState(() {
                            _sortBy = parts[0];
                            _orderBy = parts[1];
                          });
                          _loadQuestions();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'created_at_desc',
                            child: Text('최신순'),
                          ),
                          const PopupMenuItem(
                            value: 'created_at_asc',
                            child: Text('오래된순'),
                          ),
                          const PopupMenuItem(
                            value: 'like_count_desc',
                            child: Text('좋아요 많은순'),
                          ),
                          const PopupMenuItem(
                            value: 'like_count_asc',
                            child: Text('좋아요 적은순'),
                          ),
                          const PopupMenuItem(
                            value: 'user_id_asc',
                            child: Text('작성자순'),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      
                      // 새로고침 버튼
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: '새로고침',
                        onPressed: _isLoading ? null : _loadQuestions,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 질문 목록
          Expanded(
            child: _isLoading && _questions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _questions.isEmpty
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
                                onPressed: _loadQuestions,
                                child: const Text('다시 시도'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _questions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  '질문이 없습니다.',
                                  style: AppTypography.body1.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadQuestions,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: _questions.length,
                              itemBuilder: (context, index) {
                                final item = _questions[index];
                                final question = item['question'] as QuestionModel;
                                final author = item['author'] as UserModel?;
                                
                                final hiddenBy = item['hiddenBy'] as UserModel?;
                                final riskLevel = item['riskLevel'] as String?; // WP-4.3: 위험도 정보
                                
                                return ManagerQuestionCard(
                                  question: question,
                                  author: author,
                                  hiddenBy: hiddenBy,
                                  riskLevel: riskLevel, // WP-4.3: 위험도 전달
                                  onTap: () {
                                    // 질문 상세 화면으로 이동 (향후 구현)
                                  },
                                  onHide: question.isHidden ? null : () => _handleHideQuestion(question),
                                  onUnhide: question.isHidden ? () => _handleUnhideQuestion(question) : null,
                                  onUpdateReason: question.isHidden ? () => _handleUpdateHiddenReason(question) : null,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  /// 필터 칩 위젯
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: color ?? AppColors.primary.withOpacity(0.2),
        checkmarkColor: color ?? AppColors.primary,
        labelStyle: AppTypography.caption.copyWith(
          color: isSelected
              ? (color ?? AppColors.primary)
              : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}


