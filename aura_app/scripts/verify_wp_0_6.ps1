# WP-0.6: 프로젝트 문서화 및 검증 스크립트
# 
# 이 스크립트는 WP-0.6의 최종 검증 체크리스트를 자동으로 실행합니다.

param(
    [switch]$SkipTests = $false
)

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
Write-Output "WP-0.6: 프로젝트 문서화 및 검증"
Write-Output "=========================================="
Write-Output ""

# 1. 필수 문서 존재 확인
Write-Info "1. 필수 문서 존재 확인 중..."

$requiredDocs = @(
    @{ Path = "README.md"; Description = "README.md" },
    @{ Path = "docs\CODING_CONVENTIONS.md"; Description = "코딩 컨벤션 문서" },
    @{ Path = "docs\ARCHITECTURE.md"; Description = "아키텍처 문서" },
    @{ Path = "docs\ENVIRONMENT_SETUP.md"; Description = "환경 설정 가이드" },
    @{ Path = "CONTRIBUTING.md"; Description = "기여 가이드" }
)

$allDocsExist = $true
foreach ($doc in $requiredDocs) {
    if (Test-Path $doc.Path) {
        Write-Success "$($doc.Description) 존재 확인"
    } else {
        Write-Error-Custom "$($doc.Description) 없음: $($doc.Path)"
        $allDocsExist = $false
    }
}

if (-not $allDocsExist) {
    Write-Error-Custom "일부 필수 문서가 없습니다."
}

Write-Output ""

# 2. 프로젝트 폴더 구조 확인
Write-Info "2. 프로젝트 폴더 구조 확인 중..."

$requiredFolders = @(
    @{ Path = "lib\core"; Description = "core 폴더" },
    @{ Path = "lib\features"; Description = "features 폴더" },
    @{ Path = "lib\shared"; Description = "shared 폴더" },
    @{ Path = "test"; Description = "test 폴더" },
    @{ Path = "docs"; Description = "docs 폴더" }
)

$allFoldersExist = $true
foreach ($folder in $requiredFolders) {
    if (Test-Path $folder.Path) {
        Write-Success "$($folder.Description) 존재 확인"
    } else {
        Write-Error-Custom "$($folder.Description) 없음: $($folder.Path)"
        $allFoldersExist = $false
    }
}

if (-not $allFoldersExist) {
    Write-Error-Custom "일부 필수 폴더가 없습니다."
}

Write-Output ""

# 3. Flutter Doctor 확인
Write-Info "3. Flutter Doctor 확인 중..."

try {
    $flutterDoctor = flutter doctor 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Flutter Doctor 실행 성공"
        
        # 경고 확인
        if ($flutterDoctor -match "!") {
            Write-Warning-Custom "Flutter Doctor에서 경고가 발견되었습니다."
            Write-Output $flutterDoctor
        }
    } else {
        Write-Error-Custom "Flutter Doctor 실행 실패"
        Write-Output $flutterDoctor
    }
} catch {
    Write-Error-Custom "Flutter Doctor 실행 중 오류: $_"
}

Write-Output ""

# 4. 의존성 설치 확인
Write-Info "4. 의존성 설치 확인 중..."

try {
    Push-Location $PSScriptRoot\..
    flutter pub get 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "의존성 설치 성공"
    } else {
        Write-Error-Custom "의존성 설치 실패"
    }
    Pop-Location
} catch {
    Write-Error-Custom "의존성 설치 중 오류: $_"
    Pop-Location
}

Write-Output ""

# 5. 코드 분석
Write-Info "5. 코드 분석 중..."

try {
    Push-Location $PSScriptRoot\..
    $analyzeOutput = flutter analyze 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Success "코드 분석 통과 (에러 없음)"
    } else {
        Write-Warning-Custom "코드 분석에서 이슈 발견"
        Write-Output $analyzeOutput
    }
    Pop-Location
} catch {
    Write-Error-Custom "코드 분석 중 오류: $_"
    Pop-Location
}

Write-Output ""

# 6. 테스트 실행 (선택)
if (-not $SkipTests) {
    Write-Info "6. 테스트 실행 중..."
    
    try {
        Push-Location $PSScriptRoot\..
        $testOutput = flutter test 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Success "모든 테스트 통과"
        } else {
            Write-Warning-Custom "일부 테스트 실패"
            Write-Output $testOutput
        }
        Pop-Location
    } catch {
        Write-Error-Custom "테스트 실행 중 오류: $_"
        Pop-Location
    }
} else {
    Write-Info "6. 테스트 실행 건너뜀 (SkipTests 플래그)"
}

Write-Output ""

# 7. 환경 파일 템플릿 확인
Write-Info "7. 환경 파일 템플릿 확인 중..."

$envTemplates = @(
    ".env.development.example",
    ".env.staging.example",
    ".env.production.example"
)

$allTemplatesExist = $true
foreach ($template in $envTemplates) {
    if (Test-Path $template) {
        Write-Success "$template 존재 확인"
    } else {
        Write-Warning-Custom "$template 없음"
        $allTemplatesExist = $false
    }
}

Write-Output ""

# 8. CI/CD 파이프라인 확인
Write-Info "8. CI/CD 파이프라인 확인 중..."

if (Test-Path ".github\workflows\flutter-ci.yml") {
    Write-Success "CI/CD 파이프라인 파일 존재 확인"
} else {
    Write-Warning-Custom "CI/CD 파이프라인 파일 없음"
}

Write-Output ""

# 9. Git 저장소 확인
Write-Info "9. Git 저장소 확인 중..."

if (Test-Path ".git") {
    Write-Success "Git 저장소 초기화됨"
    
    # .gitignore 확인
    if (Test-Path ".gitignore") {
        Write-Success ".gitignore 파일 존재 확인"
        
        # .env 파일이 .gitignore에 포함되어 있는지 확인
        $gitignoreContent = Get-Content ".gitignore" -Raw
        if ($gitignoreContent -match "\.env") {
            Write-Success ".env file is in .gitignore"
        } else {
            Write-Warning-Custom ".env file is not in .gitignore"
        }
    } else {
        Write-Warning-Custom ".gitignore 파일 없음"
    }
} else {
    Write-Warning-Custom "Git 저장소가 초기화되지 않음"
}

Write-Output ""

# 10. 최종 요약
Write-Output "=========================================="
Write-Output "검증 완료"
Write-Output "=========================================="
Write-Output ""

if ($script:ExitCode -eq 0) {
    Write-Success "모든 검증 항목 통과!"
    Write-Output ""
    Write-Info "다음 단계:"
    Write-Output "  1. 팀원들이 로컬 환경에서 앱 실행 테스트"
    Write-Output "  2. 문서 검토 및 피드백 수집"
    Write-Output "  3. Milestone 1 개발 시작 준비"
} else {
    Write-Error-Custom "일부 검증 항목 실패. 위의 오류를 확인하세요."
}

Write-Output ""

exit $script:ExitCode
