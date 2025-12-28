import '../../../core/supabase_config.dart';
import '../models/answer_model.dart';
import '../models/qa_model.dart';
import '../../auth/models/user_model.dart';
import 'subscription_service.dart';

/// 답변 서비스
/// 
/// WP-2.4: 답변 피드 (Q&A 연결)
/// 
/// Supabase의 answers 테이블에서 답변 정보를 조회하는 서비스입니다.
class AnswerService {
  /// 구독한 셀럽의 답변 피드 조회 (Q&A 형태)
  /// 
  /// [limit]: 조회할 답변 수 (기본값: 20)
  /// [offset]: 시작 위치 (기본값: 0)
  /// [onlySubscribed]: 구독한 셀럽만 필터링할지 여부 (기본값: true)
  /// [startDate]: 필터링 시작 날짜 (선택)
  /// 
  /// Returns: Q&A 목록 (질문과 답변, 사용자 정보 포함)
  /// Throws: 답변 조회 실패 시
  static Future<List<QAModel>> getAnswersFeed({
    int limit = 20,
    int offset = 0,
    bool onlySubscribed = true,
    DateTime? startDate,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 구독한 셀럽 ID 목록 조회 (onlySubscribed가 true인 경우)
      Set<String> subscribedCelebrityIds = {};
      if (onlySubscribed) {
        subscribedCelebrityIds = await SubscriptionService.getMySubscribedCelebrityIds();
        
        // 구독한 셀럽이 없으면 빈 리스트 반환
        if (subscribedCelebrityIds.isEmpty) {
          print('ℹ️ 구독한 셀럽이 없습니다.');
          return [];
        }
      }

      // 답변 조회 쿼리 구성
      // 구독한 셀럽이 있고 필터링이 필요한 경우, 클라이언트 측에서 필터링
      // Supabase Flutter SDK에서는 여러 ID를 IN 조건으로 필터링하기 어려우므로,
      // 먼저 모든 공개 답변을 조회한 후, 클라이언트 측에서 필터링
      // 
      // 주의: users 테이블이 두 번 참조되므로 (질문 작성자, 답변 작성자),
      // 별도 쿼리로 분리하여 처리
      
      var baseQuery = client
          .from('answers')
          .select('*, questions!answers_question_id_fkey(*, users!questions_user_id_fkey(*))')
          .eq('is_draft', false); // 공개된 답변만

      // 날짜 필터링
      if (startDate != null) {
        baseQuery = baseQuery.gte('created_at', startDate.toIso8601String());
      }

      // 정렬 및 페이지네이션
      // 필터링 후 페이지네이션을 적용해야 하므로, 더 큰 범위를 조회
      final querySize = onlySubscribed && subscribedCelebrityIds.isNotEmpty 
          ? limit * 3 // 필터링을 고려하여 더 많이 조회
          : limit;
      
      final response = await baseQuery
          .order('created_at', ascending: false)
          .range(0, offset + querySize - 1);
      
      // 구독한 셀럽만 필터링 (클라이언트 측)
      List<dynamic> filteredResponse = response as List;
      if (onlySubscribed && subscribedCelebrityIds.isNotEmpty) {
        filteredResponse = (response as List).where((item) {
          final answerData = item as Map<String, dynamic>;
          final celebrityId = answerData['celebrity_id'] as String;
          return subscribedCelebrityIds.contains(celebrityId);
        }).toList();
      }
      
      // 페이지네이션 적용 (필터링 후)
      if (offset < filteredResponse.length) {
        final endIndex = offset + limit;
        if (endIndex < filteredResponse.length) {
          filteredResponse = filteredResponse.sublist(offset, endIndex);
        } else {
          filteredResponse = filteredResponse.sublist(offset);
        }
      } else {
        filteredResponse = [];
      }

      // 현재 사용자가 좋아요한 질문 ID 목록 조회
      Set<String> likedQuestionIds = {};
      try {
        final likedQuestions = await client
            .from('question_likes')
            .select('question_id')
            .eq('user_id', currentUser.id);

        likedQuestionIds = (likedQuestions as List)
            .map((item) => (item as Map<String, dynamic>)['question_id'] as String)
            .toSet();
      } catch (e) {
        print('⚠️ 좋아요 상태 조회 실패: $e (계속 진행)');
      }

      // 셀럽 ID 목록 수집 (답변 작성자)
      final celebrityIds = <String>{};
      for (final item in filteredResponse) {
        final answerData = item as Map<String, dynamic>;
        final celebrityId = answerData['celebrity_id'] as String;
        celebrityIds.add(celebrityId);
      }

      // 셀럽 정보 일괄 조회 (답변 작성자)
      // Supabase Flutter SDK에서 여러 ID를 IN 조건으로 필터링하는 방법:
      // 각 ID에 대해 개별적으로 조회하거나, 클라이언트 측에서 필터링
      // 여기서는 각 셀럽 정보를 개별적으로 조회 (celebrityIds가 많지 않을 것으로 예상)
      final celebrityMap = <String, UserModel>{};
      if (celebrityIds.isNotEmpty) {
        try {
          // 각 셀럽 ID에 대해 조회 (일괄 조회가 불가능한 경우)
          for (final celebrityId in celebrityIds) {
            try {
              final celebrityResponse = await client
                  .from('users')
                  .select()
                  .eq('id', celebrityId)
                  .maybeSingle();

              if (celebrityResponse != null) {
                final celebrity = UserModel.fromJson(celebrityResponse);
                celebrityMap[celebrity.id] = celebrity;
              }
            } catch (e) {
              print('⚠️ 셀럽 정보 조회 실패 ($celebrityId): $e');
            }
          }
        } catch (e) {
          print('⚠️ 셀럽 정보 조회 실패: $e (계속 진행)');
        }
      }

      // Q&A 모델 리스트 생성
      final qaList = <QAModel>[];
      for (final item in filteredResponse) {
        try {
          final answerData = item as Map<String, dynamic>;
          
          // 답변 데이터 추출
          final answerJson = Map<String, dynamic>.from(answerData);
          final celebrityId = answerJson['celebrity_id'] as String;
          
          // 질문 데이터 추출 (answers 테이블의 question_id를 통해 JOIN된 questions 데이터)
          final questionsData = answerJson['questions'] as Map<String, dynamic>?;
          if (questionsData == null) {
            print('⚠️ 질문 데이터가 없습니다. 답변 ID: ${answerJson['id']}');
            continue;
          }
          
          final questionJson = Map<String, dynamic>.from(questionsData);
          
          // 질문 작성자 데이터 추출 (questions 테이블의 user_id를 통해 JOIN된 users 데이터)
          final questionAuthorJson = questionJson['users'] as Map<String, dynamic>?;
          
          // 셀럽 데이터 추출 (별도 조회한 데이터 사용)
          final celebrity = celebrityMap[celebrityId];
          final celebrityJson = celebrity != null ? celebrity.toJson() : null;
          
          // JOIN된 데이터 제거 (순수 question/answer 데이터만 사용)
          answerJson.remove('questions');
          questionJson.remove('users');
          
          // 질문 ID로 좋아요 상태 확인
          final questionId = questionJson['id'] as String;
          final isLiked = likedQuestionIds.contains(questionId);
          
          // QAModel 생성
          final qa = QAModel.fromJson(
            questionJson: questionJson,
            answerJson: answerJson,
            questionAuthorJson: questionAuthorJson,
            celebrityJson: celebrityJson,
            isLiked: isLiked,
          );
          
          qaList.add(qa);
        } catch (e) {
          print('⚠️ Q&A 데이터 파싱 실패: $e (계속 진행)');
          continue;
        }
      }

      print('✅ 답변 피드 조회 성공: ${qaList.length}개');
      return qaList;
    } catch (e) {
      print('❌ 답변 피드 조회 실패: $e');
      rethrow;
    }
  }

