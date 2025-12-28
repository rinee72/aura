# Milestone 0: Work Package 상세 분해

## 📋 개요
**Milestone 목표**: 개발 환경 및 기본 아키텍처 설정  
**예상 기간**: 1주 (5일)  
**완료 기준**: Flutter 앱이 iOS/Android/Web에서 실행 가능하고, Supabase 연결 테스트 성공

---

## 🎯 Work Package 구조

```
WP-0.1: Flutter 멀티 플랫폼 프로젝트 초기화
WP-0.2: Supabase 프로젝트 생성 및 연결
WP-0.3: Git 저장소 및 협업 환경 구축
WP-0.4: 개발/스테이징/프로덕션 환경 분리
WP-0.5: 디자인 시스템 기본 구조 설정
WP-0.6: 프로젝트 문서화 및 검증
```

---

## 📦 WP-0.1: Flutter 멀티 플랫폼 프로젝트 초기화

### 목표
Flutter 프로젝트를 생성하고 iOS/Android/Web에서 실행 가능한 상태로 만들기

### 사용자 가치
개발자가 즉시 코드 작성을 시작할 수 있는 기반 제공

### 작업 내용
1. **Flutter 프로젝트 생성**
   ```bash
   flutter create aura_app --org com.aura --platforms=ios,android,web
   cd aura_app
   ```

