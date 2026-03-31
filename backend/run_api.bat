@echo off
echo Starting HK Stock App Backend API...
echo Backend: http://localhost:8000
echo API Docs: http://localhost:8000/docs

cd /d "%~dp0"
"C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
