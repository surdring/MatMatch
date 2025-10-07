"""
轻量级Oracle连接适配器

重构后的Task 1.2 - 基础设施层
提供可复用的Oracle连接管理和通用查询执行能力

职责：
- 连接管理（建立、关闭、重试）
- 通用查询执行（同步/异步/流式）
- 查询结果缓存（LRU + TTL）
- 错误处理和日志记录

不包含：
- [FAIL] 业务查询逻辑（由上层调用者提供SQL）
- [FAIL] 字段映射和数据处理
- [FAIL] ETL业务逻辑
"""

import asyncio
import logging
from typing import Dict, List, Any, Optional, AsyncGenerator, NamedTuple
from functools import wraps
import time
import hashlib
import json
import oracledb

from backend.core.config import OracleConfig


# ============================================================================
# 数据模型
# ============================================================================

class MaterialRecord(NamedTuple):
    """物料记录数据模型（用于测试兼容）"""
    erp_code: str
    material_name: str
    specification: Optional[str] = None
    model: Optional[str] = None
    category_id: Optional[str] = None
    unit_id: Optional[str] = None

# 初始化Oracle thick模式（支持旧版本Oracle）
try:
    oracledb.init_oracle_client()
    logger_init = logging.getLogger(__name__)
    logger_init.info("[OK] Oracle thick模式初始化成功")
except Exception as e:
    # 如果已经初始化过或不需要thick模式，忽略错误
    pass

# 配置日志
logger = logging.getLogger(__name__)


# ============================================================================
# 查询缓存
# ============================================================================

class QueryCache:
    """
    查询结果缓存
    
    使用LRU策略和TTL过期机制
    支持动态增长的数据量
    """
    
    def __init__(self, max_size: int = 1000, ttl: int = 300):
        """
        Args:
            max_size: 最大缓存条目数
            ttl: 缓存过期时间（秒），默认5分钟
        """
        self.max_size = max_size
        self.ttl = ttl
        self._cache: Dict[str, tuple[Any, float]] = {}  # key -> (value, timestamp)
        self._access_order: List[str] = []  # LRU访问顺序
    
    def _make_key(self, query: str, params: Optional[Dict] = None) -> str:
        """生成缓存键"""
        key_data = {
            'query': query,
            'params': params or {}
        }
        key_str = json.dumps(key_data, sort_keys=True)
        return hashlib.md5(key_str.encode()).hexdigest()
    
    def get(self, query: str, params: Optional[Dict] = None) -> Optional[Any]:
        """获取缓存"""
        key = self._make_key(query, params)
        
        if key not in self._cache:
            return None
        
        value, timestamp = self._cache[key]
        
        # 检查是否过期
        if time.time() - timestamp > self.ttl:
            del self._cache[key]
            if key in self._access_order:
                self._access_order.remove(key)
            return None
        
        # 更新访问顺序（LRU）
        if key in self._access_order:
            self._access_order.remove(key)
        self._access_order.append(key)
        
        logger.debug(f" 缓存命中: {key[:8]}...")
        return value
    
    def set(self, query: str, params: Optional[Dict], value: Any) -> None:
        """设置缓存"""
        key = self._make_key(query, params)
        
        # 如果缓存已满，移除最少使用的
        if len(self._cache) >= self.max_size and key not in self._cache:
            if self._access_order:
                lru_key = self._access_order.pop(0)
                del self._cache[lru_key]
        
        self._cache[key] = (value, time.time())
        
        if key in self._access_order:
            self._access_order.remove(key)
        self._access_order.append(key)
        
        logger.debug(f"💾 缓存保存: {key[:8]}...")
    
    def clear(self) -> None:
        """清空缓存"""
        self._cache.clear()
        self._access_order.clear()
        logger.info("🧹 查询缓存已清空")
    
    def stats(self) -> Dict[str, Any]:
        """缓存统计"""
        return {
            'size': len(self._cache),
            'max_size': self.max_size,
            'ttl': self.ttl,
            'hit_rate': f"{len(self._cache)}/{self.max_size}"
        }


# ============================================================================
# 重试装饰器
# ============================================================================

