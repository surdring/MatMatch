"""
轻量级Oracle连接适配器测试套件

重构后的Task 1.2测试
测试轻量级适配器的核心功能：
- 连接管理
- 通用查询执行
- 流式查询
- 查询缓存
- 连接重试
"""

import pytest
import pytest_asyncio
import asyncio
import time
from unittest.mock import Mock, AsyncMock, patch, MagicMock
from typing import List, Dict, Any
import sys
from pathlib import Path

# 添加backend目录到Python路径
backend_dir = Path(__file__).parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from backend.adapters.oracle_adapter import (
    OracleConnectionAdapter,
    QueryCache,
    OracleConnectionError,
    NetworkTimeoutError,
    QueryExecutionError,
    async_retry
)


# ============================================================================
# Fixtures
# ============================================================================

@pytest_asyncio.fixture
async def adapter():
    """测试适配器实例"""
    adapter = OracleConnectionAdapter(enable_cache=True, cache_ttl=300)
    yield adapter
    # 清理资源
    await adapter.disconnect()


@pytest_asyncio.fixture
async def adapter_no_cache():
    """无缓存的测试适配器实例"""
    adapter = OracleConnectionAdapter(enable_cache=False)
    yield adapter
    await adapter.disconnect()


@pytest.fixture
def mock_query_result():
    """模拟查询结果"""
    return [
        {'code': 'MAT001', 'name': '不锈钢螺栓', 'spec': 'M8*20'},
        {'code': 'MAT002', 'name': '碳钢管件', 'spec': 'DN50'},
        {'code': 'MAT003', 'name': '铜管接头', 'spec': 'φ25'}
    ]


@pytest.fixture
def mock_large_query_result():
    """模拟大量查询结果（用于流式查询测试）"""
    return [
        {'code': f'MAT{i:06d}', 'name': f'物料{i}', 'spec': f'规格{i}'}
        for i in range(1, 5001)  # 5000条记录
    ]


# ============================================================================
# Test Class 1: 查询缓存测试
# ============================================================================

class TestQueryCache:
    """测试QueryCache类"""
    
    def test_cache_basic_operations(self):
        """测试基本的缓存操作"""
        cache = QueryCache(max_size=100, ttl=60)
        
        # 测试设置和获取
        cache.set("SELECT * FROM table1", None, ["result1"])
        result = cache.get("SELECT * FROM table1", None)
        
        assert result == ["result1"]
    
    def test_cache_miss(self):
        """测试缓存未命中"""
        cache = QueryCache(max_size=100, ttl=60)
        
        result = cache.get("SELECT * FROM table1", None)
        assert result is None
    
    def test_cache_expiration(self):
        """测试缓存过期"""
        cache = QueryCache(max_size=100, ttl=1)  # 1秒TTL
        
        cache.set("SELECT * FROM table1", None, ["result1"])
        
        # 等待过期
        time.sleep(1.5)
        
        result = cache.get("SELECT * FROM table1", None)
        assert result is None
    
    def test_cache_lru_eviction(self):
        """测试LRU淘汰机制"""
        cache = QueryCache(max_size=3, ttl=60)
        
        # 填满缓存
        cache.set("query1", None, "result1")
        cache.set("query2", None, "result2")
        cache.set("query3", None, "result3")
        
        # 添加第4个，应该淘汰最少使用的query1
        cache.set("query4", None, "result4")
        
        assert cache.get("query1", None) is None
        assert cache.get("query2", None) == "result2"
        assert cache.get("query3", None) == "result3"
        assert cache.get("query4", None) == "result4"
    
    def test_cache_clear(self):
        """测试清空缓存"""
        cache = QueryCache(max_size=100, ttl=60)
        
        cache.set("query1", None, "result1")
        cache.set("query2", None, "result2")
        
        cache.clear()
        
        assert cache.get("query1", None) is None
        assert cache.get("query2", None) is None
    
    def test_cache_stats(self):
        """测试缓存统计"""
        cache = QueryCache(max_size=100, ttl=60)
        
        cache.set("query1", None, "result1")
        cache.set("query2", None, "result2")
        
        stats = cache.stats()
        
        assert stats['size'] == 2
        assert stats['max_size'] == 100
        assert stats['ttl'] == 60


# ============================================================================
# Test Class 2: 重试装饰器测试
# ============================================================================

