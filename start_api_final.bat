@echo off
echo Starting API Server on port 8001...
echo.

REM Change to backend directory
cd /d "%~dp0backend"

echo Testing Python imports...
"C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" -c "import fastapi; import uvicorn; import yfinance; print('All imports OK')"

echo.
echo Starting FastAPI server...
"C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" -m uvicorn main:app --host 0.0.0.0 --port 8001

pause