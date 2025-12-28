import 'dart:io';
import 'package:aura_app/shared/utils/pubspec_validator.dart';

/// 패키지 설치 검증 유틸리티
/// 
/// Scenario 0.1-4 검증을 위한 유틸리티입니다.
/// flutter pub get 명령어 실행 및 결과 검증을 수행합니다.
class PackageInstaller {
  /// flutter pub get 명령어를 실행합니다.
  /// 
  /// Returns:
  /// - `PackageInstallResult`: 설치 결과
  static Future<PackageInstallResult> installPackages() async {
    try {
      final result = await Process.run(
        'flutter',
        ['pub', 'get'],
        runInShell: true,
      );

      final exitCode = result.exitCode;
      final stdout = result.stdout.toString();
      final stderr = result.stderr.toString();

      final isSuccess = exitCode == 0;
      final hasSuccessMessage = stdout.contains('Got dependencies!') ||
          stdout.contains('Running "flutter pub get"') ||
          stdout.contains('pub get');

      return PackageInstallResult(
        isSuccess: isSuccess && hasSuccessMessage,
        exitCode: exitCode,
        stdout: stdout,
        stderr: stderr,
        errorMessage: isSuccess ? null : stderr.isNotEmpty ? stderr : stdout,
      );
    } catch (e) {
      return PackageInstallResult(
        isSuccess: false,
        exitCode: -1,
        stdout: '',
        stderr: '',
        errorMessage: 'flutter pub get 실행 중 오류 발생: $e',
      );
    }
  }

  /// package_config.json 파일이 존재하는지 확인합니다.
  /// 
  /// Returns:
  /// - `true`: 파일 존재
  /// - `false`: 파일 없음
  static bool hasPackageConfig() {
    final file = File('.dart_tool/package_config.json');
    return file.existsSync();
  }

  /// package_config.json 파일에서 특정 패키지가 설치되었는지 확인합니다.
  /// 
  /// Returns:
  /// - `true`: 패키지 설치됨
  /// - `false`: 패키지 없음 또는 파일 없음
  static bool isPackageInstalled(String packageName) {
    final file = File('.dart_tool/package_config.json');
    if (!file.existsSync()) {
      return false;
    }

    try {
      final content = file.readAsStringSync();
      return content.contains('"$packageName"') ||
          content.contains("'$packageName'");
    } catch (e) {
      return false;
    }
  }

  /// 모든 필수 패키지가 설치되었는지 확인합니다.
  /// 
  /// Returns:
  /// - `PackageInstallVerificationResult`: 검증 결과
  static Future<PackageInstallVerificationResult> verifyInstallation() async {
    // 1. package_config.json 파일 존재 확인
    if (!hasPackageConfig()) {
      return PackageInstallVerificationResult(
        isSuccess: false,
        errorMessage: '.dart_tool/package_config.json 파일이 없습니다. flutter pub get을 실행하세요.',
        missingPackages: PubspecValidator.requiredPackages.keys.toList(),
      );
    }

    // 2. 각 필수 패키지 설치 확인
    final missingPackages = <String>[];
    for (final packageName in PubspecValidator.requiredPackages.keys) {
      if (!isPackageInstalled(packageName)) {
        missingPackages.add(packageName);
      }
    }

    final isSuccess = missingPackages.isEmpty;

    return PackageInstallVerificationResult(
      isSuccess: isSuccess,
      errorMessage: isSuccess
          ? null
          : '다음 패키지가 설치되지 않았습니다: ${missingPackages.join(", ")}',
      missingPackages: missingPackages,
    );
  }
}

/// 패키지 설치 결과
class PackageInstallResult {
  /// 설치 성공 여부
  final bool isSuccess;

  /// 종료 코드
  final int exitCode;

  /// 표준 출력
  final String stdout;

  /// 표준 에러 출력
  final String stderr;

  /// 에러 메시지 (실패 시)
  final String? errorMessage;

  PackageInstallResult({
    required this.isSuccess,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.errorMessage,
  });

  @override
  String toString() {
    if (isSuccess) {
      return '✅ 패키지 설치 성공 (exit code: $exitCode)';
    }
    return '❌ 패키지 설치 실패 (exit code: $exitCode)\n${errorMessage ?? stderr}';
  }
}

/// 패키지 설치 검증 결과
class PackageInstallVerificationResult {
  /// 검증 통과 여부
  final bool isSuccess;

  /// 에러 메시지 (검증 실패 시)
  final String? errorMessage;

  /// 누락된 패키지 목록
  final List<String> missingPackages;

  PackageInstallVerificationResult({
    required this.isSuccess,
    this.errorMessage,
    required this.missingPackages,
  });

  @override
  String toString() {
    if (isSuccess) {
      return '✅ 모든 필수 패키지가 설치되었습니다.';
    }
    return '❌ 패키지 설치 검증 실패: ${errorMessage ?? "알 수 없는 오류"}';
  }
}

