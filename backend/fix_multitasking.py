"""
修复 yfinance 中的 multitasking 兼容性问题
Python 3.8 需要 typing 支持
"""
import sys
print(f"Python version: {sys.version}")

# 检查 typing 支持
try:
    from typing import Union
    print("typing.Union is available")
except ImportError as e:
    print(f"Import error: {e}")

# 检查 multitasking 模块
try:
    import multitasking
    print("multitasking module can be imported")
    
    # 检查 multitasking 的版本问题
    import inspect
    source = inspect.getsource(multitasking.__init__.PoolConfig)
    print("multitasking.PoolConfig source found")
except Exception as e:
    print(f"multitasking error: {e}")
    
# 可能的解决方案：降级 yfinance 版本
print("\nPossible solutions:")
print("1. Install older version of yfinance: pip install yfinance==0.2.18")
print("2. Upgrade Python to 3.9+")
print("3. Patch the multitasking module")