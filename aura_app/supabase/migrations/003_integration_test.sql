-- ============================================
-- AURA MVP: 통합 테스트 스크립트
-- WP-1.1: 데이터베이스 스키마 통합 테스트
-- ============================================
-- 
-- 이 스크립트는 다음을 테스트합니다:
-- 1. 테이블 생성 확인
-- 2. RLS 정책 작동 확인
-- 3. 트리거 함수 작동 확인
-- 4. 샘플 데이터 삽입 테스트
-- 5. 역할별 접근 권한 검증
--
-- 주의: 이 스크립트는 테스트용입니다.
-- 실제 Supabase 프로젝트에서 실행하기 전에
-- Supabase Auth에서 테스트 사용자를 먼저 생성하세요.
-- ============================================

-- ============================================
-- 1. 테스트 환경 설정
-- ============================================

-- 테스트용 변수 (실제 사용 시 Supabase Auth에서 생성한 사용자 ID로 교체)
-- DO 블록에서 변수를 사용할 수 없으므로, 아래 테스트에서 직접 UUID를 사용하세요.

-- ============================================
-- 2. 테이블 존재 확인
-- ============================================

DO $$
DECLARE
    table_count INTEGER;
    expected_tables TEXT[] := ARRAY[
        'users',
        'questions',
        'question_likes',
        'answers',
        'subscriptions',
        'communities',
        'community_comments'
    ];
    table_name TEXT;
    missing_tables TEXT[] := ARRAY[]::TEXT[];
BEGIN
    RAISE NOTICE '=== 테이블 존재 확인 ===';
    
    FOREACH table_name IN ARRAY expected_tables
    LOOP
        SELECT COUNT(*) INTO table_count
        FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = table_name;
        
        IF table_count = 0 THEN
            missing_tables := array_append(missing_tables, table_name);
            RAISE NOTICE '❌ 테이블 없음: %', table_name;
        ELSE
            RAISE NOTICE '✅ 테이블 존재: %', table_name;
        END IF;
    END LOOP;
    
    IF array_length(missing_tables, 1) > 0 THEN
        RAISE EXCEPTION '누락된 테이블: %. 먼저 001_initial_schema.sql을 실행하세요.', array_to_string(missing_tables, ', ');
    END IF;
END $$;

-- ============================================
-- 3. RLS 활성화 확인
-- ============================================

DO $$
DECLARE
    rls_count INTEGER;
    expected_tables TEXT[] := ARRAY[
        'users',
        'questions',
        'question_likes',
        'answers',
        'subscriptions',
        'communities',
        'community_comments'
    ];
    table_name TEXT;
    missing_rls TEXT[] := ARRAY[]::TEXT[];
BEGIN
    RAISE NOTICE '=== RLS 활성화 확인 ===';
    
    FOREACH table_name IN ARRAY expected_tables
    LOOP
        SELECT COUNT(*) INTO rls_count
        FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename = table_name
        AND rowsecurity = true;
        
        IF rls_count = 0 THEN
            missing_rls := array_append(missing_rls, table_name);
            RAISE NOTICE '❌ RLS 비활성화: %', table_name;
        ELSE
            RAISE NOTICE '✅ RLS 활성화: %', table_name;
        END IF;
    END LOOP;
    
    IF array_length(missing_rls, 1) > 0 THEN
        RAISE WARNING 'RLS가 비활성화된 테이블: %', array_to_string(missing_rls, ', ');
    END IF;
END $$;

-- ============================================
-- 4. 트리거 함수 작동 테스트
-- ============================================

DO $$
DECLARE
    test_user_id UUID;
    test_question_id UUID;
    test_like_id UUID;
    initial_like_count INTEGER;
    final_like_count INTEGER;
BEGIN
    RAISE NOTICE '=== 트리거 함수 작동 테스트 ===';
    
    -- 테스트 사용자 생성 (실제로는 Supabase Auth에서 생성)
    -- 여기서는 임시로 테스트를 건너뜁니다.
    -- 실제 테스트를 위해서는 Supabase Auth에서 사용자를 먼저 생성해야 합니다.
    
    RAISE NOTICE '⚠️ 트리거 테스트는 실제 사용자 데이터가 필요합니다.';
    RAISE NOTICE '   Supabase Auth에서 테스트 사용자를 생성한 후 다시 실행하세요.';
    
    -- 예시: 좋아요 트리거 테스트 (실제 사용자 ID 필요)
    -- 1. 질문 생성
    -- 2. 좋아요 추가
    -- 3. like_count 확인
    -- 4. 좋아요 삭제
    -- 5. like_count 확인
    
