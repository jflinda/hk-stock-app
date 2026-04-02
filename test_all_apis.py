#!/usr/bin/env python3
"""Test all API endpoints to ensure they work properly"""
import requests
import json
import sys

BASE_URL = "http://localhost:8000"

def test_endpoint(url, name, expected_status=200):
    """Test a single API endpoint"""
    try:
        response = requests.get(url, timeout=10)
        status = response.status_code
        success = status == expected_status
        
        print(f"{name}:")
        print(f"  URL: {url}")
        print(f"  Status: {status} {'PASS' if success else 'FAIL'}")
        
        if success:
            try:
                data = response.json()
                if name == "Ping":
                    print(f"  Response: {data}")
                elif name == "Market Indices":
                    print(f"  Items: {len(data)}")
                    for i, item in enumerate(data[:3]):  # Show first 3
                        print(f"    {i+1}. {item.get('name')}: ${item.get('price')} ({item.get('change_pct')}%)")
                elif name == "Stock Quote":
                    print(f"  Price: ${data.get('price')}, Change: {data.get('changePct')}%")
                elif name == "Market Movers":
                    gainers = len(data.get('gainers', []))
                    losers = len(data.get('losers', []))
                    print(f"  Gainers: {gainers}, Losers: {losers}")
            except:
                print(f"  Response: {response.text[:100]}...")
        else:
            print(f"  Error: {response.text[:200]}")
        
        print()
        return success
        
    except requests.exceptions.ConnectionError:
        print(f"{name}:")
        print(f"  URL: {url}")
        print(f"  Status: Connection failed - API may not be running")
        print()
        return False
    except Exception as e:
        print(f"{name}:")
        print(f"  URL: {url}")
        print(f"  Status: Error - {e}")
        print()
        return False

def main():
    print("Testing HK Stock App API Endpoints")
    print("=" * 60)
    
    # List of endpoints to test
    endpoints = [
        (f"{BASE_URL}/ping", "Ping"),
        (f"{BASE_URL}/api/market/indices", "Market Indices"),
        (f"{BASE_URL}/api/stock/0700.HK/quote", "Stock Quote (0700.HK)"),
        (f"{BASE_URL}/api/market/movers", "Market Movers"),
        (f"{BASE_URL}/api/watchlist", "Watchlist"),
        (f"{BASE_URL}/api/portfolio/summary", "Portfolio Summary"),
    ]
    
    results = []
    for url, name in endpoints:
        success = test_endpoint(url, name)
        results.append((name, success))
    
    print("=" * 60)
    print("Summary:")
    
    total = len(results)
    passed = sum(1 for _, success in results if success)
    
    for name, success in results:
        status = "PASS" if success else "FAIL"
        print(f"  {name}: {status}")
    
    print(f"\nTotal: {passed}/{total} passed")
    
    # Test mobile connectivity
    print("\nTesting mobile connectivity (192.168.3.30)...")
    try:
        mobile_response = requests.get("http://192.168.3.30:8000/ping", timeout=5)
        if mobile_response.status_code == 200:
            print("  [OK] Mobile can access API at 192.168.3.30:8000")
        else:
            print(f"  [ERROR] Mobile API error: {mobile_response.status_code}")
    except:
        print("  [ERROR] Mobile cannot access API - check firewall and network")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)