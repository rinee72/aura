# Scenario 0.1-4 검증 가이드

## 📋 Scenario 개요

**Scenario**: 0.1-4  
**제목**: pubspec.yaml에 필수 패키지 추가 후 정상 설치

### 요구사항
- **Given**: Flutter 프로젝트가 생성되어 있음
- **When**: 
  - `pubspec.yaml`에 다음 패키지 추가:
    ```yaml
    dependencies:
      supabase_flutter: ^2.3.0
      go_router: ^13.0.0
      provider: ^6.1.1
      flutter_dotenv: ^5.1.0
    ```
  - `flutter pub get` 명령어 실행
- **Then**: 
  - 모든 패키지가 성공적으로 다운로드됨
  - `.dart_tool/package_config.json` 파일에 패키지 정보 존재
  - "Got dependencies!" 메시지 출력
  - 종료 코드 0 반환
- **선행 Scenario**: 0.1-1

---

## 🔍 검증 방법

### 방법 1: 유닛 테스트 실행

pubspec.yaml 검증 및 패키지 설치 검증 로직을 테스트합니다:

```bash
cd aura_app
flutter test test/shared/utils/pubspec_validator_test.dart
flutter test test/shared/utils/package_installer_test.dart
```

또는 Dart 테스트 실행:

```bash
cd aura_app
dart test test/shared/utils/pubspec_validator_test.dart
dart test test/shared/utils/package_installer_test.dart
```

**예상 결과**: 모든 테스트 통과

---

### 방법 2: 통합 테스트 실행 (Flutter SDK 필요)

실제 Flutter CLI를 사용하여 검증합니다:

```bash
cd aura_app
flutter test test/integration/scenario_0_1_4_test.dart
```

**주의**: Flutter SDK가 설치되어 있어야 합니다.

---

### 방법 3: PowerShell 스크립트 실행 (Flutter SDK 필요)

자동화된 검증 스크립트를 실행합니다:

```powershell
cd aura_app
.\scripts\verify_scenario_0_1_4.ps1
```

**주의**: Flutter SDK가 설치되어 있어야 합니다.

---

### 방법 4: 수동 검증 (Flutter SDK 필요)

직접 Flutter CLI 명령어를 실행합니다:

```bash
# 1. pubspec.yaml에 필수 패키지 확인
cat pubspec.yaml | grep -E "supabase_flutter|go_router|provider|flutter_dotenv"

# 2. flutter pub get 실행
flutter pub get

# 예상 결과:
# - "Got dependencies!" 메시지 출력
# - 종료 코드 0 반환
# - .dart_tool/package_config.json 파일 생성/업데이트

# 3. package_config.json 확인
cat .dart_tool/package_config.json | grep -E "supabase_flutter|go_router|provider|flutter_dotenv"
```

---

## ✅ 검증 기준

다음 조건들이 모두 충족되어야 Scenario 0.1-4가 통과한 것으로 간주됩니다:

1. ✅ **필수 패키지 추가**: pubspec.yaml에 다음 패키지가 모두 추가되어 있음
   - `supabase_flutter: ^2.3.0`
   - `go_router: ^13.0.0`
   - `provider: ^6.1.1`
   - `flutter_dotenv: ^5.1.0`

2. ✅ **패키지 설치 성공**: `flutter pub get` 명령어의 exit code가 0

3. ✅ **성공 메시지 출력**: "Got dependencies!" 또는 유사한 메시지 출력

4. ✅ **package_config.json 존재**: `.dart_tool/package_config.json` 파일이 생성됨

5. ✅ **패키지 정보 확인**: package_config.json에 필수 패키지 정보가 포함됨

---

## 📁 관련 파일

### 구현 파일
- `lib/shared/utils/pubspec_validator.dart`: pubspec.yaml 검증 유틸리티
  - pubspec.yaml 파일 읽기 및 파싱
  - 필수 패키지 존재 확인
  - 패키지 버전 확인
  - 검증 결과 제공

- `lib/shared/utils/package_installer.dart`: 패키지 설치 검증 유틸리티
  - flutter pub get 실행
  - package_config.json 확인
  - 패키지 설치 검증

### 테스트 파일
- `test/shared/utils/pubspec_validator_test.dart`: 유닛 테스트
  - Scenario 0.1-4의 모든 검증 케이스 포함
  - pubspec.yaml 검증 테스트
  - 필수 패키지 확인 테스트

- `test/shared/utils/package_installer_test.dart`: 유닛 테스트
  - 패키지 설치 검증 테스트
  - package_config.json 확인 테스트

- `test/integration/scenario_0_1_4_test.dart`: 통합 테스트
  - 실제 Flutter CLI를 사용한 검증
  - flutter pub get 실행 및 결과 검증

