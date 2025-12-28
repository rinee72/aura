# Supabase 설정 가이드

## 문제 상황

회원가입 화면에서 다음과 같은 오류가 발생하는 경우:

```
인증 상태 초기화 중 오류가 발생했습니다: SupabaseConfigException: Supabase가 초기화되지 않았습니다. SupabaseConfig.initialize()를 먼저 호출하세요.
```

이는 `.env.development` 파일이 없거나, Supabase 프로젝트 정보가 제대로 설정되지 않았을 때 발생합니다.

## 해결 방법

### 1. `.env.development` 파일 확인 및 생성

프로젝트 루트(`C:\modu\aura_app`)에 `.env.development` 파일이 있어야 합니다.

파일이 없다면, 다음 내용으로 생성하세요:

```env
# AURA Development Environment Configuration
# WP-0.4: 개발/스테이징/프로덕션 환경 분리

# Development Supabase 프로젝트 URL
DEV_SUPABASE_URL=https://your-project-id.supabase.co

# Development Supabase Anon Key
DEV_SUPABASE_ANON_KEY=your-anon-key-here
```

또는 PowerShell 스크립트를 사용하여 자동 생성:

```powershell
cd C:\modu\aura_app
.\scripts\setup_env_files.ps1
```

### 2. Supabase 프로젝트 정보 확인

Supabase 대시보드에서 프로젝트 정보를 확인하세요:

1. [Supabase 대시보드](https://app.supabase.com) 접속
2. 프로젝트 선택
3. Settings → API 메뉴 이동
4. 다음 정보 확인:
   - **Project URL**: `DEV_SUPABASE_URL`에 입력
   - **anon public key**: `DEV_SUPABASE_ANON_KEY`에 입력

### 3. `.env.development` 파일에 실제 값 입력

`.env.development` 파일을 열어서 다음처럼 실제 값을 입력하세요:

```env
DEV_SUPABASE_URL=https://abcdefghijklmnop.supabase.co
DEV_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYxNjIzOTAyMiwiZXhwIjoxOTMxODE1MDIyfQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 4. 앱 재시작

환경 파일을 수정한 후에는 앱을 완전히 재시작해야 합니다:

1. 현재 실행 중인 앱 종료 (CMD 창에서 `q` 키 누르기)
2. `run_app.bat` 파일 다시 실행

## 추가 참고사항

- `.env.development` 파일은 Git에 커밋되지 않습니다 (`.gitignore`에 포함됨)
- 보안을 위해 Supabase 프로젝트 정보를 공개 저장소에 올리지 마세요
- 개발 환경과 프로덕션 환경의 Supabase 프로젝트를 분리하는 것을 권장합니다

## 문제가 계속 발생하는 경우

1. `.env.development` 파일이 올바른 위치에 있는지 확인 (프로젝트 루트)
2. 파일 인코딩이 UTF-8인지 확인
3. Supabase 프로젝트가 활성 상태인지 확인
4. 인터넷 연결 확인
5. CMD 창에서 출력되는 오류 메시지 확인


