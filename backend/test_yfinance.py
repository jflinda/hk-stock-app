#!/usr/bin/env python3
"""Test yfinance connectivity and data fetching"""
import yfinance as yf
import pandas as pd
import json
from datetime import datetime

print("Testing yfinance data fetching...")
print("=" * 60)

# Test 1: Basic ticker info
print("Test 1: Basic ticker info")
try:
    ticker = yf.Ticker("^HSI")
    info = ticker.info
    print(f"^HSI info keys: {list(info.keys())[:10]}")
    print(f"^HSI currentPrice: {info.get('currentPrice', 'N/A')}")
    print(f"^HSI regularMarketPrice: {info.get('regularMarketPrice', 'N/A')}")
except Exception as e:
    print(f"Error: {e}")

print("\nTest 2: History data (5 days)")
try:
    ticker = yf.Ticker("^HSI")
    hist = ticker.history(period="5d")
    print(f"History shape: {hist.shape}")
    print(f"Columns: {list(hist.columns)}")
    if not hist.empty:
        print(f"Last 5 rows:\n{hist.tail()}")
    else:
        print("History is empty!")
except Exception as e:
    print(f"Error: {e}")

print("\nTest 3: Multiple indices")
tickers = ["^HSI", "^HSCE", "000001.SS"]
for symbol in tickers:
    try:
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period="1d")
        if hist.empty:
            print(f"{symbol}: No data (empty)")
        else:
            price = hist["Close"].iloc[-1] if "Close" in hist.columns else 0
            print(f"{symbol}: Price = {price}")
    except Exception as e:
        print(f"{symbol}: Error - {e}")

print("\nTest 4: 0700.HK (Tencent)")
try:
    ticker = yf.Ticker("0700.HK")
    info = ticker.info
    hist = ticker.history(period="1d")
    print(f"0700.HK currentPrice: {info.get('currentPrice', 'N/A')}")
    print(f"0700.HK history price: {hist['Close'].iloc[-1] if not hist.empty else 'N/A'}")
except Exception as e:
    print(f"Error: {e}")

print("\n" + "=" * 60)
print("Diagnosis complete.")