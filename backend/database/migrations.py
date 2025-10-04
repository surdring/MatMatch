"""
数据库迁移管理模块
实现数据库表结构创建、索引管理和迁移脚本

对应 [I.2] 编码策略中的迁移脚本实现
对应 [I.5] 风险缓解策略中的CREATE INDEX CONCURRENTLY方案
"""

import asyncio
import logging
from typing import List
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.session import db_manager
from backend.models.base import Base
from backend.models.materials import (
    MaterialsMaster, MaterialCategory, MeasurementUnit,
    ExtractionRule, Synonym, KnowledgeCategory  # Task 1.1重构 - 添加知识库表
)

# 配置日志
logger = logging.getLogger(__name__)


class DatabaseMigration:
    """
    数据库迁移管理器
    
    负责数据库表结构创建、索引管理和数据迁移
    对应 [I.2] - alembic迁移脚本的功能实现
    """
    
    def __init__(self):
        # 确保数据库已初始化
        if db_manager._engine is None:
            db_manager.initialize()
        self.engine = db_manager.engine
    
    async def create_extensions(self):
        """
        创建PostgreSQL扩展
        
        创建pg_trgm和unaccent扩展，支持模糊匹配和文本处理
        对应 [T.1] - 核心功能路径测试的基础要求
        """
        logger.info("🔧 创建PostgreSQL扩展...")
        
        extensions = [
            "CREATE EXTENSION IF NOT EXISTS pg_trgm;",
            "CREATE EXTENSION IF NOT EXISTS unaccent;",
        ]
        
        async with self.engine.begin() as conn:
            for extension_sql in extensions:
                try:
                    await conn.execute(text(extension_sql))
                    logger.info(f"✅ 扩展创建成功: {extension_sql}")
                except Exception as e:
                    logger.warning(f"⚠️ 扩展创建警告: {e}")
    
    async def create_tables(self):
        """
        创建数据库表结构
        
        基于SQLAlchemy模型定义创建所有表
        对应 [I.1] - DeclarativeBase.metadata.create_all的使用
        """
        logger.info("🏗️ 创建数据库表结构...")
        
        try:
            async with self.engine.begin() as conn:
                # 对应 [I.1] - AsyncConnection.run_sync用法
                await conn.run_sync(Base.metadata.create_all)
            
            logger.info("✅ 数据库表结构创建成功")
            
            # 验证表创建
            await self._verify_tables()
            
        except Exception as e:
            logger.error(f"❌ 创建表结构失败: {e}")
            raise
    
    async def create_indexes_concurrent(self):
        """
        并发创建数据库索引
        
        使用CREATE INDEX CONCURRENTLY避免阻塞，对应 [I.5] 风险缓解策略
        对应 [T.3] - pg_trgm索引性能测试的基础设施
        """
        logger.info("🔍 并发创建数据库索引...")
        
        # 对应 [I.3] - pg_trgm并发创建策略的具体实现
        indexes = [
            # 物料查询性能索引 - 对应 [T.3] ≤500ms性能要求
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_materials_normalized_name_trgm 
            ON materials_master USING gin (normalized_name gin_trgm_ops)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_materials_full_description_trgm 
            ON materials_master USING gin (full_description gin_trgm_ops)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_materials_attributes_gin 
            ON materials_master USING gin (attributes)
            """,
            
            # 基础查询索引
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_materials_erp_code 
            ON materials_master (erp_code)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_materials_category_confidence 
            ON materials_master (detected_category, category_confidence DESC)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_materials_enable_state 
            ON materials_master (enable_state) WHERE enable_state = 2
            """,
            
            # 分类表索引
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_categories_code 
            ON material_categories (category_code)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_categories_oracle_id 
            ON material_categories (oracle_category_id)
            """,
            
            # 单位表索引
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_units_code 
            ON measurement_units (unit_code)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_units_oracle_id 
            ON measurement_units (oracle_unit_id)
            """,
            
            # ============ Task 1.1重构 - 知识库表索引 ============
            # 提取规则表索引 - 对应 [T.1.4] 规则导入测试
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_extraction_rules_category 
            ON extraction_rules (material_category)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_extraction_rules_attribute 
            ON extraction_rules (attribute_name)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_extraction_rules_priority 
            ON extraction_rules (priority DESC)
            """,
            
            # 同义词表索引 - 对应 [T.1.5] 同义词导入测试
            # 组合索引支持高效的同义词查找 - 对应 [I.3] 索引优化策略
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_synonym_lookup 
            ON synonyms (synonym_term, standard_term)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_synonym_standard 
            ON synonyms (standard_term)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_synonym_category 
            ON synonyms (category)
            """,
            
            # 知识库类别表索引 - 对应 [T.1.6] 类别导入测试
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_knowledge_category_name 
            ON knowledge_categories (category_name)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_knowledge_category_keywords_gin 
            ON knowledge_categories USING gin (keywords)
            """,
            
            """
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_knowledge_category_active 
            ON knowledge_categories (is_active) WHERE is_active = true
            """,
        ]
        
        # 创建单独的连接用于并发索引创建
        async with self.engine.connect() as conn:
            for i, index_sql in enumerate(indexes, 1):
                try:
                    logger.info(f"🔍 创建索引 {i}/{len(indexes)}...")
                    await conn.execute(text(index_sql))
                    await conn.commit()  # 每个索引独立提交
                    logger.info(f"✅ 索引 {i} 创建成功")
                    
                    # 短暂等待，避免数据库压力过大
                    await asyncio.sleep(0.5)
                    
                except Exception as e:
                    logger.warning(f"⚠️ 索引 {i} 创建警告: {e}")
                    await conn.rollback()
        
        logger.info("✅ 所有索引创建完成")
    
    async def _verify_tables(self):
        """
        验证表创建结果
        
        检查关键表是否存在，对应 [T.1] 核心功能路径测试
        """
        logger.info("🔍 验证表创建结果...")
        
        table_checks = [
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'materials_master'",
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'material_categories'", 
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'measurement_units'",
            # Task 1.1重构 - 验证知识库表
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'extraction_rules'",
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'synonyms'",
            "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'knowledge_categories'",
        ]
        
        async with self.engine.connect() as conn:
            for sql in table_checks:
                result = await conn.execute(text(sql))
                count = result.scalar()
                table_name = sql.split("'")[1]
                
                if count == 1:
                    logger.info(f"✅ 表 {table_name} 存在")
                else:
                    logger.error(f"❌ 表 {table_name} 不存在")
                    raise Exception(f"表 {table_name} 创建失败")
    
    async def drop_tables(self):
        """
        删除所有表（仅用于测试和重建）
        
        危险操作，仅在开发环境使用
        对应 [T.2] 边界情况测试中的数据库重置需求
        """
        logger.warning("⚠️ 删除所有表结构（危险操作）...")
        
        async with self.engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        
        logger.warning("🗑️ 所有表已删除")
    
    async def get_migration_status(self) -> dict:
        """
        获取迁移状态信息
        
        返回数据库表和索引的状态信息
        对应监控和运维需求
        
        Returns:
            dict: 迁移状态信息
        """
        logger.info("📊 获取迁移状态...")
        
        status = {
            "tables": {},
            "indexes": {},
            "extensions": {}
        }
        
        async with self.engine.connect() as conn:
            # 检查表状态
            table_sql = """
                SELECT table_name, 
                       (SELECT COUNT(*) FROM information_schema.columns 
                        WHERE table_name = t.table_name) as column_count
                FROM information_schema.tables t 
                WHERE table_schema = 'public' 
                ORDER BY table_name
            """
            
            result = await conn.execute(text(table_sql))
            for row in result:
                status["tables"][row[0]] = {
                    "exists": True,
                    "column_count": row[1]
                }
            
            # 检查索引状态
            index_sql = """
                SELECT indexname, tablename 
                FROM pg_indexes 
                WHERE schemaname = 'public' 
                ORDER BY tablename, indexname
            """
            
            result = await conn.execute(text(index_sql))
            for row in result:
                if row[1] not in status["indexes"]:
                    status["indexes"][row[1]] = []
                status["indexes"][row[1]].append(row[0])
            
            # 检查扩展状态
            ext_sql = "SELECT extname FROM pg_extension WHERE extname IN ('pg_trgm', 'unaccent')"
            result = await conn.execute(text(ext_sql))
            for row in result:
                status["extensions"][row[0]] = True
        
        return status


# 全局迁移管理器
migration_manager = DatabaseMigration()


async def run_full_migration():
    """
    运行完整的数据库迁移
    
    执行完整的数据库初始化流程
    对应 [I.2] 编码策略中的迁移脚本执行
    """
    logger.info("🚀 开始完整数据库迁移...")
    
    try:
        # 1. 创建扩展
        await migration_manager.create_extensions()
        
        # 2. 创建表结构
        await migration_manager.create_tables()
        
        # 3. 创建索引
        await migration_manager.create_indexes_concurrent()
        
        # 4. 验证迁移状态
        status = await migration_manager.get_migration_status()
        logger.info(f"📊 迁移完成状态: {status}")
        
        logger.info("🎉 数据库迁移完成！")
        return True
        
    except Exception as e:
        logger.error(f"❌ 数据库迁移失败: {e}")
        return False


if __name__ == "__main__":
    """
    独立运行迁移脚本
    
    支持命令行执行数据库迁移
    """
    asyncio.run(run_full_migration())
