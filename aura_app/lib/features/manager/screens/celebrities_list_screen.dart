import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../services/celebrity_management_service.dart';
import '../widgets/manager_celebrity_card.dart';

/// 셀럽 목록 화면 (매니저용)
/// 
/// WP-4.4: 셀럽 계정 관리
/// 
/// 매니저가 모든 셀럽 목록을 조회하고 검색/정렬할 수 있는 화면입니다.
class CelebritiesListScreen extends StatefulWidget {
  const CelebritiesListScreen({super.key});

  @override
  State<CelebritiesListScreen> createState() => _CelebritiesListScreenState();
}

class _CelebritiesListScreenState extends State<CelebritiesListScreen> {
  List<CelebrityWithStats> _celebrities = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  
  // 정렬 옵션
  String _sortBy = 'name'; // 'name', 'subscribers', 'recent_activity'
  String _orderBy = 'asc'; // 'asc', 'desc'

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
      final celebrities = await CelebrityManagementService.getAllCelebrities(
        searchQuery: _searchController.text.trim().isEmpty 
            ? null 
            : _searchController.text.trim(),
        sortBy: _sortBy,
        orderBy: _orderBy,
      );

      if (mounted) {
        setState(() {
          _celebrities = celebrities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorString = e.toString();
        String errorMessage = '셀럽 목록을 불러오는데 실패했습니다: $e';
        
        // 권한 관련 에러 처리
        if (errorString.contains('권한') || errorString.contains('매니저만')) {
          errorMessage = '셀럽 목록 조회는 매니저만 가능합니다.';
        } else if (errorString.contains('로그인')) {
          errorMessage = '로그인이 필요합니다.';
        } else if (errorString.contains('네트워크') || errorString.contains('연결')) {
          errorMessage = '네트워크 연결을 확인해주세요.';
        }
        
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      }
    }
  }

  /// 검색 실행
  void _handleSearch(String query) {
    _loadCelebrities();
  }

  /// 정렬 옵션 변경
  void _handleSortChanged(String? value) {
    if (value == null) return;
    
    setState(() {
      _sortBy = value;
    });
    _loadCelebrities();
  }

  /// 정렬 순서 변경
  void _handleOrderChanged(String? value) {
    if (value == null) return;
    
    setState(() {
      _orderBy = value;
    });
    _loadCelebrities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '셀럽 관리',
        role: 'manager',
      ),
      body: Column(
        children: [
          // 검색 및 정렬 영역
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.surfaceVariant,
            child: Column(
              children: [
                // 검색 바
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '이름 또는 이메일로 검색',
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
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: _handleSearch,
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                
                // 정렬 옵션
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: InputDecoration(
                          labelText: '정렬 기준',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radius),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('이름순'),
                          ),
                          DropdownMenuItem(
                            value: 'subscribers',
                            child: Text('구독자순'),
                          ),
                          DropdownMenuItem(
                            value: 'recent_activity',
                            child: Text('최근 활동순'),
                          ),
                        ],
                        onChanged: _handleSortChanged,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _orderBy,
                        decoration: InputDecoration(
                          labelText: '순서',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radius),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'asc',
                            child: Text('오름차순'),
                          ),
                          DropdownMenuItem(
                            value: 'desc',
                            child: Text('내림차순'),
                          ),
                        ],
                        onChanged: _handleOrderChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 셀럽 목록
          Expanded(
            child: _isLoading && _celebrities.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null && _celebrities.isEmpty
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
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton(
                              onPressed: _loadCelebrities,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                    : _celebrities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  '셀럽이 없습니다.',
                                  style: AppTypography.body1.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCelebrities,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: _celebrities.length,
                              itemBuilder: (context, index) {
                                final celebrityWithStats = _celebrities[index];
                                return ManagerCelebrityCard(
                                  celebrity: celebrityWithStats.celebrity,
                                  stats: celebrityWithStats.stats,
                                  onTap: () {
                                    context.push(
                                      '/manager/celebrities/${celebrityWithStats.celebrity.id}',
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

