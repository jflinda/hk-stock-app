"""Watchlist CRUD router"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
import sqlite3, os

router = APIRouter()
DB_PATH = os.path.join(os.path.dirname(__file__), "..", "database", "hkstock.db")

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

class WatchlistItem(BaseModel):
    ticker: str
    name:   Optional[str] = None
    alert_price: Optional[float] = None
    notes:  Optional[str] = None

@router.get("")
def get_watchlist():
    with get_db() as conn:
        rows = conn.execute("SELECT * FROM watchlist ORDER BY added_at DESC").fetchall()
    return [dict(r) for r in rows]

@router.post("")
def add_to_watchlist(item: WatchlistItem):
    try:
        with get_db() as conn:
            conn.execute(
                "INSERT INTO watchlist (ticker, name, alert_price, notes) VALUES (?,?,?,?)",
                (item.ticker.upper(), item.name, item.alert_price, item.notes)
            )
            conn.commit()
        return {"status": "added", "ticker": item.ticker.upper()}
    except sqlite3.IntegrityError:
        raise HTTPException(status_code=400, detail="Ticker already in watchlist")

@router.delete("/{ticker}")
def remove_from_watchlist(ticker: str):
    with get_db() as conn:
        conn.execute("DELETE FROM watchlist WHERE ticker=?", (ticker.upper(),))
        conn.commit()
    return {"status": "removed", "ticker": ticker.upper()}
