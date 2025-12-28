import '../../../core/supabase_config.dart';
import '../../fan/models/answer_model.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/utils/permission_checker.dart';
import '../../../shared/utils/profanity_filter.dart';

/// 답변 서비스 (셀럽용)
/// 
/// WP-3.2: 답변 작성 시스템
/// 
/// 셀럽이 답변을 작성, 수정, 게시할 수 있는 서비스입니다.
class AnswerService {
  /// 답변 생성 (임시저장 또는 게시)
  /// 
  /// [questionId]: 질문 ID
  /// [content]: 답변 내용
  /// [isDraft]: 임시저장 여부 (true: 임시저장, false: 게시)
  /// 
  /// Returns: 생성된 답변
  /// Throws: 권한 없음, 답변 생성 실패 시
  static Future<AnswerModel> createAnswer({
    required String questionId,
    required String content,
    bool isDraft = false,
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

      // 권한 검증: 셀럽만 답변 작성 가능
      try {
        PermissionChecker.canManageAnswer(user);
      } catch (e) {
        throw Exception('답변 작성은 셀럽만 가능합니다.');
      }

      // 답변 내용 유효성 검증
      final trimmedContent = content.trim();
      if (trimmedContent.isEmpty) {
        throw Exception('답변 내용을 입력해주세요.');
      }

      if (trimmedContent.length < 10) {
        throw Exception('답변은 최소 10자 이상 입력해주세요.');
      }

      if (trimmedContent.length > 5000) {
        throw Exception('답변은 최대 5000자까지 입력 가능합니다.');
      }

      // 욕설 필터링
      if (ProfanityFilter.containsProfanity(trimmedContent)) {
        throw Exception('답변에 부적절한 단어가 포함되어 있습니다.');
      }

      // 질문 존재 여부 및 권한 확인
      final questionResponse = await client
          .from('questions')
          .select()
          .eq('id', questionId)
          .eq('is_hidden', false) // 숨김되지 않은 질문만
          .maybeSingle();

      if (questionResponse == null) {
        throw Exception('질문을 찾을 수 없거나 접근할 수 없습니다.');
      }

      // 기존 답변 확인 (UNIQUE 제약조건으로 인해 한 질문당 하나의 답변만 가능)
      final existingAnswerResponse = await client
          .from('answers')
          .select()
          .eq('question_id', questionId)
          .maybeSingle();

      if (existingAnswerResponse != null) {
        final existingAnswer = AnswerModel.fromJson(existingAnswerResponse);
        // 기존 답변이 현재 셀럽의 답변이 아니면 에러
        if (existingAnswer.celebrityId != user.id) {
          throw Exception('이 질문에는 이미 다른 셀럽이 답변했습니다.');
        }
        // 기존 답변이 있으면 수정으로 처리
        return await updateAnswer(
          answerId: existingAnswer.id,
          content: trimmedContent,
          isDraft: isDraft,
        );
      }

      // 답변 생성
      final answerData = {
        'question_id': questionId,
        'celebrity_id': user.id,
        'content': trimmedContent,
        'is_draft': isDraft,
      };

      final response = await client
          .from('answers')
          .insert(answerData)
          .select()
          .single();

      final answer = AnswerModel.fromJson(response);

      // 게시된 답변이면 질문 상태가 'answered'로 자동 업데이트됨 (트리거)
      // 임시저장이면 상태 변경 없음

      print('✅ 답변 생성 성공: ${answer.id} (임시저장: $isDraft)');
      return answer;
    } catch (e) {
      print('❌ 답변 생성 실패: $e');
      rethrow;
    }
  }

