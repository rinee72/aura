# 환경 설정 가이드 (Environment Setup Guide)

## 📋 개요

WP-0.4: 개발/스테이징/프로덕션 환경 분리

AURA 프로젝트는 3가지 환경을 지원합니다:
- **Development**: 개발 환경 (로컬 개발 및 테스트)
- **Staging**: 스테이징 환경 (배포 전 최종 테스트)
- **Production**: 프로덕션 환경 (실제 사용자 대상 서비스)

각 환경은 독립적인 Supabase 프로젝트를 사용하여 데이터를 분리합니다.

---

## 🚀 빠른 시작

### 1. 환경별 설정 파일 생성

각 환경에 맞는 `.env` 파일을 생성하세요:

```bash
# 개발 환경
cp .env.development.example .env.development

# 스테이징 환경
cp .env.staging.example .env.staging

# 프로덕션 환경
cp .env.production.example .env.production
```

### 2. Supabase 프로젝트 생성

각 환경에 맞는 Supabase 프로젝트를 생성하세요:

- **Development**: `aura-mvp-dev`
- **Staging**: `aura-mvp-staging`
- **Production**: `aura-mvp-prod`

### 3. 환경 파일에 설정 입력

각 `.env` 파일에 해당 환경의 Supabase URL과 Anon Key를 입력하세요:

**`.env.development` 예시:**
```env
DEV_SUPABASE_URL=https://your-dev-project.supabase.co
DEV_SUPABASE_ANON_KEY=your-dev-anon-key-here
```

**`.env.staging` 예시:**
```env
STAGING_SUPABASE_URL=https://your-staging-project.supabase.co
STAGING_SUPABASE_ANON_KEY=your-staging-anon-key-here
```

**`.env.production` 예시:**
```env
PROD_SUPABASE_URL=https://your-prod-project.supabase.co
PROD_SUPABASE_ANON_KEY=your-prod-anon-key-here
```

### 4. 앱 실행

#### 방법 1: PowerShell 스크립트 사용 (권장)

```powershell
# 개발 환경
.\scripts\run_dev.ps1

# 스테이징 환경
.\scripts\run_staging.ps1

# 프로덕션 환경
.\scripts\run_prod.ps1
```

#### 방법 2: Flutter 명령어 직접 사용

```bash
# 개발 환경
flutter run --dart-define=ENVIRONMENT=development

# 스테이징 환경
flutter run --dart-define=ENVIRONMENT=staging

# 프로덕션 환경
flutter run --dart-define=ENVIRONMENT=production
```

---

## 📁 파일 구조

```
aura_app/
├── .env.development.example      # 개발 환경 템플릿
├── .env.staging.example          # 스테이징 환경 템플릿
├── .env.production.example       # 프로덕션 환경 템플릿
├── .env.development              # 개발 환경 설정 (Git 제외)
├── .env.staging                  # 스테이징 환경 설정 (Git 제외)
├── .env.production               # 프로덕션 환경 설정 (Git 제외)
├── lib/
│   └── core/
│       ├── environment.dart      # 환경 관리 클래스
│       └── supabase_config.dart  # Supabase 설정 (환경별 지원)
└── scripts/
    ├── run_dev.ps1               # 개발 환경 실행 스크립트
    ├── run_staging.ps1           # 스테이징 환경 실행 스크립트
    └── run_prod.ps1              # 프로덕션 환경 실행 스크립트
```

---

## 🔧 환경 변수

### 개발 환경 (Development)

| 변수명 | 설명 | 예시 |
|--------|------|------|
| `DEV_SUPABASE_URL` | 개발 Supabase 프로젝트 URL | `https://your-dev-project.supabase.co` |
| `DEV_SUPABASE_ANON_KEY` | 개발 Supabase Anon Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |

### 스테이징 환경 (Staging)

| 변수명 | 설명 | 예시 |
|--------|------|------|
| `STAGING_SUPABASE_URL` | 스테이징 Supabase 프로젝트 URL | `https://your-staging-project.supabase.co` |
| `STAGING_SUPABASE_ANON_KEY` | 스테이징 Supabase Anon Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |

### 프로덕션 환경 (Production)

| 변수명 | 설명 | 예시 |
|--------|------|------|
| `PROD_SUPABASE_URL` | 프로덕션 Supabase 프로젝트 URL | `https://your-prod-project.supabase.co` |
| `PROD_SUPABASE_ANON_KEY` | 프로덕션 Supabase Anon Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |

### 하위 호환성

기존 `SUPABASE_URL`과 `SUPABASE_ANON_KEY`도 지원합니다. 환경별 변수가 없으면 기본 변수를 사용합니다.

