"""
PostgreSQL规则和词典初始化脚本
将生成的提取规则和同义词典导入到PostgreSQL数据库
"""

import json
import asyncio
import logging
from datetime import datetime
from typing import Dict, List
import asyncpg
import os

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class PostgreSQLRuleInitializer:
    """PostgreSQL规则初始化器"""
    
    def __init__(self, pg_config: Dict[str, str]):
        self.pg_config = pg_config
        self.connection = None
    
    async def connect(self):
        """连接PostgreSQL数据库"""
        try:
            self.connection = await asyncpg.connect(
                host=self.pg_config['host'],
                port=self.pg_config['port'],
                database=self.pg_config['database'],
                user=self.pg_config['username'],
                password=self.pg_config['password']
            )
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
        """创建必要的表结构"""
        logger.info("🏗️ 创建数据库表结构...")
        
        # 创建提取规则表
        create_rules_table = """
        CREATE TABLE IF NOT EXISTS extraction_rules (
            id SERIAL PRIMARY KEY,
            rule_name VARCHAR(100) NOT NULL,
            material_category VARCHAR(100) NOT NULL,
            attribute_name VARCHAR(50) NOT NULL,
            regex_pattern TEXT NOT NULL,
            priority INTEGER DEFAULT 100,
            is_active BOOLEAN DEFAULT TRUE,
            description TEXT,
            example_input TEXT,
            example_output TEXT,
            version INTEGER DEFAULT 1,
            created_by VARCHAR(50) DEFAULT 'system',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        # 创建同义词表
        create_synonyms_table = """
        CREATE TABLE IF NOT EXISTS synonyms (
            id SERIAL PRIMARY KEY,
            original_term VARCHAR(100) NOT NULL,
            standard_term VARCHAR(100) NOT NULL,
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
            oracle_category_id VARCHAR(20) UNIQUE,
            category_code VARCHAR(40) NOT NULL,
            category_name VARCHAR(200) NOT NULL,
            parent_category_id VARCHAR(20),
            enable_state INTEGER DEFAULT 2,
            detection_keywords TEXT[],
            category_description TEXT,
            processing_rules JSONB DEFAULT '{}',
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
    
    async def import_extraction_rules(self, rules_file: str):
        """导入提取规则"""
        logger.info(f"📥 导入提取规则: {rules_file}")
        
        with open(rules_file, 'r', encoding='utf-8') as f:
            rules = json.load(f)
        
        # 清空现有规则
        await self.connection.execute("DELETE FROM extraction_rules WHERE created_by = 'system'")
        
        # 批量插入规则
        insert_query = """
        INSERT INTO extraction_rules 
        (rule_name, material_category, attribute_name, regex_pattern, priority, 
         description, example_input, example_output, created_by)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'system')
        """
        
        for rule in rules:
            await self.connection.execute(
                insert_query,
                rule['rule_name'],
                rule['material_category'],
                rule['attribute_name'],
                rule['regex_pattern'],
                rule['priority'],
                rule.get('description', ''),
                rule.get('example_input', ''),
                rule.get('example_output', '')
            )
        
        logger.info(f"✅ 成功导入 {len(rules)} 条提取规则")
        return len(rules)
    
    async def import_synonym_dictionary(self, dict_file: str):
        """导入同义词典"""
        logger.info(f"📥 导入同义词典: {dict_file}")
        
        with open(dict_file, 'r', encoding='utf-8') as f:
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
            # 确定同义词类型
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
    
    async def import_material_categories(self, categories_data: List[Dict]):
        """导入物料分类数据"""
        logger.info("📂 导入物料分类数据...")
        
        # 清空现有分类
        await self.connection.execute("DELETE FROM material_categories WHERE oracle_category_id IS NOT NULL")
        
        # 批量插入分类
        insert_query = """
        INSERT INTO material_categories 
        (oracle_category_id, category_code, category_name, parent_category_id, 
         enable_state, detection_keywords, category_description)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        """
        
        for category in categories_data:
            # 生成检测关键词
            keywords = self._generate_category_keywords(category['CATEGORY_NAME'])
            
            await self.connection.execute(
                insert_query,
                category['CATEGORY_ID'],
                category['CATEGORY_CODE'],
                category['CATEGORY_NAME'],
                category.get('PARENT_CATEGORY_ID'),
                category.get('ENABLE_STATE', 2),
                keywords,
                f"基于Oracle分类: {category['CATEGORY_NAME']}"
            )
        
        logger.info(f"✅ 成功导入 {len(categories_data)} 个物料分类")
        return len(categories_data)
    
    def _detect_synonym_type(self, term: str) -> str:
        """检测同义词类型"""
        term_lower = term.lower()
        
        # 品牌类型
        brands = ['skf', 'nsk', 'fag', 'siemens', 'abb', 'schneider', 'omron', 'parker']
        if any(brand in term_lower for brand in brands):
            return 'brand'
        
        # 材质类型
        materials = ['304', '316', '不锈钢', '碳钢', '合金钢', '铸铁', '铜', '铝']
        if any(material in term_lower for material in materials):
            return 'material'
        
        # 规格类型
        if re.search(r'\d+[×*xX]\d+|DN\d+|Φ\d+|M\d+', term):
            return 'specification'
        
        # 单位类型
        units = ['mm', 'kg', 'mpa', 'bar', '个', '只', '件', '套']
        if any(unit in term_lower for unit in units):
            return 'unit'
        
        return 'general'
    
    def _detect_synonym_category(self, term: str) -> str:
        """检测同义词所属类别"""
        term_lower = term.lower()
        
        for category, keywords in {
            'bearing': ['轴承', 'bearing'],
            'bolt': ['螺栓', '螺钉', 'bolt', 'screw'],
            'valve': ['阀', 'valve'],
            'pipe': ['管', 'pipe'],
            'electrical': ['接触器', '继电器', '断路器', 'contactor', 'relay']
        }.items():
            if any(keyword in term_lower for keyword in keywords):
                return category
        
        return 'general'
    
    def _generate_category_keywords(self, category_name: str) -> List[str]:
        """为分类生成检测关键词"""
        keywords = [category_name]
        
        # 基于分类名称生成相关关键词
        name_lower = category_name.lower()
        
        # 添加常见变体
        if '轴承' in name_lower:
            keywords.extend(['bearing', '軸承', '滚动', '滑动'])
        elif '螺栓' in name_lower or '螺钉' in name_lower:
            keywords.extend(['bolt', 'screw', '紧固件'])
        elif '阀' in name_lower:
            keywords.extend(['valve', '閥'])
        elif '管' in name_lower:
            keywords.extend(['pipe', 'tube'])
        elif '电' in name_lower:
            keywords.extend(['electrical', 'electric'])
        
        return list(set(keywords))
    
    async def create_indexes(self):
        """创建必要的索引"""
        logger.info("🔍 创建数据库索引...")
        
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_extraction_rules_category ON extraction_rules (material_category, priority) WHERE is_active = TRUE;",
            "CREATE INDEX IF NOT EXISTS idx_synonyms_original ON synonyms (original_term) WHERE is_active = TRUE;",
            "CREATE INDEX IF NOT EXISTS idx_synonyms_category_type ON synonyms (category, synonym_type) WHERE is_active = TRUE;",
            "CREATE INDEX IF NOT EXISTS idx_categories_code ON material_categories (category_code);",
            "CREATE INDEX IF NOT EXISTS idx_categories_keywords ON material_categories USING gin (detection_keywords);"
        ]
        
        for index_sql in indexes:
            try:
                await self.connection.execute(index_sql)
            except Exception as e:
                logger.warning(f"创建索引时出现警告: {e}")
        
        logger.info("✅ 数据库索引创建完成")


