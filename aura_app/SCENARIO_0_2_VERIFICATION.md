# WP-0.2 시나리오 검증 가이드

## 목적
WP-0.2 시나리오 문서의 모든 요구사항을 검증하여 Supabase 프로젝트 생성 및 연결이 올바르게 구현되었는지 확인합니다.

## 검증 방법

### 방법 1: 유닛 테스트 실행
```bash
cd aura_app
flutter test test/core/supabase_config_test.dart
flutter test test/shared/utils/env_validator_test.dart
```

### 방법 2: 통합 테스트 실행 (실제 .env 파일 필요)
```bash
cd aura_app
flutter test test/integration/scenario_0_2_test.dart
```

### 방법 3: PowerShell 스크립트 실행
```powershell
cd aura_app
.\scripts\verify_scenario_0_2.ps1
```

### 방법 4: 수동 검증

#### Scenario 0.2-4: .env.example 파일 생성 성공
```bash
# .env.example 파일 확인
cat .env.example

# 예상 내용:
# SUPABASE_URL=https://your-project.supabase.co
# SUPABASE_ANON_KEY=your-anon-key
```

#### Scenario 0.2-5: .env 파일에 올바른 Supabase 설정 추가 후 로드 성공
```bash
# 1. .env.example 복사
cp .env.example .env

# 2. .env 파일 편집하여 실제 Supabase URL 및 Anon Key 입력
# (Supabase 대시보드 > Settings > API에서 확인)

# 3. Flutter 앱 실행하여 환경 변수 로드 확인
flutter run -d chrome

# 예상 결과:
# - 콘솔에 "✅ Supabase 초기화 성공" 메시지 출력
# - "✅ Supabase 연결 테스트 성공" 메시지 출력
```

#### Scenario 0.2-6: .env 파일에 잘못된 URL/키 입력 시 로드 실패
```bash
# 1. .env 파일에 잘못된 URL 입력
# SUPABASE_URL=https://invalid-url.com

# 2. Flutter 앱 실행
flutter run -d chrome

# 예상 결과:
# - "SUPABASE_URL 형식이 올바르지 않습니다" 에러 메시지 출력
# - 앱은 계속 실행되지만 Supabase 기능은 사용할 수 없음
```

#### Scenario 0.2-7: .gitignore 확인
```bash
# .gitignore 파일 확인
cat .gitignore | grep "\.env"

# 예상 결과:
# .env
# .env.development
# .env.staging
# .env.production

# Git 상태 확인
git status

# 예상 결과:
# .env 파일이 추적 대상에 포함되지 않음
```

#### Scenario 0.2-8: SupabaseConfig 클래스 생성 및 초기화 코드 작성 성공
```bash
# 파일 존재 확인
ls lib/core/supabase_config.dart

# 코드 분석
flutter analyze lib/core/supabase_config.dart

# 예상 결과:
# 에러 없음
```

#### Scenario 0.2-9: main.dart에서 Supabase 초기화 호출 성공
```bash
# main.dart 파일 확인
cat lib/main.dart | grep "SupabaseConfig"

# 예상 결과:
# SupabaseConfig.initialize() 호출 확인
```

#### Scenario 0.2-10: 환경 변수 없이 초기화 시도 시 실패
```bash
# 1. .env 파일 임시로 이름 변경
mv .env .env.backup

# 2. Flutter 앱 실행
flutter run -d chrome

# 예상 결과:
# - ".env 파일을 찾을 수 없습니다" 에러 메시지 출력
# - 앱은 계속 실행되지만 Supabase 기능은 사용할 수 없음

# 3. .env 파일 복구
mv .env.backup .env
```

#### Scenario 0.2-11: Flutter 앱에서 Supabase 연결 성공 (Health Check)
```bash
# 1. .env 파일에 올바른 설정 입력
# 2. Flutter 앱 실행
flutter run -d chrome

# 예상 결과:
# - 콘솔에 "✅ Supabase 초기화 성공" 메시지 출력
# - "✅ Supabase 연결 확인: 인증되지 않음 (정상)" 메시지 출력
# - "✅ Supabase 연결 테스트 성공" 메시지 출력
# - 에러 없이 앱이 정상 실행됨
```

#### Scenario 0.2-12: 잘못된 URL로 연결 시도 시 실패
```bash
# 1. .env 파일에 잘못된 URL 입력
# SUPABASE_URL=https://invalid-url.com

# 2. Flutter 앱 실행
flutter run -d chrome

# 예상 결과:
# - "SUPABASE_URL 형식이 올바르지 않습니다" 에러 메시지 출력
# - 초기화 실패
```

#### Scenario 0.2-13: 잘못된 Anon Key로 연결 시도 시 실패
```bash
# 1. .env 파일에 잘못된 Anon Key 입력
# SUPABASE_ANON_KEY=invalid-key

# 2. Flutter 앱 실행
flutter run -d chrome

# 예상 결과:
# - 초기화는 성공하지만 API 호출 시 실패
# - "Invalid API key" 또는 "Unauthorized" 에러 발생
```

#### Scenario 0.2-14: 네트워크 연결 없이 연결 시도 시 실패
```bash
# 1. 네트워크 연결 끊기 (Wi-Fi/이더넷 비활성화)
# 2. Flutter 앱 실행
flutter run -d chrome

# 예상 결과:
# - "네트워크 연결 오류" 또는 "Connection timeout" 에러 발생
# - 연결 실패
```

## 검증 기준

### 코드 레벨 검증
- ✅ `.env.example` 파일 존재 및 내용 확인
- ✅ `SupabaseConfig` 클래스 생성 및 구현
- ✅ `main.dart`에서 초기화 호출
- ✅ 에러 처리 구현
- ✅ `.gitignore`에 `.env` 포함

### 실제 테스트 검증
- ✅ `.env` 파일에 올바른 설정 입력 후 로드 성공
- ✅ 잘못된 URL/키 입력 시 적절한 에러 메시지 출력
- ✅ 실제 Supabase 연결 성공 (Health Check)
- ✅ 네트워크 에러 처리

## 관련 파일
- `lib/core/supabase_config.dart`: Supabase 초기화 및 설정 관리
- `lib/shared/utils/env_validator.dart`: 환경 변수 검증 유틸리티
- `test/core/supabase_config_test.dart`: SupabaseConfig 유닛 테스트
- `test/shared/utils/env_validator_test.dart`: EnvValidator 유닛 테스트
- `test/integration/scenario_0_2_test.dart`: WP-0.2 통합 테스트
- `scripts/verify_scenario_0_2.ps1`: 검증 스크립트

