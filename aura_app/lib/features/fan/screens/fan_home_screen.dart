import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/environment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/widgets/permission_wrapper.dart';
import '../../../shared/utils/permission_checker.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../services/subscription_service.dart';
import '../services/celebrity_service.dart';
import '../services/answer_service.dart';
import '../widgets/celebrity_card.dart';
import '../widgets/qa_card.dart';
import '../models/qa_model.dart';

/// 팬 홈 화면
/// 
/// WP-1.4: 역할 기반 라우팅 및 Navigation 구현
/// 
/// 팬 역할 사용자의 메인 홈 화면입니다.
/// 기본 구조만 구현되며, 상세 기능은 이후 WP에서 추가됩니다.
class FanHomeScreen extends StatelessWidget {
  const FanHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '${AppEnvironment.appTitle} - 팬',
        role: 'fan',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 새로고침 (구독 목록 등 업데이트)
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WP-1.5: 권한 기반 UI 테스트 예제
              const _PermissionTestSection(),
              const SizedBox(height: AppSpacing.xl),

              // WP-2.3: 내 구독 섹션
              _MySubscriptionsSection(),
              const SizedBox(height: AppSpacing.xl),

              // WP-2.4: 답변 피드 섹션
              const _AnswersFeedSection(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _FanBottomNavigation(),
    );
  }
}

/// 팬용 Bottom Navigation
class _FanBottomNavigation extends StatelessWidget {
  const _FanBottomNavigation();

  /// 현재 경로에 따른 인덱스 반환
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    switch (location) {
      case '/fan/home':
        return 0;
      case '/fan/questions':
        return 1;
      case '/fan/community':
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
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.question_answer),
          label: '질문',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: '커뮤니티',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '프로필',
        ),
      ],
      onTap: (index) {
        // WP-1.4: Go Router 사용
        switch (index) {
          case 0:
            context.go('/fan/home');
            break;
          case 1:
            context.go('/fan/questions');
            break;
          case 2:
            context.go('/fan/community');
            break;
          case 3:
            context.go('/fan/profile');
            break;
        }
      },
    );
  }
}

/// 권한 테스트 섹션
/// 
/// WP-1.5: RBAC 구현 및 권한 검증 - 실제 테스트 예제
class _PermissionTestSection extends StatelessWidget {
  const _PermissionTestSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                '권한 테스트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // 팬만 보이는 버튼 (RoleWrapper 테스트)
              RoleWrapper(
                role: PermissionChecker.roleFan,
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        // 질문 작성 화면으로 이동 (홈에서는 새로고침이 필요 없음)
                        await context.push('/fan/questions/create');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('질문 작성하기'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/fan/celebrities');
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('셀럽 탐색하기'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 권한 기반 버튼 (PermissionButton 테스트)
              // 주의: canCreateQuestion은 예외를 발생시킬 수 있으므로 try-catch 필요
              _SafePermissionButton(
                text: '질문 작성 테스트',
                permissionCheck: (user) {
                  try {
                    PermissionChecker.canCreateQuestion(user);
                    return true;
                  } catch (e) {
                    return false;
                  }
                },
                onPressed: () => _showSuccessMessage(context, '질문 작성 권한이 있습니다.'),
                noPermissionTooltip: '질문 작성은 팬만 가능합니다.',
              ),
              
              const SizedBox(height: 8),
              
              // 셀럽은 보이지 않아야 함 (RoleWrapper 테스트)
              RoleWrapper(
                role: PermissionChecker.roleCelebrity,
                hideWhenNoPermission: true,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('이 버튼은 셀럽에게만 보입니다'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 현재 권한 정보 표시
              _buildPermissionInfo(context, user),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPermissionInfo(BuildContext context, UserModel? user) {
    if (user == null) {
      return const Text(
        '로그인이 필요합니다.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final canViewQuestion = PermissionChecker.canViewQuestionGeneral(
      user,
      isHidden: false,
    );
    
    final isFan = PermissionChecker.hasRole(user, PermissionChecker.roleFan);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 권한 정보',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('역할: ${user.role ?? "없음"}'),
            Text('질문 조회 가능: ${canViewQuestion ? "예" : "아니오"}'),
            Text('팬 권한: ${isFan ? "예" : "아니오"}'),
          ],
        ),
      ),
    );
  }
}

/// 안전한 권한 버튼 (예외를 catch하여 처리)
class _SafePermissionButton extends StatelessWidget {
  final String text;
  final bool Function(UserModel?) permissionCheck;
  final VoidCallback? onPressed;
  final String? noPermissionTooltip;

  const _SafePermissionButton({
    required this.text,
    required this.permissionCheck,
    this.onPressed,
    this.noPermissionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        final hasPermission = permissionCheck(user);
        final bool isEnabled = hasPermission && onPressed != null;

        Widget button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          child: Text(text),
        );

        if (!hasPermission && noPermissionTooltip != null) {
          return Tooltip(
            message: noPermissionTooltip!,
            child: button,
          );
        }

        return button;
      },
    );
  }
}