async def main():
    """主函数"""
    logger.info("🚀 开始PostgreSQL规则和词典初始化")
    
    # PostgreSQL配置
    pg_config = {
        'host': os.getenv('PG_HOST', 'localhost'),
        'port': int(os.getenv('PG_PORT', 5432)),
        'database': os.getenv('PG_DATABASE', 'matmatch'),
        'username': os.getenv('PG_USERNAME', 'matmatch'),
        'password': os.getenv('PG_PASSWORD', 'matmatch')
    }
    
    initializer = PostgreSQLRuleInitializer(pg_config)
    
    try:
        # 连接数据库
        if not await initializer.connect():
            return False
        
        # 创建表结构
        if not await initializer.create_tables():
            return False
        
        # 查找最新的生成文件
        output_dir = './output'
        if not os.path.exists(output_dir):
            logger.error(f"❌ 输出目录不存在: {output_dir}")
            logger.info("💡 请先运行 python generate_rules_and_dictionary.py 生成规则和词典")
            return False
        
        # 查找最新的规则和词典文件
        rule_files = [f for f in os.listdir(output_dir) if f.startswith('extraction_rules_') and f.endswith('.json')]
        dict_files = [f for f in os.listdir(output_dir) if f.startswith('synonym_dictionary_') and f.endswith('.json')]
        
        if not rule_files or not dict_files:
            logger.error("❌ 未找到规则或词典文件")
            logger.info("💡 请先运行 python generate_rules_and_dictionary.py 生成规则和词典")
            return False
        
        # 使用最新的文件
        latest_rules_file = os.path.join(output_dir, sorted(rule_files)[-1])
        latest_dict_file = os.path.join(output_dir, sorted(dict_files)[-1])
        
        logger.info(f"📁 使用规则文件: {latest_rules_file}")
        logger.info(f"📁 使用词典文件: {latest_dict_file}")
        
        # 导入规则和词典
        rules_count = await initializer.import_extraction_rules(latest_rules_file)
        synonyms_count = await initializer.import_synonym_dictionary(latest_dict_file)
        
        # 创建索引
        await initializer.create_indexes()
        
        logger.info("🎉 PostgreSQL规则和词典初始化完成！")
        logger.info(f"📊 导入统计:")
        logger.info(f"  - 提取规则: {rules_count} 条")
        logger.info(f"  - 同义词: {synonyms_count} 条")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 初始化过程中发生错误: {e}")
        return False
    finally:
        await initializer.disconnect()


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
