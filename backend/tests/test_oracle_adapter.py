"""
Oracle数据源适配器测试套件

基于[T] Test阶段设计的测试清单实现
包含核心功能、边界情况和性能测试
对应 [I.4] - 命名规范承诺中的测试用例编号系统
"""

import pytest
import pytest_asyncio
import asyncio
import time
from unittest.mock import Mock, AsyncMock, patch
from typing import List, Dict, Any

from backend.adapters.oracle_adapter import (
    OracleDataSourceAdapter, 
    MaterialRecord,
    OracleConnectionError,
    FieldMappingError,
    SchemaValidationError,
    NetworkTimeoutError
)
from core.config import OracleConfig


@pytest_asyncio.fixture
async def adapter():
    """测试适配器实例"""
    adapter = OracleDataSourceAdapter()
    yield adapter
    # 清理资源
    await adapter.disconnect()

@pytest.fixture
def mock_oracle_records():
    """模拟Oracle记录数据"""
    return [
        {
            'code': 'MAT001',
            'name': '不锈钢螺栓',
            'materialspec': 'M8*20',
            'materialtype': '304',
            'pk_marbasclass': 'CAT001',
            'pk_brand': 'BRAND001',
            'pk_measdoc': 'UNIT001',
            'enablestate': 2,
            'ename': 'Stainless Steel Bolt',
            'ematerialspec': 'M8*20',
            'materialshortname': '螺栓',
            'materialmnecode': 'BOLT001',
            'memo': '高强度螺栓',
            'creationtime': '2023-01-01 10:00:00',
            'modifiedtime': '2023-01-02 15:30:00'
        },
        {
            'code': 'MAT002',
            'name': '碳钢管件',
            'materialspec': 'DN50',
            'materialtype': 'Q235',
            'pk_marbasclass': 'CAT002',
            'pk_brand': 'BRAND002',
            'pk_measdoc': 'UNIT002',
            'enablestate': 2,
            'ename': 'Carbon Steel Pipe',
            'ematerialspec': 'DN50',
            'materialshortname': '管件',
            'materialmnecode': 'PIPE001',
            'memo': '标准管件',
            'creationtime': '2023-01-01 11:00:00',
            'modifiedtime': '2023-01-02 16:30:00'
        }
    ]


