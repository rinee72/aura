-- ============================================
-- WP-3.5: 셀럽 피드 작성 - feeds 테이블 생성
-- ============================================
-- 
-- 셀럽이 일반 피드를 작성하고 이미지를 업로드할 수 있는 테이블
-- ============================================

-- feeds 테이블 생성
CREATE TABLE IF NOT EXISTS public.feeds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    celebrity_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    image_urls JSONB, -- 여러 이미지 URL을 JSON 배열로 저장 (예: ["url1", "url2"])
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    -- 주의: celebrity_id가 celebrity 역할인지 확인하는 것은 RLS 정책과 애플리케이션 레벨에서 처리
    -- CHECK 제약조건에서는 서브쿼리를 사용할 수 없음
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_feeds_celebrity_id ON public.feeds(celebrity_id);
CREATE INDEX IF NOT EXISTS idx_feeds_created_at ON public.feeds(created_at DESC);

-- updated_at 자동 업데이트 트리거
DROP TRIGGER IF EXISTS update_feeds_updated_at ON public.feeds;
CREATE TRIGGER update_feeds_updated_at
    BEFORE UPDATE ON public.feeds
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS 활성화
ALTER TABLE public.feeds ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS 정책 생성
-- ============================================

-- 셀럽: 자신의 피드 조회/작성/수정/삭제
DROP POLICY IF EXISTS "Celebrities can manage own feeds" ON public.feeds;
CREATE POLICY "Celebrities can manage own feeds"
    ON public.feeds FOR ALL
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

-- 팬: 모든 공개 피드 조회 (구독한 셀럽의 피드만 표시하는 것은 애플리케이션 레벨에서 처리)
DROP POLICY IF EXISTS "Fans can view all feeds" ON public.feeds;
CREATE POLICY "Fans can view all feeds"
    ON public.feeds FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'fan'
        )
    );

-- 매니저: 모든 피드 조회
DROP POLICY IF EXISTS "Managers can view all feeds" ON public.feeds;
CREATE POLICY "Managers can view all feeds"
    ON public.feeds FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'manager'
        )
    );

-- 주석 추가
COMMENT ON TABLE public.feeds IS '셀럽이 작성한 일반 피드 테이블';
COMMENT ON COLUMN public.feeds.image_urls IS '피드에 첨부된 이미지 URL 배열 (JSON 형식)';

