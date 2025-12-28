import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 환경 타입을 나타내는 열거형
/// 
/// 개발, 스테이징, 프로덕션 환경을 구분합니다.
enum Environment {
  /// 개발 환경
  /// - 로컬 개발 및 테스트용
  /// - 개발자 전용 데이터베이스 사용
  development,
  
  /// 스테이징 환경
  /// - 배포 전 최종 테스트용
  /// - 프로덕션과 유사한 환경
  staging,
  
  /// 프로덕션 환경
  /// - 실제 사용자 대상 서비스
  /// - 프로덕션 데이터베이스 사용
  production;

  /// 환경에 따른 AppBar 색상 반환
  Color get appBarColor {
    switch (this) {
      case Environment.development:
        return Colors.blue.shade700; // 개발 환경: 파란색
      case Environment.staging:
        return Colors.orange.shade700; // 스테이징 환경: 주황색
      case Environment.production:
        return Colors.deepPurple; // 프로덕션 환경: 기본 보라색
    }
  }
}

/// 앱 환경 설정을 관리하는 클래스
/// 
/// 현재 실행 환경에 따라 적절한 설정을 제공합니다.
/// 
/// 사용법:
/// ```dart
/// // 환경 설정 (main.dart에서)
/// AppEnvironment.initialize(Environment.development);
/// 
/// // Supabase URL 가져오기
/// final url = AppEnvironment.supabaseUrl;
/// ```
class AppEnvironment {
  /// 현재 실행 환경
  static Environment current = Environment.development;
  
  /// 환경이 초기화되었는지 여부
  static bool _initialized = false;
  
  /// 환경을 초기화합니다.
  /// 
  /// [environment]에 따라 적절한 .env 파일을 로드합니다.
  /// 
  /// Parameters:
  /// - [environment]: 설정할 환경 (development, staging, production)
  /// 
  /// Throws:
  /// - [Exception]: 환경 파일 로드 실패 시
  static Future<void> initialize(Environment environment) async {
    current = environment;
    
    // 환경별 .env 파일 로드
    String envFileName;
    switch (environment) {
      case Environment.development:
        envFileName = '.env.development';
        break;
      case Environment.staging:
        envFileName = '.env.staging';
        break;
      case Environment.production:
        envFileName = '.env.production';
        break;
    }
    
    try {
      await dotenv.load(fileName: envFileName);
      _initialized = true;
      print('✅ 환경 설정 완료: ${environment.name}');
      print('   환경 파일: $envFileName');
    } catch (e) {
      // 환경 파일이 없으면 기본 .env 파일 시도
      try {
        await dotenv.load(fileName: '.env');
        _initialized = true;
        print('⚠️ 환경 파일($envFileName)을 찾을 수 없어 기본 .env 파일을 사용합니다.');
        print('   환경: ${environment.name}');
      } catch (e2) {
        throw Exception(
          '환경 파일을 로드할 수 없습니다. $envFileName 또는 .env 파일을 확인하세요.\n'
          '오류: ${e.toString()}',
        );
      }
    }
  }
  
  /// 환경을 dart-define에서 초기화합니다.
  /// 
  /// Flutter 실행 시 --dart-define=ENVIRONMENT=development 형식으로 전달된
  /// 환경 값을 읽어서 초기화합니다.
  /// 
  /// 기본값은 development입니다.
  static Future<void> initializeFromDartDefine() async {
    const String envString = String.fromEnvironment('ENVIRONMENT', defaultValue: '');
    
    Environment environment;
    if (envString.isEmpty) {
      environment = Environment.development;
      print('⚠️ ENVIRONMENT가 설정되지 않아 development 환경을 사용합니다.');
    } else {
      switch (envString.toLowerCase()) {
        case 'development':
        case 'dev':
          environment = Environment.development;
          break;
        case 'staging':
        case 'stage':
          environment = Environment.staging;
          break;
        case 'production':
        case 'prod':
          environment = Environment.production;
          break;
        default:
          environment = Environment.development;
          print('⚠️ 알 수 없는 환경($envString)이므로 development 환경을 사용합니다.');
      }
    }
    
    await initialize(environment);
  }
  
