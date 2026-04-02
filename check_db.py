import sqlite3
import os
from datetime import date, timedelta
import random

DB_PATH = r'C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\backend\database\hkstock.db'

conn = sqlite3.connect(DB_PATH)
conn.row_factory = sqlite3.Row
cur = conn.cursor()

# Check current state
print("=== Current DB State ===")
print("Trades:", cur.execute("SELECT COUNT(*) FROM trades").fetchone()[0])
print("Watchlist:", cur.execute("SELECT COUNT(*) FROM watchlist").fetchone()[0])

# Print watchlist schema
ws = cur.execute("PRAGMA table_info(watchlist)").fetchall()
print("\nWatchlist schema:")
for col in ws:
    print(f"  {col[1]} {col[2]}")

# Print first watchlist item
rows = cur.execute("SELECT * FROM watchlist LIMIT 3").fetchall()
print("\nSample watchlist rows:")
for r in rows:
    print(" ", dict(r))

# Check table schemas
tables = cur.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
print("\nTables:", [t[0] for t in tables])

# Print trades schema
schema = cur.execute("PRAGMA table_info(trades)").fetchall()
print("\nTrades schema:")
for col in schema:
    print(f"  {col[1]} {col[2]}")

conn.close()
print("\nDone.")
