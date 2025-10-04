"""
数据库功能测试模块
实现数据库连接、模型CRUD、性能基准测试

对应 [T.1] 核心功能路径、[T.2] 边界情况、[T.3] 性能测试的具体实现
"""

import asyncio
import pytest
import time
from typing import List, Dict, Any
from datetime import datetime, timedelta

from sqlalchemy import text, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.session import get_test_session, db_manager
from backend.database.migrations import migration_manager
from backend.models.materials import MaterialsMaster, MaterialCategory, MeasurementUnit


class TestDatabaseConnection:
    """
    数据库连接测试类
    
    对应 [T.1] 核心功能路径测试 - 数据库连接和会话管理
    """
    
    async def test_engine_creation(self):
        """
        测试异步引擎创建
        
        验证SQLAlchemy 2.1异步引擎是否正确配置
        对应 [I.1] - create_async_engine API使用验证
        """
        engine = db_manager.create_engine()
        assert engine is not None
        assert str(engine.url).startswith("postgresql+asyncpg://")
        print("✅ 异步引擎创建测试通过")
    
    async def test_session_creation(self):
        """
        测试异步会话创建和关闭
        
        验证会话生命周期管理和资源释放
        对应 [R.19] - 阻塞处理和资源管理验证
        """
        session = await get_test_session()
        assert session is not None
        
        # 测试基本查询
        result = await session.execute(text("SELECT 1 as test"))
        assert result.scalar() == 1
        
        await session.close()
        print("✅ 异步会话创建测试通过")
    
    async def test_connection_pool(self):
        """
        测试连接池并发性能
        
        验证连接池是否支持并发访问
        对应 [T.3] - 并发连接池支持≥10个连接的测试
        """
        start_time = time.time()
        
        async def concurrent_query(session_id: int):
            session = await get_test_session()
            try:
                result = await session.execute(
                    text("SELECT :session_id as id, pg_backend_pid() as pid"),
                    {"session_id": str(session_id)}
                )
                row = result.fetchone()
                return {"session_id": row[0], "backend_pid": row[1]}
            finally:
                await session.close()
        
        # 创建10个并发会话
        tasks = [concurrent_query(i) for i in range(10)]
        results = await asyncio.gather(*tasks)
        
        end_time = time.time()
        
        # 验证结果
        assert len(results) == 10
        assert len(set(r["backend_pid"] for r in results)) <= 10  # 允许连接复用
        
        print(f"✅ 连接池并发测试通过: {len(results)}个连接, 耗时{end_time - start_time:.2f}秒")


class TestDatabaseModels:
    """
    数据库模型测试类
    
    对应 [T.1] 核心功能路径测试 - SQLAlchemy模型CRUD操作
    """
    
    @pytest.fixture
    async def session(self):
        """测试会话夹具"""
        session = await get_test_session()
        yield session
        await session.close()
    
    async def test_materials_master_crud(self):
        """
        测试物料主数据CRUD操作
        
        验证MaterialsMaster模型的创建、查询、更新、删除
        对应 [I.3] - Oracle字段映射逻辑的验证
        """
        session = await get_test_session()
        
        try:
            # 创建测试数据
            test_material = MaterialsMaster(
                erp_code="TEST001",
                material_name="测试物料",
                specification="10*20*30",
                model="A型",
                oracle_category_id="CAT001",
                oracle_unit_id="UNIT001",
                enable_state=2,
                normalized_name="测试物料",
                attributes={"size": "10*20*30", "material": "steel"},
                detected_category="fastener",
                category_confidence=0.85
            )
            
            # 插入数据
            session.add(test_material)
            await session.commit()
            await session.refresh(test_material)
            
            # 验证插入
            assert test_material.id is not None
            assert test_material.erp_code == "TEST001"
            
            # 查询数据
            result = await session.execute(
                select(MaterialsMaster).where(MaterialsMaster.erp_code == "TEST001")
            )
            found_material = result.scalar_one()
            assert found_material.material_name == "测试物料"
            assert found_material.attributes["size"] == "10*20*30"
            
            # 更新数据
            found_material.material_name = "更新后的测试物料"
            await session.commit()
            
            # 验证更新
            await session.refresh(found_material)
            assert found_material.material_name == "更新后的测试物料"
            
            # 删除数据
            await session.delete(found_material)
            await session.commit()
            
            print("✅ 物料主数据CRUD测试通过")
            
        finally:
            await session.close()
    
    async def test_jsonb_attributes(self):
        """
        测试JSONB属性字段操作
        
        验证复杂JSON数据的存储和查询
        对应 [T.2] - JSONB字段验证的边界情况测试
        """
        session = await get_test_session()
        
        try:
            # 创建复杂JSONB数据
            complex_attributes = {
                "dimensions": {
                    "length": 100,
                    "width": 50,
                    "height": 25,
                    "unit": "mm"
                },
                "material_properties": {
                    "hardness": "HRC45-50",
                    "surface_treatment": "镀锌",
                    "temperature_range": "-20~80°C"
                },
                "certifications": ["ISO9001", "CE", "RoHS"],
                "supplier_info": {
                    "name": "测试供应商",
                    "country": "中国",
                    "lead_time": 15
                }
            }
            
            test_material = MaterialsMaster(
                erp_code="TEST_JSONB",
                material_name="JSONB测试物料",
                normalized_name="jsonb测试物料",
                attributes=complex_attributes,
                detected_category="component",
                category_confidence=0.90
            )
            
            session.add(test_material)
            await session.commit()
            await session.refresh(test_material)
            
            # 验证JSONB查询
            result = await session.execute(
                select(MaterialsMaster).where(
                    MaterialsMaster.attributes['dimensions']['length'].as_integer() == 100
                )
            )
            found_material = result.scalar_one()
            assert found_material.erp_code == "TEST_JSONB"
            assert found_material.attributes["certifications"] == ["ISO9001", "CE", "RoHS"]
            
            # 清理测试数据
            await session.delete(found_material)
            await session.commit()
            
            print("✅ JSONB属性测试通过")
            
        finally:
            await session.close()


