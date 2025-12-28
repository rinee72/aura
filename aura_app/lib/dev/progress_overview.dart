import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';
import 'wp_1_1_status.dart';
import 'wp_1_2_status.dart';
import 'wp_1_3_status.dart';

/// 전체 진행 상황 통합 페이지
/// 
/// 지금까지 완료된 모든 Work Package의 진행 상황을 한눈에 볼 수 있습니다.
class ProgressOverviewPage extends StatelessWidget {
  const ProgressOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AURA 개발 진행 상황'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.xl),
          _buildMilestoneOverview(),
          const SizedBox(height: AppSpacing.xl),
          _buildWorkPackages(context),
          const SizedBox(height: AppSpacing.xl),
          _buildQuickLinks(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard, size: 48, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AURA MVP 개발 현황',
                        style: AppTypography.h2.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        '셀럽-팬 소통 플랫폼',
                        style: AppTypography.body1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '✅ Milestone 1 진행 중 (3/4 완료)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Milestone 1: 기본 인프라 및 인증 시스템',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildProgressBar(75), // 3/4 완료
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '진행률: 75%',
                  style: AppTypography.body1,
                ),
                Text(
                  '3/4 완료',
                  style: AppTypography.body1.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(double percentage) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: percentage / 100,
        minHeight: 20,
        backgroundColor: Colors.grey[200],
        valueColor: AlwaysStoppedAnimation<Color>(
          percentage >= 75 ? Colors.green : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildWorkPackages(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '완료된 Work Packages',
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildWPCard(
          context,
          'WP-1.1',
          '데이터베이스 스키마 설계 및 생성',
          '✅ 완료',
          Colors.green,
          Icons.storage,
          '7개 테이블, 18개 인덱스, RLS 정책 설정 완료',
          '/wp11-status',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildWPCard(
          context,
          'WP-1.2',
          'Supabase Auth 기본 연동 및 회원가입/로그인',
          '✅ 완료',
          Colors.green,
          Icons.verified_user,
          '회원가입, 로그인, 세션 관리, JWT 기반 인증 완료',
          '/wp12-status',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildWPCard(
          context,
          'WP-1.3',
          '사용자 프로필 및 역할 관리 시스템',
          '✅ 완료',
          Colors.green,
          Icons.person_add,
          '3-tier 역할 시스템 (Fan/Celebrity/Manager), 프로필 관리 완료',
          '/wp13-status',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildWPCard(
          context,
          'WP-1.4',
          '다음 단계',
          '⏳ 대기 중',
          Colors.grey,
          Icons.arrow_forward,
          '다음 Work Package 준비 중',
          null,
        ),
      ],
    );
  }

  Widget _buildWPCard(
    BuildContext context,
    String wpNumber,
    String title,
    String status,
    Color statusColor,
    IconData icon,
    String description,
    String? route,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: route != null
            ? () => Navigator.of(context).pushNamed(route)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          wpNumber,
                          style: AppTypography.body2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      title,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTypography.body3.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (route != null)
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Card(
      color: AppColors.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '빠른 링크',
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildLinkButton(
              context,
              'WP-1.1 상세 보기',
              Icons.storage,
              '/wp11-status',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildLinkButton(
              context,
              'WP-1.2 상세 보기',
              Icons.verified_user,
              '/wp12-status',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildLinkButton(
              context,
              'WP-1.3 상세 보기',
              Icons.person_add,
              '/wp13-status',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildLinkButton(
              context,
              '컴포넌트 쇼케이스',
              Icons.palette,
              '/showcase',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkButton(
    BuildContext context,
    String label,
    IconData icon,
    String route,
  ) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.of(context).pushNamed(route),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 1,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
