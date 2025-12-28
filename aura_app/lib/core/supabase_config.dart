import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aura_app/core/environment.dart';

/// Supabase 초기화 및 설정을 관리하는 클래스
/// 
/// WP-0.4: 환경별 설정 지원
/// 
/// 사용법:
/// ```dart
/// // 환경 초기화 (main.dart에서)
/// await AppEnvironment.initializeFromDartDefine();
/// 
/// // Supabase 초기화
/// await SupabaseConfig.initialize();
/// ```
class SupabaseConfig {
  /// Supabase 초기화 여부
  static bool _isInitialized = false;
  
  /// Supabase가 초기화되었는지 확인합니다.
  static bool get isInitialized => _isInitialized;
  
  /// Supabase를 초기화합니다.
  /// 
  /// WP-0.4: AppEnvironment를 통해 현재 환경에 맞는 Supabase 설정을 사용합니다.
  /// 
  /// 환경 변수는 AppEnvironment에서 관리되며, 환경별로 다른 Supabase 프로젝트에 연결됩니다.
  /// 
  /// Throws:
  /// - [SupabaseConfigException]: 환경 변수가 없거나 유효하지 않을 때
  /// - [Exception]: Supabase 초기화 실패 시
  static Future<void> initialize() async {
    try {
      // WP-0.4: AppEnvironment를 통해 환경별 설정 가져오기
      final url = AppEnvironment.supabaseUrl;
      final anonKey = AppEnvironment.supabaseAnonKey;
      
      // URL 형식 검증
      if (!url.startsWith('https://') || !url.contains('.supabase.co')) {
        throw SupabaseConfigException(
          'SUPABASE_URL 형식이 올바르지 않습니다. https://your-project.supabase.co 형식이어야 합니다.',
        );
      }
      
      // Supabase 초기화
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      
      _isInitialized = true;
      print('✅ Supabase 초기화 성공');
      print('   환경: ${AppEnvironment.environmentName}');
      print('   URL: $url');
    } on SupabaseConfigException {
      // 커스텀 예외는 그대로 재발생
      rethrow;
    } catch (e) {
      // 기타 예외 처리
      throw SupabaseConfigException(
        'Supabase 초기화 중 오류가 발생했습니다: ${e.toString()}',
      );
    }
  }
  
  /// Supabase 클라이언트 인스턴스를 반환합니다.
  /// 
  /// initialize()가 먼저 호출되어야 합니다.
  static SupabaseClient get client {
    if (!_isInitialized) {
      throw SupabaseConfigException(
        'Supabase가 초기화되지 않았습니다. SupabaseConfig.initialize()를 먼저 호출하세요.\n'
        '환경 파일(.env.development 또는 .env)을 확인하고 Supabase 프로젝트 정보를 설정하세요.',
      );
    }
    try {
      return Supabase.instance.client;
    } catch (e) {
      _isInitialized = false;
      throw SupabaseConfigException(
        'Supabase 클라이언트를 가져올 수 없습니다: $e',
      );
    }
  }
  
  /// 연결 상태를 확인합니다 (Health Check).
  /// 
  /// 실제 Supabase API를 호출하여 연결 상태를 검증합니다.
  /// 
  /// Returns:
  /// - true: 연결 성공
  /// - false: 연결 실패 또는 초기화되지 않음
  /// 
  /// Scenario 0.2-11 검증을 위한 메서드입니다.
  static Future<bool> checkConnection() async {
    try {
      final client = SupabaseConfig.client;
      
      // Health Check: 현재 사용자 조회 (인증되지 않은 상태면 null 반환)
      // 이는 Supabase 클라이언트가 정상적으로 초기화되었는지 확인하는 간단한 방법입니다.
      final user = client.auth.currentUser;
      
      // 실제 API 연결 확인: 실제 네트워크 요청을 통해 연결 상태를 검증합니다.
      // 인증되지 않은 상태에서도 접근 가능한 API 호출을 사용합니다.
      try {
        // 방법 1: auth.getUser()를 호출하여 실제 네트워크 연결 확인
        // 이는 인증이 필요 없으며 실제 Supabase 서버와 통신합니다.
        // 인증되지 않은 상태에서는 null을 반환하지만 네트워크 요청은 발생합니다.
        await client.auth.getUser();
        
        // 방법 2: (선택적) 간단한 쿼리로 추가 확인
        // 실제 데이터베이스 테이블이 있다면 사용 가능하지만,
        // 프로젝트 초기 단계에서는 auth.getUser()로 충분합니다.
        
      } catch (apiError) {
        // API 호출 실패 시 네트워크 에러로 간주
        final errorString = apiError.toString().toLowerCase();
        final isNetworkError = errorString.contains('network') ||
            errorString.contains('connection') ||
            errorString.contains('timeout') ||
            errorString.contains('failed') ||
            errorString.contains('socket');
        
        if (isNetworkError) {
          print('⚠️ Supabase API 호출 실패: 네트워크 오류');
          print('   오류 상세: $apiError');
          print('   해결 방법:');
          print('   1. 인터넷 연결을 확인하세요');
          print('   2. VPN 설정을 확인하세요');
          print('   3. 방화벽 설정을 확인하세요');
          print('   4. Supabase 프로젝트가 활성 상태인지 확인하세요');
          return false;
        } else {
          // 네트워크 오류가 아닌 경우 (예: 인증 오류, 설정 오류 등)
          print('⚠️ Supabase API 호출 실패: $apiError');
          print('   Supabase 프로젝트 설정을 확인하세요.');
          return false;
        }
      }
      
      print('✅ Supabase 연결 확인: ${user == null ? "인증되지 않음 (정상)" : "인증됨"}');
      print('   클라이언트 인스턴스: 정상');
      print('   네트워크 연결: 성공');
      print('   Supabase connected: true');
      return true;
    } on SupabaseConfigException catch (e) {
      // 초기화되지 않은 경우
      print('❌ Supabase 연결 확인 실패: $e');
      return false;
    } catch (e) {
      // 네트워크 에러 등 기타 예외
      final errorString = e.toString().toLowerCase();
      final isNetworkError = errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('timeout') ||
          errorString.contains('failed');
      
      print('❌ Supabase 연결 확인 실패: $e');
      if (isNetworkError) {
        print('   네트워크 연결 오류가 감지되었습니다.');
        print('   - 인터넷 연결을 확인하세요');
        print('   - VPN 설정을 확인하세요');
        print('   - 방화벽 설정을 확인하세요');
      } else {
        print('   Supabase 프로젝트 설정을 확인하세요.');
      }
      return false;
    }
  }
  
