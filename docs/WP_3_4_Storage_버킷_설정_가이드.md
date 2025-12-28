# WP-3.4: Supabase Storage 버킷 설정 가이드

## 문제 상황

프로필 이미지 업로드 시 다음과 같은 오류가 발생하는 경우:

```
이미지 업로드 실패: StorageException(message: Bucket not found, statusCode: 404, error: Bucket not found)
```

이는 Supabase Storage에 'avatars' 버킷이 존재하지 않아서 발생하는 오류입니다.

## 해결 방법

### 1. Supabase 대시보드에서 버킷 생성

Supabase Storage 버킷은 SQL 마이그레이션으로 직접 생성할 수 없으므로, Supabase 대시보드에서 수동으로 생성해야 합니다.

#### 단계별 가이드

1. **Supabase 대시보드 접속**
   - [Supabase 대시보드](https://app.supabase.com) 접속
   - 프로젝트 선택

2. **Storage 메뉴 이동**
   - 왼쪽 사이드바에서 "Storage" 메뉴 클릭

3. **새 버킷 생성**
   - "New bucket" 버튼 클릭
   - 다음 설정 입력:
     - **Bucket name**: `avatars`
     - **Public bucket**: ✅ 체크 (공개 접근 허용)
     - **File size limit**: `5242880` (5MB)
     - **Allowed MIME types**: 
       - `image/jpeg`
       - `image/png`
       - `image/gif`
       - `image/webp`
   - "Create bucket" 버튼 클릭

4. **RLS 정책 확인**
   - 버킷 생성 후, "Policies" 탭에서 RLS 정책이 올바르게 설정되었는지 확인
   - 공개 버킷의 경우 읽기 접근은 자동으로 허용됩니다
   - 업로드/수정/삭제는 인증된 사용자만 가능하도록 설정되어 있습니다

### 2. 마이그레이션 파일 실행 (선택)

RLS 정책을 더 세밀하게 제어하려면 마이그레이션 파일을 실행할 수 있습니다:

```bash
# Supabase CLI를 사용하는 경우
supabase db push

# 또는 Supabase 대시보드의 SQL Editor에서
# supabase/migrations/006_create_avatars_storage_bucket.sql 파일의 내용을 실행
```

**주의**: 마이그레이션 파일은 RLS 정책만 설정하며, 버킷 자체는 대시보드에서 수동으로 생성해야 합니다.

### 3. 버킷 생성 확인

버킷이 올바르게 생성되었는지 확인:

1. Storage 메뉴에서 `avatars` 버킷이 목록에 표시되는지 확인
2. 버킷을 클릭하여 상세 정보 확인
3. "Public" 상태가 활성화되어 있는지 확인

## 파일 경로 형식

프로필 이미지는 다음 형식으로 저장됩니다:

```
avatars/{userId}.{extension}
```

예시:
- `avatars/abc123-def456-ghi789.jpg`
- `avatars/xyz789-uvw456-rst123.png`

## RLS 정책 설명

마이그레이션 파일(`006_create_avatars_storage_bucket.sql`)에 포함된 RLS 정책:

1. **Users can upload own avatar**: 사용자가 자신의 프로필 이미지만 업로드 가능
2. **Users can update own avatar**: 사용자가 자신의 프로필 이미지만 수정 가능
3. **Users can delete own avatar**: 사용자가 자신의 프로필 이미지만 삭제 가능

파일 이름의 첫 번째 부분(확장자 제외)이 현재 사용자의 ID와 일치하는지 확인하여 권한을 검증합니다.

## 문제 해결

### 버킷을 생성했는데도 여전히 오류가 발생하는 경우

1. **버킷 이름 확인**: 정확히 `avatars` (소문자)인지 확인
2. **공개 버킷 설정 확인**: Public bucket이 체크되어 있는지 확인
3. **RLS 정책 확인**: Storage → Policies에서 정책이 올바르게 설정되었는지 확인
4. **앱 재시작**: 버킷 생성 후 앱을 완전히 재시작

### 권한 오류가 발생하는 경우

1. **인증 상태 확인**: 사용자가 올바르게 로그인되어 있는지 확인
2. **RLS 정책 확인**: Storage → Policies에서 업로드 정책이 올바르게 설정되었는지 확인
3. **파일 이름 형식 확인**: 파일 이름이 `{userId}.{extension}` 형식인지 확인

## 참고 자료

- [Supabase Storage 문서](https://supabase.com/docs/guides/storage)
- [Supabase Storage RLS 정책](https://supabase.com/docs/guides/storage/security/access-control)


