import time, urllib.request, json

time.sleep(5)
endpoints = [
    ("ping", "http://localhost:8001/ping"),
    ("indices", "http://localhost:8001/api/market/indices"),
    ("portfolio", "http://localhost:8001/api/portfolio/summary"),
    ("watchlist", "http://localhost:8001/api/watchlist"),
    ("trades", "http://localhost:8001/api/trades"),
]
results = []
for name, url in endpoints:
    try:
        resp = urllib.request.urlopen(url, timeout=10)
        data = resp.read().decode()[:100]
        results.append(f"✅ {name}: OK - {data}")
    except Exception as e:
        results.append(f"❌ {name}: FAIL - {e}")

output = "\n".join(results)
print(output)
with open(r"C:\Users\jflin\WorkBuddy\20260329125422\stocktrading\api_test_result.txt", "w") as f:
    f.write(output)
