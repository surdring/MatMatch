"""
Backend异步知识库导入脚本

这是验证"对称处理"原则的关键脚本：
- 使用与SQL导入完全相同的数据源（material_knowledge_generator.py生成的JSON文件）
- 使用Backend的SQLAlchemy异步模型进行导入
- 对比SQL导入和Python导入的结果，验证两种方式的一致性

关联清单点:
- [T.1] 验证Backend模型与数据库schema的一致性
- [T.2] 验证异步导入的正确性
- [I.2] 实现对称处理原则
"""

import asyncio
import json
import logging
import sys
from pathlib import Path
from datetime import datetime
from typing import List, Dict
from sqlalchemy import select, func, text
from sqlalchemy.ext.asyncio import AsyncSession

# 添加项目路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))
sys.path.insert(0, str(project_root / 'backend'))

from backend.database.session import db_manager
from backend.models.base import Base
from backend.models.materials import ExtractionRule, Synonym, KnowledgeCategory

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'logs/knowledge_base_import_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class KnowledgeBaseImporter:
    """
    知识库异步导入器
    
    使用Backend的SQLAlchemy模型将知识库数据导入PostgreSQL
    实现"对称处理"原则
    """
    
    def __init__(self, data_dir: Path):
        """
        初始化导入器
        
        Args:
            data_dir: 知识库JSON文件所在目录
        """
        self.data_dir = Path(data_dir)
        self.stats = {
            'rules_imported': 0,
            'synonyms_imported': 0,
            'categories_imported': 0,
            'rules_skipped': 0,
            'synonyms_skipped': 0,
            'categories_skipped': 0,
            'errors': []
        }
    
    def find_latest_files(self) -> Dict[str, Path]:
        """
        查找最新的知识库文件
        
        Returns:
            包含文件路径的字典
        """
        logger.info("🔍 查找最新的知识库文件...")
        
        files = {
            'rules': None,
            'synonyms': None,
            'categories': None
        }
        
        # 查找提取规则文件
        rules_files = list(self.data_dir.glob('standardized_extraction_rules_*.json'))
        if rules_files:
            files['rules'] = max(rules_files, key=lambda p: p.stat().st_mtime)
            logger.info(f"  ✅ 提取规则: {files['rules'].name}")
        
        # 查找同义词记录文件（注意：使用records文件，不是dictionary文件）
        synonym_files = list(self.data_dir.glob('standardized_synonym_records_*.json'))
        if synonym_files:
            files['synonyms'] = max(synonym_files, key=lambda p: p.stat().st_mtime)
            logger.info(f"  ✅ 同义词记录: {files['synonyms'].name}")
        
        # 查找分类关键词文件
        category_files = list(self.data_dir.glob('standardized_category_keywords_*.json'))
        if category_files:
            files['categories'] = max(category_files, key=lambda p: p.stat().st_mtime)
            logger.info(f"  ✅ 分类关键词: {files['categories'].name}")
        
        # 检查是否所有文件都找到
        missing = [k for k, v in files.items() if v is None]
        if missing:
            raise FileNotFoundError(f"缺少知识库文件: {', '.join(missing)}")
        
        return files
    
    async def clear_existing_data(self, session: AsyncSession):
        """
        清空现有数据（用于重新导入）
        
        Args:
            session: 数据库会话
        """
        logger.info("🗑️ 清空现有知识库数据...")
        
        try:
            # 删除所有现有数据
            await session.execute(text("DELETE FROM extraction_rules"))
            await session.execute(text("DELETE FROM synonyms"))
            await session.execute(text("DELETE FROM knowledge_categories"))
            await session.commit()
            logger.info("  ✅ 现有数据已清空")
        except Exception as e:
            logger.error(f"  ❌ 清空数据失败: {e}")
            await session.rollback()
            raise
    
    async def import_extraction_rules(self, session: AsyncSession, file_path: Path):
        """
        导入提取规则
        
        Args:
            session: 数据库会话
            file_path: 规则JSON文件路径
        """
        logger.info("🔧 开始导入提取规则...")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                rules_data = json.load(f)
            
            logger.info(f"  📊 读取到 {len(rules_data)} 条规则")
            
            for rule_dict in rules_data:
                try:
                    # 创建ExtractionRule对象
                    # 注意：不设置id，让数据库自动生成
                    rule = ExtractionRule(
                        rule_name=rule_dict['rule_name'],
                        material_category=rule_dict['material_category'],
                        attribute_name=rule_dict['attribute_name'],
                        regex_pattern=rule_dict['regex_pattern'],
                        priority=rule_dict.get('priority', 50),
                        confidence=rule_dict.get('confidence', 0.8),
                        is_active=rule_dict.get('is_active', True),
                        version=rule_dict.get('version', 1),
                        description=rule_dict.get('description', ''),
                        example_input=rule_dict.get('example_input'),
                        example_output=rule_dict.get('example_output'),
                        created_by=rule_dict.get('created_by', 'system')
                    )
                    
                    session.add(rule)
                    self.stats['rules_imported'] += 1
                    
                except Exception as e:
                    logger.warning(f"  ⚠️ 跳过规则 {rule_dict.get('rule_name', 'unknown')}: {e}")
                    self.stats['rules_skipped'] += 1
                    self.stats['errors'].append({
                        'type': 'rule',
                        'data': rule_dict,
                        'error': str(e)
                    })
            
            await session.commit()
            logger.info(f"  ✅ 成功导入 {self.stats['rules_imported']} 条规则")
            
            if self.stats['rules_skipped'] > 0:
                logger.warning(f"  ⚠️ 跳过 {self.stats['rules_skipped']} 条规则")
        
        except Exception as e:
            logger.error(f"  ❌ 导入规则失败: {e}")
            await session.rollback()
            raise
    
    async def import_synonyms(self, session: AsyncSession, file_path: Path):
        """
        导入同义词
        
        Args:
            session: 数据库会话
            file_path: 同义词记录JSON文件路径
        """
        logger.info("📚 开始导入同义词...")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                synonyms_data = json.load(f)
            
            logger.info(f"  📊 读取到 {len(synonyms_data)} 条同义词记录")
            
            # 批量导入，每1000条提交一次
            batch_size = 1000
            for i, syn_dict in enumerate(synonyms_data):
                try:
                    # 创建Synonym对象
                    synonym = Synonym(
                        original_term=syn_dict['original_term'],
                        standard_term=syn_dict['standard_term'],
                        category=syn_dict.get('category', 'general'),
                        synonym_type=syn_dict.get('synonym_type', 'general'),
                        confidence=syn_dict.get('confidence', 1.0)
                    )
                    
                    session.add(synonym)
                    self.stats['synonyms_imported'] += 1
                    
                    # 批量提交
                    if (i + 1) % batch_size == 0:
                        await session.commit()
                        logger.info(f"  ⏳ 已导入 {i + 1}/{len(synonyms_data)} 条同义词...")
                    
                except Exception as e:
                    logger.warning(f"  ⚠️ 跳过同义词 {syn_dict.get('original_term', 'unknown')}: {e}")
                    self.stats['synonyms_skipped'] += 1
                    if len(self.stats['errors']) < 100:  # 只记录前100个错误
                        self.stats['errors'].append({
                            'type': 'synonym',
                            'data': syn_dict,
                            'error': str(e)
                        })
            
            # 提交剩余的记录
            await session.commit()
            logger.info(f"  ✅ 成功导入 {self.stats['synonyms_imported']} 条同义词")
            
            if self.stats['synonyms_skipped'] > 0:
                logger.warning(f"  ⚠️ 跳过 {self.stats['synonyms_skipped']} 条同义词")
        
        except Exception as e:
            logger.error(f"  ❌ 导入同义词失败: {e}")
            await session.rollback()
            raise
    
    async def import_categories(self, session: AsyncSession, file_path: Path):
        """
        导入分类关键词（使用原始SQL，与SQL导入脚本保持一致）
        
        Args:
            session: 数据库会话
            file_path: 分类关键词JSON文件路径
        """
        logger.info("🏷️ 开始导入分类关键词...")
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                categories_data = json.load(f)
            
            logger.info(f"  📊 读取到 {len(categories_data)} 个分类")
            
            for category_name, keywords in categories_data.items():
                try:
                    # 确定分类类型和优先级
                    category_type = 'material_type'
                    priority = 50
                    detection_confidence = 0.8
                    
                    # 根据分类名称调整优先级
                    high_priority_categories = ['bearing', 'valve', 'pump', 'motor']
                    if category_name in high_priority_categories:
                        priority = 80
                    
                    # keywords可能是列表或字典
                    if isinstance(keywords, dict):
                        keywords_list = keywords.get('keywords', [])
                    elif isinstance(keywords, list):
                        keywords_list = keywords
                    else:
                        keywords_list = []
                    
                    # 使用原始SQL插入（与SQL脚本保持一致）
                    from sqlalchemy import text
                    sql = text("""
                        INSERT INTO knowledge_categories 
                        (category_name, keywords, detection_confidence, category_type, priority, is_active, created_by) 
                        VALUES (:name, :keywords, :confidence, :type, :priority, true, 'system')
                    """)
                    
                    await session.execute(sql, {
                        'name': category_name,
                        'keywords': keywords_list,
                        'confidence': detection_confidence,
                        'type': category_type,
                        'priority': priority
                    })
                    
                    self.stats['categories_imported'] += 1
                    
                except Exception as e:
                    logger.warning(f"  ⚠️ 跳过分类 {category_name}: {e}")
                    self.stats['categories_skipped'] += 1
                    self.stats['errors'].append({
                        'type': 'category',
                        'data': {'category_name': category_name, 'keywords': keywords},
                        'error': str(e)
                    })
            
            await session.commit()
            logger.info(f"  ✅ 成功导入 {self.stats['categories_imported']} 个分类")
            
            if self.stats['categories_skipped'] > 0:
                logger.warning(f"  ⚠️ 跳过 {self.stats['categories_skipped']} 个分类")
        
        except Exception as e:
            logger.error(f"  ❌ 导入分类失败: {e}")
            await session.rollback()
            raise
    
    async def verify_import(self, session: AsyncSession):
        """
        验证导入结果
        
        Args:
            session: 数据库会话
        """
        logger.info("=" * 80)
        logger.info("🔍 验证导入结果...")
        logger.info("=" * 80)
        
        try:
            # 统计各表记录数
            rules_count = await session.scalar(
                select(func.count()).select_from(ExtractionRule).where(ExtractionRule.is_active == True)
            )
            synonyms_count = await session.scalar(
                select(func.count()).select_from(Synonym).where(Synonym.is_active == True)
            )
            # 使用原始SQL查询分类数（与表结构匹配）
            categories_result = await session.execute(
                text("SELECT COUNT(*) FROM knowledge_categories WHERE is_active = TRUE")
            )
            categories_count = categories_result.scalar()
            
            logger.info(f"📊 数据库记录统计:")
            logger.info(f"  - 提取规则: {rules_count} 条")
            logger.info(f"  - 同义词: {synonyms_count} 条")
            logger.info(f"  - 分类关键词: {categories_count} 个")
            
            # 查询几条样例数据
            logger.info(f"\n📋 提取规则样例 (前5条):")
            result = await session.execute(
                select(ExtractionRule)
                .where(ExtractionRule.is_active == True)
                .order_by(ExtractionRule.priority.desc())
                .limit(5)
            )
            rules = result.scalars().all()
            for rule in rules:
                logger.info(f"  - [{rule.id}] {rule.rule_name} (优先级: {rule.priority}, 置信度: {rule.confidence})")
            
            logger.info(f"\n📚 同义词类型统计:")
            result = await session.execute(
                select(Synonym.synonym_type, func.count(Synonym.id))
                .where(Synonym.is_active == True)
                .group_by(Synonym.synonym_type)
                .order_by(func.count(Synonym.id).desc())
            )
            syn_stats = result.all()
            for syn_type, count in syn_stats:
                logger.info(f"  - {syn_type}: {count} 条")
            
            logger.info(f"\n🏷️ 分类关键词样例:")
            # 使用原始SQL查询分类样例
            categories_result = await session.execute(
                text("""
                    SELECT category_name, keywords, priority 
                    FROM knowledge_categories 
                    WHERE is_active = TRUE 
                    ORDER BY category_name 
                    LIMIT 5
                """)
            )
            categories = categories_result.fetchall()
            for cat in categories:
                keyword_count = len(cat.keywords) if cat.keywords else 0
                logger.info(f"  - {cat.category_name}: {keyword_count} 个关键词 (优先级: {cat.priority})")
            
            logger.info("=" * 80)
            
            # 对比导入统计
            logger.info(f"📈 导入统计对比:")
            logger.info(f"  提取规则: 导入 {self.stats['rules_imported']}, 数据库 {rules_count}")
            logger.info(f"  同义词: 导入 {self.stats['synonyms_imported']}, 数据库 {synonyms_count}")
            logger.info(f"  分类关键词: 导入 {self.stats['categories_imported']}, 数据库 {categories_count}")
            
            # 验证一致性
            if (self.stats['rules_imported'] == rules_count and
                self.stats['synonyms_imported'] == synonyms_count and
                self.stats['categories_imported'] == categories_count):
                logger.info("✅ 导入数据完全一致！")
                return True
            else:
                logger.warning("⚠️ 导入数据不一致，请检查日志")
                return False
        
        except Exception as e:
            logger.error(f"❌ 验证失败: {e}")
            return False
    
    async def run(self, clear_existing: bool = False):
        """
        执行完整的导入流程
        
        Args:
            clear_existing: 是否清空现有数据
        """
        logger.info("=" * 80)
        logger.info("🚀 Backend知识库异步导入器启动")
        logger.info("=" * 80)
        
        try:
            # 查找文件
            files = self.find_latest_files()
            
            # 初始化数据库
            logger.info("🔗 初始化数据库连接...")
            engine = db_manager.create_engine()
            session_maker = db_manager.create_session_maker()
            
            # 创建表（如果不存在）
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            
            # 创建会话
            async with session_maker() as session:
                # 清空现有数据（如果需要）
                if clear_existing:
                    await self.clear_existing_data(session)
                
                # 导入数据
                await self.import_extraction_rules(session, files['rules'])
                await self.import_synonyms(session, files['synonyms'])
                await self.import_categories(session, files['categories'])
                
                # 验证导入
                success = await self.verify_import(session)
            
            # 输出最终统计
            logger.info("=" * 80)
            logger.info("🎉 导入完成！最终统计:")
            logger.info("=" * 80)
            logger.info(f"✅ 成功导入:")
            logger.info(f"  - 提取规则: {self.stats['rules_imported']} 条")
            logger.info(f"  - 同义词: {self.stats['synonyms_imported']} 条")
            logger.info(f"  - 分类关键词: {self.stats['categories_imported']} 个")
            
            if self.stats['rules_skipped'] or self.stats['synonyms_skipped'] or self.stats['categories_skipped']:
                logger.info(f"⚠️ 跳过记录:")
                logger.info(f"  - 提取规则: {self.stats['rules_skipped']} 条")
                logger.info(f"  - 同义词: {self.stats['synonyms_skipped']} 条")
                logger.info(f"  - 分类关键词: {self.stats['categories_skipped']} 个")
            
            logger.info("=" * 80)
            
            return success
        
        except Exception as e:
            logger.error(f"❌ 导入过程发生错误: {e}")
            logger.exception("详细错误信息:")
            return False


async def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Backend知识库异步导入脚本')
    parser.add_argument('--data-dir', type=str, default='../database',
                       help='知识库JSON文件所在目录')
    parser.add_argument('--clear', action='store_true',
                       help='清空现有数据后重新导入')
    
    args = parser.parse_args()
    
    # 创建导入器
    importer = KnowledgeBaseImporter(args.data_dir)
    
    # 执行导入
    success = await importer.run(clear_existing=args.clear)
    
    if success:
        print("\n🎊 恭喜！知识库导入成功！")
        return 0
    else:
        print("\n💥 导入失败！请检查日志文件了解详细错误信息。")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
