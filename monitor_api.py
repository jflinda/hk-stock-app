"""
API服务器监控脚本
监控FastAPI服务器的健康状况、响应时间和资源使用
"""

import time
import requests
import psutil
import json
from datetime import datetime
import subprocess
import os
import sys

class APIMonitor:
    def __init__(self, api_url="http://localhost:8001"):
        self.api_url = api_url
        self.monitor_data = []
        self.start_time = datetime.now()
        
    def check_api_health(self):
        """检查API健康状态"""
        try:
            start = time.time()
            response = requests.get(f"{self.api_url}/ping", timeout=5)
            response_time = (time.time() - start) * 1000  # 毫秒
            
            health_data = {
                "timestamp": datetime.now().isoformat(),
                "endpoint": "/ping",
                "status_code": response.status_code,
                "response_time_ms": round(response_time, 2),
                "response": response.json() if response.status_code == 200 else None
            }
            
            return health_data
        except requests.exceptions.ConnectionError:
            return {
                "timestamp": datetime.now().isoformat(),
                "endpoint": "/ping",
                "status_code": 0,
                "response_time_ms": -1,
                "error": "Connection refused"
            }
        except Exception as e:
            return {
                "timestamp": datetime.now().isoformat(),
                "endpoint": "/ping",
                "status_code": -1,
                "response_time_ms": -1,
                "error": str(e)
            }
    
    def check_api_endpoints(self):
        """检查所有关键API端点"""
        endpoints = [
            "/api/market/indices",
            "/api/market/sectors",
            "/api/market/movers",
            "/api/stock/0700.HK/quote",
            "/api/watchlist",
            "/api/portfolio/summary"
        ]
        
        results = []
        for endpoint in endpoints:
            try:
                start = time.time()
                response = requests.get(f"{self.api_url}{endpoint}", timeout=10)
                response_time = (time.time() - start) * 1000
                
                result = {
                    "timestamp": datetime.now().isoformat(),
                    "endpoint": endpoint,
                    "status_code": response.status_code,
                    "response_time_ms": round(response_time, 2),
                    "data_size": len(response.content) if response.status_code == 200 else 0
                }
                
                # 检查数据结构
                if response.status_code == 200:
                    try:
                        data = response.json()
                        result["data_type"] = type(data).__name__
                        if isinstance(data, list):
                            result["item_count"] = len(data)
                        elif isinstance(data, dict):
                            result["has_data"] = len(data) > 0
                    except:
                        result["data_type"] = "invalid_json"
                
                results.append(result)
                
            except Exception as e:
                results.append({
                    "timestamp": datetime.now().isoformat(),
                    "endpoint": endpoint,
                    "status_code": -1,
                    "response_time_ms": -1,
                    "error": str(e)
                })
        
        return results
    
    def check_system_resources(self):
        """检查系统资源使用情况"""
        try:
            # 查找Python进程
            python_processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                try:
                    if 'python' in proc.info['name'].lower():
                        python_processes.append(proc.info)
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            return {
                "timestamp": datetime.now().isoformat(),
                "system_cpu_percent": psutil.cpu_percent(interval=0.1),
                "system_memory_percent": psutil.virtual_memory().percent,
                "python_processes": python_processes,
                "disk_usage": psutil.disk_usage('C:').percent
            }
        except Exception as e:
            return {
                "timestamp": datetime.now().isoformat(),
                "error": f"Resource check failed: {str(e)}"
            }
    
    def stress_test(self, concurrent_requests=10, duration_seconds=30):
        """执行压力测试"""
        import threading
        import queue
        
        results = queue.Queue()
        errors = queue.Queue()
        
        def make_request(endpoint):
            try:
                start = time.time()
                response = requests.get(f"{self.api_url}{endpoint}", timeout=5)
                elapsed = (time.time() - start) * 1000
                
                results.put({
                    "endpoint": endpoint,
                    "status": response.status_code,
                    "response_time_ms": round(elapsed, 2),
                    "success": response.status_code == 200
                })
            except Exception as e:
                errors.put({
                    "endpoint": endpoint,
                    "error": str(e)
                })
        
        endpoints = ["/ping", "/api/market/indices", "/api/market/movers"]
        
        threads = []
        start_time = time.time()
        
        print(f"开始压力测试: {concurrent_requests}个并发请求，持续{duration_seconds}秒")
        
        while time.time() - start_time < duration_seconds:
            # 启动新一批并发请求
            for i in range(concurrent_requests):
                endpoint = endpoints[i % len(endpoints)]
                t = threading.Thread(target=make_request, args=(endpoint,))
                t.start()
                threads.append(t)
            
            time.sleep(0.5)  # 小延迟以避免过载
        
        # 等待所有线程完成
        for t in threads:
            t.join(timeout=10)
        
        # 收集结果
        result_list = []
        error_list = []
        
        while not results.empty():
            result_list.append(results.get())
        
        while not errors.empty():
            error_list.append(errors.get())
        
        success_rate = len([r for r in result_list if r.get("success")]) / max(len(result_list), 1)
        avg_response_time = sum([r.get("response_time_ms", 0) for r in result_list]) / max(len(result_list), 1)
        
        stress_result = {
            "timestamp": datetime.now().isoformat(),
            "duration_seconds": duration_seconds,
            "concurrent_requests": concurrent_requests,
            "total_requests": len(result_list) + len(error_list),
            "successful_requests": len([r for r in result_list if r.get("success")]),
            "failed_requests": len(error_list),
            "success_rate_percent": round(success_rate * 100, 2),
            "average_response_time_ms": round(avg_response_time, 2),
            "max_response_time_ms": max([r.get("response_time_ms", 0) for r in result_list], default=0),
            "min_response_time_ms": min([r.get("response_time_ms", 0) for r in result_list], default=0)
        }
        
        return stress_result
    
    def auto_restart_server(self):
        """自动重启API服务器（如果需要）"""
        try:
            # 检查服务器是否在运行
            response = requests.get(f"{self.api_url}/ping", timeout=3)
            if response.status_code == 200:
                print(f"[{datetime.now().isoformat()}] API服务器正常运行")
                return False
        except:
            print(f"[{datetime.now().isoformat()}] API服务器无响应，尝试重启...")
            
            try:
                # 杀死现有Python进程
                for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                    try:
                        if 'python' in proc.info['name'].lower():
                            cmdline = ' '.join(proc.info['cmdline'] or [])
                            if 'uvicorn' in cmdline and 'main:app' in cmdline:
                                print(f"终止进程 {proc.info['pid']}: {cmdline}")
                                psutil.Process(proc.info['pid']).terminate()
                                time.sleep(1)
                    except:
                        continue
                
                # 启动新服务器
                project_dir = os.path.dirname(os.path.abspath(__file__))
                backend_dir = os.path.join(project_dir, "backend")
                
                cmd = [
                    sys.executable, "-m", "uvicorn", "main:app",
                    "--host", "0.0.0.0", "--port", "8001"
                ]
                
                # 在后台启动（Windows）
                startupinfo = subprocess.STARTUPINFO()
                startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
                startupinfo.wShowWindow = subprocess.SW_HIDE
                
                subprocess.Popen(
                    cmd,
                    cwd=backend_dir,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    startupinfo=startupinfo
                )
                
                print(f"[{datetime.now().isoformat()}] API服务器已重启")
                
                # 等待服务器启动
                time.sleep(5)
                return True
                
            except Exception as e:
                print(f"[{datetime.now().isoformat()}] 重启失败: {str(e)}")
                return False
        
        return False
    
    def run_monitoring_session(self, duration_minutes=60, interval_seconds=30):
        """运行监控会话"""
        print(f"开始监控会话: {duration_minutes}分钟，间隔{interval_seconds}秒")
        print(f"API地址: {self.api_url}")
        print(f"开始时间: {self.start_time.isoformat()}")
        print("-" * 50)
        
        start_time = time.time()
        cycle_count = 0
        
        while time.time() - start_time < duration_minutes * 60:
            cycle_count += 1
            print(f"\n[周期 {cycle_count}] 时间: {datetime.now().isoformat()}")
            
            # 1. 自动重启检查
            restarted = self.auto_restart_server()
            if restarted:
                print("API服务器已自动重启")
            
            # 2. 健康检查
            health = self.check_api_health()
            print(f"健康检查: 状态码={health.get('status_code')}, 响应时间={health.get('response_time_ms')}ms")
            
            # 3. 端点检查（每5个周期执行一次）
            if cycle_count % 5 == 0:
                print("执行端点检查...")
                endpoints = self.check_api_endpoints()
                for endpoint in endpoints[:3]:  # 只显示前3个
                    status = endpoint.get('status_code')
                    time_ms = endpoint.get('response_time_ms', 0)
                    print(f"  {endpoint.get('endpoint')}: 状态码={status}, 响应时间={time_ms}ms")
            
            # 4. 系统资源检查（每10个周期执行一次）
            if cycle_count % 10 == 0:
                print("检查系统资源...")
                resources = self.check_system_resources()
                cpu = resources.get('system_cpu_percent', 0)
                mem = resources.get('system_memory_percent', 0)
                print(f"  系统CPU: {cpu}%, 内存: {mem}%")
            
            # 5. 压力测试（每30个周期执行一次）
            if cycle_count % 30 == 0 and cycle_count > 0:
                print("执行压力测试...")
                try:
                    stress_result = self.stress_test(concurrent_requests=5, duration_seconds=10)
                    print(f"  压力测试结果: {stress_result.get('success_rate_percent')}% 成功率")
                except Exception as e:
                    print(f"  压力测试失败: {str(e)}")
            
            # 保存监控数据
            self.monitor_data.append({
                "cycle": cycle_count,
                "timestamp": datetime.now().isoformat(),
                "health": health,
                "restarted": restarted
            })
            
            # 每10个周期保存一次数据到文件
            if cycle_count % 10 == 0:
                self.save_monitor_data()
            
            # 等待下一个周期
            print(f"等待 {interval_seconds} 秒...")
            time.sleep(interval_seconds)
        
        print("\n" + "=" * 50)
        print(f"监控会话完成!")
        print(f"总时长: {duration_minutes} 分钟")
        print(f"总周期数: {cycle_count}")
        print(f"保存监控数据...")
        
        self.save_monitor_data()
        self.generate_report()
    
    def save_monitor_data(self):
        """保存监控数据到文件"""
        try:
            filename = f"api_monitor_{self.start_time.strftime('%Y%m%d_%H%M%S')}.json"
            filepath = os.path.join(os.path.dirname(os.path.abspath(__file__)), "monitor_logs", filename)
            
            # 确保目录存在
            os.makedirs(os.path.dirname(filepath), exist_ok=True)
            
            with open(filepath, 'w') as f:
                json.dump({
                    "start_time": self.start_time.isoformat(),
                    "api_url": self.api_url,
                    "total_cycles": len(self.monitor_data),
                    "monitor_data": self.monitor_data
                }, f, indent=2)
            
            print(f"监控数据已保存到: {filepath}")
        except Exception as e:
            print(f"保存监控数据失败: {str(e)}")
    
    def generate_report(self):
        """生成监控报告"""
        try:
            if not self.monitor_data:
                print("无监控数据可生成报告")
                return
            
            # 分析数据
            total_cycles = len(self.monitor_data)
            successful_health_checks = len([d for d in self.monitor_data if d.get('health', {}).get('status_code') == 200])
            failed_health_checks = total_cycles - successful_health_checks
            restart_count = len([d for d in self.monitor_data if d.get('restarted')])
            
            response_times = [d.get('health', {}).get('response_time_ms', 0) for d in self.monitor_data if d.get('health', {}).get('response_time_ms', 0) > 0]
            avg_response_time = sum(response_times) / len(response_times) if response_times else 0
            
            report = {
                "report_generated": datetime.now().isoformat(),
                "monitoring_session": {
                    "start_time": self.start_time.isoformat(),
                    "duration_minutes": round((time.time() - self.start_time.timestamp()) / 60, 2),
                    "total_cycles": total_cycles
                },
                "api_health": {
                    "success_rate_percent": round(successful_health_checks / total_cycles * 100, 2) if total_cycles > 0 else 0,
                    "failed_checks": failed_health_checks,
                    "restart_count": restart_count
                },
                "performance": {
                    "average_response_time_ms": round(avg_response_time, 2),
                    "min_response_time_ms": min(response_times) if response_times else 0,
                    "max_response_time_ms": max(response_times) if response_times else 0
                },
                "recommendations": []
            }
            
            # 添加建议
            if failed_health_checks > 0:
                report["recommendations"].append("建议实现更稳定的API服务器自动重启机制")
            
            if avg_response_time > 1000:  # 超过1秒
                report["recommendations"].append("API响应时间较长，建议优化查询或增加缓存")
            
            if restart_count > 0:
                report["recommendations"].append("API服务器不稳定，建议检查内存泄漏或资源使用")
            
            # 保存报告
            report_filename = f"api_monitor_report_{self.start_time.strftime('%Y%m%d_%H%M%S')}.json"
            report_filepath = os.path.join(os.path.dirname(os.path.abspath(__file__)), "monitor_logs", report_filename)
            
            with open(report_filepath, 'w') as f:
                json.dump(report, f, indent=2)
            
            print(f"监控报告已生成: {report_filepath}")
            print(json.dumps(report, indent=2))
            
        except Exception as e:
            print(f"生成报告失败: {str(e)}")

def main():
    """主函数"""
    print("API服务器监控系统")
    print("=" * 50)
    
    # 创建监控实例
    monitor = APIMonitor(api_url="http://localhost:8001")
    
    # 运行监控会话（30分钟，每30秒检查一次）
    # 在实际环境中，可以设置为更长的持续时间
    monitor.run_monitoring_session(duration_minutes=30, interval_seconds=30)
    
    print("\n监控完成！")

if __name__ == "__main__":
    main()