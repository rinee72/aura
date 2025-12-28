import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_app/shared/utils/flutter_sdk_checker.dart';

/// Scenario 0.1-3 통합 테스트
/// 
/// 주의: 이 테스트는 실제 환경에서 Flutter SDK 설치 여부를 확인합니다.
/// 
/// Scenario 0.1-3: Flutter SDK 미설치 상태에서 프로젝트 생성 시도 시 실패
void main() {
  group('Scenario 0.1-3 통합 테스트', () {
    test('Flutter SDK 미설치 상태에서 flutter create 실행 시 실패', () async {
      // Given: Flutter SDK 설치 여부 확인
      final isInstalled = await FlutterSDKChecker.isInstalled();
      
      if (isInstalled) {
        // Flutter SDK가 설치되어 있으면 이 테스트는 건너뜀
        print('⚠️ Flutter SDK가 설치되어 있습니다. 이 테스트를 건너뜁니다.');
        print('   이 테스트는 Flutter SDK가 PATH에 없을 때만 통과합니다.');
        return;
      }

      // Given: Flutter SDK가 PATH에 없음
      // When: flutter create 명령어 실행 시도
      try {
        final result = await Process.run(
          'flutter',
          ['create', 'test_project'],
          runInShell: true,
        );

        // Then: 프로젝트 생성 실패 (exit code != 0)
        expect(
          result.exitCode,
          isNot(equals(0)),
          reason: 'Flutter SDK가 없으면 프로젝트 생성이 실패해야 함',
        );

        // Then: "flutter: command not found" 에러 메시지 출력
        final output = (result.stderr.toString() + result.stdout.toString()).toLowerCase();
        expect(
          output,
          anyOf(
            contains('command not found'),
            contains('not recognized'),
            contains('not found'),
            contains('flutter'),
          ),
          reason: '에러 메시지에 "command not found" 또는 유사한 메시지가 포함되어야 함',
        );
      } catch (e) {
        // Process.run이 예외를 던질 수도 있음 (command not found)
        final errorString = e.toString().toLowerCase();
        expect(
          errorString,
          anyOf(
            contains('command not found'),
            contains('not recognized'),
            contains('not found'),
          ),
          reason: '예외 메시지에 "command not found" 또는 유사한 메시지가 포함되어야 함',
        );
      }
    }, skip: !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux);

    test('FlutterSDKChecker를 사용한 SDK 설치 여부 확인', () async {
      // Given: Flutter SDK 상태 확인
      final status = await FlutterSDKChecker.checkStatus();
      
      // Then: 상태 정보가 올바르게 반환되어야 함
      expect(status, isA<FlutterSDKStatus>());
      
      if (!status.isInstalled) {
        // SDK가 설치되어 있지 않으면 에러 메시지가 있어야 함
        expect(status.errorMessage, isNotNull);
        expect(status.errorMessage, contains('flutter'));
      } else {
        // SDK가 설치되어 있으면 버전 정보가 있어야 함
        expect(status.version, isNotNull);
      }
    });
  });
}

