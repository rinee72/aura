-- 프로필 이미지 업로드를 위한 Storage 버킷 RLS 정책 수정
-- 
-- WP-3.4: 셀럽 프로필 관리
-- 
-- 문제: 파일 이름 파싱 로직이 올바르게 작동하지 않아 RLS 정책 위반 발생
-- 해결: 더 간단하고 확실한 정책으로 수정

-- 기존 정책 모두 삭제
DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;

-- 공개 읽기 정책 (모든 사용자가 프로필 이미지를 조회할 수 있음)
-- 공개 버킷이면 자동으로 적용되지만, 명시적으로 설정
DROP POLICY IF EXISTS "Public avatar access" ON storage.objects;
CREATE POLICY "Public avatar access"
ON storage.objects
FOR SELECT
USING (bucket_id = 'avatars');

-- 인증된 사용자가 자신의 프로필 이미지만 업로드할 수 있도록 설정
-- 파일 이름 형식: {userId}.{extension} (예: abc123-def456-ghi789.jpg)
-- name 필드는 파일 이름만 포함 (경로 없음)
CREATE POLICY "Users can upload own avatar"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.uid()::text = split_part(name, '.', 1)
);

-- 인증된 사용자가 자신의 프로필 이미지만 업데이트할 수 있도록 설정
CREATE POLICY "Users can update own avatar"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  auth.uid()::text = split_part(name, '.', 1)
)
WITH CHECK (
  bucket_id = 'avatars' AND
  auth.uid()::text = split_part(name, '.', 1)
);

-- 인증된 사용자가 자신의 프로필 이미지만 삭제할 수 있도록 설정
CREATE POLICY "Users can delete own avatar"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  auth.uid()::text = split_part(name, '.', 1)
);


