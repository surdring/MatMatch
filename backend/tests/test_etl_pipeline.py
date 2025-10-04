"""
ETL管道单元测试

测试ETLPipeline的核心功能
"""

import pytest
import sys
from pathlib import Path
from datetime import datetime
from unittest.mock import MagicMock, AsyncMock, patch
from typing import AsyncGenerator

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from backend.etl.etl_pipeline import ETLPipeline
from backend.etl.material_processor import SimpleMaterialProcessor
from backend.etl.etl_config import ETLConfig
from backend.adapters.oracle_adapter import OracleConnectionAdapter
from backend.core.config import OracleConfig
from backend.models.materials import MaterialsMaster
from sqlalchemy.ext.asyncio import AsyncSession


# ==================== 核心功能测试 ====================

@pytest.mark.asyncio
async def test_etl_pipeline_initialization():
    """
    测试1: ETL管道初始化
    """
    # Arrange
    oracle_config = OracleConfig(
        host="localhost",
        port=1521,
        service_name="testdb",
        username="test_user",
        password="test_pass"
    )
    oracle_adapter = OracleConnectionAdapter(oracle_config)
    pg_session = AsyncMock(spec=AsyncSession)
    processor = MagicMock(spec=SimpleMaterialProcessor)
    
    # Act
    pipeline = ETLPipeline(
        oracle_adapter=oracle_adapter,
        pg_session=pg_session,
        material_processor=processor
    )
    
    # Assert
    assert pipeline.oracle_adapter is not None
    assert pipeline.pg_session is not None
    assert pipeline.processor is not None
    assert pipeline.processed_count == 0
    assert pipeline.failed_count == 0
    print("✅ 测试1通过: ETL管道初始化成功")


@pytest.mark.asyncio
async def test_extract_materials_batch_with_join():
    """
    测试2: 验证多表JOIN数据提取功能
    """
    # Arrange
    mock_oracle_data = [
        {
            'erp_code': 'MAT001',
            'material_name': '深沟球軸承',
            'specification': '６２０６',
            'model': 'ＳＫＦ',
            'oracle_category_id': 'CAT001',
            'category_name': '轴承',  # JOIN获取
            'oracle_unit_id': 'UNIT001',
            'unit_name': '个',  # JOIN获取
            'enable_state': 2
        },
        {
            'erp_code': 'MAT002',
            'material_name': '不锈钢管',
            'specification': 'DN50',
            'model': 'Φ100',
            'oracle_category_id': 'CAT002',
            'category_name': '管件',
            'oracle_unit_id': 'UNIT002',
            'unit_name': '米',
            'enable_state': 2
        }
    ]
    
    oracle_adapter = MagicMock()
    oracle_adapter.execute_query = AsyncMock(return_value=mock_oracle_data)
    
    pg_session = AsyncMock(spec=AsyncSession)
    processor = MagicMock(spec=SimpleMaterialProcessor)
    
    pipeline = ETLPipeline(
        oracle_adapter=oracle_adapter,
        pg_session=pg_session,
        material_processor=processor
    )
    
    # Act
    batch = await pipeline._extract_materials_batch(batch_size=10, offset=0)
    
    # Assert
    assert len(batch) == 2
    assert batch[0]['category_name'] == '轴承'
    assert batch[0]['unit_name'] == '个'
    assert batch[1]['category_name'] == '管件'
    assert batch[1]['unit_name'] == '米'
    
    # 验证SQL查询包含JOIN（带schema前缀）
    call_args = oracle_adapter.execute_query.call_args
    query = call_args[0][0]
    assert 'LEFT JOIN DHNC65.bd_marbasclass' in query
    assert 'LEFT JOIN DHNC65.bd_measdoc' in query
    
    print("✅ 测试2通过: 多表JOIN数据提取成功")


@pytest.mark.asyncio
async def test_process_batch_symmetric_algorithm():
    """
    测试3: 验证对称处理算法正确应用
    """
    # Arrange
    raw_batch = [
        {
            'erp_code': 'MAT001',
            'material_name': '深沟球軸承',
            'specification': '６２０６',
            'model': 'ＳＫＦ',
            'oracle_category_id': 'CAT001',
            'category_name': '轴承',
            'oracle_unit_id': 'UNIT001',
            'unit_name': '个'
        }
    ]
    
    # Mock SimpleMaterialProcessor
    processor = MagicMock(spec=SimpleMaterialProcessor)
    processed_material = MaterialsMaster(
        erp_code='MAT001',
        material_name='深沟球軸承',
        specification='６２０６',
        model='ＳＫＦ',
        # 对称处理输出
        normalized_name='深沟球轴承 6206',
        full_description='深沟球轴承 6206 SKF',
        attributes={'brand_name': 'SKF', 'bearing_code': '6206'},
        detected_category='轴承',
        category_confidence=0.85,
        last_processed_at=datetime.now()
    )
    processor.process_material.return_value = processed_material
    
    oracle_adapter = MagicMock()
    pg_session = AsyncMock(spec=AsyncSession)
    
    pipeline = ETLPipeline(
        oracle_adapter=oracle_adapter,
        pg_session=pg_session,
        material_processor=processor
    )
    
    # Act
    result = await pipeline._process_batch(raw_batch)
    
    # Assert
    assert len(result) == 1
    assert result[0].normalized_name == '深沟球轴承 6206'
    assert result[0].attributes['brand_name'] == 'SKF'
    assert result[0].detected_category == '轴承'
    assert result[0].category_confidence == 0.85
    
    # 验证processor被调用
    processor.process_material.assert_called_once()
    
    print("✅ 测试3通过: 对称处理算法应用成功")


