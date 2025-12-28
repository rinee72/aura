import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/widgets/custom_button.dart';
import '../models/question_model.dart';
import '../services/question_service.dart';
import '../widgets/question_card.dart';
import '../../auth/models/user_model.dart';

/// 질문 목록 화면
/// 
/// WP-2.1: 질문 작성 및 기본 목록 화면
/// 
/// 팬이 작성한 모든 질문을 목록으로 보여주는 화면입니다.
class QuestionsListScreen extends StatefulWidget {
  const QuestionsListScreen({super.key});

  @override
  State<QuestionsListScreen> createState() => _QuestionsListScreenState();
}

class _QuestionsListScreenState extends State<QuestionsListScreen> {
  List<QuestionModel> _questions = [];
  Map<String, UserModel?> _authors = {}; // 질문 ID -> 작성자 정보
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  static const int _pageSize = 20;
  String? _errorMessage;
  String _sortBy = 'created_at'; // 정렬 기준: 'created_at' 또는 'like_count'
  String _orderBy = 'desc'; // 정렬 방향: 'asc' 또는 'desc'

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }


  /// 질문 목록 로드
  Future<void> _loadQuestions({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (refresh) {
        _currentOffset = 0;
        _questions = [];
        _authors = {};
        _hasMore = true;
      }
    });

    try {
      final questions = await QuestionService.getQuestions(
        limit: _pageSize,
        offset: _currentOffset,
        sortBy: _sortBy,
        orderBy: _orderBy,
      );

      // 작성자 정보 조회
      final authorMap = <String, UserModel?>{};
      for (final question in questions) {
        final author = await QuestionService.getQuestionAuthor(question.userId);
        authorMap[question.id] = author;
      }

      setState(() {
        if (refresh) {
          _questions = questions;
          _authors = authorMap;
        } else {
          _questions.addAll(questions);
          _authors.addAll(authorMap);
        }
        _currentOffset += questions.length;
        _hasMore = questions.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '질문 목록을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 새로고침
  Future<void> _handleRefresh() async {
    await _loadQuestions(refresh: true);
  }

  /// 질문 상세 화면으로 이동
  void _navigateToDetail(QuestionModel question) {
    context.push('/fan/questions/${question.id}');
  }

  /// 좋아요 토글 처리
  Future<void> _handleLikeToggle(QuestionModel question) async {
    try {
      // 낙관적 UI 업데이트
      final currentLiked = question.isLiked;
      final newLikeCount = currentLiked ? question.likeCount - 1 : question.likeCount + 1;
      
      setState(() {
        final index = _questions.indexWhere((q) => q.id == question.id);
        if (index != -1) {
          _questions[index] = question.copyWith(
            isLiked: !currentLiked,
            likeCount: newLikeCount,
          );
        }
      });

      // 서버에 좋아요 토글 요청
      await QuestionService.toggleLike(question.id);
      
      // 서버에서 최신 데이터 가져오기
      final updatedQuestion = await QuestionService.getQuestionById(question.id);
      if (updatedQuestion != null && mounted) {
        setState(() {
          final index = _questions.indexWhere((q) => q.id == question.id);
          if (index != -1) {
            _questions[index] = updatedQuestion;
          }
        });
      }
    } catch (e) {
      // 에러 발생 시 원래 상태로 되돌리기
      if (mounted) {
        setState(() {
          final index = _questions.indexWhere((q) => q.id == question.id);
          if (index != -1) {
            _questions[index] = question;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('좋아요 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '질문 목록',
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
                  _sortBy = 'like_count';
                  _orderBy = 'desc';
                }
                _currentOffset = 0;
                _questions = [];
                _authors = {};
                _hasMore = true;
              });
              _loadQuestions(refresh: true);
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
                    Icon(Icons.favorite, size: 20),
                    SizedBox(width: 8),
                    Text('좋아요순'),
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
            // 질문 작성 버튼
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: CustomButton(
                  label: '질문 작성하기',
                  onPressed: () async {
                    // 질문 작성 화면으로 이동하고 돌아올 때 목록 새로고침
                    await context.push('/fan/questions/create');
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
                        TextButton(
                          onPressed: _handleRefresh,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 질문 목록
            if (_questions.isEmpty && !_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.question_answer_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '아직 등록된 질문이 없습니다.',
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomButton(
                        label: '첫 질문 작성하기',
                        onPressed: () async {
                          // 질문 작성 화면으로 이동하고 돌아올 때 목록 새로고침
                          await context.push('/fan/questions/create');
                          // 돌아왔을 때 목록 새로고침
                          if (mounted) {
                            _handleRefresh();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < _questions.length) {
                        final question = _questions[index];
                        final author = _authors[question.id];
                        return QuestionCard(
                          question: question,
                          author: author,
                          onTap: () => _navigateToDetail(question),
                          onLikeTap: () => _handleLikeToggle(question),
                        );
                      } else if (_hasMore && !_isLoading) {
                        // 더 불러오기 (로딩 중이 아닐 때만)
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _loadQuestions();
                        });
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else {
                        // 마지막
                        return const SizedBox.shrink();
                      }
                    },
                    childCount: _questions.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),

            // 로딩 인디케이터
            if (_isLoading && _questions.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _FanBottomNavigation(),
    );
  }
}

/// 팬용 Bottom Navigation
/// 
/// 질문 목록 화면에서도 팬 홈 화면과 동일한 네비게이션을 제공합니다.
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
        // 질문 상세 화면도 질문 탭으로 간주
        if (location.startsWith('/fan/questions/')) {
          return 1;
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

