import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_spacing.dart';

/// WP-1.3 완료 상황 표시 페이지
/// 
/// 웹 브라우저에서 WP-1.3의 완료 상황을 확인할 수 있습니다.
class WP13StatusPage extends StatelessWidget {
  const WP13StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WP-1.3 완료 상황'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Row(
              children: [
                const Icon(Icons.person_add, color: AppColors.success, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'WP-1.3: 사용자 프로필 및 역할 관리 시스템',
                    style: AppTypography.h1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 완료된 작업
            _buildSection(
              title: '✅ 완료된 작업',
              children: [
                _buildTaskItem('UserService 생성 (프로필 조회/생성/업데이트)'),
                _buildTaskItem('역할 선택 화면 구현 (role_selection_screen.dart)'),
                _buildTaskItem('회원가입 플로우 수정 (회원가입 → 역할 선택)'),
                _buildTaskItem('AuthProvider에 프로필 새로고침 메서드 추가'),
                _buildTaskItem('UserModel에 bio 필드 추가'),
                _buildTaskItem('홈 화면에 역할 정보 표시'),
                _buildTaskItem('AuthWrapper에 역할 체크 로직 추가'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 생성된 파일
            _buildSection(
              title: '📊 생성된 파일',
              children: [
                _buildFileItem('lib/features/auth/services/user_service.dart', '사용자 프로필 조회/생성/업데이트 서비스'),
                _buildFileItem('lib/features/auth/screens/role_selection_screen.dart', '역할 선택 화면 (팬/셀럽/매니저)'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 수정된 파일
            _buildSection(
              title: '🔧 수정된 파일',
              children: [
                _buildFileItem('lib/features/auth/models/user_model.dart', 'bio 필드 추가'),
                _buildFileItem('lib/features/auth/providers/auth_provider.dart', 'UserService 통합, 프로필 새로고침 메서드 추가'),
                _buildFileItem('lib/features/auth/screens/signup_screen.dart', '회원가입 성공 시 역할 선택 화면으로 이동'),
                _buildFileItem('lib/main.dart', '역할 선택 라우트 추가, AuthWrapper에 역할 체크 로직 추가, 홈 화면에 역할 정보 표시'),
                _buildFileItem('lib/features/auth/auth.dart', 'UserService 및 RoleSelectionScreen export 추가'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 완료 조건
            _buildSection(
              title: '📝 완료 조건 달성',
              children: [
                _buildCheckItem('회원가입 시 역할 선택 가능', true),
                _buildCheckItem('선택한 역할이 Users 테이블에 저장됨', true),
                _buildCheckItem('로그인 후 현재 사용자 정보 조회 가능', true),
                _buildCheckItem('역할 정보가 앱 전역에서 접근 가능', true),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 테스트 방법
            _buildSection(
              title: '🧪 테스트 방법',
              children: [
                _buildTestStep('1', '회원가입 화면에서 새 계정 생성'),
                _buildTestStep('2', '역할 선택 화면이 자동으로 표시되는지 확인'),
                _buildTestStep('3', '팬/셀럽/매니저 중 하나 선택'),
                _buildTestStep('4', '홈 화면에 선택한 역할이 표시되는지 확인'),
                _buildTestStep('5', '로그아웃 후 다시 로그인하여 프로필이 로드되는지 확인'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 주요 기능
            _buildSection(
              title: '🎯 주요 기능',
              children: [
                _buildFeatureItem(
                  '역할 선택 화면',
                  '회원가입 후 팬/셀럽/매니저 중 하나를 선택할 수 있는 직관적인 UI',
                  Icons.radio_button_checked,
                ),
                _buildFeatureItem(
                  'UserService',
                  '사용자 프로필 조회/생성/업데이트를 중앙화한 서비스 레이어',
                  Icons.build,
                ),
                _buildFeatureItem(
                  '프로필 관리',
                  '회원가입 시 프로필 생성, 역할 변경 시 프로필 업데이트',
                  Icons.person,
                ),
                _buildFeatureItem(
                  '전역 역할 접근',
                  'AuthProvider를 통해 어디서든 사용자 역할 정보 접근 가능',
                  Icons.public,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 다음 단계
            _buildSection(
              title: '🚀 다음 단계',
              children: [
                _buildNextStepItem('WP-1.4: 역할 기반 라우팅 및 Navigation 구현'),
                _buildNextStepItem('Go Router 설정 및 역할별 화면 분기'),
                _buildNextStepItem('공통 Navigation 컴포넌트 구현'),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // 통계
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.h2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }

  Widget _buildTaskItem(String task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              task,
              style: AppTypography.body1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(String path, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file, size: 18, color: Colors.blue),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  path,
                  style: AppTypography.body1.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              description,
              style: AppTypography.body2.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String condition, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.cancel,
            color: completed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              condition,
              style: AppTypography.body1.copyWith(
                decoration: completed ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestStep(String step, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                description,
                style: AppTypography.body1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue[700], size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.body2.copyWith(
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_forward, color: Colors.orange, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              step,
              style: AppTypography.body1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📈 통계',
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildStatRow('생성된 파일', '2개'),
          _buildStatRow('수정된 파일', '5개'),
          _buildStatRow('완료된 작업', '7개'),
          _buildStatRow('완료 조건 달성', '4/4 (100%)'),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body1,
          ),
          Text(
            value,
            style: AppTypography.body1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
