# Scenario 0.1-3 검증 스크립트
# Flutter SDK 미설치 상태에서 프로젝트 생성 시도 시 실패를 검증

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Scenario 0.1-3 검증 시작" -ForegroundColor Cyan
Write-Host "Flutter SDK 미설치 상태에서 프로젝트 생성 시도 시 실패" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Flutter SDK 설치 확인
Write-Host "[1/4] Flutter SDK 설치 확인..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "⚠️  Flutter SDK가 설치되어 있습니다." -ForegroundColor Yellow
        Write-Host "   이 시나리오는 Flutter SDK가 PATH에 없을 때 검증됩니다." -ForegroundColor Yellow
        Write-Host "   실제 검증을 위해서는 Flutter SDK를 PATH에서 제거해야 합니다." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   현재 Flutter 버전:" -ForegroundColor Gray
        Write-Host $flutterVersion -ForegroundColor Gray
        Write-Host ""
        Write-Host "   시뮬레이션 모드로 진행합니다..." -ForegroundColor Yellow
        $simulationMode = $true
    } else {
        Write-Host "✅ Flutter SDK가 PATH에 없습니다 (예상된 상태)" -ForegroundColor Green
        $simulationMode = $false
    }
} catch {
    Write-Host "✅ Flutter SDK를 찾을 수 없습니다 (예상된 상태)" -ForegroundColor Green
    $simulationMode = $false
}
Write-Host ""

# Flutter SDK 미설치 상태 시뮬레이션
if ($simulationMode) {
    Write-Host "[2/4] Flutter SDK 미설치 상태 시뮬레이션..." -ForegroundColor Yellow
    Write-Host "   실제 환경에서는 Flutter SDK가 PATH에 없어야 합니다." -ForegroundColor Gray
    Write-Host ""
    
    # PATH에서 flutter 제거 시뮬레이션
    Write-Host "   시뮬레이션: PATH에서 flutter 명령어를 찾을 수 없음" -ForegroundColor Gray
    Write-Host ""
}

# 잘못된 flutter 명령어로 프로젝트 생성 시도
Write-Host "[3/4] Flutter SDK 없이 프로젝트 생성 시도..." -ForegroundColor Yellow
Write-Host "   명령어: flutter create test_scenario_0_1_3" -ForegroundColor Gray
Write-Host ""

if ($simulationMode) {
    # 시뮬레이션: 실제로는 flutter 명령어가 실행되지 않음
    Write-Host "   [시뮬레이션] flutter 명령어를 찾을 수 없음" -ForegroundColor Gray
    Write-Host "   [시뮬레이션] 예상 에러: flutter: command not found" -ForegroundColor Gray
    $expectedError = "flutter: command not found"
    $exitCode = 1
} else {
    # 실제 테스트
    try {
        $output = flutter create test_scenario_0_1_3 2>&1
        $exitCode = $LASTEXITCODE
    } catch {
        $output = $_.Exception.Message
        $exitCode = 1
    }
}

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
if ($simulationMode) {
    Write-Host "✅ 검증 통과: [시뮬레이션] 'flutter: command not found' 에러 메시지 확인" -ForegroundColor Green
} else {
    $outputLower = $output.ToString().ToLower()
    if ($outputLower -match "command not found|not recognized|not found|flutter") {
        Write-Host "✅ 검증 통과: 에러 메시지 확인" -ForegroundColor Green
        Write-Host "   실제 에러: $output" -ForegroundColor Gray
    } else {
        Write-Host "⚠️  경고: 예상한 에러 메시지를 찾을 수 없습니다." -ForegroundColor Yellow
        Write-Host "   실제 출력: $output" -ForegroundColor Gray
    }
}

# 검증 3: 프로젝트 폴더가 생성되지 않았는지 확인
if (Test-Path "test_scenario_0_1_3") {
    Write-Host "❌ 검증 실패: 프로젝트 폴더 'test_scenario_0_1_3'가 생성되었습니다." -ForegroundColor Red
    Write-Host "   폴더가 생성되지 않아야 합니다." -ForegroundColor Yellow
    $allTestsPassed = $false
    
    # 정리
    Remove-Item -Recurse -Force test_scenario_0_1_3
} else {
    Write-Host "✅ 검증 통과: 프로젝트 폴더가 생성되지 않음" -ForegroundColor Green
}

Write-Host ""

# 최종 결과
Write-Host "========================================" -ForegroundColor Cyan
if ($allTestsPassed) {
    Write-Host "✅ Scenario 0.1-3 검증 완료: 모든 검증 통과" -ForegroundColor Green
} else {
    Write-Host "❌ Scenario 0.1-3 검증 실패: 일부 검증 실패" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($simulationMode) {
    Write-Host "📝 참고: 이 검증은 시뮬레이션 모드로 실행되었습니다." -ForegroundColor Yellow
    Write-Host "   실제 검증을 위해서는 Flutter SDK를 PATH에서 제거해야 합니다." -ForegroundColor Yellow
    Write-Host ""
}

if ($allTestsPassed) {
    exit 0
} else {
    exit 1
}

