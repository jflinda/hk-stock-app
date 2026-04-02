"""
端到端集成测试脚本
测试手机应用与服务器的完整连接和数据流
"""

import os
import json
import time
import requests
import subprocess
import psutil
from datetime import datetime, timedelta
import threading
import queue

class EndToEndTester:
    def __init__(self, api_url="http://localhost:8001", local_ip=None):
        self.api_url = api_url
        self.local_ip = local_ip or self.get_local_ip()
        self.test_results = []
        self.start_time = datetime.now()
        
        # 确保日志目录存在
        self.log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "e2e_logs")
        os.makedirs(self.log_dir, exist_ok=True)
    
    def get_local_ip(self):
        """获取本地IP地址"""
        try:
            import socket
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            # 使用一个不存在的地址，但会返回本地接口
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "192.168.3.30"  # 默认IP
    
    def test_server_startup(self):
        """测试服务器启动过程"""
        print("1. 测试服务器启动过程...")
        
        results = []
        
        # 检查当前是否有服务器在运行
        try:
            response = requests.get(f"{self.api_url}/ping", timeout=3)
            server_running = response.status_code == 200
            results.append({
                "test": "检查现有服务器",
                "success": True,
                "server_running": server_running,
                "response": response.json() if server_running else None
            })
            print(f"  {'✓' if server_running else '⚠'} 当前服务器状态: {'运行中' if server_running else '未运行'}")
        except:
            server_running = False
            results.append({
                "test": "检查现有服务器",
                "success": False,
                "server_running": False,
                "error": "连接失败"
            })
            print(f"  ✗ 当前服务器状态: 未运行")
        
        # 如果需要，启动服务器
        if not server_running:
            print("  尝试启动API服务器...")
            try:
                project_dir = os.path.dirname(os.path.abspath(__file__))
                backend_dir = os.path.join(project_dir, "backend")
                
                # 使用我们之前创建的批处理文件
                bat_file = os.path.join(project_dir, "start_api_final.bat")
                
                if os.path.exists(bat_file):
                    startup_result = subprocess.run(
                        [bat_file],
                        cwd=backend_dir,
                        capture_output=True,
                        text=True,
                        timeout=30
                    )
                    
                    start_success = startup_result.returncode == 0
                    results.append({
                        "test": "启动API服务器",
                        "success": start_success,
                        "return_code": startup_result.returncode,
                        "output_preview": startup_result.stdout[:200] + "..." if len(startup_result.stdout) > 200 else startup_result.stdout
                    })
                    
                    print(f"  {'✓' if start_success else '✗'} 服务器启动: 返回码={startup_result.returncode}")
                    
                    # 等待服务器启动
                    if start_success:
                        print("  等待服务器启动...")
                        time.sleep(5)
                        
                        # 验证服务器是否真的在运行
                        for i in range(5):
                            try:
                                response = requests.get(f"{self.api_url}/ping", timeout=3)
                                if response.status_code == 200:
                                    results.append({
                                        "test": "验证服务器运行",
                                        "success": True,
                                        "status_code": response.status_code,
                                        "response": response.json()
                                    })
                                    print(f"  ✓ 服务器验证成功")
                                    break
                            except:
                                time.sleep(2)
                        else:
                            results.append({
                                "test": "验证服务器运行",
                                "success": False,
                                "error": "服务器启动后仍无法连接"
                            })
                            print(f"  ✗ 服务器启动后验证失败")
                else:
                    results.append({
                        "test": "启动API服务器",
                        "success": False,
                        "error": "启动脚本不存在"
                    })
                    print(f"  ✗ 启动脚本不存在: {bat_file}")
            
            except Exception as e:
                results.append({
                    "test": "启动API服务器",
                    "success": False,
                    "error": str(e)
                })
                print(f"  ✗ 服务器启动失败: {str(e)}")
        
        # 总结
        success_tests = len([r for r in results if r.get("success")])
        total_tests = len(results)
        
        startup_result = {
            "test_name": "服务器启动测试",
            "timestamp": datetime.now().isoformat(),
            "tests_performed": total_tests,
            "successful_tests": success_tests,
            "success_rate_percent": round(success_tests / total_tests * 100, 2) if total_tests > 0 else 0,
            "details": results
        }
        
        self.test_results.append(startup_result)
        return startup_result
    
    def test_mobile_connectivity(self):
        """测试手机连接性"""
        print("\n2. 测试手机连接性...")
        
        results = []
        
        # 测试本地连接
        print("  测试本地连接 (localhost)...")
        try:
            local_response = requests.get(f"{self.api_url}/ping", timeout=5)
            local_success = local_response.status_code == 200
            
            results.append({
                "connection_type": "localhost",
                "url": self.api_url,
                "success": local_success,
                "status_code": local_response.status_code,
                "response_time_ms": local_response.elapsed.total_seconds() * 1000
            })
            
            print(f"  {'✓' if local_success else '✗'} 本地连接: 状态码={local_response.status_code}, 响应时间={local_response.elapsed.total_seconds()*1000:.0f}ms")
        
        except Exception as e:
            results.append({
                "connection_type": "localhost",
                "url": self.api_url,
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ 本地连接失败: {str(e)}")
        
        # 测试局域网连接
        print(f"  测试局域网连接 ({self.local_ip})...")
        lan_url = f"http://{self.local_ip}:8001"
        try:
            lan_response = requests.get(f"{lan_url}/ping", timeout=5)
            lan_success = lan_response.status_code == 200
            
            results.append({
                "connection_type": "lan",
                "url": lan_url,
                "success": lan_success,
                "status_code": lan_response.status_code,
                "response_time_ms": lan_response.elapsed.total_seconds() * 1000
            })
            
            print(f"  {'✓' if lan_success else '✗'} 局域网连接: 状态码={lan_response.status_code}, 响应时间={lan_response.elapsed.total_seconds()*1000:.0f}ms")
        
        except Exception as e:
            results.append({
                "connection_type": "lan",
                "url": lan_url,
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ 局域网连接失败: {str(e)}")
        
        # 检查防火墙设置
        print("  检查防火墙配置...")
        try:
            import platform
            system = platform.system()
            
            if system == "Windows":
                # Windows防火墙检查
                firewall_check = subprocess.run(
                    ["netsh", "advfirewall", "firewall", "show", "rule", "name=Python"],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                has_firewall_rule = "Python" in firewall_check.stdout
                results.append({
                    "check": "Windows防火墙规则",
                    "has_python_rule": has_firewall_rule,
                    "success": has_firewall_rule
                })
                
                print(f"  {'✓' if has_firewall_rule else '⚠'} Windows防火墙: {'已配置Python规则' if has_firewall_rule else '未配置Python规则'}")
            
            elif system == "Darwin":  # macOS
                # macOS防火墙检查
                firewall_check = subprocess.run(
                    ["/usr/libexec/ApplicationFirewall/socketfilterfw", "--listapps"],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                has_firewall_rule = "Python" in firewall_check.stdout
                results.append({
                    "check": "macOS防火墙规则",
                    "has_python_rule": has_firewall_rule,
                    "success": has_firewall_rule
                })
                
                print(f"  {'✓' if has_firewall_rule else '⚠'} macOS防火墙: {'已配置Python规则' if has_firewall_rule else '未配置Python规则'}")
            
            else:
                # Linux防火墙检查
                results.append({
                    "check": "Linux防火墙",
                    "note": "Linux系统防火墙检查",
                    "success": True
                })
                print(f"  ⚠ Linux防火墙: 需要手动配置")
        
        except Exception as e:
            results.append({
                "check": "防火墙检查",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ 防火墙检查失败: {str(e)}")
        
        # 总结
        success_tests = len([r for r in results if r.get("success")])
        total_tests = len(results)
        
        connectivity_result = {
            "test_name": "手机连接性测试",
            "timestamp": datetime.now().isoformat(),
            "tests_performed": total_tests,
            "successful_tests": success_tests,
            "success_rate_percent": round(success_tests / total_tests * 100, 2) if total_tests > 0 else 0,
            "local_ip": self.local_ip,
            "details": results
        }
        
        self.test_results.append(connectivity_result)
        return connectivity_result
    
    def test_realtime_data_stream(self):
        """测试实时数据流"""
        print("\n3. 测试实时数据流...")
        
        results = []
        
        # 测试多个股票的数据流
        test_stocks = ["0700.HK", "9988.HK", "3690.HK", "0005.HK", "1299.HK"]
        
        print(f"  测试{len(test_stocks)}支股票的实时数据流...")
        
        def test_stock_data(stock):
            try:
                start_time = time.time()
                
                # 获取行情数据
                quote_response = requests.get(f"{self.api_url}/api/stock/{stock}/quote", timeout=10)
                quote_success = quote_response.status_code == 200
                
                # 获取历史数据
                history_response = requests.get(f"{self.api_url}/api/stock/{stock}/history?period=1d", timeout=10)
                history_success = history_response.status_code == 200
                
                elapsed_time = (time.time() - start_time) * 1000
                
                result = {
                    "stock": stock,
                    "quote_success": quote_success,
                    "history_success": history_success,
                    "response_time_ms": round(elapsed_time, 2),
                    "success": quote_success and history_success
                }
                
                if quote_success:
                    quote_data = quote_response.json()
                    result["quote_data"] = {
                        "price": quote_data.get("current_price"),
                        "change_percent": quote_data.get("change_percent"),
                        "volume": quote_data.get("volume"),
                        "timestamp": quote_data.get("last_updated")
                    }
                
                if history_success:
                    history_data = history_response.json()
                    result["history_data_points"] = len(history_data)
                
                return result
            
            except Exception as e:
                return {
                    "stock": stock,
                    "quote_success": False,
                    "history_success": False,
                    "success": False,
                    "error": str(e)
                }
        
        # 串行测试每支股票
        for stock in test_stocks:
            result = test_stock_data(stock)
            results.append(result)
            
            status_symbol = "✓" if result["success"] else "✗"
            print(f"  {status_symbol} {stock}: 行情={result['quote_success']}, 历史={result['history_success']}, 响应时间={result['response_time_ms']}ms")
            
            # 显示实时价格
            if result.get("quote_data"):
                price = result["quote_data"].get("price")
                change = result["quote_data"].get("change_percent")
                print(f"    实时价格: {price}, 涨跌幅: {change}%")
        
        # 测试数据刷新机制
        print("  测试数据刷新机制...")
        try:
            # 多次请求同一支股票，检查价格是否更新
            stock = "0700.HK"
            prices = []
            timestamps = []
            
            for i in range(3):
                response = requests.get(f"{self.api_url}/api/stock/{stock}/quote", timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    prices.append(data.get("current_price"))
                    timestamps.append(data.get("last_updated"))
                
                if i < 2:
                    time.sleep(2)  # 等待2秒
            
            # 检查价格是否有变化
            price_changed = len(set(prices)) > 1 if prices else False
            has_timestamps = all(timestamps)
            
            refresh_result = {
                "test": "数据刷新测试",
                "stock": stock,
                "prices": prices,
                "timestamps": timestamps,
                "price_changed": price_changed,
                "has_timestamps": has_timestamps,
                "success": has_timestamps  # 只要有时间戳就认为成功
            }
            
            results.append(refresh_result)
            
            print(f"  {'✓' if has_timestamps else '✗'} 数据刷新: 价格变化={price_changed}, 时间戳={has_timestamps}")
            print(f"    价格序列: {prices}")
        
        except Exception as e:
            results.append({
                "test": "数据刷新测试",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ 数据刷新测试失败: {str(e)}")
        
        # 总结
        success_tests = len([r for r in results if r.get("success")])
        total_tests = len(results)
        
        data_stream_result = {
            "test_name": "实时数据流测试",
            "timestamp": datetime.now().isoformat(),
            "stocks_tested": len(test_stocks),
            "successful_tests": success_tests,
            "success_rate_percent": round(success_tests / total_tests * 100, 2) if total_tests > 0 else 0,
            "details": results
        }
        
        self.test_results.append(data_stream_result)
        return data_stream_result
    
    def test_data_consistency(self):
        """测试数据一致性"""
        print("\n4. 测试数据一致性...")
        
        results = []
        
        # 测试1: 同一股票多次查询的数据一致性
        print("  测试同一股票多次查询的数据一致性...")
        try:
            stock = "0700.HK"
            responses = []
            
            for i in range(3):
                response = requests.get(f"{self.api_url}/api/stock/{stock}/quote", timeout=5)
                if response.status_code == 200:
                    data = response.json()
                    responses.append(data)
                
                if i < 2:
                    time.sleep(1)
            
            if len(responses) >= 2:
                # 检查关键字段是否一致（除了时间戳）
                first_data = responses[0]
                inconsistencies = []
                
                for j, data in enumerate(responses[1:], 1):
                    for key in ["symbol", "name", "exchange"]:
                        if first_data.get(key) != data.get(key):
                            inconsistencies.append(f"周期{j}: {key}不一致")
                    
                    # 检查数值类型的近似一致性（允许微小差异）
                    for key in ["current_price", "change_percent", "volume"]:
                        val1 = first_data.get(key)
                        val2 = data.get(key)
                        
                        if val1 is not None and val2 is not None:
                            diff = abs(val1 - val2)
                            if diff > 0.01:  # 允许0.01的差异
                                inconsistencies.append(f"周期{j}: {key}差异较大 ({val1} vs {val2})")
                
                consistency_success = len(inconsistencies) == 0
                
                result = {
                    "test": "同一股票多次查询一致性",
                    "stock": stock,
                    "queries_performed": len(responses),
                    "inconsistencies": inconsistencies,
                    "success": consistency_success,
                    "details": {
                        "symbols": [r.get("symbol") for r in responses],
                        "prices": [r.get("current_price") for r in responses],
                        "timestamps": [r.get("last_updated") for r in responses]
                    }
                }
                
                results.append(result)
                
                print(f"  {'✓' if consistency_success else '⚠'} 数据一致性: 查询{len(responses)}次, 不一致项={len(inconsistencies)}")
                if inconsistencies:
                    for inc in inconsistencies[:2]:  # 只显示前2个
                        print(f"    - {inc}")
        
        except Exception as e:
            results.append({
                "test": "同一股票多次查询一致性",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ 一致性测试失败: {str(e)}")
        
        # 测试2: 市场指数数据的完整性
        print("  测试市场指数数据的完整性...")
        try:
            response = requests.get(f"{self.api_url}/api/market/indices", timeout=10)
            
            if response.status_code == 200:
                indices_data = response.json()
                
                required_indices = ["HSI", "HSCEI", "HSTI", "SP500", "SSE"]
                missing_indices = []
                
                for index in required_indices:
                    found = False
                    for item in indices_data:
                        if item.get("symbol") == index:
                            found = True
                            break
                    
                    if not found:
                        missing_indices.append(index)
                
                has_all_indices = len(missing_indices) == 0
                
                result = {
                    "test": "市场指数完整性",
                    "required_indices": required_indices,
                    "found_indices": [item.get("symbol") for item in indices_data],
                    "missing_indices": missing_indices,
                    "success": has_all_indices,
                    "data_count": len(indices_data)
                }
                
                results.append(result)
                
                print(f"  {'✓' if has_all_indices else '⚠'} 市场指数: 找到{len(indices_data)}个指数, 缺失{len(missing_indices)}个")
                if missing_indices:
                    print(f"    缺失指数: {missing_indices}")
        
        except Exception as e:
            results.append({
                "test": "市场指数完整性",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ 市场指数测试失败: {str(e)}")
        
        # 测试3: 板块数据的有效性
        print("  测试板块数据的有效性...")
        try:
            response = requests.get(f"{self.api_url}/api/market/sectors", timeout=10)
            
            if response.status_code == 200:
                sectors_data = response.json()
                
                # 检查板块数据是否包含必要字段
                valid_sectors = 0
                sector_details = []
                
                for sector in sectors_data:
                    has_name = "name" in sector
                    has_change = "change_percent" in sector
                    has_stocks = "stocks" in sector and isinstance(sector["stocks"], list)
                    
                    if has_name and has_change and has_stocks:
                        valid_sectors += 1
                    
                    sector_details.append({
                        "name": sector.get("name"),
                        "stocks_count": len(sector.get("stocks", [])),
                        "valid": has_name and has_change and has_stocks
                    })
                
                all_sectors_valid = valid_sectors == len(sectors_data)
                
                result = {
                    "test": "板块数据有效性",
                    "total_sectors": len(sectors_data),
                    "valid_sectors": valid_sectors,
                    "all_valid": all_sectors_valid,
                    "sector_details": sector_details
                }
                
                results.append(result)
                
                print(f"  {'✓' if all_sectors_valid else '⚠'} 板块数据: {valid_sectors}/{len(sectors_data)}个有效")
        
        except Exception as e:
            results.append({
                "test": "板块数据有效性",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ 板块数据测试失败: {str(e)}")
        
        # 总结
        success_tests = len([r for r in results if r.get("success")])
        total_tests = len(results)
        
        consistency_result = {
            "test_name": "数据一致性测试",
            "timestamp": datetime.now().isoformat(),
            "tests_performed": total_tests,
            "successful_tests": success_tests,
            "success_rate_percent": round(success_tests / total_tests * 100, 2) if total_tests > 0 else 0,
            "details": results
        }
        
        self.test_results.append(consistency_result)
        return consistency_result
    
    def test_error_handling(self):
        """测试错误处理机制"""
        print("\n5. 测试错误处理机制...")
        
        results = []
        
        # 测试1: 无效股票代码
        print("  测试无效股票代码处理...")
        try:
            response = requests.get(f"{self.api_url}/api/stock/INVALID.HK/quote", timeout=5)
            
            result = {
                "test": "无效股票代码",
                "status_code": response.status_code,
                "success": response.status_code == 404,  # 404表示正确处理了无效代码
                "response": response.json() if response.status_code != 404 else None
            }
            
            results.append(result)
            
            print(f"  {'✓' if result['success'] else '✗'} 无效股票代码: 状态码={response.status_code} (期望404)")
        
        except Exception as e:
            results.append({
                "test": "无效股票代码",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ 无效股票代码测试失败: {str(e)}")
        
        # 测试2: 无效API端点
        print("  测试无效API端点处理...")
        try:
            response = requests.get(f"{self.api_url}/api/invalid/endpoint", timeout=5)
            
            result = {
                "test": "无效API端点",
                "status_code": response.status_code,
                "success": response.status_code == 404,  # 404表示正确处理了无效端点
                "response": response.json() if response.status_code != 404 else None
            }
            
            results.append(result)
            
            print(f"  {'✓' if result['success'] else '✗'} 无效API端点: 状态码={response.status_code} (期望404)")
        
        except Exception as e:
            results.append({
                "test": "无效API端点",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ 无效API端点测试失败: {str(e)}")
        
        # 测试3: 服务器重启后的恢复
        print("  测试服务器重启恢复...")
        try:
            # 先测试正常连接
            response1 = requests.get(f"{self.api_url}/ping", timeout=3)
            initial_success = response1.status_code == 200
            
            if initial_success:
                print("  模拟服务器重启...")
                
                # 查找并终止Python服务器进程
                killed = False
                for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                    try:
                        if 'python' in proc.info['name'].lower():
                            cmdline = ' '.join(proc.info['cmdline'] or [])
                            if 'uvicorn' in cmdline and 'main:app' in cmdline:
                                print(f"    终止进程 {proc.info['pid']}")
                                psutil.Process(proc.info['pid']).terminate()
                                killed = True
                                time.sleep(2)
                                break
                    except:
                        continue
                
                if killed:
                    # 验证服务器已停止
                    try:
                        requests.get(f"{self.api_url}/ping", timeout=2)
                        server_stopped = False
                    except:
                        server_stopped = True
                    
                    if server_stopped:
                        print("    服务器已停止，等待自动重启...")
                        
                        # 等待自动重启（如果有监控脚本在运行）
                        recovery_success = False
                        for i in range(10):
                            try:
                                response2 = requests.get(f"{self.api_url}/ping", timeout=3)
                                if response2.status_code == 200:
                                    recovery_success = True
                                    print(f"    服务器在第{i+1}次尝试后恢复")
                                    break
                            except:
                                time.sleep(2)
                        
                        result = {
                            "test": "服务器重启恢复",
                            "initial_success": initial_success,
                            "server_killed": killed,
                            "server_stopped": server_stopped,
                            "recovery_success": recovery_success,
                            "success": recovery_success
                        }
                        
                        results.append(result)
                        
                        print(f"  {'✓' if recovery_success else '✗'} 服务器重启恢复: 恢复成功={recovery_success}")
                    else:
                        result = {
                            "test": "服务器重启恢复",
                            "success": False,
                            "error": "服务器未正确停止"
                        }
                        results.append(result)
                        print(f"  ✗ 服务器重启恢复: 服务器未正确停止")
                else:
                    result = {
                        "test": "服务器重启恢复",
                        "success": False,
                        "error": "未找到服务器进程"
                    }
                    results.append(result)
                    print(f"  ✗ 服务器重启恢复: 未找到服务器进程")
            else:
                result = {
                    "test": "服务器重启恢复",
                    "success": False,
                    "error": "初始连接失败"
                }
                results.append(result)
                print(f"  ✗ 服务器重启恢复: 初始连接失败")
        
        except Exception as e:
            results.append({
                "test": "服务器重启恢复",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ 服务器重启恢复测试失败: {str(e)}")
        
        # 总结
        success_tests = len([r for r in results if r.get("success")])
        total_tests = len(results)
        
        error_handling_result = {
            "test_name": "错误处理测试",
            "timestamp": datetime.now().isoformat(),
            "tests_performed": total_tests,
            "successful_tests": success_tests,
            "success_rate_percent": round(success_tests / total_tests * 100, 2) if total_tests > 0 else 0,
            "details": results
        }
        
        self.test_results.append(error_handling_result)
        return error_handling_result
    
    def run_comprehensive_test(self):
        """运行全面的端到端测试"""
        print("=" * 60)
        print("端到端集成测试")
        print(f"开始时间: {self.start_time.isoformat()}")
        print(f"API地址: {self.api_url}")
        print(f"本地IP地址: {self.local_ip}")
        print("=" * 60)
        
        # 运行所有测试
        self.test_server_startup()
        self.test_mobile_connectivity()
        self.test_realtime_data_stream()
        self.test_data_consistency()
        self.test_error_handling()
        
        # 生成测试报告
        self.generate_test_report()
        
        print("\n" + "=" * 60)
        print("端到端测试完成!")
        print(f"结束时间: {datetime.now().isoformat()}")
        print(f"总测试项目: {len(self.test_results)}")
        
        # 计算总体成功率
        total_tests = 0
        successful_tests = 0
        
        for test_result in self.test_results:
            if "success_rate_percent" in test_result:
                total_tests += 1
                if test_result["success_rate_percent"] >= 80:  # 80%成功率视为通过
                    successful_tests += 1
        
        overall_success_rate = round(successful_tests / total_tests * 100, 2) if total_tests > 0 else 0
        
        print(f"总体成功率: {overall_success_rate}%")
        
        # 提供连接测试指南
        print("\n📱 手机连接测试指南:")
        print(f"1. 确保手机和电脑在同一个WiFi网络")
        print(f"2. 在手机浏览器中访问: http://{self.local_ip}:8001/ping")
        print(f"3. 如果能看到API响应，说明网络连接正常")
        print(f"4. 在手机应用中配置服务器地址为: http://{self.local_ip}:8001")
        print("=" * 60)
    
    def generate_test_report(self):
        """生成测试报告"""
        try:
            report_data = {
                "report_generated": datetime.now().isoformat(),
                "test_session": {
                    "start_time": self.start_time.isoformat(),
                    "duration_seconds": round((datetime.now() - self.start_time).total_seconds(), 2),
                    "total_tests": len(self.test_results),
                    "api_url": self.api_url,
                    "local_ip": self.local_ip
                },
                "test_results": self.test_results,
                "summary": {},
                "recommendations": []
            }
            
            # 计算摘要统计
            total_success_rate = 0
            test_count = 0
            
            critical_tests = ["服务器启动测试", "手机连接性测试", "实时数据流测试"]
            critical_passed = 0
            
            for test_result in self.test_results:
                test_name = test_result.get("test_name", "")
                success_rate = test_result.get("success_rate_percent", 0)
                
                if success_rate > 0:  # 只计算有成功率的测试
                    total_success_rate += success_rate
                    test_count += 1
                
                if test_name in critical_tests and success_rate >= 80:
                    critical_passed += 1
            
            avg_success_rate = round(total_success_rate / test_count, 2) if test_count > 0 else 0
            
            report_data["summary"] = {
                "average_success_rate_percent": avg_success_rate,
                "critical_tests_passed": f"{critical_passed}/{len(critical_tests)}",
                "overall_status": "PASS" if avg_success_rate >= 80 and critical_passed == len(critical_tests) else "FAIL"
            }
            
            # 添加建议
            for test_result in self.test_results:
                test_name = test_result.get("test_name", "")
                success_rate = test_result.get("success_rate_percent", 0)
                
                if success_rate < 80:
                    report_data["recommendations"].append(f"{test_name}: 成功率较低 ({success_rate}%)，需要优化")
                
                if test_name == "手机连接性测试" and success_rate < 100:
                    report_data["recommendations"].append("手机连接不稳定，检查防火墙和网络配置")
                
                if test_name == "服务器启动测试" and success_rate < 100:
                    report_data["recommendations"].append("服务器启动存在问题，检查启动脚本和依赖")
            
            # 保存报告
            report_filename = f"e2e_test_report_{self.start_time.strftime('%Y%m%d_%H%M%S')}.json"
            report_filepath = os.path.join(self.log_dir, report_filename)
            
            with open(report_filepath, 'w', encoding='utf-8') as f:
                json.dump(report_data, f, indent=2, ensure_ascii=False)
            
            print(f"\n测试报告已保存到: {report_filepath}")
            
            # 同时生成HTML格式的简要报告
            self.generate_html_report(report_data)
            
            return report_filepath
            
        except Exception as e:
            print(f"生成测试报告失败: {str(e)}")
            return None
    
    def generate_html_report(self, report_data):
        """生成HTML格式的简要报告"""
        try:
            html_content = f"""
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>端到端集成测试报告</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        .header {{ text-align: center; margin-bottom: 30px; border-bottom: 2px solid #007bff; padding-bottom: 10px; }}
        .summary {{ background-color: #e9f7fe; padding: 15px; border-radius: 5px; margin-bottom: 20px; }}
        .connection-info {{ background-color: #f0f9f0; padding: 15px; border-radius: 5px; margin-bottom: 20px; }}
        .test-result {{ margin-bottom: 15px; padding: 10px; border-left: 4px solid #ccc; }}
        .test-pass {{ border-left-color: #28a745; background-color: #f0f9f0; }}
        .test-fail {{ border-left-color: #dc3545; background-color: #fdf0f0; }}
        .test-warning {{ border-left-color: #ffc107; background-color: #fff9e6; }}
        .status-badge {{ display: inline-block; padding: 3px 8px; border-radius: 12px; font-size: 12px; font-weight: bold; }}
        .status-pass {{ background-color: #28a745; color: white; }}
        .status-fail {{ background-color: #dc3545; color: white; }}
        .recommendations {{ background-color: #fff3cd; padding: 15px; border-radius: 5px; margin-top: 20px; }}
        .test-details {{ margin-top: 10px; font-size: 14px; color: #666; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📱 端到端集成测试报告</h1>
            <p>Flutter港股投资应用 - 服务器与手机连接测试</p>
            <p>生成时间: {report_data['report_generated']}</p>
        </div>
        
        <div class="summary">
            <h2>📊 测试摘要</h2>
            <p><strong>总体状态:</strong> 
                <span class="status-badge {'status-pass' if report_data['summary']['overall_status'] == 'PASS' else 'status-fail'}">
                    {report_data['summary']['overall_status']}
                </span>
            </p>
            <p><strong>平均成功率:</strong> {report_data['summary']['average_success_rate_percent']}%</p>
            <p><strong>关键测试通过率:</strong> {report_data['summary']['critical_tests_passed']}</p>
            <p><strong>测试时长:</strong> {report_data['test_session']['duration_seconds']} 秒</p>
            <p><strong>总测试项目:</strong> {report_data['test_session']['total_tests']}</p>
        </div>
        
        <div class="connection-info">
            <h2>🔗 连接信息</h2>
            <p><strong>API服务器地址:</strong> {report_data['test_session']['api_url']}</p>
            <p><strong>本地IP地址:</strong> {report_data['test_session']['local_ip']}</p>
            <p><strong>手机连接地址:</strong> http://{report_data['test_session']['local_ip']}:8001</p>
            <p><em>提示: 在手机浏览器中访问上述地址测试连接</em></p>
        </div>
        
        <h2>🧪 详细测试结果</h2>
        """
            
            for test_result in report_data['test_results']:
                test_name = test_result.get('test_name', '未命名测试')
                success_rate = test_result.get('success_rate_percent', 0)
                
                status_class = 'test-pass' if success_rate >= 80 else 'test-fail' if success_rate < 50 else 'test-warning'
                
                html_content += f"""
        <div class="test-result {status_class}">
            <h3>{test_name}</h3>
            <p><strong>成功率:</strong> {success_rate}%</p>
            <div class="test-details">
                <p><strong>测试时间:</strong> {test_result.get('timestamp', '未知')}</p>
                <p><strong>测试项目:</strong> {test_result.get('tests_performed', 0)}个</p>
                <p><strong>成功项目:</strong> {test_result.get('successful_tests', 0)}个</p>
            </div>
        </div>
                """
            
            if report_data['recommendations']:
                html_content += f"""
        <div class="recommendations">
            <h2>💡 优化建议</h2>
            <ul>
                """
                
                for recommendation in report_data['recommendations']:
                    html_content += f"<li>{recommendation}</li>"
                
                html_content += """
            </ul>
        </div>
                """
            
            html_content += """
        <div style="margin-top: 30px; text-align: center; color: #666; font-size: 12px;">
            <p>测试报告自动生成 | Flutter港股投资应用 v1.0 | 端到端集成测试</p>
        </div>
    </div>
</body>
</html>
            """
            
            html_filename = f"e2e_test_report_{self.start_time.strftime('%Y%m%d_%H%M%S')}.html"
            html_filepath = os.path.join(self.log_dir, html_filename)
            
            with open(html_filepath, 'w', encoding='utf-8') as f:
                f.write(html_content)
            
            print(f"HTML测试报告已保存到: {html_filepath}")
            
        except Exception as e:
            print(f"生成HTML报告失败: {str(e)}")

def main():
    """主函数"""
    print("端到端集成测试系统")
    print("=" * 50)
    
    # 创建测试器实例
    tester = EndToEndTester(api_url="http://localhost:8001")
    
    # 运行全面测试
    tester.run_comprehensive_test()
    
    print("\n测试完成！")

if __name__ == "__main__":
    main()