  /// 답변 수정
  /// 
  /// [answerId]: 답변 ID
  /// [content]: 수정할 답변 내용
  /// [isDraft]: 임시저장 여부 (true: 임시저장, false: 게시)
  /// 
  /// Returns: 수정된 답변
  /// Throws: 권한 없음, 답변 수정 실패 시
  static Future<AnswerModel> updateAnswer({
    required String answerId,
    required String content,
    bool? isDraft,
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

      // 권한 검증: 셀럽만 답변 수정 가능
      try {
        PermissionChecker.canManageAnswer(user);
      } catch (e) {
        throw Exception('답변 수정은 셀럽만 가능합니다.');
      }

      // 기존 답변 조회
      final existingAnswerResponse = await client
          .from('answers')
          .select()
          .eq('id', answerId)
          .maybeSingle();

      if (existingAnswerResponse == null) {
        throw Exception('답변을 찾을 수 없습니다.');
      }

      final existingAnswer = AnswerModel.fromJson(existingAnswerResponse);

      // 자신의 답변인지 확인
      if (existingAnswer.celebrityId != user.id) {
        throw Exception('자신의 답변만 수정할 수 있습니다.');
      }

      // 답변 내용 유효성 검증
      final trimmedContent = content.trim();
      if (trimmedContent.isEmpty) {
        throw Exception('답변 내용을 입력해주세요.');
      }

      if (trimmedContent.length < 10) {
        throw Exception('답변은 최소 10자 이상 입력해주세요.');
      }

      if (trimmedContent.length > 5000) {
        throw Exception('답변은 최대 5000자까지 입력 가능합니다.');
      }

      // 욕설 필터링
      if (ProfanityFilter.containsProfanity(trimmedContent)) {
        throw Exception('답변에 부적절한 단어가 포함되어 있습니다.');
      }

      // 답변 수정
      final updateData = <String, dynamic>{
        'content': trimmedContent,
      };

      if (isDraft != null) {
        updateData['is_draft'] = isDraft;
      }

      final response = await client
          .from('answers')
          .update(updateData)
          .eq('id', answerId)
          .select()
          .single();

      final answer = AnswerModel.fromJson(response);

      // 게시된 답변이면 질문 상태가 'answered'로 자동 업데이트됨 (트리거)
      // 임시저장이면 상태 변경 없음

      print('✅ 답변 수정 성공: ${answer.id}');
      return answer;
    } catch (e) {
      print('❌ 답변 수정 실패: $e');
      rethrow;
    }
  }

