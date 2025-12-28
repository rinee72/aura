import '../../../core/supabase_config.dart';
import '../../fan/models/question_model.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/utils/permission_checker.dart';
import '../models/curated_question_model.dart';

/// 질문 큐레이션 서비스
/// 
/// WP-3.1: 질문 큐레이션 대시보드
/// 
/// 셀럽이 확인할 수 있는 정제된 질문 목록을 조회하는 서비스입니다.
/// 좋아요 기반으로 Top 질문을 선별하고, 날짜별/상태별 필터링을 지원합니다.
class QuestionCurationService {
  /// Top 질문 조회 (좋아요순)
  /// 
  /// [limit]: 조회할 질문 수 (기본값: 10)
  /// [dateFilter]: 날짜 필터 ('today', 'week', 'month', 'all', 기본값: 'all')
  /// [statusFilter]: 상태 필터 ('all', 'pending', 'answered', 기본값: 'all')
  /// 
  /// Returns: 큐레이션된 질문 목록 (작성자 정보 포함)
  /// Throws: 질문 조회 실패 시, 권한 없음 시
  static Future<List<CuratedQuestionModel>> getTopQuestions({
    int limit = 10,
    String dateFilter = 'all',
    String statusFilter = 'all',
  }) async {
    try {
      final client = SupabaseConfig.client;
      final currentUser = client.auth.currentUser;

      // 권한 검증: 셀럽만 질문 큐레이션 조회 가능
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

      // 셀럽 권한 검증 (클라이언트 사이드)
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleCelebrity);
      } catch (e) {
        throw Exception('질문 큐레이션은 셀럽만 사용할 수 있습니다.');
      }

      // 날짜 범위 계산
      DateTime? startDate;
      final now = DateTime.now();
      
      switch (dateFilter) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'all':
        default:
          startDate = null;
          break;
      }

      // 기본 쿼리: 숨겨지지 않은 질문만
      dynamic query = client
          .from('questions')
          .select()
          .eq('is_hidden', false); // 매니저가 숨긴 질문 제외

      // 날짜 필터 적용
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      // 상태 필터 적용
      if (statusFilter != 'all') {
        query = query.eq('status', statusFilter);
      }

      // 정렬: 좋아요순, 동일 좋아요 수일 경우 최신순
      query = query
          .order('like_count', ascending: false)
          .order('created_at', ascending: false);

      // 개수 제한
      query = query.limit(limit);

      final response = await query;

      final questionsData = response as List;

      // 질문 ID 목록 추출
      final questionIds = questionsData
          .map((json) => (json as Map<String, dynamic>)['id'] as String)
          .toList();

      // 모든 질문에 대한 게시된 답변 존재 여부를 한 번에 조회
      // Supabase Flutter SDK의 제한으로 인해 클라이언트 측에서 필터링
      Set<String> answeredQuestionIds = {};
      if (questionIds.isNotEmpty) {
        try {
          // 모든 게시된 답변 조회 (RLS 정책에 의해 셀럽은 자신의 답변만 조회 가능)
          final answersResponse = await client
              .from('answers')
              .select('question_id')
              .eq('is_draft', false); // 게시된 답변만
          
          // 클라이언트 측에서 질문 ID 목록에 포함된 것만 필터링
          final allAnsweredIds = (answersResponse as List)
              .map((item) => (item as Map<String, dynamic>)['question_id'] as String)
              .toSet();
          
          answeredQuestionIds = allAnsweredIds.intersection(questionIds.toSet());
        } catch (e) {
          print('⚠️ 답변 존재 여부 일괄 확인 실패: $e (계속 진행)');
          // 실패 시 빈 Set 유지 (답변이 없는 것으로 처리)
        }
      }

      // 작성자 정보 조회
      final curatedQuestions = <CuratedQuestionModel>[];
      for (final json in questionsData) {
        final data = json as Map<String, dynamic>;
        final questionId = data['id'] as String;
        
        // 실제 답변 존재 여부로 status 보정
        final hasPublishedAnswer = answeredQuestionIds.contains(questionId);
        if (hasPublishedAnswer) {
          data['status'] = 'answered';
        } else if (data['status'] == 'answered') {
          // status가 'answered'인데 실제 답변이 없으면 'pending'으로 보정
          data['status'] = 'pending';
        }
        
        final question = QuestionModel.fromJson(data, isLiked: false);
        
        // 작성자 정보 조회
        UserModel? author;
        try {
          final authorResponse = await client
              .from('users')
              .select()
              .eq('id', question.userId)
              .maybeSingle();
          
          if (authorResponse != null) {
            author = UserModel.fromJson(authorResponse);
          }
        } catch (e) {
          print('⚠️ 작성자 정보 조회 실패: $e (계속 진행)');
        }

        curatedQuestions.add(
          CuratedQuestionModel.fromQuestion(
            question: question,
            author: author,
          ),
        );
      }

      print('✅ Top 질문 조회 성공: ${curatedQuestions.length}개 (날짜: $dateFilter, 상태: $statusFilter)');
      return curatedQuestions;
    } catch (e) {
      print('❌ Top 질문 조회 실패: $e');
      rethrow;
    }
  }

  /// 미답변 질문만 조회
  /// 
  /// [limit]: 조회할 질문 수 (기본값: 10)
  /// [dateFilter]: 날짜 필터 ('today', 'week', 'month', 'all', 기본값: 'all')
  /// 
  /// Returns: 미답변 질문 목록 (좋아요순 정렬)
  static Future<List<CuratedQuestionModel>> getUnansweredQuestions({
    int limit = 10,
    String dateFilter = 'all',
  }) async {
    return getTopQuestions(
      limit: limit,
      dateFilter: dateFilter,
      statusFilter: 'pending',
    );
  }

  /// 답변완료 질문만 조회
  /// 
  /// [limit]: 조회할 질문 수 (기본값: 10)
  /// [dateFilter]: 날짜 필터 ('today', 'week', 'month', 'all', 기본값: 'all')
  /// 
  /// Returns: 답변완료 질문 목록 (좋아요순 정렬)
  static Future<List<CuratedQuestionModel>> getAnsweredQuestions({
    int limit = 10,
    String dateFilter = 'all',
  }) async {
    return getTopQuestions(
      limit: limit,
      dateFilter: dateFilter,
      statusFilter: 'answered',
    );
  }

  /// 날짜 범위별 질문 조회
  /// 
  /// [dateFilter]: 날짜 필터 ('today', 'week', 'month', 'all')
  /// [limit]: 조회할 질문 수 (기본값: 10)
  /// [statusFilter]: 상태 필터 ('all', 'pending', 'answered', 기본값: 'all')
  /// 
  /// Returns: 날짜 범위별 질문 목록
  static Future<List<CuratedQuestionModel>> getQuestionsByDateRange({
    required String dateFilter,
    int limit = 10,
    String statusFilter = 'all',
  }) async {
    return getTopQuestions(
      limit: limit,
      dateFilter: dateFilter,
      statusFilter: statusFilter,
    );
  }
}

