# Git 저장소 초기화 스크립트
# WP-0.3: Git 저장소 및 협업 환경 구축

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Git 저장소 초기화 스크립트" -ForegroundColor Cyan
Write-Host "WP-0.3: Git 저장소 및 협업 환경 구축" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectPath = "C:\modu\aura_app"

# 현재 디렉토리 확인
if (-not (Test-Path $projectPath)) {
    Write-Host "❌ 프로젝트 경로를 찾을 수 없습니다: $projectPath" -ForegroundColor Red
    exit 1
}

Set-Location $projectPath

# 1. Git 저장소 초기화 확인
Write-Host "[1/5] Git 저장소 초기화 확인..." -ForegroundColor Yellow
if (Test-Path ".git") {
    Write-Host "✅ Git 저장소가 이미 초기화되어 있습니다." -ForegroundColor Green
} else {
    Write-Host "⚠️  Git 저장소가 초기화되지 않았습니다." -ForegroundColor Yellow
    Write-Host "   다음 명령어를 실행하여 Git 저장소를 초기화하세요:" -ForegroundColor Gray
    Write-Host "   git init" -ForegroundColor Gray
    Write-Host "   git add ." -ForegroundColor Gray
    Write-Host "   git commit -m `"Initial project setup`"" -ForegroundColor Gray
}
Write-Host ""

# 2. .gitignore 확인
Write-Host "[2/5] .gitignore 확인..." -ForegroundColor Yellow
if (Test-Path ".gitignore") {
    Write-Host "✅ .gitignore 파일이 존재합니다." -ForegroundColor Green
    $gitignoreContent = Get-Content ".gitignore" -Raw
    if ($gitignoreContent -match "\.env") {
        Write-Host "✅ .gitignore에 .env 파일이 포함되어 있습니다." -ForegroundColor Green
    } else {
        Write-Host "⚠️  .gitignore에 .env 파일이 포함되어 있지 않습니다." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ .gitignore 파일이 존재하지 않습니다." -ForegroundColor Red
}
Write-Host ""

# 3. GitHub Actions CI 파이프라인 확인
Write-Host "[3/5] GitHub Actions CI 파이프라인 확인..." -ForegroundColor Yellow
$ciPath = ".github\workflows\flutter-ci.yml"
if (Test-Path $ciPath) {
    Write-Host "✅ GitHub Actions CI 파이프라인이 설정되어 있습니다." -ForegroundColor Green
    Write-Host "   경로: $ciPath" -ForegroundColor Gray
} else {
    Write-Host "❌ GitHub Actions CI 파이프라인이 설정되지 않았습니다." -ForegroundColor Red
    Write-Host "   경로: $ciPath" -ForegroundColor Gray
}
Write-Host ""

# 4. Pull Request 템플릿 확인
Write-Host "[4/5] Pull Request 템플릿 확인..." -ForegroundColor Yellow
$prTemplatePath = ".github\pull_request_template.md"
if (Test-Path $prTemplatePath) {
    Write-Host "✅ Pull Request 템플릿이 설정되어 있습니다." -ForegroundColor Green
    Write-Host "   경로: $prTemplatePath" -ForegroundColor Gray
} else {
    Write-Host "❌ Pull Request 템플릿이 설정되지 않았습니다." -ForegroundColor Red
    Write-Host "   경로: $prTemplatePath" -ForegroundColor Gray
}
Write-Host ""

# 5. CONTRIBUTING.md 확인
Write-Host "[5/5] CONTRIBUTING.md 확인..." -ForegroundColor Yellow
if (Test-Path "CONTRIBUTING.md") {
    Write-Host "✅ CONTRIBUTING.md 파일이 존재합니다." -ForegroundColor Green
} else {
    Write-Host "❌ CONTRIBUTING.md 파일이 존재하지 않습니다." -ForegroundColor Red
}
Write-Host ""

# 최종 결과
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Git 저장소 초기화 확인 완료" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "1. Git 저장소 초기화 (아직 안 했다면):" -ForegroundColor Gray
Write-Host "   git init" -ForegroundColor Gray
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m `"Initial project setup`"" -ForegroundColor Gray
Write-Host ""
Write-Host "2. GitHub/GitLab 저장소 생성:" -ForegroundColor Gray
Write-Host "   - Private repository 생성: aura-mvp" -ForegroundColor Gray
Write-Host "   - Remote 연결:" -ForegroundColor Gray
Write-Host "     git remote add origin <repository-url>" -ForegroundColor Gray
Write-Host "     git push -u origin main" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 브랜치 전략:" -ForegroundColor Gray
Write-Host "   - main: 프로덕션 브랜치" -ForegroundColor Gray
Write-Host "   - develop: 개발 통합 브랜치" -ForegroundColor Gray
Write-Host "   - feature/*: 기능 개발 브랜치" -ForegroundColor Gray
Write-Host "   - hotfix/*: 긴급 수정 브랜치" -ForegroundColor Gray
Write-Host ""

exit 0

