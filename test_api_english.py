"""Simple API test script in English"""
import requests
import sys

def test_api_endpoints():
    """Test API endpoints"""
    base_url = "http://localhost:8001"
    endpoints = [
        "/ping",
        "/api/market/indices",
        "/api/stock/0700.HK/quote",
        "/api/market/movers",
    ]
    
    print("API Endpoint Testing")
    print("=" * 60)
    
    for endpoint in endpoints:
        url = f"{base_url}{endpoint}"
        print(f"\nTesting {endpoint}")
        print("-" * 30)
        
        try:
            response = requests.get(url, timeout=5)
            print(f"Status Code: {response.status_code}")
            
            if response.status_code == 200:
                print("✓ Success")
                try:
                    data = response.json()
                    if endpoint == "/ping":
                        print(f"Response: {data}")
                    elif endpoint == "/api/market/indices":
                        print(f"Number of indices: {len(data)}")
                        for idx in data[:3]:
                            print(f"  - {idx.get('name')}: {idx.get('price')}")
                    elif endpoint == "/api/stock/0700.HK/quote":
                        print(f"Stock: {data.get('name')}")
                        print(f"Price: {data.get('current_price')}")
                except:
                    print(f"Response length: {len(response.text)} characters")
            else:
                print(f"✗ Failed")
                print(f"Error: {response.text[:200]}")
                
        except requests.exceptions.Timeout:
            print("✗ Timeout")
        except requests.exceptions.ConnectionError:
            print("✗ Connection Error")
        except Exception as e:
            print(f"✗ Exception: {str(e)}")

if __name__ == "__main__":
    print("Starting API server test...")
    try:
        test_api_endpoints()
        print("\n" + "=" * 60)
        print("Test completed")
    except Exception as e:
        print(f"Error during test: {e}")
        sys.exit(1)