# WP-0.4: 프로덕션 환경 실행 스크립트
# Production 환경으로 Flutter 앱을 실행합니다.
#
# ⚠️ 주의: 프로덕션 환경은 실제 사용자 데이터를 사용합니다.
# 신중하게 사용하세요.

Write-Host "========================================" -ForegroundColor Red
Write-Host "AURA 프로덕션 환경 실행" -ForegroundColor Red
Write-Host "WP-0.4: 개발/스테이징/프로덕션 환경 분리" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""
Write-Host "⚠️  경고: 프로덕션 환경은 실제 사용자 데이터를 사용합니다." -ForegroundColor Yellow
Write-Host "   계속하시겠습니까? (Y/N)" -ForegroundColor Yellow
$confirm = Read-Host

if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "실행이 취소되었습니다." -ForegroundColor Gray
    exit 0
}

Write-Host ""

$projectPath = "C:\modu\aura_app"

# 프로젝트 경로로 이동
if (-not (Test-Path $projectPath)) {
    Write-Host "❌ 프로젝트 경로를 찾을 수 없습니다: $projectPath" -ForegroundColor Red
    exit 1
}

Set-Location $projectPath

# 환경 파일 확인
Write-Host "[1/3] 환경 파일 확인..." -ForegroundColor Yellow
$envFile = ".env.production"
if (-not (Test-Path $envFile)) {
    Write-Host "⚠️  $envFile 파일이 없습니다." -ForegroundColor Yellow
    Write-Host "   .env.production.example을 복사하여 $envFile 파일을 생성하세요." -ForegroundColor Gray
    Write-Host "   또는 기본 .env 파일을 사용합니다." -ForegroundColor Gray
} else {
    Write-Host "✅ $envFile 파일 확인됨" -ForegroundColor Green
}
Write-Host ""

# Flutter 실행
Write-Host "[2/3] Flutter 앱 실행 중..." -ForegroundColor Yellow
Write-Host "   환경: Production" -ForegroundColor Gray
Write-Host "   Supabase 프로젝트: aura-mvp-prod" -ForegroundColor Gray
Write-Host ""

# dart-define으로 환경 전달
flutter run --dart-define=ENVIRONMENT=production

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "프로덕션 환경 실행 완료" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

