"""
Add test trade data for Portfolio page
Run this script to populate the database with sample trades
"""
import sqlite3
import os
from datetime import datetime, timedelta

DB_PATH = os.path.join(os.path.dirname(__file__), "database", "hkstock.db")

def add_test_trades():
    """Add sample BUY/SELL trades for testing Portfolio page"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # First, clear existing test data (optional, comment out if you want to keep data)
    cursor.execute("DELETE FROM trades WHERE id < 100")
    
    # Test trades data for Linda Wong's portfolio
    test_trades = [
        # 0700.HK Tencent - 腾讯控股
        ('0700', 'Tencent Holdings', 'BUY', 200, 245.80, 50.0, '2026-03-01', 'Initial position'),
        ('0700', 'Tencent Holdings', 'BUY', 100, 242.50, 25.0, '2026-03-15', 'Add more on dip'),
        ('0700', 'Tencent Holdings', 'SELL', 50, 255.30, 25.0, '2026-03-25', 'Partial profit taking'),
        
        # 9988.HK Alibaba - 阿里巴巴
        ('9988', 'Alibaba Group', 'BUY', 300, 123.45, 50.0, '2026-02-10', 'Initial position'),
        ('9988', 'Alibaba Group', 'BUY', 200, 118.20, 30.0, '2026-03-05', 'Average down'),
        
        # 3690.HK Meituan - 美团
        ('3690', 'Meituan', 'BUY', 150, 456.78, 100.0, '2026-03-10', 'Tech portfolio'),
        
        # 0005.HK HSBC - 汇丰控股
        ('0005', 'HSBC Holdings', 'BUY', 400, 234.56, 100.0, '2026-01-15', 'Dividend stock'),
        ('0005', 'HSBC Holdings', 'BUY', 200, 238.90, 50.0, '2026-02-20', 'Add more'),
        
        # 2020.HK Anta - 安踏体育
        ('2020', 'Anta Sports', 'BUY', 500, 12.34, 30.0, '2026-03-12', 'Consumer stock'),
        
        # 1810.HK Xiaomi - 小米集团
        ('1810', 'Xiaomi Corporation', 'BUY', 800, 89.23, 80.0, '2026-03-18', 'Smartphone exposure'),
        
        # 2382.HK Ping An - 中国平安
        ('2382', 'Ping An Insurance', 'BUY', 300, 45.67, 50.0, '2026-02-28', 'Insurance sector'),
        
        # 0388.HK HKEX - 香港交易所
        ('0388', 'Hong Kong Exchanges', 'BUY', 100, 345.67, 100.0, '2026-01-20', 'Exchange stock'),
    ]
    
    insert_sql = """
    INSERT INTO trades (ticker, name, direction, qty, price, fee, trade_date, notes)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    """
    
    for trade in test_trades:
        cursor.execute(insert_sql, trade)
    
    # Add some watchlist items
    test_watchlist = [
        ('0700', 'Tencent Holdings', 260.00, 'above', 'Tech leader'),
        ('9988', 'Alibaba Group', 130.00, 'above', 'E-commerce giant'),
        ('3690', 'Meituan', 480.00, 'above', 'Food delivery'),
        ('0005', 'HSBC Holdings', 250.00, 'above', 'Banking stock'),
        ('2020', 'Anta Sports', 15.00, 'above', 'Sportswear'),
        ('1810', 'Xiaomi Corporation', 95.00, 'above', 'Smartphones'),
        ('2382', 'Ping An Insurance', 50.00, 'above', 'Insurance'),
        ('0388', 'Hong Kong Exchanges', 360.00, 'above', 'HKEX'),
        ('0011', 'Hang Seng Bank', 120.00, 'above', 'Local bank'),
        ('1928', 'Sands China', 25.00, 'above', 'Gaming'),
    ]
    
    insert_watchlist_sql = """
    INSERT OR IGNORE INTO watchlist (ticker, name, alert_price, alert_type, notes)
    VALUES (?, ?, ?, ?, ?)
    """
    
    for item in test_watchlist:
        cursor.execute(insert_watchlist_sql, item)
    
    conn.commit()
    conn.close()
    
    print(f"Added {len(test_trades)} test trades to database")
    print(f"Added {len(test_watchlist)} watchlist items")
    print(f"\nPortfolio now contains:")
    print("  - Tencent (0700): 250 shares")
    print("  - Alibaba (9988): 500 shares")
    print("  - Meituan (3690): 150 shares")
    print("  - HSBC (0005): 600 shares")
    print("  - Anta (2020): 500 shares")
    print("  - Xiaomi (1810): 800 shares")
    print("  - Ping An (2382): 300 shares")
    print("  - HKEX (0388): 100 shares")
    print("\nNow Portfolio page will show real data!")

def check_database():
    """Check if database exists and has data"""
    if not os.path.exists(DB_PATH):
        print("Database not found. Please run init_db.py first")
        return False
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Check tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = cursor.fetchall()
    print("Database tables:")
    for table in tables:
        print(f"  - {table[0]}")
    
    # Check trade count
    cursor.execute("SELECT COUNT(*) FROM trades")
    trade_count = cursor.fetchone()[0]
    print(f"\nCurrent trade count: {trade_count}")
    
    # Check watchlist count
    cursor.execute("SELECT COUNT(*) FROM watchlist")
    watchlist_count = cursor.fetchone()[0]
    print(f"Current watchlist count: {watchlist_count}")
    
    conn.close()
    return True

if __name__ == "__main__":
    print("Adding test data to HK Stock App database...")
    
    if check_database():
        add_test_trades()
        print("\nTest data added successfully!")
        print("\nNext steps:")
        print("1. Make sure backend API is running (python -m uvicorn main:app --reload)")
        print("2. Run Flutter app with 'flutter run'")
        print("3. Portfolio page will show real trades and positions")
        print("4. Add trades via the 'Add Trade' modal to see real-time updates")
    else:
        print("Please initialize database first by running init_db.py")