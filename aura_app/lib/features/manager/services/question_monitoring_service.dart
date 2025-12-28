import '../../../core/supabase_config.dart';
import '../../fan/models/question_model.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/utils/permission_checker.dart';
import 'profanity_filter_service.dart';

/// 질문 모니터링 서비스
/// 
/// WP-4.1: 매니저 대시보드 및 질문 모니터링
/// 
/// 매니저가 모든 질문을 모니터링할 수 있는 서비스입니다.
/// 팬/셀럽과 달리 숨김 처리된 질문도 포함하여 조회할 수 있습니다.
class QuestionMonitoringService {
  /// 모든 질문 조회 (필터링 전, 숨김 포함)
  /// 
  /// [limit]: 조회할 질문 수 (기본값: 50)
  /// [offset]: 시작 위치 (기본값: 0)
  /// [statusFilter]: 상태 필터 ('all', 'pending', 'answered', 'hidden', 기본값: 'all')
  /// [dateFilter]: 날짜 필터 ('all', 'today', 'week', 'month', 기본값: 'all')
  /// [sortBy]: 정렬 기준 ('created_at', 'like_count', 'user_id', 기본값: 'created_at')
  /// [orderBy]: 정렬 방향 ('asc', 'desc', 기본값: 'desc')
  /// [searchQuery]: 검색어 (질문 내용 또는 작성자 이름, 기본값: null)
  /// 
  /// Returns: 질문 목록 (작성자 정보 포함)
  /// Throws: 권한 없음, 질문 조회 실패 시
  static Future<List<Map<String, dynamic>>> getAllQuestions({
    int limit = 50,
    int offset = 0,
    String statusFilter = 'all',
    String dateFilter = 'all',
    String sortBy = 'created_at',
    String orderBy = 'desc',
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

      // 권한 검증: 매니저만 질문 모니터링 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('질문 모니터링은 매니저만 사용할 수 있습니다.');
      }

      // 날짜 범위 계산
      DateTime? startDate;
      final now = DateTime.now();
      
      switch (dateFilter) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'all':
        default:
          startDate = null;
          break;
      }

      // 기본 쿼리: 모든 질문 조회 (숨김 포함)
      // 매니저는 RLS 정책으로 모든 질문 조회 가능
      dynamic query = client
          .from('questions')
          .select(); // 질문만 먼저 조회

      // 상태 필터 적용
      if (statusFilter == 'hidden') {
        query = query.eq('is_hidden', true);
      } else if (statusFilter == 'pending') {
        query = query.eq('status', 'pending').eq('is_hidden', false);
      } else if (statusFilter == 'answered') {
        query = query.eq('status', 'answered').eq('is_hidden', false);
      }
      // 'all'인 경우 필터링 없음 (모든 질문 조회)

      // 날짜 필터 적용
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      // 정렬 적용 (작성자순은 클라이언트 사이드에서 처리)
      if (sortBy != 'user_id') {
        query = query.order(sortBy, ascending: orderBy == 'asc');
      } else {
        // 작성자순은 일단 최신순으로 정렬 (클라이언트에서 재정렬)
        query = query.order('created_at', ascending: false);
      }

      // 개수 제한 및 오프셋
      query = query.range(offset, offset + limit - 1);

      final response = await query;
      final questionsData = response as List;

      // 질문 ID 목록 추출 (필터링 로그 조회용) - WP-4.3
      final questionIds = questionsData
          .map((json) => (json as Map<String, dynamic>)['id'] as String)
          .toList();
      
      // 작성자 ID 목록 추출
      final authorUserIds = questionsData
          .map((json) => (json as Map<String, dynamic>)['user_id'] as String)
          .toSet()
          .toList();

      // 작성자 정보 및 숨김 처리한 매니저 정보 일괄 조회
      final Map<String, UserModel> authorsMap = {};
      final Map<String, UserModel> hiddenByMap = {};
      
      // 작성자 ID 목록
      final Set<String> userIds = authorUserIds.toSet();
      
