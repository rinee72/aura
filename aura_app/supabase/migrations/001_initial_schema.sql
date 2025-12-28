-- ============================================
-- AURA MVP: 초기 데이터베이스 스키마
-- WP-1.1: 데이터베이스 스키마 설계 및 생성
-- ============================================
-- 
-- 이 마이그레이션은 다음을 생성합니다:
-- 1. 모든 테이블 (users, questions, answers, communities, subscriptions 등)
-- 2. 외래키 제약조건
-- 3. 인덱스 (성능 최적화)
-- 4. RLS 정책 (역할별 접근 제어)
-- 5. 트리거 함수 (자동 업데이트)
--
-- 실행 방법:
-- 1. Supabase Dashboard > SQL Editor에서 실행
-- 2. 또는 Supabase CLI 사용: supabase db push
-- ============================================

-- ============================================
-- 1. 확장 기능 활성화
-- ============================================

-- UUID 생성 함수 사용
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 2. ENUM 타입 정의
-- ============================================

-- 사용자 역할 타입
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('fan', 'celebrity', 'manager');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 질문 상태 타입
DO $$ BEGIN
    CREATE TYPE question_status AS ENUM ('pending', 'answered');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- 3. 테이블 생성
-- ============================================

-- 3.1 users 테이블 (Supabase Auth와 연동)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    role user_role NOT NULL CHECK (role IN ('fan', 'celebrity', 'manager')),
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.2 questions 테이블
CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    like_count INTEGER NOT NULL DEFAULT 0,
    is_hidden BOOLEAN NOT NULL DEFAULT false,
    hidden_reason TEXT,
    hidden_at TIMESTAMPTZ,
    hidden_by UUID REFERENCES public.users(id),
    status question_status NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'answered')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.3 question_likes 테이블
CREATE TABLE IF NOT EXISTS public.question_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(question_id, user_id)
);

-- 3.4 answers 테이블
CREATE TABLE IF NOT EXISTS public.answers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL UNIQUE REFERENCES public.questions(id) ON DELETE CASCADE,
    celebrity_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_draft BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.5 subscriptions 테이블
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fan_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    celebrity_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(fan_id, celebrity_id),
    CHECK (fan_id != celebrity_id)
);

-- 3.6 communities 테이블
CREATE TABLE IF NOT EXISTS public.communities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    view_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.7 community_comments 테이블
CREATE TABLE IF NOT EXISTS public.community_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- 4. 인덱스 생성 (성능 최적화)
-- ============================================

-- users 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- questions 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_questions_user_id ON public.questions(user_id);
CREATE INDEX IF NOT EXISTS idx_questions_like_count ON public.questions(like_count DESC);
CREATE INDEX IF NOT EXISTS idx_questions_status ON public.questions(status);
CREATE INDEX IF NOT EXISTS idx_questions_created_at ON public.questions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_questions_is_hidden ON public.questions(is_hidden);

-- question_likes 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_question_likes_question_id ON public.question_likes(question_id);
CREATE INDEX IF NOT EXISTS idx_question_likes_user_id ON public.question_likes(user_id);

-- answers 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_answers_question_id ON public.answers(question_id);
CREATE INDEX IF NOT EXISTS idx_answers_celebrity_id ON public.answers(celebrity_id);
CREATE INDEX IF NOT EXISTS idx_answers_created_at ON public.answers(created_at DESC);