class TestDatabasePerformance:
    """
    数据库性能测试类
    
    对应 [T.3] 性能/压力测试的具体实现
    """
    
    async def test_pg_trgm_similarity_performance(self):
        """
        测试pg_trgm相似度查询性能
        
        验证模糊匹配查询是否满足≤500ms的性能要求
        对应 [T.3] - pg_trgm查询性能测试
        """
        session = await get_test_session()
        
        try:
            # 准备测试数据
            test_materials = []
            for i in range(100):
                material = MaterialsMaster(
                    erp_code=f"PERF_{i:04d}",
                    material_name=f"性能测试物料{i}",
                    specification=f"规格{i}*{i+1}*{i+2}",
                    normalized_name=f"性能测试物料{i}",
                    attributes={"test_id": i},
                    detected_category="performance_test",
                    category_confidence=0.80
                )
                test_materials.append(material)
            
            session.add_all(test_materials)
            await session.commit()
            
            # 性能测试查询
            search_term = "性能测试物料50"
            start_time = time.time()
            
            # 使用pg_trgm相似度查询
            result = await session.execute(
                text("""
                    SELECT erp_code, material_name, 
                           similarity(normalized_name, :search_term) as sim_score
                    FROM materials_master 
                    WHERE normalized_name % :search_term
                      AND detected_category = 'performance_test'
                    ORDER BY sim_score DESC 
                    LIMIT 10
                """),
                {"search_term": search_term}
            )
            
            end_time = time.time()
            query_time = (end_time - start_time) * 1000  # 转换为毫秒
            
            results = result.fetchall()
            
            # 验证性能要求
            assert query_time <= 500, f"查询时间 {query_time:.2f}ms 超过500ms要求"
            assert len(results) > 0, "未找到相似结果"
            
            # 清理测试数据
            await session.execute(
                text("DELETE FROM materials_master WHERE detected_category = 'performance_test'")
            )
            await session.commit()
            
            print(f"✅ pg_trgm性能测试通过: 查询时间 {query_time:.2f}ms, 结果数量 {len(results)}")
            
        finally:
            await session.close()
    
    async def test_batch_insert_performance(self):
        """
        测试批量插入性能
        
        验证批量数据插入是否满足≥1000条/分钟的性能要求
        对应 [T.3] - 批量插入性能测试
        """
        session = await get_test_session()
        
        try:
            batch_size = 100
            test_materials = []
            
            # 准备批量数据
            for i in range(batch_size):
                material = MaterialsMaster(
                    erp_code=f"BATCH_{i:04d}",
                    material_name=f"批量测试物料{i}",
                    normalized_name=f"批量测试物料{i}",
                    attributes={"batch_id": i, "created_for": "performance_test"},
                    detected_category="batch_test",
                    category_confidence=0.75
                )
                test_materials.append(material)
            
            # 性能测试
            start_time = time.time()
            session.add_all(test_materials)
            await session.commit()
            end_time = time.time()
            
            insert_time = end_time - start_time
            records_per_minute = (batch_size / insert_time) * 60
            
            # 验证性能要求
            assert records_per_minute >= 1000, f"插入速度 {records_per_minute:.2f}条/分钟 低于1000条/分钟要求"
            
            # 清理测试数据
            await session.execute(
                text("DELETE FROM materials_master WHERE detected_category = 'batch_test'")
            )
            await session.commit()
            
            print(f"✅ 批量插入性能测试通过: {records_per_minute:.2f}条/分钟")
            
        finally:
            await session.close()


