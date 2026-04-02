# -*- coding: utf-8 -*-
"""
Comprehensive API Test - All endpoints
"""
import sys
import os
import json
import time
import requests

# Force UTF-8 output
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

BASE_URL = "http://localhost:8001"

def check(label, ok, detail=""):
    status = "PASS" if ok else "FAIL"
    print(f"[{status}] {label}")
    if detail and not ok:
        print(f"       -> {detail}")

def test_all():
    results = []
    
    print("=" * 70)
    print(" COMPREHENSIVE API TEST")
    print("=" * 70)
    
    # ── 1. Ping ──────────────────────────────────────────────────────────────
    print("\n[1] Basic Connectivity")
    print("-" * 40)
    try:
        r = requests.get(f"{BASE_URL}/ping", timeout=5)
        ok = r.status_code == 200
        check("GET /ping", ok, r.text[:100] if not ok else "")
        results.append(("ping", ok))
    except Exception as e:
        check("GET /ping", False, str(e))
        results.append(("ping", False))

    # ── 2. Market Indices ─────────────────────────────────────────────────────
    print("\n[2] Market Indices")
    print("-" * 40)
    try:
        r = requests.get(f"{BASE_URL}/api/market/indices", timeout=15)
        ok = r.status_code == 200
        check("GET /api/market/indices", ok, r.text[:100] if not ok else "")
        if ok:
            data = r.json()
            check(f"  Returns list (got {len(data)} items)", isinstance(data, list))
            if data:
                idx = data[0]
                has_name = "name" in idx
                has_price = "price" in idx
                has_change = "change_pct" in idx
                check(f"  Has required fields (name={idx.get('name')}, price={idx.get('price')}, change_pct={idx.get('change_pct')})", has_name and has_price and has_change)
                check(f"  Price > 0 ({idx.get('price')})", idx.get("price", 0) > 0)
        results.append(("indices", ok))
    except Exception as e:
        check("GET /api/market/indices", False, str(e))
        results.append(("indices", False))

    # ── 3. Stock Quote ─────────────────────────────────────────────────────
    print("\n[3] Stock Quote - 0700.HK (Tencent)")
    print("-" * 40)
    try:
        r = requests.get(f"{BASE_URL}/api/stock/0700.HK/quote", timeout=15)
        ok = r.status_code == 200
        check("GET /api/stock/0700.HK/quote", ok, r.text[:200] if not ok else "")
        if ok:
            q = r.json()
            has_ticker = "ticker" in q
            has_price = "price" in q and q["price"] is not None
            has_change = "change_pct" in q
            has_name = "name" in q
            check(f"  Has ticker ({q.get('ticker')})", has_ticker)
            check(f"  Has price ({q.get('price')})", has_price)
            check(f"  Price > 0", q.get("price", 0) > 0)
            check(f"  Has name ({q.get('name')})", has_name)
            check(f"  Has change_pct ({q.get('change_pct')})", has_change)
        results.append(("stock_quote", ok))
    except Exception as e:
        check("GET /api/stock/0700.HK/quote", False, str(e))
        results.append(("stock_quote", False))

    # ── 4. Stock History ─────────────────────────────────────────────────────
    print("\n[4] Stock History - 0700.HK")
    print("-" * 40)
    try:
        r = requests.get(f"{BASE_URL}/api/stock/0700.HK/history?period=1mo", timeout=20)
        ok = r.status_code == 200
        check("GET /api/stock/0700.HK/history", ok, r.text[:100] if not ok else "")
        if ok:
            data = r.json()
            check(f"  Returns list (got {len(data)} records)", isinstance(data, list) and len(data) > 0)
            if data:
                first = data[0]
                has_ohlcv = all(k in first for k in ["date", "open", "high", "low", "close", "volume"])
                check(f"  Has OHLCV fields", has_ohlcv)
                check(f"  Close price > 0 ({first.get('close')})", first.get("close", 0) > 0)
        results.append(("stock_history", ok))
    except Exception as e:
        check("GET /api/stock/0700.HK/history", False, str(e))
        results.append(("stock_history", False))

    # ── 5. Market Movers ─────────────────────────────────────────────────────
    print("\n[5] Market Movers")
    print("-" * 40)
    try:
        r = requests.get(f"{BASE_URL}/api/market/movers", timeout=60)
        ok = r.status_code == 200
        check("GET /api/market/movers", ok, r.text[:100] if not ok else "")
        if ok:
            data = r.json()
            has_gainers = "gainers" in data
            has_losers = "losers" in data
            has_turnover = "turnover" in data
            check("  Has gainers list", has_gainers and isinstance(data.get("gainers"), list))
            check("  Has losers list", has_losers and isinstance(data.get("losers"), list))
            check("  Has turnover list", has_turnover and isinstance(data.get("turnover"), list))
        results.append(("movers", ok))
    except Exception as e:
        check("GET /api/market/movers", False, str(e))
        results.append(("movers", False))

    # ── 6. Watchlist ─────────────────────────────────────────────────────────
    print("\n[6] Watchlist")
    print("-" * 40)
    try:
        r = requests.get(f"{BASE_URL}/api/watchlist", timeout=30)
        ok = r.status_code == 200
        check("GET /api/watchlist", ok, r.text[:100] if not ok else "")
        if ok:
            data = r.json()
            check(f"  Returns list (got {len(data)} items)", isinstance(data, list))
            if data:
                item = data[0]
                has_ticker = "ticker" in item
                has_price = "price" in item
                has_changePct = "changePct" in item
                check(f"  Has ticker ({item.get('ticker')})", has_ticker)
                check(f"  Has price ({item.get('price')})", has_price)
                check(f"  Has changePct ({item.get('changePct')})", has_changePct)
        results.append(("watchlist", ok))
    except Exception as e:
        check("GET /api/watchlist", False, str(e))
        results.append(("watchlist", False))

    # ── 7. Portfolio Summary ──────────────────────────────────────────────────
    print("\n[7] Portfolio Summary")
    print("-" * 40)
    try:
        r = requests.get(f"{BASE_URL}/api/portfolio/summary", timeout=30)
        ok = r.status_code == 200
        check("GET /api/portfolio/summary", ok, r.text[:100] if not ok else "")
        if ok:
            data = r.json()
            has_total_value = "totalValue" in data
            has_total_pl = "totalPL" in data
            has_holdings = "totalHoldings" in data
            check(f"  Has totalValue ({data.get('totalValue')})", has_total_value)
            check(f"  Has totalPL ({data.get('totalPL')})", has_total_pl)
            check(f"  Has totalHoldings ({data.get('totalHoldings')})", has_holdings)
        results.append(("portfolio_summary", ok))
    except Exception as e:
        check("GET /api/portfolio/summary", False, str(e))
        results.append(("portfolio_summary", False))

    # ── 8. Portfolio Positions ────────────────────────────────────────────────
    print("\n[8] Portfolio Positions")
    print("-" * 40)
    try:
        r = requests.get(f"{BASE_URL}/api/portfolio/positions", timeout=30)
        ok = r.status_code == 200
        check("GET /api/portfolio/positions", ok, r.text[:100] if not ok else "")
        if ok:
            data = r.json()
            check(f"  Returns list (got {len(data)} positions)", isinstance(data, list))
            if data:
                pos = data[0]
                fields = ["ticker", "quantity", "avgCost", "currentPrice", "pl", "plPct"]
                all_fields = all(f in pos for f in fields)
                check(f"  Has required fields", all_fields, f"Missing: {[f for f in fields if f not in pos]}")
        results.append(("positions", ok))
    except Exception as e:
        check("GET /api/portfolio/positions", False, str(e))
        results.append(("positions", False))

    # ── 9. Trades ─────────────────────────────────────────────────────────────
    print("\n[9] Trades")
    print("-" * 40)
    try:
        r = requests.get(f"{BASE_URL}/api/trades", timeout=10)
        ok = r.status_code == 200
        check("GET /api/trades", ok, r.text[:100] if not ok else "")
        if ok:
            data = r.json()
            check(f"  Returns list (got {len(data)} trades)", isinstance(data, list))
            if data:
                trade = data[0]
                fields = ["id", "ticker", "type", "quantity", "price", "tradeDate"]
                all_fields = all(f in trade for f in fields)
                check(f"  Has required fields", all_fields, f"Missing: {[f for f in fields if f not in trade]}")
        results.append(("trades", ok))
    except Exception as e:
        check("GET /api/trades", False, str(e))
        results.append(("trades", False))

    # ── 10. Performance ───────────────────────────────────────────────────────
    print("\n[10] Portfolio Performance")
    print("-" * 40)
    try:
        r = requests.get(f"{BASE_URL}/api/portfolio/performance/overview", timeout=30)
        ok = r.status_code == 200
        check("GET /api/portfolio/performance/overview", ok, r.text[:100] if not ok else "")
        results.append(("performance", ok))
    except Exception as e:
        check("GET /api/portfolio/performance/overview", False, str(e))
        results.append(("performance", False))

    # ── Stock Search ──────────────────────────────────────────────────────────
    print("\n[11] Stock Search")
    print("-" * 40)
    try:
        r = requests.get(f"{BASE_URL}/api/stock/search?q=0700", timeout=5)
        ok = r.status_code == 200
        check("GET /api/stock/search?q=0700", ok, r.text[:100] if not ok else "")
        if ok:
            data = r.json()
            check(f"  Returns results (got {len(data)})", len(data) > 0)
        results.append(("search", ok))
    except Exception as e:
        check("GET /api/stock/search", False, str(e))
        results.append(("search", False))

    # ── Summary ───────────────────────────────────────────────────────────────
    print("\n" + "=" * 70)
    passed = sum(1 for _, ok in results if ok)
    total = len(results)
    print(f" SUMMARY: {passed}/{total} endpoints PASSED")
    print("=" * 70)

    failures = [(name, ok) for name, ok in results if not ok]
    if failures:
        print("\nFAILED ENDPOINTS:")
        for name, _ in failures:
            print(f"  - {name}")

    return passed, total

if __name__ == "__main__":
    print(f"Testing API at {BASE_URL}")
    print()
    passed, total = test_all()
    print()
    if passed == total:
        print("All tests passed!")
        sys.exit(0)
    else:
        print(f"{total - passed} test(s) failed!")
        sys.exit(1)
