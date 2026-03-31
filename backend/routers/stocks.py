"""Stock quote, history, and search router"""
from fastapi import APIRouter, HTTPException, Query
from services.market_service import MarketService

router = APIRouter()

@router.get("/{ticker}/quote", tags=["Stocks"])
def get_quote(ticker: str):
    """Get single stock quote with detailed information (price, volume, 52-week high/low, P/E, etc)"""
    try:
        return MarketService.get_stock_quote(ticker)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Stock {ticker} not found: {str(e)}")

@router.get("/{ticker}/history", tags=["Stocks"])
def get_history(
    ticker: str,
    period: str = Query("1mo", description="1d/5d/1m/3m/1y - time period for K-line data")
):
    """Get historical OHLCV data with MA5 and MA20 moving averages
    
    Period options:
    - 1d: Last 5 days
    - 5d: Last month  
    - 1m/1mo: Last 3 months
    - 3m/3mo: Last year
    - 1y: Last year
    """
    try:
        return MarketService.get_stock_history(ticker, period)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"History for {ticker} not found: {str(e)}")

@router.get("/search", tags=["Stocks"])
def search_stocks(q: str = Query(..., min_length=1, description="Search by ticker code or company name")):
    """Search stocks by ticker code or company name"""
    STOCKS = [
        {"ticker": "0700", "name": "Tencent", "sector": "Consumer"},
        {"ticker": "9988", "name": "Alibaba", "sector": "Consumer"},
        {"ticker": "3690", "name": "Meituan", "sector": "Consumer"},
        {"ticker": "2318", "name": "Ping An", "sector": "Finance"},
        {"ticker": "0883", "name": "CNOOC", "sector": "Energy"},
        {"ticker": "1299", "name": "AIA Group", "sector": "Finance"},
        {"ticker": "0016", "name": "Sun Hung Kai", "sector": "Properties"},
        {"ticker": "0941", "name": "China Mobile", "sector": "Telecom"},
        {"ticker": "2628", "name": "China Life", "sector": "Finance"},
        {"ticker": "0939", "name": "CCB", "sector": "Finance"},
        {"ticker": "1398", "name": "ICBC", "sector": "Finance"},
        {"ticker": "3988", "name": "BOC", "sector": "Finance"},
        {"ticker": "0857", "name": "PetroChina", "sector": "Energy"},
        {"ticker": "0386", "name": "Sinopec", "sector": "Energy"},
        {"ticker": "1088", "name": "China Shenhua", "sector": "Materials"},
        {"ticker": "9618", "name": "JD.com", "sector": "Consumer"},
        {"ticker": "2015", "name": "Li Auto", "sector": "Consumer"},
        {"ticker": "9868", "name": "XPeng", "sector": "Consumer"},
        {"ticker": "9863", "name": "NIO", "sector": "Consumer"},
        {"ticker": "0981", "name": "SMIC", "sector": "Materials"},
        {"ticker": "9961", "name": "Trip.com", "sector": "Consumer"},
        {"ticker": "1024", "name": "Kuaishou", "sector": "Consumer"},
    ]
    q_lower = q.lower()
    results = [s for s in STOCKS if q_lower in s["ticker"] or q_lower in s["name"].lower()]
    return results