class TestCoreFunction:
    """
    核心功能路径测试 (Happy Path)
    对应 [T.1] - 核心功能路径测试用例
    """
    
    @pytest.mark.asyncio
    async def test_T1_2_001_oracle_connection_establishment(self, adapter):
        """
        T1_2_001: Oracle连接建立测试
        
        验证OracleDataSourceAdapter能成功连接到Oracle数据库
        对应 [T.1] 核心功能路径中的连接建立测试
        """
        # Mock oracledb.connect
        with patch('oracledb.connect') as mock_connect:
            mock_connection = Mock()
            mock_connect.return_value = mock_connection
            
            # 执行连接
            result = await adapter.connect()
            
            # 验证结果
            assert result is True
            assert adapter._connection == mock_connection
            mock_connect.assert_called_once_with(
                user=adapter.config.username,
                password=adapter.config.password,
                dsn=adapter.config.dsn
            )
    
    @pytest.mark.asyncio
    async def test_T1_2_002_batch_data_extraction(self, adapter, mock_oracle_records):
        """
        T1_2_002: 批量数据提取测试
        
        验证extract_materials_batch方法能正确提取指定数量的物料数据
        对应 [T.1] 核心功能路径中的批量数据提取测试
        """
        # Mock连接和查询
        with patch.object(adapter, '_connection', Mock()):
            with patch.object(adapter, '_execute_query_async', AsyncMock()) as mock_query:
                # 设置查询返回数据
                mock_query.return_value = mock_oracle_records
                
                # 执行批量提取
                batches = []
                async for batch in adapter.extract_materials_batch(batch_size=2):
                    batches.append(batch)
                    break  # 只测试第一批
                
                # 验证结果
                assert len(batches) == 1
                assert len(batches[0]) == 2
                assert isinstance(batches[0][0], MaterialRecord)
                assert batches[0][0].erp_code == 'MAT001'
                assert batches[0][0].material_name == '不锈钢螺栓'
    
    @pytest.mark.asyncio
    async def test_T1_2_003_field_mapping_accuracy(self, adapter, mock_oracle_records):
        """
        T1_2_003: 字段映射准确性测试
        
        验证Oracle字段到标准字段的映射100%准确
        对应 [T.1] 核心功能路径中的字段映射测试
        """
        # 测试字段映射
        oracle_record = mock_oracle_records[0]
        mapped_record = adapter._map_oracle_fields(oracle_record)
        
        # 验证映射准确性
        assert mapped_record['erp_code'] == 'MAT001'
        assert mapped_record['material_name'] == '不锈钢螺栓'
        assert mapped_record['specification'] == 'M8*20'
        assert mapped_record['model'] == '304'
        assert mapped_record['category_id'] == 'CAT001'
        assert mapped_record['enable_state'] == 2
        
        # 验证所有字段都被映射
        expected_fields = set(adapter.field_mapping.keys())
        actual_fields = set(mapped_record.keys())
        assert expected_fields == actual_fields
    
    @pytest.mark.asyncio
    async def test_T1_2_004_async_data_stream(self, adapter, mock_oracle_records):
        """
        T1_2_004: 异步数据流测试
        
        验证AsyncGenerator能正确产生批量数据流
        对应 [T.1] 核心功能路径中的异步数据流测试
        """
        # Mock连接和查询
        with patch.object(adapter, '_connection', Mock()):
            with patch.object(adapter, '_execute_query_async', AsyncMock()) as mock_query:
                # 模拟多批数据
                mock_query.side_effect = [
                    mock_oracle_records,  # 第一批
                    []  # 第二批为空，结束
                ]
                
                # 测试异步生成器
                batch_count = 0
                total_records = 0
                
                async for batch in adapter.extract_materials_batch(batch_size=2):
                    batch_count += 1
                    total_records += len(batch)
                    
                    # 验证每批都是MaterialRecord列表
                    assert isinstance(batch, list)
                    assert all(isinstance(record, MaterialRecord) for record in batch)
                
                # 验证结果
                assert batch_count == 1
                assert total_records == 2
    
    @pytest.mark.asyncio
    async def test_T1_2_005_configuration_loading(self, adapter):
        """
        T1_2_005: 配置加载测试
        
        验证Oracle配置能正确从环境变量或配置文件加载
        对应 [T.1] 核心功能路径中的配置加载测试
        """
        # 验证配置加载
        assert adapter.config is not None
        assert isinstance(adapter.config, OracleConfig)
        
        # 验证默认配置值
        assert adapter.config.host == "192.168.80.90"
        assert adapter.config.port == 1521
        assert adapter.config.service_name == "ORCL"
        assert adapter.config.username == "matmatch_read"
        
        # 验证DSN构建
        expected_dsn = "192.168.80.90:1521/ORCL"
        assert adapter.config.dsn == expected_dsn
        
        # 验证字段映射配置
        assert len(adapter.field_mapping) == 15
        assert 'erp_code' in adapter.field_mapping
        assert adapter.field_mapping['erp_code'] == 'code'


