import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../auth/models/user_model.dart';
import '../services/subscription_service.dart';
import '../widgets/celebrity_card.dart';
import '../services/celebrity_service.dart';

/// 내 구독 목록 화면
/// 
/// WP-2.3: 셀럽 프로필 및 구독 시스템
/// 
/// 팬이 구독한 셀럽 목록을 확인하고 관리할 수 있는 화면입니다.
class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  List<UserModel> _subscriptions = [];
  Map<String, int> _subscriberCounts = {}; // 셀럽 ID -> 구독자 수
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  /// 구독 목록 로드
  Future<void> _loadSubscriptions() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subscriptions = await SubscriptionService.getMySubscriptions();

      // 각 셀럽의 구독자 수 조회
      final subscriberCounts = <String, int>{};
      for (final celebrity in subscriptions) {
        try {
          final count = await CelebrityService.getCelebrityProfile(celebrity.id);
          subscriberCounts[celebrity.id] = count?.subscriberCount ?? 0;
        } catch (e) {
          print('⚠️ 구독자 수 조회 실패 (${celebrity.id}): $e');
          subscriberCounts[celebrity.id] = 0;
        }
      }

      setState(() {
        _subscriptions = subscriptions;
        _subscriberCounts = subscriberCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '구독 목록을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 구독 취소 처리
  Future<void> _handleUnsubscribe(String celebrityId) async {
    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('구독 취소'),
        content: const Text('정말 구독을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('구독 취소', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SubscriptionService.unsubscribe(celebrityId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('구독이 취소되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        // 목록 새로고침
        _loadSubscriptions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구독 취소에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 셀럽 프로필 화면으로 이동
  void _navigateToProfile(String celebrityId) {
    context.push('/fan/celebrities/$celebrityId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '내 구독',
        role: 'fan',
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubscriptions,
        child: _isLoading && _subscriptions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _subscriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _errorMessage!,
                          style: AppTypography.body1.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton(
                          onPressed: _loadSubscriptions,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  )
                : _subscriptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.subscriptions_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              '구독한 셀럽이 없습니다.',
                              style: AppTypography.body1.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/fan/celebrities'),
                              icon: const Icon(Icons.search),
                              label: const Text('셀럽 탐색하기'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _subscriptions.length,
                        itemBuilder: (context, index) {
                          final celebrity = _subscriptions[index];
                          final subscriberCount = _subscriberCounts[celebrity.id] ?? 0;
                          return Dismissible(
                            key: Key(celebrity.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(AppSpacing.radius),
                              ),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              await _handleUnsubscribe(celebrity.id);
                              return false; // Dismissible이 자동으로 제거하지 않도록 (수동 새로고침)
                            },
                            child: CelebrityCard(
                              celebrity: celebrity,
                              subscriberCount: subscriberCount,
                              onTap: () => _navigateToProfile(celebrity.id),
                            ),
                          );
                        },
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
      case '/fan/questions/create':
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

