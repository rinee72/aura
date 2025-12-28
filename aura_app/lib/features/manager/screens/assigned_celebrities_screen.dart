import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../services/manager_assignment_service.dart';
import '../../auth/models/user_model.dart';

/// 담당 셀럽 목록 화면
/// 
/// WP-4.2 확장: 매니저-셀럽 관계 명시적 관리
/// 
/// 매니저가 담당하는 셀럽 목록을 표시하는 화면입니다.
class AssignedCelebritiesScreen extends StatefulWidget {
  const AssignedCelebritiesScreen({super.key});

  @override
  State<AssignedCelebritiesScreen> createState() => _AssignedCelebritiesScreenState();
}

class _AssignedCelebritiesScreenState extends State<AssignedCelebritiesScreen> {
  List<Map<String, dynamic>> _assignedCelebrities = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssignedCelebrities();
  }

  /// 담당 셀럽 목록 로드
  Future<void> _loadAssignedCelebrities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final assignments = await ManagerAssignmentService.getMyAssignedCelebrities();
      setState(() {
        _assignedCelebrities = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '담당 셀럽을 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '내 담당 셀럽',
        role: 'manager',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAssignedCelebrities,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading && _assignedCelebrities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _assignedCelebrities.isEmpty
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
                          onPressed: _loadAssignedCelebrities,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : _assignedCelebrities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            '담당 셀럽이 없습니다.',
                            style: AppTypography.body1.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '관리자에게 할당을 요청하세요.',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAssignedCelebrities,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _assignedCelebrities.length,
                        itemBuilder: (context, index) {
                          final item = _assignedCelebrities[index];
                          final celebrity = item['celebrity'] as UserModel?;
                          
                          if (celebrity == null) return const SizedBox.shrink();
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: InkWell(
                              onTap: () {
                                // 셀럽 상세 화면으로 이동 (향후 구현)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${celebrity.displayName ?? celebrity.email}의 프로필'),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(AppSpacing.radius),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(
                                  children: [
                                    // 프로필 이미지
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: AppColors.primary.withOpacity(0.2),
                                      backgroundImage: celebrity.avatarUrl != null
                                          ? NetworkImage(celebrity.avatarUrl!)
                                          : null,
                                      child: celebrity.avatarUrl == null
                                          ? Icon(
                                              Icons.person,
                                              size: 32,
                                              color: AppColors.primary,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    
                                    // 셀럽 정보
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            celebrity.displayName ?? celebrity.email,
                                            style: AppTypography.h6.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (celebrity.displayName != null)
                                            Text(
                                              celebrity.email,
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          if (celebrity.bio != null && celebrity.bio!.isNotEmpty) ...[
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(
                                              celebrity.bio!,
                                              style: AppTypography.body2.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    
                                    // 화살표 아이콘
                                    Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

