# 코딩 컨벤션 (Coding Conventions)

이 문서는 AURA 프로젝트의 코딩 스타일과 컨벤션을 정의합니다. 모든 개발자는 이 가이드를 따르는 것을 권장합니다.

---

## 📋 목차

- [Dart 스타일 가이드](#dart-스타일-가이드)
- [파일 및 폴더 구조](#파일-및-폴더-구조)
- [네이밍 규칙](#네이밍-규칙)
- [코드 포맷팅](#코드-포맷팅)
- [주석 및 문서화](#주석-및-문서화)
- [Git Commit 메시지](#git-commit-메시지)
- [테스트 작성 규칙](#테스트-작성-규칙)

---

## 🎨 Dart 스타일 가이드

### 파일명

- **스타일**: `snake_case.dart`
- **예시**: 
  - ✅ `user_profile_screen.dart`
  - ✅ `supabase_config.dart`
  - ✅ `custom_button.dart`
  - ❌ `UserProfileScreen.dart`
  - ❌ `userProfileScreen.dart`

### 클래스명

- **스타일**: `PascalCase`
- **예시**:
  - ✅ `UserProfileScreen`
  - ✅ `SupabaseConfig`
  - ✅ `CustomButton`
  - ❌ `userProfileScreen`
  - ❌ `user_profile_screen`

### 변수명 및 함수명

- **스타일**: `camelCase`
- **예시**:
  - ✅ `userName`
  - ✅ `getUserProfile()`
  - ✅ `isLoading`
  - ❌ `user_name`
  - ❌ `get_user_profile()`

### 상수명

- **스타일**: `lowerCamelCase` (Dart 권장)
- **예시**:
  - ✅ `const maxRetryCount = 3;`
  - ✅ `const defaultTimeout = Duration(seconds: 30);`
  - ❌ `const MAX_RETRY_COUNT = 3;` (Dart에서는 권장하지 않음)

### Private 멤버

- **스타일**: `_leadingUnderscore`
- **예시**:
  - ✅ `_userName`
  - ✅ `_loadData()`
  - ✅ `_isInitialized`

### 타입 매개변수

- **스타일**: 단일 대문자 또는 의미있는 이름
- **예시**:
  - ✅ `List<T>`
  - ✅ `Future<User>`
  - ✅ `Map<String, dynamic>`

---

## 📁 파일 및 폴더 구조

### 프로젝트 루트 구조

```
aura_app/
├── lib/                    # 소스 코드
│   ├── core/              # 핵심 설정 및 유틸리티
│   ├── features/          # 기능별 모듈
│   ├── shared/            # 공통 위젯 및 유틸
│   └── main.dart          # 앱 진입점
├── test/                  # 테스트 코드
├── assets/                # 이미지, 폰트 등 리소스
├── docs/                  # 프로젝트 문서
├── scripts/               # 유틸리티 스크립트
└── pubspec.yaml           # 의존성 관리
```

### lib/ 폴더 구조

```
lib/
├── core/                  # 앱 전역 설정
│   ├── theme/            # 디자인 토큰 (색상, 타이포그래피, 간격)
│   ├── environment.dart  # 환경 관리
│   └── supabase_config.dart  # Supabase 설정
├── features/             # 기능별 모듈 (도메인별 분리)
│   ├── auth/            # 인증 기능
│   ├── questions/       # 질문 기능
│   └── profile/         # 프로필 기능
├── shared/               # 공통 코드 (2개 이상 기능에서 사용)
│   ├── widgets/        # 공통 위젯
│   └── utils/          # 공통 유틸리티
└── main.dart            # 앱 진입점
```

### Features 폴더 구조

각 기능(feature)은 다음 구조를 따릅니다:

```
features/
└── auth/
    ├── models/          # 데이터 모델
    ├── providers/       # 상태 관리 (Provider, Riverpod 등)
    ├── screens/         # 화면 위젯
    ├── widgets/         # 기능 전용 위젯
    ├── services/        # 비즈니스 로직 및 API 호출
    └── auth.dart        # 기능 진입점 (export)
```

### 파일 배치 원칙

1. **Core**: 앱 전역에서 사용되는 설정 및 유틸리티만 포함
2. **Features**: 도메인별로 완전히 분리된 모듈
3. **Shared**: 2개 이상의 기능에서 사용되는 코드만 포함
   - 1개 기능에서만 사용되면 해당 기능 폴더에 배치
   - 2개 이상에서 사용되면 shared로 이동

---

## 🏷️ 네이밍 규칙

### 폴더명

- **스타일**: `snake_case` 또는 `lowercase`
- **예시**:
  - ✅ `user_profile/`
  - ✅ `auth/`
  - ✅ `shared_widgets/`

### 위젯 파일

- **파일명**: `snake_case.dart`
- **클래스명**: `PascalCase` (파일명과 일치 권장)
- **예시**:
  - 파일: `user_profile_screen.dart`
  - 클래스: `UserProfileScreen`

### 서비스 파일

- **파일명**: `snake_case_service.dart` 또는 `snake_case.dart`
- **클래스명**: `PascalCase` + `Service` (선택)
- **예시**:
  - 파일: `user_service.dart`
  - 클래스: `UserService`

### 모델 파일

- **파일명**: `snake_case_model.dart` 또는 `snake_case.dart`
- **클래스명**: `PascalCase`
- **예시**:
  - 파일: `user_model.dart`
  - 클래스: `UserModel`

### 테스트 파일

- **파일명**: `snake_case_test.dart`
- **예시**:
  - 소스: `lib/features/auth/screens/login_screen.dart`
  - 테스트: `test/features/auth/screens/login_screen_test.dart`

---

## 🎯 코드 포맷팅

### 자동 포맷팅

```bash
# 코드 포맷팅
dart format .

# 특정 파일만 포맷팅
dart format lib/main.dart
```

### 포맷팅 규칙

- **라인 길이**: 최대 80자 (가독성을 위해)
- **들여쓰기**: 2칸 스페이스
- **세미콜론**: 항상 사용
- **중괄호**: Dart 스타일 가이드 준수

### 예시

```dart
// ✅ 좋은 예
class UserProfileScreen extends StatelessWidget {
  final String userId;
  
  const UserProfileScreen({
    super.key,
    required this.userId,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: Center(
        child: Text('사용자 ID: $userId'),
      ),
    );
  }
}

// ❌ 나쁜 예
class UserProfileScreen extends StatelessWidget{
final String userId;
const UserProfileScreen({super.key,required this.userId});
@override Widget build(BuildContext context){
return Scaffold(appBar:AppBar(title:Text('프로필')),body:Center(child:Text('사용자 ID: $userId')));
}
}
```

---

## 💬 주석 및 문서화

### 문서 주석 (Documentation Comments)

공개 API는 문서 주석을 작성합니다:

```dart
/// 사용자 프로필을 표시하는 화면입니다.
/// 
/// [userId]를 받아 해당 사용자의 프로필 정보를 표시합니다.
/// 
/// 사용 예:
/// ```dart
/// UserProfileScreen(userId: '123')
/// ```
class UserProfileScreen extends StatelessWidget {
  /// 사용자 고유 ID
  final String userId;
  
  // ...
}
```

### 인라인 주석

복잡한 로직에만 주석을 추가합니다:

```dart
// 좋은 예: 복잡한 로직 설명
// Supabase RLS 정책에 따라 팬은 자신의 질문만 수정 가능
if (user.role == UserRole.fan && question.userId != user.id) {
  throw PermissionDeniedException();
}

// 나쁜 예: 명확한 코드에 불필요한 주석
// userId 변수에 사용자 ID를 저장
final userId = user.id;
```

### TODO 주석

임시 코드나 향후 개선 사항은 TODO 주석을 사용합니다:

```dart
// TODO: 성능 최적화 필요 - 현재 N+1 쿼리 발생
// TODO(작성자명): 캐싱 로직 추가
```

---

## 📝 Git Commit 메시지

### Conventional Commits 규칙

커밋 메시지는 [Conventional Commits](https://www.conventionalcommits.org/) 규칙을 따릅니다.

### 형식

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- **`feat`**: 새 기능 추가
- **`fix`**: 버그 수정
- **`docs`**: 문서 수정
- **`style`**: 코드 포맷팅, 세미콜론 누락 등 (코드 변경 없음)
- **`refactor`**: 리팩토링 (기능 변경 없음)
- **`test`**: 테스트 코드 추가/수정
- **`chore`**: 빌드 설정, 패키지 관리 등
- **`perf`**: 성능 개선
- **`ci`**: CI/CD 설정 변경

### Scope (선택)

- `auth`: 인증 관련
- `questions`: 질문 기능
- `ui`: UI 컴포넌트
- `config`: 설정 관련
- `docs`: 문서

### 예시

```bash
# 기능 추가
feat(auth): 사용자 로그인 기능 추가

- Supabase Auth 연동
- 로그인 화면 UI 구현
- 에러 처리 추가

Closes #123

# 버그 수정
fix(questions): 질문 목록 무한 스크롤 버그 수정

페이지네이션 로직 개선으로 무한 스크롤 문제 해결

Fixes #456

# 문서 수정
docs: README.md에 환경 설정 가이드 추가

# 리팩토링
refactor(auth): 인증 로직을 Provider로 분리
```

---

## 🧪 테스트 작성 규칙

### 테스트 파일 구조

```
test/
├── features/           # 기능별 테스트
│   ├── auth/
│   └── questions/
├── shared/             # 공통 유틸리티 테스트
└── integration/        # 통합 테스트
```

### 테스트 네이밍

- **파일명**: `snake_case_test.dart`
- **그룹명**: 기능별로 그룹화
- **테스트명**: `should_<expected_behavior>_when_<condition>`

### 예시

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_app/features/auth/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should_create_user_when_valid_data_provided', () {
      // Given
      final user = UserModel(
        id: '123',
        email: 'test@example.com',
        role: UserRole.fan,
      );
      
      // Then
      expect(user.id, '123');
      expect(user.email, 'test@example.com');
      expect(user.role, UserRole.fan);
    });
    
    test('should_throw_exception_when_invalid_email_provided', () {
      // Given & Then
      expect(
        () => UserModel(
          id: '123',
          email: 'invalid-email',
          role: UserRole.fan,
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
```

### 테스트 커버리지

- 최소 70% 이상의 코드 커버리지 목표
- 핵심 비즈니스 로직은 100% 커버리지 권장

---

## 🔍 코드 분석

### Flutter Analyze

```bash
# 코드 분석 실행
flutter analyze

# 특정 경로만 분석
flutter analyze lib/features/auth
```

### 분석 규칙

- `analysis_options.yaml` 파일에 정의된 규칙 준수
- 경고는 가능한 모두 해결
- 에러는 반드시 해결

---

## 📚 참고 자료

- [Dart 스타일 가이드](https://dart.dev/guides/language/effective-dart/style)
- [Flutter 스타일 가이드](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

---

## ✅ 체크리스트

코드 작성 후 다음 사항을 확인하세요:

- [ ] 파일명이 `snake_case`를 따름
- [ ] 클래스명이 `PascalCase`를 따름
- [ ] 변수/함수명이 `camelCase`를 따름
- [ ] `dart format .` 실행 완료
- [ ] `flutter analyze` 에러 없음
- [ ] 공개 API에 문서 주석 추가
- [ ] 커밋 메시지가 Conventional Commits 규칙을 따름
- [ ] 테스트 코드 작성 (필요한 경우)

---

**작성일**: 2024년  
**작성자**: AI Assistant  
**버전**: 1.0.0