  /// 특정 질문에 대한 답변 조회
  /// 
  /// [questionId]: 질문 ID
  /// 
  /// Returns: 답변 정보 (없으면 null)
  /// Throws: 답변 조회 실패 시
  static Future<AnswerModel?> getAnswerByQuestionId(String questionId) async {
    try {
      final client = SupabaseConfig.client;

      final response = await client
          .from('answers')
          .select()
          .eq('question_id', questionId)
          .eq('is_draft', false) // 공개된 답변만
          .maybeSingle();

      if (response != null) {
        final answer = AnswerModel.fromJson(response);
        print('✅ 답변 조회 성공: $questionId');
        return answer;
      }

      return null;
    } catch (e) {
      print('❌ 답변 조회 실패: $e');
      rethrow;
    }
  }

  /// 특정 셀럽의 답변 목록 조회
  /// 
  /// [celebrityId]: 셀럽 ID
  /// [limit]: 조회할 답변 수 (기본값: 20)
  /// [offset]: 시작 위치 (기본값: 0)
  /// 
  /// Returns: 답변 목록
  /// Throws: 답변 조회 실패 시
  static Future<List<AnswerModel>> getAnswersByCelebrityId({
    required String celebrityId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final client = SupabaseConfig.client;

      final response = await client
          .from('answers')
          .select()
          .eq('celebrity_id', celebrityId)
          .eq('is_draft', false) // 공개된 답변만
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final answers = (response as List)
          .map((json) => AnswerModel.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ 셀럽 답변 목록 조회 성공: ${answers.length}개');
      return answers;
    } catch (e) {
      print('❌ 셀럽 답변 목록 조회 실패: $e');
      rethrow;
    }
  }
}