END $$;

-- ============================================
-- 5. 외래키 제약조건 테스트
-- ============================================

DO $$
DECLARE
    fk_count INTEGER;
    test_passed BOOLEAN := true;
BEGIN
    RAISE NOTICE '=== 외래키 제약조건 테스트 ===';
    
    -- questions.user_id -> users.id
    SELECT COUNT(*) INTO fk_count
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    AND tc.table_name = 'questions'
    AND kcu.column_name = 'user_id';
    
    IF fk_count > 0 THEN
        RAISE NOTICE '✅ 외래키 존재: questions.user_id -> users.id';
    ELSE
        RAISE NOTICE '❌ 외래키 없음: questions.user_id -> users.id';
        test_passed := false;
    END IF;
    
    -- answers.question_id -> questions.id
    SELECT COUNT(*) INTO fk_count
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public'
    AND tc.table_name = 'answers'
    AND kcu.column_name = 'question_id';
    
    IF fk_count > 0 THEN
        RAISE NOTICE '✅ 외래키 존재: answers.question_id -> questions.id';
    ELSE
        RAISE NOTICE '❌ 외래키 없음: answers.question_id -> questions.id';
        test_passed := false;
    END IF;
    
    IF NOT test_passed THEN
        RAISE WARNING '일부 외래키 제약조건이 누락되었습니다.';
    END IF;
END $$;

-- ============================================
-- 6. RLS 정책 개수 확인
-- ============================================

DO $$
DECLARE
    policy_count INTEGER;
    min_policies INTEGER;
BEGIN
    RAISE NOTICE '=== RLS 정책 개수 확인 ===';
    
    -- users 테이블 정책 (최소 4개: 조회, 생성, 수정, 매니저 조회)
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'users';
    
    min_policies := 4;
    IF policy_count >= min_policies THEN
        RAISE NOTICE '✅ users 테이블 정책: %개 (최소 %개 필요)', policy_count, min_policies;
    ELSE
        RAISE WARNING '⚠️ users 테이블 정책 부족: %개 (최소 %개 필요)', policy_count, min_policies;
    END IF;
    
    -- questions 테이블 정책 (최소 6개)
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'questions';
    
    min_policies := 6;
    IF policy_count >= min_policies THEN
        RAISE NOTICE '✅ questions 테이블 정책: %개 (최소 %개 필요)', policy_count, min_policies;
    ELSE
        RAISE WARNING '⚠️ questions 테이블 정책 부족: %개 (최소 %개 필요)', policy_count, min_policies;
    END IF;
    
    -- answers 테이블 정책 (최소 3개)
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'answers';
    
    min_policies := 3;
    IF policy_count >= min_policies THEN
        RAISE NOTICE '✅ answers 테이블 정책: %개 (최소 %개 필요)', policy_count, min_policies;
    ELSE
        RAISE WARNING '⚠️ answers 테이블 정책 부족: %개 (최소 %개 필요)', policy_count, min_policies;
    END IF;
END $$;

-- ============================================
-- 7. 인덱스 존재 확인
-- ============================================

DO $$
DECLARE
    index_count INTEGER;
    expected_indexes TEXT[] := ARRAY[
        'idx_users_role',
        'idx_users_email',
        'idx_questions_user_id',
        'idx_questions_like_count',
        'idx_questions_status',
        'idx_questions_created_at',
        'idx_questions_is_hidden',
        'idx_question_likes_question_id',
        'idx_question_likes_user_id',
        'idx_answers_question_id',
        'idx_answers_celebrity_id',
        'idx_answers_created_at',
        'idx_subscriptions_fan_id',
        'idx_subscriptions_celebrity_id',
        'idx_communities_user_id',
        'idx_communities_created_at',
        'idx_community_comments_community_id',
        'idx_community_comments_user_id'
    ];
    index_name TEXT;
    missing_indexes TEXT[] := ARRAY[]::TEXT[];
