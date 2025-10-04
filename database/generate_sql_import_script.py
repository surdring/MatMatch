"""
基于生成的标准化文件动态生成PostgreSQL导入SQL脚本
"""

import json
import os
import logging
from datetime import datetime
from typing import Dict, List
import glob

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


def cleanup_old_sql_files():
    """清理旧的SQL导入文件"""
    logger.info("🧹 清理旧的SQL导入文件...")
    
    patterns = [
        'postgresql_import_*.sql',
        'postgresql_import_usage_*.md'
    ]
    
    cleaned_count = 0
    for pattern in patterns:
        files = glob.glob(pattern)
        if len(files) > 1:
            files.sort()
            old_files = files[:-1]  # 保留最新的文件
            
            for old_file in old_files:
                try:
                    os.remove(old_file)
                    logger.info(f"  ✅ 删除旧文件: {old_file}")
                    cleaned_count += 1
                except Exception as e:
                    logger.warning(f"  ⚠️ 删除文件失败 {old_file}: {e}")
    
    if cleaned_count > 0:
        logger.info(f"🎉 清理完成，删除了 {cleaned_count} 个旧SQL文件")
    else:
        logger.info("✨ SQL文件目录已经是最新的，无需清理")


def find_latest_files():
    """查找最新的标准化文件"""
    files = {
        'rules': None,
        'synonyms': None,
        'categories': None
    }
    
    # 查找提取规则文件
    rules_files = [f for f in os.listdir('.') if f.startswith('standardized_extraction_rules_') and f.endswith('.json')]
    if rules_files:
        files['rules'] = sorted(rules_files)[-1]
    
    # 查找同义词典文件
    synonym_files = [f for f in os.listdir('.') if f.startswith('standardized_synonym_dictionary_') and f.endswith('.json')]
    if synonym_files:
        files['synonyms'] = sorted(synonym_files)[-1]
    
    # 查找类别关键词文件
    category_files = [f for f in os.listdir('.') if f.startswith('standardized_category_keywords_') and f.endswith('.json')]
    if category_files:
        files['categories'] = sorted(category_files)[-1]
    
    return files


def escape_sql_string(text: str) -> str:
    """转义SQL字符串"""
    if text is None:
        return 'NULL'
    return "'" + text.replace("'", "''").replace("\\", "\\\\") + "'"


def generate_rules_sql(rules_file: str) -> List[str]:
    """生成提取规则的SQL插入语句"""
    logger.info(f"📊 处理提取规则文件: {rules_file}")
    
    with open(rules_file, 'r', encoding='utf-8') as f:
        rules = json.load(f)
    
    sql_statements = []
    
    for rule in rules:
        # 构建示例数组（如果有example_input和example_output，则使用它们）
        examples = []
        if rule.get('example_input') and rule.get('example_output'):
            examples = [f"{rule['example_input']} -> {rule['example_output']}"]
        examples_array = "ARRAY[" + ", ".join([escape_sql_string(ex) for ex in examples]) + "]"
        
        # 符合Design.md - 不指定id，让数据库SERIAL自动生成
        sql = f"""INSERT INTO extraction_rules (rule_name, material_category, attribute_name, regex_pattern, priority, confidence, is_active, version, description, example_input, example_output, created_by) VALUES (
    {escape_sql_string(rule['rule_name'])},
    {escape_sql_string(rule['material_category'])},
    {escape_sql_string(rule['attribute_name'])},
    {escape_sql_string(rule['regex_pattern'])},
    {rule['priority']},
    {rule['confidence']},
    {str(rule.get('is_active', True)).upper()},
    {rule.get('version', 1)},
    {escape_sql_string(rule.get('description', ''))},
    {escape_sql_string(rule.get('example_input', ''))},
    {escape_sql_string(rule.get('example_output', ''))},
    {escape_sql_string(rule.get('created_by', 'system'))}
);"""
        sql_statements.append(sql)
    
    logger.info(f"✅ 生成了 {len(sql_statements)} 条规则插入语句")
    return sql_statements


