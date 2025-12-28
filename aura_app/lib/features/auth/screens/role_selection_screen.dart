import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';

/// 역할 선택 화면
/// 
/// WP-1.3: 사용자 프로필 및 역할 관리 시스템
/// 
/// 회원가입 후 사용자가 자신의 역할(fan/celebrity/manager)을 선택하는 화면입니다.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;
  String? _errorMessage;

  /// 역할 선택
  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
      _errorMessage = null;
    });
  }

  /// 역할 저장 및 완료
  Future<void> _saveRole() async {
    if (_selectedRole == null) {
      setState(() {
        _errorMessage = '역할을 선택해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.supabaseUser;

      if (currentUser == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // pendingDisplayName 사용 (회원가입 시 입력한 이름)
      final displayName = authProvider.pendingDisplayName;
      if (displayName == null || displayName.trim().isEmpty) {
        throw Exception('이름이 없습니다. 회원가입을 다시 시도해주세요.');
      }

      // 프로필 생성 또는 업데이트 (upsert 사용)
      // createUserProfile이 upsert를 사용하므로 프로필이 있으면 업데이트, 없으면 생성됩니다
      await UserService.createUserProfile(
        userId: currentUser.id,
        email: currentUser.email ?? '',
        role: _selectedRole!,
        displayName: displayName.trim(),
      );

      // pendingDisplayName 초기화
      authProvider.clearPendingDisplayName();

      // AuthProvider에서 프로필 다시 로드
      await authProvider.refreshUserProfile();

      // 프로필이 제대로 로드되었는지 확인
      if (authProvider.currentUser?.role != _selectedRole) {
        throw Exception('역할이 제대로 저장되지 않았습니다.');
      }

      // 성공 시 홈 화면으로 이동
      // WP-1.4: Go Router의 redirect가 역할에 따라 자동으로 적절한 화면으로 리다이렉트함
      if (mounted) {
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getRoleDisplayName(_selectedRole!)} 역할로 설정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = '역할 저장 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 역할 표시 이름 반환
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'fan':
        return '팬';
      case 'celebrity':
        return '셀럽';
      case 'manager':
        return '매니저';
      default:
        return role;
    }
  }

  /// 역할 설명 반환
  String _getRoleDescription(String role) {
    switch (role) {
      case 'fan':
        return '질문을 작성하고 셀럽과 소통할 수 있습니다.';
      case 'celebrity':
        return '팬들의 질문에 답변하고 콘텐츠를 작성할 수 있습니다.';
      case 'manager':
        return '셀럽 콘텐츠를 관리하고 질문을 모니터링할 수 있습니다.';
      default:
        return '';
    }
  }

  /// 역할 아이콘 반환
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'fan':
        return Icons.favorite;
      case 'celebrity':
        return Icons.star;
      case 'manager':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  /// 역할 색상 반환
  Color _getRoleColor(String role) {
    switch (role) {
      case 'fan':
        return Colors.pink;
      case 'celebrity':
        return Colors.amber;
      case 'manager':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('역할 선택'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목
              Text(
                'AURA에서 어떤 역할로 활동하시나요?',
                style: AppTypography.h2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '역할에 따라 사용할 수 있는 기능이 달라집니다.',
                style: AppTypography.body1.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // 역할 선택 카드들
              _buildRoleCard('fan', '팬', _getRoleDescription('fan'), _getRoleIcon('fan'), _getRoleColor('fan')),
              const SizedBox(height: AppSpacing.md),
              _buildRoleCard('celebrity', '셀럽', _getRoleDescription('celebrity'), _getRoleIcon('celebrity'), _getRoleColor('celebrity')),
              const SizedBox(height: AppSpacing.md),
              _buildRoleCard('manager', '매니저', _getRoleDescription('manager'), _getRoleIcon('manager'), _getRoleColor('manager')),
              const SizedBox(height: AppSpacing.xl),

              // 에러 메시지
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.body2.copyWith(
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 완료 버튼
              CustomButton(
                label: '완료',
                onPressed: _isLoading ? null : _saveRole,
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    String role,
    String displayName,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => _selectRole(role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTypography.body2.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // 선택 표시
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
