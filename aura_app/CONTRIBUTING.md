# 기여 가이드 (Contributing Guide)

AURA 프로젝트에 기여해 주셔서 감사합니다! 이 문서는 프로젝트에 기여하는 방법을 안내합니다.

---

## 📋 목차

- [브랜치 전략](#브랜치-전략)
- [개발 워크플로우](#개발-워크플로우)
- [코드 스타일](#코드-스타일)
- [커밋 메시지 규칙](#커밋-메시지-규칙)
- [Pull Request 가이드](#pull-request-가이드)
- [이슈 리포트](#이슈-리포트)

---

## 🌿 브랜치 전략

프로젝트는 Git Flow를 기반으로 한 브랜치 전략을 사용합니다.

### 주요 브랜치

- **`main`**: 프로덕션 브랜치
  - 항상 배포 가능한 상태를 유지
  - 직접 커밋 불가 (Pull Request만 허용)
  - 태그를 통한 버전 관리

- **`develop`**: 개발 통합 브랜치
  - 다음 릴리스를 위한 통합 브랜치
  - 기능 개발 완료 후 머지되는 브랜치
  - 직접 커밋 불가 (Pull Request만 허용)

### 보조 브랜치

- **`feature/*`**: 기능 개발 브랜치
  - 예: `feature/user-authentication`, `feature/question-card`
  - `develop` 브랜치에서 분기
  - 개발 완료 후 `develop`에 머지

- **`hotfix/*`**: 긴급 수정 브랜치
  - 예: `hotfix/critical-bug-fix`
  - `main` 브랜치에서 분기
  - 수정 완료 후 `main`과 `develop`에 머지

- **`release/*`**: 릴리스 준비 브랜치
  - 예: `release/v1.0.0`
  - `develop` 브랜치에서 분기
  - 릴리스 준비 완료 후 `main`과 `develop`에 머지

---

## 🔄 개발 워크플로우

### 1. 기능 개발 시작

```bash
# develop 브랜치로 이동
git checkout develop

# 최신 변경사항 가져오기
git pull origin develop

# 새 기능 브랜치 생성
git checkout -b feature/your-feature-name

# 작업 시작
```

### 2. 작업 중

```bash
# 변경사항 커밋
git add .
git commit -m "feat: 기능 설명"

# 원격 저장소에 푸시
git push origin feature/your-feature-name
```

### 3. Pull Request 생성

1. GitHub에서 Pull Request 생성
2. `develop` 브랜치로 머지 요청
3. 코드 리뷰 대기
4. CI 파이프라인 통과 확인

### 4. 머지 후 정리

```bash
# develop 브랜치로 이동
git checkout develop

# 최신 변경사항 가져오기
git pull origin develop

# 로컬 브랜치 삭제
git branch -d feature/your-feature-name
```

---

## 💻 코드 스타일

### Dart 스타일 가이드

- **파일명**: `snake_case.dart`
- **클래스명**: `PascalCase`
- **변수명/함수명**: `camelCase`
- **상수명**: `lowerCamelCase` (Dart 권장)
- **private 멤버**: `_leadingUnderscore`

### 코드 포맷팅

```bash
# 코드 포맷팅
dart format .

# 코드 분석
flutter analyze
```

### 폴더 구조

```
lib/
├── core/               # 핵심 설정 및 유틸리티
│   ├── theme/
│   ├── environment.dart
│   └── supabase_config.dart
├── features/           # 기능별 모듈
│   ├── auth/
│   ├── questions/
│   └── profile/
├── shared/             # 공통 위젯 및 유틸
│   ├── widgets/
│   └── utils/
└── main.dart
```

### 네이밍 규칙

- **Features**: 도메인별로 분리 (예: `auth`, `questions`)
- **Shared**: 2개 이상 기능에서 사용하는 코드만 포함
- **Core**: 앱 전역 설정 및 유틸리티

---

## 📝 커밋 메시지 규칙

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
- **`refactor`**: 리팩토링
- **`test`**: 테스트 코드 추가/수정
- **`chore`**: 빌드 설정, 패키지 관리 등

### 예시

```bash
feat(auth): 사용자 로그인 기능 추가

- Supabase Auth 연동
- 로그인 화면 UI 구현
- 에러 처리 추가

Closes #123
```

```bash
fix(questions): 질문 목록 무한 스크롤 버그 수정

페이지네이션 로직 개선으로 무한 스크롤 문제 해결

Fixes #456
```

---

## 🔍 Pull Request 가이드

### PR 생성 전 체크리스트

- [ ] 코드가 최신 `develop` 브랜치를 기반으로 함
- [ ] 모든 테스트 통과
- [ ] `flutter analyze` 에러 없음
- [ ] 코드 포맷팅 완료 (`dart format .`)
- [ ] 커밋 메시지가 규칙을 따름
- [ ] PR 템플릿 작성 완료

### PR 제목 형식

```
<type>(<scope>): <subject>
```

예: `feat(auth): 사용자 로그인 기능 추가`

### PR 설명

PR 템플릿을 사용하여 다음 정보를 포함:

- 변경 사항 설명
- 테스트 완료 여부
- 스크린샷 (UI 변경 시)
- 관련 이슈 번호

### 코드 리뷰

- 최소 1명의 승인 필요
- CI 파이프라인 통과 필수
- 리뷰어의 피드백에 대한 응답 및 수정

---

## 🐛 이슈 리포트

### 버그 리포트

버그를 발견한 경우 다음 정보를 포함하여 이슈를 생성하세요:

- **버그 설명**: 무엇이 잘못되었는지
- **재현 단계**: 버그를 재현하는 방법
- **예상 동작**: 기대했던 동작
- **실제 동작**: 실제로 발생한 동작
- **스크린샷**: 가능한 경우
- **환경 정보**: Flutter 버전, OS 등

### 기능 요청

새로운 기능을 제안하는 경우:

- **기능 설명**: 무엇을 원하는지
- **사용 사례**: 왜 이 기능이 필요한지
- **대안**: 고려한 다른 방법

---

## 📚 추가 리소스

- [Flutter 공식 문서](https://flutter.dev/docs)
- [Dart 스타일 가이드](https://dart.dev/guides/language/effective-dart/style)
- [Supabase 문서](https://supabase.com/docs)

---

## ❓ 질문

프로젝트에 대한 질문이 있으시면:

- GitHub Issues에 질문 이슈 생성
- 팀 슬랙 채널 (있는 경우)

---

**감사합니다! AURA 프로젝트에 기여해 주셔서 감사합니다! 🎉**

