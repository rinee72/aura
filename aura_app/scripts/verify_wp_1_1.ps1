# WP-1.1: 데이터베이스 스키마 설계 및 생성 - 검증 스크립트
# 
# 이 스크립트는 WP-1.1의 완료 조건을 검증합니다.

$ErrorActionPreference = "Stop"
$script:ExitCode = 0

# 색상 출력 함수
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success($message) {
    Write-ColorOutput Green "✅ $message"
}

function Write-Error-Custom($message) {
    Write-ColorOutput Red "❌ $message"
    $script:ExitCode = 1
}

function Write-Warning-Custom($message) {
    Write-ColorOutput Yellow "⚠️ $message"
}

function Write-Info($message) {
    Write-ColorOutput Cyan "ℹ️ $message"
}

Write-Output ""
Write-Output "=========================================="
Write-Output "WP-1.1: 데이터베이스 스키마 설계 및 생성 검증"
Write-Output "=========================================="
Write-Output ""

# 1. ERD 문서 확인
Write-Info "1. ERD 문서 확인 중..."

if (Test-Path "docs\database\ERD.md") {
    Write-Success "ERD 문서 존재 확인"
} else {
    Write-Error-Custom "ERD 문서 없음: docs\database\ERD.md"
}

Write-Output ""

# 2. 마이그레이션 스크립트 확인
Write-Info "2. 마이그레이션 스크립트 확인 중..."

$migrationFiles = @(
    "supabase\migrations\001_initial_schema.sql",
    "supabase\migrations\002_verify_schema.sql"
)

$allMigrationsExist = $true
foreach ($file in $migrationFiles) {
    if (Test-Path $file) {
        Write-Success "$file 존재 확인"
    } else {
        Write-Error-Custom "$file 없음"
        $allMigrationsExist = $false
    }
}

if (-not $allMigrationsExist) {
    Write-Error-Custom "일부 마이그레이션 파일이 없습니다."
}

Write-Output ""

# 3. 마이그레이션 가이드 확인
Write-Info "3. 마이그레이션 가이드 확인 중..."

if (Test-Path "docs\database\MIGRATION_GUIDE.md") {
    Write-Success "마이그레이션 가이드 존재 확인"
} else {
    Write-Warning-Custom "마이그레이션 가이드 없음: docs\database\MIGRATION_GUIDE.md"
}

Write-Output ""

# 4. SQL 스크립트 내용 검증
Write-Info "4. SQL 스크립트 내용 검증 중..."

if (Test-Path "supabase\migrations\001_initial_schema.sql") {
    $sqlContent = Get-Content "supabase\migrations\001_initial_schema.sql" -Raw
    
    # 필수 테이블 확인
    $requiredTables = @(
        "CREATE TABLE.*users",
        "CREATE TABLE.*questions",
        "CREATE TABLE.*question_likes",
        "CREATE TABLE.*answers",
        "CREATE TABLE.*subscriptions",
        "CREATE TABLE.*communities",
        "CREATE TABLE.*community_comments"
    )
    
    $allTablesFound = $true
    foreach ($table in $requiredTables) {
        if ($sqlContent -match $table) {
            Write-Success "테이블 정의 발견: $table"
        } else {
            Write-Error-Custom "테이블 정의 없음: $table"
            $allTablesFound = $false
        }
    }
    
    # RLS 활성화 확인
    if ($sqlContent -match "ENABLE ROW LEVEL SECURITY") {
        Write-Success "RLS 활성화 코드 발견"
    } else {
        Write-Error-Custom "RLS 활성화 코드 없음"
    }
    
    # 인덱스 생성 확인
    if ($sqlContent -match "CREATE INDEX") {
        Write-Success "인덱스 생성 코드 발견"
    } else {
        Write-Warning-Custom "인덱스 생성 코드 없음"
    }
    
    # 외래키 제약조건 확인
    if ($sqlContent -match "REFERENCES") {
        Write-Success "외래키 제약조건 코드 발견"
    } else {
        Write-Error-Custom "외래키 제약조건 코드 없음"
    }
} else {
    Write-Error-Custom "마이그레이션 스크립트 파일을 찾을 수 없습니다."
}

Write-Output ""

# 5. 폴더 구조 확인
Write-Info "5. 폴더 구조 확인 중..."

$requiredFolders = @(
    "supabase\migrations",
    "docs\database"
)

$allFoldersExist = $true
foreach ($folder in $requiredFolders) {
    if (Test-Path $folder) {
        Write-Success "$folder 폴더 존재 확인"
    } else {
        Write-Warning-Custom "$folder 폴더 없음 (생성 필요)"
        $allFoldersExist = $false
    }
}

Write-Output ""

# 6. 최종 요약
Write-Output "=========================================="
Write-Output "검증 완료"
Write-Output "=========================================="
Write-Output ""

if ($script:ExitCode -eq 0) {
    Write-Success "모든 검증 항목 통과!"
    Write-Output ""
    Write-Info "다음 단계:"
    Write-Output "  1. Supabase Dashboard에서 마이그레이션 스크립트 실행"
    Write-Output "  2. 스키마 검증 스크립트 실행 (002_verify_schema.sql)"
    Write-Output "  3. 샘플 데이터 삽입 테스트"
    Write-Output "  4. 역할별 접근 권한 검증"
    Write-Output "  5. WP-1.2 (Supabase Auth 연동) 진행"
} else {
    Write-Error-Custom "일부 검증 항목 실패. 위의 오류를 확인하세요."
    Write-Output ""
    Write-Info "해결 방법:"
    Write-Output "  1. 누락된 파일 확인 및 생성"
    Write-Output "  2. SQL 스크립트 내용 검토"
    Write-Output "  3. 폴더 구조 확인"
}

Write-Output ""

exit $script:ExitCode