-- subscriptions 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_subscriptions_fan_id ON public.subscriptions(fan_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_celebrity_id ON public.subscriptions(celebrity_id);

-- communities 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_communities_user_id ON public.communities(user_id);
CREATE INDEX IF NOT EXISTS idx_communities_created_at ON public.communities(created_at DESC);

-- community_comments 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_community_comments_community_id ON public.community_comments(community_id);
CREATE INDEX IF NOT EXISTS idx_community_comments_user_id ON public.community_comments(user_id);

-- ============================================
-- 5. 트리거 함수 (자동 업데이트)
-- ============================================

-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- questions 테이블 updated_at 트리거
DROP TRIGGER IF EXISTS update_questions_updated_at ON public.questions;
CREATE TRIGGER update_questions_updated_at
    BEFORE UPDATE ON public.questions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- answers 테이블 updated_at 트리거
DROP TRIGGER IF EXISTS update_answers_updated_at ON public.answers;
CREATE TRIGGER update_answers_updated_at
    BEFORE UPDATE ON public.answers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- users 테이블 updated_at 트리거
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- communities 테이블 updated_at 트리거
DROP TRIGGER IF EXISTS update_communities_updated_at ON public.communities;
CREATE TRIGGER update_communities_updated_at
    BEFORE UPDATE ON public.communities
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- community_comments 테이블 updated_at 트리거
DROP TRIGGER IF EXISTS update_community_comments_updated_at ON public.community_comments;
CREATE TRIGGER update_community_comments_updated_at
    BEFORE UPDATE ON public.community_comments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- question_likes 변경 시 like_count 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_question_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.questions
        SET like_count = like_count + 1
        WHERE id = NEW.question_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.questions
        SET like_count = GREATEST(like_count - 1, 0)
        WHERE id = OLD.question_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- question_likes 트리거
DROP TRIGGER IF EXISTS trigger_update_question_like_count ON public.question_likes;
CREATE TRIGGER trigger_update_question_like_count
    AFTER INSERT OR DELETE ON public.question_likes
    FOR EACH ROW
    EXECUTE FUNCTION update_question_like_count();

-- 답변 생성 시 질문 상태 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_question_status_on_answer()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.is_draft = false THEN
        UPDATE public.questions
        SET status = 'answered'
        WHERE id = NEW.question_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.questions
        SET status = 'pending'
        WHERE id = OLD.question_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- answers 트리거
DROP TRIGGER IF EXISTS trigger_update_question_status ON public.answers;
CREATE TRIGGER trigger_update_question_status
    AFTER INSERT OR DELETE ON public.answers
    FOR EACH ROW
    EXECUTE FUNCTION update_question_status_on_answer();

-- ============================================
-- 6. RLS (Row Level Security) 활성화
-- ============================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_comments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 7. RLS 정책 생성
-- ============================================

-- ============================================
-- 7.1 users 테이블 정책
-- ============================================

-- 자신의 프로필 조회
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

-- 자신의 프로필 생성 (회원가입 시)
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile"
    ON public.users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- 자신의 프로필 수정
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 매니저는 모든 프로필 조회 가능 (auth.users를 통해 역할 확인)
DROP POLICY IF EXISTS "Managers can view all profiles" ON public.users;
CREATE POLICY "Managers can view all profiles"
    ON public.users FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'manager'
        )
    );

-- ============================================
-- 7.2 questions 테이블 정책
-- ============================================

-- 팬: 자신의 질문 조회 및 모든 공개 질문 조회
DROP POLICY IF EXISTS "Fans can view own and public questions" ON public.questions;
CREATE POLICY "Fans can view own and public questions"
    ON public.questions FOR SELECT
    USING (
        user_id = auth.uid() OR
        (is_hidden = false AND EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        ))
    );

-- 팬: 질문 작성
DROP POLICY IF EXISTS "Fans can create questions" ON public.questions;
CREATE POLICY "Fans can create questions"
    ON public.questions FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    );

-- 팬: 자신의 질문 수정
DROP POLICY IF EXISTS "Fans can update own questions" ON public.questions;
CREATE POLICY "Fans can update own questions"
    ON public.questions FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 셀럽: 숨김되지 않은 질문 조회만 가능
DROP POLICY IF EXISTS "Celebrities can view non-hidden questions" ON public.questions;
CREATE POLICY "Celebrities can view non-hidden questions"
    ON public.questions FOR SELECT
    USING (
        is_hidden = false AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'celebrity'
        )
    );

-- 매니저: 모든 질문 조회
DROP POLICY IF EXISTS "Managers can view all questions" ON public.questions;
CREATE POLICY "Managers can view all questions"
    ON public.questions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'manager'
        )
    );

-- 매니저: 질문 숨김 처리
DROP POLICY IF EXISTS "Managers can hide questions" ON public.questions;
CREATE POLICY "Managers can hide questions"
    ON public.questions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'manager'
        )
    );

-- ============================================
-- 7.3 question_likes 테이블 정책
-- ============================================

-- 모든 사용자: 자신의 좋아요 조회/작성/삭제
DROP POLICY IF EXISTS "Users can manage own likes" ON public.question_likes;
CREATE POLICY "Users can manage own likes"
    ON public.question_likes FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 팬: 모든 좋아요 조회 (통계용)
DROP POLICY IF EXISTS "Fans can view all likes" ON public.question_likes;
CREATE POLICY "Fans can view all likes"
    ON public.question_likes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    );

-- ============================================
-- 7.4 answers 테이블 정책
-- ============================================

-- 셀럽: 자신의 답변 조회/작성/수정/삭제
DROP POLICY IF EXISTS "Celebrities can manage own answers" ON public.answers;
CREATE POLICY "Celebrities can manage own answers"
    ON public.answers FOR ALL
    USING (
        celebrity_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'celebrity'
        )
    )
    WITH CHECK (
        celebrity_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'celebrity'
        )
    );

-- 팬: 공개된 답변(임시저장 아님) 조회
DROP POLICY IF EXISTS "Fans can view published answers" ON public.answers;
CREATE POLICY "Fans can view published answers"
    ON public.answers FOR SELECT
    USING (
        is_draft = false AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    );

