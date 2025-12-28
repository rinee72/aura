# 데이터베이스 ERD (Entity Relationship Diagram)

## 📋 개요

AURA 플랫폼의 데이터베이스 스키마 설계 문서입니다.

**목적**: 셀럽-팬 소통 플랫폼의 데이터 구조를 정의하고, 3-Tier 계정 구조(fan/celebrity/manager)를 지원합니다.

---

## 🎯 설계 원칙

1. **보안 우선**: RLS(Row Level Security)를 통한 역할별 접근 제어
2. **확장성**: 향후 기능 추가를 고려한 유연한 구조
3. **성능**: 자주 조회되는 필드에 인덱스 생성
4. **데이터 무결성**: 외래키 제약조건으로 참조 무결성 보장

---

## 📊 테이블 구조

### 1. users 테이블

Supabase Auth의 `auth.users`와 연동되는 사용자 프로필 테이블입니다.

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| `id` | UUID | PRIMARY KEY, NOT NULL | Supabase Auth의 user ID (auth.users.id 참조) |
| `email` | TEXT | UNIQUE, NOT NULL | 사용자 이메일 |
| `role` | TEXT | NOT NULL, CHECK | 사용자 역할: 'fan', 'celebrity', 'manager' |
| `display_name` | TEXT | | 표시 이름 (닉네임) |
| `avatar_url` | TEXT | | 프로필 이미지 URL (Supabase Storage) |
| `bio` | TEXT | | 자기소개 |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성일시 |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 수정일시 |

**인덱스**:
- `idx_users_role`: `role` 컬럼 (역할별 조회 최적화)
- `idx_users_email`: `email` 컬럼 (이메일 조회 최적화)

**RLS 정책**:
- 모든 사용자: 자신의 프로필 조회/수정 가능
- 매니저: 모든 사용자 프로필 조회 가능

---

### 2. questions 테이블

팬이 작성한 질문을 저장하는 테이블입니다.

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | 질문 고유 ID |
| `user_id` | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | 질문 작성자 (팬) |
| `content` | TEXT | NOT NULL | 질문 내용 |
| `like_count` | INTEGER | NOT NULL, DEFAULT 0 | 좋아요 수 (실시간 집계) |
| `is_hidden` | BOOLEAN | NOT NULL, DEFAULT false | 숨김 여부 (매니저가 숨김) |
| `hidden_reason` | TEXT | | 숨김 사유 (매니저가 기록) |
| `hidden_at` | TIMESTAMPTZ | | 숨김 처리 일시 |
| `hidden_by` | UUID | REFERENCES users(id) | 숨김 처리한 매니저 ID |
| `status` | TEXT | NOT NULL, DEFAULT 'pending', CHECK | 질문 상태: 'pending' (미답변), 'answered' (답변완료) |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성일시 |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 수정일시 |

**인덱스**:
- `idx_questions_user_id`: `user_id` 컬럼 (사용자별 질문 조회)
- `idx_questions_like_count`: `like_count DESC` (좋아요순 정렬)
- `idx_questions_status`: `status` 컬럼 (상태별 필터링)
- `idx_questions_created_at`: `created_at DESC` (최신순 정렬)
- `idx_questions_is_hidden`: `is_hidden` 컬럼 (숨김 필터링)

**RLS 정책**:
- 팬: 자신의 질문 조회/작성 가능, 모든 공개 질문 조회 가능
- 셀럽: 숨김되지 않은 질문 조회 가능 (수정 불가)
- 매니저: 모든 질문 조회/숨김 처리 가능

---

### 3. question_likes 테이블

질문에 대한 좋아요를 저장하는 테이블입니다.

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | 좋아요 고유 ID |
| `question_id` | UUID | NOT NULL, REFERENCES questions(id) ON DELETE CASCADE | 질문 ID |
| `user_id` | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | 좋아요한 사용자 ID |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성일시 |

**제약조건**:
- `UNIQUE(question_id, user_id)`: 한 사용자는 한 질문에 한 번만 좋아요 가능

**인덱스**:
- `idx_question_likes_question_id`: `question_id` 컬럼
- `idx_question_likes_user_id`: `user_id` 컬럼

**RLS 정책**:
- 모든 사용자: 자신의 좋아요 조회/작성/삭제 가능
- 팬: 모든 좋아요 조회 가능 (통계용)

---

