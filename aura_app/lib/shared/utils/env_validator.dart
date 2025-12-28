import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 환경 변수 검증 유틸리티
/// 
/// WP-0.2 시나리오 검증을 위한 유틸리티입니다.
/// .env 파일의 Supabase 설정을 검증합니다.
class EnvValidator {
  /// .env 파일에서 Supabase 환경 변수를 검증합니다.
  /// 
  /// Returns:
  /// - `null`: 유효함
  /// - `String`: 에러 메시지
  /// 
  /// Scenario 0.2-5, 0.2-6 검증을 위한 메서드입니다.
  static String? validateSupabaseEnv() {
    try {
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      
      // SUPABASE_URL 검증
      if (url == null || url.isEmpty) {
        return 'SUPABASE_URL이 설정되지 않았습니다. .env 파일을 확인하세요.';
      }
      
      // URL 형식 검증
      if (!url.startsWith('https://')) {
        return 'SUPABASE_URL은 https://로 시작해야 합니다.';
      }
      
      if (!url.contains('.supabase.co')) {
        return 'SUPABASE_URL 형식이 올바르지 않습니다. https://your-project.supabase.co 형식이어야 합니다.';
      }
      
      // SUPABASE_ANON_KEY 검증
      if (anonKey == null || anonKey.isEmpty) {
        return 'SUPABASE_ANON_KEY가 설정되지 않았습니다. .env 파일을 확인하세요.';
      }
      
      // Anon Key는 일반적으로 긴 문자열이므로 최소 길이 체크
      if (anonKey.length < 20) {
        return 'SUPABASE_ANON_KEY가 너무 짧습니다. 올바른 키를 확인하세요.';
      }
      
      return null; // 유효함
    } catch (e) {
      return '환경 변수 검증 중 오류 발생: ${e.toString()}';
    }
  }
  
  /// .env 파일이 로드되었는지 확인합니다.
  /// 
  /// Returns:
  /// - `true`: 로드됨
  /// - `false`: 로드되지 않음
  /// 
  /// Scenario 0.2-5, 0.2-10 검증을 위한 메서드입니다.
  static bool isEnvLoaded() {
    try {
      final url = dotenv.env['SUPABASE_URL'];
      return url != null;
    } catch (e) {
      return false;
    }
  }
  
  /// 환경 변수 값을 안전하게 가져옵니다 (민감 정보 마스킹).
  /// 
  /// 디버깅 및 로깅용으로 사용합니다.
  static String getMaskedUrl() {
    try {
      final url = dotenv.env['SUPABASE_URL'] ?? 'not set';
      if (url.length > 20) {
        return '${url.substring(0, 10)}...${url.substring(url.length - 10)}';
      }
      return url;
    } catch (e) {
      return 'error';
    }
  }
  
  /// Anon Key를 안전하게 가져옵니다 (민감 정보 마스킹).
  /// 
  /// 디버깅 및 로깅용으로 사용합니다.
  static String getMaskedAnonKey() {
    try {
      final key = dotenv.env['SUPABASE_ANON_KEY'] ?? 'not set';
      if (key.length > 20) {
        return '${key.substring(0, 10)}...${key.substring(key.length - 10)}';
      }
      return '***';
    } catch (e) {
      return 'error';
    }
  }
}