@pytest.mark.asyncio
async def test_load_batch_with_transaction():
    """
    测试4: 验证批量写入PostgreSQL带事务管理
    """
    # Arrange
    materials = [
        MaterialsMaster(
            erp_code='MAT001',
            material_name='测试物料1',
            normalized_name='测试物料1',
            detected_category='general',
            category_confidence=0.5,
            attributes={}
        ),
        MaterialsMaster(
            erp_code='MAT002',
            material_name='测试物料2',
            normalized_name='测试物料2',
            detected_category='general',
            category_confidence=0.5,
            attributes={}
        )
    ]
    
    # Mock AsyncSession
    pg_session = AsyncMock(spec=AsyncSession)
    pg_session.add_all = MagicMock()
    pg_session.commit = AsyncMock()
    pg_session.rollback = AsyncMock()
    
    oracle_adapter = MagicMock()
    processor = MagicMock(spec=SimpleMaterialProcessor)
    
    pipeline = ETLPipeline(
        oracle_adapter=oracle_adapter,
        pg_session=pg_session,
        material_processor=processor
    )
    
    # Act
    count = await pipeline._load_batch(materials)
    
    # Assert
    assert count == 2
    pg_session.add_all.assert_called_once()
    pg_session.commit.assert_called_once()
    pg_session.rollback.assert_not_called()
    
    print("✅ 测试4通过: 批量写入事务管理成功")


@pytest.mark.asyncio
async def test_run_full_sync_flow():
    """
    测试5: 验证全量同步基本流程（简化版）
    """
    # Arrange
    mock_oracle_data = [
        {'erp_code': 'MAT001', 'material_name': '物料1', 'enable_state': 2},
        {'erp_code': 'MAT002', 'material_name': '物料2', 'enable_state': 2}
    ]
    
    oracle_adapter = MagicMock()
    oracle_adapter.connect = AsyncMock()
    oracle_adapter.disconnect = AsyncMock()
    oracle_adapter.execute_query = AsyncMock(side_effect=[
        mock_oracle_data,  # 第一次返回数据
        []  # 第二次返回空，结束循环
    ])
    
    processor = MagicMock(spec=SimpleMaterialProcessor)
    processor._knowledge_base_loaded = True
    processor.process_material.side_effect = [
        MaterialsMaster(
            erp_code='MAT001',
            material_name='物料1',
            normalized_name='物料1',
            detected_category='general',
            category_confidence=0.5,
            attributes={}
        ),
        MaterialsMaster(
            erp_code='MAT002',
            material_name='物料2',
            normalized_name='物料2',
            detected_category='general',
            category_confidence=0.5,
            attributes={}
        )
    ]
    
    pg_session = AsyncMock(spec=AsyncSession)
    pg_session.add_all = MagicMock()
    pg_session.commit = AsyncMock()
    
    pipeline = ETLPipeline(
        oracle_adapter=oracle_adapter,
        pg_session=pg_session,
        material_processor=processor
    )
    
    # Act
    result = await pipeline.run_full_sync(batch_size=10)
    
    # Assert
    assert result['status'] == 'success'
    assert result['processed_records'] == 2
    assert result['failed_records'] == 0
    assert 'duration_seconds' in result
    assert 'records_per_minute' in result
    
    oracle_adapter.connect.assert_called_once()
    oracle_adapter.disconnect.assert_called_once()
    
    print("✅ 测试5通过: 全量同步流程成功")


@pytest.mark.asyncio
async def test_config_usage():
    """
    测试6: 验证配置管理
    """
    # Arrange
    custom_config = ETLConfig(
        batch_size=500,
        load_batch_size=250,
        skip_failed_records=False
    )
    
    oracle_adapter = MagicMock()
    pg_session = AsyncMock(spec=AsyncSession)
    processor = MagicMock(spec=SimpleMaterialProcessor)
    
    # Act
    pipeline = ETLPipeline(
        oracle_adapter=oracle_adapter,
        pg_session=pg_session,
        material_processor=processor,
        config=custom_config
    )
    
    # Assert
    assert pipeline.config.batch_size == 500
    assert pipeline.config.load_batch_size == 250
    assert pipeline.config.skip_failed_records is False
    
    print("✅ 测试6通过: 配置管理成功")


# ==================== 运行所有测试 ====================

if __name__ == '__main__':
    print("\n" + "="*80)
    print("开始运行ETL管道核心功能测试")
    print("="*80 + "\n")
    
    import asyncio
    
    async def run_all_tests():
        tests = [
            ("ETL管道初始化", test_etl_pipeline_initialization),
            ("多表JOIN数据提取", test_extract_materials_batch_with_join),
            ("对称处理算法应用", test_process_batch_symmetric_algorithm),
            ("批量写入事务管理", test_load_batch_with_transaction),
            ("全量同步流程", test_run_full_sync_flow),
            ("配置管理", test_config_usage),
        ]
        
        passed = 0
        failed = 0
        
        for name, test_func in tests:
            try:
                print(f"\n运行测试: {name}")
                await test_func()
                passed += 1
            except Exception as e:
                print(f"❌ 测试失败: {name}")
                print(f"   错误: {str(e)}")
                failed += 1
        
        print("\n" + "="*80)
        print(f"测试结果: {passed}个通过, {failed}个失败")
        print("="*80 + "\n")
        
        return failed == 0
    
    success = asyncio.run(run_all_tests())
    sys.exit(0 if success else 1)

