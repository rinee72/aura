import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 셀럽용 Bottom Navigation
/// 
/// 셀럽의 모든 화면에서 사용하는 하단 네비게이션 바입니다.
class CelebrityBottomNavigation extends StatelessWidget {
  const CelebrityBottomNavigation({super.key});

  /// 현재 경로에 따른 인덱스 반환
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    switch (location) {
      case '/celebrity/dashboard':
        return 0;
      case '/celebrity/answers':
        return 1;
      case '/celebrity/profile':
        return 2;
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
          icon: Icon(Icons.question_answer),
          label: '답변',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '프로필',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/celebrity/dashboard');
            break;
          case 1:
            context.go('/celebrity/answers');
            break;
          case 2:
            context.go('/celebrity/profile');
            break;
        }
      },
    );
  }
}