2. **필수 의존성 추가** (pubspec.yaml)
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     supabase_flutter: ^2.3.0
     go_router: ^13.0.0
     provider: ^6.1.1
     flutter_dotenv: ^5.1.0
   
   dev_dependencies:
     flutter_test:
       sdk: flutter
     flutter_lints: ^3.0.0
   ```

3. **플랫폼별 기본 설정**
   - **iOS**: Info.plist 권한 설정
   - **Android**: Minimum SDK 21 설정, 인터넷 권한 추가
   - **Web**: index.html 메타 태그 설정

4. **실행 테스트**
   ```bash
   flutter run -d chrome  # Web
   flutter run -d ios     # iOS Simulator
   flutter run -d android # Android Emulator
   ```

### 완료 조건
- [ ] 3개 플랫폼 모두에서 기본 "Hello World" 화면 표시
- [ ] `flutter doctor` 결과 이슈 없음
- [ ] 의존성 설치 에러 없음

### 산출물
- `aura_app/` Flutter 프로젝트 폴더
- `pubspec.yaml` 설정 파일
- 각 플랫폼별 실행 스크린샷

### 예상 소요 시간
0.5일

---

## 📦 WP-0.2: Supabase 프로젝트 생성 및 연결

### 목표
Supabase 프로젝트를 생성하고 Flutter 앱과 연결하여 통신 테스트 완료

### 사용자 가치
백엔드 인프라가 준비되어 인증 및 데이터베이스 기능 개발 가능

### 작업 내용
1. **Supabase 프로젝트 생성**
   - [supabase.com](https://supabase.com)에서 새 프로젝트 생성
   - 프로젝트 이름: `aura-mvp-dev`
   - 리전: Asia Northeast (Seoul 또는 Tokyo)
   - 데이터베이스 비밀번호 안전하게 저장

2. **환경 변수 설정**
   - `.env.example` 파일 생성
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
   - `.env` 파일 생성 (실제 값 입력)
   - `.gitignore`에 `.env` 추가

3. **Supabase 초기화 코드 작성**
   ```dart
   // lib/core/supabase_config.dart
   import 'package:supabase_flutter/supabase_flutter.dart';
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   class SupabaseConfig {
     static Future<void> initialize() async {
       await dotenv.load();
       await Supabase.initialize(
         url: dotenv.env['SUPABASE_URL']!,
         anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
       );
     }
   }
   ```

4. **연결 테스트**
   - 간단한 Health Check API 호출
   ```dart
   // lib/main.dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await SupabaseConfig.initialize();
     
     // Test connection
     final supabase = Supabase.instance.client;
     print('Supabase connected: ${supabase.auth.currentUser == null}');
     
     runApp(MyApp());
   }
   ```

### 완료 조건
- [ ] Supabase 프로젝트 생성 완료
- [ ] Flutter 앱에서 Supabase 연결 성공 (콘솔 로그 확인)
- [ ] `.env` 파일이 `.gitignore`에 포함되어 커밋 안 됨

### 산출물
- Supabase 프로젝트 URL 및 키
- `lib/core/supabase_config.dart`
- `.env.example` 템플릿 파일
- 연결 테스트 성공 스크린샷

### 예상 소요 시간
0.5일

---

## 📦 WP-0.3: Git 저장소 및 협업 환경 구축

### 목표
Git 저장소를 생성하고 팀 협업을 위한 브랜치 전략 및 CI/CD 기본 파이프라인 구축

### 사용자 가치
팀원들이 충돌 없이 협업할 수 있고, 코드 품질이 자동으로 검증됨

### 작업 내용
1. **Git 저장소 초기화**
   ```bash
   git init
   git add .
   git commit -m "Initial project setup"
   ```

2. **GitHub/GitLab 저장소 생성**
   - Private repository 생성: `aura-mvp`
   - Remote 연결
   ```bash
   git remote add origin <repository-url>
   git push -u origin main
   ```

3. **브랜치 전략 수립**
   - `main`: 프로덕션 브랜치 (항상 배포 가능)
   - `develop`: 개발 통합 브랜치
   - `feature/*`: 기능 개발 브랜치
   - `hotfix/*`: 긴급 수정 브랜치

4. **GitHub Actions CI 파이프라인 설정**
   ```yaml
   # .github/workflows/flutter-ci.yml
   name: Flutter CI
   
   on:
     push:
       branches: [ main, develop ]
     pull_request:
       branches: [ main, develop ]
   
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v4
       - uses: subosito/flutter-action@v2
         with:
           flutter-version: '3.19.0'
       - run: flutter pub get
       - run: flutter analyze
       - run: flutter test
   ```

5. **Pull Request 템플릿 생성**
   ```markdown
   # .github/pull_request_template.md
   ## 변경 사항
   - [ ] 기능 추가
   - [ ] 버그 수정
   - [ ] 리팩토링
   
   ## 테스트 완료
   - [ ] 단위 테스트 통과
   - [ ] 수동 테스트 완료
   
   ## 스크린샷 (UI 변경 시)
   ```

### 완료 조건
- [ ] GitHub/GitLab 저장소에 코드 푸시 완료
- [ ] CI 파이프라인이 정상 작동 (첫 커밋에서 통과)
- [ ] 팀원 모두 저장소 접근 권한 부여 완료

### 산출물
- `.github/workflows/flutter-ci.yml`
- `CONTRIBUTING.md` (브랜치 전략 문서)
- PR 템플릿

### 예상 소요 시간
0.5일

---

## 📦 WP-0.4: 개발/스테이징/프로덕션 환경 분리

### 목표
3가지 환경을 분리하여 안전한 개발 및 배포 프로세스 구축

### 사용자 가치
프로덕션 데이터에 영향 없이 개발/테스트 가능

### 작업 내용
1. **Supabase 프로젝트 추가 생성**
   - `aura-mvp-dev` (Development)
   - `aura-mvp-staging` (Staging)
   - `aura-mvp-prod` (Production)

2. **환경별 설정 파일 생성**
   ```
   .env.development
   .env.staging
   .env.production
   ```

3. **Flutter 환경 분기 설정**
   ```dart
   // lib/core/environment.dart
   enum Environment { development, staging, production }
   
   class AppEnvironment {
     static Environment current = Environment.development;
     
     static String get supabaseUrl {
       switch (current) {
         case Environment.development:
           return dotenv.env['DEV_SUPABASE_URL']!;
         case Environment.staging:
           return dotenv.env['STAGING_SUPABASE_URL']!;
         case Environment.production:
           return dotenv.env['PROD_SUPABASE_URL']!;
       }
     }
     
     static String get supabaseKey {
       switch (current) {
         case Environment.development:
           return dotenv.env['DEV_SUPABASE_ANON_KEY']!;
         case Environment.staging:
           return dotenv.env['STAGING_SUPABASE_ANON_KEY']!;
         case Environment.production:
           return dotenv.env['PROD_SUPABASE_ANON_KEY']!;
       }
     }
   }
   ```

4. **실행 스크립트 작성**
   ```bash
   # scripts/run_dev.sh
   flutter run --dart-define=ENVIRONMENT=development
   
   # scripts/run_staging.sh
   flutter run --dart-define=ENVIRONMENT=staging
   ```

5. **환경별 앱 아이콘 구분**
   - Dev: 파란색 리본
   - Staging: 노란색 리본
   - Prod: 리본 없음

### 완료 조건
- [ ] 3개 환경 모두 Supabase 연결 테스트 성공
- [ ] 환경 전환 시 올바른 Supabase 프로젝트 연결 확인
- [ ] 환경별 앱 아이콘이 다르게 표시됨

### 산출물
- `lib/core/environment.dart`
- `.env.development`, `.env.staging`, `.env.production` (템플릿)
- `scripts/run_dev.sh`, `scripts/run_staging.sh`
- 환경별 설정 문서

### 예상 소요 시간
1일

---

## 📦 WP-0.5: 디자인 시스템 기본 구조 설정

### 목표
일관된 UI를 위한 기본 디자인 토큰 및 공통 컴포넌트 라이브러리 구축

### 사용자 가치
일관된 UI/UX로 개발 속도 향상 및 디자인 부채 최소화

### 작업 내용
1. **디자인 토큰 정의**
   ```dart
   // lib/core/theme/app_colors.dart
   class AppColors {
     static const primary = Color(0xFF6366F1);      // Indigo
     static const secondary = Color(0xFFF59E0B);    // Amber
     static const background = Color(0xFFF9FAFB);
     static const surface = Color(0xFFFFFFFF);
     static const error = Color(0xFFEF4444);
     
     static const textPrimary = Color(0xFF111827);
     static const textSecondary = Color(0xFF6B7280);
   }
   
   // lib/core/theme/app_typography.dart
   class AppTypography {
     static const h1 = TextStyle(
       fontSize: 32,
       fontWeight: FontWeight.bold,
     );
     static const body1 = TextStyle(
       fontSize: 16,
       fontWeight: FontWeight.normal,
     );
     // ... 더 많은 스타일
   }
   ```

2. **Material Theme 설정**
   ```dart
   // lib/core/theme/app_theme.dart
   ThemeData get lightTheme => ThemeData(
     useMaterial3: true,
     colorScheme: ColorScheme.fromSeed(
       seedColor: AppColors.primary,
     ),
     textTheme: TextTheme(
       displayLarge: AppTypography.h1,
       bodyLarge: AppTypography.body1,
     ),
   );
   ```

3. **공통 컴포넌트 제작**
   ```dart
   // lib/shared/widgets/custom_button.dart
   class CustomButton extends StatelessWidget {
     final String label;
     final VoidCallback onPressed;
     final bool isLoading;
     
     @override
     Widget build(BuildContext context) {
       return ElevatedButton(
         onPressed: isLoading ? null : onPressed,
         child: isLoading 
           ? CircularProgressIndicator() 
           : Text(label),
       );
     }
   }
   
   // lib/shared/widgets/custom_text_field.dart
   class CustomTextField extends StatelessWidget {
     final String label;
     final TextEditingController controller;
     
     @override
     Widget build(BuildContext context) {
       return TextField(
         controller: controller,
         decoration: InputDecoration(
           labelText: label,
           border: OutlineInputBorder(),
         ),
       );
     }
   }
   ```

4. **컴포넌트 카탈로그 페이지 작성**
   ```dart
   // lib/dev/component_showcase.dart
   class ComponentShowcase extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('Component Showcase')),
         body: ListView(
           children: [
             CustomButton(label: 'Primary Button', onPressed: () {}),
             CustomTextField(label: 'Text Input'),
             // ... 모든 컴포넌트 시연
           ],
         ),
       );
     }
   }
   ```

### 완료 조건
- [ ] 디자인 토큰 (색상, 타이포그래피, 간격) 정의 완료
- [ ] 최소 5개 공통 컴포넌트 제작 (버튼, 텍스트필드, 카드, 로딩, 에러 위젯)
- [ ] 컴포넌트 카탈로그 페이지에서 모든 컴포넌트 확인 가능

### 산출물
- `lib/core/theme/` 폴더 (색상, 타이포그래피, 테마)
- `lib/shared/widgets/` 폴더 (공통 컴포넌트)
- `lib/dev/component_showcase.dart`
- Figma/Sketch 디자인 시스템 링크 (있으면)

### 예상 소요 시간
1일

---

## 📦 WP-0.6: 프로젝트 문서화 및 검증

### 목표
프로젝트 구조를 문서화하고 모든 설정이 정상 작동하는지 최종 검증

### 사용자 가치
신규 개발자가 빠르게 온보딩할 수 있고, 전체 팀이 일관된 컨벤션을 따름

### 작업 내용
1. **프로젝트 폴더 구조 확정**
   ```
   aura_app/
   ├── lib/
   │   ├── core/               # 핵심 설정 및 유틸리티
   │   │   ├── theme/
   │   │   ├── environment.dart
   │   │   └── supabase_config.dart
   │   ├── features/           # 기능별 모듈
   │   │   ├── auth/
   │   │   ├── questions/
   │   │   └── profile/
   │   ├── shared/             # 공통 위젯 및 유틸
   │   │   ├── widgets/
   │   │   └── utils/
   │   └── main.dart
   ├── test/
   ├── assets/
   └── docs/
   ```

2. **README.md 작성**
   ```markdown
   # AURA MVP - 셀럽-팬 소통 플랫폼
   
   ## 시작하기
   1. Flutter 3.19 이상 설치
   2. `flutter pub get`
   3. `.env` 파일 설정 (`.env.example` 참고)
   4. `flutter run`
   
   ## 브랜치 전략
   - `main`: 프로덕션
   - `develop`: 개발 통합
   - `feature/*`: 기능 개발
   
   ## 폴더 구조
   (상세 설명)
   ```

3. **코딩 컨벤션 문서 작성**
   ```markdown
   # docs/CODING_CONVENTIONS.md
   
   ## Dart 스타일 가이드
   - 파일명: snake_case
   - 클래스명: PascalCase
   - 변수명: camelCase
   - 상수명: lowerCamelCase (Dart 권장)
   
   ## 폴더 구조
   - Features: 도메인별로 분리
   - Shared: 2개 이상 기능에서 사용
   
   ## Git Commit 메시지
   - feat: 새 기능
   - fix: 버그 수정
   - docs: 문서 수정
   - refactor: 리팩토링
   ```

4. **개발 환경 세팅 가이드**
   ```markdown
   # docs/DEVELOPMENT_SETUP.md
   
   ## 필수 도구
   - Flutter 3.19+
   - Xcode (iOS)
   - Android Studio (Android)
   - VS Code + Flutter extension
   
   ## Supabase 설정
   1. 계정 생성
   2. 프로젝트 키 복사
   3. `.env` 파일에 붙여넣기
   ```

5. **최종 검증 체크리스트**
   - [ ] 3개 플랫폼 실행 테스트
   - [ ] Supabase 연결 테스트
   - [ ] CI 파이프라인 통과
   - [ ] 환경 전환 테스트
   - [ ] 컴포넌트 카탈로그 정상 표시
   - [ ] 팀원 개발 환경 세팅 완료

### 완료 조건
- [ ] `README.md`, `CODING_CONVENTIONS.md`, `DEVELOPMENT_SETUP.md` 작성 완료
- [ ] 최종 검증 체크리스트 100% 완료
- [ ] 팀원 전체가 로컬 환경에서 앱 실행 성공

### 산출물
- `README.md`
- `docs/CODING_CONVENTIONS.md`
- `docs/DEVELOPMENT_SETUP.md`
- `docs/ARCHITECTURE.md` (폴더 구조 상세 설명)
- 최종 검증 보고서

### 예상 소요 시간
0.5일

---

## 📊 Work Package 요약

| WP ID | 제목 | 소요 시간 | 의존성 | 우선순위 |
|-------|------|-----------|--------|----------|
| WP-0.1 | Flutter 프로젝트 초기화 | 0.5일 | 없음 | P0 |
| WP-0.2 | Supabase 연결 | 0.5일 | WP-0.1 | P0 |
| WP-0.3 | Git 저장소 구축 | 0.5일 | WP-0.1 | P0 |
| WP-0.4 | 환경 분리 | 1일 | WP-0.2 | P1 |
| WP-0.5 | 디자인 시스템 | 1일 | WP-0.1 | P1 |
| WP-0.6 | 문서화 및 검증 | 0.5일 | 전체 | P2 |
| **합계** | | **4일** | | |

**버퍼**: 1일 (예비 시간)

---

## ✅ Milestone 0 완료 기준 (재확인)

### 기능 측면
- [x] Flutter 앱이 iOS/Android/Web에서 실행됨
- [x] Supabase 연결 테스트 성공
- [x] 3개 환경(dev/staging/prod) 분리 완료

### 품질 측면
- [x] CI 파이프라인 통과
- [x] 코드 컨벤션 문서화
- [x] 디자인 시스템 기본 컴포넌트 5개 이상

### 협업 측면
- [x] Git 저장소 정상 작동
- [x] 팀원 모두 개발 환경 세팅 완료
- [x] 문서화 완료 (README + 개발 가이드)

---

## 🎯 다음 단계 (Milestone 1 Preview)

Milestone 0 완료 후 바로 진행할 작업:
- **M1-WP-1.1**: 데이터베이스 스키마 설계
- **M1-WP-1.2**: Supabase Auth 연동
- **M1-WP-1.3**: Role-based Access Control 구현

---

## 💡 주요 원칙 재확인

### Vertical Slicing ✅
- 각 WP는 실행 가능한 소프트웨어를 생성합니다
- WP-0.1: Flutter 앱 실행됨
- WP-0.2: Supabase 통신됨
- WP-0.5: 컴포넌트 카탈로그 페이지 작동

### 완결성 ✅
- 모든 WP 종료 시 "동작하는" 상태입니다
- WP-0.6까지 완료하면 M1 개발 즉시 시작 가능

### 사용자 가치 전달 ✅
- 개발자(내부 사용자)가 즉시 생산성 향상
- 협업 마찰 최소화
- 기술 부채 조기 방지