  /// Supabase 연결 상태를 상세히 확인합니다.
  /// 
  /// Returns:
  /// - [ConnectionStatus]: 연결 상태 정보
  /// 
  /// Scenario 0.2-11, 0.2-12, 0.2-13, 0.2-14 검증을 위한 메서드입니다.
  static Future<ConnectionStatus> checkConnectionDetailed() async {
    try {
      final client = SupabaseConfig.client;
      
      // 실제 API 호출을 통해 연결 상태 확인
      try {
        await client.auth.getUser();
        final user = client.auth.currentUser;
        
        return ConnectionStatus(
          isConnected: true,
          isAuthenticated: user != null,
          errorMessage: null,
        );
      } catch (apiError) {
        // API 호출 실패
        final errorMessage = apiError.toString();
        final isNetworkError = errorMessage.toLowerCase().contains('network') ||
            errorMessage.toLowerCase().contains('connection') ||
            errorMessage.toLowerCase().contains('timeout') ||
            errorMessage.toLowerCase().contains('failed') ||
            errorMessage.toLowerCase().contains('socket');
        
        return ConnectionStatus(
          isConnected: false,
          isAuthenticated: false,
          errorMessage: isNetworkError
              ? '네트워크 연결 오류: $errorMessage'
              : '연결 오류: $errorMessage',
          isNetworkError: isNetworkError,
        );
      }
    } on SupabaseConfigException catch (e) {
      return ConnectionStatus(
        isConnected: false,
        isAuthenticated: false,
        errorMessage: e.message,
      );
    } catch (e) {
      // 네트워크 에러 등
      final errorMessage = e.toString();
      final isNetworkError = errorMessage.toLowerCase().contains('network') ||
          errorMessage.toLowerCase().contains('connection') ||
          errorMessage.toLowerCase().contains('timeout') ||
          errorMessage.toLowerCase().contains('failed');
      
      return ConnectionStatus(
        isConnected: false,
        isAuthenticated: false,
        errorMessage: isNetworkError
            ? '네트워크 연결 오류: $errorMessage'
            : '연결 오류: $errorMessage',
        isNetworkError: isNetworkError,
      );
    }
  }
}

/// Supabase 설정 관련 예외 클래스
class SupabaseConfigException implements Exception {
  final String message;
  
  SupabaseConfigException(this.message);
  
  @override
  String toString() => 'SupabaseConfigException: $message';
}

/// Supabase 연결 상태 정보
/// 
/// Scenario 0.2-11, 0.2-12, 0.2-13, 0.2-14 검증을 위한 클래스입니다.
class ConnectionStatus {
  /// 연결 성공 여부
  final bool isConnected;
  
  /// 인증 여부 (연결 성공 시에만 의미 있음)
  final bool isAuthenticated;
  
  /// 에러 메시지 (연결 실패 시)
  final String? errorMessage;
  
  /// 네트워크 에러 여부
  final bool isNetworkError;
  
  ConnectionStatus({
    required this.isConnected,
    required this.isAuthenticated,
    this.errorMessage,
    this.isNetworkError = false,
  });
  
  @override
  String toString() {
    if (isConnected) {
      return '연결 성공 (인증: ${isAuthenticated ? "됨" : "안 됨"})';
    } else {
      return '연결 실패: $errorMessage';
    }
  }
}