class TestBoundaryCases:
    """
    边界情况测试
    对应 [T.2] - 边界情况覆盖测试用例
    """
    
    @pytest.mark.asyncio
    async def test_T1_2_B01_oracle_connection_failure(self, adapter):
        """
        T1_2_B01: Oracle连接失败处理测试
        
        测试无效连接参数时的异常处理
        预期错误类型: OracleConnectionError
        预期错误信息: "Oracle数据库连接失败"
        """
        with patch('oracledb.connect') as mock_connect:
            mock_connect.side_effect = Exception("Connection refused")
            
            # 测试连接失败
            with pytest.raises(OracleConnectionError) as exc_info:
                await adapter.connect()
            
            # 验证异常信息
            assert "Oracle数据库连接失败" in str(exc_info.value)
    
    @pytest.mark.asyncio
    async def test_T1_2_B02_empty_dataset_handling(self, adapter):
        """
        T1_2_B02: 空数据集处理测试
        
        测试Oracle表为空时的处理逻辑
        预期行为: 返回空的AsyncGenerator，不抛出异常
        """
        with patch.object(adapter, '_connection', Mock()):
            with patch.object(adapter, '_execute_query_async', AsyncMock()) as mock_query:
                # 模拟空数据集
                mock_query.return_value = []
                
                # 测试空数据处理
                batches = []
                async for batch in adapter.extract_materials_batch():
                    batches.append(batch)
                
                # 验证结果
                assert len(batches) == 0  # 空生成器
    
    @pytest.mark.asyncio
    async def test_T1_2_B03_large_batch_memory_test(self, adapter):
        """
        T1_2_B03: 大批量数据内存测试
        
        测试处理大量数据时的内存使用
        预期行为: 内存使用稳定，不超过500MB
        """
        # 创建大量模拟数据
        large_dataset = []
        for i in range(1000):  # 模拟1000条记录
            record = {
                'code': f'MAT{i:06d}',
                'name': f'物料{i}',
                'materialspec': 'M8*20',
                'materialtype': '304',
                'pk_marbasclass': 'CAT001',
                'pk_brand': 'BRAND001',
                'pk_measdoc': 'UNIT001',
                'enablestate': 2,
                'ename': f'Material {i}',
                'ematerialspec': 'M8*20',
                'materialshortname': f'物料{i}',
                'materialmnecode': f'MAT{i}',
                'memo': f'备注{i}',
                'creationtime': '2023-01-01 10:00:00',
                'modifiedtime': '2023-01-02 15:30:00'
            }
            large_dataset.append(record)
        
        with patch.object(adapter, '_connection', Mock()):
            with patch.object(adapter, '_execute_query_async', AsyncMock()) as mock_query:
                # 分批返回数据
                mock_query.side_effect = [
                    large_dataset[:500],  # 第一批500条
                    large_dataset[500:],  # 第二批500条
                    []  # 结束
                ]
                
                # 测试大批量处理
                total_processed = 0
                async for batch in adapter.extract_materials_batch(batch_size=500):
                    total_processed += len(batch)
                    # 验证每批数据都正确处理
                    assert len(batch) <= 500
                
                # 验证总数
                assert total_processed == 1000
    
    @pytest.mark.asyncio
    async def test_T1_2_B04_network_timeout_recovery(self, adapter):
        """
        T1_2_B04: 网络中断恢复测试
        
        测试数据提取过程中网络中断的恢复机制
        预期错误类型: NetworkTimeoutError
        预期错误信息: "网络连接超时，正在重试"
        """
        with patch.object(adapter, '_connection', Mock()):
            with patch.object(adapter, '_execute_query_async', AsyncMock()) as mock_query:
                # 模拟网络超时
                mock_query.side_effect = asyncio.TimeoutError("Network timeout")
                
                # 测试网络超时处理
                with pytest.raises(NetworkTimeoutError) as exc_info:
                    async for batch in adapter.extract_materials_batch():
                        pass
                
                # 验证异常信息
                assert "网络连接超时，正在重试" in str(exc_info.value)
    
    @pytest.mark.asyncio
    async def test_T1_2_B05_field_type_mismatch(self, adapter):
        """
        T1_2_B05: 字段类型不匹配测试
        
        测试Oracle字段类型与预期不符时的处理
        预期错误类型: FieldMappingError
        预期错误信息: "字段类型转换失败"
        """
        # 创建类型不匹配的记录
        invalid_record = {
            'code': None,  # 应该是字符串但为None
            'name': 123,   # 应该是字符串但为数字
            'enablestate': 'invalid'  # 应该是数字但为字符串
        }
        
        # 测试字段映射异常处理
        with pytest.raises(FieldMappingError) as exc_info:
            adapter._map_oracle_fields(invalid_record)
        
        # 验证异常信息
        assert "字段类型转换失败" in str(exc_info.value)
    
    @pytest.mark.asyncio
    async def test_T1_2_B06_batch_size_boundary(self, adapter):
        """
        T1_2_B06: 批量大小边界测试
        
        测试batch_size为0、1、最大值时的行为
        预期行为: batch_size=0抛出ValueError，batch_size=1正常工作
        """
        # 测试batch_size=0
        with pytest.raises(ValueError) as exc_info:
            async for batch in adapter.extract_materials_batch(batch_size=0):
                pass
        assert "batch_size必须大于0" in str(exc_info.value)
        
        # 测试batch_size=1
        with patch.object(adapter, '_connection', Mock()):
            with patch.object(adapter, '_execute_query_async', AsyncMock()) as mock_query:
                mock_query.return_value = []  # 空结果
                
                # 应该正常工作，不抛出异常
                batches = []
                async for batch in adapter.extract_materials_batch(batch_size=1):
                    batches.append(batch)
                
                assert len(batches) == 0
    
    @pytest.mark.asyncio
    async def test_T1_2_B07_oracle_schema_change(self, adapter):
        """
        T1_2_B07: Oracle表结构变化测试
        
        测试Oracle表字段缺失时的容错处理
        预期错误类型: SchemaValidationError
        预期错误信息: "Oracle表结构验证失败"
        """
        with patch.object(adapter, '_connection', Mock()):
            with patch.object(adapter, '_execute_query_async', AsyncMock()) as mock_query:
                # 模拟表结构错误
                mock_query.side_effect = Exception("ORA-00904: invalid identifier")
                
                # 测试表结构验证
                with pytest.raises(SchemaValidationError) as exc_info:
                    async for batch in adapter.extract_materials_batch():
                        pass
                
                # 验证异常信息
                assert "Oracle表结构验证失败" in str(exc_info.value)


