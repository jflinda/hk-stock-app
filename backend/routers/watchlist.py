"""Watchlist CRUD router"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import sqlite3
import os
from services.market_service import MarketService

router = APIRouter()
DB_PATH = os.path.join(os.path.dirname(__file__), "..", "database", "hkstock.db")
market_service = MarketService()

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

class WatchlistItemRequest(BaseModel):
    ticker: str
    alert_price: Optional[float] = None
    alert_type: Optional[str] = None

@router.get("")
def get_watchlist():
    """Get all watchlist items with current prices"""
    with get_db() as conn:
        rows = conn.execute(
            """SELECT w.ticker, w.name, w.alert_price, w.alert_type, w.added_at 
               FROM watchlist w ORDER BY w.added_at DESC"""
        ).fetchall()
    
    result = []
    for r in rows:
        ticker = r["ticker"]
        try:
            # Get current price from market service
            quote = market_service.get_quote(ticker)
            result.append({
                "ticker": ticker,
                "name": r["name"] or quote.get("name", ""),
                "price": quote.get("price", 0.0),
                "change": quote.get("change", 0.0),
                "changePct": quote.get("changePct", 0.0),
                "alertPrice": r["alert_price"],
                "alertType": r["alert_type"],
            })
        except:
            # If quote fetch fails, return last known data
            result.append({
                "ticker": ticker,
                "name": r["name"] or ticker,
                "price": 0.0,
                "change": 0.0,
                "changePct": 0.0,
                "alertPrice": r["alert_price"],
                "alertType": r["alert_type"],
            })
    return result

@router.post("")
def add_to_watchlist(item: WatchlistItemRequest):
    """Add stock to watchlist"""
    try:
        # Validate ticker by fetching its quote
        quote = market_service.get_quote(item.ticker)
        name = quote.get("name", item.ticker)
        
        with get_db() as conn:
            conn.execute(
                """INSERT INTO watchlist (ticker, name, alert_price, alert_type, added_at) 
                   VALUES (?, ?, ?, ?, ?)""",
                (item.ticker.upper(), name, item.alert_price, item.alert_type, datetime.now().isoformat())
            )
            conn.commit()
        
        return {
            "ticker": item.ticker.upper(),
            "name": name,
            "price": quote.get("price", 0.0),
            "change": quote.get("change", 0.0),
            "changePct": quote.get("changePct", 0.0),
            "alertPrice": item.alert_price,
            "alertType": item.alert_type,
        }
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Ticker already in watchlist")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid ticker: {str(e)}")

@router.delete("/{ticker}")
def remove_from_watchlist(ticker: str):
    """Remove stock from watchlist"""
    with get_db() as conn:
        cursor = conn.execute("DELETE FROM watchlist WHERE ticker=?", (ticker.upper(),))
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Ticker not found in watchlist")
    return {"status": "removed", "ticker": ticker.upper()}
