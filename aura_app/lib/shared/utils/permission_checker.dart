import '../../features/auth/models/user_model.dart';

/// 권한 관련 예외 클래스
/// 
/// WP-1.5: RBAC 구현 및 권한 검증
class PermissionException implements Exception {
  final String message;
  final String? requiredRole;
  final String? currentRole;

  const PermissionException(
    this.message, {
    this.requiredRole,
    this.currentRole,
  });

  @override
  String toString() => message;
}

/// 권한 체크 유틸리티
/// 
/// WP-1.5: RBAC 구현 및 권한 검증
/// 
/// 클라이언트 측에서 권한을 체크하여 안전한 접근 제어를 구현합니다.
/// 주의: 이 클래스는 클라이언트 측 검증일 뿐이며, 실제 보안은 서버 측 RLS 정책에 의존합니다.
class PermissionChecker {
  PermissionChecker._(); // 인스턴스 생성 방지

  /// 역할 정의
  static const String roleFan = 'fan';
  static const String roleCelebrity = 'celebrity';
  static const String roleManager = 'manager';

  /// 사용자가 특정 역할을 가지고 있는지 확인
  /// 
  /// [user]: 현재 사용자 (null이면 미인증)
  /// [requiredRole]: 필요한 역할 ('fan', 'celebrity', 'manager')
  /// 
  /// Returns: 권한이 있으면 true
  /// Throws: [PermissionException] 권한이 없을 때
  static bool requireRole(UserModel? user, String requiredRole) {
    if (user == null) {
      throw const PermissionException(
        '로그인이 필요합니다.',
      );
    }

    if (user.role != requiredRole) {
      throw PermissionException(
        '이 기능은 $requiredRole 역할만 사용할 수 있습니다. '
        '현재 역할: ${user.role ?? "없음"}',
        requiredRole: requiredRole,
        currentRole: user.role,
      );
    }

    return true;
  }

  /// 사용자가 특정 역할 중 하나를 가지고 있는지 확인
  /// 
  /// [user]: 현재 사용자 (null이면 미인증)
  /// [allowedRoles]: 허용된 역할 목록
  /// 
  /// Returns: 권한이 있으면 true
  /// Throws: [PermissionException] 권한이 없을 때
  static bool requireAnyRole(UserModel? user, List<String> allowedRoles) {
    if (user == null) {
      throw const PermissionException(
        '로그인이 필요합니다.',
      );
    }

    if (user.role == null || !allowedRoles.contains(user.role)) {
      throw PermissionException(
        '이 기능은 ${allowedRoles.join(" 또는 ")} 역할만 사용할 수 있습니다. '
        '현재 역할: ${user.role ?? "없음"}',
        currentRole: user.role,
      );
    }

    return true;
  }

  /// 사용자가 인증되었는지 확인
  /// 
  /// [user]: 현재 사용자
  /// 
  /// Returns: 인증되었으면 true
  /// Throws: [PermissionException] 미인증일 때
  static bool requireAuthenticated(UserModel? user) {
    if (user == null) {
      throw const PermissionException(
        '로그인이 필요합니다.',
      );
    }
    return true;
  }

  /// 팬이 자신의 리소스에 접근할 수 있는지 확인
  /// 
  /// [user]: 현재 사용자
  /// [resourceUserId]: 리소스 소유자의 ID
  /// 
  /// Returns: 권한이 있으면 true
  /// Throws: [PermissionException] 권한이 없을 때
  static bool requireOwnResource(UserModel? user, String resourceUserId) {
    requireAuthenticated(user);

    // 매니저는 모든 리소스에 접근 가능
    if (user!.role == roleManager) {
      return true;
    }

    // 소유자만 접근 가능
    if (user.id != resourceUserId) {
      throw PermissionException(
        '이 리소스에 접근할 권한이 없습니다.',
      );
    }

    return true;
  }

  // ============================================
  // 역할별 권한 체크 함수
  // ============================================