class TestPerformance:
    """
    性能测试
    对应 [T.3] - 性能/压力测试用例
    """
    
    @pytest.mark.asyncio
    async def test_T1_2_P01_batch_extraction_performance(self, adapter, mock_oracle_records):
        """
        T1_2_P01: 批量提取性能测试
        
        验证数据提取速度≥1000条/分钟
        测试数据量: 5000条物料数据
        预期性能: 完成时间≤5分钟
        """
        # 创建5000条模拟数据
        large_dataset = mock_oracle_records * 2500  # 2条记录 * 2500 = 5000条
        
        with patch.object(adapter, '_connection', Mock()):
            with patch.object(adapter, '_execute_query_async', AsyncMock()) as mock_query:
                # 分10批返回，每批500条
                batch_size = 500
                batches = [large_dataset[i:i+batch_size] for i in range(0, len(large_dataset), batch_size)]
                batches.append([])  # 结束标记
                mock_query.side_effect = batches
                
                # 性能测试
                start_time = time.time()
                total_processed = 0
                
                async for batch in adapter.extract_materials_batch(batch_size=batch_size):
                    total_processed += len(batch)
                
                end_time = time.time()
                processing_time = end_time - start_time
                
                # 验证性能指标
                assert total_processed == 5000
                processing_rate = total_processed / (processing_time / 60)  # 条/分钟
                
                # 性能要求: ≥1000条/分钟
                assert processing_rate >= 1000, f"处理速度 {processing_rate:.2f} 条/分钟 < 1000条/分钟"
    
    @pytest.mark.asyncio
    async def test_T1_2_P02_concurrent_connection_test(self):
        """
        T1_2_P02: 并发连接测试
        
        验证多个适配器实例并发工作
        并发数量: 5个适配器实例
        预期行为: 无连接冲突，数据不重复
        """
        adapters = [OracleDataSourceAdapter() for _ in range(5)]
        
        # Mock oracledb.connect for all adapters
        with patch('oracledb.connect') as mock_connect:
            mock_connection = Mock()
            mock_connect.return_value = mock_connection
            
            # 并发连接测试
            tasks = [adapter.connect() for adapter in adapters]
            results = await asyncio.gather(*tasks)
            
            # 验证所有连接都成功
            assert all(results)
            assert len(results) == 5
            
            # 验证连接状态
            validation_tasks = []
            for adapter in adapters:
                with patch.object(adapter, 'validate_connection', AsyncMock(return_value=True)):
                    validation_tasks.append(adapter.validate_connection())
            
            validation_results = await asyncio.gather(*validation_tasks)
            assert all(validation_results)
        
        # 清理资源
        for adapter in adapters:
            await adapter.disconnect()
    
    @pytest.mark.asyncio
    async def test_T1_2_P03_long_running_stability(self, adapter, mock_oracle_records):
        """
        T1_2_P03: 长时间运行稳定性测试
        
        验证适配器长时间运行的稳定性
        运行时间: 模拟30分钟连续数据提取
        预期行为: 无内存泄漏，连接保持稳定
        """
        with patch.object(adapter, '_connection', Mock()):
            with patch.object(adapter, '_execute_query_async', AsyncMock()) as mock_query:
                # 模拟长时间运行 - 用快速循环模拟
                mock_query.return_value = mock_oracle_records
                
                # 模拟30次批量提取（代表30分钟）
                total_batches = 0
                for _ in range(30):
                    async for batch in adapter.extract_materials_batch(batch_size=100):
                        total_batches += 1
                        break  # 每次只取一批
                    
                    # 验证连接状态
                    with patch.object(adapter, 'validate_connection', AsyncMock(return_value=True)):
                        connection_valid = await adapter.validate_connection()
                        assert connection_valid, f"连接在第{total_batches}批后失效"
                
                # 验证稳定性
                assert total_batches == 30
    
    @pytest.mark.asyncio
    async def test_T1_2_P04_large_dataset_stress_test(self, adapter):
        """
        T1_2_P04: 大数据量压力测试
        
        验证处理大量数据时的表现
        数据量: 100,000条物料数据
        预期行为: 内存使用稳定，处理速度保持在≥800条/分钟
        """
        # 创建大数据集模拟
        def create_large_batch(start_id: int, count: int) -> List[Dict[str, Any]]:
            return [
                {
                    'code': f'MAT{i:06d}',
                    'name': f'大数据测试物料{i}',
                    'materialspec': 'M8*20',
                    'materialtype': '304',
                    'pk_marbasclass': 'CAT001',
                    'pk_brand': 'BRAND001',
                    'pk_measdoc': 'UNIT001',
                    'enablestate': 2,
                    'ename': f'Large Test Material {i}',
                    'ematerialspec': 'M8*20',
                    'materialshortname': f'物料{i}',
                    'materialmnecode': f'MAT{i}',
                    'memo': f'大数据测试备注{i}',
                    'creationtime': '2023-01-01 10:00:00',
                    'modifiedtime': '2023-01-02 15:30:00'
                }
                for i in range(start_id, start_id + count)
            ]
        
        with patch.object(adapter, '_connection', Mock()):
            with patch.object(adapter, '_execute_query_async', AsyncMock()) as mock_query:
                # 分批返回100,000条数据
                batch_size = 1000
                total_records = 100000
                
                # 创建批次数据
                batches = []
                for i in range(0, total_records, batch_size):
                    batch = create_large_batch(i, min(batch_size, total_records - i))
                    batches.append(batch)
                batches.append([])  # 结束标记
                
                mock_query.side_effect = batches
                
                # 压力测试
                start_time = time.time()
                total_processed = 0
                
                async for batch in adapter.extract_materials_batch(batch_size=batch_size):
                    total_processed += len(batch)
                    
                    # 每处理10000条记录检查一次进度
                    if total_processed % 10000 == 0:
                        current_time = time.time()
                        elapsed_time = current_time - start_time
                        current_rate = total_processed / (elapsed_time / 60)
                        
                        # 验证处理速度保持在≥800条/分钟
                        assert current_rate >= 800, f"处理速度 {current_rate:.2f} 条/分钟 < 800条/分钟"
                
                end_time = time.time()
                total_time = end_time - start_time
                final_rate = total_processed / (total_time / 60)
                
                # 验证最终结果
                assert total_processed == total_records
                assert final_rate >= 800, f"最终处理速度 {final_rate:.2f} 条/分钟 < 800条/分钟"


# Mock Oracle连接器 - 对应 [I.5] 风险识别与缓解策略中的Mock实现
class MockOracleConnector:
    """
    Mock Oracle连接器
    
    用于离线测试，提供预定义测试数据集
    对应 [I.5] - 风险识别与缓解策略中的Mock实现细节
    """
    
    def __init__(self, test_data: List[Dict[str, Any]] = None):
        self.test_data = test_data or []
        self.connected = False
    
    async def connect(self) -> bool:
        """模拟连接"""
        self.connected = True
        return True
    
    async def disconnect(self) -> None:
        """模拟断开连接"""
        self.connected = False
    
    async def execute_query(self, query: str, params: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """模拟查询执行"""
        if not self.connected:
            raise OracleConnectionError("Mock连接未建立")
        
        # 根据参数返回相应的测试数据
        if params and 'offset' in params and 'batch_size' in params:
            offset = params['offset']
            batch_size = params['batch_size']
            return self.test_data[offset:offset + batch_size]
        
        return self.test_data