class TestAsyncRetry:
    """测试async_retry装饰器"""
    
    @pytest.mark.asyncio
    async def test_retry_success_on_first_attempt(self):
        """测试第一次尝试成功"""
        call_count = 0
        
        @async_retry(max_attempts=3, delay=0.1)
        async def successful_func():
            nonlocal call_count
            call_count += 1
            return "success"
        
        result = await successful_func()
        
        assert result == "success"
        assert call_count == 1
    
    @pytest.mark.asyncio
    async def test_retry_success_after_failures(self):
        """测试重试后成功"""
        call_count = 0
        
        @async_retry(max_attempts=3, delay=0.1, backoff=1.0)
        async def eventually_successful_func():
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise OracleConnectionError("临时失败")
            return "success"
        
        result = await eventually_successful_func()
        
        assert result == "success"
        assert call_count == 3
    
    @pytest.mark.asyncio
    async def test_retry_max_attempts_exceeded(self):
        """测试超过最大重试次数"""
        call_count = 0
        
        @async_retry(max_attempts=3, delay=0.1)
        async def always_failing_func():
            nonlocal call_count
            call_count += 1
            raise OracleConnectionError("持续失败")
        
        with pytest.raises(OracleConnectionError):
            await always_failing_func()
        
        assert call_count == 3
    
    @pytest.mark.asyncio
    async def test_retry_non_retryable_exception(self):
        """测试不可重试的异常"""
        call_count = 0
        
        @async_retry(max_attempts=3, delay=0.1)
        async def func_with_non_retryable_error():
            nonlocal call_count
            call_count += 1
            raise ValueError("不可重试的错误")
        
        with pytest.raises(ValueError):
            await func_with_non_retryable_error()
        
        # 不可重试的异常应该立即抛出，不重试
        assert call_count == 1


# ============================================================================
# Test Class 3: 连接管理测试
# ============================================================================

class TestConnectionManagement:
    """测试连接管理功能"""
    
    @pytest.mark.asyncio
    async def test_connect_success(self, adapter):
        """测试成功连接"""
        with patch('oracledb.connect', return_value=Mock()):
            result = await adapter.connect()
            assert result is True
    
    @pytest.mark.asyncio
    async def test_connect_failure(self, adapter):
        """测试连接失败"""
        with patch('oracledb.connect', side_effect=Exception("连接失败")):
            with pytest.raises(OracleConnectionError):
                await adapter.connect()
    
    @pytest.mark.asyncio
    async def test_disconnect(self, adapter):
        """测试断开连接"""
        mock_connection = Mock()
        adapter._connection = mock_connection
        
        with patch.object(mock_connection, 'close'):
            await adapter.disconnect()
            assert adapter._connection is None
    
    @pytest.mark.asyncio
    async def test_validate_connection_valid(self, adapter):
        """测试验证有效连接"""
        # 模拟连接
        adapter._connection = Mock()
        
        # 模拟execute_query返回结果
        with patch.object(adapter, 'execute_query', return_value=[{'1': 1}]):
            result = await adapter.validate_connection()
            assert result is True
    
    @pytest.mark.asyncio
    async def test_validate_connection_invalid(self, adapter):
        """测试验证无效连接"""
        # 无连接
        result = await adapter.validate_connection()
        assert result is False


# ============================================================================
# Test Class 4: 查询执行测试
# ============================================================================

class TestQueryExecution:
    """测试查询执行功能"""
    
    @pytest.mark.asyncio
    async def test_execute_query_basic(self, adapter, mock_query_result):
        """测试基本查询执行"""
        # 模拟连接和游标
        mock_cursor = MagicMock()
        mock_cursor.description = [('code',), ('name',), ('spec',)]
        mock_cursor.fetchall.return_value = [
            ('MAT001', '不锈钢螺栓', 'M8*20'),
            ('MAT002', '碳钢管件', 'DN50'),
            ('MAT003', '铜管接头', 'φ25')
        ]
        
        mock_connection = MagicMock()
        mock_connection.cursor.return_value = mock_cursor
        
        adapter._connection = mock_connection
        
        query = "SELECT code, name, spec FROM bd_material"
        result = await adapter.execute_query(query, use_cache=False)
        
        assert len(result) == 3
        assert result[0]['code'] == 'MAT001'
        assert result[1]['name'] == '碳钢管件'
    
    @pytest.mark.asyncio
    async def test_execute_query_with_params(self, adapter):
        """测试带参数的查询"""
        mock_cursor = MagicMock()
        mock_cursor.description = [('code',), ('name',)]
        mock_cursor.fetchall.return_value = [('MAT001', '不锈钢螺栓')]
        
        mock_connection = MagicMock()
        mock_connection.cursor.return_value = mock_cursor
        
        adapter._connection = mock_connection
        
        query = "SELECT code, name FROM bd_material WHERE code = :code"
        params = {'code': 'MAT001'}
        
        result = await adapter.execute_query(query, params, use_cache=False)
        
        assert len(result) == 1
        assert result[0]['code'] == 'MAT001'
    
    @pytest.mark.asyncio
    async def test_execute_query_with_cache(self, adapter):
        """测试查询缓存"""
        mock_cursor = MagicMock()
        mock_cursor.description = [('code',)]
        mock_cursor.fetchall.return_value = [('MAT001',)]
        
        mock_connection = MagicMock()
        mock_connection.cursor.return_value = mock_cursor
        
        adapter._connection = mock_connection
        
        query = "SELECT code FROM bd_material"
        
        # 第一次查询（未缓存）
        result1 = await adapter.execute_query(query, use_cache=True)
        
        # 第二次查询（应该命中缓存）
        result2 = await adapter.execute_query(query, use_cache=True)
        
        assert result1 == result2
        # 验证游标只被调用一次（第二次走缓存）
        assert mock_connection.cursor.call_count == 1
    
    @pytest.mark.asyncio
    async def test_execute_query_auto_connect(self, adapter):
        """测试自动连接"""
        # 确保没有连接
        adapter._connection = None
        
        with patch.object(adapter, 'connect', new_callable=AsyncMock) as mock_connect:
            mock_cursor = MagicMock()
            mock_cursor.description = [('code',)]
            mock_cursor.fetchall.return_value = []
            
            mock_connection = MagicMock()
            mock_connection.cursor.return_value = mock_cursor
            
            # 模拟connect后设置连接
            async def set_connection():
                adapter._connection = mock_connection
                return True
            
            mock_connect.side_effect = set_connection
            
            query = "SELECT code FROM bd_material"
            await adapter.execute_query(query, use_cache=False)
            
            # 验证自动调用了connect
            mock_connect.assert_called_once()


