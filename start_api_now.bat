@echo off
echo Starting API Server on port 8001...
echo.

REM First, kill any existing Python processes on port 8001
echo Stopping any existing processes on port 8001...
netstat -ano | findstr :8001 > nul
if not errorlevel 1 (
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8001') do (
        taskkill /F /PID %%a
    )
)

REM Change to backend directory
cd /d "%~dp0backend"

REM Start the API server
echo Starting FastAPI server...
"C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" -m uvicorn main:app --host 0.0.0.0 --port 8001

echo.
echo Server started. Press Ctrl+C to stop.
pause