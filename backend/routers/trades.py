"""Trade records CRUD router"""
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
import sqlite3
import csv
import io
import os
from services.market_service import MarketService

router = APIRouter()
DB_PATH = os.path.join(os.path.dirname(__file__), "..", "database", "hkstock.db")
_market_service = MarketService()

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
    
    # Resolve the real company name from market data
    ticker_upper = trade.ticker.upper()
    company_name = ticker_upper  # default fallback
    try:
        quote = _market_service.get_quote(ticker_upper)
        resolved_name = quote.get("name") or quote.get("longName") or ticker_upper
        if resolved_name and resolved_name != ticker_upper:
            company_name = resolved_name
    except Exception:
        pass  # Keep fallback; don't block trade entry on market data failure

    with get_db() as conn:
        cursor = conn.execute(
            """INSERT INTO trades (ticker, name, direction, qty, price, fee, trade_date, notes) 
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                ticker_upper,
                company_name,
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
        "ticker": ticker_upper,
        "name": company_name,
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


@router.get("/export/csv")
def export_trades_csv():
    """Export all trades as a downloadable CSV file"""
    with get_db() as conn:
        rows = conn.execute(
            "SELECT * FROM trades ORDER BY trade_date DESC"
        ).fetchall()

    output = io.StringIO()
    writer = csv.writer(output)
    # Header row
    writer.writerow([
        "ID", "Date", "Ticker", "Name", "Direction",
        "Qty", "Price (HKD)", "Commission (HKD)",
        "Total Value (HKD)", "Notes"
    ])
    for r in rows:
        writer.writerow([
            r["id"],
            r["trade_date"],
            r["ticker"],
            r["name"] or r["ticker"],
            r["direction"],
            r["qty"],
            f"{float(r['price']):.4f}",
            f"{float(r['fee']):.2f}",
            f"{float(r['price']) * int(r['qty']):.2f}",
            r["notes"] or "",
        ])

    output.seek(0)
    filename = f"hk_trades_{datetime.now().strftime('%Y%m%d')}.csv"
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
