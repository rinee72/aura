import 'dart:io';

/// Flutter SDK 설치 여부 확인 유틸리티
/// 
/// Scenario 0.1-3 검증을 위한 유틸리티입니다.
/// Flutter SDK가 PATH에 있는지 확인하고, 적절한 에러 메시지를 제공합니다.
class FlutterSDKChecker {
  /// Flutter SDK가 PATH에 설치되어 있는지 확인합니다.
  /// 
  /// Returns:
  /// - `true`: Flutter SDK가 설치되어 있음
  /// - `false`: Flutter SDK가 설치되어 있지 않음
  static Future<bool> isInstalled() async {
    try {
      final result = await Process.run(
        'flutter',
        ['--version'],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (e) {
      // "flutter: command not found" 또는 유사한 에러
      return false;
    }
  }

  /// Flutter SDK 설치 여부를 확인하고 상세 정보를 반환합니다.
  /// 
  /// Returns:
  /// - `FlutterSDKStatus`: 설치 상태 및 상세 정보
  static Future<FlutterSDKStatus> checkStatus() async {
    try {
      final result = await Process.run(
        'flutter',
        ['--version'],
        runInShell: true,
      );

      if (result.exitCode == 0) {
        // Flutter 버전 정보 파싱
        final versionOutput = result.stdout.toString();
        final versionMatch = RegExp(r'Flutter\s+([\d.]+)').firstMatch(versionOutput);
        final version = versionMatch?.group(1) ?? 'unknown';

        return FlutterSDKStatus(
          isInstalled: true,
          version: version,
          errorMessage: null,
        );
      } else {
        return FlutterSDKStatus(
          isInstalled: false,
          version: null,
          errorMessage: 'Flutter SDK가 설치되어 있지 않거나 PATH에 없습니다.',
        );
      }
    } catch (e) {
      // "flutter: command not found" 또는 유사한 에러
      final errorMessage = _getErrorMessage(e.toString());
      return FlutterSDKStatus(
        isInstalled: false,
        version: null,
        errorMessage: errorMessage,
      );
    }
  }

  /// 에러 메시지에서 플랫폼별 적절한 메시지 추출
  static String _getErrorMessage(String error) {
    final errorLower = error.toLowerCase();
    
    if (errorLower.contains('command not found') ||
        errorLower.contains('not recognized') ||
        errorLower.contains('not found')) {
      return 'flutter: command not found';
    }
    
    return 'Flutter SDK를 찾을 수 없습니다: $error';
  }

  /// Flutter SDK 미설치 시 표시할 안내 메시지 생성
  static String getInstallationGuide() {
    return '''
Flutter SDK가 설치되어 있지 않습니다.

설치 방법:
1. Flutter 공식 사이트 방문: https://flutter.dev/docs/get-started/install
2. 운영체제에 맞는 설치 가이드 확인
3. PATH 환경 변수에 Flutter SDK 경로 추가

설치 확인:
  flutter --version
''';
  }

  /// 프로젝트 생성 전 Flutter SDK 설치 여부 확인
  /// 
  /// Throws:
  /// - [FlutterSDKNotInstalledException]: Flutter SDK가 설치되어 있지 않을 때
  static Future<void> ensureInstalled() async {
    final isInstalled = await FlutterSDKChecker.isInstalled();
    if (!isInstalled) {
      throw FlutterSDKNotInstalledException(
        'Flutter SDK가 설치되어 있지 않습니다. 프로젝트를 생성할 수 없습니다.',
      );
    }
  }
}

/// Flutter SDK 설치 상태 정보
class FlutterSDKStatus {
  /// Flutter SDK 설치 여부
  final bool isInstalled;

  /// Flutter 버전 (설치되어 있을 때만)
  final String? version;

  /// 에러 메시지 (설치되어 있지 않을 때)
  final String? errorMessage;

  FlutterSDKStatus({
    required this.isInstalled,
    this.version,
    this.errorMessage,
  });

  @override
  String toString() {
    if (isInstalled) {
      return 'Flutter SDK 설치됨 (버전: $version)';
    } else {
      return 'Flutter SDK 미설치: $errorMessage';
    }
  }
}

/// Flutter SDK 미설치 예외
class FlutterSDKNotInstalledException implements Exception {
  final String message;

  FlutterSDKNotInstalledException(this.message);

  @override
  String toString() => 'FlutterSDKNotInstalledException: $message';
}

