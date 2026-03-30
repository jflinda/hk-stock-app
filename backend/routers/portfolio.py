"""Portfolio positions and P&L router"""
from fastapi import APIRouter
import sqlite3, os

router = APIRouter()
DB_PATH = os.path.join(os.path.dirname(__file__), "..", "database", "hkstock.db")

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

@router.get("/positions")
def get_positions():
    """Calculate current positions with weighted average cost"""
    with get_db() as conn:
        rows = conn.execute("SELECT * FROM trades ORDER BY trade_date ASC").fetchall()

    positions = {}
    for r in rows:
        t = r["ticker"]
        if t not in positions:
            positions[t] = {"ticker": t, "name": r["name"], "qty": 0, "total_cost": 0.0, "realized_pnl": 0.0}
        p = positions[t]
        if r["direction"] == "BUY":
            p["total_cost"] += r["qty"] * r["price"] + r["fee"]
            p["qty"]        += r["qty"]
        else:  # SELL
            if p["qty"] > 0:
                avg_cost = p["total_cost"] / p["qty"]
                p["realized_pnl"] += (r["price"] - avg_cost) * r["qty"] - r["fee"]
                p["total_cost"]   -= avg_cost * r["qty"]
                p["qty"]          -= r["qty"]

    result = []
    for t, p in positions.items():
        if p["qty"] > 0:
            avg_cost = p["total_cost"] / p["qty"]
            result.append({
                "ticker":       p["ticker"],
                "name":         p["name"],
                "qty":          p["qty"],
                "avg_cost":     round(avg_cost, 3),
                "total_cost":   round(p["total_cost"], 2),
                "realized_pnl": round(p["realized_pnl"], 2),
            })
    return result

@router.get("/summary")
def get_summary():
    """Portfolio-level P&L summary"""
    positions = get_positions()
    total_cost = sum(p["total_cost"] for p in positions)
    realized   = sum(p["realized_pnl"] for p in positions)
    return {
        "positions_count": len(positions),
        "total_cost":      round(total_cost, 2),
        "realized_pnl":    round(realized, 2),
    }
