# 프로젝트 아키텍처 (Architecture)

이 문서는 AURA 프로젝트의 폴더 구조와 아키텍처 원칙을 상세히 설명합니다.

---

## 📋 목차

- [프로젝트 구조 개요](#프로젝트-구조-개요)
- [폴더 구조 상세](#폴더-구조-상세)
- [아키텍처 원칙](#아키텍처-원칙)
- [의존성 규칙](#의존성-규칙)
- [상태 관리](#상태-관리)
- [라우팅](#라우팅)

---

## 🏗️ 프로젝트 구조 개요

AURA 프로젝트는 **Feature-First Architecture**를 따릅니다. 각 기능은 독립적인 모듈로 구성되며, 공통 코드는 `shared` 폴더에 배치됩니다.

```
aura_app/
├── lib/                    # 소스 코드
│   ├── core/              # 핵심 설정 및 유틸리티
│   ├── features/          # 기능별 모듈 (도메인별 분리)
│   ├── shared/            # 공통 위젯 및 유틸
│   └── main.dart          # 앱 진입점
├── test/                  # 테스트 코드
├── assets/                # 이미지, 폰트 등 리소스
├── docs/                  # 프로젝트 문서
├── scripts/               # 유틸리티 스크립트
└── pubspec.yaml           # 의존성 관리
```

---

## 📁 폴더 구조 상세

### lib/ 폴더

#### core/

앱 전역에서 사용되는 핵심 설정 및 유틸리티입니다.

```
core/
├── theme/                 # 디자인 시스템 토큰
│   ├── app_colors.dart   # 색상 정의
│   ├── app_typography.dart  # 타이포그래피 정의
│   ├── app_spacing.dart  # 간격 정의
│   └── app_theme.dart    # Material Theme 설정
├── environment.dart       # 환경 관리 (dev/staging/prod)
└── supabase_config.dart   # Supabase 초기화 및 설정
```

**책임**:
- 앱 전역 설정 관리
- 디자인 토큰 정의
- 외부 서비스 초기화

**사용 규칙**:
- 다른 폴더에서 `core`를 참조할 수 있음
- `core`는 다른 폴더를 참조하지 않음 (순환 의존성 방지)

#### features/

기능별로 완전히 분리된 모듈입니다. 각 기능은 독립적으로 개발 및 테스트 가능합니다.

```
features/
├── auth/                 # 인증 기능
│   ├── models/          # User, Role 등 데이터 모델
│   ├── providers/       # AuthProvider 등 상태 관리
│   ├── screens/         # LoginScreen, SignupScreen 등
│   ├── widgets/         # 기능 전용 위젯
│   ├── services/        # AuthService 등 비즈니스 로직
│   └── auth.dart        # 기능 진입점 (export)
├── questions/           # 질문 기능
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── widgets/
│   ├── services/
│   └── questions.dart
└── profile/             # 프로필 기능
    ├── models/
    ├── providers/
    ├── screens/
    ├── widgets/
    ├── services/
    └── profile.dart
```

**각 Feature 폴더 구조**:

1. **models/**: 데이터 모델 클래스
   - 예: `user_model.dart`, `question_model.dart`

2. **providers/**: 상태 관리 (Provider 패턴)
   - 예: `auth_provider.dart`, `question_provider.dart`

3. **screens/**: 화면 위젯 (전체 페이지)
   - 예: `login_screen.dart`, `question_list_screen.dart`

4. **widgets/**: 기능 전용 위젯 (재사용 가능한 UI 컴포넌트)
   - 예: `question_card.dart`, `answer_form.dart`

5. **services/**: 비즈니스 로직 및 API 호출
   - 예: `auth_service.dart`, `question_service.dart`

6. **{feature}.dart**: 기능 진입점 (export 파일)
   ```dart
   // features/auth/auth.dart
   export 'models/user_model.dart';
   export 'providers/auth_provider.dart';
   export 'screens/login_screen.dart';
   // ...
   ```

**책임**:
- 특정 도메인의 모든 기능 구현
- 독립적인 개발 및 테스트 가능

**사용 규칙**:
- Feature 간 직접 참조 금지 (느슨한 결합)
- 공통 코드는 `shared`로 이동
- Feature 내부는 자유롭게 참조 가능

#### shared/

2개 이상의 기능에서 사용되는 공통 코드입니다.

```
shared/
├── widgets/              # 공통 위젯
│   ├── custom_button.dart
│   ├── custom_text_field.dart
│   ├── custom_card.dart
│   ├── custom_loading.dart
│   └── custom_error.dart
└── utils/                # 공통 유틸리티
    ├── env_validator.dart
    ├── flutter_sdk_checker.dart
    └── ...
```

**책임**:
- 여러 기능에서 공통으로 사용되는 코드 제공
- 재사용 가능한 UI 컴포넌트
- 공통 유틸리티 함수

**사용 규칙**:
- 1개 기능에서만 사용되면 해당 기능 폴더에 배치
- 2개 이상에서 사용되면 `shared`로 이동
- `shared`는 `core`를 참조할 수 있음
- `shared`는 `features`를 참조하지 않음

#### dev/

개발 전용 코드입니다. 프로덕션 빌드에서는 제외됩니다.

```
dev/
└── component_showcase.dart  # 디자인 시스템 컴포넌트 카탈로그
```

**책임**:
- 개발 중 디버깅 및 테스트 도구
- 컴포넌트 카탈로그 등 개발자 도구

**사용 규칙**:
- 개발 환경에서만 접근 가능
- 프로덕션 빌드에서 제외

---

## 🎯 아키텍처 원칙

### 1. Feature-First Architecture

각 기능은 완전히 독립적인 모듈로 구성됩니다.

**장점**:
- 기능별로 독립적인 개발 가능
- 코드 탐색이 쉬움
- 기능 삭제 시 영향 범위가 명확함

**예시**:
```dart
// ✅ 좋은 예: Feature 내부에서 자유롭게 참조
// features/auth/screens/login_screen.dart
import '../models/user_model.dart';
import '../services/auth_service.dart';

// ❌ 나쁜 예: Feature 간 직접 참조
// features/questions/screens/question_list_screen.dart
import '../../auth/models/user_model.dart';  // 금지!
```

### 2. 계층 분리

각 계층은 명확한 책임을 가집니다.

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Screens, Widgets)                 │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Business Logic Layer         │
│  (Providers, Services)              │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Data Layer                   │
│  (Models, API Clients)               │
└─────────────────────────────────────┘
```

### 3. 의존성 역전 원칙 (DIP)

구체적인 구현보다 추상화에 의존합니다.

**예시**:
```dart
// ✅ 좋은 예: 인터페이스 사용
abstract class AuthService {
  Future<User> login(String email, String password);
}

class SupabaseAuthService implements AuthService {
  @override
  Future<User> login(String email, String password) {
    // Supabase 구현
  }
}

// ❌ 나쁜 예: 구체적인 구현에 직접 의존
class LoginScreen extends StatelessWidget {
  final SupabaseAuthService authService;  // 구체적 클래스에 의존
}
```

---

## 🔗 의존성 규칙

### 허용되는 의존성

```
core ← shared ← features
```

- `features` → `shared` ✅
- `features` → `core` ✅
- `shared` → `core` ✅
- `core` → (없음) ✅

### 금지되는 의존성

- `core` → `features` ❌
- `core` → `shared` ❌
- `shared` → `features` ❌
- `features` → `features` ❌ (Feature 간 직접 참조)

### 예외

- `dev/` 폴더는 모든 폴더를 참조할 수 있음 (개발 전용)

---

## 📊 상태 관리

### Provider 패턴 사용

각 Feature는 자체 Provider를 가집니다.

**예시**:
```dart
// features/auth/providers/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  
  User? get currentUser => _currentUser;
  
  Future<void> login(String email, String password) async {
    // 로그인 로직
    _currentUser = await authService.login(email, password);
    notifyListeners();
  }
}
```

**사용**:
```dart
// features/auth/screens/login_screen.dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      body: ElevatedButton(
        onPressed: () => authProvider.login(email, password),
        child: Text('로그인'),
      ),
    );
  }
}
```

---

## 🧭 라우팅

### Go Router 사용

`lib/core/router/app_router.dart`에서 모든 라우트를 관리합니다.

**라우트 구조**:
```dart
// core/router/app_router.dart
final appRouter = GoRouter(
  routes: [
    // 인증
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => SignupScreen()),
    
    // 팬
    GoRoute(path: '/fan/home', builder: (context, state) => FanHomeScreen()),
    GoRoute(path: '/fan/questions', builder: (context, state) => QuestionListScreen()),
    
    // 셀럽
    GoRoute(path: '/celebrity/dashboard', builder: (context, state) => CelebrityDashboardScreen()),
    
    // 매니저
    GoRoute(path: '/manager/dashboard', builder: (context, state) => ManagerDashboardScreen()),
  ],
);
```

**역할별 라우팅**:
- 로그인 후 사용자 역할에 따라 적절한 화면으로 리다이렉트
- 미인증 사용자는 로그인 화면으로 리다이렉트

---

## 🎨 디자인 시스템

### 디자인 토큰

`lib/core/theme/` 폴더에 디자인 토큰이 정의되어 있습니다.

- **색상**: `app_colors.dart`
- **타이포그래피**: `app_typography.dart`
- **간격**: `app_spacing.dart`
- **테마**: `app_theme.dart`

**사용 예시**:
```dart
import 'package:aura_app/core/theme/app_colors.dart';
import 'package:aura_app/core/theme/app_typography.dart';

Container(
  color: AppColors.primary,
  padding: EdgeInsets.all(AppSpacing.md),
  child: Text(
    'Hello',
    style: AppTypography.h1,
  ),
)
```

### 공통 컴포넌트

`lib/shared/widgets/` 폴더에 공통 위젯이 정의되어 있습니다.

- `CustomButton`: 버튼 컴포넌트
- `CustomTextField`: 텍스트 입력 필드
- `CustomCard`: 카드 컴포넌트
- `CustomLoading`: 로딩 인디케이터
- `CustomError`: 에러 메시지 표시

---

## 🔒 보안 및 권한

### Row Level Security (RLS)

Supabase의 RLS 정책을 사용하여 데이터 접근을 제어합니다.

**원칙**:
- 팬: 자신의 질문/구독 조회/작성 가능
- 셀럽: 질문 조회, 자신의 답변 작성/수정 가능
- 매니저: 모든 데이터 조회, 질문 숨기기 가능

### 클라이언트 측 권한 체크

`lib/shared/utils/permission_checker.dart`에서 권한을 체크합니다.

---

## 🧪 테스트 구조

테스트 코드는 소스 코드와 동일한 구조를 따릅니다.

```
test/
├── features/           # 기능별 테스트
│   ├── auth/
│   └── questions/
├── shared/             # 공통 유틸리티 테스트
└── integration/        # 통합 테스트
```

---

## 📚 참고 자료

- [Flutter 아키텍처 가이드](https://docs.flutter.dev/development/data-and-backend/state-mgmt/options)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Feature-First Architecture](https://medium.com/flutter-community/flutter-architecture-blueprints-a1f4b3a6b370)

---

## ✅ 체크리스트

새로운 기능을 추가할 때 다음 사항을 확인하세요:

- [ ] Feature 폴더 구조를 올바르게 따름
- [ ] Feature 간 직접 참조가 없음
- [ ] 공통 코드는 `shared`에 배치
- [ ] Provider 패턴을 사용하여 상태 관리
- [ ] 라우트가 `app_router.dart`에 등록됨
- [ ] 디자인 토큰을 사용하여 스타일링
- [ ] 테스트 코드 작성

---

**작성일**: 2024년  
**작성자**: AI Assistant  
**버전**: 1.0.0
