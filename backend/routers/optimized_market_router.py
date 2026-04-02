"""
优化市场API路由
使用性能优化的市场服务
"""
from fastapi import APIRouter, HTTPException, Query, Depends
from typing import List, Dict, Any, Optional
import logging

from ..services.optimized_market_service import get_global_service
from ..services.enhanced_cache import get_global_cache

router = APIRouter(prefix="/api/v2/market", tags=["optimized-market"])
logger = logging.getLogger(__name__)

# 获取服务实例
service = get_global_service()
cache = get_global_cache()

@router.get("/indices")
async def get_indices(
    force_refresh: bool = Query(False, description="是否强制刷新缓存")
) -> List[Dict[str, Any]]:
    """
    获取市场指数数据（优化版）
    
    Args:
        force_refresh: 强制刷新缓存
    
    Returns:
        市场指数数据列表
    """
    try:
        indices = service.get_indices(force_refresh=force_refresh)
        if indices is None:
            raise HTTPException(status_code=503, detail="获取市场指数数据失败")
        return indices
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取市场指数失败: {e}")
        raise HTTPException(status_code=500, detail=f"获取市场指数失败: {str(e)}")

@router.get("/stock/{symbol}/quote")
async def get_stock_quote(
    symbol: str,
    force_refresh: bool = Query(False, description="是否强制刷新缓存")
) -> Dict[str, Any]:
    """
    获取单只股票行情（优化版）
    
    Args:
        symbol: 股票代码
        force_refresh: 强制刷新缓存
    
    Returns:
        股票行情数据
    """
    try:
        # 格式化股票代码
        symbol = symbol.upper()
        if not symbol.endswith(".HK"):
            symbol = f"{symbol}.HK"
        
        quote = service.get_stock_quote(symbol, force_refresh=force_refresh)
        if quote is None:
            raise HTTPException(status_code=404, detail=f"股票 {symbol} 未找到或数据不可用")
        return quote
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取股票行情 {symbol} 失败: {e}")
        raise HTTPException(status_code=500, detail=f"获取股票行情失败: {str(e)}")

@router.post("/stocks/quotes")
async def get_multiple_stock_quotes(
    symbols: List[str],
    force_refresh: bool = Query(False, description="是否强制刷新缓存")
) -> Dict[str, Dict[str, Any]]:
    """
    批量获取多只股票行情（优化版）
    
    Args:
        symbols: 股票代码列表
        force_refresh: 强制刷新缓存
    
    Returns:
        股票行情字典，键为股票代码
    """
    try:
        if not symbols:
            return {}
        
        # 格式化股票代码
        formatted_symbols = []
        for symbol in symbols:
            symbol = symbol.upper()
            if not symbol.endswith(".HK"):
                symbol = f"{symbol}.HK"
            formatted_symbols.append(symbol)
        
        quotes = service.get_multiple_stock_quotes(formatted_symbols, force_refresh=force_refresh)
        return quotes
    except Exception as e:
        logger.error(f"批量获取股票行情失败: {e}")
        raise HTTPException(status_code=500, detail=f"批量获取股票行情失败: {str(e)}")

@router.get("/stock/{symbol}/history")
async def get_stock_history(
    symbol: str,
    period: str = Query("1mo", description="期间: 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, ytd, max"),
    force_refresh: bool = Query(False, description="是否强制刷新缓存")
) -> List[Dict[str, Any]]:
    """
    获取股票历史数据（K线，优化版）
    
    Args:
        symbol: 股票代码
        period: 期间
        force_refresh: 强制刷新缓存
    
    Returns:
        历史数据列表
    """
    try:
        # 格式化股票代码
        symbol = symbol.upper()
        if not symbol.endswith(".HK"):
            symbol = f"{symbol}.HK"
        
        # 验证期间参数
        valid_periods = ["1d", "5d", "1mo", "3mo", "6mo", "1y", "2y", "5y", "ytd", "max"]
        if period not in valid_periods:
            raise HTTPException(status_code=400, detail=f"无效期间，可用值: {', '.join(valid_periods)}")
        
        history = service.get_stock_history(symbol, period, force_refresh=force_refresh)
        if not history:
            raise HTTPException(status_code=404, detail=f"股票 {symbol} 历史数据不可用")
        return history
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取股票历史数据 {symbol} ({period}) 失败: {e}")
        raise HTTPException(status_code=500, detail=f"获取历史数据失败: {str(e)}")

@router.get("/sectors")
async def get_sectors(
    force_refresh: bool = Query(False, description="是否强制刷新缓存")
) -> List[Dict[str, Any]]:
    """
    获取板块数据（优化版）
    
    Args:
        force_refresh: 强制刷新缓存
    
    Returns:
        板块数据列表
    """
    try:
        sectors = service.get_sectors_data(force_refresh=force_refresh)
        if sectors is None:
            raise HTTPException(status_code=503, detail="获取板块数据失败")
        return sectors
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取板块数据失败: {e}")
        raise HTTPException(status_code=500, detail=f"获取板块数据失败: {str(e)}")

@router.get("/movers/{mover_type}")
async def get_movers(
    mover_type: str,
    limit: int = Query(10, ge=1, le=50, description="返回数量限制"),
    force_refresh: bool = Query(False, description="是否强制刷新缓存")
) -> List[Dict[str, Any]]:
    """
    获取涨跌幅榜（优化版）
    
    Args:
        mover_type: 类型 (gainers, losers, volume)
        limit: 返回数量限制
        force_refresh: 强制刷新缓存
    
    Returns:
        涨跌幅榜列表
    """
    try:
        # 验证类型
        valid_types = ["gainers", "losers", "volume"]
        if mover_type not in valid_types:
            raise HTTPException(status_code=400, detail=f"无效类型，可用值: {', '.join(valid_types)}")
        
        movers = service.get_movers(mover_type, limit, force_refresh=force_refresh)
        if movers is None:
            raise HTTPException(status_code=503, detail="获取涨跌幅榜失败")
        return movers
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"获取涨跌幅榜 {mover_type} 失败: {e}")
        raise HTTPException(status_code=500, detail=f"获取涨跌幅榜失败: {str(e)}")