      // 숨김 처리한 매니저 ID 목록 추가
      for (final questionJson in questionsData) {
        final questionData = questionJson as Map<String, dynamic>;
        final hiddenBy = questionData['hidden_by'] as String?;
        if (hiddenBy != null) {
          userIds.add(hiddenBy);
        }
      }
      
      // 모든 사용자 정보 일괄 조회
      if (userIds.isNotEmpty) {
        for (final userId in userIds) {
          try {
            final userResponse = await client
                .from('users')
                .select()
                .eq('id', userId)
                .maybeSingle();
            
            if (userResponse != null) {
              final user = UserModel.fromJson(userResponse);
              authorsMap[user.id] = user;
              hiddenByMap[user.id] = user;
            }
          } catch (e) {
            print('⚠️ 사용자 정보 조회 실패: $userId - $e');
          }
        }
      }

      // 필터링 로그 조회 (위험도 정보) - WP-4.3
      final Map<String, String> riskLevelMap = {};
      if (questionIds.isNotEmpty) {
        try {
          // 각 질문 ID에 대한 필터링 로그 조회 (효율성을 위해 개별 조회)
          // TODO: 향후 Supabase에서 IN 쿼리 지원 시 일괄 조회로 개선 가능
          for (final questionId in questionIds) {
            try {
              final filteringLogs = await ProfanityFilterService.getFilteringLogs(
                questionId: questionId,
                limit: 1, // 각 질문당 최신 로그 1개만 필요
              );
              
              if (filteringLogs.isNotEmpty) {
                riskLevelMap[questionId] = filteringLogs.first.riskLevel;
              }
            } catch (e) {
              // 개별 질문 로그 조회 실패는 무시하고 계속 진행
              print('⚠️ 질문 $questionId 필터링 로그 조회 실패: $e');
            }
          }
        } catch (e) {
          print('⚠️ 필터링 로그 조회 실패 (계속 진행): $e');
          // 필터링 로그 조회 실패는 무시하고 계속 진행
        }
      }

      // 질문과 작성자 정보, 숨김 처리한 매니저 정보, 위험도 결합
      final List<Map<String, dynamic>> questionsWithAuthors = [];
      for (final questionJson in questionsData) {
        final questionData = questionJson as Map<String, dynamic>;
        final question = QuestionModel.fromJson(questionData);
        final author = authorsMap[question.userId];
        final hiddenBy = question.hiddenBy != null 
            ? hiddenByMap[question.hiddenBy!] 
            : null;
        final riskLevel = riskLevelMap[question.id]; // WP-4.3: 위험도 정보

        questionsWithAuthors.add({
          'question': question,
          'author': author,
          'hiddenBy': hiddenBy,
          'riskLevel': riskLevel, // WP-4.3: 위험도 정보 추가
        });
      }

      // 작성자순 정렬 (클라이언트 사이드)
      // 서버 사이드에서는 user_id로 정렬하지만, 클라이언트에서 작성자 이름으로 재정렬
      if (sortBy == 'user_id') {
        questionsWithAuthors.sort((a, b) {
          final authorA = a['author'] as UserModel?;
          final authorB = b['author'] as UserModel?;
          
          // 작성자 이름 또는 이메일로 정렬
          final nameA = (authorA?.displayName ?? authorA?.email ?? '').toLowerCase();
          final nameB = (authorB?.displayName ?? authorB?.email ?? '').toLowerCase();
          
          final comparison = nameA.compareTo(nameB);
          return orderBy == 'asc' ? comparison : -comparison;
        });
      }

