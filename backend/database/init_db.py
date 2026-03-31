"""Database initialization — run once to create SQLite tables"""
import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), "hkstock.db")

SCHEMA = """
CREATE TABLE IF NOT EXISTS trades (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    ticker      TEXT NOT NULL,
    name        TEXT,
    direction   TEXT NOT NULL CHECK(direction IN ('BUY','SELL')),
    qty         INTEGER NOT NULL,
    price       REAL NOT NULL,
    fee         REAL DEFAULT 0,
    trade_date  DATE NOT NULL,
    notes       TEXT,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS watchlist (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    ticker      TEXT NOT NULL UNIQUE,
    name        TEXT,
    alert_price REAL,
    alert_type  TEXT,
    notes       TEXT,
    added_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS price_cache (
    ticker      TEXT NOT NULL,
    date        DATE NOT NULL,
    open        REAL,
    high        REAL,
    low         REAL,
    close       REAL,
    volume      INTEGER,
    PRIMARY KEY (ticker, date)
);

CREATE TABLE IF NOT EXISTS stock_info_cache (
    ticker      TEXT PRIMARY KEY,
    name        TEXT,
    sector      TEXT,
    pe_ratio    REAL,
    market_cap  REAL,
    dividend    REAL,
    updated_at  DATETIME
);
"""

def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.executescript(SCHEMA)
    conn.commit()
    conn.close()
    print(f"Database initialized at: {DB_PATH}")

if __name__ == "__main__":
    init_db()