### 4. answers 테이블

셀럽이 작성한 답변을 저장하는 테이블입니다.

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | 답변 고유 ID |
| `question_id` | UUID | NOT NULL, UNIQUE, REFERENCES questions(id) ON DELETE CASCADE | 질문 ID (1:1 관계) |
| `celebrity_id` | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | 답변 작성자 (셀럽) |
| `content` | TEXT | NOT NULL | 답변 내용 |
| `is_draft` | BOOLEAN | NOT NULL, DEFAULT false | 임시저장 여부 |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성일시 |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 수정일시 |

**인덱스**:
- `idx_answers_question_id`: `question_id` 컬럼 (질문별 답변 조회)
- `idx_answers_celebrity_id`: `celebrity_id` 컬럼 (셀럽별 답변 조회)
- `idx_answers_created_at`: `created_at DESC` (최신순 정렬)

**RLS 정책**:
- 셀럽: 자신의 답변 조회/작성/수정/삭제 가능
- 팬: 공개된 답변(임시저장 아님) 조회 가능
- 매니저: 모든 답변 조회 가능

---

### 5. subscriptions 테이블

팬이 셀럽을 구독하는 관계를 저장하는 테이블입니다.

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | 구독 고유 ID |
| `fan_id` | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | 구독자 (팬) |
| `celebrity_id` | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | 구독 대상 (셀럽) |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 구독일시 |

**제약조건**:
- `UNIQUE(fan_id, celebrity_id)`: 한 팬은 한 셀럽을 한 번만 구독 가능
- `CHECK(fan_id != celebrity_id)`: 자신을 구독할 수 없음

**인덱스**:
- `idx_subscriptions_fan_id`: `fan_id` 컬럼 (팬별 구독 목록)
- `idx_subscriptions_celebrity_id`: `celebrity_id` 컬럼 (셀럽별 구독자 목록)

**RLS 정책**:
- 팬: 자신의 구독 조회/작성/삭제 가능
- 셀럽: 자신을 구독한 팬 목록 조회 가능 (읽기 전용)
- 매니저: 모든 구독 조회 가능

---

### 6. communities 테이블

팬 커뮤니티 게시글을 저장하는 테이블입니다.

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | 게시글 고유 ID |
| `user_id` | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | 작성자 ID |
| `title` | TEXT | NOT NULL | 게시글 제목 |
| `content` | TEXT | NOT NULL | 게시글 내용 |
| `view_count` | INTEGER | NOT NULL, DEFAULT 0 | 조회수 |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성일시 |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 수정일시 |

**인덱스**:
- `idx_communities_user_id`: `user_id` 컬럼 (작성자별 게시글 조회)
- `idx_communities_created_at`: `created_at DESC` (최신순 정렬)

**RLS 정책**:
- 팬: 모든 공개 게시글 조회 가능, 자신의 게시글 작성/수정/삭제 가능
- 셀럽/매니저: 모든 게시글 조회 가능 (읽기 전용)

---

### 7. community_comments 테이블

커뮤니티 게시글에 대한 댓글을 저장하는 테이블입니다.

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|----------|------|
| `id` | UUID | PRIMARY KEY, DEFAULT gen_random_uuid() | 댓글 고유 ID |
| `community_id` | UUID | NOT NULL, REFERENCES communities(id) ON DELETE CASCADE | 게시글 ID |
| `user_id` | UUID | NOT NULL, REFERENCES users(id) ON DELETE CASCADE | 댓글 작성자 ID |
| `content` | TEXT | NOT NULL | 댓글 내용 |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 생성일시 |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | 수정일시 |

**인덱스**:
- `idx_community_comments_community_id`: `community_id` 컬럼 (게시글별 댓글 조회)
- `idx_community_comments_user_id`: `user_id` 컬럼 (작성자별 댓글 조회)

**RLS 정책**:
- 팬: 모든 공개 댓글 조회 가능, 자신의 댓글 작성/수정/삭제 가능
- 셀럽/매니저: 모든 댓글 조회 가능 (읽기 전용)

---

## 🔗 테이블 관계도

```
users (1) ──< (N) questions
users (1) ──< (N) question_likes
users (1) ──< (N) answers
users (1) ──< (N) subscriptions (fan_id)
users (1) ──< (N) subscriptions (celebrity_id)
users (1) ──< (N) communities
users (1) ──< (N) community_comments

questions (1) ──< (1) answers
questions (1) ──< (N) question_likes

communities (1) ──< (N) community_comments
```

