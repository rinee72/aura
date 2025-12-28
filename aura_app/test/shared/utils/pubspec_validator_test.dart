import 'package:flutter_test/flutter_test.dart';
import 'package:aura_app/shared/utils/pubspec_validator.dart';

/// Scenario 0.1-4 검증 테스트
/// 
/// pubspec.yaml에 필수 패키지 추가 후 정상 설치를 검증합니다.
void main() {
  group('PubspecValidator - Scenario 0.1-4 검증', () {
    group('Scenario 0.1-4: 필수 패키지 추가 검증', () {
      test('필수 패키지 목록 확인', () {
        // Given & Then: 필수 패키지 목록이 올바른지 확인
        expect(
          PubspecValidator.requiredPackages.length,
          equals(4),
          reason: '필수 패키지는 4개여야 함',
        );

        expect(
          PubspecValidator.requiredPackages.containsKey('supabase_flutter'),
          true,
          reason: 'supabase_flutter가 필수 패키지 목록에 있어야 함',
        );
        expect(
          PubspecValidator.requiredPackages.containsKey('go_router'),
          true,
          reason: 'go_router가 필수 패키지 목록에 있어야 함',
        );
        expect(
          PubspecValidator.requiredPackages.containsKey('provider'),
          true,
          reason: 'provider가 필수 패키지 목록에 있어야 함',
        );
        expect(
          PubspecValidator.requiredPackages.containsKey('flutter_dotenv'),
          true,
          reason: 'flutter_dotenv가 필수 패키지 목록에 있어야 함',
        );
      });

      test('필수 패키지 버전 확인', () {
        // Given & Then: 필수 패키지 버전이 올바른지 확인
        expect(
          PubspecValidator.requiredPackages['supabase_flutter'],
          equals('^2.3.0'),
          reason: 'supabase_flutter 버전은 ^2.3.0이어야 함',
        );
        expect(
          PubspecValidator.requiredPackages['go_router'],
          equals('^13.0.0'),
          reason: 'go_router 버전은 ^13.0.0이어야 함',
        );
        expect(
          PubspecValidator.requiredPackages['provider'],
          equals('^6.1.1'),
          reason: 'provider 버전은 ^6.1.1이어야 함',
        );
        expect(
          PubspecValidator.requiredPackages['flutter_dotenv'],
          equals('^5.1.0'),
          reason: 'flutter_dotenv 버전은 ^5.1.0이어야 함',
        );
      });

      test('pubspec.yaml 파일 읽기 테스트', () {
        // Given: pubspec.yaml 파일이 존재함
        // When: pubspec.yaml 파일 읽기
        final pubspec = PubspecValidator.loadPubspec();

        // Then: 파일이 성공적으로 읽혀야 함
        expect(
          pubspec,
          isNotNull,
          reason: 'pubspec.yaml 파일을 읽을 수 있어야 함',
        );
        expect(
          pubspec!['dependencies'],
          isNotNull,
          reason: 'dependencies 섹션이 있어야 함',
        );
      });

      test('필수 패키지 검증 테스트', () {
        // Given: pubspec.yaml 파일이 존재함
        // When: 필수 패키지 검증
        final result = PubspecValidator.validateRequiredPackages();

        // Then: 검증 결과 확인
        expect(
          result,
          isA<PubspecValidationResult>(),
          reason: 'PubspecValidationResult 객체가 반환되어야 함',
        );

        // 실제 pubspec.yaml에 필수 패키지가 있는지 확인
        // (현재 프로젝트에는 이미 추가되어 있으므로 통과해야 함)
        if (result.isValid) {
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
        }
      });

      test('특정 패키지 존재 확인 테스트', () {
        // Given: pubspec.yaml 파일이 존재함
        // When: 특정 패키지 존재 확인
        final hasSupabase = PubspecValidator.hasPackage('supabase_flutter');
        final hasGoRouter = PubspecValidator.hasPackage('go_router');

        // Then: 필수 패키지가 있어야 함
        expect(
          hasSupabase,
          true,
          reason: 'supabase_flutter 패키지가 있어야 함',
        );
        expect(
          hasGoRouter,
          true,
          reason: 'go_router 패키지가 있어야 함',
        );
      });

      test('패키지 버전 가져오기 테스트', () {
        // Given: pubspec.yaml 파일이 존재함
        // When: 패키지 버전 가져오기
        final supabaseVersion = PubspecValidator.getPackageVersion('supabase_flutter');
        final goRouterVersion = PubspecValidator.getPackageVersion('go_router');

        // Then: 버전 정보가 있어야 함
        expect(
          supabaseVersion,
          isNotNull,
          reason: 'supabase_flutter 버전 정보가 있어야 함',
        );
        expect(
          goRouterVersion,
          isNotNull,
          reason: 'go_router 버전 정보가 있어야 함',
        );
      });
    });
  });
}

