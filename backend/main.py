"""
HK Stock App — FastAPI Backend Entry Point
Run: uvicorn main:app --reload --port 8000
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers import market, stocks, watchlist, trades, portfolio

app = FastAPI(
    title="HK Stock App API",
    description="Backend API for Hong Kong Stock Investment App",
    version="1.0.0"
)

# Allow Flutter app (localhost) to call the API during development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(market.router,    prefix="/api/market",    tags=["Market"])
app.include_router(stocks.router,    prefix="/api/stock",     tags=["Stocks"])
app.include_router(watchlist.router, prefix="/api/watchlist", tags=["Watchlist"])
app.include_router(trades.router,    prefix="/api/trades",    tags=["Trades"])
app.include_router(portfolio.router, prefix="/api/portfolio", tags=["Portfolio"])

@app.get("/ping")
def ping():
    return {"status": "ok", "message": "HK Stock App API is running"}
