# 소셜 로그인 Provider 활성화 가이드

## 문제 상황

Google 로그인 시 다음과 같은 에러가 발생하는 경우:

```
{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: provider is not enabled"}
```

이는 **Supabase Dashboard에서 Google Provider가 활성화되지 않았기 때문**입니다.

---

## 해결 방법

### 1. Supabase Dashboard 접속

1. [Supabase Dashboard](https://app.supabase.com/)에 접속
2. 프로젝트 선택

### 2. Google Provider 활성화

1. 좌측 메뉴에서 **Authentication** 클릭
2. **Providers** 탭 선택
3. **Google** 섹션 찾기
4. **Enable Google provider** 토글을 **ON**으로 변경

### 3. Google OAuth 클라이언트 ID 및 시크릿 설정

Google Provider를 활성화한 후 다음 정보를 입력해야 합니다:

#### Google Cloud Console에서 정보 가져오기

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택 (또는 새 프로젝트 생성)
3. **API 및 서비스** > **사용자 인증 정보**로 이동
4. **+ 사용자 인증 정보 만들기** > **OAuth 클라이언트 ID** 선택
5. 애플리케이션 유형 선택:
   - **웹 애플리케이션**: 웹용
   - **Android**: Android용
   - **iOS**: iOS용
6. 클라이언트 ID와 클라이언트 시크릿 생성

#### Supabase Dashboard에 설정 입력

1. **Client ID (for OAuth)**: Google Cloud Console에서 생성한 클라이언트 ID 입력
2. **Client Secret (for OAuth)**: Google Cloud Console에서 생성한 클라이언트 시크릿 입력
3. **Save** 버튼 클릭

### 4. 리다이렉트 URL 설정

**중요**: Google Cloud Console에서 리다이렉트 URL을 설정해야 합니다.

1. Google Cloud Console > OAuth 클라이언트 설정으로 이동
2. **승인된 리디렉션 URI**에 다음 추가:
   ```
   https://[your-project-ref].supabase.co/auth/v1/callback
   ```
   - `[your-project-ref]`는 Supabase 프로젝트 URL의 프로젝트 참조 ID입니다.
   - 예: `https://abcdefghijklmnop.supabase.co/auth/v1/callback`

### 5. Apple Provider 활성화 (선택사항, iOS/macOS용)

Apple 로그인을 사용하려면:

1. **Authentication** > **Providers** > **Apple** 섹션
2. **Enable Apple provider** 토글을 **ON**으로 변경
3. Apple Developer에서 생성한 정보 입력:
   - **Services ID**
   - **Secret Key** (.p8 키 파일 내용)
   - **Key ID**
   - **Team ID**

자세한 설정 방법은 `docs/소셜_로그인_설정_가이드.md`를 참고하세요.

---

## 검증

Provider를 활성화한 후:

1. 앱을 재시작하거나 로그인 화면으로 이동
2. "Google로 계속하기" 버튼 클릭
3. Google 로그인 화면이 정상적으로 표시되는지 확인

---

## 문제 해결

### 여전히 같은 에러가 발생하는 경우

1. **Provider가 정말 활성화되었는지 확인**
   - Supabase Dashboard > Authentication > Providers에서 확인
   - 토글이 **ON** 상태인지 확인

2. **저장 버튼을 클릭했는지 확인**
   - 설정을 변경한 후 반드시 **Save** 버튼을 클릭해야 합니다.

3. **캐시 문제**
   - Supabase 설정 변경이 즉시 반영되지 않을 수 있습니다.
   - 몇 분 기다린 후 다시 시도해보세요.

4. **프로젝트 선택 확인**
   - 올바른 Supabase 프로젝트에서 설정했는지 확인하세요.

---

## 추가 리소스

- [Supabase Auth 문서](https://supabase.com/docs/guides/auth)
- [Supabase Google OAuth 가이드](https://supabase.com/docs/guides/auth/social-login/auth-google)
- `docs/소셜_로그인_설정_가이드.md` - 상세한 설정 가이드

