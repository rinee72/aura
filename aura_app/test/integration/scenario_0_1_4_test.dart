import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_app/shared/utils/pubspec_validator.dart';
import 'package:aura_app/shared/utils/package_installer.dart';

/// Scenario 0.1-4 통합 테스트
/// 
/// 주의: 이 테스트는 Flutter SDK가 설치되어 있어야 실행 가능합니다.
/// 
/// Scenario 0.1-4: pubspec.yaml에 필수 패키지 추가 후 정상 설치
void main() {
  group('Scenario 0.1-4 통합 테스트', () {
    test('pubspec.yaml에 필수 패키지 추가 후 정상 설치', () async {
      // Given: Flutter 프로젝트가 생성되어 있음
      // Flutter SDK 설치 확인
      try {
        final flutterCheck = await Process.run(
          'flutter',
          ['--version'],
          runInShell: true,
        );
        if (flutterCheck.exitCode != 0) {
          print('⚠️ Flutter SDK가 설치되어 있지 않습니다. 이 테스트를 건너뜁니다.');
          return;
        }
      } catch (e) {
        print('⚠️ Flutter SDK를 찾을 수 없습니다. 이 테스트를 건너뜁니다.');
        return;
      }

      // Given: pubspec.yaml에 필수 패키지가 추가되어 있음
      final pubspecValidation = PubspecValidator.validateRequiredPackages();
      
      expect(
        pubspecValidation.isValid,
        true,
        reason: 'pubspec.yaml에 모든 필수 패키지가 추가되어 있어야 함',
      );

      // When: flutter pub get 명령어 실행
      final installResult = await PackageInstaller.installPackages();

      // Then: 모든 패키지가 성공적으로 다운로드됨
      expect(
        installResult.isSuccess,
        true,
        reason: 'flutter pub get이 성공해야 함 (exit code: ${installResult.exitCode})',
      );

      // Then: 종료 코드 0 반환
      expect(
        installResult.exitCode,
        equals(0),
        reason: 'flutter pub get의 exit code는 0이어야 함',
      );

      // Then: "Got dependencies!" 메시지 출력 (또는 유사한 메시지)
      final output = installResult.stdout.toLowerCase();
      expect(
        output.contains('got dependencies') ||
            output.contains('running "flutter pub get"') ||
            output.contains('pub get'),
        true,
        reason: '출력에 "Got dependencies!" 또는 유사한 메시지가 포함되어야 함',
      );

      // Then: .dart_tool/package_config.json 파일에 패키지 정보 존재
      final verification = await PackageInstaller.verifyInstallation();
      expect(
        verification.isSuccess,
        true,
        reason: '모든 필수 패키지가 package_config.json에 있어야 함',
      );
    }, skip: !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux);

    test('필수 패키지가 pubspec.yaml에 올바르게 추가되었는지 확인', () {
      // Given: pubspec.yaml 파일이 존재함
      // When: 필수 패키지 검증
      final result = PubspecValidator.validateRequiredPackages();

      // Then: 모든 필수 패키지가 있어야 함
      expect(
        result.isValid,
        true,
        reason: '모든 필수 패키지가 pubspec.yaml에 있어야 함',
      );

      expect(
        result.missingPackages,
        isEmpty,
        reason: '누락된 패키지가 없어야 함',
      );

      expect(
        result.incorrectVersions,
        isEmpty,
        reason: '버전이 올바르지 않은 패키지가 없어야 함',
      );
    });
  });
}

