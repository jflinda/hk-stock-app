"""
Flutter应用功能测试脚本
测试所有页面的功能和API集成
"""

import os
import json
import time
import subprocess
import requests
from datetime import datetime
import psutil

class FlutterAppTester:
    def __init__(self, api_url="http://localhost:8001", project_dir=None):
        self.api_url = api_url
        if project_dir is None:
            self.project_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "frontend")
        else:
            self.project_dir = project_dir
        
        self.test_results = []
        self.start_time = datetime.now()
    
    def test_api_connectivity(self):
        """测试API连接性"""
        print("1. 测试API连接性...")
        
        endpoints = [
            ("/ping", "健康检查"),
            ("/api/market/indices", "市场指数"),
            ("/api/market/sectors", "板块数据"),
            ("/api/market/movers", "活跃股"),
            ("/api/stock/0700.HK/quote", "个股行情"),
            ("/api/stock/0700.HK/history?period=1d", "K线数据"),
            ("/api/watchlist", "自选股"),
            ("/api/portfolio/summary", "投资组合"),
            ("/api/trades", "交易记录")
        ]
        
        results = []
        for endpoint, description in endpoints:
            try:
                start_time = time.time()
                response = requests.get(f"{self.api_url}{endpoint}", timeout=10)
                response_time = (time.time() - start_time) * 1000
                
                result = {
                    "endpoint": endpoint,
                    "description": description,
                    "status_code": response.status_code,
                    "response_time_ms": round(response_time, 2),
                    "success": response.status_code == 200
                }
                
                if response.status_code == 200:
                    try:
                        data = response.json()
                        result["has_data"] = len(data) > 0 if isinstance(data, list) else bool(data)
                        result["data_sample"] = str(data)[:100] + "..." if len(str(data)) > 100 else str(data)
                    except:
                        result["has_data"] = False
                        result["data_sample"] = "Invalid JSON"
                else:
                    result["error"] = response.text[:200]
                
                results.append(result)
                status_symbol = "✓" if result["success"] else "✗"
                print(f"  {status_symbol} {description}: 状态码={result['status_code']}, 响应时间={result['response_time_ms']}ms")
                
            except Exception as e:
                result = {
                    "endpoint": endpoint,
                    "description": description,
                    "status_code": -1,
                    "response_time_ms": -1,
                    "success": False,
                    "error": str(e)
                }
                results.append(result)
                print(f"  ✗ {description}: 连接失败 - {str(e)}")
        
        success_count = len([r for r in results if r["success"]])
        total_count = len(results)
        
        connectivity_result = {
            "test_name": "API连接性测试",
            "timestamp": datetime.now().isoformat(),
            "success_rate": f"{success_count}/{total_count}",
            "success_rate_percent": round(success_count / total_count * 100, 2) if total_count > 0 else 0,
            "details": results
        }
        
        self.test_results.append(connectivity_result)
        return connectivity_result
    
    def test_yfinance_data_source(self):
        """测试yfinance数据源"""
        print("\n2. 测试yfinance数据源...")
        
        test_stocks = [
            "0700.HK",  # 腾讯
            "9988.HK",  # 阿里巴巴
            "3690.HK",  # 美团
            "0005.HK",  # 汇丰
            "1299.HK"   # 友邦
        ]
        
        results = []
        for stock in test_stocks:
            try:
                # 测试行情数据
                quote_url = f"{self.api_url}/api/stock/{stock}/quote"
                quote_response = requests.get(quote_url, timeout=10)
                
                # 测试历史数据
                history_url = f"{self.api_url}/api/stock/{stock}/history?period=5d"
                history_response = requests.get(history_url, timeout=10)
                
                result = {
                    "stock": stock,
                    "quote_status": quote_response.status_code,
                    "history_status": history_response.status_code,
                    "success": quote_response.status_code == 200 and history_response.status_code == 200
                }
                
                if quote_response.status_code == 200:
                    quote_data = quote_response.json()
                    result["quote_data"] = {
                        "symbol": quote_data.get("symbol"),
                        "price": quote_data.get("current_price"),
                        "change_percent": quote_data.get("change_percent"),
                        "volume": quote_data.get("volume")
                    }
                
                if history_response.status_code == 200:
                    history_data = history_response.json()
                    result["history_data_points"] = len(history_data)
                    if history_data:
                        result["latest_date"] = history_data[0].get("date") if isinstance(history_data, list) else None
                
                results.append(result)
                status_symbol = "✓" if result["success"] else "✗"
                print(f"  {status_symbol} {stock}: 行情={result['quote_status']}, 历史={result['history_status']}")
                
            except Exception as e:
                result = {
                    "stock": stock,
                    "quote_status": -1,
                    "history_status": -1,
                    "success": False,
                    "error": str(e)
                }
                results.append(result)
                print(f"  ✗ {stock}: 测试失败 - {str(e)}")
        
        success_count = len([r for r in results if r["success"]])
        
        yfinance_result = {
            "test_name": "yfinance数据源测试",
            "timestamp": datetime.now().isoformat(),
            "stocks_tested": len(test_stocks),
            "successful_stocks": success_count,
            "success_rate_percent": round(success_count / len(test_stocks) * 100, 2) if test_stocks else 0,
            "details": results
        }
        
        self.test_results.append(yfinance_result)
        return yfinance_result
    
    def test_flutter_build(self):
        """测试Flutter构建"""
        print("\n3. 测试Flutter构建...")
        
        results = []
        
        # 测试1: Flutter doctor
        try:
            print("  运行 flutter doctor...")
            doctor_result = subprocess.run(
                ["flutter", "doctor"],
                cwd=self.project_dir,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            doctor_success = doctor_result.returncode == 0
            results.append({
                "test": "flutter_doctor",
                "success": doctor_success,
                "return_code": doctor_result.returncode,
                "output_preview": doctor_result.stdout[:200] + "..." if len(doctor_result.stdout) > 200 else doctor_result.stdout
            })
            
            print(f"  {'✓' if doctor_success else '✗'} flutter doctor: 返回码={doctor_result.returncode}")
            
        except Exception as e:
            results.append({
                "test": "flutter_doctor",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ flutter doctor: 失败 - {str(e)}")
        
        # 测试2: Flutter analyze
        try:
            print("  运行 flutter analyze...")
            analyze_result = subprocess.run(
                ["flutter", "analyze"],
                cwd=self.project_dir,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            # 检查是否有错误
            has_errors = "error•" in analyze_result.stdout or analyze_result.returncode != 0
            analyze_success = not has_errors
            
            results.append({
                "test": "flutter_analyze",
                "success": analyze_success,
                "return_code": analyze_result.returncode,
                "has_errors": has_errors,
                "output_preview": analyze_result.stdout[:200] + "..." if len(analyze_result.stdout) > 200 else analyze_result.stdout
            })
            
            print(f"  {'✓' if analyze_success else '✗'} flutter analyze: {'有错误' if has_errors else '无错误'}")
            
        except Exception as e:
            results.append({
                "test": "flutter_analyze",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ flutter analyze: 失败 - {str(e)}")
        
        # 测试3: Flutter build apk (检查模式)
        try:
            print("  测试Flutter APK构建...")
            build_result = subprocess.run(
                ["flutter", "build", "apk", "--debug", "--no-tree-shake-icons"],
                cwd=self.project_dir,
                capture_output=True,
                text=True,
                timeout=180
            )
            
            build_success = build_result.returncode == 0
            
            # 检查APK文件是否存在
            apk_path = os.path.join(self.project_dir, "build", "app", "outputs", "flutter-apk", "app-debug.apk")
            apk_exists = os.path.exists(apk_path)
            apk_size = os.path.getsize(apk_path) if apk_exists else 0
            
            results.append({
                "test": "flutter_build",
                "success": build_success and apk_exists,
                "return_code": build_result.returncode,
                "apk_exists": apk_exists,
                "apk_size_mb": round(apk_size / (1024 * 1024), 2) if apk_exists else 0,
                "output_preview": build_result.stdout[:200] + "..." if len(build_result.stdout) > 200 else build_result.stdout
            })
            
            print(f"  {'✓' if build_success and apk_exists else '✗'} Flutter构建: APK大小={round(apk_size/(1024*1024), 2)}MB")
            
        except Exception as e:
            results.append({
                "test": "flutter_build",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ Flutter构建: 失败 - {str(e)}")
        
        success_count = len([r for r in results if r["success"]])
        
        build_result = {
            "test_name": "Flutter构建测试",
            "timestamp": datetime.now().isoformat(),
            "tests_performed": len(results),
            "successful_tests": success_count,
            "success_rate_percent": round(success_count / len(results) * 100, 2) if results else 0,
            "details": results
        }
        
        self.test_results.append(build_result)
        return build_result
    
    def test_flutter_pages(self):
        """测试Flutter页面功能"""
        print("\n4. 测试Flutter页面功能...")
        
        pages = [
            {
                "name": "Portfolio页面",
                "api_endpoints": ["/api/portfolio/summary", "/api/trades"],
                "description": "投资组合和交易记录"
            },
            {
                "name": "Market页面",
                "api_endpoints": ["/api/market/indices", "/api/market/sectors", "/api/market/movers"],
                "description": "市场数据和行情"
            },
            {
                "name": "Watchlist页面",
                "api_endpoints": ["/api/watchlist"],
                "description": "自选股管理"
            },
            {
                "name": "Tools页面",
                "api_endpoints": [],  # 工具页面主要是本地计算
                "description": "交易工具和计算器"
            },
            {
                "name": "Settings页面",
                "api_endpoints": [],  # 设置页面不需要API
                "description": "应用设置和配置"
            }
        ]
        
        results = []
        for page in pages:
            page_name = page["name"]
            endpoints = page["api_endpoints"]
            
            endpoint_results = []
            all_success = True
            
            for endpoint in endpoints:
                try:
                    response = requests.get(f"{self.api_url}{endpoint}", timeout=10)
                    success = response.status_code == 200
                    
                    endpoint_results.append({
                        "endpoint": endpoint,
                        "status_code": response.status_code,
                        "success": success,
                        "has_data": len(response.json()) > 0 if success and response.status_code == 200 else False
                    })
                    
                    if not success:
                        all_success = False
                        
                except Exception as e:
                    endpoint_results.append({
                        "endpoint": endpoint,
                        "status_code": -1,
                        "success": False,
                        "error": str(e)
                    })
                    all_success = False
            
            # 检查页面相关文件是否存在
            page_files = []
            try:
                # 检查页面文件
                pages_dir = os.path.join(self.project_dir, "lib", "screens")
                for root, dirs, files in os.walk(pages_dir):
                    for file in files:
                        if page_name.lower().replace("页面", "").lower() in file.lower():
                            page_files.append(os.path.join(root, file))
            except:
                pass
            
            result = {
                "page_name": page_name,
                "description": page["description"],
                "api_endpoints_required": len(endpoints),
                "api_endpoints_successful": len([e for e in endpoint_results if e["success"]]),
                "all_apis_successful": all_success,
                "page_files_found": len(page_files),
                "details": {
                    "api_endpoints": endpoint_results,
                    "page_files": page_files
                }
            }
            
            results.append(result)
            
            status_symbol = "✓" if all_success else "⚠" if endpoint_results else "✗"
            print(f"  {status_symbol} {page_name}: API端点={result['api_endpoints_successful']}/{result['api_endpoints_required']}, 文件={result['page_files_found']}个")
        
        successful_pages = len([r for r in results if r["all_apis_successful"]])
        
        pages_result = {
            "test_name": "Flutter页面功能测试",
            "timestamp": datetime.now().isoformat(),
            "pages_tested": len(pages),
            "successful_pages": successful_pages,
            "success_rate_percent": round(successful_pages / len(pages) * 100, 2) if pages else 0,
            "details": results
        }
        
        self.test_results.append(pages_result)
        return pages_result
    
    def test_database_operations(self):
        """测试数据库CRUD操作"""
        print("\n5. 测试数据库CRUD操作...")
        
        tests = []
        
        # 测试1: 添加自选股
        try:
            test_watchlist_item = {
                "symbol": "TEST.HK",
                "name": "测试股票",
                "current_price": 100.0,
                "change_percent": 1.5,
                "added_at": datetime.now().isoformat()
            }
            
            response = requests.post(
                f"{self.api_url}/api/watchlist",
                json=test_watchlist_item,
                timeout=10
            )
            
            add_success = response.status_code == 200
            tests.append({
                "operation": "添加自选股",
                "success": add_success,
                "status_code": response.status_code
            })
            
            print(f"  {'✓' if add_success else '✗'} 添加自选股: 状态码={response.status_code}")
            
            # 如果添加成功，测试获取和删除
            if add_success:
                # 测试获取自选股列表
                get_response = requests.get(f"{self.api_url}/api/watchlist", timeout=10)
                get_success = get_response.status_code == 200
                
                tests.append({
                    "operation": "获取自选股列表",
                    "success": get_success,
                    "status_code": get_response.status_code,
                    "count": len(get_response.json()) if get_success else 0
                })
                
                print(f"  {'✓' if get_success else '✗'} 获取自选股列表: 状态码={get_response.status_code}")
                
                # 测试删除自选股（需要知道ID，这里简化处理）
                # 实际应用中需要从响应中获取ID
                
        except Exception as e:
            tests.append({
                "operation": "添加自选股",
                "success": False,
                "error": str(e)
            })
            print(f"  ✗ 数据库操作测试: 失败 - {str(e)}")
        
        # 测试2: 添加交易记录
        try:
            test_trade = {
                "symbol": "0700.HK",
                "action": "BUY",
                "quantity": 100,
                "price": 350.0,
                "commission": 50.0,
                "trade_date": datetime.now().isoformat()
            }
            
            response = requests.post(
                f"{self.api_url}/api/trades",
                json=test_trade,
                timeout=10
            )
            
            trade_success = response.status_code == 200
            tests.append({
                "operation": "添加交易记录",
                "success": trade_success,
                "status_code": response.status_code
            })
            
            print(f"  {'✓' if trade_success else '✗'} 添加交易记录: 状态码={response.status_code}")
            
        except Exception as e:
            tests.append({
                "operation": "添加交易记录",
                "success": False,
                "error": str(e)
            })
        
        success_count = len([t for t in tests if t["success"]])
        
        db_result = {
            "test_name": "数据库CRUD操作测试",
            "timestamp": datetime.now().isoformat(),
            "operations_tested": len(tests),
            "successful_operations": success_count,
            "success_rate_percent": round(success_count / len(tests) * 100, 2) if tests else 0,
            "details": tests
        }
        
        self.test_results.append(db_result)
        return db_result
    
    def test_k_chart_integration(self):
        """测试K线图集成"""
        print("\n6. 测试K线图集成...")
        
        try:
            # 检查K线图包是否在pubspec.yaml中
            pubspec_path = os.path.join(self.project_dir, "pubspec.yaml")
            if os.path.exists(pubspec_path):
                with open(pubspec_path, 'r', encoding='utf-8') as f:
                    pubspec_content = f.read()
                
                has_k_chart = "flutter_chen_kchart" in pubspec_content or "k_chart" in pubspec_content.lower()
            else:
                has_k_chart = False
            
            # 测试K线数据API
            kchart_endpoints = [
                "/api/stock/0700.HK/history?period=1d",
                "/api/stock/0700.HK/history?period=5d",
                "/api/stock/0700.HK/history?period=1m"
            ]
            
            kchart_results = []
            for endpoint in kchart_endpoints:
                try:
                    response = requests.get(f"{self.api_url}{endpoint}", timeout=10)
                    success = response.status_code == 200
                    
                    if success:
                        data = response.json()
                        has_ohlc = all(key in data[0] for key in ["open", "high", "low", "close"]) if data else False
                    else:
                        has_ohlc = False
                    
                    kchart_results.append({
                        "endpoint": endpoint,
                        "success": success,
                        "status_code": response.status_code,
                        "has_ohlc_data": has_ohlc,
                        "data_points": len(data) if success and data else 0
                    })
                    
                except Exception as e:
                    kchart_results.append({
                        "endpoint": endpoint,
                        "success": False,
                        "error": str(e)
                    })
            
            kchart_success = all(r["success"] for r in kchart_results) and has_k_chart
            
            result = {
                "test_name": "K线图集成测试",
                "timestamp": datetime.now().isoformat(),
                "kchart_package_installed": has_k_chart,
                "kchart_endpoints_tested": len(kchart_endpoints),
                "kchart_endpoints_successful": len([r for r in kchart_results if r["success"]]),
                "all_kchart_data_valid": all(r.get("has_ohlc_data", False) for r in kchart_results if r["success"]),
                "success": kchart_success,
                "details": {
                    "pubspec_has_kchart": has_k_chart,
                    "endpoint_tests": kchart_results
                }
            }
            
            print(f"  {'✓' if kchart_success else '✗'} K线图集成: 包安装={has_k_chart}, 数据端点={result['kchart_endpoints_successful']}/{len(kchart_endpoints)}")
            
        except Exception as e:
            result = {
                "test_name": "K线图集成测试",
                "timestamp": datetime.now().isoformat(),
                "success": False,
                "error": str(e)
            }
            print(f"  ✗ K线图集成测试: 失败 - {str(e)}")
        
        self.test_results.append(result)
        return result
    
    def run_comprehensive_test(self):
        """运行全面的测试套件"""
        print("=" * 60)
        print("Flutter应用全面功能测试")
        print(f"开始时间: {self.start_time.isoformat()}")
        print(f"API地址: {self.api_url}")
        print(f"项目目录: {self.project_dir}")
        print("=" * 60)
        
        # 运行所有测试
        self.test_api_connectivity()
        self.test_yfinance_data_source()
        self.test_flutter_build()
        self.test_flutter_pages()
        self.test_database_operations()
        self.test_k_chart_integration()
        
        # 生成测试报告
        self.generate_test_report()
        
        print("\n" + "=" * 60)
        print("测试完成!")
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
        print("=" * 60)
    
    def generate_test_report(self):
        """生成测试报告"""
        try:
            report_data = {
                "report_generated": datetime.now().isoformat(),
                "test_session": {
                    "start_time": self.start_time.isoformat(),
                    "duration_seconds": round((datetime.now() - self.start_time).total_seconds(), 2),
                    "total_tests": len(self.test_results)
                },
                "test_results": self.test_results,
                "summary": {},
                "recommendations": []
            }
            
            # 计算摘要统计
            total_success_rate = 0
            test_count = 0
            
            critical_tests = ["API连接性测试", "Flutter构建测试", "K线图集成测试"]
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
                
                if test_name == "API连接性测试" and success_rate < 100:
                    report_data["recommendations"].append("API连接不稳定，检查网络配置和防火墙")
                
                if test_name == "Flutter构建测试" and success_rate < 100:
                    report_data["recommendations"].append("Flutter构建存在问题，检查依赖和配置")
            
            # 保存报告
            report_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "test_reports")
            os.makedirs(report_dir, exist_ok=True)
            
            report_filename = f"flutter_app_test_report_{self.start_time.strftime('%Y%m%d_%H%M%S')}.json"
            report_filepath = os.path.join(report_dir, report_filename)
            
            with open(report_filepath, 'w', encoding='utf-8') as f:
                json.dump(report_data, f, indent=2, ensure_ascii=False)
            
            print(f"\n测试报告已保存到: {report_filepath}")
            
            # 同时生成HTML格式的简要报告
            self.generate_html_report(report_data, report_dir)
            
            return report_filepath
            
        except Exception as e:
            print(f"生成测试报告失败: {str(e)}")
            return None
    
    def generate_html_report(self, report_data, report_dir):
        """生成HTML格式的简要报告"""
        try:
            html_content = f"""
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flutter应用测试报告</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        .header {{ text-align: center; margin-bottom: 30px; border-bottom: 2px solid #007bff; padding-bottom: 10px; }}
        .summary {{ background-color: #e9f7fe; padding: 15px; border-radius: 5px; margin-bottom: 20px; }}
        .test-result {{ margin-bottom: 15px; padding: 10px; border-left: 4px solid #ccc; }}
        .test-pass {{ border-left-color: #28a745; background-color: #f0f9f0; }}
        .test-fail {{ border-left-color: #dc3545; background-color: #fdf0f0; }}
        .test-warning {{ border-left-color: #ffc107; background-color: #fff9e6; }}
        .status-badge {{ display: inline-block; padding: 3px 8px; border-radius: 12px; font-size: 12px; font-weight: bold; }}
        .status-pass {{ background-color: #28a745; color: white; }}
        .status-fail {{ background-color: #dc3545; color: white; }}
        .recommendations {{ background-color: #fff3cd; padding: 15px; border-radius: 5px; margin-top: 20px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 Flutter港股投资应用测试报告</h1>
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
            <p><strong>测试时间:</strong> {test_result.get('timestamp', '未知')}</p>
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
            <p>测试报告自动生成 | Flutter港股投资应用 v1.0</p>
        </div>
    </div>
</body>
</html>
            """
            
            html_filename = f"test_report_{self.start_time.strftime('%Y%m%d_%H%M%S')}.html"
            html_filepath = os.path.join(report_dir, html_filename)
            
            with open(html_filepath, 'w', encoding='utf-8') as f:
                f.write(html_content)
            
            print(f"HTML测试报告已保存到: {html_filepath}")
            
        except Exception as e:
            print(f"生成HTML报告失败: {str(e)}")

def main():
    """主函数"""
    print("Flutter应用功能测试系统")
    print("=" * 50)
    
    # 创建测试器实例
    tester = FlutterAppTester(
        api_url="http://localhost:8001",
        project_dir=os.path.join(os.path.dirname(os.path.abspath(__file__)), "frontend")
    )
    
    # 运行全面测试
    tester.run_comprehensive_test()
    
    print("\n测试完成！")

if __name__ == "__main__":
    main()