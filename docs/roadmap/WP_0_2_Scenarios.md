# WP-0.2: Supabase 프로젝트 생성 및 연결 - Scenario 분해

## 📋 Work Package 개요
**WP-0.2**: Supabase 프로젝트 생성 및 연결  
**목표**: Supabase 프로젝트를 생성하고 Flutter 앱과 연결하여 통신 테스트 완료

---

## 🎯 Scenario 목록

### 그룹 A: Supabase 프로젝트 생성
- Scenario 0.2-1: Supabase 웹 대시보드에서 프로젝트 생성 성공
- Scenario 0.2-2: 이미 존재하는 프로젝트명으로 생성 시도 시 실패
- Scenario 0.2-3: Supabase 계정 미로그인 상태에서 프로젝트 생성 시도 시 실패

### 그룹 B: 환경 변수 설정
- Scenario 0.2-4: .env.example 파일 생성 성공
- Scenario 0.2-5: .env 파일에 올바른 Supabase 설정 추가 후 로드 성공
- Scenario 0.2-6: .env 파일에 잘못된 URL/키 입력 시 로드 실패
- Scenario 0.2-7: .env 파일이 .gitignore에 포함되어 커밋되지 않음 확인

### 그룹 C: Supabase 초기화 코드
- Scenario 0.2-8: SupabaseConfig 클래스 생성 및 초기화 코드 작성 성공
- Scenario 0.2-9: main.dart에서 Supabase 초기화 호출 성공
- Scenario 0.2-10: 환경 변수 없이 초기화 시도 시 실패

### 그룹 D: 연결 테스트
- Scenario 0.2-11: Flutter 앱에서 Supabase 연결 성공 (Health Check)
- Scenario 0.2-12: 잘못된 URL로 연결 시도 시 실패
- Scenario 0.2-13: 잘못된 Anon Key로 연결 시도 시 실패
- Scenario 0.2-14: 네트워크 연결 없이 연결 시도 시 실패

---

## 📝 상세 Scenario

### 🟢 그룹 A: Supabase 프로젝트 생성

#### Scenario 0.2-1: Supabase 웹 대시보드에서 프로젝트 생성 성공
- **Given**: 
  - Supabase 계정에 로그인되어 있음
  - 프로젝트 생성 권한이 있음
- **When**: 
  - Supabase 대시보드에서 "New Project" 클릭
  - 프로젝트 이름: `aura-mvp-dev` 입력
  - 리전: Asia Northeast (Seoul 또는 Tokyo) 선택
  - 데이터베이스 비밀번호 설정
  - "Create new project" 버튼 클릭
- **Then**: 
  - 프로젝트 생성 성공
  - 프로젝트 대시보드 화면 표시
  - 프로젝트 URL 및 API 키 확인 가능
  - 프로젝트 상태가 "Active"로 표시됨
- **선행 Scenario**: 없음

---

#### Scenario 0.2-2: 이미 존재하는 프로젝트명으로 생성 시도 시 실패
- **Given**: 
  - Supabase 계정에 로그인되어 있음
  - 동일한 이름의 프로젝트가 이미 존재함
- **When**: 
  - 프로젝트 이름에 기존 프로젝트명 입력
  - "Create new project" 버튼 클릭
- **Then**: 
  - 프로젝트 생성 실패
  - "Project name already exists" 또는 유사한 에러 메시지 표시
  - 프로젝트가 생성되지 않음
- **선행 Scenario**: 없음

---

#### Scenario 0.2-3: Supabase 계정 미로그인 상태에서 프로젝트 생성 시도 시 실패
- **Given**: 
  - Supabase 웹사이트에 접속했지만 로그인하지 않음
- **When**: 
  - 프로젝트 생성 페이지 접근 시도
- **Then**: 
  - 로그인 페이지로 리다이렉트됨
  - 프로젝트 생성 불가
  - "Please sign in" 또는 유사한 메시지 표시
- **선행 Scenario**: 없음

---

### 🟢 그룹 B: 환경 변수 설정

#### Scenario 0.2-4: .env.example 파일 생성 성공
- **Given**: Flutter 프로젝트가 생성되어 있음
- **When**: 
  - 프로젝트 루트에 `.env.example` 파일 생성
  - 다음 내용 추가:
    ```env
    SUPABASE_URL=https://your-project.supabase.co
    SUPABASE_ANON_KEY=your-anon-key
    ```
- **Then**: 
  - `.env.example` 파일이 생성됨
  - 파일 내용이 정확히 저장됨
  - Git에 커밋 가능 (민감 정보 없음)
- **선행 Scenario**: 0.1-1 (프로젝트 생성)

---

#### Scenario 0.2-5: .env 파일에 올바른 Supabase 설정 추가 후 로드 성공
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - Supabase 프로젝트가 생성되어 있음
  - `.env.example` 파일이 존재함
