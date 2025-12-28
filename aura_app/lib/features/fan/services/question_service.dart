import '../../../core/supabase_config.dart';
import '../models/question_model.dart';
import '../../auth/models/user_model.dart';
import '../../manager/services/profanity_filter_service.dart';

/// 질문 서비스
/// 
/// WP-2.1: 질문 작성 및 기본 목록 화면
/// WP-2.2: 질문 좋아요 기능 및 정렬
/// 
/// Supabase의 questions 테이블에서 질문 정보를 조회/생성하는 서비스입니다.
class QuestionService {
  /// 질문 생성
  /// 
  /// [content]: 질문 내용
  /// 
  /// Returns: 생성된 질문
  /// Throws: 질문 생성 실패 시, 욕설 필터링 실패 시
  static Future<QuestionModel> createQuestion({
    required String content,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final trimmedContent = content.trim();

      // WP-4.3: 질문 생성 전에 Edge Function으로 필터링 실행
      // 악플이 게시되지 않도록 사전 차단
      try {
        final filterResult = await ProfanityFilterService.checkProfanity(
          content: trimmedContent,
          // questionId는 아직 없으므로 null (질문 생성 후 로그 저장)
        );

        // 위험도가 높으면 질문 생성 차단
        if (filterResult.riskLevel == 'high') {
          final profanityList = filterResult.detectedProfanities.isNotEmpty
              ? filterResult.detectedProfanities.join(", ")
              : "부적절한 표현";
          throw Exception(
            '부적절한 표현이 포함되어 있어 질문을 등록할 수 없습니다.\n'
            '탐지된 표현: $profanityList'
          );
        }

        // 중간 위험도는 경고만 (선택적 - 필요시 여기서도 차단 가능)
        if (filterResult.riskLevel == 'medium' && filterResult.detected) {
          print('⚠️ 중간 위험도 질문 감지: ${filterResult.detectedProfanities.join(", ")}');
          // 중간 위험도도 차단하려면 아래 주석 해제
          // throw Exception('부적절한 표현이 포함되어 있습니다. 다시 작성해주세요.');
        }
      } catch (e) {
        // Edge Function 호출 실패 또는 필터링 차단
        final errorString = e.toString();
        
        // 필터링 차단 메시지인 경우 그대로 재발생
        if (errorString.contains('부적절한 표현') || 
            errorString.contains('질문을 등록할 수 없습니다')) {
          rethrow;
        }
        
        // Edge Function이 배포되지 않았거나 서비스가 준비되지 않은 경우
        // 사용자에게 명확한 메시지를 제공하되, 질문 생성은 진행
        if (errorString.contains('준비되지 않았습니다') ||
            errorString.contains('연결할 수 없습니다')) {
          print('⚠️ 욕설 필터링 서비스가 준비되지 않음 (질문 생성 계속 진행): $e');
          // 서비스가 준비되지 않았어도 질문 생성은 진행 (사용자 경험 보호)
        } else {
          // 기타 네트워크 오류 등
          print('⚠️ 욕설 필터링 실패 (질문 생성 계속 진행): $e');
        }
      }

      // 질문 생성
      final questionData = <String, dynamic>{
        'user_id': currentUser.id,
        'content': trimmedContent,
        'status': 'pending',
        'like_count': 0,
        'is_hidden': false,
      };

      final response = await client
          .from('questions')
          .insert(questionData)
          .select()
          .single();

      final question = QuestionModel.fromJson(response, isLiked: false);
      
      // 질문 생성 후 필터링 로그 저장 (questionId 포함하여 정확한 로그 기록)
      _checkProfanityAsync(question.id, trimmedContent);

      print('✅ 질문 생성 성공: ${question.id}');
      return question;
    } catch (e) {
      print('❌ 질문 생성 실패: $e');
      rethrow;
    }
  }

