@echo off
echo Starting...
cd /d "%~dp0"
set "PATH=C:\Program Files\Git\cmd;C:\Program Files\Git\bin;%PATH%"
C:\flutter\bin\flutter.bat run -d windows --dart-define=ENVIRONMENT=development
pause