  /// 팬이 질문을 수정할 수 있는지 확인
  /// 
  /// RLS 정책: 팬은 자신의 질문만 수정 가능
  /// 
  /// [user]: 현재 사용자
  /// [questionUserId]: 질문 작성자의 ID
  /// 
  /// Returns: 권한이 있으면 true
  /// Throws: [PermissionException] 권한이 없을 때
  static bool canUpdateQuestion(UserModel? user, String questionUserId) {
    requireAuthenticated(user);

    // 매니저는 모든 질문 수정 가능 (숨김 처리 등)
    if (user!.role == roleManager) {
      return true;
    }

    // 팬만 질문 수정 가능하고, 자신의 질문만 수정 가능
    if (user.role != roleFan) {
      throw PermissionException(
        '질문 수정은 팬만 가능합니다.',
        requiredRole: roleFan,
        currentRole: user.role,
      );
    }

    if (user.id != questionUserId) {
      throw PermissionException(
        '자신의 질문만 수정할 수 있습니다.',
      );
    }

    return true;
  }

  /// 셀럽이 질문을 조회할 수 있는지 확인
  /// 
  /// RLS 정책: 셀럽은 숨김되지 않은 질문만 조회 가능 (수정 불가)
  /// 
  /// [user]: 현재 사용자
  /// [isHidden]: 질문이 숨김 처리되었는지 여부
  /// 
  /// Returns: 권한이 있으면 true
  /// Throws: [PermissionException] 권한이 없을 때
  static bool canViewQuestion(UserModel? user, {required bool isHidden}) {
    requireAuthenticated(user);

    // 매니저는 모든 질문 조회 가능
    if (user!.role == roleManager) {
      return true;
    }

    // 셀럽은 숨김되지 않은 질문만 조회 가능
    if (user.role == roleCelebrity && isHidden) {
      throw PermissionException(
        '숨김 처리된 질문은 조회할 수 없습니다.',
      );
    }

    // 팬은 자신의 질문과 공개된 질문 조회 가능 (RLS에서 처리)
    if (user.role == roleFan) {
      return true;
    }

    // 셀럽은 조회 가능
    if (user.role == roleCelebrity) {
      return true;
    }

    return true;
  }

  /// 질문을 조회할 수 있는지 확인 (일반)
  /// 
  /// [user]: 현재 사용자
  /// [isHidden]: 질문이 숨김 처리되었는지 여부
  /// [questionUserId]: 질문 작성자의 ID (팬의 경우 자신의 질문은 항상 조회 가능)
  /// 
  /// Returns: 권한이 있으면 true
  static bool canViewQuestionGeneral(
    UserModel? user, {
    required bool isHidden,
    String? questionUserId,
  }) {
    if (user == null) {
      return false;
    }

    // 매니저는 모든 질문 조회 가능
    if (user.role == roleManager) {
      return true;
    }

    // 팬은 자신의 질문과 공개된 질문 조회 가능
    if (user.role == roleFan) {
      if (questionUserId != null && user.id == questionUserId) {
        return true; // 자신의 질문은 항상 조회 가능
      }
      return !isHidden; // 공개된 질문만 조회 가능
    }

    // 셀럽은 숨김되지 않은 질문만 조회 가능
    if (user.role == roleCelebrity) {
      return !isHidden;
    }

    return false;
  }

  /// 질문을 작성할 수 있는지 확인
  /// 
  /// RLS 정책: 팬만 질문 작성 가능
  /// 
  /// [user]: 현재 사용자
  /// 
  /// Returns: 권한이 있으면 true
  /// Throws: [PermissionException] 권한이 없을 때
  static bool canCreateQuestion(UserModel? user) {
    requireRole(user, roleFan);
    return true;
  }

  /// 답변을 작성/수정할 수 있는지 확인
  /// 
  /// RLS 정책: 셀럽만 답변 작성/수정 가능, 자신의 답변만 수정 가능
  /// 
  /// [user]: 현재 사용자
  /// [answerCelebrityId]: 답변 작성자의 ID (수정 시)
  /// 
  /// Returns: 권한이 있으면 true
  /// Throws: [PermissionException] 권한이 없을 때
  static bool canManageAnswer(
    UserModel? user, {
    String? answerCelebrityId,
  }) {
    requireAuthenticated(user);

    // 셀럽만 답변 관리 가능
    if (user!.role != roleCelebrity) {
      throw PermissionException(
        '답변 작성/수정은 셀럽만 가능합니다.',
        requiredRole: roleCelebrity,
        currentRole: user.role,
      );
    }

    // 수정 시 자신의 답변만 수정 가능
    if (answerCelebrityId != null && user.id != answerCelebrityId) {
      throw PermissionException(
        '자신의 답변만 수정할 수 있습니다.',
      );
    }

    return true;
  }

