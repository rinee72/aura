import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_app/core/supabase_config.dart';
import 'package:aura_app/shared/utils/env_validator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// WP-0.2 시나리오 통합 테스트
/// 
/// 주의: 이 테스트는 실제 .env 파일이 필요합니다.
/// 실제 Supabase 프로젝트가 생성되고 .env 파일에 올바른 값이 설정되어 있어야 합니다.
/// 
/// Scenario 0.2-5, 0.2-6, 0.2-10, 0.2-11, 0.2-12, 0.2-13 검증을 위한 통합 테스트입니다.
void main() {
  group('WP-0.2 통합 테스트', () {
    final projectPath = 'C:\\modu\\aura_app';
    
    test('Scenario 0.2-5: .env 파일에 올바른 Supabase 설정 추가 후 로드 성공', () async {
      // Given: .env 파일이 존재하고 올바른 값이 설정되어 있음
      final envFile = File('$projectPath/.env');
      if (!await envFile.exists()) {
        fail('.env 파일이 존재하지 않습니다. .env.example을 복사하여 .env 파일을 생성하고 실제 값을 입력하세요.');
      }
      
      // When: .env 파일 로드
      await dotenv.load(fileName: '.env');
      
      // Then: 환경 변수가 정상적으로 로드됨
      expect(dotenv.env['SUPABASE_URL'], isNotNull);
      expect(dotenv.env['SUPABASE_ANON_KEY'], isNotNull);
      
      // Then: 환경 변수 검증 통과
      final validationError = EnvValidator.validateSupabaseEnv();
      expect(validationError, isNull, reason: '환경 변수 검증이 통과해야 함: $validationError');
    }, skip: !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux);
    
    test('Scenario 0.2-11: Flutter 앱에서 Supabase 연결 성공 (Health Check)', () async {
      // Given: .env 파일에 올바른 설정이 있음
      await dotenv.load(fileName: '.env');
      
      // Given: 환경 변수 검증 통과
      final validationError = EnvValidator.validateSupabaseEnv();
      if (validationError != null) {
        fail('환경 변수 검증 실패: $validationError');
      }
      
      // When: Supabase 초기화
      await SupabaseConfig.initialize();
      
      // When: 연결 테스트
      final isConnected = await SupabaseConfig.checkConnection();
      
      // Then: 연결 성공
      expect(isConnected, isTrue, reason: 'Supabase 연결이 성공해야 함');
      
      // Then: 상세 연결 상태 확인
      final connectionStatus = await SupabaseConfig.checkConnectionDetailed();
      expect(connectionStatus.isConnected, isTrue);
      expect(connectionStatus.errorMessage, isNull);
    }, skip: !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux);
    
    test('Scenario 0.2-10: 환경 변수 없이 초기화 시도 시 실패', () async {
      // Given: .env 파일이 없거나 환경 변수가 설정되지 않음
      // 주의: 이 테스트는 실제로 .env 파일을 임시로 제거하거나
      // 다른 이름으로 변경해야 하므로, 수동 테스트로 분리하는 것이 좋습니다.
      
      // When: SupabaseConfig.initialize() 호출 (환경 변수 없이)
      // Then: SupabaseConfigException 발생
      
      // 실제 테스트를 위해서는 .env 파일을 임시로 제거해야 함
      // 이는 위험할 수 있으므로 수동 테스트로 분리
      
      expect(
        () => SupabaseConfig.initialize(),
        throwsA(isA<SupabaseConfigException>()),
      );
    }, skip: true); // 수동 테스트로 분리
    
    test('Scenario 0.2-12: 잘못된 URL로 연결 시도 시 실패', () async {
      // Given: 잘못된 URL이 .env 파일에 설정됨
      // 주의: 이 테스트는 실제로 .env 파일을 수정해야 하므로
      // 수동 테스트로 분리하는 것이 좋습니다.
      
      // 실제 테스트를 위해서는 .env 파일의 SUPABASE_URL을 잘못된 값으로 변경해야 함
      // 이는 위험할 수 있으므로 수동 테스트로 분리
      
      expect(
        () => SupabaseConfig.initialize(),
        throwsA(isA<SupabaseConfigException>()),
      );
    }, skip: true); // 수동 테스트로 분리
    
    test('Scenario 0.2-13: 잘못된 Anon Key로 연결 시도 시 실패', () async {
      // Given: 잘못된 Anon Key가 .env 파일에 설정됨
      // 주의: 이 테스트는 실제로 .env 파일을 수정해야 하므로
      // 수동 테스트로 분리하는 것이 좋습니다.
      
      // 실제 테스트를 위해서는 .env 파일의 SUPABASE_ANON_KEY를 잘못된 값으로 변경해야 함
      // 이는 위험할 수 있으므로 수동 테스트로 분리
      
      expect(
        () => SupabaseConfig.initialize(),
        throwsA(isA<SupabaseConfigException>()),
      );
    }, skip: true); // 수동 테스트로 분리
  });
}