def async_retry(max_attempts: int = 3, delay: float = 1.0, backoff: float = 2.0):
    """
    异步函数重试装饰器
    
    Args:
        max_attempts: 最大重试次数
        delay: 初始延迟时间（秒）
        backoff: 退避系数（每次重试延迟时间乘以此系数）
    
    Example:
        @async_retry(max_attempts=3, delay=1.0, backoff=2.0)
        async def connect():
            # 连接逻辑
            pass
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            current_delay = delay
            last_exception = None
            
            for attempt in range(1, max_attempts + 1):
                try:
                    return await func(*args, **kwargs)
                except (OracleConnectionError, NetworkTimeoutError) as e:
                    last_exception = e
                    if attempt < max_attempts:
                        logger.warning(
                            f"[WARN] {func.__name__} 第{attempt}次尝试失败: {str(e)}, "
                            f"{current_delay:.1f}秒后重试..."
                        )
                        await asyncio.sleep(current_delay)
                        current_delay *= backoff
                    else:
                        logger.error(
                            f"[FAIL] {func.__name__} 重试{max_attempts}次后仍然失败"
                        )
                except Exception as e:
                    # 其他异常不重试，直接抛出
                    logger.error(f"[FAIL] {func.__name__} 发生不可重试的异常: {str(e)}")
                    raise
            
            # 所有重试都失败，抛出最后一个异常
            raise last_exception
        
        return wrapper
    return decorator


# ============================================================================
# 异常类
# ============================================================================

class OracleConnectionError(Exception):
    """Oracle连接异常"""
    pass


class NetworkTimeoutError(Exception):
    """网络超时异常"""
    pass


class QueryExecutionError(Exception):
    """查询执行异常"""
    pass


class FieldMappingError(Exception):
    """字段映射错误（用于测试兼容）"""
    pass


class SchemaValidationError(Exception):
    """Schema验证错误（用于测试兼容）"""
    pass


class OracleDataSourceAdapter:
    """Oracle数据源适配器（别名，用于测试兼容）"""
    pass


# ============================================================================
# 轻量级Oracle连接适配器
# ============================================================================

class OracleConnectionAdapter:
    """
    轻量级Oracle连接适配器 - 基础设施层
    
    职责：
    - 提供可复用的Oracle连接管理
    - 支持连接重试和错误处理
    - 提供查询缓存机制
    - 支持异步查询包装
    
    不包含：
    - [FAIL] 业务查询逻辑（由上层调用者提供SQL）
    - [FAIL] 字段映射逻辑
    - [FAIL] 数据处理逻辑
    
    使用示例：
        # 基本用法
        adapter = OracleConnectionAdapter()
        await adapter.connect()
        
        # 执行查询（由调用者提供SQL）
        query = "SELECT * FROM bd_material WHERE code = :code"
        result = await adapter.execute_query(query, {'code': 'MAT001'})
        
        # 流式查询（大数据量）
        query = "SELECT * FROM bd_material"
        async for batch in adapter.execute_query_generator(query, batch_size=1000):
            process_batch(batch)
        
        await adapter.disconnect()
    """
    
    def __init__(
        self, 
        config: Optional[Dict[str, Any]] = None,
        enable_cache: bool = True, 
        cache_ttl: int = 300,
        use_pool: bool = False
    ):
        """
        初始化Oracle连接适配器
        
        Args:
            config: Oracle配置（可选，默认使用oracle_config）
            enable_cache: 是否启用查询缓存
            cache_ttl: 缓存过期时间（秒），默认5分钟
            use_pool: 是否使用连接池（高并发场景）
        """
        self.config = config or oracle_config
        self._connection: Optional[oracledb.Connection] = None
        self._connection_pool: Optional[oracledb.ConnectionPool] = None
        self._use_pool = use_pool
        
        # 查询缓存
        self._enable_cache = enable_cache
        self._query_cache = QueryCache(max_size=1000, ttl=cache_ttl) if enable_cache else None
        
        logger.info(" 轻量级Oracle连接适配器初始化完成")
        if enable_cache:
            logger.info(f"💾 查询缓存已启用 (TTL: {cache_ttl}秒)")
    
    # ========================================================================
    # 连接管理
    # ========================================================================
    
    @async_retry(max_attempts=3, delay=1.0, backoff=2.0)
    async def connect(self) -> bool:
        """
        建立Oracle数据库连接（带自动重试）
        
        Returns:
            bool: 连接是否成功
            
        Raises:
            OracleConnectionError: 连接失败
        """
        try:
            if self._use_pool:
                # 使用连接池（高并发场景）
                self._connection_pool = await asyncio.to_thread(
                    oracledb.create_pool,
                    user=self.config.username,
                    password=self.config.password,
                    dsn=self.config.dsn,
                    min=2,
                    max=10,
                    increment=1
                )
                logger.info("[OK] Oracle连接池创建成功")
            else:
                # 单连接模式
                self._connection = await asyncio.to_thread(
                    oracledb.connect,
                    user=self.config.username,
                    password=self.config.password,
                    dsn=self.config.dsn
                )
                logger.info("[OK] Oracle连接成功")
            
            return True
            
        except oracledb.DatabaseError as e:
            error_msg = f"Oracle连接失败: {str(e)}"
            logger.error(f"[FAIL] {error_msg}")
            raise OracleConnectionError(error_msg) from e
        except Exception as e:
            error_msg = f"连接过程发生未知错误: {str(e)}"
            logger.error(f"[FAIL] {error_msg}")
            raise OracleConnectionError(error_msg) from e
    
    async def disconnect(self) -> None:
        """
        关闭Oracle数据库连接
        """
        try:
            if self._connection_pool:
                await asyncio.to_thread(self._connection_pool.close)
                self._connection_pool = None
                logger.info("[OK] Oracle连接池已关闭")
            elif self._connection:
                await asyncio.to_thread(self._connection.close)
                self._connection = None
                logger.info("[OK] Oracle连接已关闭")
        except Exception as e:
            logger.error(f"[WARN] 关闭连接时发生错误: {str(e)}")
    
    def get_connection(self) -> Optional[oracledb.Connection]:
        """
        获取原始连接对象（高级用法）
        
        Returns:
            oracledb.Connection: Oracle连接对象
            
        Note:
            一般情况下不需要直接使用此方法，
            应该使用execute_query或execute_query_generator
        """
        if self._use_pool and self._connection_pool:
            return self._connection_pool.acquire()
        return self._connection
    
    async def validate_connection(self) -> bool:
        """
        验证连接是否有效
        
        Returns:
            bool: 连接是否有效
        """
        try:
            if not self._connection and not self._connection_pool:
                return False
            
            # 执行简单查询测试连接
            result = await self.execute_query("SELECT 1 FROM DUAL", use_cache=False)
            return len(result) > 0
            
        except Exception as e:
            logger.error(f"[FAIL] 连接验证失败: {str(e)}")
            return False
    
    # ========================================================================
    # 查询执行
    # ========================================================================
    
    async def execute_query(
        self, 
        query: str, 
        params: Optional[Dict[str, Any]] = None,
        use_cache: bool = True
    ) -> List[Dict[str, Any]]:
        """
        执行查询（通用方法）
        
        [OK] 提供基础的查询执行能力
        [FAIL] 不包含具体的业务查询逻辑
        
        Args:
            query: SQL查询语句（由调用者提供）
            params: 查询参数（字典格式，支持命名参数）
            use_cache: 是否使用缓存
            
        Returns:
            List[Dict[str, Any]]: 查询结果列表，每行为一个字典
            
        Raises:
            QueryExecutionError: 查询执行失败
            
        Example:
            # 简单查询
            result = await adapter.execute_query("SELECT * FROM bd_material")
            
            # 带参数查询
            query = "SELECT * FROM bd_material WHERE code = :code AND enablestate = :state"
            result = await adapter.execute_query(query, {'code': 'MAT001', 'state': 2})
        """
        # 检查缓存
        if use_cache and self._enable_cache:
            cached_result = self._query_cache.get(query, params)
            if cached_result is not None:
                logger.debug(f" 返回缓存结果（{len(cached_result)}条）")
                return cached_result
        
        # 确保连接已建立
        if not self._connection and not self._connection_pool:
            await self.connect()
        
        try:
            # 获取连接
            if self._use_pool and self._connection_pool:
                conn = await asyncio.to_thread(self._connection_pool.acquire)
            else:
                conn = self._connection
            
            # 创建游标
            cursor = await asyncio.to_thread(conn.cursor)
            
            try:
                # 执行查询
                if params:
                    await asyncio.to_thread(cursor.execute, query, params)
                else:
                    await asyncio.to_thread(cursor.execute, query)
                
                # 获取列名
                columns = [desc[0].lower() for desc in cursor.description]
                
                # 获取数据
                rows = await asyncio.to_thread(cursor.fetchall)
                
                # 转换为字典列表
                result = [dict(zip(columns, row)) for row in rows]
                
                logger.debug(f"[OK] 查询成功，返回 {len(result)} 条记录")
                
                # 缓存结果
                if use_cache and self._enable_cache:
                    self._query_cache.set(query, params, result)
                
                return result
                
            finally:
                await asyncio.to_thread(cursor.close)
                
                # 如果使用连接池，释放连接
                if self._use_pool and self._connection_pool:
                    await asyncio.to_thread(self._connection_pool.release, conn)
        
        except oracledb.DatabaseError as e:
            error_msg = f"查询执行失败: {str(e)}"
            logger.error(f"[FAIL] {error_msg}\nSQL: {query[:100]}...")
            raise QueryExecutionError(error_msg) from e
        except Exception as e:
            error_msg = f"查询过程发生未知错误: {str(e)}"
            logger.error(f"[FAIL] {error_msg}")
            raise QueryExecutionError(error_msg) from e
    
    async def execute_query_generator(
        self,
        query: str,
        params: Optional[Dict[str, Any]] = None,
        batch_size: int = 1000
    ) -> AsyncGenerator[List[Dict[str, Any]], None]:
        """
        流式执行查询（用于大数据量）
        
        [OK] 提供流式查询能力
        [FAIL] 不包含具体的业务查询逻辑
        
        Args:
            query: SQL查询语句（由调用者提供）
            params: 查询参数
            batch_size: 每批数据量
            
        Yields:
            List[Dict[str, Any]]: 批量查询结果
            
        Example:
            query = "SELECT * FROM bd_material WHERE enablestate = 2"
            async for batch in adapter.execute_query_generator(query, batch_size=1000):
                print(f"处理 {len(batch)} 条记录")
                process_batch(batch)
        """
        # 确保连接已建立
        if not self._connection and not self._connection_pool:
            await self.connect()
        
        try:
            # 获取连接
            if self._use_pool and self._connection_pool:
                conn = await asyncio.to_thread(self._connection_pool.acquire)
            else:
                conn = self._connection
            
            # 创建游标
            cursor = await asyncio.to_thread(conn.cursor)
            
            try:
                # 执行查询
                if params:
                    await asyncio.to_thread(cursor.execute, query, params)
                else:
                    await asyncio.to_thread(cursor.execute, query)
                
                # 获取列名
                columns = [desc[0].lower() for desc in cursor.description]
                
                # 流式读取数据
                total_fetched = 0
                while True:
                    rows = await asyncio.to_thread(cursor.fetchmany, batch_size)
                    if not rows:
                        break
                    
                    # 转换为字典列表
                    batch = [dict(zip(columns, row)) for row in rows]
                    total_fetched += len(batch)
                    
                    logger.debug(f" 流式查询返回批次：{len(batch)}条（累计{total_fetched}条）")
                    
                    yield batch
                
                logger.info(f"[OK] 流式查询完成，共返回 {total_fetched} 条记录")
                
            finally:
                await asyncio.to_thread(cursor.close)
                
                # 如果使用连接池，释放连接
                if self._use_pool and self._connection_pool:
                    await asyncio.to_thread(self._connection_pool.release, conn)
        
        except oracledb.DatabaseError as e:
            error_msg = f"流式查询执行失败: {str(e)}"
            logger.error(f"[FAIL] {error_msg}\nSQL: {query[:100]}...")
            raise QueryExecutionError(error_msg) from e
        except Exception as e:
            error_msg = f"流式查询过程发生未知错误: {str(e)}"
            logger.error(f"[FAIL] {error_msg}")
            raise QueryExecutionError(error_msg) from e
    
    # ========================================================================
    # 缓存管理
    # ========================================================================
    
    def clear_cache(self) -> None:
        """
        清空查询缓存
        
        使用场景：
        - 数据更新后需要清除缓存
        - 内存压力较大时
        """
        if self._query_cache:
            self._query_cache.clear()
        else:
            logger.warning("[WARN] 查询缓存未启用")
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """
        获取缓存统计信息
        
        Returns:
            Dict: 缓存统计信息
                - size: 当前缓存条目数
                - max_size: 最大缓存条目数
                - ttl: 缓存过期时间
                - hit_rate: 缓存命中率
        """
        if self._query_cache:
            return self._query_cache.stats()
        return {
            'enabled': False,
            'message': '缓存未启用'
        }
    
    # ========================================================================
    # 工具方法
    # ========================================================================
    
    def __repr__(self) -> str:
        """字符串表示"""
        status = "已连接" if (self._connection or self._connection_pool) else "未连接"
        cache_status = "启用" if self._enable_cache else "禁用"
        pool_status = "启用" if self._use_pool else "禁用"
        
        return (
            f"OracleConnectionAdapter("
            f"status={status}, "
            f"cache={cache_status}, "
            f"pool={pool_status})"
        )
    
    async def __aenter__(self):
        """异步上下文管理器入口"""
        await self.connect()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """异步上下文管理器出口"""
        await self.disconnect()


# ============================================================================
# 向后兼容（可选）
# ============================================================================

# 保留旧名称以便渐进式迁移
OracleDataSourceAdapter = OracleConnectionAdapter

logger.info("[OK] 轻量级Oracle连接适配器模块加载完成")
