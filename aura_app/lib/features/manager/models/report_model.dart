import '../services/profanity_filter_service.dart';

/// 리포트 모델
/// 
/// WP-4.5: 리포트 및 통계
/// 
/// 일일/주간/월간 리포트 데이터를 담는 모델입니다.
class ReportModel {
  final DateTime startDate;
  final DateTime endDate;
  final FilteringStats filteringStats;
  final QuestionStats questionStats;
  final List<TrendingKeyword> trendingKeywords;
  final ReportPeriod period;

  ReportModel({
    required this.startDate,
    required this.endDate,
    required this.filteringStats,
    required this.questionStats,
    required this.trendingKeywords,
    required this.period,
  });

  /// 탐지율 계산 (%)
  double get detectionRate {
    if (questionStats.totalCount == 0) return 0.0;
    return (filteringStats.totalCount / questionStats.totalCount) * 100;
  }

  /// 필터링 비율 계산 (%)
  double get filteringRate {
    if (filteringStats.totalCount == 0) return 0.0;
    return (filteringStats.highCount / filteringStats.totalCount) * 100;
  }
}

/// 리포트 기간 타입
enum ReportPeriod {
  daily,
  weekly,
  monthly,
}

/// 질문 통계 모델
class QuestionStats {
  final int totalCount;
  final int pendingCount;
  final int answeredCount;
  final int hiddenCount;
  final int filteredCount; // 필터링된 질문 수

  QuestionStats({
    required this.totalCount,
    required this.pendingCount,
    required this.answeredCount,
    required this.hiddenCount,
    required this.filteredCount,
  });

  factory QuestionStats.empty() {
    return QuestionStats(
      totalCount: 0,
      pendingCount: 0,
      answeredCount: 0,
      hiddenCount: 0,
      filteredCount: 0,
    );
  }
}

/// 트렌딩 키워드 모델
class TrendingKeyword {
  final String keyword;
  final int frequency;
  final int riskScore; // 평균 위험도 점수
  final String riskLevel; // 'low', 'medium', 'high'

  TrendingKeyword({
    required this.keyword,
    required this.frequency,
    required this.riskScore,
    required this.riskLevel,
  });
}

