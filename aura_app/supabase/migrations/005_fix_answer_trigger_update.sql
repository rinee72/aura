-- 답변 UPDATE 시 질문 상태 자동 업데이트 트리거 수정
-- 
-- WP-3.2: 답변 작성 시스템
-- 
-- 임시저장 답변을 게시로 전환하거나, 게시된 답변을 임시저장으로 변경할 때
-- 질문 상태가 자동으로 업데이트되도록 트리거 수정

-- 기존 함수 수정: UPDATE 이벤트 처리 추가
CREATE OR REPLACE FUNCTION update_question_status_on_answer()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- 답변 생성 시: 게시된 답변이면 질문 상태를 'answered'로 변경
        IF NEW.is_draft = false THEN
            UPDATE public.questions
            SET status = 'answered'
            WHERE id = NEW.question_id;
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        -- 임시저장 → 게시 전환
        IF OLD.is_draft = true AND NEW.is_draft = false THEN
            UPDATE public.questions
            SET status = 'answered'
            WHERE id = NEW.question_id;
        -- 게시 → 임시저장 전환
        ELSIF OLD.is_draft = false AND NEW.is_draft = true THEN
            UPDATE public.questions
            SET status = 'pending'
            WHERE id = NEW.question_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        -- 답변 삭제 시: 질문 상태를 'pending'으로 복원
        UPDATE public.questions
        SET status = 'pending'
        WHERE id = OLD.question_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 트리거에 UPDATE 추가
DROP TRIGGER IF EXISTS trigger_update_question_status ON public.answers;
CREATE TRIGGER trigger_update_question_status
    AFTER INSERT OR UPDATE OR DELETE ON public.answers
    FOR EACH ROW
    EXECUTE FUNCTION update_question_status_on_answer();

