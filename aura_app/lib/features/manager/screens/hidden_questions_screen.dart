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
import '../services/question_management_service.dart';
import '../widgets/manager_question_card.dart';
import '../widgets/hide_question_dialog.dart';

/// 숨긴 질문 목록 화면
/// 
/// WP-4.2: 질문 관리 기능 (숨기기/복구)
/// 
/// 매니저가 숨김 처리된 질문 목록을 확인하고 복구할 수 있는 화면입니다.
class HiddenQuestionsScreen extends StatefulWidget {
  const HiddenQuestionsScreen({super.key});

  @override
  State<HiddenQuestionsScreen> createState() => _HiddenQuestionsScreenState();
}

class _HiddenQuestionsScreenState extends State<HiddenQuestionsScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 검색 컨트롤러
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

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
            _errorMessage = '숨긴 질문 조회는 매니저만 사용할 수 있습니다.';
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

      // 숨김 처리된 질문 목록 조회
      final questions = await QuestionManagementService.getHiddenQuestions(
        limit: 100,
      );

      // 검색 필터링 (클라이언트 사이드)
      List<Map<String, dynamic>> filteredQuestions = questions;
      if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
        final queryLower = _searchQuery!.toLowerCase().trim();
        filteredQuestions = questions.where((item) {
          final question = item['question'] as QuestionModel;
          final author = item['author'] as UserModel?;
          
          final content = question.content.toLowerCase();
          final authorName = (author?.displayName ?? '').toLowerCase();
          final authorEmail = (author?.email ?? '').toLowerCase();
          final hiddenReason = (question.hiddenReason ?? '').toLowerCase();
          
          return content.contains(queryLower) || 
              authorName.contains(queryLower) || 
              authorEmail.contains(queryLower) ||
              hiddenReason.contains(queryLower);
        }).toList();
      }

      if (mounted) {
        setState(() {
          _questions = filteredQuestions;
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
        title: '숨긴 질문',
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
          // 검색 영역
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '질문 내용, 작성자, 숨김 사유로 검색',
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
                                  Icons.visibility_off,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  '숨김 처리된 질문이 없습니다.',
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
                                    // 숨김 사유 수정 다이얼로그 표시
                                    _handleUpdateHiddenReason(question);
                                  },
                                  onUnhide: () => _handleUnhideQuestion(question),
                                  onUpdateReason: () => _handleUpdateHiddenReason(question),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

