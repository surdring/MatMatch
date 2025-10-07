"""测试统计API"""
import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from backend.core.config import database_config

async def test_stats():
    engine = create_async_engine(database_config.database_url)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        try:
            # 获取物料总数
            result = await session.execute(text('SELECT COUNT(*) FROM materials_master'))
            total_materials = result.scalar()
            print(f"✅ 物料总数: {total_materials:,}")
            
            # 获取分类总数
            result = await session.execute(text('SELECT COUNT(*) FROM material_categories'))
            total_categories = result.scalar()
            print(f"✅ 分类总数: {total_categories:,}")
            
            # 获取知识库统计
            result = await session.execute(text('SELECT COUNT(*) FROM knowledge_synonyms'))
            total_synonyms = result.scalar()
            print(f"✅ 同义词总数: {total_synonyms:,}")
            
            result = await session.execute(text('SELECT COUNT(*) FROM knowledge_extraction_rules'))
            total_rules = result.scalar()
            print(f"✅ 提取规则数: {total_rules}")
            
        except Exception as e:
            print(f"❌ 错误: {e}")
            import traceback
            traceback.print_exc()
        finally:
            await engine.dispose()

if __name__ == "__main__":
    asyncio.run(test_stats())

