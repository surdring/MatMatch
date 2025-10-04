"""
ETL增量同步专项测试

测试增量同步功能的正确性和健壮性
"""

import pytest
import sys
from pathlib import Path
from unittest.mock import MagicMock, AsyncMock
from datetime import datetime, timedelta

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from backend.etl.etl_pipeline import ETLPipeline
from backend.etl.material_processor import SimpleMaterialProcessor
from backend.models.materials import MaterialsMaster
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.asyncio
async def test_incremental_sync_basic():
    """
    测试1: 基础增量同步功能
    
    验证增量同步能正确提取、处理和加载数据
    """
    # Arrange
    since_time = "2025-10-01 00:00:00"
    
    # 模拟增量数据（第一批）
    batch1 = [
        {
            'erp_code': 'MAT001',
            'material_name': '更新物料A',
            'specification': '规格A',
            'model': '型号A',
            'oracle_category_id': 'CAT001',
            'category_name': '轴承',
            'category_code': 'BEARING',
            'oracle_unit_id': 'UNIT001',
            'unit_name': '件',
            'unit_english_name': 'PCS',
            'enable_state': 2,
            'oracle_modified_time': datetime(2025, 10, 2, 10, 0, 0)
        },
        {
            'erp_code': 'MAT002',
            'material_name': '新增物料B',
            'specification': '规格B',
            'model': '型号B',
            'oracle_category_id': 'CAT002',
            'category_name': '螺栓',
            'category_code': 'BOLT',
            'oracle_unit_id': 'UNIT001',
            'unit_name': '件',
            'unit_english_name': 'PCS',
            'enable_state': 2,
            'oracle_modified_time': datetime(2025, 10, 2, 11, 0, 0)
        }
    ]
    
    # Mock Oracle适配器（使用generator）
    async def mock_generator(query, params, batch_size):
        yield batch1
        # 第二次返回空，结束迭代
        return
    
    oracle_adapter = MagicMock()
    oracle_adapter.connect = AsyncMock()
    oracle_adapter.disconnect = AsyncMock()
    oracle_adapter.execute_query_generator = mock_generator
    
    # Mock处理器
    processor = MagicMock(spec=SimpleMaterialProcessor)
    processor._knowledge_base_loaded = True
    
    def mock_process(item):
        return MaterialsMaster(
            erp_code=item['erp_code'],
            material_name=item['material_name'],
            specification=item.get('specification'),
            model=item.get('model'),
            normalized_name=item['material_name'],
            detected_category='general',
            category_confidence=0.8,
            attributes={},
            oracle_category_id=item.get('oracle_category_id'),
            oracle_unit_id=item.get('oracle_unit_id')
        )
    
    processor.process_material.side_effect = mock_process
    
    # Mock PostgreSQL会话
    pg_session = AsyncMock(spec=AsyncSession)
    pg_session.execute = AsyncMock()
    pg_session.commit = AsyncMock()
    
    # 模拟查询结果（第一个不存在，第二个存在）
    async def mock_execute(stmt):
        result = MagicMock()
        result.scalar_one_or_none.return_value = None  # 模拟不存在
        return result
    
    pg_session.execute.side_effect = mock_execute
    
    pipeline = ETLPipeline(
        oracle_adapter=oracle_adapter,
        pg_session=pg_session,
        material_processor=processor
    )
    
    # Act
    result = await pipeline.run_incremental_sync(since_time=since_time, batch_size=1000)
    
    # Assert
    assert result['status'] == 'success'
    assert result['processed_records'] == 2
    assert result['failed_records'] == 0
    assert 'duration_seconds' in result
    assert 'records_per_minute' in result
    
    # 验证连接和断开被调用
    oracle_adapter.connect.assert_called_once()
    oracle_adapter.disconnect.assert_called_once()
    
    # 验证处理器被调用
    assert processor.process_material.call_count == 2
    
    # 验证提交被调用
    assert pg_session.commit.call_count > 0
    
    print("✅ 测试1通过: 基础增量同步功能正常")