  /// 임시저장 답변을 게시로 전환
  /// 
  /// [answerId]: 답변 ID
  /// 
  /// Returns: 게시된 답변
  /// Throws: 권한 없음, 답변 게시 실패 시
  static Future<AnswerModel> publishAnswer(String answerId) async {
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

      // 권한 검증
      try {
        PermissionChecker.canManageAnswer(user);
      } catch (e) {
        throw Exception('답변 게시는 셀럽만 가능합니다.');
      }

      // 기존 답변 조회
      final existingAnswerResponse = await client
          .from('answers')
          .select()
          .eq('id', answerId)
          .maybeSingle();

      if (existingAnswerResponse == null) {
        throw Exception('답변을 찾을 수 없습니다.');
      }

      final existingAnswer = AnswerModel.fromJson(existingAnswerResponse);

      // 자신의 답변인지 확인
      if (existingAnswer.celebrityId != user.id) {
        throw Exception('자신의 답변만 게시할 수 있습니다.');
      }

      // 이미 게시된 답변이면 그대로 반환
      if (!existingAnswer.isDraft) {
        return existingAnswer;
      }

      // 임시저장 → 게시 전환
      final response = await client
          .from('answers')
          .update({'is_draft': false})
          .eq('id', answerId)
          .select()
          .single();

      final answer = AnswerModel.fromJson(response);

      // 게시 시 질문 상태가 'answered'로 자동 업데이트됨 (트리거)

      print('✅ 답변 게시 성공: ${answer.id}');
      return answer;
    } catch (e) {
      print('❌ 답변 게시 실패: $e');
      rethrow;
    }
  }

  /// 특정 질문의 답변 조회
  /// 
  /// [questionId]: 질문 ID
  /// 
  /// Returns: 답변 (없으면 null)
  /// Throws: 답변 조회 실패 시
  static Future<AnswerModel?> getAnswerByQuestionId(String questionId) async {
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

      // 권한 검증: 셀럽만 답변 조회 가능 (자신의 답변만)
      try {
        PermissionChecker.canManageAnswer(user);
      } catch (e) {
        throw Exception('답변 조회는 셀럽만 가능합니다.');
      }

      // 답변 조회 (셀럽은 자신의 답변만 조회 가능, RLS 정책)
      final response = await client
          .from('answers')
          .select()
          .eq('question_id', questionId)
          .eq('celebrity_id', user.id) // 자신의 답변만
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return AnswerModel.fromJson(response);
    } catch (e) {
      print('❌ 답변 조회 실패: $e');
      rethrow;
    }
  }

  /// 내 답변 목록 조회
  /// 
  /// [statusFilter]: 상태 필터 ('all', 'published', 'draft')
  /// [sortBy]: 정렬 방식 ('newest', 'oldest')
  /// [startDate]: 날짜 필터 시작 날짜 (선택)
  /// [searchQuery]: 검색어 (질문 내용 또는 답변 내용, 선택)
  /// 
  /// Returns: 답변 목록 (질문 정보 포함)
  /// Throws: 권한 없음, 답변 조회 실패 시
  static Future<List<Map<String, dynamic>>> getMyAnswers({
    String statusFilter = 'all',
    String sortBy = 'newest',
    DateTime? startDate,
    String? searchQuery,
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

      // 권한 검증: 셀럽만 답변 조회 가능
      try {
        PermissionChecker.canManageAnswer(user);
      } catch (e) {
        throw Exception('답변 조회는 셀럽만 가능합니다.');
      }

      // 답변 조회 쿼리 구성
      // .select()를 먼저 호출한 후 필터링 적용
      var query = client
          .from('answers')
          .select()
          .eq('celebrity_id', user.id); // 자신의 답변만

      // 상태 필터 적용
      if (statusFilter == 'published') {
        query = query.eq('is_draft', false);
      } else if (statusFilter == 'draft') {
        query = query.eq('is_draft', true);
      }

      // 날짜 필터 적용
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      // 정렬 적용
      final response = await query.order('created_at', ascending: sortBy == 'oldest');
      final answersData = response as List;

      // 검색어가 있으면 클라이언트 측에서 필터링
      List<Map<String, dynamic>> filteredAnswers = answersData
          .map((item) => item as Map<String, dynamic>)
          .toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryLower = searchQuery.toLowerCase().trim();
        filteredAnswers = filteredAnswers.where((answerData) {
          final answerContent = (answerData['content'] as String? ?? '').toLowerCase();
          return answerContent.contains(queryLower);
        }).toList();
      }

      // 질문 정보와 함께 반환 (질문 내용은 별도 조회 필요)
      final result = <Map<String, dynamic>>[];
      for (final answerData in filteredAnswers) {
        result.add({
          'answer': answerData,
          'question_id': answerData['question_id'] as String,
        });
      }

      print('✅ 내 답변 목록 조회 성공: ${result.length}개');
      return result;
    } catch (e) {
      print('❌ 내 답변 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 답변 삭제
  /// 
  /// [answerId]: 답변 ID
  /// 
  /// Throws: 권한 없음, 답변 삭제 실패 시
  static Future<void> deleteAnswer(String answerId) async {
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

      // 권한 검증
      try {
        PermissionChecker.canManageAnswer(user);
      } catch (e) {
        throw Exception('답변 삭제는 셀럽만 가능합니다.');
      }

      // 기존 답변 조회
      final existingAnswerResponse = await client
          .from('answers')
          .select()
          .eq('id', answerId)
          .maybeSingle();

      if (existingAnswerResponse == null) {
        throw Exception('답변을 찾을 수 없습니다.');
      }

      final existingAnswer = AnswerModel.fromJson(existingAnswerResponse);

      // 자신의 답변인지 확인
      if (existingAnswer.celebrityId != user.id) {
        throw Exception('자신의 답변만 삭제할 수 있습니다.');
      }

      // 답변 삭제
      await client
          .from('answers')
          .delete()
          .eq('id', answerId);

      // 삭제 시 질문 상태가 'pending'으로 자동 복원됨 (트리거)

      print('✅ 답변 삭제 성공: $answerId');
    } catch (e) {
      print('❌ 답변 삭제 실패: $e');
      rethrow;
    }
  }
}