  /// 질문 목록 조회
  /// 
  /// [limit]: 조회할 질문 수 (기본값: 20)
  /// [offset]: 시작 위치 (기본값: 0)
  /// [sortBy]: 정렬 기준 ('created_at' 또는 'like_count', 기본값: 'created_at')
  /// [orderBy]: 정렬 방향 ('asc' 또는 'desc', 기본값: 'desc')
  /// 
  /// Returns: 질문 목록 (현재 사용자의 좋아요 상태 포함)
  /// Throws: 질문 조회 실패 시
  static Future<List<QuestionModel>> getQuestions({
    int limit = 20,
    int offset = 0,
    String sortBy = 'created_at',
    String orderBy = 'desc',
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      // 숨겨지지 않은 공개 질문만 조회
      var query = client
          .from('questions')
          .select()
          .eq('is_hidden', false)
          .order(sortBy, ascending: orderBy == 'asc')
          .range(offset, offset + limit - 1);

      final response = await query;

      final questionsData = response as List;

      // 현재 사용자가 좋아요한 질문 ID 목록 조회
      Set<String> likedQuestionIds = {};
      if (currentUser != null) {
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
      }

      final questions = questionsData
          .map((json) {
            final data = json as Map<String, dynamic>;
            final questionId = data['id'] as String;
            final isLiked = likedQuestionIds.contains(questionId);
            return QuestionModel.fromJson(data, isLiked: isLiked);
          })
          .toList();

      print('✅ 질문 목록 조회 성공: ${questions.length}개 (좋아요 상태 포함)');
      return questions;
    } catch (e) {
      print('❌ 질문 목록 조회 실패: $e');
      rethrow;
    }
  }


  /// 질문 작성자 정보 조회
  /// 
  /// [userId]: 사용자 ID
  /// 
  /// Returns: 사용자 정보 (없으면 null)
  /// 
  /// 참고: 대량 조회 시 getQuestionsWithAuthors()를 사용하는 것이 더 효율적입니다.
  static Future<UserModel?> getQuestionAuthor(String userId) async {
    try {
      final client = SupabaseConfig.client;

      final response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response);
      }