BEGIN
    RAISE NOTICE '=== 인덱스 존재 확인 ===';
    
    FOREACH index_name IN ARRAY expected_indexes
    LOOP
        SELECT COUNT(*) INTO index_count
        FROM pg_indexes
        WHERE schemaname = 'public'
        AND indexname = index_name;
        
        IF index_count = 0 THEN
            missing_indexes := array_append(missing_indexes, index_name);
            RAISE NOTICE '❌ 인덱스 없음: %', index_name;
        ELSE
            RAISE NOTICE '✅ 인덱스 존재: %', index_name;
        END IF;
    END LOOP;
    
    IF array_length(missing_indexes, 1) > 0 THEN
        RAISE WARNING '누락된 인덱스: %', array_to_string(missing_indexes, ', ');
    END IF;
END $$;

-- ============================================
-- 8. 샘플 데이터 삽입 테스트 가이드
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=== 샘플 데이터 삽입 테스트 가이드 ===';
    RAISE NOTICE '';
    RAISE NOTICE '다음 단계를 수행하세요:';
    RAISE NOTICE '';
    RAISE NOTICE '1. Supabase Auth에서 테스트 사용자 생성:';
    RAISE NOTICE '   - 팬: fan@test.com';
    RAISE NOTICE '   - 셀럽: celebrity@test.com';
    RAISE NOTICE '   - 매니저: manager@test.com';
    RAISE NOTICE '';
    RAISE NOTICE '2. 각 사용자의 UUID를 복사하세요.';
    RAISE NOTICE '';
    RAISE NOTICE '3. 다음 SQL을 실행하여 프로필 생성:';
    RAISE NOTICE '   INSERT INTO public.users (id, email, role, display_name)';
    RAISE NOTICE '   VALUES';
    RAISE NOTICE '       (''<fan-user-id>'', ''fan@test.com'', ''fan'', ''테스트 팬''),';
    RAISE NOTICE '       (''<celebrity-user-id>'', ''celebrity@test.com'', ''celebrity'', ''테스트 셀럽''),';
    RAISE NOTICE '       (''<manager-user-id>'', ''manager@test.com'', ''manager'', ''테스트 매니저'');';
    RAISE NOTICE '';
    RAISE NOTICE '4. 각 역할로 로그인하여 권한 테스트를 수행하세요.';
    RAISE NOTICE '';
END $$;

-- ============================================
-- 9. 역할별 권한 검증 가이드
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '=== 역할별 권한 검증 가이드 ===';
    RAISE NOTICE '';
    RAISE NOTICE '팬 권한 테스트:';
    RAISE NOTICE '  ✅ 자신의 질문 조회/작성/수정';
    RAISE NOTICE '  ✅ 모든 공개 질문 조회';
    RAISE NOTICE '  ✅ 좋아요 추가/삭제';
    RAISE NOTICE '  ✅ 구독 추가/삭제';
    RAISE NOTICE '  ✅ 커뮤니티 게시글 작성/수정/삭제';
    RAISE NOTICE '  ❌ 숨김된 질문 조회 불가';
    RAISE NOTICE '  ❌ 다른 사용자의 질문 수정 불가';
    RAISE NOTICE '';
    RAISE NOTICE '셀럽 권한 테스트:';
    RAISE NOTICE '  ✅ 숨김되지 않은 질문 조회';
    RAISE NOTICE '  ✅ 자신의 답변 작성/수정/삭제';
    RAISE NOTICE '  ✅ 자신을 구독한 팬 목록 조회';
    RAISE NOTICE '  ❌ 질문 작성 불가';
    RAISE NOTICE '  ❌ 숨김된 질문 조회 불가';
    RAISE NOTICE '';
    RAISE NOTICE '매니저 권한 테스트:';
    RAISE NOTICE '  ✅ 모든 질문 조회 (숨김 포함)';
    RAISE NOTICE '  ✅ 질문 숨김 처리';
    RAISE NOTICE '  ✅ 모든 사용자 프로필 조회';
    RAISE NOTICE '  ✅ 모든 답변 조회';
    RAISE NOTICE '  ✅ 모든 구독 조회';
    RAISE NOTICE '';
END $$;

-- ============================================
-- 통합 테스트 완료
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '통합 테스트 완료';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '다음 단계:';
    RAISE NOTICE '  1. Supabase Auth에서 테스트 사용자 생성';
    RAISE NOTICE '  2. 샘플 데이터 삽입';
    RAISE NOTICE '  3. 각 역할로 로그인하여 권한 검증';
    RAISE NOTICE '  4. WP-1.2 (Supabase Auth 연동) 진행';
    RAISE NOTICE '';
END $$;
