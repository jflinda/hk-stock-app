"""Portfolio Performance Review router — 7 submodules"""
from fastapi import APIRouter
from typing import List, Dict, Any
import sqlite3
import os
from datetime import datetime, timedelta
from services.market_service import MarketService

router = APIRouter()
DB_PATH = os.path.join(os.path.dirname(__file__), "..", "database", "hkstock.db")
_market = MarketService()

# ── HSI benchmark ticker ───────────────────────────────────────────────────────
HSI_TICKER = "^HSI"


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def _fetch_trades() -> List[Dict[str, Any]]:
    with get_db() as conn:
        rows = conn.execute(
            "SELECT * FROM trades ORDER BY trade_date ASC"
        ).fetchall()
    return [dict(r) for r in rows]


# ── Helpers ───────────────────────────────────────────────────────────────────

def _parse_date(d: str) -> datetime:
    """Parse YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS to datetime."""
    try:
        return datetime.strptime(d[:10], "%Y-%m-%d")
    except Exception:
        return datetime.now()


def _compute_timeline(trades: List[Dict]) -> List[Dict]:
    """
    Build a monthly portfolio-value timeline using trade data.
    Returns list of {month: 'YYYY-MM', value: float, costBasis: float, pl: float}.
    Uses last recorded trade values — simplified since we don't store daily prices.
    """
    if not trades:
        return []

    first_date = _parse_date(trades[0]["trade_date"])
    today = datetime.now()

    # Build per-ticker running position (qty × avg_cost as book value)
    monthly = []
    current = datetime(first_date.year, first_date.month, 1)
    positions: Dict[str, Dict] = {}

    trade_idx = 0

    while current <= today:
        next_month = (current.replace(day=28) + timedelta(days=4)).replace(day=1)
        # Process all trades up to end of this month
        while trade_idx < len(trades):
            td = _parse_date(trades[trade_idx]["trade_date"])
            if td >= next_month:
                break
            t = trades[trade_idx]
            ticker = t["ticker"]
            if ticker not in positions:
                positions[ticker] = {"qty": 0, "total_cost": 0.0}
            p = positions[ticker]
            if t["direction"] == "BUY":
                p["total_cost"] += t["qty"] * t["price"] + t["fee"]
                p["qty"] += t["qty"]
            else:
                if p["qty"] > 0:
                    avg = p["total_cost"] / p["qty"]
                    p["total_cost"] -= avg * t["qty"]
                    p["qty"] -= t["qty"]
            trade_idx += 1

        # Cost basis at end of month
        cost_basis = sum(p["total_cost"] for p in positions.values() if p["qty"] > 0)
        if cost_basis > 0:
            monthly.append({
                "month": current.strftime("%Y-%m"),
                "costBasis": round(cost_basis, 2),
            })
        current = next_month

    return monthly


def _compute_realized_pl(trades: List[Dict]) -> List[Dict]:
    """
    Compute realized P&L per SELL trade using FIFO cost from all prior BUYs.
    Returns list of {date, ticker, pl, isWin}.
    """
    from collections import defaultdict
    buy_lots: Dict[str, list] = defaultdict(list)  # ticker → [(qty, price, fee_per_share)]
    results = []
    for t in trades:
        ticker = t["ticker"]
        if t["direction"] == "BUY":
            fee_per = t["fee"] / max(t["qty"], 1)
            buy_lots[ticker].append([t["qty"], float(t["price"]), fee_per])
        else:
            sell_qty = t["qty"]
            sell_price = float(t["price"])
            sell_fee = float(t["fee"])
            cost = 0.0
            remaining = sell_qty
            for lot in buy_lots[ticker]:
                if remaining <= 0:
                    break
                take = min(lot[0], remaining)
                cost += take * (lot[1] + lot[2])
                lot[0] -= take
                remaining -= take
            revenue = sell_qty * sell_price - sell_fee
            pl = revenue - cost
            results.append({
                "date": t["trade_date"][:10],
                "ticker": ticker,
                "pl": round(pl, 2),
                "isWin": pl > 0,
            })
    return results


def _compute_holding_days(trades: List[Dict]) -> List[Dict]:
    """Compute average holding period per completed round-trip."""
    from collections import defaultdict
    open_dates: Dict[str, list] = defaultdict(list)
    holdings = []
    for t in trades:
        ticker = t["ticker"]
        if t["direction"] == "BUY":
            open_dates[ticker].append(_parse_date(t["trade_date"]))
        else:
            if open_dates[ticker]:
                buy_date = open_dates[ticker].pop(0)
                sell_date = _parse_date(t["trade_date"])
                days = (sell_date - buy_date).days
                holdings.append({
                    "ticker": ticker,
                    "buyDate": buy_date.strftime("%Y-%m-%d"),
                    "sellDate": sell_date.strftime("%Y-%m-%d"),
                    "holdingDays": days,
                })
    return holdings


# ── Main endpoint ─────────────────────────────────────────────────────────────

