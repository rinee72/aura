# 시스템 환경 변수에 Git 경로 추가 스크립트
# 관리자 권한으로 실행해야 합니다.

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "시스템 환경 변수 설정" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 관리자 권한 확인
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠️  이 스크립트는 관리자 권한이 필요합니다." -ForegroundColor Yellow
    Write-Host "   PowerShell을 관리자 권한으로 실행한 후 다시 시도하세요." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   방법:" -ForegroundColor Gray
    Write-Host "   1. Windows 검색에서 'PowerShell' 검색" -ForegroundColor Gray
    Write-Host "   2. 'Windows PowerShell' 우클릭 → '관리자 권한으로 실행'" -ForegroundColor Gray
    Write-Host "   3. 이 스크립트 다시 실행" -ForegroundColor Gray
    exit 1
}

$gitPath = "C:\Program Files\Git\cmd"

# Git 경로 확인
if (-not (Test-Path "$gitPath\git.exe")) {
    Write-Host "❌ Git을 찾을 수 없습니다: $gitPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Git 경로 확인: $gitPath" -ForegroundColor Green
Write-Host ""

# 시스템 PATH에 Git 경로 추가
Write-Host "[1/2] 시스템 PATH에 Git 경로 추가 중..." -ForegroundColor Yellow
$systemPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")

if ($systemPath -notlike "*$gitPath*") {
    $newSystemPath = "$systemPath;$gitPath"
    [System.Environment]::SetEnvironmentVariable("Path", $newSystemPath, "Machine")
    Write-Host "✅ 시스템 PATH에 Git 경로 추가 완료" -ForegroundColor Green
} else {
    Write-Host "ℹ️  시스템 PATH에 이미 Git 경로가 포함되어 있습니다." -ForegroundColor Cyan
}
Write-Host ""

# 시스템 환경 변수에 GIT_EXEC_PATH 추가
Write-Host "[2/2] 시스템 환경 변수에 GIT_EXEC_PATH 추가 중..." -ForegroundColor Yellow
[System.Environment]::SetEnvironmentVariable("GIT_EXEC_PATH", $gitPath, "Machine")
Write-Host "✅ GIT_EXEC_PATH 설정 완료" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "설정 완료!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  중요: 환경 변수 변경사항을 적용하려면:" -ForegroundColor Yellow
Write-Host "   1. 모든 프로그램 종료" -ForegroundColor Gray
Write-Host "   2. 컴퓨터 재시작 또는 로그아웃/로그인" -ForegroundColor Gray
Write-Host "   3. Cursor 다시 실행" -ForegroundColor Gray
Write-Host ""
Write-Host "또는 새 PowerShell 창에서:" -ForegroundColor Yellow
Write-Host "   cd c:\modu\aura_app" -ForegroundColor Gray
Write-Host "   C:\flutter\bin\flutter.bat pub get" -ForegroundColor Gray
Write-Host ""













