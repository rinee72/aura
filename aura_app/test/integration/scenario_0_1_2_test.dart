import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Scenario 0.1-2 통합 테스트
/// 
/// 주의: 이 테스트는 Flutter SDK가 설치되어 있어야 실행 가능합니다.
/// CI/CD 환경에서 실행하거나, 수동으로 검증할 때 사용합니다.
/// 
/// Scenario 0.1-2: 잘못된 프로젝트명으로 생성 시도 시 실패
void main() {
  group('Scenario 0.1-2 통합 테스트', () {
    test('숫자로 시작하는 프로젝트명으로 flutter create 실행 시 실패', () async {
      // Given: Flutter SDK가 설치되어 있음
      final flutterExists = await _checkFlutterInstalled();
      if (!flutterExists) {
        // Flutter SDK가 없으면 테스트를 건너뜀
        print('⚠️ Flutter SDK가 설치되어 있지 않습니다. 이 테스트를 건너뜁니다.');
        return;
      }

      // Given: 잘못된 프로젝트명 (숫자로 시작) - Scenario 0.1-2의 When 조건
      const invalidProjectName = '123InvalidName';

      // When: flutter create 명령어 실행
      final result = await Process.run(
        'flutter',
        ['create', invalidProjectName],
        runInShell: true,
      );

      // Then: 프로젝트 생성 실패 (exit code != 0)
      expect(
        result.exitCode,
        isNot(equals(0)),
        reason: '잘못된 프로젝트명으로는 프로젝트 생성이 실패해야 함',
      );

      // Then: 에러 메시지 출력
      final output = (result.stderr.toString() + result.stdout.toString()).toLowerCase();
      expect(
        output,
        anyOf(
          contains('invalid'),
          contains('error'),
          contains('cannot'),
        ),
        reason: '에러 메시지에 "invalid", "error", 또는 "cannot"이 포함되어야 함',
      );

      // Then: 프로젝트 폴더가 생성되지 않음
      final projectDir = Directory(invalidProjectName);
      expect(
        projectDir.existsSync(),
        false,
        reason: '프로젝트 폴더가 생성되지 않아야 함',
      );

      // 정리: 혹시 생성된 폴더가 있으면 삭제
      if (projectDir.existsSync()) {
        projectDir.deleteSync(recursive: true);
      }
    }, skip: !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux);
  });
}

/// Flutter SDK가 설치되어 있는지 확인
Future<bool> _checkFlutterInstalled() async {
  try {
    final result = await Process.run(
      'flutter',
      ['--version'],
      runInShell: true,
    );
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

