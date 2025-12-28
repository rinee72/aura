import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'permission_checker.dart';
import '../../features/auth/models/user_model.dart';

/// 권한 에러 처리 유틸리티
/// 
/// WP-1.5: RBAC 구현 및 권한 검증
/// 
/// 권한 에러를 처리하고 사용자를 적절한 화면으로 리다이렉트하거나 에러 메시지를 표시합니다.
class PermissionErrorHandler {
  PermissionErrorHandler._(); // 인스턴스 생성 방지

  /// 권한 에러를 처리하고 에러 메시지를 표시
  /// 
  /// [context]: BuildContext
  /// [error]: 발생한 PermissionException
  /// 
  /// Returns: 에러가 처리되었으면 true
  static bool handleError(BuildContext context, PermissionException error) {
    // 스낵바로 에러 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    return true;
  }

  /// 권한 체크를 실행하고 에러 발생 시 처리
  /// 
  /// [context]: BuildContext
  /// [user]: 현재 사용자
  /// [checkFunction]: 권한 체크 함수 (예외를 발생시킬 수 있음)
  /// [onSuccess]: 권한이 있을 때 실행할 함수
  /// [onError]: 권한이 없을 때 실행할 함수 (선택사항, 기본값은 에러 메시지 표시)
  /// 
  /// Returns: 권한 체크가 성공했으면 true
  static bool checkAndHandle(
    BuildContext context,
    UserModel? user,
    bool Function() checkFunction, {
    VoidCallback? onSuccess,
    void Function(PermissionException)? onError,
  }) {
    try {
      checkFunction();
      onSuccess?.call();
      return true;
    } on PermissionException catch (e) {
      if (onError != null) {
        onError(e);
      } else {
        handleError(context, e);
      }
      return false;
    } catch (e) {
      // 예상치 못한 에러
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
  }

  /// 권한이 없을 때 적절한 화면으로 리다이렉트
  /// 
  /// [context]: BuildContext
  /// [user]: 현재 사용자
  /// [requiredRole]: 필요한 역할
  static void redirectIfNoPermission(
    BuildContext context,
    UserModel? user,
    String? requiredRole,
  ) {
    if (user == null) {
      // 미인증 사용자는 로그인 화면으로
      context.go('/login');
      return;
    }

    // 역할이 없거나 필요한 역할이 아니면 역할별 홈으로 리다이렉트
    if (user.role != null) {
      switch (user.role) {
        case PermissionChecker.roleFan:
          context.go('/fan/home');
          break;
        case PermissionChecker.roleCelebrity:
          context.go('/celebrity/dashboard');
          break;
        case PermissionChecker.roleManager:
          context.go('/manager/dashboard');
          break;
        default:
          context.go('/role-selection');
      }
    } else {
      context.go('/role-selection');
    }
  }

  /// 권한 에러 다이얼로그 표시
  /// 
  /// [context]: BuildContext
  /// [error]: 발생한 PermissionException
  static Future<void> showErrorDialog(
    BuildContext context,
    PermissionException error,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('권한 없음'),
          content: Text(error.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  /// 권한 체크를 실행하고 실패 시 다이얼로그 표시
  /// 
  /// [context]: BuildContext
  /// [user]: 현재 사용자
  /// [checkFunction]: 권한 체크 함수
  /// [onSuccess]: 권한이 있을 때 실행할 함수
  /// 
  /// Returns: 권한 체크가 성공했으면 true
  static Future<bool> checkWithDialog(
    BuildContext context,
    UserModel? user,
    bool Function() checkFunction, {
    VoidCallback? onSuccess,
  }) async {
    try {
      checkFunction();
      onSuccess?.call();
      return true;
    } on PermissionException catch (e) {
      await showErrorDialog(context, e);
      return false;
    } catch (e) {
      await showErrorDialog(
        context,
        PermissionException('오류가 발생했습니다: $e'),
      );
      return false;
    }
  }
}