---

## 🔒 RLS 정책 상세

### users 테이블

```sql
-- 자신의 프로필 조회/수정
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- 매니저는 모든 프로필 조회 가능
CREATE POLICY "Managers can view all profiles"
  ON users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid() AND role = 'manager'
    )
  );
```

### questions 테이블

```sql
-- 팬: 자신의 질문 조회/작성, 모든 공개 질문 조회
CREATE POLICY "Fans can view own questions"
  ON questions FOR SELECT
  USING (
    user_id = auth.uid() OR
    (is_hidden = false AND EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'fan'
    ))
  );

CREATE POLICY "Fans can create questions"
  ON questions FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'fan')
  );

-- 셀럽: 숨김되지 않은 질문 조회만 가능
CREATE POLICY "Celebrities can view non-hidden questions"
  ON questions FOR SELECT
  USING (
    is_hidden = false AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'celebrity')
  );

-- 매니저: 모든 질문 조회 및 숨김 처리 가능
CREATE POLICY "Managers can view all questions"
  ON questions FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'manager')
  );

CREATE POLICY "Managers can hide questions"
  ON questions FOR UPDATE
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'manager')
  );
```

### answers 테이블

```sql
-- 셀럽: 자신의 답변 조회/작성/수정/삭제
CREATE POLICY "Celebrities can manage own answers"
  ON answers FOR ALL
  USING (
    celebrity_id = auth.uid() AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'celebrity')
  );

-- 팬: 공개된 답변(임시저장 아님) 조회
CREATE POLICY "Fans can view published answers"
  ON answers FOR SELECT
  USING (
    is_draft = false AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'fan')
  );

-- 매니저: 모든 답변 조회
CREATE POLICY "Managers can view all answers"
  ON answers FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'manager')
  );
```

### subscriptions 테이블

```sql
-- 팬: 자신의 구독 조회/작성/삭제
CREATE POLICY "Fans can manage own subscriptions"
  ON subscriptions FOR ALL
  USING (
    fan_id = auth.uid() AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'fan')
  );

-- 셀럽: 자신을 구독한 팬 목록 조회 (읽기 전용)
CREATE POLICY "Celebrities can view own subscribers"
  ON subscriptions FOR SELECT
  USING (
    celebrity_id = auth.uid() AND
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'celebrity')
  );
```

---

## 📈 성능 최적화

### 인덱스 전략

1. **조회 빈도가 높은 컬럼**: `user_id`, `role`, `status`
2. **정렬에 사용되는 컬럼**: `created_at`, `like_count`
3. **필터링에 사용되는 컬럼**: `is_hidden`, `is_draft`

### 집계 최적화

`questions.like_count`는 `question_likes` 테이블의 집계 결과를 저장합니다. 
실시간 업데이트를 위해 트리거를 사용하거나, 필요 시 집계 쿼리를 사용합니다.

---

## 🔄 데이터 흐름

### 질문 작성 플로우

1. 팬이 질문 작성 → `questions` 테이블에 INSERT
2. 욕설 필터링 (Edge Function) → 통과 시 `is_hidden = false`
3. 다른 팬들이 좋아요 → `question_likes` 테이블에 INSERT
4. `questions.like_count` 업데이트 (트리거 또는 애플리케이션 로직)
5. 셀럽이 Top 질문 확인 → `like_count DESC` 정렬 조회

### 답변 작성 플로우

1. 셀럽이 질문 선택 → `questions` 테이블에서 조회
2. 답변 작성 → `answers` 테이블에 INSERT
3. `questions.status`를 'answered'로 업데이트
4. 구독 팬들에게 실시간 알림 (Supabase Realtime)

---

## ✅ 검증 체크리스트

- [ ] 모든 테이블이 Supabase에 생성됨
- [ ] 외래키 제약조건이 올바르게 설정됨
- [ ] 인덱스가 생성됨
- [ ] RLS 정책이 적용되어 권한별 접근 제어 작동
- [ ] 샘플 데이터 삽입 테스트 성공
- [ ] 팬/셀럽/매니저 각 역할별 접근 권한 검증 완료

---

**작성일**: 2024년 12월 19일  
**작성자**: AI Assistant  
**버전**: 1.0.0
