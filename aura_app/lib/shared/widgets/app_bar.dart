import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/environment.dart';
import '../../features/auth/providers/auth_provider.dart';

/// 공통 AppBar 컴포넌트
/// 
/// WP-1.4: 역할 기반 라우팅 및 Navigation 구현
/// 
/// 역할별로 다른 스타일과 메뉴를 제공하는 AppBar입니다.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? role; // 'fan', 'celebrity', 'manager'
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.role,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// 역할에 따른 배경색 반환
  Color _getRoleColor(String role) {
    switch (role) {
      case 'fan':
        return Colors.pink.shade50;
      case 'celebrity':
        return Colors.amber.shade50;
      case 'manager':
        return Colors.blue.shade50;
      default:
        return Colors.transparent;
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

  /// 역할에 따른 홈 경로 반환
  String? _getHomePath(String role) {
    switch (role) {
      case 'fan':
        return '/fan/home';
      case 'celebrity':
        return '/celebrity/dashboard';
      case 'manager':
        return '/manager/dashboard';
      default:
        return null;
    }
  }

  /// 하단 네비게이션의 메인 화면 경로 목록
  List<String> _getMainScreenPaths(String role) {
    switch (role) {
      case 'fan':
        return ['/fan/home', '/fan/questions', '/fan/community'];
      case 'celebrity':
        return ['/celebrity/dashboard', '/celebrity/answers', '/celebrity/profile'];
      case 'manager':
        return ['/manager/dashboard', '/manager/monitoring'];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // WP-0.4: 환경별 배지 색상
    final badgeColor = AppEnvironment.badgeColor;
    
    // GoRouter에서 뒤로 갈 수 있는지 확인
    final canPop = context.canPop();
    
    // 현재 경로 확인
    final currentPath = GoRouterState.of(context).uri.path;
    
    // 역할에 따른 홈 경로
    final homePath = role != null ? _getHomePath(role!) : null;
    
    // 하단 네비게이션의 메인 화면인지 확인
    final isMainScreen = role != null 
        ? _getMainScreenPaths(role!).contains(currentPath)
        : false;
    
    // 뒤로 가기 버튼 로직
    Widget? leadingWidget;
    if (canPop && !isMainScreen) {
      // 네비게이션 스택이 있고 메인 화면이 아니면 뒤로 가기
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
        tooltip: '뒤로 가기',
      );
    } else if (homePath != null && isMainScreen) {
      // 메인 화면이면 홈으로 이동 (대시보드로)
      leadingWidget = IconButton(
        icon: const Icon(Icons.home),
        onPressed: () => context.go(homePath),
        tooltip: '홈으로',
      );
    } else if (homePath != null && !canPop) {
      // 네비게이션 스택이 없으면 홈으로 이동
      leadingWidget = IconButton(
        icon: const Icon(Icons.home),
        onPressed: () => context.go(homePath),
        tooltip: '홈으로',
      );
    }
    
    return AppBar(
      backgroundColor: role != null ? _getRoleColor(role!) : AppEnvironment.current.appBarColor,
      automaticallyImplyLeading: false, // 수동으로 leading 위젯 제어
      leading: leadingWidget,
      title: Row(
        children: [
          Expanded(child: Text(title)),
          if (role != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(role!).withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRoleColor(role!),
                  width: 1,
                ),
              ),
              child: Text(
                _getRoleDisplayName(role!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (badgeColor != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppEnvironment.current.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        // 로그아웃 버튼
        Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isAuthenticated) {
              return IconButton(
                icon: const Icon(Icons.logout),
                tooltip: '로그아웃',
                onPressed: () async {
                  await authProvider.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        // 추가 액션들
        if (actions != null) ...actions!,
      ],
    );
  }
}

