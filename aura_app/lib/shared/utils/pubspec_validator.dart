import 'dart:io';

/// pubspec.yaml 검증 유틸리티
/// 
/// Scenario 0.1-4 검증을 위한 유틸리티입니다.
/// pubspec.yaml 파일에 필수 패키지가 올바르게 추가되었는지 확인합니다.
class PubspecValidator {
  /// 필수 패키지 목록 (Scenario 0.1-4 요구사항)
  static const Map<String, String> requiredPackages = {
    'supabase_flutter': '^2.3.0',
    'go_router': '^13.0.0',
    'provider': '^6.1.1',
    'flutter_dotenv': '^5.1.0',
  };

  /// pubspec.yaml 파일 경로
  static String get pubspecPath => 'pubspec.yaml';

  /// pubspec.yaml 파일을 읽고 파싱합니다.
  /// 
  /// Returns:
  /// - `Map<String, dynamic>`: 파싱된 pubspec.yaml 내용
  /// - `null`: 파일을 읽을 수 없거나 파싱 실패
  static Map<String, dynamic>? loadPubspec() {
    try {
      final file = File(pubspecPath);
      if (!file.existsSync()) {
        return null;
      }

      final content = file.readAsStringSync();
      return _parseYaml(content);
    } catch (e) {
      return null;
    }
  }

  /// 간단한 YAML 파싱 (dependencies 섹션만)
  static Map<String, dynamic>? _parseYaml(String content) {
    try {
      final result = <String, dynamic>{};
      final lines = content.split('\n');
      
      bool inDependencies = false;
      final dependencies = <String, dynamic>{};
      
      for (var line in lines) {
        final trimmed = line.trim();
        
        // dependencies 섹션 시작
        if (trimmed == 'dependencies:' || trimmed.startsWith('dependencies:')) {
          inDependencies = true;
          continue;
        }
        
        // 다른 최상위 섹션 시작 시 dependencies 종료
        if (inDependencies && trimmed.isNotEmpty && !line.startsWith(' ') && !line.startsWith('\t')) {
          inDependencies = false;
        }
        
        // dependencies 섹션 내에서 패키지 파싱
        if (inDependencies && trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          final colonIndex = trimmed.indexOf(':');
          if (colonIndex > 0) {
            final packageName = trimmed.substring(0, colonIndex).trim();
            final version = trimmed.substring(colonIndex + 1).trim();
            if (packageName.isNotEmpty && version.isNotEmpty) {
              dependencies[packageName] = version;
            }
          }
        }
      }
      
      result['dependencies'] = dependencies;
      return result;
    } catch (e) {
      return null;
    }
  }

  /// 필수 패키지가 pubspec.yaml에 올바르게 추가되었는지 확인합니다.
  /// 
  /// Returns:
  /// - `PubspecValidationResult`: 검증 결과
  static PubspecValidationResult validateRequiredPackages() {
    final pubspec = loadPubspec();
    if (pubspec == null) {
      return PubspecValidationResult(
        isValid: false,
        errorMessage: 'pubspec.yaml 파일을 읽을 수 없습니다.',
        missingPackages: requiredPackages.keys.toList(),
        incorrectVersions: {},
      );
    }

    final dependencies = pubspec['dependencies'] as Map?;
    if (dependencies == null) {
      return PubspecValidationResult(
        isValid: false,
        errorMessage: 'pubspec.yaml에 dependencies 섹션이 없습니다.',
        missingPackages: requiredPackages.keys.toList(),
        incorrectVersions: {},
      );
    }

    final missingPackages = <String>[];
    final incorrectVersions = <String, String>{};

    for (final entry in requiredPackages.entries) {
      final packageName = entry.key;
      final requiredVersion = entry.value;

      if (!dependencies.containsKey(packageName)) {
        missingPackages.add(packageName);
      } else {
        final actualVersion = dependencies[packageName].toString();
        // 버전 비교 (간단한 문자열 비교, ^ 기호 고려)
        if (!_isVersionCompatible(actualVersion, requiredVersion)) {
          incorrectVersions[packageName] = actualVersion;
        }
      }
    }

    final isValid = missingPackages.isEmpty && incorrectVersions.isEmpty;

    return PubspecValidationResult(
      isValid: isValid,
      errorMessage: isValid
          ? null
          : '필수 패키지가 누락되었거나 버전이 올바르지 않습니다.',
      missingPackages: missingPackages,
      incorrectVersions: incorrectVersions,
    );
  }

  /// 버전이 호환되는지 확인합니다.
  /// 
  /// 예: "^2.3.0"과 "2.3.0", "2.3.1", "2.4.0" 등은 호환됨
  static bool _isVersionCompatible(String actual, String required) {
    // ^ 기호 제거
    final actualClean = actual.replaceAll('^', '').trim();
    final requiredClean = required.replaceAll('^', '').trim();

    // 정확히 일치하는 경우
    if (actualClean == requiredClean) {
      return true;
    }

    // ^ 기호가 있는 경우 (주 버전이 같으면 호환)
    if (required.startsWith('^')) {
      final requiredParts = requiredClean.split('.');
      final actualParts = actualClean.split('.');

      if (requiredParts.isNotEmpty && actualParts.isNotEmpty) {
        // 주 버전이 같으면 호환
        return requiredParts[0] == actualParts[0];
      }
    }

    // 기본적으로 정확히 일치해야 함
    return actualClean == requiredClean;
  }

  /// 특정 패키지가 pubspec.yaml에 있는지 확인합니다.
  static bool hasPackage(String packageName) {
    final pubspec = loadPubspec();
    if (pubspec == null) return false;

    final dependencies = pubspec['dependencies'] as Map?;
    return dependencies?.containsKey(packageName) ?? false;
  }

  /// 특정 패키지의 버전을 가져옵니다.
  static String? getPackageVersion(String packageName) {
    final pubspec = loadPubspec();
    if (pubspec == null) return null;

    final dependencies = pubspec['dependencies'] as Map?;
    if (dependencies == null) return null;

    final version = dependencies[packageName];
    return version?.toString();
  }
}

/// pubspec.yaml 검증 결과
class PubspecValidationResult {
  /// 검증 통과 여부
  final bool isValid;

  /// 에러 메시지 (검증 실패 시)
  final String? errorMessage;

  /// 누락된 패키지 목록
  final List<String> missingPackages;

  /// 버전이 올바르지 않은 패키지 목록 (패키지명: 실제 버전)
  final Map<String, String> incorrectVersions;

  PubspecValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.missingPackages,
    required this.incorrectVersions,
  });

  @override
  String toString() {
    if (isValid) {
      return '✅ pubspec.yaml 검증 통과: 모든 필수 패키지가 올바르게 추가되었습니다.';
    }

    final buffer = StringBuffer();
    buffer.writeln('❌ pubspec.yaml 검증 실패:');
    if (errorMessage != null) {
      buffer.writeln('   $errorMessage');
    }
    if (missingPackages.isNotEmpty) {
      buffer.writeln('   누락된 패키지: ${missingPackages.join(", ")}');
    }
    if (incorrectVersions.isNotEmpty) {
      buffer.writeln('   버전이 올바르지 않은 패키지:');
      incorrectVersions.forEach((package, version) {
        buffer.writeln('     - $package: $version (필요: ${PubspecValidator.requiredPackages[package]})');
      });
    }
    return buffer.toString();
  }
}

