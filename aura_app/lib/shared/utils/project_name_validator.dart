/// Flutter 프로젝트명 검증 유틸리티
/// 
/// Flutter CLI의 프로젝트명 규칙을 따릅니다:
/// - 소문자, 숫자, 언더스코어만 허용
/// - 숫자로 시작할 수 없음
/// - Dart 키워드 사용 불가
/// - 최소 1자, 최대 63자
/// 
/// Scenario 0.1-2 검증을 위한 유틸리티입니다.
class ProjectNameValidator {
  /// Dart 예약 키워드 목록
  static const List<String> _dartKeywords = [
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
    'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
    'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
    'factory', 'false', 'final', 'finally', 'for', 'Function', 'get', 'hide',
    'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
    'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
    'return', 'set', 'show', 'static', 'super', 'switch', 'sync', 'this',
    'throw', 'true', 'try', 'typedef', 'var', 'void', 'while', 'with', 'yield',
  ];

  /// 프로젝트명이 유효한지 검증합니다.
  /// 
  /// Returns:
  /// - `true`: 유효한 프로젝트명
  /// - `false`: 유효하지 않은 프로젝트명
  static bool isValid(String projectName) {
    if (projectName.isEmpty) {
      return false;
    }

    // 최대 길이 검증 (63자)
    if (projectName.length > 63) {
      return false;
    }

    // 숫자로 시작하는지 검증
    if (RegExp(r'^[0-9]').hasMatch(projectName)) {
      return false;
    }

    // 허용된 문자만 사용하는지 검증 (소문자, 숫자, 언더스코어)
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(projectName)) {
      return false;
    }

    // Dart 키워드인지 검증
    if (_dartKeywords.contains(projectName)) {
      return false;
    }

    return true;
  }

  /// 프로젝트명 검증 및 상세 에러 메시지 반환
  /// 
  /// Returns:
  /// - `null`: 유효한 프로젝트명
  /// - `String`: 에러 메시지
  static String? validateWithMessage(String projectName) {
    if (projectName.isEmpty) {
      return 'Project name cannot be empty.';
    }

    if (projectName.length > 63) {
      return 'Project name cannot exceed 63 characters.';
    }

    if (RegExp(r'^[0-9]').hasMatch(projectName)) {
      return 'Invalid project name: "$projectName". Project names cannot start with a number.';
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(projectName)) {
      return 'Invalid project name: "$projectName". Project names can only contain lowercase letters, numbers, and underscores.';
    }

    if (_dartKeywords.contains(projectName)) {
      return 'Invalid project name: "$projectName". Project names cannot be Dart keywords.';
    }

    return null; // 유효함
  }

  /// Flutter CLI와 동일한 형식의 에러 메시지 생성
  static String formatFlutterError(String projectName) {
    final error = validateWithMessage(projectName);
    if (error == null) {
      return '';
    }
    return 'Error: $error';
  }
}