@pytest.mark.asyncio
async def test_incremental_sync_sql_format():
    """
    测试2: 验证增量同步SQL格式正确
    
    重点验证:
    1. SQL包含schema前缀 DHNC65
    2. SQL包含时间戳过滤条件
    3. SQL字段与全量同步一致
    """
    # Arrange
    since_time = "2025-10-01 00:00:00"
    captured_query = None
    captured_params = None
    
    # Mock generator来捕获SQL查询
    async def mock_generator(query, params, batch_size):
        nonlocal captured_query, captured_params
        captured_query = query
        captured_params = params
        yield []  # 返回空数据
    
    oracle_adapter = MagicMock()
    oracle_adapter.connect = AsyncMock()
    oracle_adapter.disconnect = AsyncMock()
    oracle_adapter.execute_query_generator = mock_generator
    
    processor = MagicMock(spec=SimpleMaterialProcessor)
    processor._knowledge_base_loaded = True
    
    pg_session = AsyncMock(spec=AsyncSession)
    pg_session.commit = AsyncMock()
    
    pipeline = ETLPipeline(
        oracle_adapter=oracle_adapter,
        pg_session=pg_session,
        material_processor=processor
    )
    
    # Act
    await pipeline.run_incremental_sync(since_time=since_time)
    
    # Assert - 验证SQL查询
    assert captured_query is not None, "SQL查询未被捕获"
    
    # 1. 验证schema前缀
    assert 'DHNC65.bd_material' in captured_query, "缺少schema前缀 DHNC65.bd_material"
    assert 'DHNC65.bd_marbasclass' in captured_query, "缺少schema前缀 DHNC65.bd_marbasclass"
    assert 'DHNC65.bd_measdoc' in captured_query, "缺少schema前缀 DHNC65.bd_measdoc"
    
    # 2. 验证时间戳过滤
    assert 'modifiedtime' in captured_query.lower(), "缺少modifiedtime过滤条件"
    assert 'TO_TIMESTAMP' in captured_query, "缺少TO_TIMESTAMP函数"
    
    # 3. 验证字段完整性（关键字段）
    assert 'category_name' in captured_query, "缺少category_name字段"
    assert 'category_code' in captured_query, "缺少category_code字段"
    assert 'unit_name' in captured_query, "缺少unit_name字段"
    assert 'unit_english_name' in captured_query, "缺少unit_english_name字段"
    
    # 4. 验证参数
    assert captured_params is not None, "SQL参数未被捕获"
    assert 'since_time' in captured_params, "缺少since_time参数"
    assert captured_params['since_time'] == since_time, "since_time参数值不正确"
    
    print("✅ 测试2通过: 增量同步SQL格式正确")
    print(f"   - Schema前缀: ✓")
    print(f"   - 时间戳过滤: ✓")
    print(f"   - 字段完整性: ✓")


@pytest.mark.asyncio
async def test_incremental_sync_upsert_mode():
    """
    测试3: 验证增量同步使用UPSERT模式
    
    验证增量同步能正确处理新增和更新两种情况
    """
    # Arrange
    since_time = "2025-10-01 00:00:00"
    
    batch = [
        {
            'erp_code': 'MAT_EXIST',
            'material_name': '已存在物料（已更新）',
            'specification': '新规格',
            'oracle_category_id': 'CAT001',
            'category_name': '轴承',
            'oracle_unit_id': 'UNIT001',
            'unit_name': '件',
            'enable_state': 2
        }
    ]
    
    # Mock generator
    async def mock_generator(query, params, batch_size):
        yield batch
    
    oracle_adapter = MagicMock()
    oracle_adapter.connect = AsyncMock()
    oracle_adapter.disconnect = AsyncMock()
    oracle_adapter.execute_query_generator = mock_generator
    
    processor = MagicMock(spec=SimpleMaterialProcessor)
    processor._knowledge_base_loaded = True
    processor.process_material.return_value = MaterialsMaster(
        erp_code='MAT_EXIST',
        material_name='已存在物料（已更新）',
        specification='新规格',
        normalized_name='已存在物料（已更新）',
        detected_category='bearing',
        category_confidence=0.9,
        attributes={}
    )
    
    # Mock PostgreSQL会话 - 模拟找到已存在记录
    existing_material = MaterialsMaster(
        id=123,
        erp_code='MAT_EXIST',
        material_name='已存在物料（旧版本）',
        specification='旧规格',
        normalized_name='已存在物料（旧版本）',
        detected_category='bearing',
        category_confidence=0.8,
        attributes={}
    )
    
    pg_session = AsyncMock(spec=AsyncSession)
    
    async def mock_execute(stmt):
        result = MagicMock()
        result.scalar_one_or_none.return_value = existing_material
        return result
    
    pg_session.execute.side_effect = mock_execute
    pg_session.commit = AsyncMock()
    
    pipeline = ETLPipeline(
        oracle_adapter=oracle_adapter,
        pg_session=pg_session,
        material_processor=processor
    )
    
    # Act
    result = await pipeline.run_incremental_sync(since_time=since_time)
    
    # Assert
    assert result['status'] == 'success'
    assert result['processed_records'] == 1
    
    # 验证执行了查询（检查是否存在）
    assert pg_session.execute.call_count > 0
    
    # 验证更新了已存在的记录
    assert existing_material.specification == '新规格', "已存在记录未被更新"
    
    # 验证提交
    pg_session.commit.assert_called()
    
    print("✅ 测试3通过: 增量同步UPSERT模式正常")


