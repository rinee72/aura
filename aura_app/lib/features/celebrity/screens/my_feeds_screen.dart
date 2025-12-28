import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/permission_error_handler.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/feed_service.dart';
import '../models/celebrity_feed_model.dart';
import '../widgets/feed_card.dart';
import '../widgets/celebrity_bottom_navigation.dart';

/// 내 피드 목록 화면
/// 
/// WP-3.5: 셀럽 피드 작성
/// 
/// 셀럽이 자신이 작성한 피드 목록을 확인하고 관리할 수 있는 화면입니다.
class MyFeedsScreen extends StatefulWidget {
  const MyFeedsScreen({super.key});

  @override
  State<MyFeedsScreen> createState() => _MyFeedsScreenState();
}

class _MyFeedsScreenState extends State<MyFeedsScreen> {
  List<CelebrityFeedModel> _feeds = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
  }

  /// 피드 목록 로드
  Future<void> _loadFeeds() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 권한 검증
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleCelebrity);
      } on PermissionException catch (e) {
        if (mounted) {
          PermissionErrorHandler.handleError(context, e);
          setState(() {
            _errorMessage = '피드 관리는 셀럽만 사용할 수 있습니다.';
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

      // 피드 목록 조회
      final feeds = await FeedService.getMyFeeds();

      if (mounted) {
        setState(() {
          _feeds = feeds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '피드를 불러오는 중 오류가 발생했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// 피드 삭제 처리
  Future<void> _handleDeleteFeed(CelebrityFeedModel feed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('피드 삭제'),
        content: const Text('정말 이 피드를 삭제하시겠습니까?'),
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
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FeedService.deleteFeed(feed.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('피드가 삭제되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        
        // 피드 목록 다시 로드
        _loadFeeds();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('피드 삭제 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '내 피드',
        role: 'celebrity',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/celebrity/feeds/create');
            },
            tooltip: '피드 작성',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeeds,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeeds,
        child: _isLoading && _feeds.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _feeds.isEmpty
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
                            onPressed: _loadFeeds,
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _feeds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              '작성한 피드가 없습니다.',
                              style: AppTypography.body1.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.push('/celebrity/feeds/create');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('피드 작성하기'),
                            ),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          if (_errorMessage != null)
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.all(AppSpacing.md),
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: AppTypography.body2.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final feed = _feeds[index];
                                return FeedCard(
                                  feed: feed,
                                  onEdit: () {
                                    context.push('/celebrity/feeds/${feed.id}/edit');
                                  },
                                  onDelete: () {
                                    _handleDeleteFeed(feed);
                                  },
                                );
                              },
                              childCount: _feeds.length,
                            ),
                          ),
                        ],
                      ),
      ),
      bottomNavigationBar: CelebrityBottomNavigation(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/celebrity/feeds/create');
        },
        child: const Icon(Icons.add),
        tooltip: '피드 작성',
      ),
    );
  }
}


