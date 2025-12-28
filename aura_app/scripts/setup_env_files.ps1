# WP-0.4: 환경 파일 생성 스크립트
# 2개 프로젝트 구성 (dev, prod) - staging은 dev와 동일한 프로젝트 사용

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "환경 파일 생성 스크립트" -ForegroundColor Cyan
Write-Host "WP-0.4: 개발/스테이징/프로덕션 환경 분리" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectPath = "C:\modu\aura_app"
Set-Location $projectPath

# .env.development 파일 생성
Write-Host "[1/3] .env.development 파일 생성..." -ForegroundColor Yellow
$devContent = @"
# AURA Development Environment Configuration
# WP-0.4: 개발/스테이징/프로덕션 환경 분리
# Supabase 프로젝트: aura-mvp-dev

DEV_SUPABASE_URL=your-dev-project-url-here
DEV_SUPABASE_ANON_KEY=your-dev-anon-key-here
"@

$devContent | Out-File -FilePath ".env.development" -Encoding utf8 -NoNewline
Write-Host "✅ .env.development 파일 생성 완료" -ForegroundColor Green
Write-Host "   ⚠️  Supabase 프로젝트 정보를 입력하세요!" -ForegroundColor Yellow
Write-Host ""

# .env.staging 파일 생성 (dev와 동일한 프로젝트 사용)
Write-Host "[2/3] .env.staging 파일 생성..." -ForegroundColor Yellow
$stagingContent = @"
# AURA Staging Environment Configuration
# WP-0.4: 개발/스테이징/프로덕션 환경 분리
# ⚠️ 주의: 무료 플랜 제한으로 인해 Development와 동일한 프로젝트를 사용합니다.
# Supabase 프로젝트: aura-mvp-dev (Development와 동일)

STAGING_SUPABASE_URL=your-dev-project-url-here
STAGING_SUPABASE_ANON_KEY=your-dev-anon-key-here
"@

$stagingContent | Out-File -FilePath ".env.staging" -Encoding utf8 -NoNewline
Write-Host "✅ .env.staging 파일 생성 완료" -ForegroundColor Green
Write-Host "   ⚠️  Development와 동일한 Supabase 프로젝트 정보를 입력하세요!" -ForegroundColor Yellow
Write-Host ""

# .env.production 파일 생성
Write-Host "[3/3] .env.production 파일 생성..." -ForegroundColor Yellow
$prodContent = @"
# AURA Production Environment Configuration
# WP-0.4: 개발/스테이징/프로덕션 환경 분리
# ⚠️ 주의: 프로덕션 환경은 실제 사용자 데이터를 사용합니다.
# Supabase 프로젝트: aura-mvp-prod

PROD_SUPABASE_URL=your-prod-project-url-here
PROD_SUPABASE_ANON_KEY=your-prod-anon-key-here
"@

$prodContent | Out-File -FilePath ".env.production" -Encoding utf8 -NoNewline
Write-Host "✅ .env.production 파일 생성 완료" -ForegroundColor Green
Write-Host "   ⚠️  Supabase 프로젝트 정보를 입력하세요!" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "환경 파일 생성 완료" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 다음 단계:" -ForegroundColor Cyan
Write-Host "   1. Supabase 대시보드에서 프로젝트 정보 확인" -ForegroundColor Gray
Write-Host "      - Settings → API → Project URL 및 anon public key" -ForegroundColor Gray
Write-Host ""
Write-Host "   2. 각 .env 파일에 실제 값 입력:" -ForegroundColor Gray
Write-Host "      - .env.development: aura-mvp-dev 프로젝트 정보" -ForegroundColor Gray
Write-Host "      - .env.staging: aura-mvp-dev 프로젝트 정보 (dev와 동일)" -ForegroundColor Gray
Write-Host "      - .env.production: aura-mvp-prod 프로젝트 정보" -ForegroundColor Gray
Write-Host ""
Write-Host "   3. 환경별 연결 테스트:" -ForegroundColor Gray
Write-Host "      - .\scripts\run_dev.ps1" -ForegroundColor Gray
Write-Host "      - .\scripts\run_staging.ps1" -ForegroundColor Gray
Write-Host "      - .\scripts\run_prod.ps1" -ForegroundColor Gray
Write-Host ""

