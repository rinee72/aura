-- ============================================
-- AURA MVP: 스키마 검증 스크립트
-- WP-1.1: 데이터베이스 스키마 검증
-- ============================================
-- 
-- 이 스크립트는 마이그레이션 후 스키마가 올바르게 생성되었는지 검증합니다.
-- 
-- 실행 방법:
-- Supabase Dashboard > SQL Editor에서 실행
-- ============================================

-- ============================================
-- 1. 테이블 존재 확인
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
        RAISE EXCEPTION '누락된 테이블: %', array_to_string(missing_tables, ', ');
    END IF;
END $$;

-- ============================================
-- 2. RLS 활성화 확인
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
            RAISE NOTICE '⚠️ RLS 비활성화: %', table_name;
        ELSE
            RAISE NOTICE '✅ RLS 활성화: %', table_name;
        END IF;
    END LOOP;
END $$;

-- ============================================
-- 3. 인덱스 존재 확인
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
        RAISE NOTICE '⚠️ 누락된 인덱스: %', array_to_string(missing_indexes, ', ');
    END IF;
END $$;

-- ============================================
-- 4. 외래키 제약조건 확인
-- ============================================

DO $$
DECLARE
    fk_count INTEGER;
BEGIN
    RAISE NOTICE '=== 외래키 제약조건 확인 ===';
    
    -- questions.user_id -> users.id
    SELECT COUNT(*) INTO fk_count
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'questions'
    AND kcu.column_name = 'user_id';
    
    IF fk_count > 0 THEN
        RAISE NOTICE '✅ 외래키 존재: questions.user_id -> users.id';
    ELSE
        RAISE NOTICE '❌ 외래키 없음: questions.user_id -> users.id';
    END IF;
    
    -- answers.question_id -> questions.id
    SELECT COUNT(*) INTO fk_count
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'answers'
    AND kcu.column_name = 'question_id';
    
    IF fk_count > 0 THEN
        RAISE NOTICE '✅ 외래키 존재: answers.question_id -> questions.id';
    ELSE
        RAISE NOTICE '❌ 외래키 없음: answers.question_id -> questions.id';
    END IF;
END $$;

-- ============================================
-- 5. RLS 정책 개수 확인
-- ============================================

DO $$
DECLARE
    policy_count INTEGER;
    table_name TEXT;
    expected_policies INTEGER;
BEGIN
    RAISE NOTICE '=== RLS 정책 확인 ===';
    
    -- users 테이블 정책 (최소 3개: 자신 조회, 자신 수정, 매니저 조회)
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'users';
    
    IF policy_count >= 3 THEN
        RAISE NOTICE '✅ users 테이블 정책: %개', policy_count;
    ELSE
        RAISE NOTICE '⚠️ users 테이블 정책 부족: %개 (최소 3개 필요)', policy_count;
    END IF;
    
    -- questions 테이블 정책 (최소 5개)
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'questions';
    
    IF policy_count >= 5 THEN
        RAISE NOTICE '✅ questions 테이블 정책: %개', policy_count;
    ELSE
        RAISE NOTICE '⚠️ questions 테이블 정책 부족: %개 (최소 5개 필요)', policy_count;
    END IF;
    
    -- answers 테이블 정책 (최소 3개)
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename = 'answers';
    
    IF policy_count >= 3 THEN
        RAISE NOTICE '✅ answers 테이블 정책: %개', policy_count;
    ELSE
        RAISE NOTICE '⚠️ answers 테이블 정책 부족: %개 (최소 3개 필요)', policy_count;
    END IF;
END $$;

-- ============================================
-- 6. 트리거 함수 확인
-- ============================================

DO $$
DECLARE
    trigger_count INTEGER;
BEGIN
    RAISE NOTICE '=== 트리거 함수 확인 ===';
    
    -- updated_at 트리거 확인
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger
    WHERE tgname LIKE 'update_%_updated_at';
    
    IF trigger_count >= 5 THEN
        RAISE NOTICE '✅ updated_at 트리거: %개', trigger_count;
    ELSE
        RAISE NOTICE '⚠️ updated_at 트리거 부족: %개 (최소 5개 필요)', trigger_count;
    END IF;
    
    -- like_count 업데이트 트리거 확인
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger
    WHERE tgname = 'trigger_update_question_like_count';
    
    IF trigger_count > 0 THEN
        RAISE NOTICE '✅ like_count 업데이트 트리거 존재';
    ELSE
        RAISE NOTICE '❌ like_count 업데이트 트리거 없음';
    END IF;
    
    -- question_status 업데이트 트리거 확인
    SELECT COUNT(*) INTO trigger_count
    FROM pg_trigger
    WHERE tgname = 'trigger_update_question_status';
    
    IF trigger_count > 0 THEN
        RAISE NOTICE '✅ question_status 업데이트 트리거 존재';
    ELSE
        RAISE NOTICE '❌ question_status 업데이트 트리거 없음';
    END IF;
END $$;

-- ============================================
-- 검증 완료
-- ============================================

RAISE NOTICE '=== 스키마 검증 완료 ===';
RAISE NOTICE '다음 단계: 샘플 데이터 삽입 테스트 및 역할별 접근 권한 검증';
