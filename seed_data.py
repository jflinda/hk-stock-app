"""
Seed test data: 12 trades + 10 watchlist items for HK Stock App
Trade schema: id, ticker, name, direction, qty, price, fee, trade_date, notes, created_at
"""
import sqlite3
import sys

DB_PATH = r'C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\backend\database\hkstock.db'

TRADES = [
    # Tencent (0700.HK) - long position
    ("0700.HK", "Tencent Holdings", "BUY",  400, 380.0,  99.0, "2025-10-15", "Long Tencent"),
    ("0700.HK", "Tencent Holdings", "BUY",  200, 360.0,  50.0, "2025-11-20", "Add to position"),
    ("0700.HK", "Tencent Holdings", "SELL", 200, 420.0,  60.0, "2026-01-10", "Partial profit"),

    # Meituan (3690.HK)
    ("3690.HK", "Meituan",          "BUY",  500, 150.0,  80.0, "2025-11-05", "Meituan entry"),
    ("3690.HK", "Meituan",          "SELL", 500, 175.0,  85.0, "2026-01-25", "Full exit"),

    # HSBC (0005.HK)
    ("0005.HK", "HSBC Holdings",    "BUY", 1000,  60.0,  70.0, "2025-12-01", "HSBC dividend play"),

    # AIA (1299.HK)
    ("1299.HK", "AIA Group",        "BUY",  300,  72.0,  55.0, "2025-12-10", "Insurance sector"),
    ("1299.HK", "AIA Group",        "SELL", 300,  69.0,  52.0, "2026-02-14", "Cut loss"),

    # Alibaba (9988.HK)
    ("9988.HK", "Alibaba Group",    "BUY",  200,  82.0,  40.0, "2026-01-03", "Rebound play"),
    ("9988.HK", "Alibaba Group",    "BUY",  100,  78.0,  25.0, "2026-01-20", "Average down"),

    # BYD (1211.HK)
    ("1211.HK", "BYD Company",      "BUY",  100, 290.0,  36.0, "2026-02-10", "EV sector"),
    ("1211.HK", "BYD Company",      "SELL", 100, 315.0,  38.0, "2026-03-15", "Target hit"),
]

WATCHLIST_EXTRA = [
    ("2318.HK", "Ping An Insurance", 50.0, -0.8),
    ("0388.HK", "HKEX",             320.0,  0.5),
    ("0941.HK", "China Mobile",      70.0,  0.3),
    ("2020.HK", "ANTA Sports",      100.0, -1.2),
    ("9618.HK", "JD.com",            145.0,  1.8),
    ("0175.HK", "Geely Automobile",   9.5, -0.4),
    ("2382.HK", "Sunny Optical",    100.0,  2.1),
]

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

# Clear existing data
cur.execute("DELETE FROM trades")
print("Cleared trades table")

# Insert trades
for ticker, name, direction, qty, price, fee, trade_date, notes in TRADES:
    cur.execute(
        "INSERT INTO trades (ticker, name, direction, qty, price, fee, trade_date, notes, created_at) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))",
        (ticker, name, direction, qty, price, fee, trade_date, notes)
    )
conn.commit()
print(f"Inserted {len(TRADES)} trades - committed")

# Watchlist - add extra items if not already present
# Schema: id, ticker, name, alert_price, notes, added_at, alert_type
cur.execute("SELECT ticker FROM watchlist")
existing = {row[0] for row in cur.fetchall()}
WATCHLIST_EXTRA_FIXED = [
    ("2318", "Ping An Insurance",  50.0, "Insurance sector",   "above"),
    ("0388", "HKEX",              320.0, "Exchange operator",  "above"),
    ("0941", "China Mobile",       70.0, "Telecom dividend",   "above"),
    ("2020", "ANTA Sports",       100.0, "Sportswear brand",   "above"),
    ("9618", "JD.com",            145.0, "E-commerce",         "above"),
    ("0175", "Geely Automobile",    9.5, "EV exposure",        "above"),
    ("0700", "Tencent Holdings",  480.0, "Tech bellwether",    "above"),
]
added = 0
for ticker, name, alert_price, notes, alert_type in WATCHLIST_EXTRA_FIXED:
    if ticker not in existing:
        cur.execute(
            "INSERT INTO watchlist (ticker, name, alert_price, notes, added_at, alert_type) "
            "VALUES (?, ?, ?, ?, datetime('now'), ?)",
            (ticker, name, alert_price, notes, alert_type)
        )
        added += 1
conn.commit()
print(f"Added {added} new watchlist items (skipped {len(WATCHLIST_EXTRA_FIXED)-added} duplicates)")
print(f"Total watchlist items: {cur.execute('SELECT COUNT(*) FROM watchlist').fetchone()[0]}")

conn.close()

# Verify via API
import requests
BASE = "http://localhost:8001"
r = requests.get(BASE + "/api/trades", timeout=5)
if r.status_code == 200:
    print(f"\nAPI /api/trades returns {len(r.json())} trades - OK")
else:
    print(f"\nAPI /api/trades FAILED: {r.status_code}")

r2 = requests.get(BASE + "/api/portfolio/summary", timeout=15)
if r2.status_code == 200:
    s = r2.json()
    print(f"API /api/portfolio/summary: totalValue={s.get('totalValue')}, totalPL={s.get('totalPL')}, holdings={s.get('totalHoldings')}")
else:
    print(f"API /api/portfolio/summary FAILED: {r2.status_code}")

r3 = requests.get(BASE + "/api/portfolio/performance", timeout=15)
if r3.status_code == 200:
    ov = r3.json().get("overview", {})
    print(f"API /api/portfolio/performance overview: realizedPL={ov.get('totalRealizedPL')}, winRate={ov.get('winRate')}%")
else:
    print(f"API /api/portfolio/performance FAILED: {r3.status_code}")

print("\nSeed complete.")
