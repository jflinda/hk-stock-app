"""
测试 API 连接而不使用 PowerShell 的 Invoke-WebRequest
"""
import socket
import time
import sys
import subprocess
import os

def test_tcp_connection(host='127.0.0.1', port=8000):
    """测试 TCP 连接"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except Exception as e:
        print(f"TCP 连接测试失败: {e}")
        return False

def test_http_ping():
    """使用简单的 HTTP 客户端测试 ping 端点"""
    import urllib.request
    import urllib.error
    
    try:
        req = urllib.request.Request("http://127.0.0.1:8000/ping", method='GET')
        response = urllib.request.urlopen(req, timeout=3)
        if response.status == 200:
            data = response.read()
            print(f"✅ API ping 成功: {data.decode()}")
            return True
        else:
            print(f"❌ API 返回状态码: {response.status}")
            return False
    except urllib.error.URLError as e:
        print(f"❌ URL 错误: {e}")
        return False
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        return False

def main():
    print("=== 测试 API 连接 ===")
    
    # 1. 检查端口
    print("1. 检查端口 8000...")
    if test_tcp_connection():
        print("   ✅ 端口 8000 正在监听")
    else:
        print("   ❌ 端口 8000 未响应")
        return False
    
    # 2. 测试 HTTP ping
    print("\n2. 测试 /ping 端点...")
    if test_http_ping():
        print("   ✅ API 连接正常")
        return True
    else:
        print("   ❌ API 连接失败")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)