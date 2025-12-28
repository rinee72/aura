-- ============================================
-- AURA MVP: RLS 무한 재귀 문제 수정
-- ============================================
-- 
-- 문제: "Managers can view all profiles" 정책이 public.users를 조회할 때
--       다시 RLS 정책을 트리거하여 무한 재귀가 발생합니다.
-- 
-- 해결: security_definer 함수를 사용하여 정책 체크를 우회하도록 수정합니다.
-- ============================================

-- ============================================
-- 1. 매니저 역할 확인 함수 생성 (security_definer)
-- ============================================

-- 이 함수는 RLS 정책을 우회하여 사용자 역할을 확인합니다
CREATE OR REPLACE FUNCTION public.is_manager(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role
    FROM public.users
    WHERE id = user_id;
    
    RETURN user_role = 'manager';
END;
$$;

-- ============================================
-- 2. users 테이블 정책 수정
-- ============================================

-- 기존 정책 삭제
DROP POLICY IF EXISTS "Managers can view all profiles" ON public.users;

-- 수정된 정책 생성 (재귀 방지)
CREATE POLICY "Managers can view all profiles"
    ON public.users FOR SELECT
    USING (
        public.is_manager(auth.uid())
    );

-- ============================================
-- 3. 다른 테이블의 users 조회 정책도 수정
-- ============================================

-- questions 테이블의 팬 역할 확인 정책 수정
DROP POLICY IF EXISTS "Fans can view own and public questions" ON public.questions;
CREATE POLICY "Fans can view own and public questions"
    ON public.questions FOR SELECT
    USING (
        user_id = auth.uid() OR
        (is_hidden = false AND public.is_manager(auth.uid()) = false)
    );

DROP POLICY IF EXISTS "Fans can create questions" ON public.questions;
CREATE POLICY "Fans can create questions"
    ON public.questions FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND public.is_manager(auth.uid()) = false
    );

-- ============================================
-- 완료
-- ============================================

-- 참고: 다른 테이블의 정책들도 필요시 수정해야 할 수 있습니다.
-- 하지만 가장 중요한 것은 users 테이블의 매니저 정책입니다.