@pytest.mark.asyncio
async def test_incremental_sync_field_consistency():
    """
    测试4: 验证增量同步与全量同步字段一致性
    
    确保增量同步提取的字段与全量同步完全一致
    """
    # Arrange
    since_time = "2025-10-01 00:00:00"
    
    # 定义期望的字段列表（与全量同步一致）
    expected_fields = {
        'erp_code', 'material_name', 'specification', 'model',
        'oracle_category_id', 'category_name', 'category_code',
        'oracle_unit_id', 'unit_name', 'unit_english_name',
        'enable_state', 'english_name', 'english_spec',
        'short_name', 'mnemonic_code', 'memo',
        'oracle_created_time', 'oracle_modified_time', 'oracle_org_id'
    }
    
    captured_query = None
    
    async def mock_generator(query, params, batch_size):
        nonlocal captured_query
        captured_query = query
        yield []
    
    oracle_adapter = MagicMock()
    oracle_adapter.connect = AsyncMock()
    oracle_adapter.disconnect = AsyncMock()
    oracle_adapter.execute_query_generator = mock_generator
    
    processor = MagicMock(spec=SimpleMaterialProcessor)
    processor._knowledge_base_loaded = True
    
    pg_session = AsyncMock(spec=AsyncSession)
    pg_session.commit = AsyncMock()
    
    pipeline = ETLPipeline(
        oracle_adapter=oracle_adapter,
        pg_session=pg_session,
        material_processor=processor
    )
    
    # Act
    await pipeline.run_incremental_sync(since_time=since_time)
    
    # Assert
    assert captured_query is not None
    
    # 验证所有期望字段都在SQL中
    missing_fields = []
    for field in expected_fields:
        if field not in captured_query:
            missing_fields.append(field)
    
    assert len(missing_fields) == 0, f"增量同步缺少字段: {missing_fields}"
    
    print("✅ 测试4通过: 增量同步与全量同步字段一致")
    print(f"   - 验证字段数: {len(expected_fields)}")
    print(f"   - 缺失字段: {len(missing_fields)}")


@pytest.mark.asyncio
async def test_incremental_sync_empty_result():
    """
    测试5: 增量同步处理空结果
    
    验证当没有增量数据时，系统能正常处理
    """
    # Arrange
    since_time = "2025-10-03 00:00:00"  # 未来日期，确保无增量数据
    
    async def mock_generator(query, params, batch_size):
        # 不yield任何数据，直接返回
        return
        yield  # 永远不会执行
    
    oracle_adapter = MagicMock()
    oracle_adapter.connect = AsyncMock()
    oracle_adapter.disconnect = AsyncMock()
    oracle_adapter.execute_query_generator = mock_generator
    
    processor = MagicMock(spec=SimpleMaterialProcessor)
    processor._knowledge_base_loaded = True
    
    pg_session = AsyncMock(spec=AsyncSession)
    pg_session.commit = AsyncMock()
    
    pipeline = ETLPipeline(
        oracle_adapter=oracle_adapter,
        pg_session=pg_session,
        material_processor=processor
    )
    
    # Act
    result = await pipeline.run_incremental_sync(since_time=since_time)
    
    # Assert
    assert result['status'] == 'success'
    assert result['processed_records'] == 0
    assert result['failed_records'] == 0
    
    # 验证连接管理正常
    oracle_adapter.connect.assert_called_once()
    oracle_adapter.disconnect.assert_called_once()
    
    print("✅ 测试5通过: 增量同步正确处理空结果")


# ==================== 运行所有测试 ====================

if __name__ == '__main__':
    import asyncio
    
    async def run_all_tests():
        tests = [
            ("基础增量同步功能", test_incremental_sync_basic),
            ("增量同步SQL格式验证", test_incremental_sync_sql_format),
            ("增量同步UPSERT模式", test_incremental_sync_upsert_mode),
            ("增量同步字段一致性", test_incremental_sync_field_consistency),
            ("增量同步空结果处理", test_incremental_sync_empty_result),
        ]
        
        print("\n" + "="*80)
        print("开始运行增量同步专项测试")
        print("="*80 + "\n")
        
        passed = 0
        failed = 0
        
        for name, test_func in tests:
            try:
                print(f"\n运行测试: {name}")
                print("-"*80)
                await test_func()
                passed += 1
            except AssertionError as e:
                print(f"❌ 测试失败: {name}")
                print(f"   错误: {str(e)}")
                failed += 1
            except Exception as e:
                print(f"❌ 测试异常: {name}")
                print(f"   异常: {str(e)}")
                failed += 1
        
        print("\n" + "="*80)
        print(f"测试完成: {passed} 通过, {failed} 失败")
        print("="*80 + "\n")
    
    asyncio.run(run_all_tests())

