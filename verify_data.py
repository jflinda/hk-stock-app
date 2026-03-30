import yfinance as yf
import pandas as pd

print("=== yfinance verification ===")
t = yf.Ticker("0700.HK")
hist = t.history(period="5d")
print(f"Tencent(0700.HK) latest close: HKD {hist['Close'].iloc[-1]:.2f}")
print(f"Rows returned (5d): {len(hist)}")

hsi = yf.Ticker("^HSI")
h = hsi.history(period="5d")
print(f"Hang Seng Index latest close: {h['Close'].iloc[-1]:.0f}")

hsce = yf.Ticker("^HSCE")
h2 = hsce.history(period="3d")
print(f"HSCEI latest close: {h2['Close'].iloc[-1]:.0f}")

print()
print(f"pandas version: {pd.__version__}")
print(">>> yfinance OK")

print()
print("=== FastAPI + uvicorn verification ===")
import fastapi, uvicorn
print(f"FastAPI version: {fastapi.__version__}")
print(f"uvicorn version: {uvicorn.__version__}")
print(">>> FastAPI OK")

print()
print("=== pandas-ta NOT installed (using manual MA calculation) ===")
# pandas-ta has compatibility issues with Python 3.14, use pandas rolling instead
closes = hist["Close"]
ma5  = closes.rolling(5).mean().iloc[-1]
print(f"Tencent MA5 (manual): {ma5:.2f}")
print(">>> Technical indicators OK via pandas rolling")

print()
print("=== ALL CHECKS PASSED ===")
