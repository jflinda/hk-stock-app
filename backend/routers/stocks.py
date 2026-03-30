"""Stock quote, history, and search router"""
from fastapi import APIRouter, HTTPException, Query
import yfinance as yf
import pandas as pd

router = APIRouter()

def hk_symbol(ticker: str) -> str:
    """Normalize ticker to Yahoo Finance HK format, e.g. '700' -> '0700.HK'"""
    t = ticker.upper().replace(".HK", "")
    return t.zfill(4) + ".HK"

@router.get("/{ticker}/quote")
def get_quote(ticker: str):
    sym = hk_symbol(ticker)
    try:
        t    = yf.Ticker(sym)
        hist = t.history(period="2d")
        curr = hist["Close"].iloc[-1]
        prev = hist["Close"].iloc[-2] if len(hist) >= 2 else curr
        pct  = (curr - prev) / prev * 100
        return {
            "ticker": ticker.upper(),
            "symbol": sym,
            "price":  round(curr, 2),
            "pct":    round(pct, 2),
            "open":   round(hist["Open"].iloc[-1], 2),
            "high":   round(hist["High"].iloc[-1], 2),
            "low":    round(hist["Low"].iloc[-1], 2),
            "volume": int(hist["Volume"].iloc[-1]),
        }
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/{ticker}/history")
def get_history(ticker: str, period: str = Query("1mo", description="1d/5d/1mo/3mo/1y")):
    sym = hk_symbol(ticker)
    try:
        hist = yf.Ticker(sym).history(period=period)
        # Calculate MA5 and MA20
        hist["ma5"]  = hist["Close"].rolling(5).mean()
        hist["ma20"] = hist["Close"].rolling(20).mean()
        records = []
        for date, row in hist.iterrows():
            records.append({
                "date":   str(date.date()),
                "open":   round(row["Open"], 2),
                "high":   round(row["High"], 2),
                "low":    round(row["Low"],  2),
                "close":  round(row["Close"],2),
                "volume": int(row["Volume"]),
                "ma5":    round(row["ma5"],  2) if not pd.isna(row["ma5"])  else None,
                "ma20":   round(row["ma20"], 2) if not pd.isna(row["ma20"]) else None,
            })
        return records
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/search")
def search_stocks(q: str = Query(..., min_length=1)):
    """Simple name/code search against a built-in stock list"""
    STOCKS = [
        {"ticker":"0700","name":"Tencent"},{"ticker":"9988","name":"Alibaba"},
        {"ticker":"3690","name":"Meituan"},{"ticker":"2318","name":"Ping An"},
        {"ticker":"0883","name":"CNOOC"},  {"ticker":"1299","name":"AIA Group"},
        {"ticker":"0016","name":"Sun Hung Kai"},{"ticker":"0941","name":"China Mobile"},
        {"ticker":"2628","name":"China Life"},  {"ticker":"0939","name":"CCB"},
        {"ticker":"1398","name":"ICBC"},   {"ticker":"3988","name":"BOC"},
        {"ticker":"0857","name":"PetroChina"},  {"ticker":"0386","name":"Sinopec"},
        {"ticker":"1088","name":"China Shenhua"},{"ticker":"9618","name":"JD.com"},
        {"ticker":"2015","name":"Li Auto"},{"ticker":"9868","name":"XPeng"},
        {"ticker":"9863","name":"NIO"},    {"ticker":"0981","name":"SMIC"},
        {"ticker":"9961","name":"Trip.com"},{"ticker":"1024","name":"Kuaishou"},
    ]
    q_lower = q.lower()
    return [s for s in STOCKS if q_lower in s["ticker"] or q_lower in s["name"].lower()]
