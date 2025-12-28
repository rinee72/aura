import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/community_post_model.dart';
import '../services/community_service.dart';
import '../widgets/community_post_card.dart';
import '../../auth/models/user_model.dart';

/// 커뮤니티 목록 화면
/// 
/// WP-2.5: 팬 커뮤니티 (게시글/댓글)
/// 
/// 팬들이 작성한 모든 커뮤니티 게시글을 목록으로 보여주는 화면입니다.
class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  List<CommunityPostModel> _posts = [];
  Map<String, UserModel?> _authors = {}; // 게시글 ID -> 작성자 정보
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  static const int _pageSize = 20;
  String? _errorMessage;
  String _sortBy = 'created_at'; // 정렬 기준: 'created_at' 또는 'comment_count'
  String _orderBy = 'desc'; // 정렬 방향: 'asc' 또는 'desc'
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 게시글 목록 로드
  Future<void> _loadPosts({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (refresh) {
        _currentOffset = 0;
        _posts = [];
        _authors = {};
        _hasMore = true;
      }
    });

    try {
      final posts = await CommunityService.getPosts(
        limit: _pageSize,
        offset: _currentOffset,
        sortBy: _sortBy,
        orderBy: _orderBy,
        searchQuery: _searchQuery,
      );

      // 작성자 정보 조회
      final authorMap = <String, UserModel?>{};
      for (final post in posts) {
        final author = await CommunityService.getPostAuthor(post.userId);
        authorMap[post.id] = author;
      }

      setState(() {
        if (refresh) {
          _posts = posts;
          _authors = authorMap;
        } else {
          _posts.addAll(posts);
          _authors.addAll(authorMap);
        }
        _hasMore = posts.length == _pageSize;
        _currentOffset += posts.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '게시글을 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 새로고침 처리
  Future<void> _handleRefresh() async {
    await _loadPosts(refresh: true);
  }

  /// 검색 처리
  void _handleSearch() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
      _currentOffset = 0;
      _posts = [];
      _authors = {};
      _hasMore = true;
    });
    _loadPosts(refresh: true);
  }

  /// 게시글 상세 화면으로 이동
  void _navigateToPostDetail(CommunityPostModel post) {
    context.push('/fan/community/${post.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '커뮤니티',
        role: 'fan',
        actions: [
          // 정렬 드롭다운
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'latest') {
                  _sortBy = 'created_at';
                  _orderBy = 'desc';
                } else if (value == 'oldest') {
                  _sortBy = 'created_at';
                  _orderBy = 'asc';
                } else if (value == 'popular') {
                  _sortBy = 'comment_count';
                  _orderBy = 'desc';
                }
                _currentOffset = 0;
                _posts = [];
                _authors = {};
                _hasMore = true;
              });
              _loadPosts(refresh: true);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'latest',
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 20),
                    SizedBox(width: 8),
                    Text('최신순'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    Icon(Icons.sort, size: 20),
                    SizedBox(width: 8),
                    Text('오래된순'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'popular',
                child: Row(
                  children: [
                    Icon(Icons.comment, size: 20),
                    SizedBox(width: 8),
                    Text('댓글순'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          slivers: [
            // 게시글 작성 버튼
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: CustomButton(
                  label: '게시글 작성하기',
                  onPressed: () async {
                    // 게시글 작성 화면으로 이동하고 돌아올 때 목록 새로고침
                    await context.push('/fan/community/create');
                    // 돌아왔을 때 목록 새로고침
                    if (mounted) {
                      _handleRefresh();
                    }
                  },
                  icon: const Icon(Icons.add, size: 20),
                  isFullWidth: true,
                ),
              ),
            ),

            // 검색 바
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _searchController,
                        hint: '제목 또는 내용 검색',
                        prefixIcon: const Icon(Icons.search),
                        onSubmitted: (_) => _handleSearch(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _handleSearch,
                      tooltip: '검색',
                    ),
                    if (_searchQuery != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = null;
                            _currentOffset = 0;
                            _posts = [];
                            _authors = {};
                            _hasMore = true;
                          });
                          _loadPosts(refresh: true);
                        },
                        tooltip: '검색 초기화',
                      ),
                  ],
                ),
              ),
            ),

            // 에러 메시지
            if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
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
                      ],
                    ),
                  ),
                ),
              ),

            // 게시글 목록
            if (_posts.isEmpty && !_isLoading)
              SliverFillRemaining(
                child: Center(
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
                        _searchQuery != null
                            ? '검색 결과가 없습니다'
                            : '아직 게시글이 없습니다',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // 무한 스크롤: 마지막 아이템 근처에서 다음 페이지 로드
                    if (index >= _posts.length - 3 && _hasMore && !_isLoading) {
                      _loadPosts();
                    }

                    if (index < _posts.length) {
                      final post = _posts[index];
                      final author = _authors[post.id];

                      return CommunityPostCard(
                        post: post,
                        author: author,
                        onTap: () => _navigateToPostDetail(post),
                      );
                    }

                    // 로딩 인디케이터
                    if (index == _posts.length && _isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    return null;
                  },
                  childCount: _posts.length + (_isLoading ? 1 : 0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

