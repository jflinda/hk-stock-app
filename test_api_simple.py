"""简单的API测试脚本"""
import requests
import sys

def test_api_endpoints():
    """测试API端点"""
    base_url = "http://localhost:8001"
    endpoints = [
        "/ping",
        "/api/market/indices",
        "/api/stock/0700.HK/quote",
        "/api/market/movers",
    ]
    
    print("API端点测试")
    print("=" * 60)
    
    for endpoint in endpoints:
        url = f"{base_url}{endpoint}"
        print(f"\n测试 {endpoint}")
        print("-" * 30)
        
        try:
            response = requests.get(url, timeout=5)
            print(f"状态码: {response.status_code}")
            
            if response.status_code == 200:
                print("✓ 成功")
                try:
                    data = response.json()
                    if endpoint == "/ping":
                        print(f"响应: {data}")
                    elif endpoint == "/api/market/indices":
                        print(f"返回指数数量: {len(data)}")
                        for idx in data[:3]:
                            print(f"  - {idx.get('name')}: {idx.get('price')}")
                    elif endpoint == "/api/stock/0700.HK/quote":
                        print(f"股票: {data.get('name')}")
                        print(f"价格: {data.get('current_price')}")
                except:
                    print(f"响应长度: {len(response.text)} 字符")
            else:
                print(f"✗ 失败")
                print(f"错误: {response.text[:200]}")
                
        except requests.exceptions.Timeout:
            print("✗ 超时")
        except requests.exceptions.ConnectionError:
            print("✗ 连接错误")
        except Exception as e:
            print(f"✗ 异常: {str(e)}")

if __name__ == "__main__":
    print("Starting API server test...")
    try:
        test_api_endpoints()
        print("\n" + "=" * 60)
        print("Test completed")
    except Exception as e:
        print(f"测试过程中发生错误: {e}")
        sys.exit(1)