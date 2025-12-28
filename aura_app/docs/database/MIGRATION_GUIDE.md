# 데이터베이스 마이그레이션 가이드

## 📋 개요

이 가이드는 WP-1.1의 데이터베이스 스키마를 Supabase에 적용하는 방법을 설명합니다.

---

## 🚀 마이그레이션 실행 방법

### 방법 1: Supabase Dashboard 사용 (권장)

1. **Supabase 프로젝트 접속**
   - [Supabase Dashboard](https://app.supabase.com)에 로그인
   - 프로젝트 선택 (예: `aura-mvp-dev`)

2. **SQL Editor 열기**
   - 왼쪽 메뉴에서 "SQL Editor" 클릭
   - "New query" 클릭

3. **마이그레이션 스크립트 실행**
   - `supabase/migrations/001_initial_schema.sql` 파일 내용을 복사
   - SQL Editor에 붙여넣기
   - "Run" 버튼 클릭

4. **결과 확인**
   - 에러가 없으면 성공
   - "Table Editor"에서 테이블 생성 확인

### 방법 2: Supabase CLI 사용

```bash
# Supabase CLI 설치 (아직 설치하지 않은 경우)
npm install -g supabase

# Supabase 프로젝트 연결
supabase link --project-ref <your-project-ref>

# 마이그레이션 실행
supabase db push
```

---

## ✅ 검증 단계

### 1. 테이블 생성 확인

Supabase Dashboard > Table Editor에서 다음 테이블들이 생성되었는지 확인:

- ✅ `users`
- ✅ `questions`
- ✅ `question_likes`
- ✅ `answers`
- ✅ `subscriptions`
- ✅ `communities`
- ✅ `community_comments`

### 2. 스키마 검증 스크립트 실행

1. SQL Editor에서 `supabase/migrations/002_verify_schema.sql` 실행
2. 모든 항목이 ✅로 표시되는지 확인

### 3. RLS 정책 확인

Supabase Dashboard > Authentication > Policies에서 각 테이블의 RLS 정책이 활성화되었는지 확인

### 4. 샘플 데이터 삽입 테스트

다음 SQL을 실행하여 샘플 데이터를 삽입하고 테스트합니다:

```sql
-- 주의: 이 스크립트는 테스트용입니다. 실제 사용자 데이터가 있는 경우 사용하지 마세요.

-- 1. 테스트 사용자 생성 (Supabase Auth에서 먼저 생성 필요)
-- Auth > Users에서 테스트 사용자 생성 후 ID 복사

-- 2. users 테이블에 프로필 추가
INSERT INTO public.users (id, email, role, display_name)
VALUES 
    ('<fan-user-id>', 'fan@test.com', 'fan', '테스트 팬'),
    ('<celebrity-user-id>', 'celebrity@test.com', 'celebrity', '테스트 셀럽'),
    ('<manager-user-id>', 'manager@test.com', 'manager', '테스트 매니저');

-- 3. 테스트 질문 생성
INSERT INTO public.questions (user_id, content)
VALUES 
    ('<fan-user-id>', '테스트 질문 1: 셀럽님의 취미는 무엇인가요?'),
    ('<fan-user-id>', '테스트 질문 2: 좋아하는 음식은?');

-- 4. 테스트 좋아요
INSERT INTO public.question_likes (question_id, user_id)
SELECT id, '<fan-user-id>' FROM public.questions LIMIT 1;

-- 5. 테스트 답변
INSERT INTO public.answers (question_id, celebrity_id, content)
SELECT id, '<celebrity-user-id>', '테스트 답변입니다.'
FROM public.questions
WHERE status = 'pending'
LIMIT 1;

-- 6. 테스트 구독
INSERT INTO public.subscriptions (fan_id, celebrity_id)
VALUES ('<fan-user-id>', '<celebrity-user-id>');
```

### 5. 역할별 접근 권한 검증

각 역할로 로그인하여 다음을 테스트합니다:

#### 팬 (Fan) 권한 테스트

```sql
-- 팬 계정으로 로그인 후 실행

-- ✅ 자신의 질문 조회 가능
SELECT * FROM public.questions WHERE user_id = auth.uid();

-- ✅ 모든 공개 질문 조회 가능
SELECT * FROM public.questions WHERE is_hidden = false;

-- ✅ 질문 작성 가능
INSERT INTO public.questions (user_id, content)
VALUES (auth.uid(), '새 질문입니다.');

-- ✅ 좋아요 가능
INSERT INTO public.question_likes (question_id, user_id)
VALUES ('<question-id>', auth.uid());

-- ❌ 숨김된 질문 조회 불가 (결과 없음)
SELECT * FROM public.questions WHERE is_hidden = true;

-- ❌ 다른 사용자의 질문 수정 불가 (에러 발생)
UPDATE public.questions 
SET content = '수정된 내용'
WHERE user_id != auth.uid();
```

#### 셀럽 (Celebrity) 권한 테스트

```sql
-- 셀럽 계정으로 로그인 후 실행

-- ✅ 숨김되지 않은 질문 조회 가능
SELECT * FROM public.questions WHERE is_hidden = false;

-- ✅ 자신의 답변 작성 가능
INSERT INTO public.answers (question_id, celebrity_id, content)
VALUES ('<question-id>', auth.uid(), '답변 내용입니다.');

-- ✅ 자신의 답변 수정 가능
UPDATE public.answers
SET content = '수정된 답변'
WHERE celebrity_id = auth.uid();

-- ❌ 질문 작성 불가 (에러 발생)
INSERT INTO public.questions (user_id, content)
VALUES (auth.uid(), '셀럽이 작성한 질문'); -- 실패해야 함

-- ❌ 숨김된 질문 조회 불가 (결과 없음)
SELECT * FROM public.questions WHERE is_hidden = true;
```

#### 매니저 (Manager) 권한 테스트

```sql
-- 매니저 계정으로 로그인 후 실행

-- ✅ 모든 질문 조회 가능 (숨김 포함)
SELECT * FROM public.questions;

-- ✅ 질문 숨김 처리 가능
UPDATE public.questions
SET is_hidden = true,
    hidden_reason = '부적절한 내용',
    hidden_at = NOW(),
    hidden_by = auth.uid()
WHERE id = '<question-id>';

-- ✅ 모든 사용자 프로필 조회 가능
SELECT * FROM public.users;

-- ✅ 모든 답변 조회 가능
SELECT * FROM public.answers;
```

---

## 🔍 문제 해결

### 문제: "relation does not exist" 오류

**원인**: 테이블이 생성되지 않았거나 스키마가 잘못되었습니다.

**해결**:
1. SQL Editor에서 에러 메시지 확인
2. `001_initial_schema.sql`을 다시 실행
3. Table Editor에서 테이블 존재 확인

### 문제: RLS 정책이 작동하지 않음

**원인**: RLS가 활성화되지 않았거나 정책이 올바르게 생성되지 않았습니다.

**해결**:
1. Supabase Dashboard > Authentication > Policies 확인
2. 각 테이블의 RLS가 활성화되어 있는지 확인
3. 정책이 올바르게 생성되었는지 확인
4. 필요시 `001_initial_schema.sql`의 RLS 정책 부분만 다시 실행

### 문제: 외래키 제약조건 오류

**원인**: 참조하는 테이블이 없거나 데이터가 존재합니다.

**해결**:
1. 테이블 생성 순서 확인 (users → questions → answers)
2. 기존 데이터가 있다면 먼저 삭제
3. 마이그레이션 스크립트를 순서대로 실행

### 문제: 트리거가 작동하지 않음

**원인**: 트리거 함수가 생성되지 않았거나 트리거가 연결되지 않았습니다.

**해결**:
1. `002_verify_schema.sql` 실행하여 트리거 확인
2. 트리거 함수가 생성되었는지 확인:
   ```sql
   SELECT * FROM pg_proc WHERE proname = 'update_question_like_count';
   ```
3. 필요시 트리거 부분만 다시 실행

---

## 📊 마이그레이션 체크리스트

마이그레이션 후 다음 항목을 확인하세요:

### 기본 구조
- [ ] 모든 테이블이 생성됨 (7개)
- [ ] 모든 인덱스가 생성됨 (18개)
- [ ] 모든 외래키 제약조건이 설정됨
- [ ] 모든 RLS 정책이 활성화됨

### 기능
- [ ] `updated_at` 자동 업데이트 트리거 작동
- [ ] `like_count` 자동 업데이트 트리거 작동
- [ ] `question_status` 자동 업데이트 트리거 작동

### 권한
- [ ] 팬 권한 테스트 통과
- [ ] 셀럽 권한 테스트 통과
- [ ] 매니저 권한 테스트 통과

---

## 🎯 다음 단계

마이그레이션이 완료되면 다음 작업을 진행하세요:

1. **WP-1.2**: Supabase Auth 기본 연동 및 회원가입/로그인
2. **WP-1.3**: 사용자 프로필 및 역할 관리 시스템
3. **WP-1.4**: 역할 기반 라우팅 및 Navigation 구현

---

**작성일**: 2024년 12월 19일  
**작성자**: AI Assistant  
**버전**: 1.0.0
