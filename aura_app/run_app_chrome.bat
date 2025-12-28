@echo off
REM AURA App Launcher (Chrome)
REM Fixes Git PATH issue and runs Flutter app in Chrome

REM Add Git to PATH at the beginning (highest priority)
set "PATH=C:\Program Files\Git\cmd;C:\Program Files\Git\bin;%PATH%"
set "GIT_EXEC_PATH=C:\Program Files\Git\cmd"

REM Change to script directory
cd /d "%~dp0"

REM Verify Git is accessible
"C:\Program Files\Git\cmd\git.exe" --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git not found at C:\Program Files\Git\cmd\git.exe
    echo Please verify Git installation.
    pause
    exit /b 1
)

echo Starting Flutter app (Chrome)...
echo Browser will open automatically after compilation.
echo.

REM Run Flutter app
C:\flutter\bin\flutter.bat run -d chrome --dart-define=ENVIRONMENT=development

pause

