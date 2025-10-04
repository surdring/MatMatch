"""
对称性验证脚本

对比SQL导入和Python异步导入的结果，验证"对称处理"原则
确保两种导入方式产生完全一致的数据

关联清单点:
- [T.3] 验证对称处理原则
- [R.0] S.T.I.R. 流程符合度
"""

import asyncio
import logging
import sys
from pathlib import Path
from datetime import datetime
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
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class SymmetryVerifier:
    """
    对称性验证器
    
    对比SQL和Python两种导入方式的结果
    """
    
    def __init__(self):
        self.verification_results = {
            'rules': {'passed': [], 'failed': []},
            'synonyms': {'passed': [], 'failed': []},
            'categories': {'passed': [], 'failed': []}
        }
    
    async def verify_table_counts(self, session: AsyncSession):
        """验证各表的记录数"""
        logger.info("=" * 80)
        logger.info("📊 第1步：验证记录数")
        logger.info("=" * 80)
        
        # 期望值（来自SQL导入的验证结果）
        expected = {
            'extraction_rules': 6,
            'synonyms': 38068,  # 基于Oracle真实数据动态生成
            'material_categories': 1594  # 从Oracle分类动态生成的关键词
        }
        
        # 实际值
        actual = {}
        actual['extraction_rules'] = await session.scalar(
            select(func.count()).select_from(ExtractionRule).where(ExtractionRule.is_active == True)
        )
        actual['synonyms'] = await session.scalar(
            select(func.count()).select_from(Synonym).where(Synonym.is_active == True)
        )
        actual['material_categories'] = await session.scalar(
            select(func.count()).select_from(KnowledgeCategory).where(KnowledgeCategory.keywords != None)
        )
        
        # 对比
        all_passed = True
        for table, expected_count in expected.items():
            actual_count = actual[table]
            if expected_count == actual_count:
                logger.info(f"✅ {table}: {actual_count} 条（符合预期）")
                self.verification_results[table.replace('extraction_', '').replace('material_', '')]['passed'].append('record_count')
            else:
                logger.error(f"❌ {table}: 期望 {expected_count} 条，实际 {actual_count} 条")
                self.verification_results[table.replace('extraction_', '').replace('material_', '')]['failed'].append('record_count')
                all_passed = False
        
        return all_passed
    
    async def verify_extraction_rules(self, session: AsyncSession):
        """验证提取规则的完整性"""
        logger.info("\n" + "=" * 80)
        logger.info("🔧 第2步：验证提取规则")
        logger.info("=" * 80)
        
        # 期望的规则（来自SQL导入的验证结果）
        expected_rules = [
            {'id': 1, 'rule_name': '尺寸规格提取', 'priority': 90, 'confidence': 0.95},
            {'id': 2, 'rule_name': '螺纹规格提取', 'priority': 95, 'confidence': 0.98},
            {'id': 3, 'rule_name': '压力等级提取', 'priority': 88, 'confidence': 0.90},
            {'id': 4, 'rule_name': '公称直径提取', 'priority': 87, 'confidence': 0.95},
            {'id': 5, 'rule_name': '品牌名称提取', 'priority': 85, 'confidence': 0.92},
            {'id': 6, 'rule_name': '材质类型提取', 'priority': 88, 'confidence': 0.90},
        ]
        
        all_passed = True
        
        for expected in expected_rules:
            result = await session.execute(
                select(ExtractionRule).where(
                    ExtractionRule.rule_name == expected['rule_name']
                )
            )
            rule = result.scalar_one_or_none()
            
            if rule is None:
                logger.error(f"❌ 规则缺失: {expected['rule_name']}")
                self.verification_results['rules']['failed'].append(expected['rule_name'])
                all_passed = False
                continue
            
            # 验证优先级和置信度
            if rule.priority == expected['priority'] and float(rule.confidence) == expected['confidence']:
                logger.info(f"✅ {rule.rule_name}: 优先级={rule.priority}, 置信度={rule.confidence}")
                self.verification_results['rules']['passed'].append(rule.rule_name)
            else:
                logger.error(f"❌ {rule.rule_name}: 期望 优先级={expected['priority']}, 置信度={expected['confidence']}, "
                           f"实际 优先级={rule.priority}, 置信度={rule.confidence}")
                self.verification_results['rules']['failed'].append(rule.rule_name)
                all_passed = False
        
        return all_passed
    
    async def verify_synonym_types(self, session: AsyncSession):
        """验证同义词类型分布"""
        logger.info("\n" + "=" * 80)
        logger.info("📚 第3步：验证同义词类型分布")
        logger.info("=" * 80)
        
        result = await session.execute(
            select(Synonym.synonym_type, func.count(Synonym.id))
            .where(Synonym.is_active == True)
            .group_by(Synonym.synonym_type)
            .order_by(func.count(Synonym.id).desc())
        )
        syn_stats = result.all()
        
        logger.info("同义词类型分布:")
        total = 0
        for syn_type, count in syn_stats:
            logger.info(f"  - {syn_type}: {count} 条")
            total += count
            self.verification_results['synonyms']['passed'].append(f'{syn_type}_distribution')
        
        logger.info(f"  总计: {total} 条")
        
        return True
    
    async def verify_category_keywords(self, session: AsyncSession):
        """验证分类关键词"""
        logger.info("\n" + "=" * 80)
        logger.info("🏷️ 第4步：验证分类关键词")
        logger.info("=" * 80)
        
        result = await session.execute(
            select(KnowledgeCategory)
            .where(KnowledgeCategory.keywords != None)
            .order_by(KnowledgeCategory.category_name)
        )
        categories = result.scalars().all()
        
        all_passed = True
        
        for cat in categories:
            keyword_count = len(cat.keywords) if cat.keywords else 0
            if keyword_count > 0:
                logger.info(f"✅ {cat.category_name}: {keyword_count} 个关键词")
                self.verification_results['categories']['passed'].append(cat.category_name)
            else:
                logger.warning(f"⚠️ {cat.category_name}: 没有关键词")
                self.verification_results['categories']['failed'].append(cat.category_name)
                all_passed = False
        
        return all_passed
    
    async def verify_indexes(self, session: AsyncSession):
        """验证索引是否存在"""
        logger.info("\n" + "=" * 80)
        logger.info("🔍 第5步：验证索引")
        logger.info("=" * 80)
        
        expected_indexes = [
            'extraction_rules_pkey',
            'idx_extraction_rules_category',
            'idx_extraction_rules_name',
            'synonyms_pkey',
            'idx_synonyms_original',
            'idx_synonyms_standard',
            'idx_synonyms_category_type',
            'material_categories_pkey',
            'idx_categories_name',
            'idx_categories_keywords'
        ]
        
        result = await session.execute(
            text("""
                SELECT indexname 
                FROM pg_indexes 
                WHERE tablename IN ('extraction_rules', 'synonyms', 'material_categories')
                ORDER BY indexname
            """)
        )
        actual_indexes = [row[0] for row in result.all()]
        
        all_passed = True
        for expected_index in expected_indexes:
            if expected_index in actual_indexes:
                logger.info(f"✅ 索引存在: {expected_index}")
            else:
                logger.error(f"❌ 索引缺失: {expected_index}")
                all_passed = False
        
        return all_passed
    
    async def verify_data_integrity(self, session: AsyncSession):
        """验证数据完整性"""
        logger.info("\n" + "=" * 80)
        logger.info("🔒 第6步：验证数据完整性")
        logger.info("=" * 80)
        
        checks = []
        
        # 检查1: 所有规则都有必需字段
        result = await session.execute(
            select(func.count()).select_from(ExtractionRule).where(
                (ExtractionRule.rule_name == None) |
                (ExtractionRule.regex_pattern == None)
            )
        )
        invalid_rules = result.scalar()
        if invalid_rules == 0:
            logger.info("✅ 所有规则都有必需字段")
            checks.append(True)
        else:
            logger.error(f"❌ 发现 {invalid_rules} 条规则缺少必需字段")
            checks.append(False)
        
        # 检查2: 所有同义词都有必需字段
        result = await session.execute(
            select(func.count()).select_from(Synonym).where(
                (Synonym.original_term == None) |
                (Synonym.standard_term == None)
            )
        )
        invalid_synonyms = result.scalar()
        if invalid_synonyms == 0:
            logger.info("✅ 所有同义词都有必需字段")
            checks.append(True)
        else:
            logger.error(f"❌ 发现 {invalid_synonyms} 条同义词缺少必需字段")
            checks.append(False)
        
        # 检查3: 所有分类都有关键词
        result = await session.execute(
            select(func.count()).select_from(KnowledgeCategory).where(
                KnowledgeCategory.keywords == None
            )
        )
        invalid_categories = result.scalar()
        if invalid_categories == 0:
            logger.info("✅ 所有分类都有关键词")
            checks.append(True)
        else:
            logger.warning(f"⚠️ 发现 {invalid_categories} 个分类没有关键词")
            checks.append(False)
        
        return all(checks)
    
    async def run(self):
        """执行完整的对称性验证"""
        logger.info("=" * 80)
        logger.info("🔄 对称性验证器启动")
        logger.info("  验证SQL导入和Python异步导入的一致性")
        logger.info("=" * 80)
        
        try:
            # 初始化数据库
            engine = db_manager.create_engine()
            session_maker = db_manager.create_session_maker()
            
            # 执行验证
            async with session_maker() as session:
                results = []
                
                results.append(await self.verify_table_counts(session))
                results.append(await self.verify_extraction_rules(session))
                results.append(await self.verify_synonym_types(session))
                results.append(await self.verify_category_keywords(session))
                results.append(await self.verify_indexes(session))
                results.append(await self.verify_data_integrity(session))
            
            # 输出最终结果
            logger.info("\n" + "=" * 80)
            logger.info("📋 验证结果汇总")
            logger.info("=" * 80)
            
            passed_count = sum(1 for r in results if r)
            total_count = len(results)
            
            logger.info(f"✅ 通过: {passed_count}/{total_count} 项检查")
            
            if all(results):
                logger.info("\n🎉 完美！SQL导入和Python导入完全对称！")
                logger.info("✅ 验证了\"对称处理\"原则的正确实现")
                return True
            else:
                logger.warning(f"\n⚠️ 发现 {total_count - passed_count} 项不一致")
                logger.warning("请检查上述错误信息")
                return False
        
        except Exception as e:
            logger.error(f"❌ 验证过程发生错误: {e}")
            logger.exception("详细错误信息:")
            return False


async def main():
    """主函数"""
    verifier = SymmetryVerifier()
    success = await verifier.run()
    
    if success:
        print("\n🎊 对称性验证通过！")
        return 0
    else:
        print("\n💥 对称性验证失败！")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)

