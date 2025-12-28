# WP-0.2 시나리오 검증 스크립트
# Supabase 프로젝트 생성 및 연결 검증

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WP-0.2 시나리오 검증 시작" -ForegroundColor Cyan
Write-Host "Supabase 프로젝트 생성 및 연결" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectPath = "C:\modu\aura_app"

# 1. .env.example 파일 확인
Write-Host "[1/6] .env.example 파일 확인..." -ForegroundColor Yellow
if (Test-Path "$projectPath\.env.example") {
    Write-Host "✅ .env.example 파일 존재 확인됨" -ForegroundColor Green
    $envExampleContent = Get-Content "$projectPath\.env.example" -Raw
    if ($envExampleContent -match "SUPABASE_URL" -and $envExampleContent -match "SUPABASE_ANON_KEY") {
        Write-Host "✅ .env.example 파일 내용 확인됨 (SUPABASE_URL, SUPABASE_ANON_KEY 포함)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  경고: .env.example 파일에 SUPABASE_URL 또는 SUPABASE_ANON_KEY가 없습니다." -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ .env.example 파일이 존재하지 않습니다." -ForegroundColor Red
    exit 1
}
Write-Host ""

# 2. .env 파일 확인
Write-Host "[2/6] .env 파일 확인..." -ForegroundColor Yellow
if (Test-Path "$projectPath\.env") {
    Write-Host "✅ .env 파일 존재 확인됨" -ForegroundColor Green
    $envContent = Get-Content "$projectPath\.env" -Raw
    if ($envContent -match "SUPABASE_URL=https://.*\.supabase\.co" -and $envContent -match "SUPABASE_ANON_KEY=.+") {
        Write-Host "✅ .env 파일 내용 확인됨 (올바른 형식)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  경고: .env 파일의 형식이 올바르지 않을 수 있습니다." -ForegroundColor Yellow
        Write-Host "   SUPABASE_URL은 https://your-project.supabase.co 형식이어야 합니다." -ForegroundColor Gray
    }
} else {
    Write-Host "⚠️  .env 파일이 존재하지 않습니다." -ForegroundColor Yellow
    Write-Host "   .env.example을 복사하여 .env 파일을 생성하고 실제 값을 입력하세요." -ForegroundColor Yellow
}
Write-Host ""

# 3. .gitignore 확인
Write-Host "[3/6] .gitignore 확인..." -ForegroundColor Yellow
if (Test-Path "$projectPath\.gitignore") {
    $gitignoreContent = Get-Content "$projectPath\.gitignore" -Raw
    if ($gitignoreContent -match "\.env") {
        Write-Host "✅ .gitignore에 .env 포함 확인됨" -ForegroundColor Green
    } else {
        Write-Host "❌ .gitignore에 .env가 포함되어 있지 않습니다." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "⚠️  .gitignore 파일이 존재하지 않습니다." -ForegroundColor Yellow
}
Write-Host ""

# 4. SupabaseConfig 클래스 확인
Write-Host "[4/6] SupabaseConfig 클래스 확인..." -ForegroundColor Yellow
if (Test-Path "$projectPath\lib\core\supabase_config.dart") {
    Write-Host "✅ SupabaseConfig 클래스 파일 존재 확인됨" -ForegroundColor Green
    $configContent = Get-Content "$projectPath\lib\core\supabase_config.dart" -Raw
    if ($configContent -match "class SupabaseConfig" -and $configContent -match "static Future<void> initialize") {
        Write-Host "✅ SupabaseConfig 클래스 및 initialize() 메서드 확인됨" -ForegroundColor Green
    } else {
        Write-Host "❌ SupabaseConfig 클래스 또는 initialize() 메서드가 없습니다." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ SupabaseConfig 클래스 파일이 존재하지 않습니다." -ForegroundColor Red
    exit 1
}
Write-Host ""

# 5. main.dart에서 초기화 호출 확인
Write-Host "[5/6] main.dart에서 Supabase 초기화 호출 확인..." -ForegroundColor Yellow
if (Test-Path "$projectPath\lib\main.dart") {
    $mainContent = Get-Content "$projectPath\lib\main.dart" -Raw
    if ($mainContent -match "SupabaseConfig\.initialize") {
        Write-Host "✅ main.dart에서 SupabaseConfig.initialize() 호출 확인됨" -ForegroundColor Green
    } else {
        Write-Host "❌ main.dart에서 SupabaseConfig.initialize() 호출이 없습니다." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "❌ main.dart 파일이 존재하지 않습니다." -ForegroundColor Red
    exit 1
}
Write-Host ""

# 6. Flutter 앱 실행 및 연결 테스트 (선택적)
Write-Host "[6/6] Flutter 앱 실행 및 연결 테스트..." -ForegroundColor Yellow
Write-Host "   이 단계는 실제 Supabase 프로젝트가 생성되어 있어야 합니다." -ForegroundColor Gray
Write-Host "   수동으로 다음 명령어를 실행하여 테스트하세요:" -ForegroundColor Gray
Write-Host "   cd $projectPath" -ForegroundColor Gray
Write-Host "   flutter run -d chrome" -ForegroundColor Gray
Write-Host ""

# 최종 결과
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ WP-0.2 코드 레벨 검증 완료" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "1. Supabase 프로젝트 생성 (대시보드에서 수동)" -ForegroundColor Gray
Write-Host "2. .env 파일에 실제 Supabase URL 및 Anon Key 입력" -ForegroundColor Gray
Write-Host "3. flutter run -d chrome 실행하여 실제 연결 테스트" -ForegroundColor Gray
Write-Host ""

exit 0

