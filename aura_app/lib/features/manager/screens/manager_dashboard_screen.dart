import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/environment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../services/manager_assignment_service.dart';
import '../../auth/models/user_model.dart';

/// 매니저 대시보드 화면
/// 
/// WP-1.4: 역할 기반 라우팅 및 Navigation 구현
/// WP-4.1: 매니저 대시보드 및 질문 모니터링
/// WP-4.2 확장: 매니저-셀럽 관계 명시적 관리
/// 
/// 매니저 역할 사용자의 메인 대시보드 화면입니다.
class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  List<Map<String, dynamic>> _assignedCelebrities = [];
  bool _isLoadingCelebrities = false;

  @override
  void initState() {
    super.initState();
    _loadAssignedCelebrities();
  }

  /// 담당 셀럽 목록 로드
  Future<void> _loadAssignedCelebrities() async {
    setState(() {
      _isLoadingCelebrities = true;
    });

    try {
      final assignments = await ManagerAssignmentService.getMyAssignedCelebrities();
      setState(() {
        _assignedCelebrities = assignments;
        _isLoadingCelebrities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCelebrities = false;
      });
      // 에러는 조용히 무시 (담당 셀럽이 없을 수도 있음)
      print('⚠️ 담당 셀럽 조회 실패: $e');
    }
  }
  
  /// 액션 카드 위젯
  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Card(
      elevation: enabled ? 2 : 1,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.bold,
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '${AppEnvironment.appTitle} - 매니저',
        role: 'manager',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '매니저 대시보드',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // 내 담당 셀럽 섹션
            if (_assignedCelebrities.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '내 담당 셀럽',
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/manager/celebrities/assigned'),
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('전체 보기'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 120,
                child: _isLoadingCelebrities
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _assignedCelebrities.length > 5 
                            ? 5 
                            : _assignedCelebrities.length,
                        itemBuilder: (context, index) {
                          final item = _assignedCelebrities[index];
                          final celebrity = item['celebrity'] as UserModel?;
                          
                          if (celebrity == null) return const SizedBox.shrink();
                          
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            child: Card(
                              child: InkWell(
                                onTap: () {
                                  // 셀럽 상세 화면으로 이동 (향후 구현)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${celebrity.displayName ?? celebrity.email}의 프로필'),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(AppSpacing.radius),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: AppColors.primary.withOpacity(0.2),
                                        backgroundImage: celebrity.avatarUrl != null
                                            ? NetworkImage(celebrity.avatarUrl!)
                                            : null,
                                        child: celebrity.avatarUrl == null
                                            ? Icon(
                                                Icons.person,
                                                size: 30,
                                                color: AppColors.primary,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        celebrity.displayName ?? 
                                        celebrity.email.split('@').first,
                                        style: AppTypography.caption.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ] else if (!_isLoadingCelebrities) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  border: Border.all(
                    color: AppColors.textTertiary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '담당 셀럽이 없습니다. 관리자에게 할당을 요청하세요.',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            // 질문 모니터링 섹션
            _buildActionCard(
              context,
              title: '질문 모니터링',
              description: '모든 질문을 실시간으로 모니터링하고 관리합니다.',
              icon: Icons.monitor,
              onTap: () => context.push('/manager/monitoring'),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // 질문 관리 섹션
            _buildActionCard(
              context,
              title: '숨긴 질문',
              description: '숨김 처리된 질문을 확인하고 복구할 수 있습니다.',
              icon: Icons.visibility_off,
              onTap: () => context.push('/manager/questions/hidden'),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // 셀럽 할당 관리 섹션
            _buildActionCard(
              context,
              title: '셀럽 할당',
              description: '매니저에게 셀럽을 할당합니다.',
              icon: Icons.person_add,
              onTap: () async {
                await context.push('/manager/assign');
                // 할당 화면에서 돌아오면 항상 담당 셀럽 목록 새로고침
                _loadAssignedCelebrities();
              },
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            _buildActionCard(
              context,
              title: '할당 관리',
              description: '모든 할당 관계를 조회하고 관리합니다.',
              icon: Icons.assignment,
              onTap: () async {
                await context.push('/manager/assignments');
                // 할당 관리 화면에서 돌아오면 담당 셀럽 목록 새로고침
                _loadAssignedCelebrities();
              },
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            _buildActionCard(
              context,
              title: '셀럽 계정 관리',
              description: '모든 셀럽의 프로필을 관리하고 수정할 수 있습니다.',
              icon: Icons.person,
              onTap: () => context.push('/manager/celebrities'),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            _buildActionCard(
              context,
              title: '리포트 및 통계',
              description: '필터링 통계 및 트렌드 분석',
              icon: Icons.bar_chart,
              onTap: () => context.push('/manager/reports'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _ManagerBottomNavigation(),
    );
  }
}

/// 매니저용 Bottom Navigation
class _ManagerBottomNavigation extends StatelessWidget {
  const _ManagerBottomNavigation();

  /// 현재 경로에 따른 인덱스 반환
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    switch (location) {
      case '/manager/dashboard':
        return 0;
      case '/manager/monitoring':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(context),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: '대시보드',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: '모니터링',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: '설정',
        ),
      ],
      onTap: (index) {
        // WP-1.4: Go Router 사용
        switch (index) {
          case 0:
            context.go('/manager/dashboard');
            break;
          case 1:
            context.go('/manager/monitoring');
            break;
          case 2:
            // 설정 화면으로 이동 (구현 예정)
            break;
        }
      },
    );
  }
}

