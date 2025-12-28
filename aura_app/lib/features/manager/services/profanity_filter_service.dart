import '../../../core/supabase_config.dart';
import '../../fan/models/question_model.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/utils/permission_checker.dart';

/// 욕설 필터링 서비스
/// 
/// WP-4.3: AI 악플 필터링 시스템 (Edge Function)
/// 
/// Supabase Edge Function을 호출하여 서버 사이드에서 욕설을 탐지하고
/// 위험도를 계산하는 서비스입니다.
class ProfanityFilterService {
  /// Edge Function을 호출하여 욕설을 탐지하고 위험도를 계산
  /// 
  /// [content]: 검사할 텍스트
  /// [questionId]: 질문 ID (선택, 제공되면 필터링 로그 저장 및 자동 숨김 처리)
  /// 
  /// Returns: 필터링 결과 (탐지 여부, 위험도 점수, 위험도 레벨, 조치)
  /// Throws: Edge Function 호출 실패 시
  static Future<ProfanityFilterResult> checkProfanity({
    required String content,
    String? questionId,
  }) async {
    try {
      final client = SupabaseConfig.client;

      // Edge Function 호출
      final response = await client.functions.invoke(
        'profanity-filter',
        body: {
          'content': content,
          if (questionId != null) 'questionId': questionId,
        },
      );

      if (response.status != 200) {
        // Edge Function이 배포되지 않았거나 오류가 발생한 경우
        final errorMessage = response.data is Map
            ? (response.data as Map<String, dynamic>)['error']?.toString() ?? '알 수 없는 오류'
            : 'Edge Function 호출 실패';
        
        throw Exception(
          '욕설 필터링 서비스에 연결할 수 없습니다. '
          'Edge Function이 배포되었는지 확인해주세요. (상태 코드: ${response.status}, 오류: $errorMessage)'
        );
      }

      final data = response.data as Map<String, dynamic>;

      return ProfanityFilterResult.fromJson(data);
    } catch (e) {
      final errorString = e.toString();
      
      // Edge Function이 배포되지 않은 경우 명확한 메시지 제공
      if (errorString.contains('Function not found') || 
          errorString.contains('404') ||
          errorString.contains('not found')) {
        print('❌ Edge Function이 배포되지 않았습니다. Supabase Dashboard에서 profanity-filter 함수를 배포해주세요.');
        throw Exception(
          '욕설 필터링 서비스가 준비되지 않았습니다. '
          '관리자에게 문의하거나 잠시 후 다시 시도해주세요.'
        );
      }
      
      print('❌ 욕설 필터링 실패: $e');
      rethrow;
    }
  }

