import '../../../core/supabase_config.dart';
import '../../auth/models/user_model.dart';
import '../models/manager_celebrity_assignment_model.dart';
import '../../../shared/utils/permission_checker.dart';

/// 매니저 담당 관계 서비스
/// 
/// WP-4.2 확장: 매니저-셀럽 관계 명시적 관리
/// 
/// 매니저가 담당하는 셀럽을 조회하고 관리하는 서비스입니다.
class ManagerAssignmentService {
  /// 현재 매니저가 담당하는 셀럽 목록 조회
  /// 
  /// Returns: 담당 셀럽 목록 (셀럽 정보 포함)
  /// Throws: 권한 없음, 조회 실패 시
  static Future<List<Map<String, dynamic>>> getMyAssignedCelebrities() async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 담당 셀럽 조회 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('담당 셀럽 조회는 매니저만 가능합니다.');
      }

      // 담당 관계 조회 (셀럽 정보 포함)
      final assignmentsResponse = await client
          .from('manager_celebrity_assignments')
          .select('''
            *,
            celebrity:celebrity_id (
              id,
              email,
              display_name,
              avatar_url,
              bio,
              created_at,
              updated_at
            )
          ''')
          .eq('manager_id', currentUser.id)
          .order('assigned_at', ascending: false);

      final assignments = (assignmentsResponse as List).map((item) {
        final assignmentData = item as Map<String, dynamic>;
        final assignment = ManagerCelebrityAssignmentModel.fromJson(
          Map<String, dynamic>.from(assignmentData)
            ..remove('celebrity'),
        );
        
        final celebrityData = assignmentData['celebrity'] as Map<String, dynamic>?;
        final celebrity = celebrityData != null
            ? UserModel.fromJson(celebrityData)
            : null;

        return {
          'assignment': assignment,
          'celebrity': celebrity,
        };
      }).toList();

      print('✅ 담당 셀럽 조회 성공: ${assignments.length}개');
      return assignments;
    } catch (e) {
      print('❌ 담당 셀럽 조회 실패: $e');
      rethrow;
    }
  }

  /// 특정 셀럽의 담당 매니저 조회
  /// 
  /// [celebrityId]: 셀럽 ID
  /// 
  /// Returns: 담당 매니저 목록 (매니저 정보 포함)
  /// Throws: 권한 없음, 조회 실패 시
  static Future<List<Map<String, dynamic>>> getCelebrityManagers(
    String celebrityId,
  ) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 담당 관계 조회 (매니저 정보 포함)
      final assignmentsResponse = await client
          .from('manager_celebrity_assignments')
          .select('''
            *,
            manager:manager_id (
              id,
              email,
              display_name,
              avatar_url,
              bio,
              created_at,
              updated_at
            )
          ''')
          .eq('celebrity_id', celebrityId)
          .order('assigned_at', ascending: false);

      final assignments = (assignmentsResponse as List).map((item) {
        final assignmentData = item as Map<String, dynamic>;
        final assignment = ManagerCelebrityAssignmentModel.fromJson(
          Map<String, dynamic>.from(assignmentData)
            ..remove('manager'),
        );
        
        final managerData = assignmentData['manager'] as Map<String, dynamic>?;
        final manager = managerData != null
            ? UserModel.fromJson(managerData)
            : null;

        return {
          'assignment': assignment,
          'manager': manager,
        };
      }).toList();

      print('✅ 셀럽 담당 매니저 조회 성공: ${celebrityId} - ${assignments.length}개');
      return assignments;
    } catch (e) {
      print('❌ 셀럽 담당 매니저 조회 실패: $e');
      rethrow;
    }
  }

  /// 담당 셀럽 할당 (매니저에게 셀럽 할당)
  /// 
  /// [managerId]: 매니저 ID
  /// [celebrityId]: 셀럽 ID
  /// [notes]: 할당 관련 메모 (선택)
  /// 
  /// Returns: 생성된 담당 관계
  /// Throws: 권한 없음, 할당 실패 시
  static Future<ManagerCelebrityAssignmentModel> assignCelebrity({
    required String managerId,
    required String celebrityId,
    String? notes,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 할당 가능 (자신에게 할당하거나, 다른 매니저에게 할당)
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('셀럽 할당은 매니저만 가능합니다.');
      }

      // 이미 할당되어 있는지 확인
      final existingResponse = await client
          .from('manager_celebrity_assignments')
          .select()
          .eq('manager_id', managerId)
          .eq('celebrity_id', celebrityId)
          .maybeSingle();

      if (existingResponse != null) {
        throw Exception('이미 할당된 셀럽입니다.');
      }

      // 담당 관계 생성
      final insertData = <String, dynamic>{
        'manager_id': managerId,
        'celebrity_id': celebrityId,
        'assigned_by': currentUser.id,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      final response = await client
          .from('manager_celebrity_assignments')
          .insert(insertData)
          .select()
          .single();

      final assignment = ManagerCelebrityAssignmentModel.fromJson(response);
      print('✅ 셀럽 할당 성공: $managerId -> $celebrityId');
      return assignment;
    } catch (e) {
      print('❌ 셀럽 할당 실패: $e');
      rethrow;
    }
  }

  /// 담당 셀럽 해제 (매니저의 셀럽 담당 해제)
  /// 
  /// [assignmentId]: 담당 관계 ID
  /// 
  /// Returns: 해제 성공 여부
  /// Throws: 권한 없음, 해제 실패 시
  static Future<bool> unassignCelebrity(String assignmentId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 해제 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('담당 해제는 매니저만 가능합니다.');
      }

      // 담당 관계 삭제
      await client
          .from('manager_celebrity_assignments')
          .delete()
          .eq('id', assignmentId)
          .eq('manager_id', currentUser.id); // 자신의 담당만 해제 가능

      print('✅ 담당 해제 성공: $assignmentId');
      return true;
    } catch (e) {
      print('❌ 담당 해제 실패: $e');
      rethrow;
    }
  }

  /// 현재 매니저가 특정 셀럽을 담당하는지 확인
  /// 
  /// [celebrityId]: 셀럽 ID
  /// 
  /// Returns: 담당 중이면 true, 아니면 false
  static Future<bool> isAssignedToCelebrity(String celebrityId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        return false;
      }

      final response = await client
          .from('manager_celebrity_assignments')
          .select('id')
          .eq('manager_id', currentUser.id)
          .eq('celebrity_id', celebrityId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('⚠️ 담당 여부 확인 실패: $e');
      return false;
    }
  }

  /// 모든 매니저 목록 조회
  /// 
  /// Returns: 매니저 목록
  /// Throws: 권한 없음, 조회 실패 시
  static Future<List<UserModel>> getAllManagers() async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 매니저 목록 조회 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('매니저 목록 조회는 매니저만 가능합니다.');
      }

      // 매니저 목록 조회
      final managersResponse = await client
          .from('users')
          .select()
          .eq('role', 'manager')
          .order('created_at', ascending: false);

      final managers = (managersResponse as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ 매니저 목록 조회 성공: ${managers.length}개');
      return managers;
    } catch (e) {
      print('❌ 매니저 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 모든 셀럽 목록 조회
  /// 
  /// Returns: 셀럽 목록
  /// Throws: 권한 없음, 조회 실패 시
  static Future<List<UserModel>> getAllCelebrities() async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 셀럽 목록 조회 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('셀럽 목록 조회는 매니저만 가능합니다.');
      }

      // 셀럽 목록 조회
      final celebritiesResponse = await client
          .from('users')
          .select()
          .eq('role', 'celebrity')
          .order('created_at', ascending: false);

      final celebrities = (celebritiesResponse as List)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ 셀럽 목록 조회 성공: ${celebrities.length}개');
      return celebrities;
    } catch (e) {
      print('❌ 셀럽 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 모든 할당 관계 조회 (관리자용)
  /// 
  /// Returns: 모든 할당 관계 목록 (매니저 및 셀럽 정보 포함)
  /// Throws: 권한 없음, 조회 실패 시
  static Future<List<Map<String, dynamic>>> getAllAssignments() async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 모든 할당 관계 조회 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('할당 관계 조회는 매니저만 가능합니다.');
      }

      // 모든 할당 관계 조회 (매니저 및 셀럽 정보 포함)
      final assignmentsResponse = await client
          .from('manager_celebrity_assignments')
          .select('''
            *,
            manager:manager_id (
              id,
              email,
              display_name,
              avatar_url,
              bio,
              created_at,
              updated_at
            ),
            celebrity:celebrity_id (
              id,
              email,
              display_name,
              avatar_url,
              bio,
              created_at,
              updated_at
            )
          ''')
          .order('assigned_at', ascending: false);

      final assignments = (assignmentsResponse as List).map((item) {
        final assignmentData = item as Map<String, dynamic>;
        final assignment = ManagerCelebrityAssignmentModel.fromJson(
          Map<String, dynamic>.from(assignmentData)
            ..remove('manager')
            ..remove('celebrity'),
        );
        
        final managerData = assignmentData['manager'] as Map<String, dynamic>?;
        final manager = managerData != null
            ? UserModel.fromJson(managerData)
            : null;

        final celebrityData = assignmentData['celebrity'] as Map<String, dynamic>?;
        final celebrity = celebrityData != null
            ? UserModel.fromJson(celebrityData)
            : null;

        return {
          'assignment': assignment,
          'manager': manager,
          'celebrity': celebrity,
        };
      }).toList();

      print('✅ 모든 할당 관계 조회 성공: ${assignments.length}개');
      return assignments;
    } catch (e) {
      print('❌ 할당 관계 조회 실패: $e');
      rethrow;
    }
  }

  /// 담당 관계 삭제 (관리자용 - 다른 매니저의 담당도 삭제 가능)
  /// 
  /// [assignmentId]: 담당 관계 ID
  /// 
  /// Returns: 삭제 성공 여부
  /// Throws: 권한 없음, 삭제 실패 시
  static Future<bool> deleteAssignment(String assignmentId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자 정보 조회
      final userResponse = await client
          .from('users')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('사용자 정보를 찾을 수 없습니다.');
      }

      final user = UserModel.fromJson(userResponse);

      // 권한 검증: 매니저만 삭제 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('담당 관계 삭제는 매니저만 가능합니다.');
      }

      // 담당 관계 삭제
      await client
          .from('manager_celebrity_assignments')
          .delete()
          .eq('id', assignmentId);

      print('✅ 담당 관계 삭제 성공: $assignmentId');
      return true;
    } catch (e) {
      print('❌ 담당 관계 삭제 실패: $e');
      rethrow;
    }
  }
}