### 검증 스크립트
- `scripts/verify_scenario_0_1_4.ps1`: PowerShell 검증 스크립트
  - 자동화된 검증 프로세스
  - Flutter SDK 설치 확인
  - pubspec.yaml 검증
  - flutter pub get 실행 및 결과 검증
  - package_config.json 확인

---

## 🎯 Scenario 0.1-4의 목적

이 Scenario는 **의존성 관리 검증**을 목적으로 합니다:

1. **필수 패키지 추가 확인**
   - 프로젝트에 필요한 핵심 패키지가 올바르게 추가되었는지 확인
   - 패키지 버전이 올바른지 확인

2. **패키지 설치 검증**
   - flutter pub get이 성공적으로 실행되는지 확인
   - 패키지가 올바르게 다운로드되었는지 확인

3. **의존성 관리 시스템 검증**
   - Flutter의 의존성 관리 시스템이 올바르게 작동하는지 확인
   - package_config.json 파일이 올바르게 생성되는지 확인

---

## 📊 검증 결과 예시

### 성공 케이스

```
✅ Flutter SDK 설치 확인됨
✅ pubspec.yaml 파일 존재 확인
✅ 모든 필수 패키지가 pubspec.yaml에 추가되어 있음
✅ 검증 통과: flutter pub get 성공 (exit code: 0)
✅ 검증 통과: 'Got dependencies!' 또는 유사한 메시지 확인
✅ 검증 통과: .dart_tool/package_config.json 파일 존재
✅ 검증 통과: 모든 필수 패키지가 package_config.json에 존재
✅ Scenario 0.1-4 검증 완료: 모든 검증 통과
```

### 실패 케이스

```
❌ 패키지 누락: supabase_flutter
❌ 다음 패키지가 pubspec.yaml에 없습니다: supabase_flutter
```

---

## 🔧 문제 해결

### Flutter SDK가 설치되어 있지 않은 경우

1. **Flutter SDK 설치**: [Flutter 공식 사이트](https://flutter.dev/docs/get-started/install)에서 설치 가이드 확인
2. **유닛 테스트 실행**: Flutter SDK 없이도 pubspec.yaml 검증 로직은 테스트 가능

### 패키지 설치 실패

1. **인터넷 연결 확인**: 패키지 다운로드를 위해 인터넷 연결 필요
2. **pubspec.yaml 확인**: 패키지 이름 및 버전이 올바른지 확인
3. **캐시 정리**: `flutter pub cache repair` 실행

### package_config.json이 생성되지 않는 경우

1. **flutter pub get 재실행**: `flutter pub get` 명령어 다시 실행
2. **.dart_tool 폴더 확인**: `.dart_tool` 폴더가 생성되었는지 확인
3. **권한 확인**: 파일 쓰기 권한 확인

---

## 📝 참고 자료

- [Flutter 패키지 관리 가이드](https://flutter.dev/docs/development/packages-and-plugins/using-packages)
- [pubspec.yaml 파일 형식](https://dart.dev/tools/pub/pubspec)
- `docs/roadmap/WP_0_1_Scenarios.md`: Scenario 상세 문서

---

## 🔄 관련 Scenario

- **Scenario 0.1-1**: Flutter CLI로 멀티 플랫폼 프로젝트 생성 성공 (선행 Scenario)
- **Scenario 0.1-5**: 존재하지 않는 패키지 버전 추가 시 실패 (실패 케이스)
- **Scenario 0.1-6**: 의존성 충돌 발생 시 에러 메시지 확인 (실패 케이스)

---

## 💡 사용 예시

### pubspec.yaml 검증

```dart
import 'package:aura_app/shared/utils/pubspec_validator.dart';

// 필수 패키지 검증
final result = PubspecValidator.validateRequiredPackages();
if (result.isValid) {
  print('✅ 모든 필수 패키지가 올바르게 추가되었습니다.');
} else {
  print(result.toString());
}

// 특정 패키지 확인
final hasSupabase = PubspecValidator.hasPackage('supabase_flutter');
print('supabase_flutter 존재: $hasSupabase');
```

### 패키지 설치 검증

```dart
import 'package:aura_app/shared/utils/package_installer.dart';

// 패키지 설치
final installResult = await PackageInstaller.installPackages();
if (installResult.isSuccess) {
  print('✅ 패키지 설치 성공');
} else {
  print('❌ 패키지 설치 실패: ${installResult.errorMessage}');
}

// 설치 검증
final verification = await PackageInstaller.verifyInstallation();
if (verification.isSuccess) {
  print('✅ 모든 필수 패키지가 설치되었습니다.');
} else {
  print('❌ 일부 패키지가 설치되지 않았습니다.');
}
```