  /// 필터링 로그 조회
  /// 
  /// [questionId]: 질문 ID (선택, 제공되면 특정 질문의 로그만 조회)
  /// [limit]: 조회할 로그 수 (기본값: 50)
  /// [offset]: 시작 위치 (기본값: 0)
  /// [riskLevel]: 위험도 레벨 필터 (선택)
  /// 
  /// Returns: 필터링 로그 목록
  /// Throws: 권한 없음, 로그 조회 실패 시
  static Future<List<FilteringLog>> getFilteringLogs({
    String? questionId,
    int limit = 50,
    int offset = 0,
    String? riskLevel, // 'low', 'medium', 'high'
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

      // 권한 검증: 매니저만 필터링 로그 조회 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('필터링 로그 조회는 매니저만 가능합니다.');
      }

      // 쿼리 구성
      dynamic query = client
          .from('filtering_logs')
          .select('''
            *,
            question:question_id (
              id,
              content,
              user_id,
              status,
              is_hidden,
              created_at
            )
          ''');
      
      // questionId 필터 적용
      if (questionId != null) {
        query = query.eq('question_id', questionId);
      }
      
      // riskLevel 필터 적용
      if (riskLevel != null) {
        query = query.eq('risk_level', riskLevel);
      }
      
      // 정렬 및 범위 적용
      query = query
          .order('filtered_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;
      final logsData = response as List;

      // 필터링 로그 파싱 (question 정보는 fromJson 내부에서 처리됨)
      final logs = logsData
          .map((json) => FilteringLog.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ 필터링 로그 조회 성공: ${logs.length}개');
      return logs;
    } catch (e) {
      final errorString = e.toString();
      
      // 테이블이 없을 때 명확한 메시지 제공
      if (errorString.contains('does not exist') || 
          errorString.contains('relation') ||
          errorString.contains('table') ||
          errorString.contains('PGRST')) {
        print('❌ filtering_logs 테이블이 존재하지 않습니다. 마이그레이션을 실행해주세요.');
        throw Exception(
          '필터링 로그 테이블이 준비되지 않았습니다. '
          '011_create_filtering_logs_table.sql 마이그레이션을 실행해주세요.'
        );
      }
      
      print('❌ 필터링 로그 조회 실패: $e');
      rethrow;
    }
  }

  /// 필터링 통계 조회
  /// 
  /// [startDate]: 시작 날짜 (선택)
  /// [endDate]: 종료 날짜 (선택)
  /// 
  /// Returns: 필터링 통계 (전체 로그 수, 위험도별 통계, 조치별 통계)
  /// Throws: 권한 없음, 통계 조회 실패 시
  static Future<FilteringStats> getFilteringStats({
    DateTime? startDate,
    DateTime? endDate,
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

      // 권한 검증: 매니저만 통계 조회 가능
      try {
        PermissionChecker.requireRole(user, PermissionChecker.roleManager);
      } catch (e) {
        throw Exception('필터링 통계 조회는 매니저만 가능합니다.');
      }

      // 기본 쿼리
      dynamic query = client.from('filtering_logs').select('risk_level, action_taken');

      // 날짜 필터 적용
      if (startDate != null) {
        query = query.gte('filtered_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('filtered_at', endDate.toIso8601String());
      }

      final response = await query;
      final logsData = response as List;

      // 통계 계산
      int totalCount = logsData.length;
      int lowCount = 0;
      int mediumCount = 0;
      int highCount = 0;
      int flaggedCount = 0;
      int autoHiddenCount = 0;
      int noneCount = 0;

      for (final log in logsData) {
        final data = log as Map<String, dynamic>;
        final riskLevel = data['risk_level'] as String?;
        final actionTaken = data['action_taken'] as String?;

        // 위험도별 통계
        if (riskLevel == 'low') {
          lowCount++;
        } else if (riskLevel == 'medium') {
          mediumCount++;
        } else if (riskLevel == 'high') {
          highCount++;
        }

        // 조치별 통계
        if (actionTaken == 'flagged') {
          flaggedCount++;
        } else if (actionTaken == 'auto_hidden') {
          autoHiddenCount++;
        } else if (actionTaken == 'none') {
          noneCount++;
        }
      }

      final stats = FilteringStats(
        totalCount: totalCount,
        lowCount: lowCount,
        mediumCount: mediumCount,
        highCount: highCount,
        flaggedCount: flaggedCount,
        autoHiddenCount: autoHiddenCount,
        noneCount: noneCount,
      );

      print('✅ 필터링 통계 조회 성공');
      return stats;
    } catch (e) {
      print('❌ 필터링 통계 조회 실패: $e');
      rethrow;
    }
  }
}

/// 필터링 결과 모델
class ProfanityFilterResult {
  final bool detected;
  final List<String> detectedProfanities;
  final int riskScore;
  final String riskLevel; // 'low', 'medium', 'high'
  final String actionTaken; // 'flagged', 'auto_hidden', 'none'
  final int matchCount;

  ProfanityFilterResult({
    required this.detected,
    required this.detectedProfanities,
    required this.riskScore,
    required this.riskLevel,
    required this.actionTaken,
    required this.matchCount,
  });

  factory ProfanityFilterResult.fromJson(Map<String, dynamic> json) {
    return ProfanityFilterResult(
      detected: json['detected'] as bool? ?? false,
      detectedProfanities: (json['detectedProfanities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      riskScore: json['riskScore'] as int? ?? 0,
      riskLevel: json['riskLevel'] as String? ?? 'low',
      actionTaken: json['actionTaken'] as String? ?? 'none',
      matchCount: json['matchCount'] as int? ?? 0,
    );
  }
}

/// 필터링 로그 모델
class FilteringLog {
  final String id;
  final String questionId;
  final String content;
  final List<String> detectedProfanities;
  final int riskScore;
  final String riskLevel;
  final DateTime filteredAt;
  final String actionTaken;
  final DateTime createdAt;
  final DateTime updatedAt;
  final QuestionModel? question;

  FilteringLog({
    required this.id,
    required this.questionId,
    required this.content,
    required this.detectedProfanities,
    required this.riskScore,
    required this.riskLevel,
    required this.filteredAt,
    required this.actionTaken,
    required this.createdAt,
    required this.updatedAt,
    this.question,
  });

  factory FilteringLog.fromJson(Map<String, dynamic> json) {
    final questionData = json['question'] as Map<String, dynamic>?;
    QuestionModel? question;
    if (questionData != null) {
      question = QuestionModel.fromJson(questionData, isLiked: false);
    }

    return FilteringLog(
      id: json['id'] as String,
      questionId: json['question_id'] as String,
      content: json['content'] as String,
      detectedProfanities: (json['detected_profanities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      riskScore: json['risk_score'] as int? ?? 0,
      riskLevel: json['risk_level'] as String? ?? 'low',
      filteredAt: DateTime.parse(json['filtered_at'] as String),
      actionTaken: json['action_taken'] as String? ?? 'none',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      question: question,
    );
  }
}

/// 필터링 통계 모델
class FilteringStats {
  final int totalCount;
  final int lowCount;
  final int mediumCount;
  final int highCount;
  final int flaggedCount;
  final int autoHiddenCount;
  final int noneCount;

  FilteringStats({
    required this.totalCount,
    required this.lowCount,
    required this.mediumCount,
    required this.highCount,
    required this.flaggedCount,
    required this.autoHiddenCount,
    required this.noneCount,
  });

  /// 위험도가 높은 비율 (%)
  double get highRiskPercentage {
    if (totalCount == 0) return 0.0;
    return (highCount / totalCount) * 100;
  }

  /// 자동 숨김 처리 비율 (%)
  double get autoHiddenPercentage {
    if (totalCount == 0) return 0.0;
    return (autoHiddenCount / totalCount) * 100;
  }
}