  /// 현재 환경의 Supabase URL을 반환합니다.
  /// 
  /// Returns:
  /// - 환경에 맞는 Supabase URL
  /// 
  /// Throws:
  /// - [Exception]: 환경이 초기화되지 않았거나 환경 변수가 없을 때
  static String get supabaseUrl {
    if (!_initialized) {
      throw Exception(
        '환경이 초기화되지 않았습니다. AppEnvironment.initialize()를 먼저 호출하세요.',
      );
    }
    
    String? url;
    switch (current) {
      case Environment.development:
        url = dotenv.env['DEV_SUPABASE_URL'] ?? dotenv.env['SUPABASE_URL'];
        break;
      case Environment.staging:
        url = dotenv.env['STAGING_SUPABASE_URL'] ?? dotenv.env['SUPABASE_URL'];
        break;
      case Environment.production:
        url = dotenv.env['PROD_SUPABASE_URL'] ?? dotenv.env['SUPABASE_URL'];
        break;
    }
    
    if (url == null || url.isEmpty) {
      throw Exception(
        '${current.name} 환경의 Supabase URL이 설정되지 않았습니다. '
        '환경 파일을 확인하세요.',
      );
    }
    
    return url;
  }
  
  /// 현재 환경의 Supabase Anon Key를 반환합니다.
  /// 
  /// Returns:
  /// - 환경에 맞는 Supabase Anon Key
  /// 
  /// Throws:
  /// - [Exception]: 환경이 초기화되지 않았거나 환경 변수가 없을 때
  static String get supabaseAnonKey {
    if (!_initialized) {
      throw Exception(
        '환경이 초기화되지 않았습니다. AppEnvironment.initialize()를 먼저 호출하세요.',
      );
    }
    
    String? key;
    switch (current) {
      case Environment.development:
        key = dotenv.env['DEV_SUPABASE_ANON_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'];
        break;
      case Environment.staging:
        key = dotenv.env['STAGING_SUPABASE_ANON_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'];
        break;
      case Environment.production:
        key = dotenv.env['PROD_SUPABASE_ANON_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'];
        break;
    }
    
    if (key == null || key.isEmpty) {
      throw Exception(
        '${current.name} 환경의 Supabase Anon Key가 설정되지 않았습니다. '
        '환경 파일을 확인하세요.',
      );
    }
    
    return key;
  }
  
  /// 현재 환경의 이름을 반환합니다.
  /// 
  /// Returns:
  /// - 환경 이름 (development, staging, production)
  static String get environmentName => current.name;
  
  /// 현재 환경이 개발 환경인지 확인합니다.
  static bool get isDevelopment => current == Environment.development;
  
  /// 현재 환경이 스테이징 환경인지 확인합니다.
  static bool get isStaging => current == Environment.staging;
  
  /// 현재 환경이 프로덕션 환경인지 확인합니다.
  static bool get isProduction => current == Environment.production;
  
  /// 환경별 앱 제목을 반환합니다.
  /// 
  /// 개발/스테이징 환경에서는 환경 이름을 표시합니다.
  static String get appTitle {
    switch (current) {
      case Environment.development:
        return 'AURA (Dev)';
      case Environment.staging:
        return 'AURA (Staging)';
      case Environment.production:
        return 'AURA';
    }
  }
  
  /// 환경별 배지 색상을 반환합니다.
  /// 
  /// 앱 아이콘에 표시할 배지 색상입니다.
  /// - Development: 파란색
  /// - Staging: 노란색
  /// - Production: 없음 (null)
  static Color? get badgeColor {
    switch (current) {
      case Environment.development:
        return Colors.blue;
      case Environment.staging:
        return Colors.orange;
      case Environment.production:
        return null;
    }
  }
}

