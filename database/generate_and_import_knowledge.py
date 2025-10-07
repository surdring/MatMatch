"""
从PostgreSQL清洗后的数据生成知识库并直接导入数据库（一步到位）

此脚本：
1. 从materials_master表加载清洗后的数据
2. 生成提取规则、同义词、分类关键词
3. 直接导入到数据库表中
4. 无需中间JSON文件
"""

import asyncio
import sys
from pathlib import Path
from datetime import datetime

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text
from backend.core.config import database_config
from database.material_knowledge_generator import MaterialKnowledgeGenerator
from backend.models.materials import ExtractionRule, Synonym, KnowledgeCategory
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def clear_existing_data(session: AsyncSession):
    """清空现有知识库数据"""
    logger.info("🗑️  清空现有知识库数据...")
    
    try:
        # 清空表（保留表结构）
        await session.execute(text("TRUNCATE TABLE extraction_rules, synonyms, knowledge_categories RESTART IDENTITY CASCADE"))
        await session.commit()
        logger.info("✅ 已清空现有数据")
    except Exception as e:
        logger.error(f"❌ 清空数据失败: {e}")
        await session.rollback()
        raise


async def import_extraction_rules(session: AsyncSession, rules: list):
    """导入提取规则"""
    logger.info(f"📥 导入 {len(rules)} 条提取规则...")
    
    for rule in rules:
        db_rule = ExtractionRule(
            rule_name=rule['rule_name'],
            material_category=rule['material_category'],
            attribute_name=rule['attribute_name'],
            regex_pattern=rule['regex_pattern'],
            priority=rule.get('priority', 0),
            confidence=rule.get('confidence', 0.5),
            is_active=rule.get('is_active', True),
            description=rule.get('description', ''),
            example_input=rule.get('example_input', ''),
            example_output=rule.get('example_output', ''),
            created_by=rule.get('created_by', 'system')
        )
        session.add(db_rule)
    
    await session.commit()
    logger.info("✅ 提取规则导入完成")


async def import_synonyms(session: AsyncSession, synonym_dict: dict):
    """导入同义词"""
    # 将字典转换为记录列表
    synonym_records = []
    for standard_term, variants in synonym_dict.items():
        for variant in variants:
            if variant != standard_term:
                synonym_records.append({
                    'original_term': variant,
                    'standard_term': standard_term
                })
    
    logger.info(f"📥 导入 {len(synonym_records)} 条同义词记录...")
    
    for record in synonym_records:
        db_synonym = Synonym(
            original_term=record['original_term'],
            standard_term=record['standard_term']
        )
        session.add(db_synonym)
    
    await session.commit()
    logger.info("✅ 同义词导入完成")


async def import_category_keywords(session: AsyncSession, category_keywords: dict):
    """导入分类关键词"""
    logger.info(f"📥 导入 {len(category_keywords)} 个分类的关键词...")
    
    for category_name, keywords in category_keywords.items():
        if keywords:  # 只导入有关键词的分类
            db_category = KnowledgeCategory(
                category_name=category_name,
                keywords=keywords
            )
            session.add(db_category)
    
    await session.commit()
    logger.info("✅ 分类关键词导入完成")


async def verify_import(session: AsyncSession):
    """验证导入结果"""
    logger.info("\n" + "=" * 80)
    logger.info("🔍 验证导入结果...")
    logger.info("=" * 80)
    
    # 统计各表数据量
    result = await session.execute(text("SELECT COUNT(*) FROM extraction_rules"))
    rules_count = result.scalar()
    
    result = await session.execute(text("SELECT COUNT(*) FROM synonyms"))
    synonyms_count = result.scalar()
    
    result = await session.execute(text("SELECT COUNT(*) FROM knowledge_categories"))
    categories_count = result.scalar()
    
    logger.info(f"✅ 提取规则: {rules_count} 条")
    logger.info(f"✅ 同义词: {synonyms_count} 条")
    logger.info(f"✅ 分类关键词: {categories_count} 个分类")
    
    return rules_count > 0 and synonyms_count > 0 and categories_count > 0


async def main():
    """主函数"""
    logger.info("=" * 80)
    logger.info("🚀 从PostgreSQL清洗后数据生成知识库并直接导入")
    logger.info("=" * 80)
    
    # 创建PostgreSQL引擎
    engine = create_async_engine(
        database_config.database_url,
        echo=False,
        pool_pre_ping=True
    )
    
    async_session_maker = sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    try:
        async with async_session_maker() as session:
            # 步骤1: 加载数据并生成知识库
            logger.info("\n📊 步骤1: 加载清洗后的数据...")
            generator = MaterialKnowledgeGenerator(pg_session=session)
            await generator.load_all_data()
            
            logger.info("\n🔧 步骤2: 生成知识库...")
            extraction_rules = generator.generate_extraction_rules()
            synonyms = generator.generate_synonym_dictionary()
            category_keywords = generator.category_keywords
            
            logger.info(f"  ✅ 生成 {len(extraction_rules)} 条提取规则")
            logger.info(f"  ✅ 生成 {len(synonyms)} 个同义词组")
            logger.info(f"  ✅ 生成 {len(category_keywords)} 个分类关键词")
            
            # 步骤2: 清空现有数据
            logger.info("\n🗑️  步骤3: 清空现有知识库数据...")
            await clear_existing_data(session)
            
            # 步骤3: 导入新数据
            logger.info("\n📥 步骤4: 导入新知识库到数据库...")
            await import_extraction_rules(session, extraction_rules)
            await import_synonyms(session, synonyms)
            await import_category_keywords(session, category_keywords)
            
            # 步骤4: 验证导入
            success = await verify_import(session)
            
            if success:
                logger.info("\n" + "=" * 80)
                logger.info("✅ 知识库生成并导入成功！")
                logger.info("=" * 80)
                logger.info("💡 提示: 后端服务会在5秒后自动刷新知识库缓存")
            else:
                logger.error("\n❌ 导入验证失败，请检查数据")
                
    except Exception as e:
        logger.error(f"\n❌ 操作失败: {e}", exc_info=True)
        raise
    finally:
        await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())

