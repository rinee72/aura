@echo off
REM AURA App Launcher
REM Fixes WHERE command and Git PATH issues

echo ========================================
echo AURA App Launcher
echo ========================================
echo.

REM Add system paths FIRST (required for WHERE command)
set "PATH=C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;%PATH%"

REM Add Git to PATH
set "PATH=C:\Program Files\Git\cmd;C:\Program Files\Git\bin;%PATH%"
set "GIT_EXEC_PATH=C:\Program Files\Git\cmd"

REM Change to script directory
cd /d "%~dp0"
echo Current directory: %CD%
echo.

REM Verify WHERE command works
where where >nul 2>&1
if errorlevel 1 (
    echo ERROR: WHERE command not found
    echo This should not happen. Please check Windows installation.
    pause
    exit /b 1
)

REM Verify Git is accessible
echo [1/4] Checking Git...
where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git not found in PATH
    echo Trying direct path...
    if exist "C:\Program Files\Git\cmd\git.exe" (
        echo OK: Git found at direct path
    ) else (
        echo ERROR: Git not found
        pause
        exit /b 1
    )
) else (
    echo OK: Git found in PATH
)
echo.

REM Check Flutter
echo [2/4] Checking Flutter...
if exist "C:\flutter\bin\flutter.bat" (
    echo OK: Flutter found
) else (
    echo ERROR: Flutter not found at C:\flutter\bin\flutter.bat
    pause
    exit /b 1
)
echo.

REM Install dependencies
echo [3/4] Installing dependencies...
call C:\flutter\bin\flutter.bat pub get
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)
echo OK: Dependencies installed
echo.

REM Run app
echo [4/4] Starting Flutter app...
echo.
call C:\flutter\bin\flutter.bat run -d windows --dart-define=ENVIRONMENT=development

echo.
echo ========================================
echo Process completed
echo ========================================
pause
