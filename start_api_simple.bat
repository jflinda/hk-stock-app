@echo off
echo Killing existing Python processes...
taskkill /F /IM python.exe > nul 2>&1
timeout /t 2 /nobreak > nul

echo Starting HK Stock API Server...
echo API will be available at:
echo   - Local: http://localhost:8001
echo   - Mobile: http://192.168.3.30:8001
echo   - Docs: http://localhost:8001/docs
echo.

cd /d "%~dp0backend"
"C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" -c "import uvicorn; uvicorn.run('main:app', host='0.0.0.0', port=8001)"