- **When**: 
  - `.env` 파일 생성
  - 실제 Supabase URL 및 Anon Key 입력
  - `flutter_dotenv` 패키지로 `.env` 파일 로드
- **Then**: 
  - `.env` 파일이 생성됨
  - 환경 변수가 정상적으로 로드됨
  - `dotenv.env['SUPABASE_URL']` 값이 올바르게 반환됨
  - `dotenv.env['SUPABASE_ANON_KEY']` 값이 올바르게 반환됨
- **선행 Scenario**: 0.1-1, 0.2-1, 0.2-4

---

#### Scenario 0.2-6: .env 파일에 잘못된 URL/키 입력 시 로드 실패
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - `.env` 파일이 존재함
- **When**: 
  - `.env` 파일에 잘못된 형식의 URL 또는 빈 값 입력
  - `dotenv.load()` 실행
- **Then**: 
  - 환경 변수 로드는 성공하지만 값이 유효하지 않음
  - Supabase 초기화 시 에러 발생
  - 적절한 에러 메시지 표시
- **선행 Scenario**: 0.1-1, 0.2-4

---

#### Scenario 0.2-7: .env 파일이 .gitignore에 포함되어 커밋되지 않음 확인
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - `.env` 파일이 존재함
  - Git 저장소가 초기화되어 있음
- **When**: 
  - `.gitignore` 파일에 `.env` 추가 확인
  - `git status` 명령어 실행
- **Then**: 
  - `.env` 파일이 Git 추적 대상에서 제외됨
  - `git status`에 `.env` 파일이 표시되지 않음
  - `.env.example`은 추적 대상에 포함됨
- **선행 Scenario**: 0.1-1, 0.2-5

---

### 🟢 그룹 C: Supabase 초기화 코드

#### Scenario 0.2-8: SupabaseConfig 클래스 생성 및 초기화 코드 작성 성공
- **Given**: 
  - Flutter 프로젝트가 생성되어 있음
  - `supabase_flutter` 및 `flutter_dotenv` 패키지가 설치되어 있음
- **When**: 
  - `lib/core/supabase_config.dart` 파일 생성
  - `SupabaseConfig` 클래스 작성
  - `initialize()` 메서드에 Supabase 초기화 코드 작성
- **Then**: 
  - 파일이 정상적으로 생성됨
  - 코드 컴파일 성공
  - `flutter analyze` 실행 시 에러 없음
- **선행 Scenario**: 0.1-1, 0.1-4

---

#### Scenario 0.2-9: main.dart에서 Supabase 초기화 호출 성공
- **Given**: 
  - `SupabaseConfig` 클래스가 생성되어 있음
  - `.env` 파일에 올바른 설정이 있음
- **When**: 
  - `lib/main.dart`에서 `SupabaseConfig.initialize()` 호출
  - 앱 실행
- **Then**: 
  - Supabase 초기화 성공
  - 에러 없이 앱이 시작됨
  - 콘솔에 초기화 성공 로그 출력
- **선행 Scenario**: 0.2-5, 0.2-8

---

#### Scenario 0.2-10: 환경 변수 없이 초기화 시도 시 실패
- **Given**: 
  - `SupabaseConfig` 클래스가 생성되어 있음
  - `.env` 파일이 없거나 환경 변수가 설정되지 않음
- **When**: 
  - `SupabaseConfig.initialize()` 호출
- **Then**: 
  - 초기화 실패
  - "Environment variable not found" 또는 유사한 에러 발생
  - 앱이 크래시하거나 적절한 에러 처리됨
- **선행 Scenario**: 0.2-8

---

### 🟢 그룹 D: 연결 테스트

#### Scenario 0.2-11: Flutter 앱에서 Supabase 연결 성공 (Health Check)
- **Given**: 
  - Supabase 프로젝트가 생성되어 있음
  - `.env` 파일에 올바른 설정이 있음
  - `SupabaseConfig.initialize()`가 성공적으로 호출됨
- **When**: 
  - `Supabase.instance.client`로 클라이언트 인스턴스 가져오기
  - 간단한 Health Check (예: `auth.currentUser` 조회)
  - 앱 실행
- **Then**: 
  - Supabase 클라이언트 인스턴스가 정상적으로 생성됨
  - 연결 성공
  - 콘솔에 "Supabase connected" 또는 유사한 성공 메시지 출력
  - 에러 없음
- **선행 Scenario**: 0.2-1, 0.2-5, 0.2-9

---

#### Scenario 0.2-12: 잘못된 URL로 연결 시도 시 실패
- **Given**: 
  - `.env` 파일이 존재함
  - `SupabaseConfig` 클래스가 생성되어 있음
- **When**: 
  - `.env` 파일에 잘못된 URL 입력 (예: `https://invalid-url.com`)
  - `SupabaseConfig.initialize()` 호출
