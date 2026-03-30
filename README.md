# HK Stock Investment App

A personal Android app for Hong Kong stock market analysis, built with Flutter + Python FastAPI.

## Quick Start (Backend)

```bash
# Use the pre-installed Python
$py = "C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe"

# Init database (first time only)
& $py backend\database\init_db.py

# Start API server
cd backend
& $py -m uvicorn main:app --reload --port 8000
# API docs: http://localhost:8000/docs
```

## Tech Stack

| Layer    | Technology          |
|----------|---------------------|
| Android  | Flutter 3.x (Dart)  |
| Backend  | Python FastAPI      |
| Data     | yfinance (Yahoo)    |
| Storage  | SQLite (sqflite)    |

## Project Structure

```
stocktrading/
├── backend/              ← Python FastAPI server
│   ├── main.py           ← Entry point
│   ├── routers/          ← API route handlers
│   ├── database/         ← SQLite schema + init
│   └── requirements.txt
├── frontend/             ← Flutter Android app (to be created)
├── docs/                 ← API spec, DB design
├── portfolio_prototype.html  ← UI prototype (browser preview)
└── 01–04 docs            ← Requirements, plan, checklist
```

## Python Path

`C:\Users\jflin\.workbuddy\binaries\python\versions\3.14.3\python.exe`
