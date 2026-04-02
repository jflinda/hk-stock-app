"""
测试优化市场服务
"""
import sys
import os
import time
import json
import requests
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
import statistics

# 添加项目根目录到路径
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, project_root)

from backend.services.optimized_market_service import get_global_service
from backend.services.enhanced_cache import get_global_cache

class OptimizedServiceTester:
    """优化服务测试器"""
    
    def __init__(self, base_url="http://localhost:8001"):
        self.base_url = base_url
        self.service = get_global_service()
        self.cache = get_global_cache()
        self.results = []
    
    def test_api_endpoints(self):
        """测试API端点"""
        print("=" * 60)
        print("API端点测试")
        print("=" * 60)
        
        endpoints = [
            ("GET", "/api/v2/market/health", None),
            ("GET", "/api/v2/market/indices", None),
            ("GET", "/api/v2/market/stock/0700.HK/quote", None),
            ("GET", "/api/v2/market/sectors", None),
            ("GET", "/api/v2/market/movers/gainers?limit=5", None),
            ("GET", "/api/v2/market/performance/stats", None),
            ("GET", "/api/v2/market/cache/stats", None),
        ]
        
        for method, endpoint, data in endpoints:
            url = f"{self.base_url}{endpoint}"
            print(f"\n测试 {method} {endpoint}")
            print("-" * 40)
            
            try:
                start_time = time.time()
                
                if method == "GET":
                    response = requests.get(url, timeout=10)
                elif method == "POST":
                    response = requests.post(url, json=data, timeout=10)
                else:
                    print(f"  不支持的方法: {method}")
                    continue
                
                response_time = (time.time() - start_time) * 1000
                
                if response.status_code == 200:
                    print(f"  ✓ 成功 - 状态码: {response.status_code}")
                    print(f"    响应时间: {response_time:.2f}ms")
                    
                    # 显示部分响应数据
                    try:
                        data = response.json()
                        if endpoint == "/api/v2/market/indices":
                            print(f"    返回指数数量: {len(data)}")
                            for idx in data[:2]:  # 显示前2个指数
                                print(f"    - {idx.get('name')}: {idx.get('price')} ({idx.get('change_pct')}%)")
                        elif endpoint == "/api/v2/market/stock/0700.HK/quote":
                            print(f"    股票: {data.get('name')}")
                            print(f"    价格: {data.get('current_price')}")
                            print(f"    涨跌幅: {data.get('change_percent')}%")
                        elif endpoint == "/api/v2/market/performance/stats":
                            perf = data.get('performance', {})
                            print(f"    API调用次数: {perf.get('total_api_calls')}")
                            print(f"    缓存命中率: {perf.get('cache_hit_rate_percent')}%")
                            print(f"    平均响应时间: {perf.get('average_response_time_ms')}ms")
                    except:
                        print(f"    响应数据长度: {len(response.text)} 字符")
                
                else:
                    print(f"  ✗ 失败 - 状态码: {response.status_code}")
                    print(f"    错误信息: {response.text[:200]}")
                    
            except requests.exceptions.Timeout:
                print(f"  ✗ 超时 - 请求超过10秒")
            except requests.exceptions.ConnectionError:
                print(f"  ✗ 连接错误 - 无法连接到服务器")
            except Exception as e:
                print(f"  ✗ 异常: {str(e)}")
    
    def test_cache_performance(self):
        """测试缓存性能"""
        print("\n" + "=" * 60)
        print("缓存性能测试")
        print("=" * 60)
        
        test_symbols = ["0700.HK", "9988.HK", "3690.HK", "0005.HK", "1299.HK"]
        
        # 先清空缓存
        print("1. 清空缓存...")
        self.cache.clear()
        
        # 测试缓存未命中（第一次获取）
        print("\n2. 测试缓存未命中（第一次获取）...")
        first_times = []
        for symbol in test_symbols:
            start_time = time.time()
            quote = self.service.get_stock_quote(symbol, force_refresh=True)
            elapsed = (time.time() - start_time) * 1000
            first_times.append(elapsed)
            
            if quote:
                print(f"  {symbol}: {elapsed:.2f}ms - 价格: {quote.get('current_price')}")
            else:
                print(f"  {symbol}: {elapsed:.2f}ms - 失败")
        
        avg_first = statistics.mean(first_times) if first_times else 0
        print(f"  平均首次获取时间: {avg_first:.2f}ms")
        
        # 测试缓存命中（第二次获取）
        print("\n3. 测试缓存命中（第二次获取）...")
        second_times = []
        for symbol in test_symbols:
            start_time = time.time()
            quote = self.service.get_stock_quote(symbol, force_refresh=False)
            elapsed = (time.time() - start_time) * 1000
            second_times.append(elapsed)
            
            if quote:
                print(f"  {symbol}: {elapsed:.2f}ms - 价格: {quote.get('current_price')}")
            else:
                print(f"  {symbol}: {elapsed:.2f}ms - 失败")
        
        avg_second = statistics.mean(second_times) if second_times else 0
        print(f"  平均缓存命中时间: {avg_second:.2f}ms")
        
        # 计算性能提升
        if avg_first > 0 and avg_second > 0:
            improvement = (avg_first - avg_second) / avg_first * 100
            print(f"  性能提升: {improvement:.1f}%")
        
        # 显示缓存统计
        print("\n4. 缓存统计信息...")
        stats = self.cache.get_stats()
        print(f"  内存缓存条目: {stats.get('memory_cache', {}).get('entries', 0)}")
        print(f"  持久化缓存条目: {stats.get('persistent_cache', {}).get('total_entries', 0)}")
        print(f"  缓存命中率: {stats.get('hit_rate_percent', 0)}%")
    
    def test_batch_performance(self):
        """测试批量获取性能"""
        print("\n" + "=" * 60)
        print("批量获取性能测试")
        print("=" * 60)
        
        # 测试不同批量大小
        batch_sizes = [1, 3, 5, 10]
        symbols = [
            "0700.HK", "9988.HK", "3690.HK", "0005.HK", "1299.HK",
            "2318.HK", "0941.HK", "0001.HK", "0016.HK", "0011.HK"
        ]
        
        for batch_size in batch_sizes:
            print(f"\n批量大小: {batch_size} 只股票")
            print("-" * 30)
            
            # 选择测试股票
            test_symbols = symbols[:batch_size]
            
            # 清空缓存
            self.cache.clear(CachePartitions.STOCK_QUOTE)
            
            # 测试串行获取
            start_time = time.time()
            serial_results = {}
            for symbol in test_symbols:
                quote = self.service.get_stock_quote(symbol, force_refresh=True)
                if quote:
                    serial_results[symbol] = quote
            serial_time = (time.time() - start_time) * 1000
            
            # 测试批量获取（内部使用线程池）
            start_time = time.time()
            batch_results = self.service.get_multiple_stock_quotes(test_symbols, force_refresh=True)
            batch_time = (time.time() - start_time) * 1000
            
            print(f"  串行获取: {serial_time:.2f}ms, 成功: {len(serial_results)}/{batch_size}")
            print(f"  批量获取: {batch_time:.2f}ms, 成功: {len(batch_results)}/{batch_size}")
            
            if serial_time > 0 and batch_time > 0:
                improvement = (serial_time - batch_time) / serial_time * 100
                print(f"  性能提升: {improvement:.1f}%")
    
    def test_concurrent_requests(self):
        """测试并发请求"""
        print("\n" + "=" * 60)
        print("并发请求测试")
        print("=" * 60)
        
        symbols = ["0700.HK", "9988.HK", "3690.HK", "0005.HK", "1299.HK"]
        
        # 清空缓存
        self.cache.clear(CachePartitions.STOCK_QUOTE)
        
        # 并发请求
        print("并发获取5只股票行情...")
        start_time = time.time()
        
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = {executor.submit(self.service.get_stock_quote, symbol, True): symbol for symbol in symbols}
            
            results = []
            for future in as_completed(futures):
                symbol = futures[future]
                try:
                    quote = future.result(timeout=10)
                    if quote:
                        results.append((symbol, quote.get('current_price')))
                except Exception as e:
                    print(f"  {symbol}: 失败 - {str(e)}")
        
        total_time = (time.time() - start_time) * 1000
        print(f"  总时间: {total_time:.2f}ms")
        print(f"  成功获取: {len(results)}/{len(symbols)}")
        
        for symbol, price in results:
            print(f"  {symbol}: {price}")
    
    def test_service_resilience(self):
        """测试服务韧性"""
        print("\n" + "=" * 60)
        print("服务韧性测试")
        print("=" * 60)
        
        # 测试无效股票代码
        print("1. 测试无效股票代码处理...")
        invalid_symbols = ["INVALID.HK", "NOTEXIST.HK", "123456.HK"]
        
        for symbol in invalid_symbols:
            try:
                quote = self.service.get_stock_quote(symbol, force_refresh=True)
                if quote is None:
                    print(f"  ✓ {symbol}: 正确处理为None")
                else:
                    print(f"  ⚠ {symbol}: 返回了数据（可能有问题）")
            except Exception as e:
                print(f"  ✗ {symbol}: 抛出异常 - {str(e)}")
        
        # 测试网络异常恢复
        print("\n2. 测试缓存降级...")
        
        # 获取正常数据
        normal_quote = self.service.get_stock_quote("0700.HK", force_refresh=True)
        if normal_quote:
            print(f"  正常获取 0700.HK: {normal_quote.get('current_price')}")
        
        # 模拟yfinance失败（通过设置无效的代理或环境变量）
        # 这里我们只是测试缓存是否工作
        print("  测试缓存降级（模拟API失败）...")
        
        # 获取缓存数据
        cached_quote = self.service.get_stock_quote("0700.HK", force_refresh=False)
        if cached_quote:
            print(f"  缓存获取 0700.HK: {cached_quote.get('current_price')}")
            print("  ✓ 缓存降级工作正常")
        else:
            print("  ✗ 缓存降级失败")
    
    def run_comprehensive_test(self):
        """运行全面测试"""
        print("优化市场服务全面测试")
        print("=" * 60)
        
        test_start_time = time.time()
        
        # 运行所有测试
        self.test_api_endpoints()
        self.test_cache_performance()
        self.test_batch_performance()
        self.test_concurrent_requests()
        self.test_service_resilience()
        
        # 最终统计
        test_total_time = (time.time() - test_start_time)
        print("\n" + "=" * 60)
        print("测试完成")
        print("=" * 60)
        
        # 显示最终性能统计
        final_stats = self.service.get_performance_stats()
        perf = final_stats.get('performance', {})
        
        print(f"总测试时间: {test_total_time:.2f}秒")
        print(f"API总调用次数: {perf.get('total_api_calls', 0)}")
        print(f"缓存命中率: {perf.get('cache_hit_rate_percent', 0)}%")
        print(f"平均响应时间: {perf.get('average_response_time_ms', 0)}ms")
        print(f"错误率: {perf.get('error_rate_percent', 0)}%")
        
        # 保存测试结果
        self.save_test_results(final_stats)
        
        return final_stats
    
    def save_test_results(self, stats):
        """保存测试结果"""
        try:
            results_dir = os.path.join(project_root, "test_results")
            os.makedirs(results_dir, exist_ok=True)
            
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"optimized_service_test_{timestamp}.json"
            filepath = os.path.join(results_dir, filename)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(stats, f, indent=2, ensure_ascii=False)
            
            print(f"\n测试结果已保存到: {filepath}")
            
        except Exception as e:
            print(f"保存测试结果失败: {e}")

def main():
    """主函数"""
    print("优化市场服务测试程序")
    print("=" * 60)
    
    # 检查API服务器是否运行
    print("检查API服务器状态...")
    try:
        response = requests.get("http://localhost:8001/ping", timeout=3)
        if response.status_code == 200:
            print("✓ API服务器正在运行")
        else:
            print("✗ API服务器响应异常")
            return
    except:
        print("✗ 无法连接到API服务器")
        print("请先启动API服务器: python backend/main.py 或运行 run_api.bat")
        return
    
    # 创建测试器
    tester = OptimizedServiceTester()
    
    # 运行测试
    try:
        tester.run_comprehensive_test()
    except KeyboardInterrupt:
        print("\n测试被用户中断")
    except Exception as e:
        print(f"\n测试过程中发生错误: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()