-- 매니저: 모든 답변 조회
DROP POLICY IF EXISTS "Managers can view all answers" ON public.answers;
CREATE POLICY "Managers can view all answers"
    ON public.answers FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'manager'
        )
    );

-- ============================================
-- 7.5 subscriptions 테이블 정책
-- ============================================

-- 팬: 자신의 구독 조회/작성/삭제
DROP POLICY IF EXISTS "Fans can manage own subscriptions" ON public.subscriptions;
CREATE POLICY "Fans can manage own subscriptions"
    ON public.subscriptions FOR ALL
    USING (
        fan_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    )
    WITH CHECK (
        fan_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    );

-- 셀럽: 자신을 구독한 팬 목록 조회 (읽기 전용)
DROP POLICY IF EXISTS "Celebrities can view own subscribers" ON public.subscriptions;
CREATE POLICY "Celebrities can view own subscribers"
    ON public.subscriptions FOR SELECT
    USING (
        celebrity_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'celebrity'
        )
    );

-- 매니저: 모든 구독 조회
DROP POLICY IF EXISTS "Managers can view all subscriptions" ON public.subscriptions;
CREATE POLICY "Managers can view all subscriptions"
    ON public.subscriptions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'manager'
        )
    );

-- ============================================
-- 7.6 communities 테이블 정책
-- ============================================

-- 팬: 모든 공개 게시글 조회
DROP POLICY IF EXISTS "Fans can view all communities" ON public.communities;
CREATE POLICY "Fans can view all communities"
    ON public.communities FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    );

-- 팬: 자신의 게시글 작성/수정/삭제
DROP POLICY IF EXISTS "Fans can manage own communities" ON public.communities;
CREATE POLICY "Fans can manage own communities"
    ON public.communities FOR ALL
    USING (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    )
    WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    );

-- 셀럽/매니저: 모든 게시글 조회 (읽기 전용)
DROP POLICY IF EXISTS "Celebrities and managers can view all communities" ON public.communities;
CREATE POLICY "Celebrities and managers can view all communities"
    ON public.communities FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role IN ('celebrity', 'manager')
        )
    );

-- ============================================
-- 7.7 community_comments 테이블 정책
-- ============================================

-- 팬: 모든 공개 댓글 조회
DROP POLICY IF EXISTS "Fans can view all comments" ON public.community_comments;
CREATE POLICY "Fans can view all comments"
    ON public.community_comments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    );

-- 팬: 자신의 댓글 작성/수정/삭제
DROP POLICY IF EXISTS "Fans can manage own comments" ON public.community_comments;
CREATE POLICY "Fans can manage own comments"
    ON public.community_comments FOR ALL
    USING (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    )
    WITH CHECK (
        user_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    );

-- 셀럽/매니저: 모든 댓글 조회 (읽기 전용)
DROP POLICY IF EXISTS "Celebrities and managers can view all comments" ON public.community_comments;
CREATE POLICY "Celebrities and managers can view all comments"
    ON public.community_comments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role IN ('celebrity', 'manager')
        )
    );

-- ============================================
-- 8. 주석 추가 (문서화)
-- ============================================

COMMENT ON TABLE public.users IS '사용자 프로필 테이블 (Supabase Auth와 연동)';
COMMENT ON TABLE public.questions IS '팬이 작성한 질문 테이블';
COMMENT ON TABLE public.question_likes IS '질문 좋아요 테이블';
COMMENT ON TABLE public.answers IS '셀럽이 작성한 답변 테이블';
COMMENT ON TABLE public.subscriptions IS '팬-셀럽 구독 관계 테이블';
COMMENT ON TABLE public.communities IS '팬 커뮤니티 게시글 테이블';
COMMENT ON TABLE public.community_comments IS '커뮤니티 게시글 댓글 테이블';

COMMENT ON COLUMN public.users.role IS '사용자 역할: fan, celebrity, manager';
COMMENT ON COLUMN public.questions.status IS '질문 상태: pending (미답변), answered (답변완료)';
COMMENT ON COLUMN public.questions.is_hidden IS '매니저가 숨김 처리한 질문 여부';
COMMENT ON COLUMN public.answers.is_draft IS '임시저장 여부 (true면 공개되지 않음)';

-- ============================================
-- 마이그레이션 완료
-- ============================================

-- 마이그레이션 실행 후 다음을 확인하세요:
-- 1. Supabase Dashboard > Table Editor에서 모든 테이블 확인
-- 2. RLS 정책이 활성화되었는지 확인
-- 3. 샘플 데이터 삽입 테스트
-- 4. 역할별 접근 권한 검증
