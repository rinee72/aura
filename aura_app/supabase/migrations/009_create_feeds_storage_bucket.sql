-- ============================================
-- WP-3.5: 셀럽 피드 작성 - feeds Storage 버킷 RLS 정책
-- ============================================
-- 
-- 피드 이미지 업로드를 위한 Storage 버킷 RLS 정책 설정
-- 
-- 주의: 이 SQL을 실행하기 전에 Supabase Dashboard에서
-- 'feeds' 버킷을 수동으로 생성해야 합니다.
-- 
-- 생성 방법:
-- 1. Supabase Dashboard > Storage > New bucket
-- 2. Bucket name: feeds
-- 3. Public bucket: true (체크)
-- 4. Create bucket
-- ============================================

-- 기존 정책 모두 삭제
DROP POLICY IF EXISTS "Public feed image access" ON storage.objects;
DROP POLICY IF EXISTS "Celebrities can upload feed images" ON storage.objects;
DROP POLICY IF EXISTS "Celebrities can update feed images" ON storage.objects;
DROP POLICY IF EXISTS "Celebrities can delete feed images" ON storage.objects;

-- 공개 읽기 정책 (모든 사용자가 피드 이미지를 조회할 수 있음)
-- 공개 버킷이면 자동으로 적용되지만, 명시적으로 설정
CREATE POLICY "Public feed image access"
ON storage.objects
FOR SELECT
USING (bucket_id = 'feeds');

-- 인증된 셀럽이 피드 이미지를 업로드할 수 있도록 설정
-- 경로 형식: {userId}/{timestamp}_{index}.{extension}
-- name 필드는 경로를 포함 (예: abc123-def456-ghi789/1234567890_0.jpg)
CREATE POLICY "Celebrities can upload feed images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'feeds' AND
  EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid() 
    AND u.role = 'celebrity'
    AND split_part(name, '/', 1) = auth.uid()::text
  )
);

-- 인증된 셀럽이 자신의 피드 이미지만 업데이트할 수 있도록 설정
CREATE POLICY "Celebrities can update feed images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'feeds' AND
  EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid() 
    AND u.role = 'celebrity'
    AND split_part(name, '/', 1) = auth.uid()::text
  )
)
WITH CHECK (
  bucket_id = 'feeds' AND
  EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid() 
    AND u.role = 'celebrity'
    AND split_part(name, '/', 1) = auth.uid()::text
  )
);

-- 인증된 셀럽이 자신의 피드 이미지만 삭제할 수 있도록 설정
CREATE POLICY "Celebrities can delete feed images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'feeds' AND
  EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = auth.uid() 
    AND u.role = 'celebrity'
    AND split_part(name, '/', 1) = auth.uid()::text
  )
);

