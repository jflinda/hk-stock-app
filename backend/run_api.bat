@echo off
REM Start FastAPI Backend Server
REM Usage: run_api.bat

cd /d "%~dp0"
echo Starting HK Stock App FastAPI Backend...
echo.

REM Use Python 3.14.3 from .workbuddy
"C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe" -m uvicorn main:app --reload --port 8000

pause