@router.get("")
def get_performance() -> Dict[str, Any]:
    """
    Portfolio Performance Review — all 7 submodules in one response.

    Submodules:
      1. overview        – total P&L, return %, win rate, profit factor
      2. monthly_returns – monthly P&L breakdown
      3. cumulative      – cumulative portfolio cost-basis timeline
      4. drawdown        – max drawdown estimation from realized P&L curve
      5. sector_pl       – P&L contribution per ticker
      6. holding_periods – average holding days
      7. benchmark       – portfolio vs HSI benchmark performance (YTD cost return)
    """
    trades = _fetch_trades()

    if not trades:
        return {
            "overview": _empty_overview(),
            "monthlyReturns": [],
            "cumulative": [],
            "drawdown": {"maxDrawdown": 0.0, "maxDrawdownPct": 0.0},
            "sectorPL": [],
            "holdingPeriods": {"avgDays": 0, "details": []},
            "benchmark": {"portfolio": 0.0, "hsi": 0.0, "alpha": 0.0},
        }

    realized = _compute_realized_pl(trades)
    holding_data = _compute_holding_days(trades)
    timeline = _compute_timeline(trades)

    # ── 1. Overview ────────────────────────────────────────────────────────
    total_cost = sum(
        t["qty"] * t["price"] + t["fee"]
        for t in trades if t["direction"] == "BUY"
    )
    total_revenue = sum(
        t["qty"] * t["price"] - t["fee"]
        for t in trades if t["direction"] == "SELL"
    )
    total_realized_pl = sum(r["pl"] for r in realized)
    wins = [r for r in realized if r["isWin"]]
    losses = [r for r in realized if not r["isWin"]]
    win_rate = len(wins) / len(realized) * 100 if realized else 0
    avg_win = sum(r["pl"] for r in wins) / len(wins) if wins else 0
    avg_loss = abs(sum(r["pl"] for r in losses) / len(losses)) if losses else 0
    profit_factor = (sum(r["pl"] for r in wins) / sum(abs(r["pl"]) for r in losses)) if losses else 0

    # Sell cost basis for return % computation
    sell_cost = sum(
        t["qty"] * t["price"] + t["fee"]
        for t in trades if t["direction"] == "BUY"
    )
    return_pct = (total_realized_pl / sell_cost * 100) if sell_cost > 0 else 0.0

    overview = {
        "totalRealizedPL": round(total_realized_pl, 2),
        "returnPct": round(return_pct, 2),
        "totalTrades": len(trades),
        "completedTrades": len(realized),
        "winRate": round(win_rate, 1),
        "avgWin": round(avg_win, 2),
        "avgLoss": round(avg_loss, 2),
        "profitFactor": round(profit_factor, 2),
    }

    # ── 2. Monthly returns ─────────────────────────────────────────────────
    monthly_map: Dict[str, float] = {}
    for r in realized:
        month = r["date"][:7]
        monthly_map[month] = monthly_map.get(month, 0.0) + r["pl"]

    monthly_returns = sorted(
        [{"month": k, "pl": round(v, 2)} for k, v in monthly_map.items()],
        key=lambda x: x["month"],
    )

    # ── 3. Cumulative P&L curve ────────────────────────────────────────────
    cumulative_pl = 0.0
    cum_curve = []
    for r in sorted(realized, key=lambda x: x["date"]):
        cumulative_pl += r["pl"]
        cum_curve.append({"date": r["date"], "cumPL": round(cumulative_pl, 2)})

    # ── 4. Max Drawdown (on cumulative P&L curve) ──────────────────────────
    peak = 0.0
    max_dd = 0.0
    peak_val = 0.0
    running = 0.0
    for r in sorted(realized, key=lambda x: x["date"]):
        running += r["pl"]
        if running > peak_val:
            peak_val = running
        dd = peak_val - running
        if dd > max_dd:
            max_dd = dd
            peak = peak_val

    max_dd_pct = (max_dd / peak * 100) if peak > 0 else 0.0
    drawdown = {
        "maxDrawdown": round(max_dd, 2),
        "maxDrawdownPct": round(max_dd_pct, 2),
    }

    # ── 5. Sector / Ticker P&L breakdown ──────────────────────────────────
    ticker_pl: Dict[str, float] = {}
    for r in realized:
        ticker_pl[r["ticker"]] = ticker_pl.get(r["ticker"], 0.0) + r["pl"]

    sector_pl = sorted(
        [{"ticker": k, "pl": round(v, 2)} for k, v in ticker_pl.items()],
        key=lambda x: x["pl"],
        reverse=True,
    )

    # ── 6. Holding periods ────────────────────────────────────────────────
    avg_days = (
        sum(h["holdingDays"] for h in holding_data) / len(holding_data)
        if holding_data else 0
    )
    holding_periods = {
        "avgDays": round(avg_days, 1),
        "details": holding_data[-20:],  # last 20 round-trips
    }

    # ── 7. Benchmark comparison ───────────────────────────────────────────
    # Compare portfolio total realized return% vs HSI YTD (use "1y" period, filter to YTD)
    hsi_ytd = 0.0
    try:
        import yfinance as yf
        ticker_obj = yf.Ticker(HSI_TICKER)
        hist = ticker_obj.history(period="1y").dropna(subset=["Close"])
        year_start = datetime(datetime.now().year, 1, 1)
        hist.index = hist.index.tz_localize(None) if hist.index.tzinfo is not None else hist.index
        ytd_hist = hist[hist.index >= year_start]
        if len(ytd_hist) >= 2:
            start_price = float(ytd_hist["Close"].iloc[0])
            end_price = float(ytd_hist["Close"].iloc[-1])
            if start_price > 0:
                hsi_ytd = round((end_price - start_price) / start_price * 100, 2)
    except Exception:
        hsi_ytd = 0.0

    benchmark = {
        "portfolioReturn": round(return_pct, 2),
        "hsiYTD": hsi_ytd,
        "alpha": round(return_pct - hsi_ytd, 2),
    }

    return {
        "overview": overview,
        "monthlyReturns": monthly_returns,
        "cumulative": cum_curve,
        "drawdown": drawdown,
        "sectorPL": sector_pl,
        "holdingPeriods": holding_periods,
        "benchmark": benchmark,
    }


def _empty_overview() -> Dict[str, Any]:
    return {
        "totalRealizedPL": 0.0,
        "returnPct": 0.0,
        "totalTrades": 0,
        "completedTrades": 0,
        "winRate": 0.0,
        "avgWin": 0.0,
        "avgLoss": 0.0,
        "profitFactor": 0.0,
    }