# ============================================================================
# Test Class 5: 流式查询测试
# ============================================================================

class TestStreamingQuery:
    """测试流式查询功能"""
    
    @pytest.mark.asyncio
    async def test_execute_query_generator_basic(self, adapter):
        """测试基本流式查询"""
        # 模拟分批返回数据
        batches = [
            [('MAT001', '物料1'), ('MAT002', '物料2')],
            [('MAT003', '物料3'), ('MAT004', '物料4')],
            []  # 空列表表示结束
        ]
        
        mock_cursor = MagicMock()
        mock_cursor.description = [('code',), ('name',)]
        mock_cursor.fetchmany = MagicMock(side_effect=batches)
        
        mock_connection = MagicMock()
        mock_connection.cursor.return_value = mock_cursor
        
        adapter._connection = mock_connection
        
        query = "SELECT code, name FROM bd_material"
        
        total_records = 0
        batch_count = 0
        
        async for batch in adapter.execute_query_generator(query, batch_size=2):
            batch_count += 1
            total_records += len(batch)
            assert len(batch) <= 2
        
        assert total_records == 4
        assert batch_count == 2


# ============================================================================
# Test Class 6: 缓存管理测试
# ============================================================================

class TestCacheManagement:
    """测试缓存管理功能"""
    
    def test_clear_cache(self, adapter):
        """测试清空缓存"""
        # 添加缓存
        adapter._query_cache.set("query1", None, "result1")
        
        # 清空
        adapter.clear_cache()
        
        # 验证缓存已清空
        result = adapter._query_cache.get("query1", None)
        assert result is None
    
    def test_get_cache_stats(self, adapter):
        """测试获取缓存统计"""
        adapter._query_cache.set("query1", None, "result1")
        adapter._query_cache.set("query2", None, "result2")
        
        stats = adapter.get_cache_stats()
        
        assert stats['size'] == 2
        assert 'max_size' in stats
        assert 'ttl' in stats
    
    def test_cache_disabled_stats(self, adapter_no_cache):
        """测试禁用缓存时的统计"""
        stats = adapter_no_cache.get_cache_stats()
        
        assert stats['enabled'] is False


# ============================================================================
# Test Class 7: 上下文管理器测试
# ============================================================================

class TestContextManager:
    """测试异步上下文管理器"""
    
    @pytest.mark.asyncio
    async def test_context_manager(self):
        """测试async with语法"""
        with patch('oracledb.connect', return_value=Mock()):
            async with OracleConnectionAdapter() as adapter:
                assert adapter._connection is not None or adapter._connection_pool is not None
            
            # 退出上下文后应该自动断开
            # 注意：这里无法直接验证，因为disconnect是异步的


# ============================================================================
# Test Class 8: 错误处理测试
# ============================================================================

class TestErrorHandling:
    """测试错误处理"""
    
    @pytest.mark.asyncio
    async def test_query_execution_error(self, adapter):
        """测试查询执行错误"""
        mock_cursor = MagicMock()
        mock_cursor.execute.side_effect = Exception("SQL错误")
        
        mock_connection = MagicMock()
        mock_connection.cursor.return_value = mock_cursor
        
        adapter._connection = mock_connection
        
        with pytest.raises(QueryExecutionError):
            await adapter.execute_query("INVALID SQL")


# ============================================================================
# 运行测试
# ============================================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])

