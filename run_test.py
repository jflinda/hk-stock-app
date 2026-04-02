import sys
import requests

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

BASE = "http://localhost:8001"
PASS = 0
FAIL = 0

def ok(label, cond, note=""):
    global PASS, FAIL
    if cond:
        PASS += 1
        print("[PASS]", label)
    else:
        FAIL += 1
        print("[FAIL]", label, ("-> " + note) if note else "")

def get(path, timeout=10):
    try:
        r = requests.get(BASE + path, timeout=timeout)
        return r.status_code, r
    except Exception as e:
        return None, str(e)

print("=" * 60)
print("API TEST RUNNER  base=" + BASE)
print("=" * 60)

# 1. Ping
print("\n--- 1. Ping ---")
code, r = get("/ping", 5)
ok("GET /ping status 200", code == 200, str(r) if code is None else "")

# 2. Market Indices
print("\n--- 2. Market Indices ---")
code, r = get("/api/market/indices", 20)
ok("GET /api/market/indices", code == 200, str(r) if code is None else "")
if code == 200:
    data = r.json()
    ok("  returns list", isinstance(data, list))
    if data:
        idx = data[0]
        ok("  has name+price+change_pct", all(k in idx for k in ["name","price","change_pct"]))
        ok("  price > 0 (" + str(idx.get("price")) + ")", (idx.get("price") or 0) > 0)

# 3. Stock Quote
print("\n--- 3. Stock Quote 0700.HK ---")
code, r = get("/api/stock/0700.HK/quote", 20)
ok("GET /api/stock/0700.HK/quote", code == 200, str(r) if code is None else "")
if code == 200:
    q = r.json()
    ok("  has price (" + str(q.get("price")) + ")", q.get("price") is not None and q.get("price", 0) > 0)
    ok("  has name (" + str(q.get("name")) + ")", bool(q.get("name")))
    ok("  has change_pct", "change_pct" in q)

# 4. Stock History
print("\n--- 4. Stock History 0700.HK ---")
code, r = get("/api/stock/0700.HK/history?period=1mo", 25)
ok("GET /api/stock/0700.HK/history", code == 200, str(r) if code is None else "")
if code == 200:
    data = r.json()
    ok("  returns non-empty list (" + str(len(data)) + " records)", len(data) > 0)
    if data:
        ok("  has OHLCV fields", all(k in data[0] for k in ["date","open","high","low","close","volume"]))

# 5. Watchlist
print("\n--- 5. Watchlist ---")
code, r = get("/api/watchlist", 30)
ok("GET /api/watchlist", code == 200, str(r) if code is None else "")
if code == 200:
    data = r.json()
    ok("  returns list (" + str(len(data)) + " items)", isinstance(data, list))
    if data:
        item = data[0]
        ok("  has ticker+price+changePct", all(k in item for k in ["ticker","price","changePct"]))

# 6. Portfolio Summary
print("\n--- 6. Portfolio Summary ---")
code, r = get("/api/portfolio/summary", 30)
ok("GET /api/portfolio/summary", code == 200, str(r) if code is None else "")
if code == 200:
    data = r.json()
    ok("  has totalValue+totalPL+totalHoldings", all(k in data for k in ["totalValue","totalPL","totalHoldings"]))
    ok("  totalValue (" + str(data.get("totalValue")) + ")", data.get("totalValue") is not None)

# 7. Portfolio Positions
print("\n--- 7. Portfolio Positions ---")
code, r = get("/api/portfolio/positions", 30)
ok("GET /api/portfolio/positions", code == 200, str(r) if code is None else "")
if code == 200:
    data = r.json()
    ok("  returns list (" + str(len(data)) + " items)", isinstance(data, list))
    if data:
        pos = data[0]
        fields = ["ticker","quantity","avgCost","currentPrice","pl","plPct"]
        missing = [f for f in fields if f not in pos]
        ok("  has required fields", len(missing) == 0, "Missing: " + str(missing))

# 8. Trades
print("\n--- 8. Trades ---")
code, r = get("/api/trades", 10)
ok("GET /api/trades", code == 200, str(r) if code is None else "")
if code == 200:
    data = r.json()
    ok("  returns list (" + str(len(data)) + " trades)", isinstance(data, list))
    if data:
        t = data[0]
        fields = ["id","ticker","type","quantity","price","tradeDate"]
        missing = [f for f in fields if f not in t]
        ok("  has required fields", len(missing) == 0, "Missing: " + str(missing))

# 9. Performance Overview
print("\n--- 9. Performance Overview ---")
code, r = get("/api/portfolio/performance/overview", 30)
ok("GET /api/portfolio/performance/overview", code == 200, str(r) if code is None else "")

# 10. Stock Search
print("\n--- 10. Stock Search ---")
code, r = get("/api/stock/search?q=0700", 10)
ok("GET /api/stock/search?q=0700", code == 200, str(r) if code is None else "")
if code == 200:
    data = r.json()
    ok("  returns results (" + str(len(data)) + ")", len(data) > 0)

# 11. Market Movers (skip if too slow, use short timeout)
print("\n--- 11. Market Movers (30s timeout) ---")
code, r = get("/api/market/movers", 30)
ok("GET /api/market/movers", code == 200, str(r) if code is None else "")
if code == 200:
    data = r.json()
    ok("  has gainers+losers+turnover", all(k in data for k in ["gainers","losers","turnover"]))

print("\n" + "=" * 60)
print("RESULT: " + str(PASS) + " passed, " + str(FAIL) + " failed out of " + str(PASS+FAIL) + " checks")
print("=" * 60)
sys.exit(0 if FAIL == 0 else 1)
