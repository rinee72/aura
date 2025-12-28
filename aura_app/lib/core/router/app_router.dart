import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/environment.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/fan/screens/fan_home_screen.dart';
import '../../features/fan/screens/questions_list_screen.dart';
import '../../features/fan/screens/create_question_screen.dart';
import '../../features/fan/screens/question_detail_screen.dart';
import '../../features/fan/screens/celebrities_list_screen.dart';
import '../../features/fan/screens/celebrity_profile_screen.dart';
import '../../features/fan/screens/my_subscriptions_screen.dart';
import '../../features/fan/screens/answers_feed_screen.dart';
import '../../features/fan/screens/community_list_screen.dart';
import '../../features/fan/screens/create_community_post_screen.dart';
import '../../features/fan/screens/community_post_detail_screen.dart';
import '../../features/fan/screens/fan_profile_screen.dart';
import '../../features/celebrity/screens/celebrity_dashboard_screen.dart';
import '../../features/celebrity/screens/question_curation_dashboard_screen.dart';
import '../../features/celebrity/screens/create_answer_screen.dart';
import '../../features/celebrity/screens/my_answers_screen.dart';
import '../../features/celebrity/screens/answer_detail_screen.dart';
import '../../features/celebrity/screens/profile_management_screen.dart';
import '../../features/celebrity/screens/create_feed_screen.dart';
import '../../features/celebrity/screens/my_feeds_screen.dart';
import '../../features/manager/screens/manager_dashboard_screen.dart';
import '../../features/manager/screens/question_monitoring_screen.dart';
import '../../features/manager/screens/hidden_questions_screen.dart';
import '../../features/manager/screens/assigned_celebrities_screen.dart';
import '../../features/manager/screens/assign_celebrity_screen.dart';
import '../../features/manager/screens/assignment_management_screen.dart';
import '../../features/manager/screens/celebrities_list_screen.dart' as manager;
import '../../features/manager/screens/celebrity_profile_management_screen.dart';
import '../../features/manager/screens/reports_screen.dart';
import '../../dev/component_showcase.dart';
import '../../dev/progress_overview.dart';
import '../../dev/wp_1_1_status.dart';
import '../../dev/wp_1_2_status.dart';
import '../../dev/wp_1_3_status.dart';

/// WP-1.4: 역할 기반 라우팅 및 Navigation 구현
/// 
/// Go Router를 사용하여 역할별로 다른 화면으로 라우팅하고,
/// 인증 가드를 구현하여 권한 없는 접근을 차단합니다.
class AppRouter {
  AppRouter._(); // 인스턴스 생성 방지

  /// Go Router 인스턴스 생성
  /// 
  /// AuthProvider를 refreshListenable로 등록하여 인증 상태 변화를 감지합니다.
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: authProvider,
      redirect: (BuildContext context, GoRouterState state) {
        return _handleRedirect(context, state);
      },
      routes: [
        // 로딩 화면 (로딩 중일 때 표시)
        GoRoute(
          path: '/loading',
          name: 'loading',
          builder: (context, state) => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),

        // 인증 라우트 (미인증 사용자 접근 가능)
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/role-selection',
          name: 'role-selection',
          builder: (context, state) => const RoleSelectionScreen(),
        ),

        // 팬 라우트
        GoRoute(
          path: '/fan/home',
          name: 'fan-home',
          builder: (context, state) => const FanHomeScreen(),
        ),
        GoRoute(
          path: '/fan/questions',
          name: 'fan-questions',
          builder: (context, state) => const QuestionsListScreen(),
        ),
        GoRoute(
          path: '/fan/questions/create',
          name: 'fan-questions-create',
          builder: (context, state) => const CreateQuestionScreen(),
        ),
        GoRoute(
          path: '/fan/questions/:questionId',
          name: 'fan-question-detail',
          builder: (context, state) {
            final questionId = state.pathParameters['questionId']!;
            return QuestionDetailScreen(questionId: questionId);
          },
        ),
        GoRoute(
          path: '/fan/community',
          name: 'fan-community',
          builder: (context, state) => const CommunityListScreen(),
        ),
        GoRoute(
          path: '/fan/community/create',
          name: 'fan-community-create',
          builder: (context, state) => const CreateCommunityPostScreen(),
        ),
        GoRoute(
          path: '/fan/community/:postId',
          name: 'fan-community-detail',
          builder: (context, state) {
            final postId = state.pathParameters['postId']!;
            return CommunityPostDetailScreen(postId: postId);
          },
        ),
        GoRoute(
          path: '/fan/community/:postId/edit',
          name: 'fan-community-edit',
          builder: (context, state) {
            final postId = state.pathParameters['postId']!;
            return CreateCommunityPostScreen(postId: postId);
          },
        ),
        GoRoute(
          path: '/fan/celebrities',
          name: 'fan-celebrities',
          builder: (context, state) => const CelebritiesListScreen(),
        ),
        GoRoute(
          path: '/fan/celebrities/:celebrityId',
          name: 'fan-celebrity-profile',
          builder: (context, state) {
            final celebrityId = state.pathParameters['celebrityId']!;
            return CelebrityProfileScreen(celebrityId: celebrityId);
          },
        ),
        GoRoute(
          path: '/fan/my-subscriptions',
          name: 'fan-my-subscriptions',
          builder: (context, state) => const MySubscriptionsScreen(),
        ),
        GoRoute(
          path: '/fan/answers',
          name: 'fan-answers',
          builder: (context, state) => const AnswersFeedScreen(),
        ),
        GoRoute(
          path: '/fan/profile',
          name: 'fan-profile',
          builder: (context, state) => const FanProfileScreen(),
        ),

