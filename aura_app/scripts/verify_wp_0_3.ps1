# WP-0.3 검증 스크립트
# Git 저장소 및 협업 환경 구축 검증

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WP-0.3 검증 시작" -ForegroundColor Cyan
Write-Host "Git 저장소 및 협업 환경 구축" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectPath = "C:\modu\aura_app"
$allPassed = $true

# 1. GitHub Actions CI 파이프라인 확인
Write-Host "[1/6] GitHub Actions CI 파이프라인 확인..." -ForegroundColor Yellow
$ciPath = "$projectPath\.github\workflows\flutter-ci.yml"
if (Test-Path $ciPath) {
    Write-Host "✅ CI 파이프라인 파일 존재 확인됨" -ForegroundColor Green
    $ciContent = Get-Content $ciPath -Raw
    if ($ciContent -match "name: Flutter CI" -and $ciContent -match "flutter-version: '3.19.0'") {
        Write-Host "✅ CI 파이프라인 내용 확인됨" -ForegroundColor Green
    } else {
        Write-Host "⚠️  경고: CI 파이프라인 내용이 올바르지 않을 수 있습니다." -ForegroundColor Yellow
        $allPassed = $false
    }
} else {
    Write-Host "❌ CI 파이프라인 파일이 존재하지 않습니다." -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# 2. Pull Request 템플릿 확인
Write-Host "[2/6] Pull Request 템플릿 확인..." -ForegroundColor Yellow
$prTemplatePath = "$projectPath\.github\pull_request_template.md"
if (Test-Path $prTemplatePath) {
    Write-Host "✅ PR 템플릿 파일 존재 확인됨" -ForegroundColor Green
    $prContent = Get-Content $prTemplatePath -Raw
    if ($prContent -match "변경 사항" -and $prContent -match "테스트 완료") {
        Write-Host "✅ PR 템플릿 내용 확인됨" -ForegroundColor Green
    } else {
        Write-Host "⚠️  경고: PR 템플릿 내용이 올바르지 않을 수 있습니다." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ PR 템플릿 파일이 존재하지 않습니다." -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# 3. 이슈 템플릿 확인
Write-Host "[3/6] 이슈 템플릿 확인..." -ForegroundColor Yellow
$bugTemplatePath = "$projectPath\.github\ISSUE_TEMPLATE\bug_report.md"
$featureTemplatePath = "$projectPath\.github\ISSUE_TEMPLATE\feature_request.md"
if (Test-Path $bugTemplatePath) {
    Write-Host "✅ 버그 리포트 템플릿 존재 확인됨" -ForegroundColor Green
} else {
    Write-Host "❌ 버그 리포트 템플릿이 존재하지 않습니다." -ForegroundColor Red
    $allPassed = $false
}
if (Test-Path $featureTemplatePath) {
    Write-Host "✅ 기능 요청 템플릿 존재 확인됨" -ForegroundColor Green
} else {
    Write-Host "❌ 기능 요청 템플릿이 존재하지 않습니다." -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# 4. CONTRIBUTING.md 확인
Write-Host "[4/6] CONTRIBUTING.md 확인..." -ForegroundColor Yellow
$contributingPath = "$projectPath\CONTRIBUTING.md"
if (Test-Path $contributingPath) {
    Write-Host "✅ CONTRIBUTING.md 파일 존재 확인됨" -ForegroundColor Green
    $contributingContent = Get-Content $contributingPath -Raw
    if ($contributingContent -match "브랜치 전략" -and $contributingContent -match "커밋 메시지 규칙") {
        Write-Host "✅ CONTRIBUTING.md 내용 확인됨" -ForegroundColor Green
    } else {
        Write-Host "⚠️  경고: CONTRIBUTING.md 내용이 올바르지 않을 수 있습니다." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ CONTRIBUTING.md 파일이 존재하지 않습니다." -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# 5. .gitignore 확인
Write-Host "[5/6] .gitignore 확인..." -ForegroundColor Yellow
$gitignorePath = "$projectPath\.gitignore"
if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    if ($gitignoreContent -match "\.env") {
        Write-Host "✅ .gitignore에 .env 포함 확인됨" -ForegroundColor Green
    } else {
        Write-Host "❌ .gitignore에 .env가 포함되어 있지 않습니다." -ForegroundColor Red
        $allPassed = $false
    }
} else {
    Write-Host "⚠️  .gitignore 파일이 존재하지 않습니다." -ForegroundColor Yellow
}
Write-Host ""

# 6. Git 저장소 초기화 확인
Write-Host "[6/6] Git 저장소 초기화 확인..." -ForegroundColor Yellow
if (Test-Path "$projectPath\.git") {
    Write-Host "✅ Git 저장소가 초기화되어 있습니다." -ForegroundColor Green
} else {
    Write-Host "⚠️  Git 저장소가 초기화되지 않았습니다." -ForegroundColor Yellow
    Write-Host "   다음 명령어를 실행하여 Git 저장소를 초기화하세요:" -ForegroundColor Gray
    Write-Host "   git init" -ForegroundColor Gray
    Write-Host "   git add ." -ForegroundColor Gray
    Write-Host "   git commit -m `"Initial project setup`"" -ForegroundColor Gray
}
Write-Host ""

# 최종 결과
Write-Host "========================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "✅ WP-0.3 코드 레벨 검증 완료" -ForegroundColor Green
} else {
    Write-Host "⚠️  WP-0.3 검증 중 일부 문제 발견" -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "1. Git 저장소 초기화 (아직 안 했다면)" -ForegroundColor Gray
Write-Host "2. GitHub/GitLab 저장소 생성 및 연결" -ForegroundColor Gray
Write-Host "3. develop 브랜치 생성" -ForegroundColor Gray
Write-Host "4. 첫 커밋에서 CI 파이프라인 테스트" -ForegroundColor Gray
Write-Host ""

exit 0

