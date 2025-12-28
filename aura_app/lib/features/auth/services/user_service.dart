import '../../../core/supabase_config.dart';
import '../models/user_model.dart';

/// 사용자 프로필 서비스
/// 
/// WP-1.3: 사용자 프로필 및 역할 관리 시스템
/// 
/// Supabase의 users 테이블에서 사용자 정보를 조회/업데이트하는 서비스입니다.
class UserService {
  /// 현재 사용자 프로필 조회
  /// 
  /// Returns: 현재 로그인한 사용자의 프로필 정보
  /// Throws: 사용자 프로필이 없거나 조회 실패 시
  static Future<UserModel?> getCurrentUserProfile() async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        return null;
      }

      final response = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response);
      }

      return null;
    } catch (e) {
      print('⚠️ 사용자 프로필 조회 실패: $e');
      rethrow;
    }
  }

  /// 사용자 프로필 생성 (또는 업데이트)
  /// 
  /// [userId]: 사용자 ID (Supabase Auth의 user ID)
  /// [email]: 이메일 주소
  /// [role]: 사용자 역할 ('fan', 'celebrity', 'manager')
  /// [displayName]: 표시 이름 (필수)
  /// 
  /// 프로필이 이미 존재하면 업데이트하고, 없으면 생성합니다.
  /// Throws: 프로필 생성/업데이트 실패 시
  static Future<void> createUserProfile({
    required String userId,
    required String email,
    required String role,
    required String displayName,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final now = DateTime.now().toIso8601String();

      // upsert 사용: 프로필이 있으면 업데이트, 없으면 생성
      // created_at은 제외하여 기존 레코드의 created_at이 유지되도록 함
      // displayName은 필수이므로 항상 포함
      final profileData = <String, dynamic>{
        'id': userId,
        'email': email,
        'role': role,
        'display_name': displayName.trim(),
        'updated_at': now,
      };
      
      await client.from('users').upsert(
        profileData,
        onConflict: 'id',
      ).select();

      print('✅ 사용자 프로필 생성/업데이트 성공: $userId (role: $role, name: $displayName)');
    } catch (e) {
      print('❌ 사용자 프로필 생성/업데이트 실패: $e');
      rethrow;
    }
  }

  /// 사용자 프로필 업데이트
  /// 
  /// [userId]: 사용자 ID
  /// [displayName]: 표시 이름 (선택)
  /// [avatarUrl]: 프로필 이미지 URL (선택)
  /// [bio]: 자기소개 (선택)
  /// [role]: 역할 (선택, 변경 시 주의 필요)
  /// 
  /// Throws: 프로필 업데이트 실패 시
  static Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? role,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) {
        updateData['display_name'] = displayName;
      }
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }
      if (bio != null) {
        updateData['bio'] = bio;
      }
      if (role != null) {
        updateData['role'] = role;
      }

      await client
          .from('users')
          .update(updateData)
          .eq('id', userId);

      print('✅ 사용자 프로필 업데이트 성공: $userId');
    } catch (e) {
      print('❌ 사용자 프로필 업데이트 실패: $e');
      rethrow;
    }
  }

  /// 사용자 역할 업데이트
  /// 
  /// [userId]: 사용자 ID
  /// [role]: 새로운 역할 ('fan', 'celebrity', 'manager')
  /// 
  /// Throws: 역할 업데이트 실패 시
  static Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    try {
      // 역할 유효성 검증
      if (!['fan', 'celebrity', 'manager'].contains(role)) {
        throw ArgumentError('유효하지 않은 역할입니다: $role');
      }

      await updateUserProfile(userId: userId, role: role);
      print('✅ 사용자 역할 업데이트 성공: $userId -> $role');
    } catch (e) {
      print('❌ 사용자 역할 업데이트 실패: $e');
      rethrow;
    }
  }

  /// 사용자 프로필 존재 여부 확인
  /// 
  /// [userId]: 사용자 ID
  /// 
  /// Returns: 프로필이 존재하면 true, 없으면 false
  static Future<bool> userProfileExists(String userId) async {
    try {
      final client = SupabaseConfig.client;
      final response = await client
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('⚠️ 사용자 프로필 존재 여부 확인 실패: $e');
      return false;
    }
  }

  /// 이메일 중복 확인
  /// 
  /// [email]: 확인할 이메일 주소
  /// 
  /// Returns: 이메일이 이미 등록되어 있으면 true, 없으면 false
  /// 
  /// 주의: 이 메서드는 public.users 테이블만 체크합니다.
  /// auth.users에도 이메일이 있을 수 있으므로, 
  /// signUp 시도 후 에러 처리도 함께 수행해야 합니다.
  static Future<bool> isEmailExists(String email) async {
    try {
      final client = SupabaseConfig.client;
      final trimmedEmail = email.trim().toLowerCase();
      
      print('🔍 이메일 중복 확인 시작: $trimmedEmail');
      
      // public.users 테이블에서 이메일 확인
      final response = await client
          .from('users')
          .select('id')
          .eq('email', trimmedEmail)
          .maybeSingle();

      final exists = response != null;
      print('${exists ? "✅" : "❌"} 이메일 중복 확인 결과: $trimmedEmail -> ${exists ? "존재함" : "없음"}');
      return exists;
    } catch (e, stackTrace) {
      print('⚠️ 이메일 중복 확인 실패: $e');
      print('스택 트레이스: $stackTrace');
      // 에러 발생 시 false 반환 (안전하게 회원가입 시도 허용)
      // 하지만 실제로는 에러를 다시 throw하는 것이 나을 수도 있음
      return false;
    }
  }
}