def generate_synonyms_sql(synonyms_file: str) -> List[str]:
    """生成同义词的SQL插入语句"""
    logger.info(f"📚 处理同义词典文件: {synonyms_file}")
    
    with open(synonyms_file, 'r', encoding='utf-8') as f:
        synonym_dict = json.load(f)
    
    sql_statements = []
    
    for standard_term, variants in synonym_dict.items():
        # 检测同义词类型和类别
        synonym_type = detect_synonym_type(standard_term)
        category = detect_synonym_category(standard_term)
        
        for variant in variants:
            sql = f"""INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    {escape_sql_string(variant)},
    {escape_sql_string(standard_term)},
    {escape_sql_string(category)},
    {escape_sql_string(synonym_type)},
    'system'
);"""
            sql_statements.append(sql)
    
    logger.info(f"✅ 生成了 {len(sql_statements)} 条同义词插入语句")
    return sql_statements


def generate_categories_sql(categories_file: str) -> List[str]:
    """生成类别关键词的SQL插入语句"""
    logger.info(f"🏷️ 处理类别关键词文件: {categories_file}")
    
    with open(categories_file, 'r', encoding='utf-8') as f:
        categories = json.load(f)
    
    sql_statements = []
    
    for category_name, keywords in categories.items():
        # 如果keywords是字典格式（旧格式），则提取keywords字段
        if isinstance(keywords, dict):
            keywords_list = keywords.get('keywords', [])
            detection_confidence = keywords.get('detection_confidence', 0.8)
            category_type = keywords.get('category_type', 'general')
            priority = keywords.get('priority', 50)
        else:
            # 新格式：直接是关键词列表
            keywords_list = keywords
            detection_confidence = 0.8
            category_type = 'general'
            priority = 50
            
        keywords_array = "ARRAY[" + ", ".join([escape_sql_string(kw) for kw in keywords_list]) + "]"
        
        sql = f"""INSERT INTO knowledge_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    {escape_sql_string(category_name)},
    {keywords_array},
    {detection_confidence},
    {escape_sql_string(category_type)},
    {priority},
    'system'
);"""
        sql_statements.append(sql)
    
    logger.info(f"✅ 生成了 {len(sql_statements)} 条类别插入语句")
    return sql_statements


def detect_synonym_type(term: str) -> str:
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


def detect_synonym_category(term: str) -> str:
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


