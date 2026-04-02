@echo off
echo Starting HK Stock App Backend API on port 8001...
echo Backend: http://localhost:8001
echo API Docs: http://localhost:8001/docs
echo ReDoc: http://localhost:8001/redoc

cd /d "%~dp0"
"C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload