import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../services/celebrity_service.dart';
import '../widgets/celebrity_card.dart';

/// 셀럽 리스트 화면
/// 
/// WP-2.3: 셀럽 프로필 및 구독 시스템
/// 
/// 팬이 셀럽을 탐색하고 검색할 수 있는 화면입니다.
class CelebritiesListScreen extends StatefulWidget {
  const CelebritiesListScreen({super.key});

  @override
  State<CelebritiesListScreen> createState() => _CelebritiesListScreenState();
}

class _CelebritiesListScreenState extends State<CelebritiesListScreen> {
  List<CelebrityWithSubscriberCount> _celebrities = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCelebrities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 셀럽 목록 로드
  Future<void> _loadCelebrities() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final celebrities = await CelebrityService.getCelebrities();
      setState(() {
        _celebrities = celebrities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '셀럽 목록을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 셀럽 검색
  Future<void> _searchCelebrities(String query) async {
    if (query.trim().isEmpty) {
      _loadCelebrities();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSearching = true;
    });

    try {
      final celebrities = await CelebrityService.searchCelebrities(query: query);
      setState(() {
        _celebrities = celebrities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '셀럽 검색에 실패했습니다: $e';
        _isLoading = false;
      });
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
        title: '셀럽 탐색',
        role: 'fan',
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '셀럽 이름으로 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadCelebrities();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
              ),
              onSubmitted: _searchCelebrities,
              onChanged: (value) {
                if (value.isEmpty && _isSearching) {
                  _loadCelebrities();
                  setState(() {
                    _isSearching = false;
                  });
                }
              },
            ),
          ),

          // 에러 메시지
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.body2.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadCelebrities,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),

          // 셀럽 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _celebrities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _isSearching
                                  ? '검색 결과가 없습니다.'
                                  : '등록된 셀럽이 없습니다.',
                              style: AppTypography.body1.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        itemCount: _celebrities.length,
                        itemBuilder: (context, index) {
                          final item = _celebrities[index];
                          return CelebrityCard(
                            celebrity: item.celebrity,
                            subscriberCount: item.subscriberCount,
                            onTap: () => _navigateToProfile(item.celebrity.id),
                          );
                        },
                      ),
          ),
        ],
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
        // 셀럽 관련 화면도 홈으로 간주
        if (location.startsWith('/fan/celebrities')) {
          return 0;
        }
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