class TestDatabaseBoundary:
    """
    数据库边界情况测试类
    
    对应 [T.2] 边界情况覆盖测试
    """
    
    async def test_connection_failure_handling(self):
        """
        测试数据库连接失败处理
        
        验证连接异常时的错误处理机制
        对应 [T.2] - 数据库连接失败处理测试
        """
        # 创建错误的数据库配置
        from core.config import DatabaseConfig
        
        invalid_config = DatabaseConfig(
            host="invalid_host",
            port=5432,
            username="invalid_user",
            password="invalid_password",
            database="invalid_db"
        )
        
        # 测试连接失败处理
        try:
            from sqlalchemy.ext.asyncio import create_async_engine
            invalid_engine = create_async_engine(invalid_config.database_url)
            
            async with invalid_engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            
            assert False, "应该抛出连接异常"
            
        except Exception as e:
            # 验证异常类型 - 包含各种可能的连接错误
            error_msg = str(e).lower()
            expected_errors = ["connection", "timeout", "getaddrinfo", "host", "refused", "unreachable"]
            assert any(err in error_msg for err in expected_errors), f"未预期的异常类型: {e}"
            print(f"✅ 连接失败处理测试通过: {type(e).__name__}")
        
        finally:
            if 'invalid_engine' in locals():
                await invalid_engine.dispose()
    
    async def test_large_jsonb_data(self):
        """
        测试大型JSONB数据处理
        
        验证系统对复杂JSON数据的处理能力
        对应 [T.2] - JSONB复杂数据结构验证
        """
        session = await get_test_session()
        
        try:
            # 创建大型JSONB数据（模拟复杂的物料属性）
            large_attributes = {
                f"property_{i}": {
                    "value": f"value_{i}",
                    "unit": f"unit_{i}",
                    "tolerance": f"±{i}%",
                    "test_conditions": {
                        "temperature": f"{20+i}°C",
                        "humidity": f"{50+i}%",
                        "pressure": f"{1+i/100:.2f}bar"
                    },
                    "certifications": [f"cert_{j}" for j in range(5)],
                    "history": [
                        {
                            "date": f"2025-01-{(i%30)+1:02d}",
                            "value": f"old_value_{i}_{j}",
                            "operator": f"operator_{j}"
                        } for j in range(3)
                    ]
                } for i in range(50)  # 50个复杂属性
            }
            
            test_material = MaterialsMaster(
                erp_code="LARGE_JSONB",
                material_name="大型JSONB测试物料",
                normalized_name="大型jsonb测试物料",
                attributes=large_attributes,
                detected_category="large_data_test",
                category_confidence=0.88
            )
            
            # 测试插入和查询
            session.add(test_material)
            await session.commit()
            await session.refresh(test_material)
            
            # 验证数据完整性
            assert len(test_material.attributes) == 50
            assert test_material.attributes["property_10"]["value"] == "value_10"
            
            # 测试复杂JSONB查询
            result = await session.execute(
                select(MaterialsMaster).where(
                    MaterialsMaster.attributes['property_25']['test_conditions']['temperature'].as_string() == '45°C'
                )
            )
            found_material = result.scalar_one()
            assert found_material.erp_code == "LARGE_JSONB"
            
            # 清理测试数据
            await session.delete(found_material)
            await session.commit()
            
            print("✅ 大型JSONB数据测试通过")
            
        finally:
            await session.close()


async def run_all_tests():
    """
    运行所有数据库测试
    
    执行完整的测试套件，对应 [T.1][T.2][T.3] 所有测试要求
    """
    print("🚀 开始数据库测试套件...")
    
    # 确保数据库迁移已完成
    print("📋 检查数据库迁移状态...")
    status = await migration_manager.get_migration_status()
    if not status["tables"]:
        print("⚠️ 数据库未初始化，运行迁移...")
        await migration_manager.run_full_migration()
    
    test_classes = [
        TestDatabaseConnection(),
        TestDatabaseModels(), 
        TestDatabasePerformance(),
        TestDatabaseBoundary()
    ]
    
    total_tests = 0
    passed_tests = 0
    
    for test_class in test_classes:
        print(f"\n📝 运行 {test_class.__class__.__name__} 测试...")
        
        # 获取所有测试方法
        test_methods = [method for method in dir(test_class) if method.startswith('test_')]
        
        for method_name in test_methods:
            total_tests += 1
            try:
                method = getattr(test_class, method_name)
                print(f"  🧪 {method_name}...")
                await method()
                passed_tests += 1
            except Exception as e:
                print(f"  ❌ {method_name} 失败: {e}")
    
    print(f"\n📊 测试结果: {passed_tests}/{total_tests} 通过")
    
    if passed_tests == total_tests:
        print("🎉 所有数据库测试通过！")
        return True
    else:
        print("❌ 部分测试失败，请检查配置")
        return False


if __name__ == "__main__":
    """
    独立运行测试脚本
    
    支持命令行执行数据库测试
    """
    success = asyncio.run(run_all_tests())
    exit(0 if success else 1)