      return null;
    } catch (e) {
      print('⚠️ 질문 작성자 조회 실패: $e');
      return null;
    }
  }

  /// 질문 목록과 작성자 정보를 함께 조회 (최적화)
  /// 
  /// [limit]: 조회할 질문 수
  /// [offset]: 시작 위치
  /// 
  /// Returns: 질문과 작성자 정보의 맵
  static Future<Map<QuestionModel, UserModel?>> getQuestionsWithAuthors({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final client = SupabaseConfig.client;

      // 질문과 작성자 정보를 함께 조회
      var query = client
          .from('questions')
          .select('*, users!questions_user_id_fkey(*)')
          .eq('is_hidden', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;

      final result = <QuestionModel, UserModel?>{};
      
      for (final item in response as List) {
        final data = item as Map<String, dynamic>;
        final usersData = data['users'] as Map<String, dynamic>?;
        
        // users 정보 제거
        data.remove('users');
        
        final question = QuestionModel.fromJson(data, isLiked: false);
        final author = usersData != null 
            ? UserModel.fromJson(usersData) 
            : null;
        
        result[question] = author;
      }

      print('✅ 질문 목록 및 작성자 정보 조회 성공: ${result.length}개');
      return result;
    } catch (e) {
      print('❌ 질문 목록 및 작성자 정보 조회 실패: $e');
      rethrow;
    }
  }

  /// 질문 좋아요 토글
  /// 
  /// [questionId]: 질문 ID
  /// 
  /// Returns: 좋아요 상태 (true: 좋아요 눌림, false: 좋아요 취소됨)
  /// Throws: 좋아요 토글 실패 시
  static Future<bool> toggleLike(String questionId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 좋아요 상태 확인
      final existingLike = await client
          .from('question_likes')
          .select('id')
          .eq('question_id', questionId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existingLike != null) {
        // 좋아요 취소
        await client
            .from('question_likes')
            .delete()
            .eq('question_id', questionId)
            .eq('user_id', currentUser.id);

        print('✅ 좋아요 취소 성공: $questionId');
        return false;
      } else {
        // 좋아요 추가
        await client.from('question_likes').insert({
          'question_id': questionId,
          'user_id': currentUser.id,
        });

        print('✅ 좋아요 추가 성공: $questionId');
        return true;
      }
    } catch (e) {
      print('❌ 좋아요 토글 실패: $e');
      rethrow;
    }
  }

  /// 내가 작성한 질문 목록 조회
  /// 
  /// [limit]: 조회할 질문 수 (기본값: 20)
  /// [offset]: 시작 위치 (기본값: 0)
  /// 
  /// Returns: 내가 작성한 질문 목록
  /// Throws: 질문 조회 실패 시
  static Future<List<QuestionModel>> getMyQuestions({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 현재 사용자가 작성한 질문만 조회
      var query = client
          .from('questions')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;

      final questionsData = response as List;

      final questions = questionsData
          .map((json) {
            final data = json as Map<String, dynamic>;
            return QuestionModel.fromJson(data, isLiked: false);
          })
          .toList();

      print('✅ 내 질문 목록 조회 성공: ${questions.length}개');
      return questions;
    } catch (e) {
      print('❌ 내 질문 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 질문 상세 조회 (좋아요 상태 포함)
  /// 
  /// [questionId]: 질문 ID
  /// 
  /// Returns: 질문 정보 (없으면 null, 현재 사용자의 좋아요 상태 포함)
  /// Throws: 질문 조회 실패 시
  /// 
  /// 주의: RLS 정책에 의해 팬은 자신의 질문은 숨김 처리되어도 조회 가능하며,
  /// 다른 사용자의 숨김 처리된 질문은 조회할 수 없습니다.
  static Future<QuestionModel?> getQuestionById(String questionId) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      // RLS 정책에 의해 자동으로 필터링됨:
      // - 팬: 자신의 질문 또는 숨김되지 않은 공개 질문만 조회 가능
      // - 셀럽: 숨김되지 않은 질문만 조회 가능
      // - 매니저: 모든 질문 조회 가능
      final response = await client
          .from('questions')
          .select()
          .eq('id', questionId)
          .maybeSingle();

      if (response != null) {
        // 현재 사용자가 좋아요한 질문인지 확인
        bool isLiked = false;
        if (currentUser != null) {
          try {
            final existingLike = await client
                .from('question_likes')
                .select('id')
                .eq('question_id', questionId)
                .eq('user_id', currentUser.id)
                .maybeSingle();
            isLiked = existingLike != null;
          } catch (e) {
            print('⚠️ 좋아요 상태 조회 실패: $e (계속 진행)');
          }
        }

        final question = QuestionModel.fromJson(response, isLiked: isLiked);
        print('✅ 질문 조회 성공: $questionId (좋아요 상태: $isLiked)');
        return question;
      }

      return null;
    } catch (e) {
      print('❌ 질문 조회 실패: $e');
      rethrow;
    }
  }

  /// Edge Function을 통한 욕설 필터링 (비동기)
  /// 
  /// 질문 생성 후 백그라운드에서 실행되어 사용자 경험에 영향을 주지 않음
  static void _checkProfanityAsync(String questionId, String content) {
    // 비동기로 실행 (await 없이)
    ProfanityFilterService.checkProfanity(
      content: content,
      questionId: questionId,
    ).then((result) {
      print('✅ 욕설 필터링 완료: 질문 ID=$questionId, 위험도=${result.riskLevel}, 점수=${result.riskScore}');
      if (result.detected) {
        print('   탐지된 욕설: ${result.detectedProfanities.join(", ")}');
        print('   조치: ${result.actionTaken}');
      }
    }).catchError((error) {
      // 에러는 조용히 로그만 남김 (질문 생성에는 영향을 주지 않음)
      print('⚠️ 욕설 필터링 실패 (질문은 정상 생성됨): $error');
    });
  }
}

