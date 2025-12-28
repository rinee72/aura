import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/models/user_model.dart';
import '../utils/permission_checker.dart';

/// 권한 기반 위젯 래퍼
/// 
/// WP-1.5: RBAC 구현 및 권한 검증
/// 
/// 권한이 있는 경우에만 자식 위젯을 표시하고, 권한이 없으면 대체 위젯을 표시합니다.
class PermissionWrapper extends StatelessWidget {
  /// 자식 위젯 (권한이 있을 때 표시)
  final Widget child;

  /// 권한이 없을 때 표시할 위젯 (선택사항)
  final Widget? fallback;

  /// 권한이 없을 때 숨길지 여부 (true면 아무것도 표시하지 않음)
  final bool hideWhenNoPermission;

  /// 권한 체크 함수
  final bool Function(UserModel?) permissionCheck;

  const PermissionWrapper({
    super.key,
    required this.child,
    required this.permissionCheck,
    this.fallback,
    this.hideWhenNoPermission = false,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    final hasPermission = permissionCheck(user);

    if (!hasPermission) {
      if (hideWhenNoPermission) {
        return const SizedBox.shrink();
      }
      if (fallback != null) {
        return fallback!;
      }
      return const SizedBox.shrink();
    }

    return child;
  }
}

/// 역할 기반 위젯 래퍼
/// 
/// 특정 역할을 가진 사용자에게만 위젯을 표시합니다.
class RoleWrapper extends StatelessWidget {
  /// 자식 위젯
  final Widget child;

  /// 허용된 역할
  final String role;

  /// 권한이 없을 때 표시할 위젯 (선택사항)
  final Widget? fallback;

  /// 권한이 없을 때 숨길지 여부
  final bool hideWhenNoPermission;

  const RoleWrapper({
    super.key,
    required this.child,
    required this.role,
    this.fallback,
    this.hideWhenNoPermission = false,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWrapper(
      permissionCheck: (user) => PermissionChecker.hasRole(user, role),
      fallback: fallback,
      hideWhenNoPermission: hideWhenNoPermission,
      child: child,
    );
  }
}

/// 역할 목록 기반 위젯 래퍼
/// 
/// 여러 역할 중 하나를 가진 사용자에게만 위젯을 표시합니다.
class AnyRoleWrapper extends StatelessWidget {
  /// 자식 위젯
  final Widget child;

  /// 허용된 역할 목록
  final List<String> roles;

  /// 권한이 없을 때 표시할 위젯 (선택사항)
  final Widget? fallback;

  /// 권한이 없을 때 숨길지 여부
  final bool hideWhenNoPermission;

  const AnyRoleWrapper({
    super.key,
    required this.child,
    required this.roles,
    this.fallback,
    this.hideWhenNoPermission = false,
  });

  @override
  Widget build(BuildContext context) {
    return PermissionWrapper(
      permissionCheck: (user) => PermissionChecker.hasAnyRole(user, roles),
      fallback: fallback,
      hideWhenNoPermission: hideWhenNoPermission,
      child: child,
    );
  }
}

/// 권한 기반 버튼 위젯
/// 
/// 권한이 있을 때만 활성화되고, 권한이 없으면 비활성화됩니다.
class PermissionButton extends StatelessWidget {
  /// 버튼 텍스트
  final String text;

  /// 버튼 클릭 시 실행할 함수
  final VoidCallback? onPressed;

  /// 권한 체크 함수
  final bool Function(UserModel?) permissionCheck;

  /// 권한이 없을 때 표시할 툴팁
  final String? noPermissionTooltip;

  /// 버튼 스타일
  final ButtonStyle? style;

  const PermissionButton({
    super.key,
    required this.text,
    required this.permissionCheck,
    this.onPressed,
    this.noPermissionTooltip,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    final hasPermission = permissionCheck(user);
    final bool isEnabled = hasPermission && onPressed != null;

    Widget button = ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: style,
      child: Text(text),
    );

    if (!hasPermission && noPermissionTooltip != null) {
      return Tooltip(
        message: noPermissionTooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// 권한 기반 아이콘 버튼 위젯
/// 
/// 권한이 있을 때만 활성화되고, 권한이 없으면 비활성화됩니다.
class PermissionIconButton extends StatelessWidget {
  /// 아이콘
  final IconData icon;

  /// 버튼 클릭 시 실행할 함수
  final VoidCallback? onPressed;

  /// 권한 체크 함수
  final bool Function(UserModel?) permissionCheck;

  /// 권한이 없을 때 표시할 툴팁
  final String? noPermissionTooltip;

  /// 아이콘 크기
  final double? iconSize;

  /// 색상
  final Color? color;

  const PermissionIconButton({
    super.key,
    required this.icon,
    required this.permissionCheck,
    this.onPressed,
    this.noPermissionTooltip,
    this.iconSize,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    final hasPermission = permissionCheck(user);
    final bool isEnabled = hasPermission && onPressed != null;

    Widget button = IconButton(
      icon: Icon(icon, size: iconSize, color: color),
      onPressed: isEnabled ? onPressed : null,
    );

    if (!hasPermission && noPermissionTooltip != null) {
      return Tooltip(
        message: noPermissionTooltip!,
        child: button,
      );
    }

    return button;
  }
}

