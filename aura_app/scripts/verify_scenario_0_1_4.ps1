# Scenario 0.1-4 검증 스크립트
# pubspec.yaml에 필수 패키지 추가 후 정상 설치를 검증

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Scenario 0.1-4 검증 시작" -ForegroundColor Cyan
Write-Host "pubspec.yaml에 필수 패키지 추가 후 정상 설치" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Flutter SDK 설치 확인
Write-Host "[1/5] Flutter SDK 설치 확인..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Flutter SDK가 설치되어 있지 않습니다." -ForegroundColor Red
        Write-Host "   Scenario 0.1-4 검증을 위해 Flutter SDK가 필요합니다." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ Flutter SDK 설치 확인됨" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host "❌ Flutter SDK를 찾을 수 없습니다." -ForegroundColor Red
    exit 1
}

# pubspec.yaml 파일 존재 확인
Write-Host "[2/5] pubspec.yaml 파일 확인..." -ForegroundColor Yellow
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ pubspec.yaml 파일이 없습니다." -ForegroundColor Red
    exit 1
}
Write-Host "✅ pubspec.yaml 파일 존재 확인" -ForegroundColor Green
Write-Host ""

# 필수 패키지 확인
Write-Host "[3/5] 필수 패키지 확인..." -ForegroundColor Yellow
$requiredPackages = @{
    "supabase_flutter" = "^2.3.0"
    "go_router" = "^13.0.0"
    "provider" = "^6.1.1"
    "flutter_dotenv" = "^5.1.0"
}

$pubspecContent = Get-Content "pubspec.yaml" -Raw
$missingPackages = @()
$incorrectVersions = @()

foreach ($package in $requiredPackages.Keys) {
    $requiredVersion = $requiredPackages[$package]
    
    # 패키지 존재 확인
    if ($pubspecContent -notmatch "$package\s*:") {
        $missingPackages += $package
        Write-Host "❌ 패키지 누락: $package" -ForegroundColor Red
    } else {
        # 버전 확인 (간단한 패턴 매칭)
        if ($pubspecContent -match "$package\s*:\s*([^\s]+)") {
            $actualVersion = $matches[1]
            Write-Host "✅ 패키지 확인: $package ($actualVersion)" -ForegroundColor Green
        } else {
            Write-Host "⚠️  패키지 버전 확인 불가: $package" -ForegroundColor Yellow
        }
    }
}

if ($missingPackages.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ 다음 패키지가 pubspec.yaml에 없습니다: $($missingPackages -join ', ')" -ForegroundColor Red
    exit 1
}
Write-Host "✅ 모든 필수 패키지가 pubspec.yaml에 추가되어 있음" -ForegroundColor Green
Write-Host ""

# flutter pub get 실행
Write-Host "[4/5] flutter pub get 실행..." -ForegroundColor Yellow
Write-Host "   명령어: flutter pub get" -ForegroundColor Gray
Write-Host ""

$pubGetResult = flutter pub get 2>&1
$exitCode = $LASTEXITCODE

Write-Host $pubGetResult -ForegroundColor Gray
Write-Host ""

# 검증: 패키지 설치 성공 확인
Write-Host "[5/5] 검증 결과 확인..." -ForegroundColor Yellow
Write-Host ""

$allTestsPassed = $true

# 검증 1: 종료 코드 0 확인
if ($exitCode -ne 0) {
    Write-Host "❌ 검증 실패: flutter pub get이 실패했습니다 (exit code: $exitCode)" -ForegroundColor Red
    $allTestsPassed = $false
} else {
    Write-Host "✅ 검증 통과: flutter pub get 성공 (exit code: $exitCode)" -ForegroundColor Green
}

# 검증 2: "Got dependencies!" 메시지 확인
$outputLower = $pubGetResult.ToString().ToLower()
if ($outputLower -match "got dependencies|running.*flutter pub get|pub get") {
    Write-Host "✅ 검증 통과: 'Got dependencies!' 또는 유사한 메시지 확인" -ForegroundColor Green
} else {
    Write-Host "⚠️  경고: 예상한 메시지를 찾을 수 없습니다." -ForegroundColor Yellow
    Write-Host "   실제 출력: $pubGetResult" -ForegroundColor Gray
}

# 검증 3: package_config.json 파일 존재 확인
if (Test-Path ".dart_tool/package_config.json") {
    Write-Host "✅ 검증 통과: .dart_tool/package_config.json 파일 존재" -ForegroundColor Green
    
    # 필수 패키지가 package_config.json에 있는지 확인
    $packageConfigContent = Get-Content ".dart_tool/package_config.json" -Raw
    $missingInConfig = @()
    
    foreach ($package in $requiredPackages.Keys) {
        if ($packageConfigContent -notmatch "`"$package`"") {
            $missingInConfig += $package
        }
    }
    
    if ($missingInConfig.Count -gt 0) {
        Write-Host "⚠️  경고: 다음 패키지가 package_config.json에 없습니다: $($missingInConfig -join ', ')" -ForegroundColor Yellow
    } else {
        Write-Host "✅ 검증 통과: 모든 필수 패키지가 package_config.json에 존재" -ForegroundColor Green
    }
} else {
    Write-Host "❌ 검증 실패: .dart_tool/package_config.json 파일이 없습니다." -ForegroundColor Red
    Write-Host "   flutter pub get을 실행했는지 확인하세요." -ForegroundColor Yellow
    $allTestsPassed = $false
}

Write-Host ""

# 최종 결과
Write-Host "========================================" -ForegroundColor Cyan
if ($allTestsPassed) {
    Write-Host "✅ Scenario 0.1-4 검증 완료: 모든 검증 통과" -ForegroundColor Green
} else {
    Write-Host "❌ Scenario 0.1-4 검증 실패: 일부 검증 실패" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($allTestsPassed) {
    exit 0
} else {
    exit 1
}

