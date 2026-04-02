@echo off
echo ============================================
echo HK Stock App - API Server Manual Start
echo ============================================
echo.
echo This script will start the API server on port 8001
echo to avoid conflicts with existing processes.
echo.
echo Press Ctrl+C to stop the server.
echo.
echo Starting server...

cd /d "%~dp0backend"
"C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" -c "import uvicorn; uvicorn.run('main:app', host='0.0.0.0', port=8001, log_level='info')"