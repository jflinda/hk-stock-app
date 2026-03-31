"""Portfolio positions and P&L router"""
from fastapi import APIRouter
from typing import List, Dict, Any
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

@router.get("/positions")
def get_positions() -> List[Dict[str, Any]]:
    """Calculate current positions with weighted average cost and current P&L"""
    with get_db() as conn:
        rows = conn.execute("SELECT * FROM trades ORDER BY trade_date ASC").fetchall()

    positions = {}
    for r in rows:
        t = r["ticker"]
        if t not in positions:
            positions[t] = {
                "ticker": t,
                "name": r["name"],
                "quantity": 0,
                "avgCost": 0.0,
                "totalCost": 0.0,
                "realizedPL": 0.0,
            }
        p = positions[t]
        if r["direction"] == "BUY":
            p["totalCost"] += r["qty"] * r["price"] + r["fee"]
            p["quantity"] += r["qty"]
        else:  # SELL
            if p["quantity"] > 0:
                avg_cost = p["totalCost"] / p["quantity"]
                p["realizedPL"] += (r["price"] - avg_cost) * r["qty"] - r["fee"]
                p["totalCost"] -= avg_cost * r["qty"]
                p["quantity"] -= r["qty"]

    result = []
    for t, p in positions.items():
        if p["quantity"] > 0:
            avg_cost = p["totalCost"] / p["quantity"]
            p["avgCost"] = round(avg_cost, 3)
            
            # Get current price
            try:
                quote = market_service.get_quote(t)
                current_price = quote.get("price", avg_cost) or avg_cost
            except:
                current_price = avg_cost  # Fall back to avg cost if price unavailable
            
            current_value = current_price * p["quantity"]
            unrealized_pl = current_value - p["totalCost"]
            
            result.append({
                "ticker": t,
                "name": p["name"],
                "quantity": p["quantity"],
                "avgCost": p["avgCost"],
                "currentPrice": round(float(current_price), 3),
                "costValue": round(p["totalCost"], 2),
                "currentValue": round(float(current_value), 2),
                "pl": round(float(unrealized_pl), 2),
                "plPct": round(float((unrealized_pl / p["totalCost"] * 100) if p["totalCost"] > 0 else 0), 2),
            })
    
    return result

@router.get("/summary")
def get_summary() -> Dict[str, Any]:
    """Portfolio-level P&L summary"""
    positions = get_positions()
    
    with get_db() as conn:
        trades = conn.execute("SELECT * FROM trades").fetchall()
    
    total_value = sum(float(p.get("currentValue") or 0) for p in positions)
    total_cost = sum(float(p.get("costValue") or 0) for p in positions)
    total_pl = total_value - total_cost
    
    # Calculate trade statistics
    buy_trades = [t for t in trades if t["direction"] == "BUY"]
    sell_trades = [t for t in trades if t["direction"] == "SELL"]
    
    total_win = 0
    total_loss = 0
    win_count = 0
    loss_count = 0
    
    for sell_trade in sell_trades:
        ticker = sell_trade["ticker"]
        # Find corresponding buy for this sell
        buy_price_total = sum(t["qty"] * t["price"] for t in buy_trades if t["ticker"] == ticker)
        buy_qty_total = sum(t["qty"] for t in buy_trades if t["ticker"] == ticker)
        
        if buy_qty_total > 0:
            avg_buy = buy_price_total / buy_qty_total
            trade_pl = (sell_trade["price"] - avg_buy) * sell_trade["qty"] - sell_trade["fee"]
            
            if trade_pl > 0:
                total_win += trade_pl
                win_count += 1
            else:
                total_loss += abs(trade_pl)
                loss_count += 1
    
    win_rate = (win_count / (win_count + loss_count) * 100) if (win_count + loss_count) > 0 else 0
    avg_win = (total_win / win_count) if win_count > 0 else 0
    avg_loss = (total_loss / loss_count) if loss_count > 0 else 0
    
    return {
        "totalValue": round(total_value, 2),
        "totalCost": round(total_cost, 2),
        "totalPL": round(total_pl, 2),
        "totalPLPct": round((total_pl / total_cost * 100) if total_cost > 0 else 0, 2),
        "totalHoldings": len(positions),
        "totalTrades": len(trades),
        "winRate": round(win_rate, 2),
        "avgWin": round(avg_win, 2),
        "avgLoss": round(avg_loss, 2),
    }
