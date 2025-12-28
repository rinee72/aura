import '../../../core/supabase_config.dart';
import '../../fan/models/question_model.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/utils/permission_checker.dart';
import 'question_monitoring_service.dart';

/// 질문 관리 서비스
/// 
/// WP-4.2: 질문 관리 기능 (숨기기/복구)
/// 
/// 매니저가 질문을 숨기고 복구할 수 있는 서비스입니다.
class QuestionManagementService {
  /// 질문 숨기기
  /// 
  /// [questionId]: 숨길 질문 ID
  /// [reason]: 숨김 사유 (필수)
  /// 
  /// Returns: 숨김 처리된 질문
  /// Throws: 권한 없음, 질문 숨기기 실패 시
  static Future<QuestionModel> hideQuestion({
    required String questionId,
    required String reason,
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

      // 권한 검증: 매니저만 질문 숨기기 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('질문 숨기기는 매니저만 가능합니다.');
      }

      // 숨김 사유 검증
      if (reason.trim().isEmpty) {
        throw Exception('숨김 사유를 입력해주세요.');
      }

      // 질문 존재 여부 확인
      final questionResponse = await client
          .from('questions')
          .select()
          .eq('id', questionId)
          .maybeSingle();

      if (questionResponse == null) {
        throw Exception('질문을 찾을 수 없습니다.');
      }

      // 이미 숨김 처리된 경우 확인
      final isAlreadyHidden = (questionResponse['is_hidden'] as bool?) ?? false;
      if (isAlreadyHidden) {
        throw Exception('이미 숨김 처리된 질문입니다.');
      }

      // 질문 숨기기
      final now = DateTime.now();
      final updateData = <String, dynamic>{
        'is_hidden': true,
        'hidden_reason': reason.trim(),
        'hidden_at': now.toIso8601String(),
        'hidden_by': user.id,
      };

      final response = await client
          .from('questions')
          .update(updateData)
          .eq('id', questionId)
          .select()
          .single();

      final question = QuestionModel.fromJson(response);
      print('✅ 질문 숨기기 성공: $questionId');
      return question;
    } catch (e) {
      print('❌ 질문 숨기기 실패: $e');
      rethrow;
    }
  }

  /// 질문 복구
  /// 
  /// [questionId]: 복구할 질문 ID
  /// 
  /// Returns: 복구된 질문
  /// Throws: 권한 없음, 질문 복구 실패 시
  static Future<QuestionModel> unhideQuestion(String questionId) async {
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

      // 권한 검증: 매니저만 질문 복구 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('질문 복구는 매니저만 가능합니다.');
      }

      // 질문 존재 여부 및 숨김 상태 확인
      final questionResponse = await client
          .from('questions')
          .select()
          .eq('id', questionId)
          .maybeSingle();

      if (questionResponse == null) {
        throw Exception('질문을 찾을 수 없습니다.');
      }

      final isHidden = (questionResponse['is_hidden'] as bool?) ?? false;
      if (!isHidden) {
        throw Exception('숨김 처리되지 않은 질문입니다.');
      }

      // 질문 복구 (숨김 정보 초기화)
      final updateData = <String, dynamic>{
        'is_hidden': false,
        'hidden_reason': null,
        'hidden_at': null,
        'hidden_by': null,
      };

      final response = await client
          .from('questions')
          .update(updateData)
          .eq('id', questionId)
          .select()
          .single();

      final question = QuestionModel.fromJson(response);
      print('✅ 질문 복구 성공: $questionId');
      return question;
    } catch (e) {
      print('❌ 질문 복구 실패: $e');
      rethrow;
    }
  }

  /// 숨김 처리된 질문 목록 조회
  /// 
  /// [limit]: 조회할 질문 수 (기본값: 50)
  /// [offset]: 시작 위치 (기본값: 0)
  /// 
  /// Returns: 숨김 처리된 질문 목록 (작성자 정보 포함)
  /// Throws: 권한 없음, 질문 조회 실패 시
  static Future<List<Map<String, dynamic>>> getHiddenQuestions({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // QuestionMonitoringService의 getHiddenQuestions 사용
      return await QuestionMonitoringService.getHiddenQuestions(
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print('❌ 숨김 질문 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 숨김 사유 수정
  /// 
  /// [questionId]: 질문 ID
  /// [reason]: 새로운 숨김 사유 (필수)
  /// 
  /// Returns: 수정된 질문
  /// Throws: 권한 없음, 질문 수정 실패 시
  static Future<QuestionModel> updateHiddenReason({
    required String questionId,
    required String reason,
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

      // 권한 검증: 매니저만 숨김 사유 수정 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('숨김 사유 수정은 매니저만 가능합니다.');
      }

      // 숨김 사유 검증
      if (reason.trim().isEmpty) {
        throw Exception('숨김 사유를 입력해주세요.');
      }

      // 질문 존재 여부 및 숨김 상태 확인
      final questionResponse = await client
          .from('questions')
          .select()
          .eq('id', questionId)
          .maybeSingle();

      if (questionResponse == null) {
        throw Exception('질문을 찾을 수 없습니다.');
      }

      final isHidden = (questionResponse['is_hidden'] as bool?) ?? false;
      if (!isHidden) {
        throw Exception('숨김 처리되지 않은 질문입니다.');
      }

      // 숨김 사유 수정
      final updateData = <String, dynamic>{
        'hidden_reason': reason.trim(),
      };

      final response = await client
          .from('questions')
          .update(updateData)
          .eq('id', questionId)
          .select()
          .single();

      final question = QuestionModel.fromJson(response);
      print('✅ 숨김 사유 수정 성공: $questionId');
      return question;
    } catch (e) {
      print('❌ 숨김 사유 수정 실패: $e');
      rethrow;
    }
  }
}

