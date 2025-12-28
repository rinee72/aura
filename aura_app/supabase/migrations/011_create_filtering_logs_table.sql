-- ============================================
-- AURA MVP: 필터링 로그 테이블 생성
-- WP-4.3: AI 악플 필터링 시스템 (Edge Function)
-- ============================================
-- 
-- 이 마이그레이션은 다음을 생성합니다:
-- 1. filtering_logs 테이블 (욕설 필터링 로그)
-- 2. 인덱스 (성능 최적화)
-- 3. RLS 정책 (역할별 접근 제어)
-- 4. 트리거 함수 (자동 업데이트)
--
-- 실행 방법:
-- 1. Supabase Dashboard > SQL Editor에서 실행
-- 2. 또는 Supabase CLI 사용: supabase db push
-- ============================================

-- ============================================
-- 1. 위험도 레벨 ENUM 타입 정의
-- ============================================

DO $$ BEGIN
    CREATE TYPE risk_level AS ENUM ('low', 'medium', 'high');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- 2. 조치 타입 ENUM 정의
-- ============================================

DO $$ BEGIN
    CREATE TYPE action_taken AS ENUM ('flagged', 'auto_hidden', 'none');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ============================================
-- 3. filtering_logs 테이블 생성
-- ============================================

CREATE TABLE IF NOT EXISTS public.filtering_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id UUID NOT NULL REFERENCES public.questions(id) ON DELETE CASCADE,
    content TEXT NOT NULL, -- 원본 질문 내용
    detected_profanities JSONB NOT NULL DEFAULT '[]'::jsonb, -- 탐지된 욕설 목록
    risk_score INTEGER NOT NULL DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100), -- 위험도 점수 (0-100)
    risk_level risk_level NOT NULL DEFAULT 'low', -- 위험도 레벨
    filtered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), -- 필터링 일시
    action_taken action_taken NOT NULL DEFAULT 'none', -- 조치
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- 4. 인덱스 생성 (성능 최적화)
-- ============================================

-- question_id 인덱스 (질문별 로그 조회)
CREATE INDEX IF NOT EXISTS idx_filtering_logs_question_id 
    ON public.filtering_logs(question_id);

-- risk_level 인덱스 (위험도별 필터링)
CREATE INDEX IF NOT EXISTS idx_filtering_logs_risk_level 
    ON public.filtering_logs(risk_level);

-- risk_score 인덱스 (위험도 점수별 정렬)
CREATE INDEX IF NOT EXISTS idx_filtering_logs_risk_score 
    ON public.filtering_logs(risk_score DESC);

-- filtered_at 인덱스 (시간별 정렬)
CREATE INDEX IF NOT EXISTS idx_filtering_logs_filtered_at 
    ON public.filtering_logs(filtered_at DESC);

-- action_taken 인덱스 (조치별 필터링)
CREATE INDEX IF NOT EXISTS idx_filtering_logs_action_taken 
    ON public.filtering_logs(action_taken);

-- ============================================
-- 5. updated_at 자동 업데이트 트리거
-- ============================================

-- 트리거 함수 (이미 존재하면 스킵)
CREATE OR REPLACE FUNCTION update_filtering_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_filtering_logs_updated_at ON public.filtering_logs;
CREATE TRIGGER trigger_update_filtering_logs_updated_at
    BEFORE UPDATE ON public.filtering_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_filtering_logs_updated_at();

-- ============================================
-- 6. RLS (Row Level Security) 활성화
-- ============================================

ALTER TABLE public.filtering_logs ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 7. RLS 정책 정의
-- ============================================

-- 매니저: 모든 필터링 로그 조회 가능
DROP POLICY IF EXISTS "Managers can view all filtering logs" ON public.filtering_logs;
CREATE POLICY "Managers can view all filtering logs"
    ON public.filtering_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'manager'
        )
    );

-- 매니저: 필터링 로그 생성 가능 (Edge Function에서 사용)
DROP POLICY IF EXISTS "Managers can create filtering logs" ON public.filtering_logs;
CREATE POLICY "Managers can create filtering logs"
    ON public.filtering_logs FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'manager'
        )
    );

-- 매니저: 필터링 로그 수정 가능
DROP POLICY IF EXISTS "Managers can update filtering logs" ON public.filtering_logs;
CREATE POLICY "Managers can update filtering logs"
    ON public.filtering_logs FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'manager'
        )
    );

-- Edge Function: 서비스 역할로 필터링 로그 생성 가능
-- 주의: Edge Function은 service_role 키를 사용하므로 RLS를 우회합니다.
-- 하지만 보안을 위해 service_role 키는 서버 사이드에서만 사용해야 합니다.

-- ============================================
-- 완료
-- ============================================

-- 참고:
-- 1. Edge Function은 service_role 키를 사용하여 RLS를 우회할 수 있습니다.
-- 2. 실제 프로덕션에서는 Edge Function의 인증을 추가로 검증해야 합니다.
-- 3. detected_profanities는 JSONB 타입으로 여러 욕설을 배열로 저장합니다.
--    예: ["시발", "병신", "개새끼"]

