# AURA MVP - 셀럽-팬 소통 플랫폼

## 📋 프로젝트 개요

AURA는 셀럽과 팬이 건강하게 소통할 수 있는 플랫폼입니다.

**핵심 가치**: 셀럽 피로도 최소화 + 팬 경험 극대화 + 안전한 소통 환경

---

## 🚀 시작하기

### 필수 요구사항

- **Flutter**: 3.19 이상
- **Dart**: 3.0 이상
- **Node.js**: (선택) Supabase CLI 사용 시

### 설치 및 실행

#### 1. 저장소 클론

```bash
git clone <repository-url>
cd aura_app
```

#### 2. 의존성 설치

```bash
flutter pub get
```

#### 3. 환경 변수 설정

각 환경에 맞는 `.env` 파일을 생성하세요:

```bash
# 개발 환경
cp .env.development.example .env.development

# 스테이징 환경
cp .env.staging.example .env.staging

# 프로덕션 환경
cp .env.production.example .env.production
```

각 `.env` 파일에 Supabase URL과 Anon Key를 입력하세요. 자세한 내용은 [환경 설정 가이드](docs/ENVIRONMENT_SETUP.md)를 참고하세요.

#### 4. 앱 실행

**방법 1: PowerShell 스크립트 사용 (권장)**

```powershell
# 개발 환경
.\scripts\run_dev.ps1

# 스테이징 환경
.\scripts\run_staging.ps1

# 프로덕션 환경
.\scripts\run_prod.ps1
```

**방법 2: Flutter 명령어 직접 사용**

```bash
# 개발 환경 - Web
flutter run -d chrome --dart-define=ENVIRONMENT=development

# 개발 환경 - iOS (macOS만)
flutter run -d ios --dart-define=ENVIRONMENT=development

# 개발 환경 - Android
flutter run -d android --dart-define=ENVIRONMENT=development
```

---

## 📁 프로젝트 구조

```
aura_app/
├── lib/                    # 소스 코드
│   ├── core/              # 핵심 설정 및 유틸리티
│   │   ├── theme/        # 디자인 토큰 (색상, 타이포그래피, 간격)
│   │   ├── environment.dart  # 환경 관리
│   │   └── supabase_config.dart  # Supabase 설정
│   ├── features/          # 기능별 모듈 (도메인별 분리)
│   │   ├── auth/         # 인증 기능
│   │   ├── questions/    # 질문 기능
│   │   └── profile/      # 프로필 기능
│   ├── shared/           # 공통 위젯 및 유틸
│   │   ├── widgets/     # 공통 위젯
│   │   └── utils/       # 공통 유틸리티
│   ├── dev/              # 개발 전용 코드
│   │   └── component_showcase.dart  # 컴포넌트 카탈로그
│   └── main.dart         # 앱 진입점
├── test/                  # 테스트 코드
├── assets/                # 이미지, 폰트 등 리소스
├── docs/                  # 프로젝트 문서
│   ├── CODING_CONVENTIONS.md  # 코딩 컨벤션
│   ├── ARCHITECTURE.md       # 아키텍처 문서
│   └── ENVIRONMENT_SETUP.md  # 환경 설정 가이드
├── scripts/               # 유틸리티 스크립트
└── pubspec.yaml           # 의존성 관리
```

자세한 폴더 구조 설명은 [아키텍처 문서](docs/ARCHITECTURE.md)를 참고하세요.

---

## 🌿 브랜치 전략

프로젝트는 Git Flow를 기반으로 한 브랜치 전략을 사용합니다.

### 주요 브랜치

- **`main`**: 프로덕션 브랜치 (항상 배포 가능한 상태)
- **`develop`**: 개발 통합 브랜치 (다음 릴리스를 위한 통합)

### 보조 브랜치

- **`feature/*`**: 기능 개발 브랜치 (예: `feature/user-authentication`)
- **`hotfix/*`**: 긴급 수정 브랜치 (예: `hotfix/critical-bug-fix`)
- **`release/*`**: 릴리스 준비 브랜치 (예: `release/v1.0.0`)

자세한 내용은 [기여 가이드](CONTRIBUTING.md)를 참고하세요.

---

## 🛠️ 기술 스택

- **프레임워크**: Flutter 3.19+ (iOS, Android, Web)
- **백엔드**: Supabase (Auth, Database, Storage, Realtime)
- **라우팅**: Go Router
- **상태 관리**: Provider
- **환경 변수**: flutter_dotenv

---

## 📚 문서

- [코딩 컨벤션](docs/CODING_CONVENTIONS.md) - 코드 스타일 및 네이밍 규칙
- [아키텍처 문서](docs/ARCHITECTURE.md) - 폴더 구조 및 아키텍처 원칙
- [환경 설정 가이드](docs/ENVIRONMENT_SETUP.md) - 개발/스테이징/프로덕션 환경 설정
- [기여 가이드](CONTRIBUTING.md) - 브랜치 전략 및 개발 워크플로우

---

## 🧪 테스트

```bash
# 모든 테스트 실행
flutter test

# 특정 테스트 파일 실행
flutter test test/features/auth/auth_test.dart

# 커버리지 확인
flutter test --coverage
```

---

## 🔧 개발 도구

### 코드 포맷팅

```bash
dart format .
```

### 코드 분석

```bash
flutter analyze
```

### 의존성 업데이트

```bash
flutter pub outdated
flutter pub upgrade
```

---

## 🐛 문제 해결

### 일반적인 문제

**문제**: `flutter pub get` 실패  
**해결**: Flutter SDK 버전 확인 (`flutter --version`)

**문제**: 환경 변수를 찾을 수 없음  
**해결**: `.env.development.example`을 복사하여 `.env.development` 파일 생성

**문제**: Supabase 연결 실패  
**해결**: 환경 파일의 URL과 Anon Key 확인

자세한 문제 해결 방법은 각 문서를 참고하세요.

---

## 📝 라이선스

이 프로젝트는 비공개 프로젝트입니다.

---

## 👥 기여하기

프로젝트에 기여하고 싶으시다면 [기여 가이드](CONTRIBUTING.md)를 먼저 읽어주세요.

---

## 📞 문의

프로젝트에 대한 질문이 있으시면 GitHub Issues에 이슈를 생성해주세요.

---

**작성일**: 2024년  
**버전**: 1.0.0

