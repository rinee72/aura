# WP-0.4: 스테이징 환경 실행 스크립트
# Staging 환경으로 Flutter 앱을 실행합니다.

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AURA 스테이징 환경 실행" -ForegroundColor Cyan
Write-Host "WP-0.4: 개발/스테이징/프로덕션 환경 분리" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
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
$envFile = ".env.staging"
if (-not (Test-Path $envFile)) {
    Write-Host "⚠️  $envFile 파일이 없습니다." -ForegroundColor Yellow
    Write-Host "   .env.staging.example을 복사하여 $envFile 파일을 생성하세요." -ForegroundColor Gray
    Write-Host "   또는 기본 .env 파일을 사용합니다." -ForegroundColor Gray
} else {
    Write-Host "✅ $envFile 파일 확인됨" -ForegroundColor Green
}
Write-Host ""

# Flutter 실행
Write-Host "[2/3] Flutter 앱 실행 중..." -ForegroundColor Yellow
Write-Host "   환경: Staging" -ForegroundColor Gray
Write-Host "   Supabase 프로젝트: aura-mvp-staging" -ForegroundColor Gray
Write-Host ""

# dart-define으로 환경 전달
flutter run --dart-define=ENVIRONMENT=staging

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "스테이징 환경 실행 완료" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

