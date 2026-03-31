"""Market data router — indices, sectors, movers"""
from fastapi import APIRouter, HTTPException
from services.market_service import MarketService

router = APIRouter()

@router.get("/indices", tags=["Market"])
def get_indices():
    """Get all major indices (HSI, HSCEI, HSTI, S&P 500, SSE) with real-time quotes"""
    try:
        return MarketService.get_indices()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/movers", tags=["Market"])
def get_movers():
    """Get top 5 gainers, losers, and highest volume stocks"""
    try:
        return MarketService.get_movers()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
