"""
Test API connection without using PowerShell Invoke-WebRequest
"""
import socket
import sys
import urllib.request
import urllib.error

def test_tcp_connection(host='127.0.0.1', port=8000):
    """Test TCP connection"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except Exception as e:
        print(f"TCP connection test failed: {e}")
        return False

def test_http_ping():
    """Test ping endpoint using simple HTTP client"""
    try:
        req = urllib.request.Request("http://127.0.0.1:8000/ping", method='GET')
        response = urllib.request.urlopen(req, timeout=3)
        if response.status == 200:
            data = response.read()
            print(f"API ping successful: {data.decode()}")
            return True
        else:
            print(f"API returned status code: {response.status}")
            return False
    except urllib.error.URLError as e:
        print(f"URL error: {e}")
        return False
    except Exception as e:
        print(f"Test failed: {e}")
        return False

def main():
    print("=== Testing API Connection ===")
    
    # 1. Check port
    print("1. Checking port 8000...")
    if test_tcp_connection():
        print("   Port 8000 is listening")
    else:
        print("   Port 8000 is not responding")
        return False
    
    # 2. Test HTTP ping
    print("\n2. Testing /ping endpoint...")
    if test_http_ping():
        print("   API connection is working")
        return True
    else:
        print("   API connection failed")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)