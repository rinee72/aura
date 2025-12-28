/// 욕설 필터링 유틸리티
/// 
/// WP-2.1: 질문 작성 및 기본 목록 화면
/// 
/// 클라이언트 사이드에서 기본적인 욕설/비속어를 필터링합니다.
/// 주의: 이는 1차 필터링이며, 서버 사이드(Edge Function)에서도 추가 필터링이 수행됩니다.
class ProfanityFilter {
  ProfanityFilter._(); // 인스턴스 생성 방지

  /// 기본 욕설 사전 (한국어 중심)
  /// 
  /// 주의: 실제 프로덕션 환경에서는 더 포괄적인 사전이 필요합니다.
  /// 이는 예시이며, 실제 사용 시 외부 파일이나 데이터베이스에서 로드하는 것을 권장합니다.
  static final List<String> _profanityList = [
    // 욕설 (예시 - 실제로는 더 포괄적인 목록 필요)
    '시발', '병신', '미친', '개새끼', '좆', '씨발', '지랄',
    // 비속어
    '젠장', '망할', '망했어',
  ];

  /// 변형된 욕설 패턴 (정규식)
  /// 
  /// 일부 문자를 특수문자나 숫자로 변형한 욕설을 탐지합니다.
  static final List<RegExp> _profanityPatterns = [
    // 예: 시발 -> 시@발, 시1발 등
    RegExp(r'시[0-9@#$%^&*]발', caseSensitive: false),
    RegExp(r'병[0-9@#$%^&*]신', caseSensitive: false),
  ];

  /// 텍스트에 욕설이 포함되어 있는지 확인
  /// 
  /// [text]: 검사할 텍스트
  /// 
  /// Returns: 욕설이 포함되어 있으면 true, 아니면 false
  static bool containsProfanity(String text) {
    final normalizedText = text.toLowerCase().trim();

    // 기본 욕설 사전 검사
    for (final profanity in _profanityList) {
      if (normalizedText.contains(profanity.toLowerCase())) {
        return true;
      }
    }

    // 변형된 욕설 패턴 검사
    for (final pattern in _profanityPatterns) {
      if (pattern.hasMatch(normalizedText)) {
        return true;
      }
    }

    return false;
  }

  /// 텍스트에서 욕설을 찾아 반환
  /// 
  /// [text]: 검사할 텍스트
  /// 
  /// Returns: 발견된 욕설 목록 (없으면 빈 리스트)
  static List<String> findProfanity(String text) {
    final foundProfanities = <String>[];
    final normalizedText = text.toLowerCase().trim();

    // 기본 욕설 사전 검사
    for (final profanity in _profanityList) {
      if (normalizedText.contains(profanity.toLowerCase())) {
        foundProfanities.add(profanity);
      }
    }

    // 변형된 욕설 패턴 검사
    for (final pattern in _profanityPatterns) {
      final matches = pattern.allMatches(normalizedText);
      for (final match in matches) {
        foundProfanities.add(match.group(0) ?? '');
      }
    }

    return foundProfanities.toSet().toList(); // 중복 제거
  }

  /// 사용자 친화적인 에러 메시지 생성
  /// 
  /// [foundProfanities]: 발견된 욕설 목록
  /// 
  /// Returns: 사용자에게 표시할 에러 메시지
  static String getErrorMessage(List<String> foundProfanities) {
    if (foundProfanities.isEmpty) {
      return '부적절한 내용이 포함되어 있습니다.';
    }

    if (foundProfanities.length == 1) {
      return '부적절한 표현이 포함되어 있습니다. 다시 작성해주세요.';
    }

    return '부적절한 표현이 포함되어 있습니다. 다시 작성해주세요.';
  }
}

