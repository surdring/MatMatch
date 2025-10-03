"""
PostgreSQL规则和词典自动导入脚本
基于生成的标准化规则和词典，自动导入到PostgreSQL数据库
"""

import json
import asyncio
import asyncpg
import logging
import os
from datetime import datetime
from typing import Dict, List

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class PostgreSQLImporter:
    """PostgreSQL规则和词典导入器"""
    
    def __init__(self):
        self.connection = None
        self.pg_config = {
            'host': os.getenv('PG_HOST', 'localhost'),
            'port': int(os.getenv('PG_PORT', 5432)),
            'database': os.getenv('PG_DATABASE', 'matmatch'),
            'user': os.getenv('PG_USERNAME', 'matmatch'),
            'password': os.getenv('PG_PASSWORD', 'matmatch')
        }
    
    async def connect(self):
        """连接PostgreSQL数据库"""
        try:
            self.connection = await asyncpg.connect(**self.pg_config)
            logger.info("✅ PostgreSQL数据库连接成功")
            return True
        except Exception as e:
            logger.error(f"❌ PostgreSQL连接失败: {e}")
            return False
    
    async def disconnect(self):
        """断开数据库连接"""
        if self.connection:
            await self.connection.close()
            logger.info("🔌 PostgreSQL连接已断开")
    
    async def create_tables(self):
        """创建数据库表结构"""
        logger.info("🏗️ 创建数据库表结构...")
        
        # 创建提取规则表
        create_rules_table = """
        CREATE TABLE IF NOT EXISTS extraction_rules (
            id SERIAL PRIMARY KEY,
            rule_id VARCHAR(50) UNIQUE NOT NULL,
            rule_name VARCHAR(100) NOT NULL,
            material_category VARCHAR(100) NOT NULL,
            attribute_name VARCHAR(50) NOT NULL,
            regex_pattern TEXT NOT NULL,
            priority INTEGER DEFAULT 100,
            confidence DECIMAL(3,2) DEFAULT 1.0,
            is_active BOOLEAN DEFAULT TRUE,
            description TEXT,
            examples TEXT[],
            data_source VARCHAR(50) DEFAULT 'oracle_real_data',
            created_by VARCHAR(50) DEFAULT 'system',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        # 创建同义词表
        create_synonyms_table = """
        CREATE TABLE IF NOT EXISTS synonyms (
            id SERIAL PRIMARY KEY,
            original_term VARCHAR(200) NOT NULL,
            standard_term VARCHAR(200) NOT NULL,
            category VARCHAR(50) DEFAULT 'general',
            synonym_type VARCHAR(20) DEFAULT 'general',
            is_active BOOLEAN DEFAULT TRUE,
            confidence DECIMAL(3,2) DEFAULT 1.0,
            description TEXT,
            created_by VARCHAR(50) DEFAULT 'system',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        # 创建物料类别表
        create_categories_table = """
        CREATE TABLE IF NOT EXISTS material_categories (
            id SERIAL PRIMARY KEY,
            category_name VARCHAR(200) NOT NULL,
            keywords TEXT[],
            detection_confidence DECIMAL(3,2) DEFAULT 0.8,
            category_type VARCHAR(50) DEFAULT 'general',
            priority INTEGER DEFAULT 50,
            is_active BOOLEAN DEFAULT TRUE,
            description TEXT,
            created_by VARCHAR(50) DEFAULT 'system',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        try:
            await self.connection.execute(create_rules_table)
            await self.connection.execute(create_synonyms_table)
            await self.connection.execute(create_categories_table)
            logger.info("✅ 数据库表创建成功")
            return True
        except Exception as e:
            logger.error(f"❌ 创建表失败: {e}")
            return False
    
    async def create_indexes(self):
        """创建数据库索引"""
        logger.info("🔍 创建数据库索引...")
        
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_extraction_rules_category ON extraction_rules (material_category, priority) WHERE is_active = TRUE;",
            "CREATE INDEX IF NOT EXISTS idx_extraction_rules_rule_id ON extraction_rules (rule_id) WHERE is_active = TRUE;",
            "CREATE INDEX IF NOT EXISTS idx_synonyms_original ON synonyms (original_term) WHERE is_active = TRUE;",
            "CREATE INDEX IF NOT EXISTS idx_synonyms_standard ON synonyms (standard_term) WHERE is_active = TRUE;",
            "CREATE INDEX IF NOT EXISTS idx_synonyms_category_type ON synonyms (category, synonym_type) WHERE is_active = TRUE;",
            "CREATE INDEX IF NOT EXISTS idx_categories_name ON material_categories (category_name) WHERE is_active = TRUE;",
            "CREATE INDEX IF NOT EXISTS idx_categories_keywords ON material_categories USING gin (keywords) WHERE is_active = TRUE;"
        ]
        
        for index_sql in indexes:
            try:
                await self.connection.execute(index_sql)
            except Exception as e:
                logger.warning(f"创建索引时出现警告: {e}")
        
        logger.info("✅ 数据库索引创建完成")
    
    async def import_extraction_rules(self):
        """导入提取规则"""
        logger.info("📥 导入提取规则...")
        
        # 查找最新的规则文件
        rules_files = [f for f in os.listdir('.') if f.startswith('standardized_extraction_rules_') and f.endswith('.json')]
        if not rules_files:
            logger.error("❌ 未找到标准化提取规则文件")
            return False
        
        latest_rules_file = sorted(rules_files)[-1]
        logger.info(f"📁 使用规则文件: {latest_rules_file}")
        
        with open(latest_rules_file, 'r', encoding='utf-8') as f:
            rules = json.load(f)
        
        # 清空现有规则
        await self.connection.execute("DELETE FROM extraction_rules WHERE created_by = 'system'")
        
        # 批量插入规则
        insert_query = """
        INSERT INTO extraction_rules 
        (rule_id, rule_name, material_category, attribute_name, regex_pattern, priority, 
         confidence, description, examples, data_source, created_by)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'system')
        """
        
        for rule in rules:
            await self.connection.execute(
                insert_query,
                rule['id'],
                rule['name'],
                rule['category'],
                rule['attribute'],
                rule['pattern'],
                rule['priority'],
                rule['confidence'],
                rule.get('description', ''),
                rule.get('examples', []),
                rule.get('data_source', 'oracle_real_data')
            )
        
        logger.info(f"✅ 成功导入 {len(rules)} 条提取规则")
        return len(rules)
    
    async def import_synonym_dictionary(self):
        """导入同义词典"""
        logger.info("📥 导入同义词典...")
        
        # 查找最新的词典文件
        dict_files = [f for f in os.listdir('.') if f.startswith('standardized_synonym_dictionary_') and f.endswith('.json')]
        if not dict_files:
            logger.error("❌ 未找到标准化同义词典文件")
            return False
        
        latest_dict_file = sorted(dict_files)[-1]
        logger.info(f"📁 使用词典文件: {latest_dict_file}")
        
        with open(latest_dict_file, 'r', encoding='utf-8') as f:
            synonym_dict = json.load(f)
        
        # 清空现有同义词
        await self.connection.execute("DELETE FROM synonyms WHERE created_by = 'system'")
        
        # 批量插入同义词
        insert_query = """
        INSERT INTO synonyms 
        (original_term, standard_term, category, synonym_type, created_by)
        VALUES ($1, $2, $3, $4, 'system')
        """
        
        total_synonyms = 0
        for standard_term, variants in synonym_dict.items():
            # 确定同义词类型和类别
            synonym_type = self._detect_synonym_type(standard_term)
            category = self._detect_synonym_category(standard_term)
            
            for variant in variants:
                await self.connection.execute(
                    insert_query,
                    variant,
                    standard_term,
                    category,
                    synonym_type
                )
                total_synonyms += 1
        
        logger.info(f"✅ 成功导入 {total_synonyms} 条同义词")
        return total_synonyms
    
    async def import_category_keywords(self):
        """导入类别关键词"""
        logger.info("📥 导入类别关键词...")
        
        # 查找最新的关键词文件
        keywords_files = [f for f in os.listdir('.') if f.startswith('standardized_category_keywords_') and f.endswith('.json')]
        if not keywords_files:
            logger.error("❌ 未找到标准化类别关键词文件")
            return False
        
        latest_keywords_file = sorted(keywords_files)[-1]
        logger.info(f"📁 使用关键词文件: {latest_keywords_file}")
        
        with open(latest_keywords_file, 'r', encoding='utf-8') as f:
            categories = json.load(f)
        
        # 清空现有类别
        await self.connection.execute("DELETE FROM material_categories WHERE created_by = 'system'")
        
        # 批量插入类别
        insert_query = """
        INSERT INTO material_categories 
        (category_name, keywords, detection_confidence, category_type, priority, created_by)
        VALUES ($1, $2, $3, $4, $5, 'system')
        """
        
        for category_name, info in categories.items():
            await self.connection.execute(
                insert_query,
                category_name,
                info['keywords'],
                info['detection_confidence'],
                info['category_type'],
                info['priority']
            )
        
        logger.info(f"✅ 成功导入 {len(categories)} 个类别关键词")
        return len(categories)
    
    def _detect_synonym_type(self, term: str) -> str:
        """检测同义词类型"""
        term_lower = term.lower()
        
        # 材质类型
        materials = ['304', '316', '不锈钢', '碳钢', '合金钢', '铸铁', '铜', '铝']
        if any(material in term_lower for material in materials):
            return 'material'
        
        # 单位类型
        units = ['mm', 'kg', 'mpa', 'bar', '个', '只', '件', '套']
        if any(unit in term_lower for unit in units):
            return 'unit'
        
        # 规格类型
        if any(spec in term for spec in ['x', '×', '*', 'DN', 'PN', 'Φ']):
            return 'specification'
        
        return 'general'
    
    def _detect_synonym_category(self, term: str) -> str:
        """检测同义词所属类别"""
        term_lower = term.lower()
        
        category_mapping = {
            'material': ['304', '316', '不锈钢', '碳钢', '合金钢', '铸铁', '铜', '铝'],
            'unit': ['mm', 'kg', 'mpa', 'bar', '个', '只', '件', '套'],
            'specification': ['x', '×', '*', 'DN', 'PN', 'Φ'],
            'fastener': ['螺栓', '螺钉', 'M'],
            'valve': ['阀', 'valve', 'PN'],
            'pipe': ['管', 'pipe', 'DN']
        }
        
        for category, keywords in category_mapping.items():
            if any(keyword in term_lower for keyword in keywords):
                return category
        
        return 'general'
    
    async def verify_import(self):
        """验证导入结果"""
        logger.info("🔍 验证导入结果...")
        
        # 检查各表的记录数
        rules_count = await self.connection.fetchval("SELECT COUNT(*) FROM extraction_rules WHERE is_active = TRUE")
        synonyms_count = await self.connection.fetchval("SELECT COUNT(*) FROM synonyms WHERE is_active = TRUE")
        categories_count = await self.connection.fetchval("SELECT COUNT(*) FROM material_categories WHERE is_active = TRUE")
        
        logger.info(f"📊 导入验证结果:")
        logger.info(f"  - 提取规则: {rules_count} 条")
        logger.info(f"  - 同义词: {synonyms_count} 条")
        logger.info(f"  - 类别关键词: {categories_count} 个")
        
        # 测试规则
        test_result = await self.connection.fetch("""
            SELECT rule_name, confidence 
            FROM extraction_rules 
            WHERE is_active = TRUE 
            ORDER BY priority DESC 
            LIMIT 3
        """)
        
        logger.info("🧪 规则测试:")
        for rule in test_result:
            logger.info(f"  - {rule['rule_name']}: 置信度 {rule['confidence']}")
        
        return {
            'rules_count': rules_count,
            'synonyms_count': synonyms_count,
            'categories_count': categories_count
        }


async def main():
    """主函数"""
    logger.info("🚀 开始PostgreSQL规则和词典导入")
    
    importer = PostgreSQLImporter()
    
    try:
        # 连接数据库
        if not await importer.connect():
            return False
        
        # 创建表结构
        if not await importer.create_tables():
            return False
        
        # 导入数据
        rules_count = await importer.import_extraction_rules()
        synonyms_count = await importer.import_synonym_dictionary()
        categories_count = await importer.import_category_keywords()
        
        # 创建索引
        await importer.create_indexes()
        
        # 验证导入
        result = await importer.verify_import()
        
        logger.info("🎉 PostgreSQL规则和词典导入完成！")
        logger.info(f"📊 导入统计:")
        logger.info(f"  - 提取规则: {result['rules_count']} 条")
        logger.info(f"  - 同义词: {result['synonyms_count']} 条")
        logger.info(f"  - 类别关键词: {result['categories_count']} 个")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 导入过程中发生错误: {e}")
        return False
    finally:
        await importer.disconnect()


if __name__ == "__main__":
    success = asyncio.run(main())
    exit(0 if success else 1)
