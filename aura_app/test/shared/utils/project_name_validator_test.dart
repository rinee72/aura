import 'package:flutter_test/flutter_test.dart';
import 'package:aura_app/shared/utils/project_name_validator.dart';

/// Scenario 0.1-2 검증 테스트
/// 
/// 잘못된 프로젝트명으로 생성 시도 시 실패를 검증합니다.
void main() {
  group('ProjectNameValidator - Scenario 0.1-2 검증', () {
    group('Scenario 0.1-2: 잘못된 프로젝트명 검증', () {
      test('숫자로 시작하는 프로젝트명은 유효하지 않음', () {
        // Given: 숫자로 시작하는 프로젝트명 (Scenario 0.1-2의 When 조건)
        const invalidNames = [
          '123InvalidName', // Scenario 문서에 명시된 케이스
          '1test',
          '999project',
          '0app',
        ];

        // When & Then: 모든 케이스가 유효하지 않음
        for (final name in invalidNames) {
          expect(
            ProjectNameValidator.isValid(name),
            false,
            reason: '"$name"은 숫자로 시작하므로 유효하지 않아야 함',
          );

          final error = ProjectNameValidator.validateWithMessage(name);
          expect(
            error,
            isNotNull,
            reason: '"$name"에 대한 에러 메시지가 있어야 함',
          );
          expect(
            error,
            contains('cannot start with a number'),
            reason: '에러 메시지에 "cannot start with a number"가 포함되어야 함',
          );

          // Flutter CLI 형식의 에러 메시지 확인
          final flutterError = ProjectNameValidator.formatFlutterError(name);
          expect(
            flutterError,
            startsWith('Error:'),
            reason: 'Flutter CLI 형식의 에러 메시지여야 함',
          );
        }
      });

      test('대문자를 포함한 프로젝트명은 유효하지 않음', () {
        const invalidNames = [
          'InvalidName',
          'TestApp',
          'MyProject',
        ];

        for (final name in invalidNames) {
          expect(
            ProjectNameValidator.isValid(name),
            false,
            reason: '"$name"은 대문자를 포함하므로 유효하지 않아야 함',
          );
        }
      });

      test('특수문자를 포함한 프로젝트명은 유효하지 않음', () {
        const invalidNames = [
          'test-app',
          'my.project',
          'app@name',
          'test name',
        ];

        for (final name in invalidNames) {
          expect(
            ProjectNameValidator.isValid(name),
            false,
            reason: '"$name"은 특수문자를 포함하므로 유효하지 않아야 함',
          );
        }
      });

      test('Dart 키워드는 프로젝트명으로 사용 불가', () {
        const invalidNames = [
          'class',
          'import',
          'void',
          'return',
        ];

        for (final name in invalidNames) {
          expect(
            ProjectNameValidator.isValid(name),
            false,
            reason: '"$name"은 Dart 키워드이므로 유효하지 않아야 함',
          );
        }
      });

      test('유효한 프로젝트명은 통과', () {
        const validNames = [
          'aura_app',
          'test_project',
          'myapp',
          'project123',
          'a',
          'valid_name_123',
        ];

        for (final name in validNames) {
          expect(
            ProjectNameValidator.isValid(name),
            true,
            reason: '"$name"은 유효한 프로젝트명이어야 함',
          );

          final error = ProjectNameValidator.validateWithMessage(name);
          expect(
            error,
            isNull,
            reason: '"$name"에 대한 에러 메시지가 없어야 함',
          );
        }
      });

      test('빈 문자열은 유효하지 않음', () {
        expect(ProjectNameValidator.isValid(''), false);
        expect(
          ProjectNameValidator.validateWithMessage(''),
          contains('cannot be empty'),
        );
      });

      test('63자를 초과하는 프로젝트명은 유효하지 않음', () {
        final longName = 'a' * 64; // 64자
        expect(ProjectNameValidator.isValid(longName), false);
        expect(
          ProjectNameValidator.validateWithMessage(longName),
          contains('cannot exceed 63 characters'),
        );
      });
    });
  });
}

