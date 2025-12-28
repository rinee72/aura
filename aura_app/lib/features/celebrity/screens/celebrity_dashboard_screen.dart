import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/environment.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/widgets/permission_wrapper.dart';
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/permission_error_handler.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../services/question_curation_service.dart';
import '../models/curated_question_model.dart';
import '../widgets/curated_question_card.dart';
import '../widgets/celebrity_bottom_navigation.dart';

/// 셀럽 대시보드 화면
/// 
/// WP-1.4: 역할 기반 라우팅 및 Navigation 구현
/// WP-3.1: 질문 큐레이션 대시보드 통합
/// 
/// 셀럽 역할 사용자의 메인 대시보드 화면입니다.
/// 질문 큐레이션 섹션을 포함합니다.
class CelebrityDashboardScreen extends StatelessWidget {
  const CelebrityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '${AppEnvironment.appTitle} - 셀럽',
        role: 'celebrity',
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 새로고침 (향후 구현)
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WP-3.4: 프로필 관리 섹션
              _ProfileManagementSection(),
              const SizedBox(height: AppSpacing.xl),

              // WP-3.5: 셀럽 활동 섹션
              _CelebrityActionSection(),
              const SizedBox(height: AppSpacing.xl),

              // WP-3.1: 질문 큐레이션 섹션
              _QuestionCurationSection(),
              const SizedBox(height: AppSpacing.xl),

              // WP-1.5: 권한 기반 UI 테스트 예제
              const _CelebrityPermissionTestSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CelebrityBottomNavigation(),
    );
  }
}

/// 프로필 관리 섹션
/// 
/// WP-3.4: 셀럽 프로필 관리
/// 
/// 셀럽 대시보드에 프로필 관리 링크를 추가합니다.
class _ProfileManagementSection extends StatelessWidget {
  const _ProfileManagementSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        
        // 셀럽이 아니면 섹션 숨김
        if (user == null || user.role != PermissionChecker.roleCelebrity) {
          return const SizedBox.shrink();
        }

        return Card(
          color: AppColors.surface,
          child: InkWell(
            onTap: () {
              context.push('/celebrity/profile');
            },
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!) as ImageProvider
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 30,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName ?? '이름 없음',
                          style: AppTypography.h6.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '프로필 관리',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 셀럽 활동 섹션
/// 
/// WP-3.5: 셀럽 피드 작성
/// 
/// 셀럽 대시보드에 피드 작성, 내 답변 관리, 프로필 관리 버튼을 추가합니다.
class _CelebrityActionSection extends StatelessWidget {
  const _CelebrityActionSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '셀럽 활동',
          style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildActionButton(
              context,
              '피드 작성',
              Icons.article,
              () => context.push('/celebrity/feeds/create'),
            ),
            _buildActionButton(
              context,
              '내 피드',
              Icons.feed,
              () => context.push('/celebrity/feeds'),
            ),
            _buildActionButton(
              context,
              '질문 큐레이션',
              Icons.question_answer,
              () => context.push('/celebrity/questions/curation'),
            ),
            _buildActionButton(
              context,
              '내 답변 관리',
              Icons.rate_review,
              () => context.push('/celebrity/answers'),
            ),
            _buildActionButton(
              context,
              '프로필 관리',
              Icons.person,
              () => context.push('/celebrity/profile'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

/// 질문 큐레이션 섹션
/// 
/// WP-3.1: 질문 큐레이션 대시보드
/// 
/// 셀럽 대시보드에 질문 큐레이션 섹션을 추가합니다.
class _QuestionCurationSection extends StatelessWidget {
  const _QuestionCurationSection();

  @override
  Widget build(BuildContext context) {
    // 권한 검증: 셀럽만 표시
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        
        // 셀럽이 아니면 섹션 숨김
        if (user == null || user.role != PermissionChecker.roleCelebrity) {
          return const SizedBox.shrink();
        }

        return _buildQuestionCurationContent(context);
      },
    );
  }

  Widget _buildQuestionCurationContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '질문 큐레이션',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '좋아요 기반 Top 질문을 확인하고 답변하세요',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () {
                context.push('/celebrity/questions/curation');
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('전체 보기'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // 질문 큐레이션 미리보기 (최대 3개)
        FutureBuilder<List<CuratedQuestionModel>>(
          future: _loadTopQuestions(),
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
                  '질문을 불러올 수 없습니다: ${snapshot.error}',
                  style: AppTypography.body2.copyWith(color: Colors.red),
                ),
              );
            }

            final questions = snapshot.data ?? [];
            
            if (questions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.question_answer_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '아직 질문이 없습니다.',
                      style: AppTypography.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                ...questions.take(3).map((curatedQuestion) {
                  final question = curatedQuestion.question;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: CuratedQuestionCard(
                      curatedQuestion: curatedQuestion,
                      onTap: () {
                        context.push('/celebrity/questions/${question.id}/answer');
                      },
                    ),
                  );
                }),
                
                // 더보기 버튼
                if (questions.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          context.push('/celebrity/questions/curation');
                        },
                        child: const Text('더보기'),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Top 질문 로드
  Future<List<CuratedQuestionModel>> _loadTopQuestions() async {
    try {
      final questions = await QuestionCurationService.getTopQuestions(
        limit: 5, // 미리보기용으로 5개 로드
        dateFilter: 'all',
        statusFilter: 'all',
      );
      return questions;
    } catch (e) {
      print('⚠️ Top 질문 로드 실패: $e');
      return [];
    }
  }
}


/// 셀럽 권한 테스트 섹션
/// 
/// WP-1.5: RBAC 구현 및 권한 검증 - 실제 테스트 예제
class _CelebrityPermissionTestSection extends StatelessWidget {
  const _CelebrityPermissionTestSection();

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
              
              // 셀럽만 보이는 버튼 (RoleWrapper 테스트)
              RoleWrapper(
                role: PermissionChecker.roleCelebrity,
                child: ElevatedButton.icon(
                  onPressed: () => _testManageAnswer(context, user),
                  icon: const Icon(Icons.edit),
                  label: const Text('답변 작성 (셀럽만 가능)'),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // 팬은 보이지 않아야 함 (RoleWrapper 테스트)
              RoleWrapper(
                role: PermissionChecker.roleFan,
                hideWhenNoPermission: true,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('이 버튼은 팬에게만 보입니다'),
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

  void _testManageAnswer(BuildContext context, UserModel? user) {
    PermissionErrorHandler.checkAndHandle(
      context,
      user,
      () => PermissionChecker.canManageAnswer(user),
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('답변 작성 권한이 확인되었습니다!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Widget _buildPermissionInfo(BuildContext context, UserModel? user) {
    if (user == null) {
      return const Text(
        '로그인이 필요합니다.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final canManageAnswer = _checkCanManageAnswer(user);
    final isCelebrity = PermissionChecker.hasRole(user, PermissionChecker.roleCelebrity);

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
            Text('답변 작성 가능: ${canManageAnswer ? "예" : "아니오"}'),
            Text('셀럽 권한: ${isCelebrity ? "예" : "아니오"}'),
          ],
        ),
      ),
    );
  }

  bool _checkCanManageAnswer(UserModel? user) {
    try {
      PermissionChecker.canManageAnswer(user);
      return true;
    } catch (e) {
      return false;
    }
  }
}

