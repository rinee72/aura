@echo off
REM AURA App Launcher - Simple Version

echo ========================================
echo AURA App Launcher
echo ========================================
echo.

REM Add Git to PATH
set "PATH=C:\Program Files\Git\cmd;C:\Program Files\Git\bin;%PATH%"

REM Change to script directory
cd /d "%~dp0"
echo Current directory: %CD%
echo.

REM Check Git
echo [1/4] Checking Git...
"C:\Program Files\Git\cmd\git.exe" --version
if errorlevel 1 (
    echo ERROR: Git not found
    goto :error
)
echo OK: Git found
echo.

REM Check Flutter
echo [2/4] Checking Flutter...
C:\flutter\bin\flutter.bat --version
if errorlevel 1 (
    echo ERROR: Flutter not found
    goto :error
)
echo OK: Flutter found
echo.

REM Install dependencies
echo [3/4] Installing dependencies...
C:\flutter\bin\flutter.bat pub get
if errorlevel 1 (
    echo ERROR: Failed to install dependencies
    goto :error
)
echo OK: Dependencies installed
echo.

REM Run app
echo [4/4] Starting Flutter app...
echo.
C:\flutter\bin\flutter.bat run -d windows --dart-define=ENVIRONMENT=development

echo.
echo ========================================
echo Process completed
echo ========================================
goto :end

:error
echo.
echo ========================================
echo ERROR OCCURRED
echo ========================================
echo Please check the error messages above.
echo.

:end
echo Press any key to exit...
pause >nul