      // 검색어 필터링 (클라이언트 사이드)
      List<Map<String, dynamic>> filteredQuestions = [];
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryLower = searchQuery.toLowerCase().trim();
        for (final item in questionsWithAuthors) {
          final question = item['question'] as QuestionModel;
          final author = item['author'] as UserModel?;
          
          final content = question.content.toLowerCase();
          final authorName = (author?.displayName ?? '').toLowerCase();
          final authorEmail = (author?.email ?? '').toLowerCase();
          
          if (content.contains(queryLower) || 
              authorName.contains(queryLower) || 
              authorEmail.contains(queryLower)) {
            filteredQuestions.add(item);
          }
        }
      } else {
        filteredQuestions = questionsWithAuthors;
      }

      final result = filteredQuestions;

      print('✅ 질문 모니터링 조회 성공: ${result.length}개');
      return result;
    } catch (e) {
      print('❌ 질문 모니터링 조회 실패: $e');
      rethrow;
    }
  }

  /// 최근 질문 조회 (기본값: 24시간 이내)
  /// 
  /// [hours]: 조회할 시간 범위 (기본값: 24)
  /// [limit]: 조회할 질문 수 (기본값: 50)
  /// 
  /// Returns: 최근 질문 목록 (작성자 정보 포함)
  /// Throws: 권한 없음, 질문 조회 실패 시
  static Future<List<Map<String, dynamic>>> getRecentQuestions({
    int hours = 24,
    int limit = 50,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(hours: hours));
      
      return await getQuestionsByDateRange(
        startDate: startDate,
        limit: limit,
      );
    } catch (e) {
      print('❌ 최근 질문 조회 실패: $e');
      rethrow;
    }
  }

  /// 날짜별 필터링
  /// 
  /// [startDate]: 시작 날짜
  /// [endDate]: 종료 날짜 (선택)
  /// [limit]: 조회할 질문 수 (기본값: 50)
  /// 
  /// Returns: 날짜 범위 내 질문 목록 (작성자 정보 포함)
  /// Throws: 권한 없음, 질문 조회 실패 시
  static Future<List<Map<String, dynamic>>> getQuestionsByDateRange({
    required DateTime startDate,
    DateTime? endDate,
    int limit = 50,
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

      // 권한 검증: 매니저만 질문 모니터링 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('질문 모니터링은 매니저만 사용할 수 있습니다.');
      }

      // 쿼리 구성
      dynamic query = client
          .from('questions')
          .select()
          .gte('created_at', startDate.toIso8601String());

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      query = query
          .order('created_at', ascending: false)
          .limit(limit);

      final response = await query;
      final questionsData = response as List;

      // 질문 ID 목록 추출
      final questionIds = questionsData
          .map((json) => (json as Map<String, dynamic>)['user_id'] as String)
          .toSet()
          .toList();

      // 작성자 정보 일괄 조회
      final Map<String, UserModel> authorsMap = {};
      if (questionIds.isNotEmpty) {
        // 각 사용자별로 조회 (최적화는 나중에)
        for (final userId in questionIds) {
          try {
            final userResponse = await client
                .from('users')
                .select()
                .eq('id', userId)
                .maybeSingle();
            
            if (userResponse != null) {
              final user = UserModel.fromJson(userResponse);
              authorsMap[user.id] = user;
            }
          } catch (e) {
            print('⚠️ 사용자 정보 조회 실패: $userId - $e');
          }
        }
      }

      // 결과 포맷팅
      final result = questionsData.map((questionJson) {
        final questionData = questionJson as Map<String, dynamic>;
        final question = QuestionModel.fromJson(questionData);
        final author = authorsMap[question.userId];
        
        return {
          'question': question,
          'author': author,
        };
      }).toList();

      print('✅ 날짜별 질문 조회 성공: ${result.length}개');
      return result;
    } catch (e) {
      print('❌ 날짜별 질문 조회 실패: $e');
      rethrow;
    }
  }

  /// 숨김 처리된 질문만 조회
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
    return await getAllQuestions(
      limit: limit,
      offset: offset,
      statusFilter: 'hidden',
      sortBy: 'created_at',
      orderBy: 'desc',
    );
  }

  /// 상태별 필터링
  /// 
  /// [status]: 상태 ('pending', 'answered')
  /// [limit]: 조회할 질문 수 (기본값: 50)
  /// [offset]: 시작 위치 (기본값: 0)
  /// 
  /// Returns: 상태별 질문 목록 (작성자 정보 포함)
  /// Throws: 권한 없음, 질문 조회 실패 시
  static Future<List<Map<String, dynamic>>> getQuestionsByStatus({
    required String status,
    int limit = 50,
    int offset = 0,
  }) async {
    return await getAllQuestions(
      limit: limit,
      offset: offset,
      statusFilter: status,
      sortBy: 'created_at',
      orderBy: 'desc',
    );
  }
}

