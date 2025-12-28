import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/manager_assignment_service.dart';

/// 셀럽 할당 화면
/// 
/// WP-4.2 확장: 매니저-셀럽 관계 명시적 관리
/// 
/// 매니저에게 셀럽을 할당하는 화면입니다.
class AssignCelebrityScreen extends StatefulWidget {
  const AssignCelebrityScreen({super.key});

  @override
  State<AssignCelebrityScreen> createState() => _AssignCelebrityScreenState();
}

class _AssignCelebrityScreenState extends State<AssignCelebrityScreen> {
  List<UserModel> _managers = [];
  List<UserModel> _celebrities = [];
  UserModel? _selectedManager;
  UserModel? _selectedCelebrity;
  bool _isLoadingManagers = false;
  bool _isLoadingCelebrities = false;
  bool _isAssigning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadManagers();
    _loadCelebrities();
    _setCurrentManagerAsDefault();
  }

  /// 기본적으로 현재 로그인한 매니저를 선택
  void _setCurrentManagerAsDefault() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser != null && 
        currentUser.role == 'manager' && 
        _managers.isNotEmpty &&
        _selectedManager == null) {
      final currentManager = _managers.firstWhere(
        (manager) => manager.id == currentUser.id,
        orElse: () => _managers.first,
      );
      setState(() {
        _selectedManager = currentManager;
      });
    }
  }

  /// 매니저 목록 로드
  Future<void> _loadManagers() async {
    setState(() {
      _isLoadingManagers = true;
    });

    try {
      final managers = await ManagerAssignmentService.getAllManagers();
      setState(() {
        _managers = managers;
        _isLoadingManagers = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '매니저 목록을 불러오는 중 오류가 발생했습니다: $e';
        _isLoadingManagers = false;
      });
    }
  }

  /// 셀럽 목록 로드
  Future<void> _loadCelebrities() async {
    setState(() {
      _isLoadingCelebrities = true;
    });

    try {
      final celebrities = await ManagerAssignmentService.getAllCelebrities();
      setState(() {
        _celebrities = celebrities;
        _isLoadingCelebrities = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '셀럽 목록을 불러오는 중 오류가 발생했습니다: $e';
        _isLoadingCelebrities = false;
      });
    }
  }

  /// 셀럽 할당 처리
  Future<void> _handleAssign() async {
    if (_selectedManager == null || _selectedCelebrity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매니저와 셀럽을 모두 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('셀럽 할당'),
        content: Text(
          '${_selectedManager!.displayName ?? _selectedManager!.email} 매니저에게\n'
          '${_selectedCelebrity!.displayName ?? _selectedCelebrity!.email} 셀럽을 할당하시겠습니까?',
        ),
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
            child: const Text('할당'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isAssigning = true;
      _errorMessage = null;
    });

    try {
      await ManagerAssignmentService.assignCelebrity(
        managerId: _selectedManager!.id,
        celebrityId: _selectedCelebrity!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedCelebrity!.displayName ?? _selectedCelebrity!.email} 셀럽이 '
              '${_selectedManager!.displayName ?? _selectedManager!.email} 매니저에게 할당되었습니다.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );

        // 선택 초기화
        setState(() {
          _selectedManager = null;
          _selectedCelebrity = null;
        });

        // 할당 완료 후 화면 닫기 (대시보드에서 새로고침하도록)
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('할당 실패: ${_errorMessage ?? e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '셀럽 할당',
        role: 'manager',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '매니저에게 셀럽을 할당하면 해당 매니저가 셀럽을 관리할 수 있습니다.',
                      style: AppTypography.body2.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 매니저 선택
            Text(
              '매니저 선택 *',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _isLoadingManagers
                ? const Center(child: CircularProgressIndicator())
                : _managers.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radius),
                        ),
                        child: const Text('매니저가 없습니다.'),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.textTertiary.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(AppSpacing.radius),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<UserModel>(
                            value: _selectedManager,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            hint: const Text('매니저를 선택하세요'),
                            items: _managers.map((manager) {
                              return DropdownMenuItem<UserModel>(
                                value: manager,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primary.withOpacity(0.2),
                                      backgroundImage: manager.avatarUrl != null
                                          ? NetworkImage(manager.avatarUrl!)
                                          : null,
                                      child: manager.avatarUrl == null
                                          ? Icon(
                                              Icons.person,
                                              size: 16,
                                              color: AppColors.primary,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            manager.displayName ?? manager.email,
                                            style: AppTypography.body1,
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
                              );
                            }).toList(),
                            onChanged: (manager) {
                              setState(() {
                                _selectedManager = manager;
                              });
                            },
                          ),
                        ),
                      ),
            const SizedBox(height: AppSpacing.lg),

            // 셀럽 선택
            Text(
              '셀럽 선택 *',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _isLoadingCelebrities
                ? const Center(child: CircularProgressIndicator())
                : _celebrities.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radius),
                        ),
                        child: const Text('셀럽이 없습니다.'),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.textTertiary.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(AppSpacing.radius),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<UserModel>(
                            value: _selectedCelebrity,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            hint: const Text('셀럽을 선택하세요'),
                            items: _celebrities.map((celebrity) {
                              return DropdownMenuItem<UserModel>(
                                value: celebrity,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primary.withOpacity(0.2),
                                      backgroundImage: celebrity.avatarUrl != null
                                          ? NetworkImage(celebrity.avatarUrl!)
                                          : null,
                                      child: celebrity.avatarUrl == null
                                          ? Icon(
                                              Icons.person,
                                              size: 16,
                                              color: AppColors.primary,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            celebrity.displayName ?? celebrity.email,
                                            style: AppTypography.body1,
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
                              );
                            }).toList(),
                            onChanged: (celebrity) {
                              setState(() {
                                _selectedCelebrity = celebrity;
                              });
                            },
                          ),
                        ),
                      ),
            const SizedBox(height: AppSpacing.lg),

            // 할당 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isAssigning || _selectedManager == null || _selectedCelebrity == null)
                    ? null
                    : _handleAssign,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _isAssigning
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('할당하기'),
              ),
            ),

            // 에러 메시지
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.body2.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

