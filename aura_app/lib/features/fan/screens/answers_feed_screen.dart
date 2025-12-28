import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../models/qa_model.dart';
import '../services/answer_service.dart';
import '../widgets/qa_card.dart';

/// 답변 피드 화면
/// 
/// WP-2.4: 답변 피드 (Q&A 연결)
/// 
/// 구독한 셀럽의 답변을 Q&A 형태로 표시하는 피드 화면입니다.
class AnswersFeedScreen extends StatefulWidget {
  const AnswersFeedScreen({super.key});

  @override
  State<AnswersFeedScreen> createState() => _AnswersFeedScreenState();
}

class _AnswersFeedScreenState extends State<AnswersFeedScreen> {
  List<QAModel> _qaList = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  static const int _pageSize = 20;
  String? _errorMessage;
  bool _onlySubscribed = true; // 구독한 셀럽만 필터링
  DateTime? _startDate; // 날짜 필터 (null이면 전체)

  @override
  void initState() {
    super.initState();
    _loadAnswersFeed();
  }

  /// 답변 피드 로드
  Future<void> _loadAnswersFeed({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (refresh) {
        _currentOffset = 0;
        _qaList = [];
        _hasMore = true;
      }
    });

    try {
      final qaList = await AnswerService.getAnswersFeed(
        limit: _pageSize,
        offset: _currentOffset,
        onlySubscribed: _onlySubscribed,
        startDate: _startDate,
      );

      setState(() {
        if (refresh) {
          _qaList = qaList;
        } else {
          _qaList.addAll(qaList);
        }
        _currentOffset += qaList.length;
        _hasMore = qaList.length >= _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '답변 피드를 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 새로고침
  Future<void> _handleRefresh() async {
    await _loadAnswersFeed(refresh: true);
  }

  /// 필터 변경 처리
  Future<void> _handleFilterChange({
    bool? onlySubscribed,
    DateTime? startDate,
  }) async {
    setState(() {
      if (onlySubscribed != null) {
        _onlySubscribed = onlySubscribed;
      }
      if (startDate != null) {
        _startDate = startDate;
      }
    });
    await _loadAnswersFeed(refresh: true);
  }

  /// Q&A 카드 탭 처리
  void _handleQATap(QAModel qa) {
    context.push('/fan/questions/${qa.question.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '답변 피드',
        role: 'fan',
      ),
      body: Column(
        children: [
          // 필터 섹션
          _buildFilterSection(),
          
          // 답변 피드 목록
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _buildAnswersList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 필터 섹션 빌드
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 구독한 셀럽만 필터
          FilterChip(
            label: const Text('구독한 셀럽만'),
            selected: _onlySubscribed,
            onSelected: (selected) {
              _handleFilterChange(onlySubscribed: selected);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          
          // 날짜 필터 드롭다운
          PopupMenuButton<String>(
            onSelected: (value) {
              DateTime? startDate;
              final now = DateTime.now();
              
              switch (value) {
                case 'today':
                  startDate = DateTime(now.year, now.month, now.day);
                  break;
                case 'week':
                  startDate = now.subtract(const Duration(days: 7));
                  break;
                case 'month':
                  startDate = DateTime(now.year, now.month, 1);
                  break;
                case 'all':
                  startDate = null;
                  break;
              }
              
              _handleFilterChange(startDate: startDate);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('전체'),
              ),
              const PopupMenuItem(
                value: 'today',
                child: Text('오늘'),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Text('이번 주'),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Text('이번 달'),
              ),
            ],
            child: Chip(
              label: Text(
                _startDate == null
                    ? '전체 기간'
                    : _startDate!.year == DateTime.now().year &&
                            _startDate!.month == DateTime.now().month &&
                            _startDate!.day == DateTime.now().day
                        ? '오늘'
                        : DateTime.now().difference(_startDate!).inDays <= 7
                            ? '이번 주'
                            : '이번 달',
              ),
              avatar: const Icon(Icons.calendar_today, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// 답변 목록 빌드
  Widget _buildAnswersList() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage!,
              style: AppTypography.body1.copyWith(
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => _loadAnswersFeed(refresh: true),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _qaList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_qaList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _onlySubscribed
                  ? '구독한 셀럽의 답변이 없습니다.\n셀럽을 구독하고 답변을 기다려보세요!'
                  : '답변이 없습니다.',
              style: AppTypography.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _qaList.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _qaList.length) {
          // 더 불러오기 로딩 인디케이터
          if (_hasMore && !_isLoading) {
            // 다음 페이지 자동 로드
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadAnswersFeed();
            });
          }
          return _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink();
        }

        final qa = _qaList[index];
        return QACard(
          qa: qa,
          onTap: () => _handleQATap(qa),
        );
      },
    );
  }
}
