"""Market data router — indices, sectors, movers"""
from fastapi import APIRouter
import yfinance as yf
import pandas as pd

router = APIRouter()

INDICES = {
    "HSI":    "^HSI",
    "HSCEI":  "^HSCE",
    "SP500":  "^GSPC",
    "SSE":    "000001.SS",
}

@router.get("/indices")
def get_indices():
    result = []
    for name, symbol in INDICES.items():
        try:
            t = yf.Ticker(symbol)
            hist = t.history(period="2d")
            if len(hist) >= 2:
                prev  = hist["Close"].iloc[-2]
                curr  = hist["Close"].iloc[-1]
                pct   = (curr - prev) / prev * 100
            else:
                curr = hist["Close"].iloc[-1]
                pct  = 0.0
            result.append({"name": name, "symbol": symbol, "price": round(curr, 2), "pct": round(pct, 2)})
        except Exception as e:
            result.append({"name": name, "symbol": symbol, "price": 0, "pct": 0, "error": str(e)})
    return result

@router.get("/movers")
def get_movers():
    # Static watchlist of liquid HK stocks for mover ranking
    tickers = ["0700.HK","9988.HK","3690.HK","2318.HK","0883.HK","1299.HK","0016.HK",
               "0941.HK","2628.HK","0386.HK","1088.HK","0857.HK","9618.HK","2015.HK"]
    movers = []
    for sym in tickers:
        try:
            t = yf.Ticker(sym)
            h = t.history(period="2d")
            if len(h) >= 2:
                prev = h["Close"].iloc[-2]; curr = h["Close"].iloc[-1]
                pct  = (curr - prev) / prev * 100
                vol  = int(h["Volume"].iloc[-1])
                movers.append({"ticker": sym.replace(".HK",""), "price": round(curr,2),
                                "pct": round(pct,2), "volume": vol})
        except:
            pass
    gainers  = sorted(movers, key=lambda x: x["pct"], reverse=True)[:5]
    losers   = sorted(movers, key=lambda x: x["pct"])[:5]
    turnover = sorted(movers, key=lambda x: x["volume"], reverse=True)[:5]
    return {"gainers": gainers, "losers": losers, "turnover": turnover}
