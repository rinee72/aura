// ============================================
// AURA MVP: 욕설 필터링 Edge Function
// WP-4.3: AI 악플 필터링 시스템 (Edge Function)
// ============================================
// 
// 이 Edge Function은 질문 내용을 분석하여 욕설/비속어를 탐지하고
// 위험도 점수를 계산합니다.
//
// 배포 방법:
// 1. Supabase CLI 사용: supabase functions deploy profanity-filter
// 2. 또는 Supabase Dashboard > Edge Functions에서 수동 배포
// ============================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ============================================
// 1. 욕설 사전 정의
// ============================================

// 한국어 욕설 사전 (포괄적)
const PROFANITY_DICTIONARY = {
  // 강한 욕설 (가중치: 10)
  strong: [
    '시발', '씨발', '병신', '개새끼', '좆', '지랄', '미친놈', '미친년',
    '개같은', '개소리', '좆같은', '좆도', '좆나', '좆만', '좆밥',
    '씹', '씹새끼', '씹년', '씹놈', '씹창', '씹할', '씹것',
    '호로', '호로새끼', '호로년', '호로놈',
    '조센징', '쪽바리', '왜놈',
  ],
  // 중간 욕설 (가중치: 5)
  medium: [
    '미친', '미쳤어', '미쳤나', '미쳤네', '미쳤다',
    '바보', '멍청이', '등신', '찐따', '찐찐따',
    '개', '개같이', '개처럼', '개새', '개지랄',
    '젠장', '망할', '망했어', '망해', '망해라',
    '죽어', '죽어라', '죽여', '죽이고', '죽일',
    '닥쳐', '닥치고', '닥쳐라',
  ],
  // 약한 욕설/비속어 (가중치: 2)
  weak: [
    '바보', '멍청', '등신', '찐따',
    '젠장', '망할', '망해',
    '헐', '헉', '어이',
  ],
};

// 외래어 욕설 (가중치: 8)
const FOREIGN_PROFANITY = [
  'fuck', 'shit', 'damn', 'bitch', 'asshole', 'bastard',
  'stupid', 'idiot', 'moron', 'retard',
];

// ============================================
// 2. 정규식 패턴 정의 (변형 욕설 탐지)
// ============================================

