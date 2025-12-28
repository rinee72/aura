# Scenario 0.1-2 검증 가이드

## 📋 Scenario 개요

**Scenario 0.1-2**: 잘못된 프로젝트명으로 생성 시도 시 실패

### 요구사항
- **Given**: Flutter SDK 3.19 이상이 설치되어 있음
- **When**: `flutter create 123InvalidName` 명령어 실행 (숫자로 시작하는 프로젝트명)
- **Then**: 
  - 프로젝트 생성 실패
  - "Invalid project name" 에러 메시지 출력
  - 프로젝트 폴더가 생성되지 않음

---

## 🔍 검증 방법

### 방법 1: 유닛 테스트 실행 (Flutter SDK 불필요)

프로젝트명 검증 로직을 테스트합니다:

```bash
cd aura_app
flutter test test/shared/utils/project_name_validator_test.dart
```

또는 Dart 테스트 실행:

```bash
cd aura_app
dart test test/shared/utils/project_name_validator_test.dart
```

**예상 결과**: 모든 테스트 통과

---

### 방법 2: 통합 테스트 실행 (Flutter SDK 필요)

실제 Flutter CLI를 사용하여 검증합니다:

```bash
cd aura_app
flutter test test/integration/scenario_0_1_2_test.dart
```

**주의**: Flutter SDK가 설치되어 있어야 합니다. 미설치 시 테스트는 자동으로 건너뜁니다.

---

### 방법 3: PowerShell 스크립트 실행 (Flutter SDK 필요)

자동화된 검증 스크립트를 실행합니다:

```powershell
cd aura_app
.\scripts\verify_scenario_0_1_2.ps1
```

**주의**: Flutter SDK가 설치되어 있어야 합니다.

---

### 방법 4: 수동 검증 (Flutter SDK 필요)

직접 Flutter CLI 명령어를 실행합니다:

```bash
# 잘못된 프로젝트명으로 프로젝트 생성 시도
flutter create 123InvalidName

# 예상 결과:
# - 프로젝트 생성 실패 (exit code != 0)
# - "Invalid project name" 또는 유사한 에러 메시지 출력
# - 프로젝트 폴더가 생성되지 않음
```

---

## ✅ 검증 기준

다음 조건들이 모두 충족되어야 Scenario 0.1-2가 통과한 것으로 간주됩니다:

1. ✅ **프로젝트 생성 실패**: `flutter create` 명령어의 exit code가 0이 아님
2. ✅ **에러 메시지 출력**: "Invalid", "error", 또는 "cannot" 등의 키워드가 포함된 에러 메시지 출력
3. ✅ **프로젝트 폴더 미생성**: `123InvalidName` 폴더가 생성되지 않음

---

## 📁 관련 파일

### 구현 파일
- `lib/shared/utils/project_name_validator.dart`: 프로젝트명 검증 유틸리티
  - Flutter 프로젝트명 규칙을 따르는 검증 로직
  - 숫자로 시작하는 프로젝트명 검증
  - Dart 키워드 검증
  - 문자 형식 검증

### 테스트 파일
- `test/shared/utils/project_name_validator_test.dart`: 유닛 테스트
  - Scenario 0.1-2의 모든 검증 케이스 포함
  - 숫자로 시작하는 프로젝트명 검증 테스트
  - 다양한 잘못된 프로젝트명 케이스 테스트
  - 유효한 프로젝트명 케이스 테스트

- `test/integration/scenario_0_1_2_test.dart`: 통합 테스트
  - 실제 Flutter CLI를 사용한 검증
  - Flutter SDK 설치 여부 자동 확인

### 검증 스크립트
- `scripts/verify_scenario_0_1_2.ps1`: PowerShell 검증 스크립트
  - 자동화된 검증 프로세스
  - Flutter SDK 설치 확인
  - 프로젝트 생성 시도 및 결과 검증
  - 자동 정리

---

## 🎯 Scenario 0.1-2의 목적

이 Scenario는 **실패 케이스 검증**을 목적으로 합니다:

1. **Flutter CLI의 프로젝트명 검증 기능 확인**
   - 잘못된 프로젝트명 입력 시 적절한 에러 처리
   - 사용자에게 명확한 에러 메시지 제공

2. **프로젝트명 규칙 준수 확인**
   - 숫자로 시작하는 프로젝트명은 허용되지 않음
   - Flutter/Dart의 프로젝트명 규칙 준수

3. **안전한 프로젝트 생성 보장**
   - 잘못된 프로젝트명으로 인한 문제 사전 방지
   - 개발 환경의 일관성 유지

---

## 📊 검증 결과 예시

### 성공 케이스

```
✅ 검증 통과: 프로젝트 생성 실패 (exit code: 1)
✅ 검증 통과: 에러 메시지 확인
✅ 검증 통과: 프로젝트 폴더가 생성되지 않음
✅ Scenario 0.1-2 검증 완료: 모든 검증 통과
```

### 실패 케이스

```
❌ 검증 실패: 프로젝트 생성이 성공했지만 실패해야 합니다.
❌ 검증 실패: 프로젝트 폴더 '123InvalidName'가 생성되었습니다.
```

---

## 🔧 문제 해결

### Flutter SDK가 설치되어 있지 않은 경우

1. **유닛 테스트 실행**: Flutter SDK 없이도 프로젝트명 검증 로직을 테스트할 수 있습니다.
   ```bash
   dart test test/shared/utils/project_name_validator_test.dart
   ```

2. **Flutter SDK 설치**: 통합 테스트 및 실제 CLI 검증을 위해서는 Flutter SDK 설치가 필요합니다.
   - [Flutter 공식 사이트](https://flutter.dev/docs/get-started/install)에서 설치 가이드 확인

### 테스트 실행 오류

1. **의존성 설치**: `flutter pub get` 실행
2. **테스트 파일 확인**: 테스트 파일 경로 확인
3. **Flutter 버전 확인**: `flutter --version`으로 버전 확인

---

## 📝 참고 자료

- [Flutter 프로젝트 생성 가이드](https://flutter.dev/docs/get-started/test-drive)
- [Dart 프로젝트명 규칙](https://dart.dev/guides/language/effective-dart/style#do-name-libraries-and-source-files-using-lowercase_with_underscores)
- `docs/roadmap/WP_0_1_Scenarios.md`: Scenario 상세 문서

