# Scenario 0.1-2 검증 스크립트
# 잘못된 프로젝트명으로 Flutter 프로젝트 생성 시도 시 실패를 검증

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Scenario 0.1-2 검증 시작" -ForegroundColor Cyan
Write-Host "잘못된 프로젝트명으로 생성 시도 시 실패" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Flutter SDK 설치 확인
Write-Host "[1/4] Flutter SDK 설치 확인..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Flutter SDK가 설치되어 있지 않습니다." -ForegroundColor Red
        Write-Host "   Scenario 0.1-2 검증을 위해 Flutter SDK가 필요합니다." -ForegroundColor Yellow
        Write-Host "   유닛 테스트는 Flutter SDK 없이도 실행 가능합니다." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ Flutter SDK 설치 확인됨" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Flutter SDK를 찾을 수 없습니다." -ForegroundColor Red
    exit 1
}

# 테스트용 임시 디렉토리 생성
$testDir = "test_scenario_0_1_2"
$invalidProjectName = "123InvalidName"

# 기존 테스트 디렉토리가 있으면 삭제
if (Test-Path $invalidProjectName) {
    Write-Host "[2/4] 기존 테스트 디렉토리 정리..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $invalidProjectName
    Write-Host "✅ 정리 완료" -ForegroundColor Green
    Write-Host ""
}

# 잘못된 프로젝트명으로 프로젝트 생성 시도
Write-Host "[3/4] 잘못된 프로젝트명으로 프로젝트 생성 시도..." -ForegroundColor Yellow
Write-Host "   프로젝트명: $invalidProjectName" -ForegroundColor Gray
Write-Host ""

$output = flutter create $invalidProjectName 2>&1
$exitCode = $LASTEXITCODE

Write-Host "   명령어 출력:" -ForegroundColor Gray
Write-Host $output -ForegroundColor Gray
Write-Host ""

# 검증: 프로젝트 생성 실패 확인
Write-Host "[4/4] 검증 결과 확인..." -ForegroundColor Yellow
Write-Host ""

$allTestsPassed = $true

# 검증 1: 프로젝트 생성 실패 (exit code != 0)
if ($exitCode -eq 0) {
    Write-Host "❌ 검증 실패: 프로젝트 생성이 성공했지만 실패해야 합니다." -ForegroundColor Red
    $allTestsPassed = $false
} else {
    Write-Host "✅ 검증 통과: 프로젝트 생성 실패 (exit code: $exitCode)" -ForegroundColor Green
}

# 검증 2: 에러 메시지 확인
$outputLower = $output.ToLower()
if ($outputLower -match "invalid|error|cannot") {
    Write-Host "✅ 검증 통과: 에러 메시지 확인" -ForegroundColor Green
} else {
    Write-Host "⚠️  경고: 예상한 에러 메시지를 찾을 수 없습니다." -ForegroundColor Yellow
    Write-Host "   실제 출력: $output" -ForegroundColor Gray
}

# 검증 3: 프로젝트 폴더가 생성되지 않았는지 확인
if (Test-Path $invalidProjectName) {
    Write-Host "❌ 검증 실패: 프로젝트 폴더 '$invalidProjectName'가 생성되었습니다." -ForegroundColor Red
    Write-Host "   폴더가 생성되지 않아야 합니다." -ForegroundColor Yellow
    $allTestsPassed = $false
    
    # 정리
    Remove-Item -Recurse -Force $invalidProjectName
} else {
    Write-Host "✅ 검증 통과: 프로젝트 폴더가 생성되지 않음" -ForegroundColor Green
}

Write-Host ""

# 최종 결과
Write-Host "========================================" -ForegroundColor Cyan
if ($allTestsPassed) {
    Write-Host "✅ Scenario 0.1-2 검증 완료: 모든 검증 통과" -ForegroundColor Green
} else {
    Write-Host "❌ Scenario 0.1-2 검증 실패: 일부 검증 실패" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

exit ($allTestsPassed ? 0 : 1)

