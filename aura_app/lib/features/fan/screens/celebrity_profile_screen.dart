import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar.dart' as shared;
import '../../../shared/widgets/custom_button.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/celebrity_service.dart';
import '../services/subscription_service.dart';
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/permission_error_handler.dart';

/// 셀럽 프로필 화면
/// 
/// WP-2.3: 셀럽 프로필 및 구독 시스템
/// 
/// 팬이 셀럽의 프로필을 확인하고 구독/구독취소할 수 있는 화면입니다.
class CelebrityProfileScreen extends StatefulWidget {
  const CelebrityProfileScreen({
    super.key,
    required this.celebrityId,
  });

  final String celebrityId;

  @override
  State<CelebrityProfileScreen> createState() => _CelebrityProfileScreenState();
}

class _CelebrityProfileScreenState extends State<CelebrityProfileScreen> {
  CelebrityWithSubscriberCount? _celebrityData;
  bool _isLoading = true;
  bool _isSubscribed = false;
  bool _isTogglingSubscription = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// 셀럽 프로필 로드
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final celebrityData = await CelebrityService.getCelebrityProfile(
        widget.celebrityId,
      );

      if (celebrityData == null) {
        setState(() {
          _errorMessage = '셀럽을 찾을 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      // 구독 상태 확인
      final isSubscribed = await SubscriptionService.isSubscribed(
        widget.celebrityId,
      );

      setState(() {
        _celebrityData = celebrityData;
        _isSubscribed = isSubscribed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '프로필을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 구독/구독취소 토글
  Future<void> _toggleSubscription() async {
    if (_celebrityData == null || _isTogglingSubscription) return;

    // 권한 체크 (팬만 구독 가능)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    try {
      // canManageSubscription은 subscriptionFanId를 받지만, 
      // 실제로는 현재 사용자의 ID만 확인하면 되므로 user.id를 전달
      if (user != null) {
        PermissionChecker.canManageSubscription(
          user,
          subscriptionFanId: user.id,
        );
      } else {
        PermissionErrorHandler.handleError(
          context,
          const PermissionException('로그인이 필요합니다.'),
        );
        return;
      }
    } on PermissionException catch (e) {
      PermissionErrorHandler.handleError(context, e);
      return;
    } catch (e) {
      // 기타 예외는 무시하고 진행
      print('⚠️ 권한 체크 오류: $e');
    }

    setState(() {
      _isTogglingSubscription = true;
    });

    try {
      // 낙관적 UI 업데이트
      final currentSubscribed = _isSubscribed;
      setState(() {
        _isSubscribed = !currentSubscribed;
        if (_celebrityData != null) {
          _celebrityData = CelebrityWithSubscriberCount(
            celebrity: _celebrityData!.celebrity,
            subscriberCount: currentSubscribed
                ? _celebrityData!.subscriberCount - 1
                : _celebrityData!.subscriberCount + 1,
          );
        }
      });

      // 서버에 요청
      if (currentSubscribed) {
        await SubscriptionService.unsubscribe(widget.celebrityId);
      } else {
        await SubscriptionService.subscribe(widget.celebrityId);
      }

      // 최신 데이터 다시 로드
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentSubscribed ? '구독이 취소되었습니다.' : '구독되었습니다.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 에러 발생 시 원래 상태로 되돌리기
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구독 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingSubscription = false;
        });
      }
    }
  }

  /// 시간 표시 포맷
  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year년 $month월 $day일';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: shared.CustomAppBar(
        title: '셀럽 프로필',
        role: 'fan',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
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
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () => context.go('/fan/home'),
                        child: const Text('홈으로 돌아가기'),
                      ),
                    ],
                  ),
                )
              : _celebrityData == null
                  ? const Center(child: Text('셀럽을 찾을 수 없습니다.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 프로필 섹션
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                children: [
                                  // 프로필 이미지
                                  CircleAvatar(
                                    radius: 48,
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.2),
                                    backgroundImage:
                                        _celebrityData!.celebrity.avatarUrl != null
                                            ? NetworkImage(
                                                _celebrityData!.celebrity.avatarUrl!)
                                            : null,
                                    child:
                                        _celebrityData!.celebrity.avatarUrl == null
                                            ? Icon(
                                                Icons.person,
                                                size: 48,
                                                color: AppColors.primary,
                                              )
                                            : null,
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // 셀럽 이름
                                  Text(
                                    _celebrityData!.celebrity.displayName ??
                                        _celebrityData!.celebrity.email,
                                    style: AppTypography.h4.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),

                                  // 이메일
                                  Text(
                                    _celebrityData!.celebrity.email,
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // 구독자 수
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 20,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        '구독자 ${_celebrityData!.subscriberCount}명',
                                        style: AppTypography.body1.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // 자기소개
                                  if (_celebrityData!.celebrity.bio != null &&
                                      _celebrityData!.celebrity.bio!.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(AppSpacing.radius),
                                      ),
                                      child: Text(
                                        _celebrityData!.celebrity.bio!,
                                        style: AppTypography.body1.copyWith(
                                          color: AppColors.textPrimary,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                  const SizedBox(height: AppSpacing.lg),

                                  // 구독/구독취소 버튼
                                  CustomButton(
                                    label: _isSubscribed ? '구독 취소' : '구독하기',
                                    onPressed:
                                        _isTogglingSubscription ? null : _toggleSubscription,
                                    isLoading: _isTogglingSubscription,
                                    isFullWidth: true,
                                    variant: _isSubscribed
                                        ? ButtonVariant.outlined
                                        : ButtonVariant.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // 가입일 정보
                          Text(
                            '가입일: ${_formatDateTime(_celebrityData!.celebrity.createdAt)}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // 최근 답변 섹션 (미리보기)
                          Text(
                            '최근 답변',
                            style: AppTypography.h5.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.textTertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radius),
                            ),
                            child: Text(
                              '답변 피드는 WP-2.4에서 구현 예정입니다.',
                              style: AppTypography.body2.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

