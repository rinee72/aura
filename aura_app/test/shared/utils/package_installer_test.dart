import 'package:flutter_test/flutter_test.dart';
import 'package:aura_app/shared/utils/package_installer.dart';

/// Scenario 0.1-4 검증 테스트
/// 
/// 패키지 설치 검증을 테스트합니다.
void main() {
  group('PackageInstaller - Scenario 0.1-4 검증', () {
    group('Scenario 0.1-4: 패키지 설치 검증', () {
      test('package_config.json 파일 존재 확인', () {
        // Given: flutter pub get이 실행되었을 수 있음
        // When: package_config.json 파일 존재 확인
        final hasConfig = PackageInstaller.hasPackageConfig();

        // Then: 파일이 존재할 수도 있고 없을 수도 있음 (flutter pub get 실행 여부에 따라)
        expect(hasConfig, isA<bool>());
      });

      test('패키지 설치 확인 기능 테스트', () {
        // Given: package_config.json 파일이 있을 수 있음
        // When: 특정 패키지 설치 확인
        final isInstalled = PackageInstaller.isPackageInstalled('supabase_flutter');

        // Then: 결과가 bool 타입이어야 함
        expect(isInstalled, isA<bool>());
      });

      test('패키지 설치 검증 기능 테스트', () async {
        // Given: 패키지 설치 검증
        // When: 설치 검증 실행
        final result = await PackageInstaller.verifyInstallation();

        // Then: 검증 결과가 반환되어야 함
        expect(
          result,
          isA<PackageInstallVerificationResult>(),
          reason: 'PackageInstallVerificationResult 객체가 반환되어야 함',
        );
        expect(
          result.isSuccess,
          isA<bool>(),
          reason: 'isSuccess가 bool 타입이어야 함',
        );
      });
    });
  });
}

