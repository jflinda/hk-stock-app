@echo off
cd /d "c:\Users\jflin\WorkBuddy\20260329125422\stocktrading\backend"
echo Starting HK Stock API Server...
echo API will be available at: http://localhost:8000
echo.
echo Press Ctrl+C to stop the server
echo.
python -m uvicorn main:app --host 0.0.0.0 --port 8000