# GitHub 업로드 가이드 - 리팩토링 전 백업

## 📋 총 파일 수: 약 279개 (100개 제한으로 3-4번에 나누어 업로드)

---

## 🎯 1차 업로드: 핵심 소스 코드 및 설정 파일 (약 80-90개)

### 필수 설정 파일
- `.gitignore`
- `aura_app/pubspec.yaml`
- `aura_app/pubspec.lock`
- `aura_app/analysis_options.yaml`

### 핵심 소스 코드
- `aura_app/lib/` 폴더 전체 (모든 .dart 파일)
  - `lib/main.dart`
  - `lib/core/` 폴더 전체
  - `lib/features/` 폴더 전체
  - `lib/shared/` 폴더 전체
  - `lib/dev/` 폴더 전체

### 필수 문서
- `aura_app/README.md`
- `aura_app/CONTRIBUTING.md`
- `aura_app/docs/ARCHITECTURE.md`
- `aura_app/docs/CODING_CONVENTIONS.md`
- `aura_app/docs/ENVIRONMENT_SETUP.md`

**커밋 메시지**: `feat: Add core source code and configuration files`

---

## 🎯 2차 업로드: 테스트 및 데이터베이스 (약 50-60개)

### 테스트 코드
- `aura_app/test/` 폴더 전체 (모든 .dart 파일)

### 데이터베이스 마이그레이션
- `aura_app/supabase/migrations/` 폴더 전체 (모든 .sql 파일)
- `aura_app/supabase/functions/` 폴더 전체

### 추가 문서
- `docs/` 폴더의 모든 파일
  - `docs/roadmap/` 폴더 전체
  - `docs/core/` 폴더 전체
  - `docs/*.md` 파일들

**커밋 메시지**: `feat: Add tests, database migrations, and documentation`

---

## 🎯 3차 업로드: 스크립트 및 플랫폼 설정 (약 50-60개)

### 스크립트 파일
- `aura_app/scripts/` 폴더 전체 (모든 .ps1 파일)
- `aura_app/*.bat` 파일들
- `aura_app/*.cmd` 파일들

### Android 설정
- `aura_app/android/app/build.gradle`
- `aura_app/android/build.gradle`
- `aura_app/android/settings.gradle`
- `aura_app/android/gradle.properties`
- `aura_app/android/local.properties.example`
- `aura_app/android/gradle/wrapper/gradle-wrapper.properties`
- `aura_app/android/app/src/main/AndroidManifest.xml`
- `aura_app/android/app/src/main/kotlin/` 폴더의 .kt 파일들

### iOS 설정
- `aura_app/ios/Podfile`
- `aura_app/ios/Runner/Info.plist`
- `aura_app/ios/Runner/Runner.entitlements`
- `aura_app/ios/Runner/AppDelegate.swift`
- `aura_app/ios/Runner.xcodeproj/project.pbxproj`

### Web 설정
- `aura_app/web/index.html`
- `aura_app/web/manifest.json`

**커밋 메시지**: `feat: Add scripts and platform configuration files`

---

## 🎯 4차 업로드: 나머지 문서 및 리소스 (약 50-60개)

### 나머지 문서 파일
- `aura_app/*.md` 파일들 (모든 마크다운 파일)
  - 검증 리포트 파일들
  - 가이드 문서들
  - 시나리오 문서들

### 리소스 파일 (있는 경우)
- `aura_app/assets/` 폴더 (이미지, 폰트 등)

### 기타 설정 파일
- `aura_app/aura_app.iml`
- `aura_app/component_preview.html`
- `aura_app/RUN_APP.txt`

**커밋 메시지**: `docs: Add remaining documentation and resources`

---

## ⚠️ 제외할 파일들 (.gitignore에 이미 포함됨)

다음 파일들은 업로드하지 마세요:
- `build/` 폴더
- `aura_app/flutter/` 폴더 (Flutter SDK)
- `*.log` 파일들
- `.env` 파일들
- `.dart_tool/` 폴더
- `.idea/`, `.vscode/` 폴더
- `android/local.properties` (실제 파일, 예제만 업로드)

---

## 📝 업로드 방법

1. GitHub 웹사이트에서 저장소로 이동
2. "Add file" → "Upload files" 클릭
3. 위의 각 단계별 파일들을 선택 (100개 미만)
4. 커밋 메시지 입력
5. "Commit changes" 클릭
6. 다음 단계로 진행

---

## ✅ 업로드 완료 확인

모든 단계를 완료한 후:
- GitHub에서 파일들이 모두 보이는지 확인
- 각 폴더 구조가 올바르게 표시되는지 확인
- 리팩토링 전 상태가 백업되었는지 확인