/// 내 구독 섹션
/// 
/// WP-2.3: 셀럽 프로필 및 구독 시스템
class _MySubscriptionsSection extends StatelessWidget {
  const _MySubscriptionsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return FutureBuilder<List<CelebrityWithSubscriberCount>>(
          future: _loadMySubscriptions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Text(
                  '구독 목록을 불러올 수 없습니다: ${snapshot.error}',
                  style: AppTypography.body2.copyWith(color: Colors.red),
                ),
              );
            }

            final subscriptions = snapshot.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '내 구독',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subscriptions.isNotEmpty)
                      TextButton(
                        onPressed: () => context.push('/fan/my-subscriptions'),
                        child: const Text('전체 보기'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (subscriptions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.subscriptions_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '구독한 셀럽이 없습니다.',
                          style: AppTypography.body1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/fan/celebrities'),
                          icon: const Icon(Icons.search),
                          label: const Text('셀럽 탐색하기'),
                        ),
                      ],
                    ),
                  )
                else
                  // 최대 3개만 미리보기
                  ...subscriptions.take(3).map((item) => CelebrityCard(
                        celebrity: item.celebrity,
                        subscriberCount: item.subscriberCount,
                        onTap: () => context.push('/fan/celebrities/${item.celebrity.id}'),
                      )),
              ],
            );
          },
        );
      },
    );
  }

  /// 내 구독 목록 로드
  Future<List<CelebrityWithSubscriberCount>> _loadMySubscriptions() async {
    try {
      final subscriptions = await SubscriptionService.getMySubscriptions();
      final result = <CelebrityWithSubscriberCount>[];

      for (final celebrity in subscriptions) {
        final profile = await CelebrityService.getCelebrityProfile(celebrity.id);
        if (profile != null) {
          result.add(profile);
        }
      }

      return result;
    } catch (e) {
      print('⚠️ 내 구독 목록 로드 실패: $e');
      return [];
    }
  }
}

/// 답변 피드 섹션
/// 
/// WP-2.4: 답변 피드 (Q&A 연결)
/// 
/// 최근 답변을 미리보기로 표시하고, 전체 피드로 이동할 수 있는 섹션입니다.
class _AnswersFeedSection extends StatefulWidget {
  const _AnswersFeedSection();

  @override
  State<_AnswersFeedSection> createState() => _AnswersFeedSectionState();
}

class _AnswersFeedSectionState extends State<_AnswersFeedSection> {
  List<QAModel> _qaList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnswersFeed();
  }

  /// 최근 답변 피드 로드 (최대 5개)
  Future<void> _loadAnswersFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final qaList = await AnswerService.getAnswersFeed(
        limit: 5, // 홈 화면에서는 최대 5개만 표시
        offset: 0,
        onlySubscribed: true, // 구독한 셀럽만
      );

      if (mounted) {
        setState(() {
          _qaList = qaList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '답변 피드를 불러오는데 실패했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '최근 답변',
              style: AppTypography.h5.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push('/fan/answers');
              },
              child: const Text('더보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // 답변 피드 목록
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Text(
                _errorMessage!,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else if (_qaList.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Text(
                '구독한 셀럽의 답변이 없습니다.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ..._qaList.map((qa) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: QACard(
                  qa: qa,
                  onTap: () {
                    context.push('/fan/questions/${qa.question.id}');
                  },
                ),
              )),
      ],
    );
  }
}