---

## 🎨 환경별 앱 아이콘 구분

### 현재 상태

앱 실행 시 화면에 환경 배지가 표시됩니다:
- **Development**: 파란색 배지
- **Staging**: 주황색 배지
- **Production**: 배지 없음

### 향후 개선 (선택사항)

앱 아이콘에 환경별 리본을 추가할 수 있습니다:
- **Dev**: 파란색 리본
- **Staging**: 노란색 리본
- **Prod**: 리본 없음

이 기능은 나중에 구현할 수 있습니다.

---

## 🔍 환경 확인

### 코드에서 환경 확인

```dart
import 'package:aura_app/core/environment.dart';

// 현재 환경 확인
final currentEnv = AppEnvironment.current;
print('현재 환경: ${AppEnvironment.environmentName}');

// 환경별 분기
if (AppEnvironment.isDevelopment) {
  // 개발 환경 전용 코드
} else if (AppEnvironment.isStaging) {
  // 스테이징 환경 전용 코드
} else if (AppEnvironment.isProduction) {
  // 프로덕션 환경 전용 코드
}

// 환경별 앱 제목
final title = AppEnvironment.appTitle; // "AURA (Dev)", "AURA (Staging)", "AURA"
```

### Supabase URL/Key 가져오기

```dart
import 'package:aura_app/core/environment.dart';

// 현재 환경의 Supabase URL
final url = AppEnvironment.supabaseUrl;

// 현재 환경의 Supabase Anon Key
final key = AppEnvironment.supabaseAnonKey;
```

---

## ✅ 검증

### 환경별 연결 테스트

각 환경에서 앱을 실행하고 다음을 확인하세요:

1. **환경 설정 확인**
   ```
   ✅ 환경 설정 완료: development
      환경 파일: .env.development
   ```

2. **Supabase 연결 확인**
   ```
   ✅ Supabase 초기화 성공
      환경: development
      URL: https://your-dev-project.supabase.co
   ```

3. **화면에서 환경 배지 확인**
   - 개발 환경: 파란색 배지 표시
   - 스테이징 환경: 주황색 배지 표시
   - 프로덕션 환경: 배지 없음

---

## 🚨 주의사항

### 프로덕션 환경

- ⚠️ **프로덕션 환경은 실제 사용자 데이터를 사용합니다**
- 프로덕션 환경에서 테스트할 때는 신중하게 진행하세요
- 프로덕션 데이터를 변경하거나 삭제하지 마세요

### 환경 파일 보안

- `.env.development`, `.env.staging`, `.env.production` 파일은 `.gitignore`에 포함되어 있습니다
- 절대 Git에 커밋하지 마세요
- 팀원과 공유할 때는 안전한 방법을 사용하세요 (예: 비밀 관리 도구)

### 환경 전환

- 환경을 전환할 때는 앱을 재시작하세요
- 환경 파일이 올바르게 로드되었는지 확인하세요

---

## 📚 관련 문서

- [WP-0.4: 개발/스테이징/프로덕션 환경 분리](../docs/roadmap/Milestone_0_Work_Packages.md#-wp-04-개발스테이징프로덕션-환경-분리)
- [Supabase 설정 가이드](../lib/core/supabase_config.dart)
- [환경 관리 클래스](../lib/core/environment.dart)

---

## 🐛 문제 해결

### 환경 파일을 찾을 수 없음

**문제**: `환경 파일을 로드할 수 없습니다` 오류

**해결**:
1. `.env.development.example`을 복사하여 `.env.development` 파일 생성
2. 파일에 올바른 Supabase URL과 Anon Key 입력
3. `pubspec.yaml`에 환경 파일이 assets로 등록되어 있는지 확인

### 잘못된 환경 연결

**문제**: 다른 환경의 Supabase에 연결됨

**해결**:
1. `--dart-define=ENVIRONMENT=development` 형식이 올바른지 확인
2. 환경 파일의 변수명이 올바른지 확인 (예: `DEV_SUPABASE_URL`)
3. 앱을 재시작하여 환경 설정이 다시 로드되도록 함

### 환경 배지가 표시되지 않음

**문제**: 화면에 환경 배지가 표시되지 않음

**해결**:
1. `AppEnvironment.initializeFromDartDefine()`가 호출되었는지 확인
2. `main.dart`에서 환경 초기화가 올바르게 수행되었는지 확인
3. Hot Reload 대신 Hot Restart 사용

---

**작성일**: 2024년  
**작성자**: AI Assistant  
**버전**: 1.0.0

