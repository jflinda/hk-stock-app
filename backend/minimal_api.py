"""
Minimal HK Stock App API for testing
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="HK Stock App API (Minimal)",
    description="Minimal backend API for testing",
    version="1.0.0"
)

# Allow Flutter app (localhost) to call the API during development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/ping")
def ping():
    return {"status": "ok", "message": "Minimal API is running"}

@app.get("/health")
def health():
    return {"status": "healthy", "timestamp": "2026-04-01T15:30:00Z"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)