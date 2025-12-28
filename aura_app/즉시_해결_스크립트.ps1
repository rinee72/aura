# Flutter Git PATH 문제 즉시 해결 스크립트
# 이 스크립트를 실행하면 현재 PowerShell 세션에서 Git을 찾을 수 있게 됩니다.

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Flutter Git PATH 문제 해결" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Git 경로 확인
$gitPath = "C:\Program Files\Git\cmd"
if (Test-Path "$gitPath\git.exe") {
    Write-Host "✅ Git 경로 확인: $gitPath" -ForegroundColor Green
} else {
    Write-Host "❌ Git을 찾을 수 없습니다: $gitPath" -ForegroundColor Red
    Write-Host "   Git을 설치하거나 경로를 확인하세요." -ForegroundColor Yellow
    exit 1
}

# 환경 변수 설정
Write-Host "[1/3] 환경 변수 설정 중..." -ForegroundColor Yellow
$env:PATH = "$env:PATH;$gitPath"
$env:GIT_EXEC_PATH = $gitPath
Write-Host "✅ 환경 변수 설정 완료" -ForegroundColor Green
Write-Host ""

# Git 확인
Write-Host "[2/3] Git 동작 확인 중..." -ForegroundColor Yellow
try {
    $gitVersion = & "$gitPath\git.exe" --version 2>&1
    Write-Host "✅ Git 확인: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git 실행 실패: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Flutter 프로젝트로 이동
Write-Host "[3/3] Flutter 패키지 설치 중..." -ForegroundColor Yellow
$projectPath = "c:\modu\aura_app"
if (Test-Path $projectPath) {
    Set-Location $projectPath
    Write-Host "✅ 프로젝트 경로: $projectPath" -ForegroundColor Green
} else {
    Write-Host "❌ 프로젝트 경로를 찾을 수 없습니다: $projectPath" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Flutter pub get 실행
try {
    C:\flutter\bin\flutter.bat pub get
    Write-Host ""
    Write-Host "✅ 패키지 설치 완료!" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "❌ 패키지 설치 실패: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "다음 단계를 시도하세요:" -ForegroundColor Yellow
    Write-Host "1. Cursor 완전 재시작" -ForegroundColor Gray
    Write-Host "2. Windows 환경 변수에 GIT_EXEC_PATH 추가" -ForegroundColor Gray
    Write-Host "3. 컴퓨터 재시작" -ForegroundColor Gray
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "해결 완료!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 명령으로 앱을 실행할 수 있습니다:" -ForegroundColor Yellow
Write-Host "  C:\flutter\bin\flutter.bat run -d chrome --dart-define=ENVIRONMENT=development" -ForegroundColor Gray
Write-Host ""