const PROFANITY_PATTERNS = [
  // 특수문자 변형: 시@발, 시#발, 시$발 등
  /시[0-9@#$%^&*!~`]발/gi,
  /씨[0-9@#$%^&*!~`]발/gi,
  /병[0-9@#$%^&*!~`]신/gi,
  /개[0-9@#$%^&*!~`]새끼/gi,
  /좆[0-9@#$%^&*!~`]/gi,
  /지[0-9@#$%^&*!~`]랄/gi,
  
  // 숫자 변형: 시0발, 시1발 등
  /시[0-9]발/gi,
  /씨[0-9]발/gi,
  /병[0-9]신/gi,
  
  // 공백 삽입: 시 발, 씨 발 등
  /시\s+발/gi,
  /씨\s+발/gi,
  /병\s+신/gi,
  /개\s+새끼/gi,
  
  // 반복: 시발시발, 씨발씨발 등
  /(시발|씨발|병신|개새끼){2,}/gi,
];

// ============================================
// 3. 위험도 계산 함수
// ============================================

interface ProfanityMatch {
  word: string;
  weight: number;
  type: 'strong' | 'medium' | 'weak' | 'foreign' | 'pattern';
}

function calculateRiskScore(matches: ProfanityMatch[]): {
  score: number;
  level: 'low' | 'medium' | 'high';
} {
  if (matches.length === 0) {
    return { score: 0, level: 'low' };
  }

  // 가중치 합계 계산
  let totalWeight = 0;
  for (const match of matches) {
    totalWeight += match.weight;
  }

  // 위험도 점수 계산 (0-100)
  // 기본 점수: 가중치 합계
  // 추가 점수: 욕설 개수에 따른 보너스 (최대 20점)
  const baseScore = Math.min(totalWeight, 80);
  const bonusScore = Math.min(matches.length * 2, 20);
  const finalScore = Math.min(baseScore + bonusScore, 100);

  // 위험도 레벨 결정
  let level: 'low' | 'medium' | 'high';
  if (finalScore <= 30) {
    level = 'low';
  } else if (finalScore <= 70) {
    level = 'medium';
  } else {
    level = 'high';
  }

  return { score: finalScore, level };
}

// ============================================
// 4. 욕설 탐지 함수
// ============================================

function detectProfanity(content: string): ProfanityMatch[] {
  const matches: ProfanityMatch[] = [];
  const normalizedContent = content.toLowerCase();

  // 1. 기본 욕설 사전 검사
  for (const [level, words] of Object.entries(PROFANITY_DICTIONARY)) {
    const weight = level === 'strong' ? 10 : level === 'medium' ? 5 : 2;
    for (const word of words) {
      if (normalizedContent.includes(word.toLowerCase())) {
        matches.push({
          word,
          weight,
          type: level as 'strong' | 'medium' | 'weak',
        });
      }
    }
  }

  // 2. 외래어 욕설 검사
  for (const word of FOREIGN_PROFANITY) {
    const regex = new RegExp(`\\b${word}\\b`, 'gi');
    if (regex.test(content)) {
      matches.push({
        word,
        weight: 8,
        type: 'foreign',
      });
    }
  }

  // 3. 정규식 패턴 검사 (변형 욕설)
  for (const pattern of PROFANITY_PATTERNS) {
    const regexMatches = content.matchAll(pattern);
    for (const match of regexMatches) {
      if (match[0]) {
        matches.push({
          word: match[0],
          weight: 10, // 변형 욕설은 강한 욕설로 간주
          type: 'pattern',
        });
      }
    }
  }

  // 중복 제거 (같은 단어가 여러 번 발견되면 한 번만 기록)
  const uniqueMatches: ProfanityMatch[] = [];
  const seenWords = new Set<string>();
  for (const match of matches) {
    const key = `${match.word}-${match.type}`;
    if (!seenWords.has(key)) {
      seenWords.add(key);
      uniqueMatches.push(match);
    }
  }

  return uniqueMatches;
}

// ============================================
// 5. Edge Function 핸들러
// ============================================

serve(async (req) => {
  try {
    // CORS 헤더 설정
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
    };

    // OPTIONS 요청 처리 (CORS preflight)
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }

    // 요청 본문 파싱
    const { questionId, content } = await req.json();

    if (!content || typeof content !== "string") {
      return new Response(
        JSON.stringify({ error: "content is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 욕설 탐지
    const matches = detectProfanity(content);
    const detectedWords = matches.map((m) => m.word);

    // 위험도 계산
    const { score, level } = calculateRiskScore(matches);

    // 조치 결정
    let actionTaken: 'flagged' | 'auto_hidden' | 'none' = 'none';
    if (level === 'high') {
      actionTaken = 'auto_hidden'; // 위험도가 높으면 자동 숨김
    } else if (level === 'medium') {
      actionTaken = 'flagged'; // 중간 위험도는 플래그만
    }

    // Supabase 클라이언트 생성 (service_role 키 사용)
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error("Supabase 환경 변수가 설정되지 않았습니다.");
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 필터링 로그 저장 (questionId가 제공된 경우)
    if (questionId) {
      try {
        const { error: logError } = await supabase
          .from("filtering_logs")
          .insert({
            question_id: questionId,
            content: content,
            detected_profanities: detectedWords,
            risk_score: score,
            risk_level: level,
            action_taken: actionTaken,
          });

        if (logError) {
          console.error("필터링 로그 저장 실패:", logError);
          // 로그 저장 실패는 응답에 영향을 주지 않음
        }

        // 자동 숨김 처리 (위험도가 높은 경우)
        if (actionTaken === 'auto_hidden') {
          try {
            const { error: hideError } = await supabase
              .from("questions")
              .update({
                is_hidden: true,
                hidden_reason: `자동 필터링: 욕설 탐지 (위험도: ${level}, 점수: ${score})`,
                hidden_at: new Date().toISOString(),
                hidden_by: null, // 시스템 자동 처리
              })
              .eq("id", questionId);

            if (hideError) {
              console.error("자동 숨김 처리 실패:", hideError);
              // 숨김 처리 실패는 응답에 영향을 주지 않음
            }
          } catch (hideErr) {
            console.error("자동 숨김 처리 중 오류:", hideErr);
          }
        }
      } catch (err) {
        console.error("필터링 로그 처리 중 오류:", err);
        // 오류가 발생해도 응답은 정상 반환
      }
    }

    // 응답 반환
    return new Response(
      JSON.stringify({
        success: true,
        detected: matches.length > 0,
        detectedProfanities: detectedWords,
        riskScore: score,
        riskLevel: level,
        actionTaken: actionTaken,
        matchCount: matches.length,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Edge Function 오류:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Content-Type": "application/json",
        },
      }
    );
  }
});