        // 셀럽 라우트
        GoRoute(
          path: '/celebrity/dashboard',
          name: 'celebrity-dashboard',
          builder: (context, state) => const CelebrityDashboardScreen(),
        ),
        GoRoute(
          path: '/celebrity/questions/curation',
          name: 'celebrity-questions-curation',
          builder: (context, state) => const QuestionCurationDashboardScreen(),
        ),
        GoRoute(
          path: '/celebrity/questions/:questionId/answer',
          name: 'celebrity-question-answer',
          builder: (context, state) {
            final questionId = state.pathParameters['questionId']!;
            return CreateAnswerScreen(questionId: questionId);
          },
        ),
        GoRoute(
          path: '/celebrity/answers',
          name: 'celebrity-answers',
          builder: (context, state) => const MyAnswersScreen(),
        ),
        GoRoute(
          path: '/celebrity/answers/:answerId',
          name: 'celebrity-answer-detail',
          builder: (context, state) {
            final answerId = state.pathParameters['answerId']!;
            return AnswerDetailScreen(answerId: answerId);
          },
        ),
        GoRoute(
          path: '/celebrity/profile',
          name: 'celebrity-profile',
          builder: (context, state) => const ProfileManagementScreen(),
        ),
        GoRoute(
          path: '/celebrity/feeds',
          name: 'celebrity-feeds',
          builder: (context, state) => const MyFeedsScreen(),
        ),
        GoRoute(
          path: '/celebrity/feeds/create',
          name: 'celebrity-feeds-create',
          builder: (context, state) => const CreateFeedScreen(),
        ),
        GoRoute(
          path: '/celebrity/feeds/:feedId/edit',
          name: 'celebrity-feeds-edit',
          builder: (context, state) {
            final feedId = state.pathParameters['feedId']!;
            return CreateFeedScreen(feedId: feedId);
          },
        ),

        // 매니저 라우트
        GoRoute(
          path: '/manager/dashboard',
          name: 'manager-dashboard',
          builder: (context, state) => const ManagerDashboardScreen(),
        ),
        GoRoute(
          path: '/manager/monitoring',
          name: 'manager-monitoring',
          builder: (context, state) => const QuestionMonitoringScreen(),
        ),
        GoRoute(
          path: '/manager/questions/hidden',
          name: 'manager-hidden-questions',
          builder: (context, state) => const HiddenQuestionsScreen(),
        ),
        GoRoute(
          path: '/manager/celebrities/assigned',
          name: 'manager-assigned-celebrities',
          builder: (context, state) => const AssignedCelebritiesScreen(),
        ),
        GoRoute(
          path: '/manager/assign',
          name: 'manager-assign-celebrity',
          builder: (context, state) => const AssignCelebrityScreen(),
        ),
        GoRoute(
          path: '/manager/assignments',
          name: 'manager-assignment-management',
          builder: (context, state) => const AssignmentManagementScreen(),
        ),
        GoRoute(
          path: '/manager/celebrities',
          name: 'manager-celebrities-list',
          builder: (context, state) => const manager.CelebritiesListScreen(),
        ),
        GoRoute(
          path: '/manager/celebrities/:celebrityId',
          name: 'manager-celebrity-profile',
          builder: (context, state) {
            final celebrityId = state.pathParameters['celebrityId']!;
            return CelebrityProfileManagementScreen(celebrityId: celebrityId);
          },
        ),
        GoRoute(
          path: '/manager/reports',
          name: 'manager-reports',
          builder: (context, state) => const ReportsScreen(),
        ),