@router.get("/performance/stats")
async def get_performance_stats() -> Dict[str, Any]:
    """
    获取服务性能统计
    
    Returns:
        性能统计信息
    """
    try:
        stats = service.get_performance_stats()
        return stats
    except Exception as e:
        logger.error(f"获取性能统计失败: {e}")
        raise HTTPException(status_code=500, detail=f"获取性能统计失败: {str(e)}")

@router.post("/performance/reset")
async def reset_performance_stats() -> Dict[str, str]:
    """
    重置性能统计
    
    Returns:
        操作结果
    """
    try:
        service.reset_stats()
        return {"message": "性能统计已重置", "timestamp": service.performance_stats["last_reset"]}
    except Exception as e:
        logger.error(f"重置性能统计失败: {e}")
        raise HTTPException(status_code=500, detail=f"重置性能统计失败: {str(e)}")

@router.get("/cache/stats")
async def get_cache_stats() -> Dict[str, Any]:
    """
    获取缓存统计信息
    
    Returns:
        缓存统计信息
    """
    try:
        stats = cache.get_stats()
        return stats
    except Exception as e:
        logger.error(f"获取缓存统计失败: {e}")
        raise HTTPException(status_code=500, detail=f"获取缓存统计失败: {str(e)}")

@router.post("/cache/clear")
async def clear_cache(
    partition: Optional[str] = Query(None, description="缓存分区，如为空则清空所有")
) -> Dict[str, str]:
    """
    清空缓存
    
    Args:
        partition: 缓存分区
    
    Returns:
        操作结果
    """
    try:
        if partition:
            success = cache.clear(partition)
            if success:
                return {"message": f"缓存分区 '{partition}' 已清空"}
            else:
                raise HTTPException(status_code=500, detail=f"清空缓存分区 '{partition}' 失败")
        else:
            success = cache.clear()
            if success:
                return {"message": "所有缓存已清空"}
            else:
                raise HTTPException(status_code=500, detail="清空所有缓存失败")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"清空缓存失败: {e}")
        raise HTTPException(status_code=500, detail=f"清空缓存失败: {str(e)}")

@router.post("/cache/cleanup")
async def cleanup_cache(
    days_old: int = Query(7, ge=1, le=365, description="清理指定天数前的数据")
) -> Dict[str, Any]:
    """
    清理旧缓存数据
    
    Args:
        days_old: 天数
    
    Returns:
        清理结果
    """
    try:
        deleted_count = service.cleanup_old_cache(days_old)
        return {
            "message": f"清理了 {deleted_count} 个 {days_old} 天前的缓存条目",
            "deleted_count": deleted_count,
            "days_old": days_old
        }
    except Exception as e:
        logger.error(f"清理缓存失败: {e}")
        raise HTTPException(status_code=500, detail=f"清理缓存失败: {str(e)}")

@router.get("/health")
async def health_check() -> Dict[str, str]:
    """
    健康检查端点
    
    Returns:
        健康状态
    """
    try:
        # 简单测试服务是否正常
        indices = service.get_indices(force_refresh=False)
        if indices is not None and len(indices) > 0:
            return {
                "status": "healthy",
                "service": "optimized_market_service",
                "timestamp": service.performance_stats["last_reset"],
                "cache_hit_rate": f"{service.performance_stats['cache_hits'] / max(service.performance_stats['api_calls'], 1) * 100:.1f}%"
            }
        else:
            return {
                "status": "degraded",
                "service": "optimized_market_service",
                "message": "服务运行但数据获取可能有问题",
                "timestamp": service.performance_stats["last_reset"]
            }
    except Exception as e:
        logger.error(f"健康检查失败: {e}")
        raise HTTPException(status_code=503, detail=f"服务异常: {str(e)}")

@router.get("/status")
async def service_status() -> Dict[str, Any]:
    """
    获取服务详细状态
    
    Returns:
        服务状态信息
    """
    try:
        # 获取性能统计
        perf_stats = service.get_performance_stats()
        
        # 获取缓存统计
        cache_stats = cache.get_stats()
        
        # 获取市场指数状态
        indices_status = "healthy"
        try:
            indices = service.get_indices(force_refresh=False)
            indices_count = len(indices) if indices else 0
        except:
            indices_count = 0
            indices_status = "unavailable"
        
        # 获取板块状态
        sectors_status = "healthy"
        try:
            sectors = service.get_sectors_data(force_refresh=False)
            sectors_count = len(sectors) if sectors else 0
        except:
            sectors_count = 0
            sectors_status = "unavailable"
        
        return {
            "service": "optimized_market_service",
            "status": "running",
            "timestamp": datetime.now().isoformat(),
            "components": {
                "indices": {
                    "status": indices_status,
                    "count": indices_count
                },
                "sectors": {
                    "status": sectors_status,
                    "count": sectors_count
                },
                "cache": cache_stats,
                "performance": perf_stats.get("performance", {})
            },
            "thread_pool": {
                "max_workers": service.executor._max_workers,
                "active_tasks": len([t for t in service.executor._threads if t.is_alive()]) if hasattr(service.executor, '_threads') else 0
            }
        }
    except Exception as e:
        logger.error(f"获取服务状态失败: {e}")
        return {
            "service": "optimized_market_service",
            "status": "error",
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        }

# 导入datetime
from datetime import datetime