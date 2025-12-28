import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/permission_error_handler.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../services/manager_assignment_service.dart';
import '../models/manager_celebrity_assignment_model.dart';

/// 할당 관리 화면
/// 
/// WP-4.2 확장: 매니저-셀럽 관계 명시적 관리
/// 
/// 모든 할당 관계를 조회하고 관리하는 화면입니다.
class AssignmentManagementScreen extends StatefulWidget {
  const AssignmentManagementScreen({super.key});

  @override
  State<AssignmentManagementScreen> createState() => _AssignmentManagementScreenState();
}

class _AssignmentManagementScreenState extends State<AssignmentManagementScreen> {
  List<Map<String, dynamic>> _assignments = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  /// 할당 관계 목록 로드
  Future<void> _loadAssignments() async {
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
            _errorMessage = '할당 관리는 매니저만 사용할 수 있습니다.';
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

      final assignments = await ManagerAssignmentService.getAllAssignments();
      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '할당 관계를 불러오는 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 할당 해제 처리
  Future<void> _handleUnassign(ManagerCelebrityAssignmentModel assignment) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할당 해제'),
        content: const Text('이 할당 관계를 해제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('해제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ManagerAssignmentService.deleteAssignment(assignment.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('할당이 해제되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // 목록 새로고침
        _loadAssignments();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('할당 해제 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
        title: '할당 관리',
        role: 'manager',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAssignments,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading && _assignments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _assignments.isEmpty
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
                          onPressed: _loadAssignments,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : _assignments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '할당된 관계가 없습니다.',
                            style: AppTypography.body1.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAssignments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _assignments.length,
                        itemBuilder: (context, index) {
                          final item = _assignments[index];
                          final assignment = item['assignment'] as ManagerCelebrityAssignmentModel;
                          final manager = item['manager'] as UserModel?;
                          final celebrity = item['celebrity'] as UserModel?;

                          if (manager == null || celebrity == null) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 매니저 정보
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.primary.withOpacity(0.2),
                                        backgroundImage: manager.avatarUrl != null
                                            ? NetworkImage(manager.avatarUrl!)
                                            : null,
                                        child: manager.avatarUrl == null
                                            ? Icon(
                                                Icons.person,
                                                size: 20,
                                                color: AppColors.primary,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              manager.displayName ?? manager.email,
                                              style: AppTypography.body1.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (manager.displayName != null)
                                              Text(
                                                manager.email,
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  
                                  // 화살표 아이콘
                                  Row(
                                    children: [
                                      const SizedBox(width: 20),
                                      Icon(
                                        Icons.arrow_downward,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  
                                  // 셀럽 정보
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.purple.withOpacity(0.2),
                                        backgroundImage: celebrity.avatarUrl != null
                                            ? NetworkImage(celebrity.avatarUrl!)
                                            : null,
                                        child: celebrity.avatarUrl == null
                                            ? Icon(
                                                Icons.person,
                                                size: 20,
                                                color: Colors.purple,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              celebrity.displayName ?? celebrity.email,
                                              style: AppTypography.body1.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (celebrity.displayName != null)
                                              Text(
                                                celebrity.email,
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  
                                  // 할당 일시
                                  Text(
                                    '할당일: ${_formatTime(assignment.assignedAt)}',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  
                                  // 해제 버튼
                                  const SizedBox(height: AppSpacing.sm),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _handleUnassign(assignment),
                                      icon: const Icon(Icons.delete_outline, size: 16),
                                      label: const Text('해제'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