  /// 구독을 관리할 수 있는지 확인
  /// 
  /// RLS 정책: 팬만 구독 관리 가능, 자신의 구독만 관리 가능
  /// 
  /// [user]: 현재 사용자
  /// [subscriptionFanId]: 구독한 팬의 ID
  /// 
  /// Returns: 권한이 있으면 true
  /// Throws: [PermissionException] 권한이 없을 때
  static bool canManageSubscription(
    UserModel? user, {
    required String subscriptionFanId,
  }) {
    requireAuthenticated(user);

    // 팬만 구독 관리 가능
    if (user!.role != roleFan) {
      throw PermissionException(
        '구독 관리는 팬만 가능합니다.',
        requiredRole: roleFan,
        currentRole: user.role,
      );
    }

    // 자신의 구독만 관리 가능
    if (user.id != subscriptionFanId) {
      throw PermissionException(
        '자신의 구독만 관리할 수 있습니다.',
      );
    }

    return true;
  }

  /// 커뮤니티 게시글을 관리할 수 있는지 확인
  /// 
  /// RLS 정책: 팬만 게시글 작성/수정/삭제 가능, 자신의 게시글만 수정 가능
  /// 
  /// [user]: 현재 사용자
  /// [postUserId]: 게시글 작성자의 ID
  /// 
  /// Returns: 권한이 있으면 true
  /// Throws: [PermissionException] 권한이 없을 때
  static bool canManageCommunityPost(
    UserModel? user, {
    required String postUserId,
  }) {
    requireAuthenticated(user);

    // 매니저는 모든 게시글 관리 가능
    if (user!.role == roleManager) {
      return true;
    }

    // 팬만 게시글 관리 가능
    if (user.role != roleFan) {
      throw PermissionException(
        '커뮤니티 게시글 관리는 팬만 가능합니다.',
        requiredRole: roleFan,
        currentRole: user.role,
      );
    }

    // 자신의 게시글만 수정 가능
    if (user.id != postUserId) {
      throw PermissionException(
        '자신의 게시글만 수정할 수 있습니다.',
      );
    }

    return true;
  }

  /// 질문을 숨김 처리할 수 있는지 확인
  /// 
  /// RLS 정책: 매니저만 질문 숨김 처리 가능
  /// 
  /// [user]: 현재 사용자
  /// 
  /// Returns: 권한이 있으면 true
  /// Throws: [PermissionException] 권한이 없을 때
  static bool canHideQuestion(UserModel? user) {
    requireRole(user, roleManager);
    return true;
  }

  /// 모든 사용자 프로필을 조회할 수 있는지 확인
  /// 
  /// RLS 정책: 매니저만 모든 프로필 조회 가능
  /// 
  /// [user]: 현재 사용자
  /// 
  /// Returns: 권한이 있으면 true
  /// Throws: [PermissionException] 권한이 없을 때
  static bool canViewAllProfiles(UserModel? user) {
    requireRole(user, roleManager);
    return true;
  }

  // ============================================
  // 권한 확인 헬퍼 함수 (예외 발생하지 않음)
  // ============================================

  /// 역할을 가지고 있는지 확인 (예외 발생하지 않음)
  /// 
  /// [user]: 현재 사용자
  /// [role]: 확인할 역할
  /// 
  /// Returns: 권한이 있으면 true
  static bool hasRole(UserModel? user, String role) {
    return user?.role == role;
  }

  /// 역할 중 하나를 가지고 있는지 확인 (예외 발생하지 않음)
  /// 
  /// [user]: 현재 사용자
  /// [roles]: 확인할 역할 목록
  /// 
  /// Returns: 권한이 있으면 true
  static bool hasAnyRole(UserModel? user, List<String> roles) {
    if (user?.role == null) return false;
    return roles.contains(user!.role);
  }

  /// 인증되었는지 확인 (예외 발생하지 않음)
  /// 
  /// [user]: 현재 사용자
  /// 
  /// Returns: 인증되었으면 true
  static bool isAuthenticated(UserModel? user) {
    return user != null;
  }

  /// 자신의 리소스인지 확인 (예외 발생하지 않음)
  /// 
  /// [user]: 현재 사용자
  /// [resourceUserId]: 리소스 소유자의 ID
  /// 
  /// Returns: 자신의 리소스이거나 매니저이면 true
  static bool isOwnResource(UserModel? user, String resourceUserId) {
    if (user == null) return false;
    if (user.role == roleManager) return true;
    return user.id == resourceUserId;
  }
}

