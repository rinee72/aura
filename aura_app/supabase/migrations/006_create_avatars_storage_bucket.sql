-- 프로필 이미지 업로드를 위한 Storage 버킷 생성
-- 
-- WP-3.4: 셀럽 프로필 관리
-- 
-- Supabase Storage에 'avatars' 버킷을 생성하고 공개 접근 권한을 설정합니다.

-- Storage 버킷 생성 (SQL로 직접 생성할 수 없으므로 주석으로 안내)
-- Supabase 대시보드에서 수동으로 생성해야 합니다:
-- 1. Supabase 대시보드 → Storage 메뉴
-- 2. "New bucket" 클릭
-- 3. Bucket name: "avatars"
-- 4. Public bucket: 체크 (공개 접근 허용)
-- 5. File size limit: 5242880 (5MB)
-- 6. Allowed MIME types: image/jpeg, image/png, image/gif, image/webp
-- 7. "Create bucket" 클릭

-- 참고: Supabase Storage 버킷은 SQL 마이그레이션으로 직접 생성할 수 없습니다.
-- 위의 단계를 따라 Supabase 대시보드에서 수동으로 생성해야 합니다.

-- RLS 정책 설정 (버킷 생성 후 실행)
-- 참고: storage.objects 테이블에 대한 RLS 정책은 Supabase가 자동으로 관리합니다.
-- 공개 버킷의 경우 모든 사용자가 조회할 수 있으며, 업로드/수정/삭제는 인증된 사용자만 가능합니다.

-- 공개 읽기 접근 정책 (모든 사용자가 프로필 이미지를 조회할 수 있음)
-- 공개 버킷으로 생성하면 자동으로 적용되지만, 명시적으로 설정할 수도 있습니다.
-- 주의: 이미 정책이 존재할 수 있으므로 IF NOT EXISTS를 사용하거나 수동으로 확인하세요.

-- 사용자가 자신의 프로필 이미지만 업로드할 수 있도록 설정
-- 파일 경로 형식: {userId}.{extension} (예: abc123.jpg)
-- 참고: 공개 버킷이라도 INSERT 정책이 필요합니다.
DO $$
BEGIN
  -- 기존 정책 삭제 (있다면)
  DROP POLICY IF EXISTS "Users can upload own avatar" ON storage.objects;
  
  -- 새 정책 생성
  CREATE POLICY "Users can upload own avatar"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (regexp_split_to_array(name, '\.'))[1]
  );
END $$;

-- 사용자가 자신의 프로필 이미지만 업데이트할 수 있도록 설정
DO $$
BEGIN
  -- 기존 정책 삭제 (있다면)
  DROP POLICY IF EXISTS "Users can update own avatar" ON storage.objects;
  
  -- 새 정책 생성
  CREATE POLICY "Users can update own avatar"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (regexp_split_to_array(name, '\.'))[1]
  );
END $$;

-- 사용자가 자신의 프로필 이미지만 삭제할 수 있도록 설정
DO $$
BEGIN
  -- 기존 정책 삭제 (있다면)
  DROP POLICY IF EXISTS "Users can delete own avatar" ON storage.objects;
  
  -- 새 정책 생성
  CREATE POLICY "Users can delete own avatar"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (regexp_split_to_array(name, '\.'))[1]
  );
END $$;

