# Profanity Filter Edge Function

## 개요

이 Edge Function은 질문 내용을 분석하여 욕설/비속어를 탐지하고 위험도를 계산합니다.

## 배포 방법

### 방법 1: Supabase CLI 사용 (권장)

```bash
# Supabase CLI 설치 (아직 설치하지 않은 경우)
npm install -g supabase

# Supabase 프로젝트 연결
supabase link --project-ref <your-project-ref>

# Edge Function 배포
supabase functions deploy profanity-filter
```

### 방법 2: Supabase Dashboard 사용

1. Supabase Dashboard 접속
2. Edge Functions 메뉴로 이동
3. "Create a new function" 클릭
4. Function 이름: `profanity-filter`
5. `index.ts` 파일 내용을 복사하여 붙여넣기
6. "Deploy" 클릭

## 환경 변수 설정

Supabase Dashboard > Settings > Edge Functions에서 다음 환경 변수를 설정해야 합니다:

- `SUPABASE_URL`: Supabase 프로젝트 URL
- `SUPABASE_SERVICE_ROLE_KEY`: Supabase Service Role Key (RLS 우회용)

**주의**: Service Role Key는 절대 클라이언트에 노출되어서는 안 됩니다. Edge Function에서만 사용해야 합니다.

## 사용 방법

### Flutter 클라이언트에서 호출

```dart
import 'package:aura_app/features/manager/services/profanity_filter_service.dart';

// 욕설 필터링 실행
final result = await ProfanityFilterService.checkProfanity(
  content: '질문 내용',
  questionId: 'question-id', // 선택
);

print('탐지 여부: ${result.detected}');
print('위험도: ${result.riskLevel}');
print('점수: ${result.riskScore}');
```

## 기능

1. **욕설 사전 기반 필터링**
   - 한국어 욕설 (강함/중간/약함)
   - 외래어 욕설

2. **정규식 기반 변형 욕설 탐지**
   - 특수문자 변형 (시@발)
   - 숫자 변형 (시0발)
   - 공백 삽입 (시 발)

3. **위험도 스코어링**
   - 점수 범위: 0-100
   - 레벨: low (0-30), medium (31-70), high (71-100)

4. **자동 조치**
   - high: 자동 숨김 처리
   - medium: 플래그만
   - low: 조치 없음

5. **필터링 로그 저장**
   - `filtering_logs` 테이블에 기록
   - 탐지된 욕설, 위험도, 조치 정보 저장

## 테스트

Edge Function을 테스트하려면 Supabase Dashboard > Edge Functions > profanity-filter > "Invoke function"을 사용하거나, Flutter 앱에서 직접 호출할 수 있습니다.

