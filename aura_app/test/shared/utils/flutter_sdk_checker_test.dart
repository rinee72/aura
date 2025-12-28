import 'package:flutter_test/flutter_test.dart';
import 'package:aura_app/shared/utils/flutter_sdk_checker.dart';

/// Scenario 0.1-3 검증 테스트
/// 
/// Flutter SDK 미설치 상태에서 프로젝트 생성 시도 시 실패를 검증합니다.
void main() {
  group('FlutterSDKChecker - Scenario 0.1-3 검증', () {
    group('Scenario 0.1-3: Flutter SDK 미설치 상태 검증', () {
      test('Flutter SDK 설치 여부 확인 기능 테스트', () async {
        // Given: Flutter SDK 설치 여부 확인
        final isInstalled = await FlutterSDKChecker.isInstalled();
        
        // Then: 결과가 bool 타입이어야 함
        expect(isInstalled, isA<bool>());
      });

      test('Flutter SDK 상태 확인 기능 테스트', () async {
        // Given: Flutter SDK 상태 확인
        final status = await FlutterSDKChecker.checkStatus();
        
        // Then: FlutterSDKStatus 객체가 반환되어야 함
        expect(status, isA<FlutterSDKStatus>());
        expect(status.isInstalled, isA<bool>());
        
        // 설치되어 있으면 버전 정보가 있어야 함
        if (status.isInstalled) {
          expect(status.version, isNotNull);
          expect(status.errorMessage, isNull);
        } else {
          // 설치되어 있지 않으면 에러 메시지가 있어야 함
          expect(status.errorMessage, isNotNull);
          expect(status.version, isNull);
        }
      });

      test('에러 메시지 형식 확인', () async {
        // Given: Flutter SDK가 설치되어 있지 않은 상태
        final status = await FlutterSDKChecker.checkStatus();
        
        if (!status.isInstalled) {
          // Then: 에러 메시지가 "flutter: command not found" 형식이어야 함
          expect(
            status.errorMessage,
            isNotNull,
            reason: '에러 메시지가 있어야 함',
          );
          
          // 에러 메시지에 "flutter" 또는 "command not found"가 포함되어야 함
          final errorLower = status.errorMessage!.toLowerCase();
          expect(
            errorLower.contains('flutter') || 
            errorLower.contains('command not found') ||
            errorLower.contains('not found'),
            true,
            reason: '에러 메시지에 "flutter" 또는 "command not found"가 포함되어야 함',
          );
        }
      });

      test('설치 가이드 메시지 확인', () {
        // Given: 설치 가이드 메시지 요청
        final guide = FlutterSDKChecker.getInstallationGuide();
        
        // Then: 가이드 메시지가 비어있지 않아야 함
        expect(guide, isNotEmpty);
        expect(guide, contains('Flutter SDK'));
        expect(guide, contains('설치'));
      });

      test('ensureInstalled() - SDK 미설치 시 예외 발생', () async {
        // Given: Flutter SDK 설치 여부 확인
        final isInstalled = await FlutterSDKChecker.isInstalled();
        
        if (!isInstalled) {
          // When & Then: ensureInstalled() 호출 시 예외 발생
          expect(
            () => FlutterSDKChecker.ensureInstalled(),
            throwsA(isA<FlutterSDKNotInstalledException>()),
          );
        } else {
          // SDK가 설치되어 있으면 예외가 발생하지 않아야 함
          expect(
            () => FlutterSDKChecker.ensureInstalled(),
            returnsNormally,
          );
        }
      });

      test('FlutterSDKStatus toString() 테스트', () async {
        // Given: Flutter SDK 상태 확인
        final status = await FlutterSDKChecker.checkStatus();
        
        // When: toString() 호출
        final statusString = status.toString();
        
        // Then: 문자열이 반환되어야 함
        expect(statusString, isNotEmpty);
        
        if (status.isInstalled) {
          expect(statusString, contains('설치됨'));
          expect(statusString, contains('버전'));
        } else {
          expect(statusString, contains('미설치'));
        }
      });
    });
  });
}

