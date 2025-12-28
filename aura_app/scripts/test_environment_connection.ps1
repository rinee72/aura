# WP-0.4: 환경별 연결 테스트 스크립트
# 각 환경(development, staging, production)에서 Supabase 연결을 테스트합니다.

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WP-0.4: 환경별 연결 테스트" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectPath = "C:\modu\aura_app"
Set-Location $projectPath

# 테스트할 환경 목록
$environments = @("development", "staging", "production")
$allPassed = $true

foreach ($env in $environments) {
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host "[$env 환경 테스트]" -ForegroundColor Yellow
    Write-Host "----------------------------------------" -ForegroundColor Yellow
    Write-Host ""
    
    # 1. 환경 파일 확인
    $envFile = ".env.$env"
    Write-Host "[1/3] 환경 파일 확인..." -ForegroundColor Cyan
    if (Test-Path $envFile) {
        Write-Host "✅ $envFile 파일 존재 확인" -ForegroundColor Green
        
        # 환경 변수 확인 (실제 값이 입력되었는지)
        $content = Get-Content $envFile -Raw
        if ($env -eq "development") {
            if ($content -match "DEV_SUPABASE_URL=https://.*\.supabase\.co" -and 
                $content -match "DEV_SUPABASE_ANON_KEY=eyJ") {
                Write-Host "✅ Development 환경 변수 형식 확인됨" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Development 환경 변수가 올바르게 설정되지 않았습니다." -ForegroundColor Yellow
                Write-Host "   DEV_SUPABASE_URL과 DEV_SUPABASE_ANON_KEY를 확인하세요." -ForegroundColor Gray
            }
        } elseif ($env -eq "staging") {
            if ($content -match "STAGING_SUPABASE_URL=https://.*\.supabase\.co" -and 
                $content -match "STAGING_SUPABASE_ANON_KEY=eyJ") {
                Write-Host "✅ Staging 환경 변수 형식 확인됨" -ForegroundColor Green
            } elseif ($content -match "DEV_SUPABASE_URL=https://.*\.supabase\.co" -and 
                      $content -match "DEV_SUPABASE_ANON_KEY=eyJ") {
                Write-Host "✅ Staging 환경이 Development 프로젝트를 사용합니다 (2개 프로젝트 구성)" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Staging 환경 변수가 올바르게 설정되지 않았습니다." -ForegroundColor Yellow
            }
        } elseif ($env -eq "production") {
            if ($content -match "PROD_SUPABASE_URL=https://.*\.supabase\.co" -and 
                $content -match "PROD_SUPABASE_ANON_KEY=eyJ") {
                Write-Host "✅ Production 환경 변수 형식 확인됨" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Production 환경 변수가 올바르게 설정되지 않았습니다." -ForegroundColor Yellow
                Write-Host "   PROD_SUPABASE_URL과 PROD_SUPABASE_ANON_KEY를 확인하세요." -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "❌ $envFile 파일이 없습니다." -ForegroundColor Red
        Write-Host "   환경 파일을 생성하고 Supabase 프로젝트 정보를 입력하세요." -ForegroundColor Gray
        $allPassed = $false
    }
    Write-Host ""
    
    # 2. Flutter 코드 분석 (환경별 설정이 올바른지)
    Write-Host "[2/3] 코드 설정 확인..." -ForegroundColor Cyan
    $envDartFile = "lib\core\environment.dart"
    if (Test-Path $envDartFile) {
        $envDartContent = Get-Content $envDartFile -Raw
        if ($envDartContent -match "Environment\.$env" -or $envDartContent -match "case Environment\.$env") {
            Write-Host "✅ $env 환경이 코드에 정의되어 있습니다." -ForegroundColor Green
        } else {
            Write-Host "⚠️  $env 환경이 코드에 정의되지 않았습니다." -ForegroundColor Yellow
        }
    }
    Write-Host ""
    
    # 3. 실제 연결 테스트 (Flutter 앱 실행)
    Write-Host "[3/3] 실제 연결 테스트..." -ForegroundColor Cyan
    Write-Host "   이 테스트는 Flutter 앱을 실행하여 Supabase 연결을 확인합니다." -ForegroundColor Gray
    Write-Host "   수동으로 다음 명령어를 실행하세요:" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   flutter run --dart-define=ENVIRONMENT=$env" -ForegroundColor White
    Write-Host ""
    Write-Host "   또는 다음 스크립트를 사용하세요:" -ForegroundColor Gray
    if ($env -eq "development") {
        Write-Host "   .\scripts\run_dev.ps1" -ForegroundColor White
    } elseif ($env -eq "staging") {
        Write-Host "   .\scripts\run_staging.ps1" -ForegroundColor White
    } elseif ($env -eq "production") {
        Write-Host "   .\scripts\run_prod.ps1" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "   앱 실행 후 콘솔에서 다음 메시지를 확인하세요:" -ForegroundColor Gray
    Write-Host "   ✅ Supabase 연결 테스트 성공" -ForegroundColor Green
    Write-Host "   ✅ 환경 설정 완료: $env" -ForegroundColor Green
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "환경별 연결 테스트 가이드 완료" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($allPassed) {
    Write-Host "✅ 모든 환경 파일이 존재합니다." -ForegroundColor Green
    Write-Host "   이제 각 환경에서 Flutter 앱을 실행하여 연결을 테스트하세요." -ForegroundColor Gray
} else {
    Write-Host "⚠️  일부 환경 파일이 누락되었습니다." -ForegroundColor Yellow
    Write-Host "   누락된 파일을 생성하고 Supabase 프로젝트 정보를 입력하세요." -ForegroundColor Gray
}

Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Cyan
Write-Host "1. 각 환경에서 Flutter 앱 실행" -ForegroundColor White
Write-Host "2. 콘솔에서 '✅ Supabase 연결 테스트 성공' 메시지 확인" -ForegroundColor White
Write-Host "3. 앱 화면에서 환경 배지 확인 (Development: 파란색, Staging: 주황색, Production: 보라색)" -ForegroundColor White
Write-Host ""

