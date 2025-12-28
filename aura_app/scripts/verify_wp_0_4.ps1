# WP-0.4 검증 스크립트
# 개발/스테이징/프로덕션 환경 분리 검증

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WP-0.4 검증 시작" -ForegroundColor Cyan
Write-Host "개발/스테이징/프로덕션 환경 분리" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectPath = "C:\modu\aura_app"
$allPassed = $true

# 1. 환경 분리 시스템 파일 확인
Write-Host "[1/8] 환경 분리 시스템 파일 확인..." -ForegroundColor Yellow
$envFile = "$projectPath\lib\core\environment.dart"
if (Test-Path $envFile) {
    Write-Host "✅ environment.dart 파일 존재 확인됨" -ForegroundColor Green
    $envContent = Get-Content $envFile -Raw
    if ($envContent -match "enum Environment" -and $envContent -match "class AppEnvironment") {
        Write-Host "✅ Environment enum 및 AppEnvironment 클래스 확인됨" -ForegroundColor Green
    } else {
        Write-Host "❌ environment.dart 파일 내용이 올바르지 않습니다." -ForegroundColor Red
        $allPassed = $false
    }
} else {
    Write-Host "❌ environment.dart 파일이 존재하지 않습니다." -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# 2. 환경별 설정 파일 템플릿 확인
Write-Host "[2/8] 환경별 설정 파일 템플릿 확인..." -ForegroundColor Yellow
$envTemplates = @(
    ".env.development.example",
    ".env.staging.example",
    ".env.production.example"
)

foreach ($template in $envTemplates) {
    $templatePath = "$projectPath\$template"
    if (Test-Path $templatePath) {
        Write-Host "✅ $template 파일 존재 확인됨" -ForegroundColor Green
        $templateContent = Get-Content $templatePath -Raw
        if ($template -match "development" -and $templateContent -match "DEV_SUPABASE_URL") {
            Write-Host "   개발 환경 변수 확인됨" -ForegroundColor Gray
        } elseif ($template -match "staging" -and $templateContent -match "STAGING_SUPABASE_URL") {
            Write-Host "   스테이징 환경 변수 확인됨" -ForegroundColor Gray
        } elseif ($template -match "production" -and $templateContent -match "PROD_SUPABASE_URL") {
            Write-Host "   프로덕션 환경 변수 확인됨" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠️  $template 파일이 존재하지 않습니다." -ForegroundColor Yellow
        Write-Host "   이 파일은 템플릿이므로 생성해야 합니다." -ForegroundColor Gray
    }
}
Write-Host ""

# 3. SupabaseConfig 환경별 지원 확인
Write-Host "[3/8] SupabaseConfig 환경별 지원 확인..." -ForegroundColor Yellow
$supabaseConfigFile = "$projectPath\lib\core\supabase_config.dart"
if (Test-Path $supabaseConfigFile) {
    $supabaseContent = Get-Content $supabaseConfigFile -Raw
    if ($supabaseContent -match "AppEnvironment" -and $supabaseContent -match "supabaseUrl") {
        Write-Host "✅ SupabaseConfig가 AppEnvironment를 사용함" -ForegroundColor Green
    } else {
        Write-Host "❌ SupabaseConfig가 환경별 설정을 사용하지 않습니다." -ForegroundColor Red
        $allPassed = $false
    }
} else {
    Write-Host "❌ supabase_config.dart 파일이 존재하지 않습니다." -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# 4. main.dart 환경 설정 통합 확인
Write-Host "[4/8] main.dart 환경 설정 통합 확인..." -ForegroundColor Yellow
$mainFile = "$projectPath\lib\main.dart"
if (Test-Path $mainFile) {
    $mainContent = Get-Content $mainFile -Raw
    if ($mainContent -match "AppEnvironment" -and $mainContent -match "initializeFromDartDefine") {
        Write-Host "✅ main.dart에서 환경 초기화 확인됨" -ForegroundColor Green
    } else {
        Write-Host "❌ main.dart에서 환경 초기화가 누락되었습니다." -ForegroundColor Red
        $allPassed = $false
    }
    
    if ($mainContent -match "appTitle" -or $mainContent -match "badgeColor") {
        Write-Host "✅ 환경별 UI 표시 확인됨" -ForegroundColor Green
    } else {
        Write-Host "⚠️  환경별 UI 표시가 누락되었을 수 있습니다." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ main.dart 파일이 존재하지 않습니다." -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# 5. 실행 스크립트 확인
Write-Host "[5/8] 실행 스크립트 확인..." -ForegroundColor Yellow
$scripts = @(
    "scripts\run_dev.ps1",
    "scripts\run_staging.ps1",
    "scripts\run_prod.ps1"
)

foreach ($script in $scripts) {
    $scriptPath = "$projectPath\$script"
    if (Test-Path $scriptPath) {
        Write-Host "✅ $script 파일 존재 확인됨" -ForegroundColor Green
        $scriptContent = Get-Content $scriptPath -Raw
        if ($scriptContent -match "dart-define=ENVIRONMENT") {
            Write-Host "   dart-define 설정 확인됨" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ $script 파일이 존재하지 않습니다." -ForegroundColor Red
        $allPassed = $false
    }
}
Write-Host ""

# 6. pubspec.yaml 환경 파일 등록 확인
Write-Host "[6/8] pubspec.yaml 환경 파일 등록 확인..." -ForegroundColor Yellow
$pubspecFile = "$projectPath\pubspec.yaml"
if (Test-Path $pubspecFile) {
    $pubspecContent = Get-Content $pubspecFile -Raw
    if ($pubspecContent -match "\.env\.development\.example" -and 
        $pubspecContent -match "\.env\.staging\.example" -and 
        $pubspecContent -match "\.env\.production\.example") {
        Write-Host "✅ 환경별 .env.example 파일이 assets에 등록됨" -ForegroundColor Green
    } else {
        Write-Host "⚠️  환경별 .env.example 파일이 assets에 등록되지 않았습니다." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ pubspec.yaml 파일이 존재하지 않습니다." -ForegroundColor Red
    $allPassed = $false
}
Write-Host ""

# 7. 문서 확인
Write-Host "[7/8] 문서 확인..." -ForegroundColor Yellow
$docs = @(
    "docs\ENVIRONMENT_SETUP.md",
    "WP_0_4_구현_완료_리포트.md"
)

foreach ($doc in $docs) {
    $docPath = "$projectPath\$doc"
    if (Test-Path $docPath) {
        Write-Host "✅ $doc 파일 존재 확인됨" -ForegroundColor Green
    } else {
        Write-Host "⚠️  $doc 파일이 존재하지 않습니다." -ForegroundColor Yellow
    }
}
Write-Host ""

# 8. 코드 분석 (린터 오류 확인)
Write-Host "[8/8] 코드 분석..." -ForegroundColor Yellow
Set-Location $projectPath
try {
    $analyzeOutput = flutter analyze --no-fatal-infos 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Flutter analyze 통과" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Flutter analyze에서 경고가 발견되었습니다." -ForegroundColor Yellow
        Write-Host "   출력: $analyzeOutput" -ForegroundColor Gray
    }
} catch {
    Write-Host "⚠️  Flutter analyze 실행 실패 (Flutter SDK 경로 확인 필요)" -ForegroundColor Yellow
}
Write-Host ""

# 최종 결과
Write-Host "========================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "✅ WP-0.4 검증 완료" -ForegroundColor Green
    Write-Host "   모든 필수 파일이 올바르게 구현되었습니다." -ForegroundColor Green
} else {
    Write-Host "⚠️  WP-0.4 검증 완료 (일부 문제 발견)" -ForegroundColor Yellow
    Write-Host "   위의 오류를 확인하고 수정하세요." -ForegroundColor Yellow
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 사용자 작업 필요 항목 안내
Write-Host "📋 사용자가 수행해야 할 작업:" -ForegroundColor Cyan
Write-Host "   1. Supabase 프로젝트 생성 (3개: dev, staging, prod)" -ForegroundColor Gray
Write-Host "   2. 환경별 설정 파일 생성:" -ForegroundColor Gray
Write-Host "      - .env.development.example을 복사하여 .env.development 생성" -ForegroundColor Gray
Write-Host "      - .env.staging.example을 복사하여 .env.staging 생성" -ForegroundColor Gray
Write-Host "      - .env.production.example을 복사하여 .env.production 생성" -ForegroundColor Gray
Write-Host "   3. 환경별 Supabase URL/Key 입력" -ForegroundColor Gray
Write-Host "   4. 환경별 연결 테스트:" -ForegroundColor Gray
Write-Host "      - .\scripts\run_dev.ps1" -ForegroundColor Gray
Write-Host "      - .\scripts\run_staging.ps1" -ForegroundColor Gray
Write-Host "      - .\scripts\run_prod.ps1" -ForegroundColor Gray
Write-Host ""

