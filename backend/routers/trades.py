"""Trade records CRUD router"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
import sqlite3
import os

router = APIRouter()
DB_PATH = os.path.join(os.path.dirname(__file__), "..", "database", "hkstock.db")

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

class TradeRequest(BaseModel):
    ticker: str
    type: str          # BUY or SELL
    quantity: int
    price: float
    commission: float = 0.0
    trade_date: str    # ISO 8601 datetime string
    notes: Optional[str] = None

@router.get("")
def get_trades(limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
    """Get trade history with pagination"""
    with get_db() as conn:
        rows = conn.execute(
            "SELECT * FROM trades ORDER BY trade_date DESC LIMIT ? OFFSET ?",
            (limit, offset)
        ).fetchall()
    
    result = []
    for r in rows:
        result.append({
            "id": str(r["id"]),
            "ticker": r["ticker"],
            "name": r["name"] or r["ticker"],
            "type": r["direction"],
            "quantity": r["qty"],
            "price": float(r["price"]),
            "commission": float(r["fee"]),
            "tradeDate": r["trade_date"],
            "pl": 0.0,     # Calculated in portfolio
            "plPct": 0.0,  # Calculated in portfolio
            "notes": r["notes"],
        })
    return result

@router.post("")
def add_trade(trade: TradeRequest) -> Dict[str, Any]:
    """Add a new trade record"""
    if trade.type not in ("BUY", "SELL"):
        raise HTTPException(status_code=400, detail="type must be BUY or SELL")
    
    # Parse and normalize trade_date
    try:
        if "T" in trade.trade_date:
            trade_dt = datetime.fromisoformat(trade.trade_date)
            trade_date_str = trade_dt.strftime("%Y-%m-%d")
        else:
            trade_date_str = trade.trade_date
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid trade_date format")
    
    with get_db() as conn:
        cursor = conn.execute(
            """INSERT INTO trades (ticker, name, direction, qty, price, fee, trade_date, notes) 
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                trade.ticker.upper(),
                trade.ticker.upper(),  # Will be overwritten with name from market service
                trade.type,
                trade.quantity,
                trade.price,
                trade.commission,
                trade_date_str,
                trade.notes
            )
        )
        conn.commit()
        new_id = cursor.lastrowid
    
    return {
        "id": str(new_id),
        "ticker": trade.ticker.upper(),
        "name": trade.ticker.upper(),
        "type": trade.type,
        "quantity": trade.quantity,
        "price": trade.price,
        "commission": trade.commission,
        "tradeDate": trade_date_str,
        "pl": 0.0,
        "plPct": 0.0,
        "notes": trade.notes,
    }

@router.delete("/{trade_id}")
def delete_trade(trade_id: int) -> Dict[str, str]:
    """Delete a trade record"""
    with get_db() as conn:
        cursor = conn.execute("DELETE FROM trades WHERE id=?", (trade_id,))
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Trade not found")
    return {"status": "deleted", "id": str(trade_id)}