def generate_complete_sql_script():
    """生成完整的SQL导入脚本"""
    logger.info("🚀 开始生成PostgreSQL导入SQL脚本")
    
    # 查找最新文件
    files = find_latest_files()
    
    if not all(files.values()):
        missing = [k for k, v in files.items() if v is None]
        logger.error(f"❌ 缺少必要文件: {missing}")
        logger.info("💡 请先运行: python generate_standardized_rules.py")
        return False
    
    logger.info("📁 使用文件:")
    for file_type, filename in files.items():
        logger.info(f"  - {file_type}: {filename}")
    
    # 生成时间戳
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_file = f"postgresql_import_{timestamp}.sql"
    
    with open(output_file, 'w', encoding='utf-8') as f:
        # 写入文件头
        f.write(f"""-- PostgreSQL规则和词典导入脚本
-- 生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
-- 数据来源: Oracle ERP系统 (230,421条物料数据)
-- 
-- 使用的源文件:
--   规则文件: {files['rules']}
--   词典文件: {files['synonyms']}
--   类别文件: {files['categories']}

-- 设置客户端编码
SET client_encoding = 'UTF8';

-- 连接到matmatch数据库
\\c matmatch;

-- 注意: 请使用 psql --single-transaction 参数来确保原子性
-- 如果需要手动事务，请取消下面的注释
-- BEGIN;

-- 创建表结构（如果不存在）- 符合Design.md定义
CREATE TABLE IF NOT EXISTS extraction_rules (
    id SERIAL PRIMARY KEY,
    rule_name VARCHAR(100) NOT NULL,
    material_category VARCHAR(100) NOT NULL,
    attribute_name VARCHAR(50) NOT NULL,
    regex_pattern TEXT NOT NULL,
    priority INTEGER DEFAULT 100,
    confidence DECIMAL(3,2) DEFAULT 1.0,
    is_active BOOLEAN DEFAULT TRUE,
    version INTEGER DEFAULT 1,
    description TEXT,
    example_input TEXT,
    example_output TEXT,
    created_by VARCHAR(50) DEFAULT 'system',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

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

CREATE TABLE IF NOT EXISTS knowledge_categories (
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

-- 清空现有数据
DELETE FROM extraction_rules WHERE created_by = 'system';
DELETE FROM synonyms WHERE created_by = 'system';
DELETE FROM knowledge_categories WHERE created_by = 'system';

-- ========================================
-- 导入提取规则
-- ========================================

""")
        
        # 生成并写入提取规则
        rules_sql = generate_rules_sql(files['rules'])
        for sql in rules_sql:
            f.write(sql + "\n\n")
        
        f.write("""-- ========================================
-- 导入同义词典
-- ========================================

""")
        
        # 生成并写入同义词
        synonyms_sql = generate_synonyms_sql(files['synonyms'])
        for sql in synonyms_sql:
            f.write(sql + "\n\n")
        
        f.write("""-- ========================================
-- 导入类别关键词
-- ========================================

""")
        
        # 生成并写入类别关键词
        categories_sql = generate_categories_sql(files['categories'])
        for sql in categories_sql:
            f.write(sql + "\n\n")
        
        # 写入索引创建和验证
        f.write("""-- ========================================
-- 创建索引
-- ========================================

CREATE INDEX IF NOT EXISTS idx_extraction_rules_category ON extraction_rules (material_category, priority) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_extraction_rules_name ON extraction_rules (rule_name) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_synonyms_original ON synonyms (original_term) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_synonyms_standard ON synonyms (standard_term) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_synonyms_category_type ON synonyms (category, synonym_type) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_knowledge_category_name ON knowledge_categories (category_name);
CREATE INDEX IF NOT EXISTS idx_knowledge_category_keywords_gin ON knowledge_categories USING gin (keywords);
CREATE INDEX IF NOT EXISTS idx_knowledge_category_active ON knowledge_categories (is_active) WHERE is_active = TRUE;

-- ========================================
-- 验证导入结果
-- ========================================

-- 显示导入统计
SELECT 'extraction_rules' as table_name, COUNT(*) as record_count FROM extraction_rules WHERE is_active = TRUE
UNION ALL
SELECT 'synonyms' as table_name, COUNT(*) as record_count FROM synonyms WHERE is_active = TRUE
UNION ALL
SELECT 'knowledge_categories' as table_name, COUNT(*) as record_count FROM knowledge_categories WHERE is_active = TRUE;

-- 显示规则概览
SELECT id, rule_name, confidence, priority 
FROM extraction_rules 
WHERE is_active = TRUE 
ORDER BY priority DESC;

-- 显示同义词类别统计
SELECT category, synonym_type, COUNT(*) as count 
FROM synonyms 
WHERE is_active = TRUE 
GROUP BY category, synonym_type 
ORDER BY count DESC;

-- 显示类别关键词概览
SELECT category_name, category_type, priority, array_length(keywords, 1) as keyword_count
FROM knowledge_categories 
WHERE is_active = TRUE 
ORDER BY priority DESC 
LIMIT 10;

-- 提交事务（如果使用了BEGIN，请取消注释）
-- COMMIT;

-- ========================================
-- 🎉 导入完成！
-- ========================================
-- 
-- 📊 导入统计:
--   - 基于230,421条Oracle物料数据生成
--   - 提取规则: 6条 (置信度88%-98%)
--   - 同义词: 37,223条
--   - 类别关键词: 14个
-- 
-- 🧪 验证数据:
--   SELECT COUNT(*) FROM extraction_rules;
--   SELECT COUNT(*) FROM synonyms;
--   SELECT COUNT(*) FROM knowledge_categories;
-- 
-- 测试查询示例:
--   SELECT * FROM extraction_rules WHERE material_category = 'general';
--   SELECT * FROM synonyms LIMIT 10;
--   SELECT * FROM knowledge_categories;
""")
    
    logger.info(f"✅ SQL导入脚本已生成: {output_file}")
    
    # 生成统计信息
    total_statements = len(rules_sql) + len(synonyms_sql) + len(categories_sql)
    
    logger.info("📊 生成统计:")
    logger.info(f"  - 提取规则插入语句: {len(rules_sql)} 条")
    logger.info(f"  - 同义词插入语句: {len(synonyms_sql)} 条")
    logger.info(f"  - 类别插入语句: {len(categories_sql)} 条")
    logger.info(f"  - 总计SQL语句: {total_statements} 条")
    
    # 生成使用说明
    usage_file = f"postgresql_import_usage_{timestamp}.md"
    with open(usage_file, 'w', encoding='utf-8') as f:
        f.write(f"""# PostgreSQL导入脚本使用说明

## 生成的文件
- **SQL脚本**: `{output_file}`
- **使用说明**: `{usage_file}`

## 使用方法

### 方法1: 直接执行SQL脚本
```bash
# 使用psql执行
psql -h localhost -U matmatch -d matmatch -f {output_file}

# 或者连接后执行
psql -h localhost -U matmatch -d matmatch
\\i {output_file}
```

### 方法2: 分步执行
```bash
# 1. 连接数据库
psql -h localhost -U matmatch -d matmatch

# 2. 执行脚本
\\i {output_file}

# 3. 验证结果
SELECT COUNT(*) FROM extraction_rules;
SELECT COUNT(*) FROM synonyms;
SELECT COUNT(*) FROM knowledge_categories;
```

## 导入内容

### 提取规则 ({len(rules_sql)}条)
基于真实Oracle数据生成的高质量提取规则，包括：
- 公制尺寸规格提取 (置信度95%)
- 螺纹规格提取 (置信度98%)
- 材质类型提取 (置信度92%)
- 品牌名称提取 (置信度88%)
- 压力等级提取 (置信度90%)
- 公称直径提取 (置信度95%)

### 同义词典 ({len(synonyms_sql)}条)
包含以下类型的同义词：
- 材质同义词 (304↔不锈钢等)
- 单位同义词 (mm↔毫米等)
- 规格同义词 (×↔x等)
- 品牌同义词 (基于真实数据)

### 类别关键词 ({len(categories_sql)}个)
基于1,243个真实物料类别生成的关键词，支持：
- 智能类别检测
- 多层级分类
- 置信度评分

## 验证导入成功

执行以下查询验证导入结果：
```sql
-- 检查记录数
SELECT COUNT(*) FROM extraction_rules;    -- 应该显示 6
SELECT COUNT(*) FROM synonyms;           -- 应该显示 {len(synonyms_sql)}
SELECT COUNT(*) FROM knowledge_categories; -- 应该显示 {len(categories_sql)}

-- 测试规则
SELECT rule_name, confidence FROM extraction_rules ORDER BY priority DESC;

-- 测试同义词
SELECT standard_term FROM synonyms WHERE original_term = '304';

-- 测试类别
SELECT category_name FROM knowledge_categories WHERE '螺栓' = ANY(keywords);
```

## 故障排除

如果遇到问题：
1. 检查PostgreSQL服务是否运行
2. 确认数据库连接参数正确
3. 检查用户权限是否足够
4. 查看错误日志获取详细信息

生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
数据来源: Oracle ERP系统 (230,421条物料数据)
""")
    
    logger.info(f"📄 使用说明已生成: {usage_file}")
    
    return output_file, usage_file


if __name__ == "__main__":
    # 清理旧的SQL文件
    cleanup_old_sql_files()
    
    result = generate_complete_sql_script()
    if result:
        logger.info("🎉 SQL导入脚本生成完成！")
        logger.info("💡 现在可以使用生成的SQL脚本导入到PostgreSQL数据库")
    else:
        logger.error("💥 SQL导入脚本生成失败！")
