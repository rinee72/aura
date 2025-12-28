import '../../../core/supabase_config.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/utils/permission_checker.dart';
import '../models/report_model.dart';
import 'profanity_filter_service.dart';

/// 리포트 서비스
/// 
/// WP-4.5: 리포트 및 통계
/// 
/// 매니저가 필터링 통계, 일일/주간/월간 리포트, 
/// 이슈성 키워드 트렌드를 조회할 수 있는 서비스입니다.
class ReportService {
  /// 일일 리포트 조회
  /// 
  /// [date]: 리포트 날짜 (기본값: 오늘)
  /// 
  /// Returns: 일일 리포트 데이터
  /// Throws: 권한 없음, 리포트 조회 실패 시
  static Future<ReportModel> getDailyReport({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    // 일일 리포트 시작: 해당 날짜 00:00:00
    final startDate = DateTime(targetDate.year, targetDate.month, targetDate.day);
    // 일일 리포트 종료: 해당 날짜 23:59:59
    final endDate = startDate.copyWith(
      hour: 23,
      minute: 59,
      second: 59,
      millisecond: 999,
    );

    return await _getReport(
      startDate: startDate,
      endDate: endDate,
      period: ReportPeriod.daily,
    );
  }

  /// 주간 리포트 조회
  /// 
  /// [startDate]: 주간 리포트 시작 날짜 (기본값: 이번 주 월요일)
  /// 
  /// Returns: 주간 리포트 데이터
  /// Throws: 권한 없음, 리포트 조회 실패 시
  static Future<ReportModel> getWeeklyReport({DateTime? startDate}) async {
    final now = DateTime.now();
    final targetStartDate = startDate ?? _getStartOfWeek(now);
    // 주간 리포트 종료 날짜: 일요일 23:59:59
    final endDate = targetStartDate
        .add(const Duration(days: 6)) // 월요일 + 6일 = 일요일
        .copyWith(
          hour: 23,
          minute: 59,
          second: 59,
          millisecond: 999,
        );

    return await _getReport(
      startDate: targetStartDate,
      endDate: endDate,
      period: ReportPeriod.weekly,
    );
  }

  /// 월간 리포트 조회
  /// 
  /// [year]: 연도 (기본값: 올해)
  /// [month]: 월 (기본값: 이번 달)
  /// 
  /// Returns: 월간 리포트 데이터
  /// Throws: 권한 없음, 리포트 조회 실패 시
  static Future<ReportModel> getMonthlyReport({
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;
    // 월간 리포트 시작: 해당 월 1일 00:00:00
    final startDate = DateTime(targetYear, targetMonth, 1);
    // 월간 리포트 종료: 해당 월 마지막 날 23:59:59
    final endDate = DateTime(targetYear, targetMonth + 1, 1)
        .subtract(const Duration(seconds: 1))
        .copyWith(
          hour: 23,
          minute: 59,
          second: 59,
          millisecond: 999,
        );

    return await _getReport(
      startDate: startDate,
      endDate: endDate,
      period: ReportPeriod.monthly,
    );
  }

  /// 리포트 데이터 조회 (내부 메서드)
  static Future<ReportModel> _getReport({
    required DateTime startDate,
    required DateTime endDate,
    required ReportPeriod period,
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

      // 권한 검증: 매니저만 리포트 조회 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('리포트 조회는 매니저만 가능합니다.');
      }

      // 필터링 통계 조회
      final filteringStats = await ProfanityFilterService.getFilteringStats(
        startDate: startDate,
        endDate: endDate,
      );

      // 질문 통계 조회
      final questionStats = await _getQuestionStats(startDate, endDate);

      // 트렌딩 키워드 조회
      final trendingKeywords = await _getTrendingKeywords(startDate, endDate);

      final report = ReportModel(
        startDate: startDate,
        endDate: endDate,
        filteringStats: filteringStats,
        questionStats: questionStats,
        trendingKeywords: trendingKeywords,
        period: period,
      );

      print('✅ 리포트 조회 성공: ${period.name} 리포트');
      return report;
    } catch (e) {
      print('❌ 리포트 조회 실패: $e');
      rethrow;
    }
  }

  /// 질문 통계 조회
  static Future<QuestionStats> _getQuestionStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final client = SupabaseConfig.client;

      // 전체 질문 수 (날짜 범위 내)
      final allQuestions = await client
          .from('questions')
          .select('id, status, is_hidden')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final questionsData = allQuestions as List;

      int totalCount = questionsData.length;
      int pendingCount = 0;
      int answeredCount = 0;
      int hiddenCount = 0;

      // 필터링된 질문 수 (filtering_logs에서 조회)
      final filteringLogs = await client
          .from('filtering_logs')
          .select('question_id')
          .gte('filtered_at', startDate.toIso8601String())
          .lte('filtered_at', endDate.toIso8601String());

      final filteredQuestionIds = (filteringLogs as List)
          .map((log) => (log as Map<String, dynamic>)['question_id'] as String)
          .toSet();

      int filteredCount = filteredQuestionIds.length;

      for (final questionJson in questionsData) {
        final questionData = questionJson as Map<String, dynamic>;
        final status = questionData['status'] as String?;
        final isHidden = questionData['is_hidden'] as bool? ?? false;

        if (isHidden) {
          hiddenCount++;
        } else if (status == 'pending') {
          pendingCount++;
        } else if (status == 'answered') {
          answeredCount++;
        }
      }

      return QuestionStats(
        totalCount: totalCount,
        pendingCount: pendingCount,
        answeredCount: answeredCount,
        hiddenCount: hiddenCount,
        filteredCount: filteredCount,
      );
    } catch (e) {
      print('⚠️ 질문 통계 조회 실패: $e');
      return QuestionStats.empty();
    }
  }

  /// 트렌딩 키워드 조회
  static Future<List<TrendingKeyword>> _getTrendingKeywords(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final client = SupabaseConfig.client;

      // 필터링 로그에서 탐지된 욕설 키워드 추출
      final filteringLogs = await client
          .from('filtering_logs')
          .select('detected_profanities, risk_score, risk_level')
          .gte('filtered_at', startDate.toIso8601String())
          .lte('filtered_at', endDate.toIso8601String());

      final logsData = filteringLogs as List;

      // 키워드별 빈도수 및 위험도 점수 집계
      final Map<String, List<int>> keywordScores = {};
      final Map<String, List<String>> keywordRiskLevels = {};

      for (final logJson in logsData) {
        final logData = logJson as Map<String, dynamic>;
        final detectedProfanitiesRaw = logData['detected_profanities'];
        final riskScore = logData['risk_score'] as int? ?? 0;
        final riskLevel = logData['risk_level'] as String? ?? 'low';

        // detected_profanities가 JSONB 배열인 경우 처리
        List<dynamic> detectedProfanities = [];
        if (detectedProfanitiesRaw != null) {
          if (detectedProfanitiesRaw is List) {
            detectedProfanities = detectedProfanitiesRaw;
          } else if (detectedProfanitiesRaw is String) {
            // JSON 문자열인 경우 파싱 시도 (일반적이지 않지만 안전을 위해)
            try {
              detectedProfanities = [detectedProfanitiesRaw];
            } catch (e) {
              print('⚠️ detected_profanities 파싱 실패: $e');
            }
          }
        }

        for (final profanity in detectedProfanities) {
          final keyword = profanity.toString().trim().toLowerCase();
          // 빈 문자열이 아닌 경우만 추가
          if (keyword.isNotEmpty) {
            keywordScores.putIfAbsent(keyword, () => []).add(riskScore);
            keywordRiskLevels.putIfAbsent(keyword, () => []).add(riskLevel);
          }
        }
      }

      // 키워드별 통계 계산
      final List<TrendingKeyword> keywords = [];
      for (final entry in keywordScores.entries) {
        final keyword = entry.key;
        final scores = entry.value;
        final riskLevels = keywordRiskLevels[keyword] ?? [];

        // 평균 위험도 점수 계산
        final avgScore = scores.isEmpty
            ? 0
            : (scores.reduce((a, b) => a + b) / scores.length).round();

        // 가장 높은 위험도 레벨 선택
        String highestRiskLevel = 'low';
        if (riskLevels.contains('high')) {
          highestRiskLevel = 'high';
        } else if (riskLevels.contains('medium')) {
          highestRiskLevel = 'medium';
        }

        keywords.add(TrendingKeyword(
          keyword: keyword,
          frequency: scores.length,
          riskScore: avgScore,
          riskLevel: highestRiskLevel,
        ));
      }

      // 빈도수 기준 내림차순 정렬
      keywords.sort((a, b) => b.frequency.compareTo(a.frequency));

      // 상위 10개만 반환
      return keywords.take(10).toList();
    } catch (e) {
      print('⚠️ 트렌딩 키워드 조회 실패: $e');
      return [];
    }
  }

  /// 주의 시작 날짜 계산 (월요일 00:00:00)
  static DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    final startDate = date.subtract(Duration(days: weekday - 1));
    // 시간을 00:00:00으로 설정
    return DateTime(startDate.year, startDate.month, startDate.day);
  }
}