- **Then**: 
  - 초기화 실패 또는 연결 실패
  - "Invalid URL" 또는 "Connection failed" 에러 발생
  - 적절한 에러 메시지 표시
- **선행 Scenario**: 0.2-8

---

#### Scenario 0.2-13: 잘못된 Anon Key로 연결 시도 시 실패
- **Given**: 
  - `.env` 파일이 존재함
  - `SupabaseConfig` 클래스가 생성되어 있음
  - 올바른 URL이 설정되어 있음
- **When**: 
  - `.env` 파일에 잘못된 Anon Key 입력
  - `SupabaseConfig.initialize()` 호출
  - API 호출 시도
- **Then**: 
  - 초기화는 성공하지만 API 호출 시 실패
  - "Invalid API key" 또는 "Unauthorized" 에러 발생
  - 적절한 에러 메시지 표시
- **선행 Scenario**: 0.2-8

---

#### Scenario 0.2-14: 네트워크 연결 없이 연결 시도 시 실패
- **Given**: 
  - `.env` 파일에 올바른 설정이 있음
  - `SupabaseConfig` 클래스가 생성되어 있음
  - 디바이스/컴퓨터의 네트워크 연결이 끊어짐
- **When**: 
  - `SupabaseConfig.initialize()` 호출
  - API 호출 시도
- **Then**: 
  - 연결 실패
  - "Network error" 또는 "Connection timeout" 에러 발생
  - 적절한 에러 메시지 표시
- **선행 Scenario**: 0.2-8

---

## 📊 Scenario 의존성 다이어그램

```
[그룹 A: 프로젝트 생성]
0.2-1 (프로젝트 생성 성공)
  ├─> 0.2-5 (환경 변수 설정) [그룹 B]
  └─> 0.2-11 (연결 테스트) [그룹 D]

[그룹 B: 환경 변수]
0.2-4 (.env.example)
  └─> 0.2-5 (.env 설정)
       └─> 0.2-9 (초기화 호출) [그룹 C]

[그룹 C: 초기화 코드]
0.2-8 (SupabaseConfig 생성)
  ├─> 0.2-9 (main.dart 호출)
  │    └─> 0.2-11 (연결 테스트) [그룹 D]
  ├─> 0.2-10 (환경 변수 없음 실패)
  ├─> 0.2-12 (잘못된 URL 실패)
  └─> 0.2-13 (잘못된 Key 실패)

[그룹 D: 연결 테스트]
0.2-11 (연결 성공)
0.2-12, 0.2-13, 0.2-14 (실패 케이스)
```

---

## 📋 Scenario 실행 순서 (권장)

### Phase 1: 프로젝트 생성 (필수)
1. 0.2-1: Supabase 프로젝트 생성 성공

### Phase 2: 환경 변수 설정 (필수)
2. 0.2-4: .env.example 파일 생성
3. 0.2-5: .env 파일에 올바른 설정 추가
4. 0.2-7: .gitignore 확인

### Phase 3: 초기화 코드 작성 (필수)
5. 0.2-8: SupabaseConfig 클래스 생성
6. 0.2-9: main.dart에서 초기화 호출

### Phase 4: 연결 테스트 (필수)
7. 0.2-11: 연결 성공 테스트

### Phase 5: 실패 케이스 검증 (선택)
8. 0.2-2, 0.2-3: 프로젝트 생성 실패 케이스
9. 0.2-6: 환경 변수 실패 케이스
10. 0.2-10, 0.2-12, 0.2-13, 0.2-14: 초기화/연결 실패 케이스

---

## ✅ WP-0.2 완료 조건 검증

WP-0.2는 다음 Scenario들이 모두 통과되어야 완료된 것으로 간주:

### 필수 통과 Scenario (Success Cases)
- ✅ 0.2-1: Supabase 프로젝트 생성 성공
- ✅ 0.2-4: .env.example 파일 생성 성공
- ✅ 0.2-5: .env 파일 설정 성공
- ✅ 0.2-7: .gitignore 확인
- ✅ 0.2-8: SupabaseConfig 클래스 생성 성공
- ✅ 0.2-9: main.dart에서 초기화 호출 성공
- ✅ 0.2-11: Supabase 연결 성공

### 검증 완료 Scenario (Failure Cases)
- ✅ 0.2-2, 0.2-3: 프로젝트 생성 실패 케이스 확인
- ✅ 0.2-6: 환경 변수 실패 케이스 확인
- ✅ 0.2-10: 환경 변수 없음 실패 케이스 확인
- ✅ 0.2-12, 0.2-13, 0.2-14: 연결 실패 케이스 확인

---

## 🎯 요약

- **총 Scenario 수**: 14개
  - 성공 케이스: 7개
  - 실패 케이스: 7개
- **예상 실행 시간**: 0.5일
- **핵심 원칙**: 하나의 Scenario = 하나의 행동 = 하나의 검증


