"""Trade records CRUD router"""
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

class Trade(BaseModel):
    ticker:     str
    name:       Optional[str] = None
    direction:  str   # BUY or SELL
    qty:        int
    price:      float
    fee:        float = 0.0
    trade_date: str   # YYYY-MM-DD
    notes:      Optional[str] = None

@router.get("")
def get_trades():
    with get_db() as conn:
        rows = conn.execute("SELECT * FROM trades ORDER BY trade_date DESC").fetchall()
    return [dict(r) for r in rows]

@router.post("")
def add_trade(trade: Trade):
    if trade.direction not in ("BUY", "SELL"):
        raise HTTPException(status_code=400, detail="direction must be BUY or SELL")
    with get_db() as conn:
        cur = conn.execute(
            "INSERT INTO trades (ticker,name,direction,qty,price,fee,trade_date,notes) VALUES (?,?,?,?,?,?,?,?)",
            (trade.ticker.upper(), trade.name, trade.direction, trade.qty,
             trade.price, trade.fee, trade.trade_date, trade.notes)
        )
        conn.commit()
        return {"status": "created", "id": cur.lastrowid}

@router.delete("/{trade_id}")
def delete_trade(trade_id: int):
    with get_db() as conn:
        conn.execute("DELETE FROM trades WHERE id=?", (trade_id,))
        conn.commit()
    return {"status": "deleted", "id": trade_id}
