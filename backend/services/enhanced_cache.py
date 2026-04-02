"""
增强型缓存系统 - 支持内存缓存和持久化缓存
"""
import json
import pickle
import time
import threading
import sqlite3
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Union
import logging
import os

logger = logging.getLogger(__name__)

class EnhancedCache:
    """
    增强型缓存类，支持：
    1. 内存缓存（快速访问）
    2. SQLite持久化缓存（跨会话持久化）
    3. 缓存分区（不同类型数据）
    4. TTL过期机制
    5. 缓存统计和监控
    """
    
    def __init__(self, db_path: Optional[str] = None):
        # 内存缓存
        self.memory_cache: Dict[str, Dict[str, Any]] = {}
        
        # 持久化缓存数据库路径
        if db_path is None:
            base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            self.db_path = os.path.join(base_dir, "hkstock.db")
        else:
            self.db_path = db_path
        
        # 缓存锁
        self.lock = threading.RLock()
        
        # 初始化数据库
        self._init_database()
        
        # 缓存统计
        self.stats = {
            "hits": 0,
            "misses": 0,
            "sets": 0,
            "evictions": 0
        }
        
        # 缓存配置
        self.default_ttl = 300  # 5分钟
        self.memory_limit = 1000  # 内存缓存项限制
        
        logger.info(f"增强型缓存已初始化，数据库: {self.db_path}")
    
    def _init_database(self):
        """初始化缓存数据库"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # 创建缓存表
                cursor.execute('''
                CREATE TABLE IF NOT EXISTS cache_data (
                    key TEXT PRIMARY KEY,
                    partition TEXT NOT NULL,
                    value BLOB NOT NULL,
                    ttl_seconds INTEGER DEFAULT 300,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    last_accessed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    access_count INTEGER DEFAULT 0
                )
                ''')
                
                # 创建索引
                cursor.execute('CREATE INDEX IF NOT EXISTS idx_cache_partition ON cache_data(partition)')
                cursor.execute('CREATE INDEX IF NOT EXISTS idx_cache_created ON cache_data(created_at)')
                
                conn.commit()
                
        except Exception as e:
            logger.error(f"初始化缓存数据库失败: {e}")
    
    def _serialize_value(self, value: Any) -> bytes:
        """序列化缓存值"""
        try:
            return pickle.dumps(value)
        except Exception:
            # 如果pickle失败，尝试JSON序列化
            try:
                return json.dumps(value).encode('utf-8')
            except Exception as e:
                logger.error(f"缓存值序列化失败: {e}")
                raise
    
    def _deserialize_value(self, value_bytes: bytes) -> Any:
        """反序列化缓存值"""
        try:
            return pickle.loads(value_bytes)
        except Exception:
            # 如果pickle失败，尝试JSON反序列化
            try:
                return json.loads(value_bytes.decode('utf-8'))
            except Exception as e:
                logger.error(f"缓存值反序列化失败: {e}")
                raise
    
    def _clean_expired_entries(self):
        """清理过期的缓存条目"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # 删除内存中过期的条目
                now = datetime.now()
                expired_keys = []
                
                for key, entry in list(self.memory_cache.items()):
                    if "expires_at" in entry and now > entry["expires_at"]:
                        expired_keys.append(key)
                
                for key in expired_keys:
                    del self.memory_cache[key]
                    self.stats["evictions"] += 1
                
                # 删除数据库中过期的条目
                cursor.execute("DELETE FROM cache_data WHERE datetime(created_at, '+' || ttl_seconds || ' seconds') < datetime('now')")
                conn.commit()
                
        except Exception as e:
            logger.error(f"清理过期缓存失败: {e}")
    
    def _check_memory_limit(self):
        """检查内存缓存限制"""
        if len(self.memory_cache) > self.memory_limit:
            # 淘汰最旧的条目
            with self.lock:
                sorted_keys = sorted(
                    self.memory_cache.keys(),
                    key=lambda k: self.memory_cache[k].get("last_accessed", datetime.min)
                )
                
                # 淘汰20%的条目
                evict_count = max(1, len(self.memory_cache) // 5)
                for i in range(evict_count):
                    if i < len(sorted_keys):
                        key = sorted_keys[i]
                        del self.memory_cache[key]
                        self.stats["evictions"] += 1
    
    def get(self, key: str, partition: str = "default") -> Optional[Any]:
        """
        获取缓存值
        
        Args:
            key: 缓存键
            partition: 缓存分区
            
        Returns:
            缓存值或None
        """
        with self.lock:
            # 1. 首先检查内存缓存
            mem_key = f"{partition}:{key}"
            if mem_key in self.memory_cache:
                entry = self.memory_cache[mem_key]
                
                # 检查是否过期
                if "expires_at" in entry and datetime.now() > entry["expires_at"]:
                    del self.memory_cache[mem_key]
                    self.stats["evictions"] += 1
                else:
                    # 更新访问时间
                    self.memory_cache[mem_key]["last_accessed"] = datetime.now()
                    self.stats["hits"] += 1
                    return entry["value"]
            
            # 2. 检查持久化缓存
            try:
                with sqlite3.connect(self.db_path) as conn:
                    cursor = conn.cursor()
                    
                    cursor.execute('''
                    SELECT value, ttl_seconds, created_at 
                    FROM cache_data 
                    WHERE key = ? AND partition = ?
                    ''', (key, partition))
                    
                    row = cursor.fetchone()
                    
                    if row:
                        value_bytes, ttl_seconds, created_at = row
                        
                        # 检查是否过期
                        if isinstance(created_at, str):
                            created_dt = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                        else:
                            created_dt = created_at
                        
                        expires_at = created_dt + timedelta(seconds=ttl_seconds)
                        
                        if datetime.now() > expires_at:
                            # 删除过期条目
                            cursor.execute("DELETE FROM cache_data WHERE key = ? AND partition = ?", (key, partition))
                            conn.commit()
                            self.stats["misses"] += 1
                            return None
                        
                        # 反序列化值
                        value = self._deserialize_value(value_bytes)
                        
                        # 更新统计信息
                        cursor.execute('''
                        UPDATE cache_data 
                        SET last_accessed = datetime('now'), access_count = access_count + 1 
                        WHERE key = ? AND partition = ?
                        ''', (key, partition))
                        conn.commit()
                        
                        # 添加到内存缓存
                        self.memory_cache[mem_key] = {
                            "value": value,
                            "expires_at": expires_at,
                            "last_accessed": datetime.now()
                        }
                        
                        self._check_memory_limit()
                        self.stats["hits"] += 1
                        return value
                    else:
                        self.stats["misses"] += 1
                        return None
                        
            except Exception as e:
                logger.error(f"获取持久化缓存失败 {key}: {e}")
                self.stats["misses"] += 1
                return None
    
    def set(self, key: str, value: Any, partition: str = "default", ttl: Optional[int] = None) -> bool:
        """
        设置缓存值
        
        Args:
            key: 缓存键
            value: 缓存值
            partition: 缓存分区
            ttl: 缓存有效期（秒），默认使用default_ttl
        
        Returns:
            是否设置成功
        """
        with self.lock:
            try:
                # 设置TTL
                if ttl is None:
                    ttl = self.default_ttl
                
                expires_at = datetime.now() + timedelta(seconds=ttl)
                
                # 序列化值
                value_bytes = self._serialize_value(value)
                
                # 1. 保存到内存缓存
                mem_key = f"{partition}:{key}"
                self.memory_cache[mem_key] = {
                    "value": value,
                    "expires_at": expires_at,
                    "last_accessed": datetime.now()
                }
                
                self._check_memory_limit()
                
                # 2. 保存到持久化缓存
                with sqlite3.connect(self.db_path) as conn:
                    cursor = conn.cursor()
                    
                    # 插入或更新
                    cursor.execute('''
                    INSERT OR REPLACE INTO cache_data 
                    (key, partition, value, ttl_seconds, created_at, last_accessed, access_count)
                    VALUES (?, ?, ?, ?, datetime('now'), datetime('now'), 
                            COALESCE((SELECT access_count FROM cache_data WHERE key = ? AND partition = ?), 0) + 1)
                    ''', (key, partition, value_bytes, ttl, key, partition))
                    
                    conn.commit()
                
                self.stats["sets"] += 1
                return True
                
            except Exception as e:
                logger.error(f"设置缓存失败 {key}: {e}")
                return False
    
    def delete(self, key: str, partition: str = "default") -> bool:
        """
        删除缓存值
        
        Args:
            key: 缓存键
            partition: 缓存分区
        
        Returns:
            是否删除成功
        """
        with self.lock:
            try:
                # 1. 从内存缓存中删除
                mem_key = f"{partition}:{key}"
                if mem_key in self.memory_cache:
                    del self.memory_cache[mem_key]
                
                # 2. 从持久化缓存中删除
                with sqlite3.connect(self.db_path) as conn:
                    cursor = conn.cursor()
                    cursor.execute("DELETE FROM cache_data WHERE key = ? AND partition = ?", (key, partition))
                    conn.commit()
                
                return True
                
            except Exception as e:
                logger.error(f"删除缓存失败 {key}: {e}")
                return False
    
    def clear(self, partition: Optional[str] = None) -> bool:
        """
        清空缓存
        
        Args:
            partition: 可选分区，如为None则清空所有
        
        Returns:
            是否清空成功
        """
        with self.lock:
            try:
                # 1. 清空内存缓存
                if partition is None:
                    self.memory_cache.clear()
                else:
                    # 删除指定分区的所有键
                    keys_to_delete = [k for k in self.memory_cache.keys() if k.startswith(f"{partition}:")]
                    for key in keys_to_delete:
                        del self.memory_cache[key]
                
                # 2. 清空持久化缓存
                with sqlite3.connect(self.db_path) as conn:
                    cursor = conn.cursor()
                    if partition is None:
                        cursor.execute("DELETE FROM cache_data")
                    else:
                        cursor.execute("DELETE FROM cache_data WHERE partition = ?", (partition,))
                    conn.commit()
                
                return True
                
            except Exception as e:
                logger.error(f"清空缓存失败: {e}")
                return False
    
    def get_stats(self) -> Dict[str, Any]:
        """
        获取缓存统计信息
        
        Returns:
            统计信息字典
        """
        with self.lock:
            # 清理过期条目
            self._clean_expired_entries()
            
            # 获取持久化缓存统计
            db_stats = {}
            try:
                with sqlite3.connect(self.db_path) as conn:
                    cursor = conn.cursor()
                    
                    cursor.execute("SELECT COUNT(*) FROM cache_data")
                    db_stats["total_entries"] = cursor.fetchone()[0]
                    
                    cursor.execute("SELECT COUNT(DISTINCT partition) FROM cache_data")
                    db_stats["partitions"] = cursor.fetchone()[0]
                    
                    cursor.execute("SELECT SUM(access_count) FROM cache_data")
                    db_stats["total_accesses"] = cursor.fetchone()[0] or 0
                    
            except Exception as e:
                logger.error(f"获取数据库统计失败: {e}")
                db_stats = {"error": str(e)}
            
            return {
                "memory_cache": {
                    "entries": len(self.memory_cache),
                    "limit": self.memory_limit
                },
                "persistent_cache": db_stats,
                "access_stats": self.stats.copy(),
                "hit_rate_percent": round(self.stats["hits"] / max(self.stats["hits"] + self.stats["misses"], 1) * 100, 2),
                "timestamp": datetime.now().isoformat()
            }
    
    def get_keys(self, partition: Optional[str] = None) -> List[str]:
        """
        获取缓存键列表
        
        Args:
            partition: 可选分区
        
        Returns:
            键列表
        """
        with self.lock:
            try:
                with sqlite3.connect(self.db_path) as conn:
                    cursor = conn.cursor()
                    
                    if partition is None:
                        cursor.execute("SELECT DISTINCT key FROM cache_data ORDER BY key")
                    else:
                        cursor.execute("SELECT key FROM cache_data WHERE partition = ? ORDER BY key", (partition,))
                    
                    rows = cursor.fetchall()
                    return [row[0] for row in rows]
                    
            except Exception as e:
                logger.error(f"获取缓存键列表失败: {e}")
                return []
    
    def cleanup_old_data(self, days_old: int = 7) -> int:
        """
        清理指定天数前的旧缓存数据
        
        Args:
            days_old: 天数
        
        Returns:
            删除的条目数
        """
        with self.lock:
            try:
                with sqlite3.connect(self.db_path) as conn:
                    cursor = conn.cursor()
                    
                    # 计算截止日期
                    cutoff_date = datetime.now() - timedelta(days=days_old)
                    
                    # 删除旧数据
                    cursor.execute(
                        "DELETE FROM cache_data WHERE datetime(created_at) < datetime(?)", 
                        (cutoff_date.isoformat(),)
                    )
                    
                    deleted_count = cursor.rowcount
                    conn.commit()
                    
                    # 同时清理内存缓存
                    keys_to_delete = []
                    now = datetime.now()
                    
                    for key, entry in self.memory_cache.items():
                        if "expires_at" in entry and now > entry["expires_at"]:
                            keys_to_delete.append(key)
                    
                    for key in keys_to_delete:
                        del self.memory_cache[key]
                    
                    logger.info(f"清理了 {deleted_count} 个 {days_old} 天前的缓存条目")
                    return deleted_count
                    
            except Exception as e:
                logger.error(f"清理旧数据失败: {e}")
                return 0


# 全局缓存实例
_global_cache: Optional[EnhancedCache] = None

def get_global_cache() -> EnhancedCache:
    """获取全局缓存实例"""
    global _global_cache
    if _global_cache is None:
        _global_cache = EnhancedCache()
    return _global_cache

# 常用分区常量
class CachePartitions:
    """缓存分区常量"""
    MARKET_INDICES = "market_indices"
    STOCK_QUOTE = "stock_quote"
    STOCK_HISTORY = "stock_history"
    SECTOR_DATA = "sector_data"
    MOVERS_DATA = "movers_data"
    USER_DATA = "user_data"  # 用户特定数据，如自选股列表