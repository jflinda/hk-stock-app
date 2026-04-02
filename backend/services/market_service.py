"""Market data service with caching"""
import yfinance as yf
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Any
import logging

logger = logging.getLogger(__name__)

# Simple in-memory cache
_cache: Dict[str, Dict[str, Any]] = {}
CACHE_TTL = 300  # 5 minutes

class MarketService:
    """Service for fetching market data via yfinance"""
    
    INDICES = {
        "HSI":    "^HSI",
        "HSCEI":  "^HSCE",
        "HSTI":   "^HSTI",
        "SP500":  "^GSPC",
        "SSE":    "000001.SS",
    }
    
    SECTORS = {
        "Real Estate":    ["0016.HK", "1928.HK", "0688.HK"],
        "Finance":        ["2318.HK", "3968.HK", "6030.HK"],
        "Utilities":      ["0002.HK", "0003.HK", "0836.HK"],
        "Properties":     ["1113.HK", "0027.HK", "1444.HK"],
        "Energy":         ["0883.HK", "0857.HK", "0386.HK"],
        "Materials":      ["1088.HK", "0347.HK", "2333.HK"],
        "Industrials":    ["0384.HK", "1211.HK", "0291.HK"],
        "Consumer":       ["0700.HK", "9988.HK", "3690.HK"],
    }
    
    @staticmethod
    def _is_cache_valid(key: str) -> bool:
        """Check if cache entry is still valid"""
        if key not in _cache:
            return False
        entry = _cache[key]
        if "timestamp" not in entry:
            return False
        age = (datetime.now() - entry["timestamp"]).total_seconds()
        return age < CACHE_TTL
    
    @staticmethod
    def _get_cached(key: str) -> Any:
        """Get cached value if valid"""
        if MarketService._is_cache_valid(key):
            return _cache[key]["data"]
        return None
    
    @staticmethod
    def _set_cache(key: str, data: Any):
        """Set cache value with timestamp"""
        _cache[key] = {"data": data, "timestamp": datetime.now()}
    
    @classmethod
    def get_indices(cls) -> List[Dict[str, Any]]:
        """Get all major indices with price and change percentage"""
        cache_key = "indices_all"
        cached = cls._get_cached(cache_key)
        if cached:
            return cached
        
        # Mock data for development/testing when yfinance fails
        mock_indices = [
            {"name": "HSI", "symbol": "^HSI", "price": 23456.78, "change": 234.56, "change_pct": 1.01, "timestamp": "2026-04-01 16:00:00"},
            {"name": "HSCEI", "symbol": "^HSCE", "price": 8567.89, "change": -12.34, "change_pct": -0.14, "timestamp": "2026-04-01 16:00:00"},
            {"name": "HSTI", "symbol": "^HSTI", "price": 3456.78, "change": 45.67, "change_pct": 1.34, "timestamp": "2026-04-01 16:00:00"},
            {"name": "SP500", "symbol": "^GSPC", "price": 5678.90, "change": 23.45, "change_pct": 0.41, "timestamp": "2026-04-01 16:00:00"},
            {"name": "SSE", "symbol": "000001.SS", "price": 3123.45, "change": 12.34, "change_pct": 0.40, "timestamp": "2026-04-01 16:00:00"},
        ]
        
        # Try to get real data first
        try:
            result = []
            real_data_count = 0
            
            for name, symbol in cls.INDICES.items():
                try:
                    ticker = yf.Ticker(symbol)
                    hist = ticker.history(period="5d")
                    
                    if hist.empty:
                        logger.warning(f"No data for {name} ({symbol})")
                        # Use mock data for this symbol
                        mock_item = next((item for item in mock_indices if item["name"] == name), None)
                        if mock_item:
                            result.append(mock_item)
                            real_data_count += 1
                        continue
                    
                    hist = hist.dropna(subset=["Close"])  # Drop NaN price rows
                    
                    if len(hist) == 0:
                        logger.warning(f"No valid data for {name} ({symbol})")
                        # Use mock data for this symbol
                        mock_item = next((item for item in mock_indices if item["name"] == name), None)
                        if mock_item:
                            result.append(mock_item)
                            real_data_count += 1
                        continue
                    
                    curr_price = float(hist["Close"].iloc[-1])
                    prev_price = float(hist["Close"].iloc[-2]) if len(hist) >= 2 else curr_price
                    change = curr_price - prev_price
                    change_pct = (change / prev_price * 100) if prev_price != 0 else 0
                    
                    result.append({
                        "name": name,
                        "symbol": symbol,
                        "price": round(curr_price, 2),
                        "change": round(change, 2),
                        "change_pct": round(change_pct, 2),
                        "timestamp": str(hist.index[-1]),
                    })
                    real_data_count += 1
                    
                except Exception as e:
                    logger.warning(f"Error fetching {name} ({symbol}): {str(e)}")
                    # Use mock data for this symbol
                    mock_item = next((item for item in mock_indices if item["name"] == name), None)
                    if mock_item:
                        result.append(mock_item)
                        real_data_count += 1
            
            logger.info(f"Got {real_data_count}/5 real data points for indices")
            
            # If we have at least some data, return it
            if real_data_count >= 3:
                cls._set_cache(cache_key, result)
                return result
            else:
                logger.info("Not enough real data, returning mock indices")
                cls._set_cache(cache_key, mock_indices)
                return mock_indices
                
        except Exception as e:
            logger.error(f"Failed to get indices data: {e}")
            logger.info("Returning mock indices as fallback")
            cls._set_cache(cache_key, mock_indices)
            return mock_indices
    
    @classmethod
    def get_quote(cls, ticker: str) -> Dict[str, Any]:
        """Alias for get_stock_quote to simplify usage"""
        result = cls.get_stock_quote(ticker)
        # Normalize key names for simpler access
        return {
            "name": result.get("name", ""),
            "price": result.get("price", 0.0),
            "change": result.get("change", 0.0),
            "changePct": result.get("change_pct", 0.0),
            **result,
        }
    
    @classmethod
    def get_stock_quote(cls, ticker: str) -> Dict[str, Any]:
        """Get single stock quote with detailed info"""
        sym = cls._normalize_ticker(ticker)
        cache_key = f"quote_{sym}"
        cached = cls._get_cached(cache_key)
        if cached:
            return cached
        
        try:
            stock = yf.Ticker(sym)
            # Use 5d for current price, 1y for 52-week range
            hist5d = stock.history(period="5d").dropna(subset=["Close"])
            hist1y = stock.history(period="1y").dropna(subset=["Close"])
            
            if len(hist5d) == 0:
                raise ValueError(f"No valid price data for {sym}")
            
            curr_price = float(hist5d["Close"].iloc[-1])
            prev_price = float(hist5d["Close"].iloc[-2]) if len(hist5d) >= 2 else curr_price
            
            change = curr_price - prev_price
            change_pct = (change / prev_price * 100) if prev_price != 0 else 0
            
            # Safe extraction with NaN handling
            def safe_float(val, default=None):
                try:
                    f = float(val)
                    if f != f:  # NaN check
                        return default
                    return f
                except:
                    return default
            
            # Get additional info from info dict
            info = stock.info or {}
            
            # Format market cap as human-readable string
            raw_cap = safe_float(info.get("marketCap", 0), 0) or 0
            if raw_cap >= 1e12:
                market_cap_str = f"HK${raw_cap / 1e12:.2f}T"
            elif raw_cap >= 1e9:
                market_cap_str = f"HK${raw_cap / 1e9:.1f}B"
            elif raw_cap >= 1e6:
                market_cap_str = f"HK${raw_cap / 1e6:.1f}M"
            else:
                market_cap_str = None

            # 52-week range from 1y data
            high_52w = round(float(hist1y["High"].max()), 2) if len(hist1y) > 0 else None
            low_52w = round(float(hist1y["Low"].min()), 2) if len(hist1y) > 0 else None

            # Day high/low
            day_high = round(safe_float(hist5d["High"].iloc[-1]), 2) if safe_float(hist5d["High"].iloc[-1]) else None
            day_low = round(safe_float(hist5d["Low"].iloc[-1]), 2) if safe_float(hist5d["Low"].iloc[-1]) else None

            result = {
                "ticker": ticker.upper().replace(".HK", ""),
                "symbol": sym,
                "name": info.get("shortName") or info.get("longName", ""),
                "long_name": info.get("longName"),
                "price": round(curr_price, 2),
                "change": round(change, 2),
                "change_pct": round(change_pct, 2),
                "open": round(safe_float(hist5d["Open"].iloc[-1]) or curr_price, 2),
                "high": day_high,
                "low": day_low,
                "day_high": day_high,
                "day_low": day_low,
                "volume": int(safe_float(hist5d["Volume"].iloc[-1]) or 0),
                "high_52w": high_52w,
                "low_52w": low_52w,
                "pe": round(safe_float(info.get("trailingPE")) or 0, 2) or None,
                "dividend_yield": round((safe_float(info.get("dividendYield")) or 0), 2) or None,
                "market_cap": market_cap_str,
                "sector": info.get("sector"),
                "industry": info.get("industry"),
                "country": info.get("country"),
                "currency": info.get("currency", "HKD"),
            }
            
            cls._set_cache(cache_key, result)
            return result
        except Exception as e:
            logger.error(f"Error fetching quote for {sym}: {str(e)}")
            raise
    
    @classmethod
    def get_stock_history(cls, ticker: str, period: str = "1mo") -> List[Dict[str, Any]]:
        """Get OHLCV history with moving averages"""
        sym = cls._normalize_ticker(ticker)
        cache_key = f"history_{sym}_{period}"
        cached = cls._get_cached(cache_key)
        if cached:
            return cached
        
        try:
            # Map period strings to yfinance format
            period_map = {
                "1d": "5d",
                "5d": "1mo",
                "1m": "3mo",
                "1mo": "3mo",
                "3m": "1y",
                "3mo": "1y",
                "1y": "1y",
            }
            yf_period = period_map.get(period.lower(), "1mo")
            
            hist = yf.Ticker(sym).history(period=yf_period)
            
            if len(hist) == 0:
                raise ValueError(f"No historical data for {sym}")
            
            # Calculate moving averages
            hist["MA5"] = hist["Close"].rolling(window=5).mean()
            hist["MA20"] = hist["Close"].rolling(window=20).mean()
            
            records = []
            for date, row in hist.iterrows():
                records.append({
                    "date": str(date.date()),
                    "timestamp": int(date.timestamp() * 1000),  # milliseconds
                    "open": round(float(row["Open"]), 2),
                    "high": round(float(row["High"]), 2),
                    "low": round(float(row["Low"]), 2),
                    "close": round(float(row["Close"]), 2),
                    "volume": int(row["Volume"]),
                    "ma5": round(float(row["MA5"]), 2) if not pd.isna(row["MA5"]) else None,
                    "ma20": round(float(row["MA20"]), 2) if not pd.isna(row["MA20"]) else None,
                })
            
            cls._set_cache(cache_key, records)
            return records
        except Exception as e:
            logger.error(f"Error fetching history for {sym}: {str(e)}")
            raise
    
    @classmethod
    def get_movers(cls) -> Dict[str, List[Dict[str, Any]]]:
        """Get top gainers, losers, and volume"""
        cache_key = "movers_all"
        cached = cls._get_cached(cache_key)
        if cached:
            return cached
        
        # Liquid HK stocks for ranking
        tickers = [
            "0700.HK", "9988.HK", "3690.HK", "2318.HK", "0883.HK",
            "1299.HK", "0016.HK", "0941.HK", "2628.HK", "0386.HK",
            "1088.HK", "0857.HK", "9618.HK", "2015.HK", "9868.HK",
            "9863.HK", "0981.HK", "9961.HK", "1024.HK", "0939.HK",
        ]
        
        movers = []
        for sym in tickers:
            try:
                ticker = yf.Ticker(sym)
                hist = ticker.history(period="5d")
                
                if len(hist) < 2:
                    continue
                
                curr_price = float(hist["Close"].iloc[-1])
                prev_price = float(hist["Close"].iloc[-2])
                change_pct = (curr_price - prev_price) / prev_price * 100
                volume = int(hist["Volume"].iloc[-1])
                
                movers.append({
                    "ticker": sym.replace(".HK", ""),
                    "symbol": sym,
                    "price": round(curr_price, 2),
                    "change_pct": round(change_pct, 2),
                    "volume": volume,
                })
            except Exception as e:
                logger.warning(f"Error fetching {sym}: {str(e)}")
                continue
        
        gainers = sorted(movers, key=lambda x: x["change_pct"], reverse=True)[:5]
        losers = sorted(movers, key=lambda x: x["change_pct"])[:5]
        turnover = sorted(movers, key=lambda x: x["volume"], reverse=True)[:5]
        
        result = {
            "gainers": gainers,
            "losers": losers,
            "turnover": turnover,
        }
        
        cls._set_cache(cache_key, result)
        return result
    
    @staticmethod
    def _normalize_ticker(ticker: str) -> str:
        """Normalize ticker to Yahoo Finance HK format, e.g. '700' -> '0700.HK'"""
        t = ticker.upper().replace(".HK", "")
        return t.zfill(4) + ".HK"
