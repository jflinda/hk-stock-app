@echo off
echo Killing existing Python processes...
taskkill /F /IM python.exe > nul 2>&1
timeout /t 2 /nobreak > nul

echo Starting HK Stock API Server...
echo API will be available at:
echo   - Local: http://localhost:8000
echo   - Mobile: http://192.168.3.30:8000
echo.

cd /d "%~dp0backend"
"python.exe" -m uvicorn main:app --host 0.0.0.0 --port 8000

echo.
echo API server stopped.
pause