        // 루트 경로 (역할에 따라 리다이렉트)
        GoRoute(
          path: '/',
          name: 'root',
          redirect: (context, state) => _getRootRedirect(context),
        ),

        // 개발 환경 전용 라우트
        if (AppEnvironment.current == Environment.development) ...[
          GoRoute(
            path: '/showcase',
            name: 'showcase',
            builder: (context, state) => const ComponentShowcase(),
          ),
          GoRoute(
            path: '/progress',
            name: 'progress',
            builder: (context, state) => const ProgressOverviewPage(),
          ),
          GoRoute(
            path: '/wp11-status',
            name: 'wp11-status',
            builder: (context, state) => const WP11StatusPage(),
          ),
          GoRoute(
            path: '/wp12-status',
            name: 'wp12-status',
            builder: (context, state) => const WP12StatusPage(),
          ),
          GoRoute(
            path: '/wp13-status',
            name: 'wp13-status',
            builder: (context, state) => const WP13StatusPage(),
          ),
        ],
      ],
    );
  }

  /// 리다이렉트 처리
  /// 
  /// 인증 상태와 역할에 따라 적절한 화면으로 리다이렉트합니다.
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    // AuthProvider 접근
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentPath = state.uri.path;

    // 로딩 중이고 초기 로딩인 경우 로딩 화면으로 리다이렉트
    // (단, 인증 라우트에서는 로딩 화면으로 리다이렉트하지 않음)
    if (authProvider.isLoading && !_isAuthRoute(currentPath)) {
      // 초기 로딩 중이고 사용자 정보가 없으면 로딩 화면 표시
      if (authProvider.currentUser == null && authProvider.supabaseUser == null) {
        return '/loading';
      }
      // 로딩 중이지만 이미 화면에 있으면 그대로 유지
      return null;
    }

    final isAuthenticated = authProvider.isAuthenticated;
    final role = authProvider.currentUser?.role;

    // 인증 라우트 (/login, /signup, /role-selection)
    if (_isAuthRoute(currentPath)) {
      // 이미 인증되어 있고 역할이 있으면 역할별 홈으로 리다이렉트
      if (isAuthenticated && role != null && role.isNotEmpty) {
        return _getRoleHomeRoute(role);
      }
      // 인증되지 않았으면 인증 라우트 접근 허용
      return null;
    }

    // 인증되지 않은 사용자는 로그인 화면으로 리다이렉트
    if (!isAuthenticated) {
      return '/login';
    }

    // 역할이 설정되지 않은 경우 역할 선택 화면으로 리다이렉트
    if (role == null || role.isEmpty) {
      // 이미 역할 선택 화면에 있으면 그대로 둠
      if (currentPath == '/role-selection') {
        return null;
      }
      return '/role-selection';
    }

    // 역할별 라우트 접근 권한 체크
    if (_isRoleRoute(currentPath, role)) {
      return null; // 권한 있음
    }

    // 권한이 없는 라우트 접근 시 역할별 홈으로 리다이렉트
    return _getRoleHomeRoute(role);
  }

  /// 루트 경로 리다이렉트
  static String _getRootRedirect(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    
    if (!authProvider.isAuthenticated) {
      return '/login';
    }

    final role = authProvider.currentUser?.role;
    if (role == null || role.isEmpty) {
      return '/role-selection';
    }

    return _getRoleHomeRoute(role);
  }

  /// 역할에 따른 홈 라우트 반환
  static String _getRoleHomeRoute(String role) {
    switch (role) {
      case 'fan':
        return '/fan/home';
      case 'celebrity':
        return '/celebrity/dashboard';
      case 'manager':
        return '/manager/dashboard';
      default:
        return '/login';
    }
  }

  /// 인증 라우트 여부 확인
  static bool _isAuthRoute(String path) {
    return path == '/login' || path == '/signup' || path == '/role-selection';
  }

  /// 역할별 라우트 접근 권한 체크
  static bool _isRoleRoute(String path, String role) {
    if (path.startsWith('/fan/')) {
      return role == 'fan';
    }
    if (path.startsWith('/celebrity/')) {
      return role == 'celebrity';
    }
    if (path.startsWith('/manager/')) {
      return role == 'manager';
    }
    // 기타 라우트는 모두 허용 (인증만 확인)
    return true;
  }
}

