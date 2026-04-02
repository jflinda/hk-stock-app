"""
性能优化的市场服务
整合增强型缓存，支持批量获取和智能重试
"""
import yfinance as yf
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple
import logging
import asyncio
import aiohttp
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

from .enhanced_cache import get_global_cache, CachePartitions

logger = logging.getLogger(__name__)

class OptimizedMarketService:
    """
    优化的市场数据服务
    
    特性：
    1. 增强型缓存（内存+持久化）
    2. 批量获取股票数据
    3. 智能重试机制
    4. 异步数据获取
    5. 性能监控
    """
    
    # 市场指数配置
    INDICES = {
        "HSI":    "^HSI",
        "HSCEI":  "^HSCE", 
        "HSTI":   "^HSTI",
        "SP500":  "^GSPC",
        "SSE":    "000001.SS",
    }
    
    # 热门港股列表
    POPULAR_STOCKS = [
        "0700.HK",  # 腾讯
        "9988.HK",  # 阿里巴巴
        "3690.HK",  # 美团
        "0005.HK",  # 汇丰银行
        "1299.HK",  # 友邦保险
        "2318.HK",  # 平安保险
        "0941.HK",  # 中国移动
        "0001.HK",  # 长和
        "0016.HK",  # 新鸿基
        "0011.HK",  # 恒生银行
    ]
    
    # 板块配置
    SECTORS = {
        "金融": ["0005.HK", "1299.HK", "2318.HK", "2388.HK", "3968.HK"],
        "科技": ["0700.HK", "9988.HK", "3690.HK", "1810.HK", "9618.HK"],
        "地产": ["0016.HK", "1109.HK", "0688.HK", "0011.HK", "1113.HK"],
        "能源": ["0386.HK", "0857.HK", "0883.HK", "1171.HK", "1357.HK"],
        "消费": ["2020.HK", "2319.HK", "1044.HK", "0322.HK", "3331.HK"],
        "工业": ["3800.HK", "1138.HK", "0683.HK", "2688.HK", "2338.HK"],
        "医疗": ["1093.HK", "2269.HK", "1177.HK", "1530.HK", "1951.HK"],
        "公用事业": ["0002.HK", "0003.HK", "0006.HK", "0836.HK", "2638.HK"],
    }
    
    def __init__(self):
        self.cache = get_global_cache()
        self.performance_stats = {
            "api_calls": 0,
            "cache_hits": 0,
            "cache_misses": 0,
            "total_response_time": 0.0,
            "errors": 0,
            "last_reset": datetime.now().isoformat()
        }
        
        # 线程池用于并行获取数据
        self.executor = ThreadPoolExecutor(max_workers=10)
        
        logger.info("性能优化的市场服务已初始化")
    
    def _update_stats(self, cache_hit: bool, response_time: float = 0.0, error: bool = False):
        """更新性能统计"""
        self.performance_stats["api_calls"] += 1
        if cache_hit:
            self.performance_stats["cache_hits"] += 1
        else:
            self.performance_stats["cache_misses"] += 1
        
        self.performance_stats["total_response_time"] += response_time
        
        if error:
            self.performance_stats["errors"] += 1
    
    def _get_cached_or_fetch(self, key: str, partition: str, fetch_func, ttl: int = 300, force_refresh: bool = False):
        """
        通用缓存获取或获取新数据
        
        Args:
            key: 缓存键
            partition: 缓存分区
            fetch_func: 获取数据的函数
            ttl: 缓存有效期（秒）
            force_refresh: 是否强制刷新缓存
        
        Returns:
            数据
        """
        start_time = time.time()
        
        # 如果强制刷新，先删除缓存
        if force_refresh:
            self.cache.delete(key, partition)
        
        # 尝试从缓存获取
        cached_data = self.cache.get(key, partition)
        
        if cached_data is not None:
            self._update_stats(cache_hit=True, response_time=time.time() - start_time)
            logger.debug(f"缓存命中: {partition}/{key}")
            return cached_data
        
        # 缓存未命中，获取新数据
        logger.debug(f"缓存未命中: {partition}/{key}，获取新数据...")
        
        try:
            data = fetch_func()
            if data is not None:
                # 保存到缓存
                self.cache.set(key, data, partition, ttl)
                
                response_time = time.time() - start_time
                self._update_stats(cache_hit=False, response_time=response_time)
                logger.debug(f"数据获取成功并缓存: {partition}/{key}，耗时: {response_time:.2f}s")
                return data
            else:
                self._update_stats(cache_hit=False, response_time=time.time() - start_time, error=True)
                logger.warning(f"数据获取返回None: {partition}/{key}")
                return None
                
        except Exception as e:
            self._update_stats(cache_hit=False, response_time=time.time() - start_time, error=True)
            logger.error(f"数据获取失败 {partition}/{key}: {e}")
            return None
    
    def get_indices(self, force_refresh: bool = False) -> List[Dict[str, Any]]:
        """
        获取市场指数数据
        
        Args:
            force_refresh: 是否强制刷新缓存
        
        Returns:
            指数数据列表
        """
        cache_key = "all_indices"
        
        def fetch_indices():
            """获取指数数据的实际函数"""
            indices_data = []
            
            # 尝试批量获取（yfinance支持批量）
            try:
                # 使用yfinance批量获取
                symbols = list(self.INDICES.values())
                tickers = yf.Tickers(" ".join(symbols))
                
                for name, symbol in self.INDICES.items():
                    try:
                        ticker = tickers.tickers[symbol]
                        
                        # 获取最新数据
                        info = ticker.info
                        hist = ticker.history(period="2d")
                        
                        if not hist.empty and len(hist) >= 2:
                            current_close = hist.iloc[-1]["Close"]
                            prev_close = hist.iloc[-2]["Close"]
                            
                            change = current_close - prev_close
                            change_pct = (change / prev_close) * 100
                            
                            indices_data.append({
                                "name": name,
                                "symbol": symbol,
                                "price": round(float(current_close), 2),
                                "change": round(float(change), 2),
                                "change_pct": round(float(change_pct), 2),
                                "volume": int(hist.iloc[-1]["Volume"]),
                                "timestamp": datetime.now().isoformat()
                            })
                        else:
                            # 如果数据不足，使用默认值
                            indices_data.append({
                                "name": name,
                                "symbol": symbol,
                                "price": 0.0,
                                "change": 0.0,
                                "change_pct": 0.0,
                                "volume": 0,
                                "timestamp": datetime.now().isoformat(),
                                "error": "数据不足"
                            })
                            
                    except Exception as e:
                        logger.error(f"获取指数 {name} ({symbol}) 失败: {e}")
                        indices_data.append({
                            "name": name,
                            "symbol": symbol,
                            "price": 0.0,
                            "change": 0.0,
                            "change_pct": 0.0,
                            "volume": 0,
                            "timestamp": datetime.now().isoformat(),
                            "error": str(e)[:100]
                        })
                        
            except Exception as e:
                logger.error(f"批量获取指数失败: {e}")
                # 回退到单独获取
                for name, symbol in self.INDICES.items():
                    try:
                        ticker = yf.Ticker(symbol)
                        hist = ticker.history(period="2d")
                        
                        if not hist.empty and len(hist) >= 2:
                            current_close = hist.iloc[-1]["Close"]
                            prev_close = hist.iloc[-2]["Close"]
                            
                            change = current_close - prev_close
                            change_pct = (change / prev_close) * 100
                            
                            indices_data.append({
                                "name": name,
                                "symbol": symbol,
                                "price": round(float(current_close), 2),
                                "change": round(float(change), 2),
                                "change_pct": round(float(change_pct), 2),
                                "volume": int(hist.iloc[-1]["Volume"]),
                                "timestamp": datetime.now().isoformat()
                            })
                    except Exception as e2:
                        logger.error(f"单独获取指数 {name} 失败: {e2}")
                        indices_data.append({
                            "name": name,
                            "symbol": symbol,
                            "price": 0.0,
                            "change": 0.0,
                            "change_pct": 0.0,
                            "volume": 0,
                            "timestamp": datetime.now().isoformat(),
                            "error": str(e2)[:100]
                        })
            
            return indices_data
        
        # 使用缓存获取
        return self._get_cached_or_fetch(
            cache_key, 
            CachePartitions.MARKET_INDICES, 
            fetch_indices, 
            ttl=60,  # 指数数据1分钟缓存
            force_refresh=force_refresh
        )
    
    def get_stock_quote(self, symbol: str, force_refresh: bool = False) -> Optional[Dict[str, Any]]:
        """
        获取单只股票行情
        
        Args:
            symbol: 股票代码
            force_refresh: 是否强制刷新缓存
        
        Returns:
            股票行情数据
        """
        cache_key = f"quote_{symbol}"
        
        def fetch_stock_quote():
            """获取股票行情的实际函数"""
            try:
                ticker = yf.Ticker(symbol)
                
                # 获取基本信息
                info = ticker.info
                
                # 获取历史数据计算涨跌
                hist = ticker.history(period="2d")
                
                if hist.empty or len(hist) < 2:
                    logger.warning(f"股票 {symbol} 历史数据不足")
                    return None
                
                # 当前价格和涨跌
                current_price = hist.iloc[-1]["Close"]
                prev_close = hist.iloc[-2]["Close"]
                
                change = current_price - prev_close
                change_pct = (change / prev_close) * 100
                
                # 获取52周高低
                hist_1y = ticker.history(period="1y")
                
                week_52_high = float(hist_1y["High"].max()) if not hist_1y.empty else 0.0
                week_52_low = float(hist_1y["Low"].min()) if not hist_1y.empty else 0.0
                
                # 构建返回数据
                quote_data = {
                    "symbol": symbol,
                    "name": info.get("longName", info.get("shortName", symbol)),
                    "current_price": round(float(current_price), 2),
                    "prev_close": round(float(prev_close), 2),
                    "change": round(float(change), 2),
                    "change_percent": round(float(change_pct), 2),
                    "volume": int(hist.iloc[-1]["Volume"]),
                    "market_cap": info.get("marketCap", 0),
                    "pe_ratio": info.get("trailingPE", 0.0),
                    "dividend_yield": info.get("dividendYield", 0.0),
                    "week_52_high": round(week_52_high, 2),
                    "week_52_low": round(week_52_low, 2),
                    "currency": info.get("currency", "HKD"),
                    "exchange": info.get("exchange", "HKG"),
                    "last_updated": datetime.now().isoformat()
                }
                
                return quote_data
                
            except Exception as e:
                logger.error(f"获取股票行情 {symbol} 失败: {e}")
                return None
        
        # 使用缓存获取
        return self._get_cached_or_fetch(
            cache_key,
            CachePartitions.STOCK_QUOTE,
            fetch_stock_quote,
            ttl=30,  # 行情数据30秒缓存
            force_refresh=force_refresh
        )
    
    def get_multiple_stock_quotes(self, symbols: List[str], force_refresh: bool = False) -> Dict[str, Dict[str, Any]]:
        """
        批量获取多只股票行情
        
        Args:
            symbols: 股票代码列表
            force_refresh: 是否强制刷新缓存
        
        Returns:
            股票行情字典，键为股票代码
        """
        if not symbols:
            return {}
        
        # 去重
        symbols = list(set(symbols))
        
        result = {}
        missing_symbols = []
        
        # 首先检查缓存
        for symbol in symbols:
            cache_key = f"quote_{symbol}"
            cached_data = None if force_refresh else self.cache.get(cache_key, CachePartitions.STOCK_QUOTE)
            
            if cached_data is not None:
                result[symbol] = cached_data
                self._update_stats(cache_hit=True)
            else:
                missing_symbols.append(symbol)
        
        # 如果没有缺失的数据，直接返回
        if not missing_symbols:
            return result
        
        # 批量获取缺失的数据
        logger.info(f"批量获取 {len(missing_symbols)} 只股票行情...")
        
        # 使用线程池并行获取
        futures = {}
        for symbol in missing_symbols:
            future = self.executor.submit(self.get_stock_quote, symbol, True)  # 强制刷新
            futures[future] = symbol
        
        # 等待所有结果
        for future in as_completed(futures):
            symbol = futures[future]
            try:
                data = future.result(timeout=10)
                if data is not None:
                    result[symbol] = data
                else:
                    logger.warning(f"股票 {symbol} 获取结果为空")
            except Exception as e:
                logger.error(f"获取股票 {symbol} 失败: {e}")
        
        return result
    
    def get_stock_history(self, symbol: str, period: str = "1mo", force_refresh: bool = False) -> List[Dict[str, Any]]:
        """
        获取股票历史数据（K线）
        
        Args:
            symbol: 股票代码
            period: 期间（1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, ytd, max）
            force_refresh: 是否强制刷新缓存
        
        Returns:
            历史数据列表
        """
        cache_key = f"history_{symbol}_{period}"
        
        # 不同期间设置不同的缓存时间
        period_ttl_map = {
            "1d": 30,     # 1天数据缓存30秒
            "5d": 60,     # 5天数据缓存1分钟
            "1mo": 300,   # 1个月数据缓存5分钟
            "3mo": 600,   # 3个月数据缓存10分钟
            "6mo": 1800,  # 6个月数据缓存30分钟
            "1y": 3600,   # 1年数据缓存1小时
            "2y": 7200,   # 2年数据缓存2小时
            "5y": 14400,  # 5年数据缓存4小时
            "ytd": 3600,  # 年初至今缓存1小时
            "max": 86400, # 最大期间缓存1天
        }
        
        ttl = period_ttl_map.get(period, 300)  # 默认5分钟
        
        def fetch_stock_history():
            """获取股票历史数据的实际函数"""
            try:
                ticker = yf.Ticker(symbol)
                hist = ticker.history(period=period)
                
                if hist.empty:
                    logger.warning(f"股票 {symbol} 历史数据为空")
                    return []
                
                # 计算移动平均线
                hist['MA5'] = hist['Close'].rolling(window=5).mean()
                hist['MA20'] = hist['Close'].rolling(window=20).mean()
                
                # 转换为列表格式
                history_data = []
                for idx, row in hist.iterrows():
                    # 处理时间戳
                    if isinstance(idx, pd.Timestamp):
                        timestamp = idx.isoformat()
                    else:
                        timestamp = str(idx)
                    
                    history_data.append({
                        "date": timestamp,
                        "open": round(float(row.get("Open", 0)), 2),
                        "high": round(float(row.get("High", 0)), 2),
                        "low": round(float(row.get("Low", 0)), 2),
                        "close": round(float(row.get("Close", 0)), 2),
                        "volume": int(row.get("Volume", 0)),
                        "ma5": round(float(row.get("MA5", 0)), 2) if not pd.isna(row.get("MA5")) else None,
                        "ma20": round(float(row.get("MA20", 0)), 2) if not pd.isna(row.get("MA20")) else None,
                    })
                
                return history_data
                
            except Exception as e:
                logger.error(f"获取股票历史数据 {symbol} ({period}) 失败: {e}")
                return []
        
        # 使用缓存获取
        return self._get_cached_or_fetch(
            cache_key,
            CachePartitions.STOCK_HISTORY,
            fetch_stock_history,
            ttl=ttl,
            force_refresh=force_refresh
        )
    
    def get_sectors_data(self, force_refresh: bool = False) -> List[Dict[str, Any]]:
        """
        获取板块数据
        
        Args:
            force_refresh: 是否强制刷新缓存
        
        Returns:
            板块数据列表
        """
        cache_key = "all_sectors"
        
        def fetch_sectors_data():
            """获取板块数据的实际函数"""
            sectors_data = []
            
            # 为每个板块创建一个获取任务
            futures = {}
            for sector_name, stocks in self.SECTORS.items():
                # 只取前3只股票作为代表
                representative_stocks = stocks[:3]
                future = self.executor.submit(self._get_sector_performance, sector_name, representative_stocks)
                futures[future] = sector_name
            
            # 收集结果
            for future in as_completed(futures):
                sector_name = futures[future]
                try:
                    sector_data = future.result(timeout=5)
                    if sector_data is not None:
                        sectors_data.append(sector_data)
                except Exception as e:
                    logger.error(f"获取板块 {sector_name} 数据失败: {e}")
            
            # 按涨跌幅排序
            sectors_data.sort(key=lambda x: x.get("change_percent", 0), reverse=True)
            
            return sectors_data
        
        # 使用缓存获取
        return self._get_cached_or_fetch(
            cache_key,
            CachePartitions.SECTOR_DATA,
            fetch_sectors_data,
            ttl=300,  # 板块数据5分钟缓存
            force_refresh=force_refresh
        )
    
    def _get_sector_performance(self, sector_name: str, stocks: List[str]) -> Optional[Dict[str, Any]]:
        """
        获取单个板块表现
        
        Args:
            sector_name: 板块名称
            stocks: 板块内股票列表
        
        Returns:
            板块数据
        """
        try:
            # 获取板块内股票数据
            quotes = self.get_multiple_stock_quotes(stocks)
            
            if not quotes:
                return None
            
            # 计算板块平均涨跌幅
            changes = []
            total_market_cap = 0
            
            for symbol, quote in quotes.items():
                if quote and "change_percent" in quote:
                    changes.append(quote["change_percent"])
                    total_market_cap += quote.get("market_cap", 0)
            
            if not changes:
                return None
            
            avg_change = sum(changes) / len(changes)
            
            # 确定板块颜色（用于热力图）
            if avg_change >= 2.0:
                color_intensity = 3  # 强上涨
            elif avg_change >= 0.5:
                color_intensity = 2  # 中上涨
            elif avg_change > 0:
                color_intensity = 1  # 弱上涨
            elif avg_change > -0.5:
                color_intensity = -1  # 弱下跌
            elif avg_change > -2.0:
                color_intensity = -2  # 中下跌
            else:
                color_intensity = -3  # 强下跌
            
            return {
                "name": sector_name,
                "change_percent": round(float(avg_change), 2),
                "color_intensity": color_intensity,
                "stocks": [
                    {
                        "symbol": symbol,
                        "name": quote.get("name", symbol),
                        "price": quote.get("current_price", 0),
                        "change_percent": quote.get("change_percent", 0)
                    }
                    for symbol, quote in quotes.items() if quote
                ][:10],  # 最多显示10只股票
                "total_market_cap": total_market_cap,
                "stock_count": len(quotes),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"计算板块 {sector_name} 表现失败: {e}")
            return None
    
    def get_movers(self, mover_type: str = "gainers", limit: int = 10, force_refresh: bool = False) -> List[Dict[str, Any]]:
        """
        获取涨跌幅榜
        
        Args:
            mover_type: gainers（涨幅榜）, losers（跌幅榜）, volume（成交额榜）
            limit: 返回数量
            force_refresh: 是否强制刷新缓存
        
        Returns:
            涨跌幅榜列表
        """
        cache_key = f"movers_{mover_type}_{limit}"
        
        def fetch_movers():
            """获取涨跌幅榜的实际函数"""
            # 获取热门股票数据
            quotes = self.get_multiple_stock_quotes(self.POPULAR_STOCKS, True)  # 强制刷新
            
            if not quotes:
                return []
            
            # 过滤有效数据
            valid_quotes = []
            for symbol, quote in quotes.items():
                if quote and "change_percent" in quote and "current_price" in quote:
                    valid_quotes.append((symbol, quote))
            
            if not valid_quotes:
                return []
            
            # 根据类型排序
            if mover_type == "gainers":
                # 涨幅榜：按涨幅降序
                sorted_quotes = sorted(valid_quotes, key=lambda x: x[1]["change_percent"], reverse=True)
            elif mover_type == "losers":
                # 跌幅榜：按涨幅升序
                sorted_quotes = sorted(valid_quotes, key=lambda x: x[1]["change_percent"])
            elif mover_type == "volume":
                # 成交额榜：需要计算成交额（价格×成交量）
                sorted_quotes = []
                for symbol, quote in valid_quotes:
                    price = quote.get("current_price", 0)
                    volume = quote.get("volume", 0)
                    turnover = price * volume if price and volume else 0
                    sorted_quotes.append((symbol, {**quote, "turnover": turnover}))
                
                sorted_quotes = sorted(sorted_quotes, key=lambda x: x[1].get("turnover", 0), reverse=True)
            else:
                return []
            
            # 格式化和限制数量
            movers = []
            for i, (symbol, quote) in enumerate(sorted_quotes[:limit]):
                movers.append({
                    "rank": i + 1,
                    "symbol": symbol,
                    "name": quote.get("name", symbol),
                    "price": quote.get("current_price", 0),
                    "change": quote.get("change", 0),
                    "change_percent": quote.get("change_percent", 0),
                    "volume": quote.get("volume", 0),
                    "market_cap": quote.get("market_cap", 0),
                    "timestamp": datetime.now().isoformat()
                })
            
            return movers
        
        # 使用缓存获取
        return self._get_cached_or_fetch(
            cache_key,
            CachePartitions.MOVERS_DATA,
            fetch_movers,
            ttl=60,  # 涨跌幅榜1分钟缓存
            force_refresh=force_refresh
        )
    
    def get_performance_stats(self) -> Dict[str, Any]:
        """
        获取服务性能统计
        
        Returns:
            性能统计信息
        """
        # 获取缓存统计
        cache_stats = self.cache.get_stats()
        
        # 计算平均响应时间
        total_calls = self.performance_stats["api_calls"]
        total_time = self.performance_stats["total_response_time"]
        
        avg_response_time = total_time / total_calls if total_calls > 0 else 0
        
        # 计算缓存命中率
        hits = self.performance_stats["cache_hits"]
        misses = self.performance_stats["cache_misses"]
        
        hit_rate = hits / (hits + misses) * 100 if (hits + misses) > 0 else 0
        
        return {
            "performance": {
                "total_api_calls": total_calls,
                "cache_hits": hits,
                "cache_misses": misses,
                "cache_hit_rate_percent": round(hit_rate, 2),
                "average_response_time_ms": round(avg_response_time * 1000, 2),
                "total_errors": self.performance_stats["errors"],
                "error_rate_percent": round(self.performance_stats["errors"] / max(total_calls, 1) * 100, 2),
                "last_reset": self.performance_stats["last_reset"],
                "current_time": datetime.now().isoformat()
            },
            "cache": cache_stats,
            "thread_pool": {
                "max_workers": self.executor._max_workers,
                "active_threads": len([t for t in self.executor._threads if t.is_alive()]) if hasattr(self.executor, '_threads') else 0
            }
        }
    
    def reset_stats(self):
        """重置性能统计"""
        self.performance_stats = {
            "api_calls": 0,
            "cache_hits": 0,
            "cache_misses": 0,
            "total_response_time": 0.0,
            "errors": 0,
            "last_reset": datetime.now().isoformat()
        }
        logger.info("性能统计已重置")
    
    def cleanup_old_cache(self, days_old: int = 7) -> int:
        """
        清理旧缓存数据
        
        Args:
            days_old: 天数
        
        Returns:
            删除的条目数
        """
        try:
            deleted_count = self.cache.cleanup_old_data(days_old)
            logger.info(f"清理了 {deleted_count} 个 {days_old} 天前的缓存条目")
            return deleted_count
        except Exception as e:
            logger.error(f"清理旧缓存失败: {e}")
            return 0


# 全局服务实例
_global_service: Optional[OptimizedMarketService] = None

def get_global_service() -> OptimizedMarketService:
    """获取全局服务实例"""
    global _global_service
    if _global_service is None:
        _global_service = OptimizedMarketService()
    return _global_service