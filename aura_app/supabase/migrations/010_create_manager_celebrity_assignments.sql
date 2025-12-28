-- ============================================
-- AURA MVP: 매니저-셀럽 담당 관계 테이블 생성
-- WP-4.2 확장: 매니저-셀럽 관계 명시적 관리
-- ============================================
-- 
-- 이 마이그레이션은 다음을 생성합니다:
-- 1. manager_celebrity_assignments 테이블 (매니저-셀럽 담당 관계)
-- 2. 인덱스 (성능 최적화)
-- 3. RLS 정책 (역할별 접근 제어)
--
-- 실행 방법:
-- 1. Supabase Dashboard > SQL Editor에서 실행
-- 2. 또는 Supabase CLI 사용: supabase db push
-- ============================================

-- ============================================
-- 1. 테이블 생성
-- ============================================

-- manager_celebrity_assignments 테이블
-- 매니저가 담당하는 셀럽을 관리하는 테이블
CREATE TABLE IF NOT EXISTS public.manager_celebrity_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    manager_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    celebrity_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by UUID REFERENCES public.users(id), -- 할당한 사람 (관리자 또는 다른 매니저)
    notes TEXT, -- 할당 관련 메모
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- 제약조건: 한 매니저는 한 셀럽을 한 번만 담당할 수 있음
    UNIQUE(manager_id, celebrity_id),
    
    -- 제약조건: 매니저는 자신을 담당할 수 없음
    CONSTRAINT check_not_self CHECK (manager_id != celebrity_id)
    
    -- 참고: manager_id와 celebrity_id의 역할 검증은 
    -- 애플리케이션 레벨과 RLS 정책에서 처리합니다.
    -- (PostgreSQL CHECK 제약조건에서는 서브쿼리를 사용할 수 없음)
);

-- ============================================
-- 2. 인덱스 생성
-- ============================================

-- 매니저별 담당 셀럽 조회 최적화
CREATE INDEX IF NOT EXISTS idx_manager_assignments_manager_id 
    ON public.manager_celebrity_assignments(manager_id);

-- 셀럽별 담당 매니저 조회 최적화
CREATE INDEX IF NOT EXISTS idx_manager_assignments_celebrity_id 
    ON public.manager_celebrity_assignments(celebrity_id);

-- 할당 일시 정렬 최적화
CREATE INDEX IF NOT EXISTS idx_manager_assignments_assigned_at 
    ON public.manager_celebrity_assignments(assigned_at DESC);

-- ============================================
-- 3. 트리거 함수 (updated_at 자동 업데이트)
-- ============================================

-- updated_at 자동 업데이트 함수 (이미 존재할 수 있음)
CREATE OR REPLACE FUNCTION update_manager_assignments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_manager_assignments_updated_at 
    ON public.manager_celebrity_assignments;
CREATE TRIGGER trigger_update_manager_assignments_updated_at
    BEFORE UPDATE ON public.manager_celebrity_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_manager_assignments_updated_at();

-- ============================================
-- 4. RLS (Row Level Security) 활성화
-- ============================================

ALTER TABLE public.manager_celebrity_assignments ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 5. RLS 정책 생성
-- ============================================

-- 매니저: 자신의 담당 셀럽 조회 가능
DROP POLICY IF EXISTS "Managers can view own assignments" 
    ON public.manager_celebrity_assignments;
CREATE POLICY "Managers can view own assignments"
    ON public.manager_celebrity_assignments FOR SELECT
    USING (
        manager_id = auth.uid() AND
        public.is_manager(auth.uid())
    );

-- 매니저: 모든 담당 관계 조회 가능 (다른 매니저의 담당 셀럽도 확인 가능)
DROP POLICY IF EXISTS "Managers can view all assignments" 
    ON public.manager_celebrity_assignments;
CREATE POLICY "Managers can view all assignments"
    ON public.manager_celebrity_assignments FOR SELECT
    USING (
        public.is_manager(auth.uid())
    );

-- 매니저: 담당 셀럽 할당 가능 (자신에게 할당)
-- 주의: 실제로는 관리자나 슈퍼 매니저만 할당할 수 있도록 애플리케이션 레벨에서 제한할 수 있음
DROP POLICY IF EXISTS "Managers can create assignments" 
    ON public.manager_celebrity_assignments;
CREATE POLICY "Managers can create assignments"
    ON public.manager_celebrity_assignments FOR INSERT
    WITH CHECK (
        public.is_manager(auth.uid()) AND
        (manager_id = auth.uid() OR assigned_by = auth.uid())
    );

-- 매니저: 자신의 담당 관계 수정 가능 (notes 등)
DROP POLICY IF EXISTS "Managers can update own assignments" 
    ON public.manager_celebrity_assignments;
CREATE POLICY "Managers can update own assignments"
    ON public.manager_celebrity_assignments FOR UPDATE
    USING (
        manager_id = auth.uid() AND
        public.is_manager(auth.uid())
    )
    WITH CHECK (
        manager_id = auth.uid() AND
        public.is_manager(auth.uid())
    );

-- 매니저: 자신의 담당 관계 삭제 가능 (담당 해제)
DROP POLICY IF EXISTS "Managers can delete own assignments" 
    ON public.manager_celebrity_assignments;
CREATE POLICY "Managers can delete own assignments"
    ON public.manager_celebrity_assignments FOR DELETE
    USING (
        manager_id = auth.uid() AND
        public.is_manager(auth.uid())
    );

-- 셀럽: 자신을 담당하는 매니저 조회 가능
DROP POLICY IF EXISTS "Celebrities can view assigned managers" 
    ON public.manager_celebrity_assignments;
CREATE POLICY "Celebrities can view assigned managers"
    ON public.manager_celebrity_assignments FOR SELECT
    USING (
        celebrity_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role = 'celebrity'
        )
    );

-- ============================================
-- 6. 주석 추가 (문서화)
-- ============================================

COMMENT ON TABLE public.manager_celebrity_assignments IS 
    '매니저-셀럽 담당 관계 테이블 (어떤 매니저가 어떤 셀럽을 담당하는지 관리)';

COMMENT ON COLUMN public.manager_celebrity_assignments.manager_id IS 
    '담당 매니저 ID (users 테이블의 manager 역할 사용자)';

COMMENT ON COLUMN public.manager_celebrity_assignments.celebrity_id IS 
    '담당 대상 셀럽 ID (users 테이블의 celebrity 역할 사용자)';

COMMENT ON COLUMN public.manager_celebrity_assignments.assigned_at IS 
    '담당 시작 일시';

COMMENT ON COLUMN public.manager_celebrity_assignments.assigned_by IS 
    '담당을 할당한 사람 (관리자 또는 다른 매니저, NULL이면 자동 할당)';

COMMENT ON COLUMN public.manager_celebrity_assignments.notes IS 
    '할당 관련 메모 (선택 사항)';

-- ============================================
-- 마이그레이션 완료
-- ============================================

-- 마이그레이션 실행 후 다음을 확인하세요:
-- 1. Supabase Dashboard > Table Editor에서 manager_celebrity_assignments 테이블 확인
-- 2. RLS 정책이 활성화되었는지 확인
-- 3. 샘플 데이터 삽입 테스트:
--    INSERT INTO public.manager_celebrity_assignments (manager_id, celebrity_id)
--    VALUES ('<manager-user-id>', '<celebrity-user-id>');

