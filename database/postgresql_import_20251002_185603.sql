-- PostgreSQL规则和词典导入脚本
-- 生成时间: 2025-10-02 18:56:03
-- 数据来源: Oracle ERP系统 (230,421条物料数据)
-- 
-- 使用的源文件:
--   规则文件: standardized_extraction_rules_20251002_184612.json
--   词典文件: standardized_synonym_dictionary_20251002_184612.json
--   类别文件: standardized_category_keywords_20251002_184612.json

-- 设置客户端编码
SET client_encoding = 'UTF8';

-- 连接到matmatch数据库
\c matmatch;

-- 开始事务
BEGIN;

-- 创建表结构（如果不存在）
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

-- 清空现有数据
DELETE FROM extraction_rules WHERE created_by = 'system';
DELETE FROM synonyms WHERE created_by = 'system';
DELETE FROM material_categories WHERE created_by = 'system';

-- ========================================
-- 导入提取规则
-- ========================================

INSERT INTO extraction_rules (rule_id, rule_name, material_category, attribute_name, regex_pattern, priority, confidence, description, examples, data_source, created_by) VALUES (
    'size_spec_metric',
    '公制尺寸规格提取',
    'general',
    'size_specification',
    '(?:M|Φ|φ|DN)?(\\d+(?:\\.\\d+)?[×*xX]\\d+(?:\\.\\d+)?(?:[×*xX]\\d+(?:\\.\\d+)?)?)',
    100,
    0.95,
    '基于20个真实尺寸样本，提取公制尺寸规格',
    ARRAY['1*20', 'M20*1.5', 'M24*1', 'M22*1', 'M22*1.5'],
    'oracle_real_data',
    'system'
);

INSERT INTO extraction_rules (rule_id, rule_name, material_category, attribute_name, regex_pattern, priority, confidence, description, examples, data_source, created_by) VALUES (
    'thread_spec',
    '螺纹规格提取',
    'fastener',
    'thread_specification',
    '(M\\d+(?:\\.\\d+)?[×*xX]\\d+(?:\\.\\d+)?)',
    95,
    0.98,
    '提取螺纹规格如M20*1.5',
    ARRAY['M20*1.5', 'M24*1', 'M22*1', 'M22*1.5', 'M16*1.5'],
    'oracle_real_data',
    'system'
);

INSERT INTO extraction_rules (rule_id, rule_name, material_category, attribute_name, regex_pattern, priority, confidence, description, examples, data_source, created_by) VALUES (
    'material_type',
    '材质类型提取',
    'general',
    'material_type',
    '(304|不锈钢|316L|430|201|碳钢|铜|316|铸铁|铝|合金钢)',
    90,
    0.92,
    '基于11种真实材质样本',
    ARRAY['304', '不锈钢', '316L', '430', '201'],
    'oracle_real_data',
    'system'
);

INSERT INTO extraction_rules (rule_id, rule_name, material_category, attribute_name, regex_pattern, priority, confidence, description, examples, data_source, created_by) VALUES (
    'brand_name',
    '品牌名称提取',
    'general',
    'brand_name',
    '\\b(DN50|DN25|DN100|PN16|DN80|DN150|DN200|DN40|DN65|DN20|DN32|DN125|Q235B|YJV|DN15|DN250|DN300|M16|M30|PN10)\\b',
    85,
    0.88,
    '基于20个真实品牌样本',
    ARRAY['DN50', 'DN25', 'DN100', 'PN16', 'DN80'],
    'oracle_real_data',
    'system'
);

INSERT INTO extraction_rules (rule_id, rule_name, material_category, attribute_name, regex_pattern, priority, confidence, description, examples, data_source, created_by) VALUES (
    'pressure_rating',
    '压力等级提取',
    'valve',
    'pressure_rating',
    '(PN\\d+|(?:\\d+(?:\\.\\d+)?(?:MPa|bar|公斤|kg)))',
    88,
    0.9,
    '提取压力等级如PN16, 1.6MPa',
    ARRAY['PN16', '1.6MPa', '10bar'],
    'pattern_analysis',
    'system'
);

INSERT INTO extraction_rules (rule_id, rule_name, material_category, attribute_name, regex_pattern, priority, confidence, description, examples, data_source, created_by) VALUES (
    'nominal_diameter',
    '公称直径提取',
    'pipe',
    'nominal_diameter',
    '(DN\\d+|Φ\\d+)',
    87,
    0.95,
    '提取公称直径如DN50, Φ100',
    ARRAY['DN50', 'DN100', 'Φ50'],
    'pattern_analysis',
    'system'
);

-- ========================================
-- 导入同义词典
-- ========================================

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '06',
    '部',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '11',
    '对',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16',
    '节',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '21',
    '盘',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27',
    '台',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32',
    '只',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '37',
    '方',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42',
    '延米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '62',
    '轴',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65',
    '间',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '71',
    '扇',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '81',
    '流',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76',
    '度',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '82',
    '台班',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '83',
    '套',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85',
    '斗',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '102',
    '年',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '07',
    '车',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12',
    '副',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17',
    '件',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22',
    '辆',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28',
    '条',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '33',
    '组',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38',
    '匹',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '77',
    '棵',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '05',
    '本',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10',
    '顶',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15',
    '架',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20',
    '块',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26',
    '双',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '31',
    '张',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36',
    '捆',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '41',
    'EA',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '61',
    '批',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63',
    '串',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '78',
    '单相米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '101',
    '吨铁',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '64',
    '磅',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '67',
    '具',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60',
    'GJ',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '04',
    '包',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '09',
    '袋',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14',
    '盒',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19',
    '卷',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24',
    '瓶',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '44',
    '箱',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Boxes',
    '箱',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35',
    '盏',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40',
    '付',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80',
    '板',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70',
    '项',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '86',
    '平米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45',
    '千克',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Kilograms',
    '千克',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '46',
    '克',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Grams',
    '克',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '47',
    '吨',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Tons',
    '吨',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48',
    '米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Meters',
    '米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '49',
    '分米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Decimeters',
    '分米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50',
    '厘米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Centimeters',
    '厘米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '51',
    '千米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Kilometers',
    '千米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '52',
    '平方米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Square Meters',
    '平方米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '53',
    '平方千米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Square Kilometers',
    '平方千米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '54',
    '立方米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Cubic Meters',
    '立方米',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55',
    '升',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Liters',
    '升',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '只',
    '个',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '件',
    '个',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '套',
    '个',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'pcs',
    '个',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'PCS',
    '个',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56',
    '秒',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Seconds',
    '秒',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '57',
    '分',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Minutes',
    '分',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '58',
    '小时',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Hours',
    '小时',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '59',
    '天',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Days',
    '天',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '03',
    '把',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '08',
    '次',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13',
    '罐',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18',
    '斤',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '23',
    '片',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '29',
    '桶',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34',
    '支',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '39',
    '面',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '68',
    '座',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '01',
    '根',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '66',
    '位',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '69',
    '盆',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '79',
    '台套',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100',
    '月',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Months',
    '月',
    'general',
    'general',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*100',
    '200x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×100',
    '6x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*100',
    '6x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*200',
    '6x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X200',
    '6x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×200',
    '6x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '230*113',
    '230x113',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*120',
    '200x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200×120',
    '200x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×300',
    '100x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*300',
    '100x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×40',
    '50x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*40',
    '50x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50X40',
    '50x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*50',
    '6x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×40',
    '6x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*40',
    '6x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*60',
    '6x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X60',
    '6x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450X200',
    '450x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450×200',
    '450x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450*200',
    '450x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400X200',
    '400x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*200',
    '400x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400×200',
    '400x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*250',
    '300x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300×250',
    '300x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300×200',
    '300x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*200',
    '300x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×100',
    '100x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*100',
    '100x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X100',
    '100x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450*400',
    '450x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450×400',
    '450x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450X400',
    '450x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450×250',
    '450x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450*250',
    '450x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450X250',
    '450x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500×400',
    '500x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500X400',
    '500x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*400',
    '500x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600*600',
    '600x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600×600',
    '600x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600X600',
    '600x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250X200',
    '250x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250×200',
    '250x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*200',
    '250x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*500',
    '500x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500×500',
    '500x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500X500',
    '500x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350*250',
    '350x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350×250',
    '350x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350×200',
    '350x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350*200',
    '350x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350X200',
    '350x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300×150',
    '300x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300X150',
    '300x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*150',
    '300x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450*350',
    '450x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450X350',
    '450x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450×350',
    '450x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500X250',
    '500x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*250',
    '500x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500×250',
    '500x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300×300',
    '300x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*300',
    '300x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300X300',
    '300x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300×350',
    '300x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*350',
    '300x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150×100',
    '150x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*100',
    '150x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150X100',
    '150x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*6',
    '100x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×6',
    '100x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X6',
    '100x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*250',
    '400x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400×250',
    '400x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*5',
    '60x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60X5',
    '60x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×5',
    '60x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '165*165',
    '165x165',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '165×165',
    '165x165',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '165X165',
    '165x165',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*200',
    '200x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200×200',
    '200x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200X200',
    '200x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×1',
    '14x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14X1',
    '14x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*1',
    '14x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12X1',
    '12x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*1',
    '12x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×1',
    '12x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×2',
    '20x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*2',
    '20x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X2',
    '20x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×2',
    '14x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14X2',
    '14x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*2',
    '14x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*1',
    '10x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X1',
    '10x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×1',
    '10x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30X2',
    '30x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×2',
    '30x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*2',
    '30x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*2',
    '100x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×2',
    '100x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*2',
    '90x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90×2',
    '90x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*2',
    '60x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×2',
    '60x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60X2',
    '60x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48X3',
    '48x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48×3',
    '48x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*3',
    '48x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*1',
    '40x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×1',
    '40x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*6',
    '90x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90×6',
    '90x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×8',
    '80x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*8',
    '80x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36X2',
    '36x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36×2',
    '36x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36*2',
    '36x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36*3',
    '36x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36×3',
    '36x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30X130',
    '30x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*130',
    '30x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8X1',
    '8x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×1',
    '8x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*1',
    '8x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12X30',
    '12x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*30',
    '12x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×30',
    '12x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27*2',
    '27x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27×2',
    '27x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27X2',
    '27x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×1',
    '16x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X1',
    '16x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*1',
    '16x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*50',
    '16x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×50',
    '16x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*80',
    '24x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×80',
    '24x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95*2',
    '95x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95×2',
    '95x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42*3',
    '42x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42X3',
    '42x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42×3',
    '42x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*2',
    '80x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×2',
    '80x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38×1',
    '38x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*1',
    '38x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '170×3',
    '170x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '170*3',
    '170x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75×2',
    '75x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75*2',
    '75x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130*2',
    '130x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130×2',
    '130x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*1',
    '20x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X1',
    '20x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×1',
    '20x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '68*2',
    '68x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '68×2',
    '68x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '68X2',
    '68x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*3',
    '80x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×3',
    '80x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110X2',
    '110x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*2',
    '110x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30X1',
    '30x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×1',
    '30x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*1',
    '30x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '115*2',
    '115x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '115×2',
    '115x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56×5',
    '56x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56*5',
    '56x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '64×2',
    '64x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '64X2',
    '64x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '64*2',
    '64x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*45',
    '22x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22X45',
    '22x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '480*3',
    '480x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '480×3',
    '480x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48X2',
    '48x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48×2',
    '48x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*2',
    '48x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*40',
    '16x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×40',
    '16x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56*4',
    '56x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56×4',
    '56x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48×4',
    '48x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*4',
    '48x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*90',
    '24x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×90',
    '24x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '170×4',
    '170x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '170*4',
    '170x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*100',
    '30x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×100',
    '30x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*5',
    '48x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48×5',
    '48x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*3',
    '30x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30X3',
    '30x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×3',
    '30x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×2',
    '16x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*2',
    '16x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X2',
    '16x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*2',
    '125x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125×2',
    '125x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '105X2',
    '105x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '105*2',
    '105x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*35',
    '10x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×35',
    '10x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*2',
    '65x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×2',
    '65x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*6',
    '60x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×6',
    '60x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*2',
    '150x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150×2',
    '150x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X1',
    '5x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*1',
    '5x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×1',
    '5x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*150',
    '16x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×150',
    '16x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×80',
    '8x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*80',
    '8x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*60',
    '8x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×60',
    '8x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*100',
    '12x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×100',
    '12x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*150',
    '20x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×150',
    '20x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*40',
    '8x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×40',
    '8x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×260',
    '20x260',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*260',
    '20x260',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×10',
    '8x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*10',
    '8x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×100',
    '14x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*100',
    '14x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×120',
    '16x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*120',
    '16x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*80',
    '14x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×80',
    '14x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×50',
    '10x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*50',
    '10x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X50',
    '10x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*60',
    '12x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×60',
    '12x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×80',
    '16x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*80',
    '16x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X120',
    '20x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×120',
    '20x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*120',
    '20x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*90',
    '12x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×90',
    '12x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×50',
    '3x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*50',
    '3x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X50',
    '3x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*200',
    '16x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×200',
    '16x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*150',
    '18x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18×150',
    '18x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27×1',
    '27x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27*1',
    '27x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*1',
    '22x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22X1',
    '22x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22×1',
    '22x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*70',
    '10x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×70',
    '10x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X70',
    '10x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*100',
    '16x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×100',
    '16x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*80',
    '6x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×80',
    '6x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×80',
    '10x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*80',
    '10x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*140',
    '20x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×140',
    '20x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X55',
    '10x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*55',
    '10x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×55',
    '10x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*80',
    '12x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×80',
    '12x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*120',
    '10x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×120',
    '10x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*8',
    '10x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X8',
    '10x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*140',
    '16x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×140',
    '16x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*90',
    '22x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22×90',
    '22x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*6',
    '8x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×6',
    '8x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×6',
    '6x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*6',
    '6x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×75',
    '20x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*75',
    '20x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*6',
    '5x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×6',
    '5x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X6',
    '5x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*100',
    '20x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×100',
    '20x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X100',
    '20x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*15',
    '8x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×15',
    '8x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×35',
    '20x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*35',
    '20x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×55',
    '16x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*55',
    '16x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*20',
    '8x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8X20',
    '8x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×20',
    '8x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×40',
    '10x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X40',
    '10x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*40',
    '10x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*40',
    '5x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×40',
    '5x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X40',
    '5x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×110',
    '20x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*110',
    '20x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×300',
    '6x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*300',
    '6x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*45',
    '10x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×45',
    '10x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*25',
    '10x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×25',
    '10x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X25',
    '10x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*130',
    '20x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×130',
    '20x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*85',
    '20x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×85',
    '20x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*85',
    '12x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×85',
    '12x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×150',
    '24x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*150',
    '24x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×55',
    '24x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*55',
    '24x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*50',
    '8x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×50',
    '8x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8X50',
    '8x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*65',
    '10x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×65',
    '10x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X65',
    '10x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×15',
    '5x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*15',
    '5x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X1',
    '6x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*1',
    '6x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×1',
    '6x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×30',
    '14x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*30',
    '14x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*100',
    '22x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22X100',
    '22x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*90',
    '20x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×90',
    '20x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×110',
    '24x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*110',
    '24x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8X30',
    '8x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*30',
    '8x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×30',
    '8x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*65',
    '22x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22×65',
    '22x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*140',
    '12x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×140',
    '12x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12X75',
    '12x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×75',
    '12x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*75',
    '12x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×20',
    '5x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*20',
    '5x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X20',
    '5x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*150',
    '10x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X150',
    '10x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×120',
    '30x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*120',
    '30x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*70',
    '16x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×70',
    '16x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*80',
    '400x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400×80',
    '400x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*100',
    '24x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×100',
    '24x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*125',
    '24x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×125',
    '24x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×70',
    '12x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12X70',
    '12x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*70',
    '12x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42*150',
    '42x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42×150',
    '42x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×85',
    '24x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*85',
    '24x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×150',
    '30x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*150',
    '30x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*130',
    '16x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X130',
    '16x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×130',
    '16x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×70',
    '14x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*70',
    '14x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14X70',
    '14x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X70',
    '20x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*70',
    '20x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×70',
    '20x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*300',
    '48x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48×300',
    '48x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×20',
    '6x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*20',
    '6x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X20',
    '6x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×60',
    '16x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*60',
    '16x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×65',
    '20x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*65',
    '20x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X65',
    '20x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×80',
    '5x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*80',
    '5x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X80',
    '5x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×60',
    '5x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*60',
    '5x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X60',
    '5x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*100',
    '5x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×200',
    '5x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*200',
    '5x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*15',
    '25x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×15',
    '25x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X15',
    '25x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*140',
    '6x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X140',
    '6x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X180',
    '6x180',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*180',
    '6x180',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×120',
    '6x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*120',
    '6x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×25',
    '12x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*25',
    '12x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×250',
    '6x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*250',
    '6x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*300',
    '8x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×200',
    '8x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*200',
    '8x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*140',
    '10x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×140',
    '10x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X60',
    '10x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*60',
    '10x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×60',
    '10x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*220',
    '10x220',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×220',
    '10x220',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*250',
    '10x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X250',
    '10x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*300',
    '12x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×300',
    '12x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*50',
    '12x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12X50',
    '12x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×50',
    '12x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27*100',
    '27x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27×100',
    '27x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*35',
    '12x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×35',
    '12x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27*120',
    '27x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27×120',
    '27x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27×130',
    '27x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27*130',
    '27x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*30',
    '10x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×30',
    '10x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*30',
    '16x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×30',
    '16x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×60',
    '20x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*60',
    '20x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×80',
    '20x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*80',
    '20x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*110',
    '16x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X110',
    '16x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×110',
    '16x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*65',
    '12x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×65',
    '12x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X130',
    '5x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*130',
    '5x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X50',
    '5x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*50',
    '5x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*30',
    '5x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X30',
    '5x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*170',
    '5x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X170',
    '5x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*190',
    '6x190',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X190',
    '6x190',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×45',
    '5x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*45',
    '5x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X90',
    '6x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*90',
    '6x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*130',
    '6x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×130',
    '6x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*210',
    '5x210',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X210',
    '5x210',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8X70',
    '8x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*70',
    '8x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X245',
    '6x245',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*245',
    '6x245',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X110',
    '10x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*110',
    '10x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X35',
    '16x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*35',
    '16x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×35',
    '16x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X185',
    '10x185',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*185',
    '10x185',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X25',
    '6x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*25',
    '6x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18×80',
    '18x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*80',
    '18x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×14',
    '10x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*14',
    '10x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*24',
    '16x24',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×24',
    '16x24',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×170',
    '16x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*170',
    '16x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*90',
    '16x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×90',
    '16x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×200',
    '20x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*200',
    '20x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*220',
    '16x220',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×220',
    '16x220',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*160',
    '20x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×160',
    '20x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*40',
    '12x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12X40',
    '12x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*50',
    '20x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×50',
    '20x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×40',
    '20x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*40',
    '20x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X40',
    '20x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*20',
    '10x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×20',
    '10x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×50',
    '14x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*50',
    '14x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×25',
    '8x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8X25',
    '8x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*25',
    '8x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×30',
    '6x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*30',
    '6x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X30',
    '6x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*15',
    '10x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X15',
    '10x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*70',
    '18x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18×70',
    '18x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*130',
    '24x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×130',
    '24x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*2',
    '18x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18×2',
    '18x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*150',
    '5x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X150',
    '5x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*60',
    '14x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×60',
    '14x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×16',
    '8x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*16',
    '8x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*60',
    '30x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*160',
    '16x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×160',
    '16x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×220',
    '24x220',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*220',
    '24x220',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×18',
    '12x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*18',
    '12x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48×480',
    '48x480',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*480',
    '48x480',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*135',
    '10x135',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×135',
    '10x135',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40X40',
    '40x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*40',
    '40x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*90',
    '18x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18×90',
    '18x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18X90',
    '18x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*125',
    '5x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X36',
    '6x36',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×36',
    '6x36',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*36',
    '6x36',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X75',
    '10x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*75',
    '10x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*20',
    '12x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*12',
    '6x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X12',
    '6x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×12',
    '6x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30X135',
    '30x135',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*135',
    '30x135',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*30',
    '4x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18×60',
    '18x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*60',
    '18x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*12',
    '8x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×12',
    '8x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75*50',
    '75x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75×50',
    '75x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75×30',
    '75x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75*30',
    '75x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×40',
    '25x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*40',
    '25x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*10',
    '6x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×10',
    '6x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*10',
    '5x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X10',
    '5x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×10',
    '5x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*45',
    '8x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×45',
    '8x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8X45',
    '8x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*16',
    '6x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X16',
    '6x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×16',
    '6x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*280',
    '20x280',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×280',
    '20x280',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×1000',
    '20x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*1000',
    '20x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*16',
    '5x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X16',
    '5x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×16',
    '5x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*180',
    '16x180',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X180',
    '16x180',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*190',
    '16x190',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×190',
    '16x190',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*1',
    '24x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24X1',
    '24x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×1',
    '24x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*130',
    '14x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14X130',
    '14x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×8',
    '5x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*8',
    '5x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×90',
    '8x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*90',
    '8x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×500',
    '20x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*500',
    '20x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X15',
    '6x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*15',
    '6x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*25',
    '14x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×25',
    '14x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*35',
    '18x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18×35',
    '18x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*20',
    '4x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*55',
    '14x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14X55',
    '14x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×190',
    '24x190',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*190',
    '24x190',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*25',
    '25x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X25',
    '25x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X12',
    '10x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*12',
    '10x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36×600',
    '36x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36*600',
    '36x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*1000',
    '24x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×1000',
    '24x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*215',
    '10x215',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×215',
    '10x215',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*55',
    '22x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*18',
    '16x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×15',
    '4x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*15',
    '4x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*7',
    '10x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X7',
    '10x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*3',
    '8x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8X3',
    '8x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×3',
    '8x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×10',
    '4x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*10',
    '4x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4X10',
    '4x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*16',
    '16x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X16',
    '16x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*25',
    '5x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×25',
    '5x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X25',
    '5x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*25',
    '16x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×25',
    '16x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*150',
    '6x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×150',
    '6x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×45',
    '24x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*45',
    '24x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*80',
    '30x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×80',
    '30x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×20',
    '20x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*20',
    '20x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42×110',
    '42x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42X110',
    '42x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42*110',
    '42x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×6',
    '4x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*6',
    '4x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*8',
    '4x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4X8',
    '4x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '11*1',
    '11x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '11×1',
    '11x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×30',
    '25x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*30',
    '25x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*50',
    '30x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×50',
    '30x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X35',
    '5x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*35',
    '5x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×4',
    '16x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*4',
    '16x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*5',
    '3x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×5',
    '3x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12X230',
    '12x230',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*230',
    '12x230',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X0',
    '5x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*0',
    '5x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*70',
    '30x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*75',
    '5x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42*1050',
    '42x1050',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36*900',
    '36x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×1170',
    '160x1170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*1170',
    '160x1170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42*1000',
    '42x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*760',
    '30x760',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*1200',
    '48x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×270',
    '24x270',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*270',
    '24x270',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*120',
    '25x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X120',
    '25x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27×250',
    '27x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27*250',
    '27x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×310',
    '20x310',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*310',
    '20x310',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36*1',
    '36x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36×1',
    '36x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*75',
    '30x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×75',
    '30x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*320',
    '16x320',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X320',
    '16x320',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*25',
    '4x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4X25',
    '4x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×16',
    '4x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*16',
    '4x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×2',
    '8x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8X2',
    '8x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*2',
    '8x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*2',
    '5x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X2',
    '5x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×2',
    '5x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42*120',
    '42x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42×120',
    '42x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×240',
    '14x240',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*240',
    '14x240',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×5',
    '6x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*5',
    '6x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X3',
    '6x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×3',
    '6x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*3',
    '6x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X22',
    '20x22',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*22',
    '20x22',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*56',
    '20x56',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X56',
    '20x56',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12X5',
    '12x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*5',
    '12x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×5',
    '12x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*3',
    '14x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×7',
    '8x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*7',
    '8x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*260',
    '22x260',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22×260',
    '22x260',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*6',
    '2x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X6',
    '2x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×6',
    '2x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '33×1',
    '33x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '33*1',
    '33x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*130',
    '10x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X130',
    '10x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*75',
    '8x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×75',
    '8x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×10',
    '3x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*10',
    '3x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X10',
    '3x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X700',
    '20x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*700',
    '20x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×700',
    '20x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22X140',
    '22x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*140',
    '22x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22×140',
    '22x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×10',
    '10x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*10',
    '10x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*3',
    '25x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×3',
    '25x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X3',
    '25x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X1',
    '3x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*1',
    '3x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×1',
    '3x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*1',
    '1x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X1',
    '1x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×1',
    '1x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*165',
    '30x165',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*135',
    '24x135',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×135',
    '24x135',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*12',
    '3x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X150',
    '3x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*150',
    '3x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×150',
    '3x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17*2',
    '17x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17×2',
    '17x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22×3',
    '22x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22X3',
    '22x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*3',
    '22x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*125',
    '6x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X16',
    '2x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*16',
    '2x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×16',
    '2x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*5',
    '4x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×5',
    '4x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×3',
    '3x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X3',
    '3x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*3',
    '3x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*35',
    '4x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*8',
    '6x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×8',
    '6x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*8',
    '3x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*4',
    '30x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×4',
    '30x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*3',
    '32x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×3',
    '32x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32X3',
    '32x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×3',
    '4x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*3',
    '4x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4X3',
    '4x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273×8',
    '273x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273*8',
    '273x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '720*8',
    '720x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '720×8',
    '720x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '720X8',
    '720x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630*8',
    '630x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630×8',
    '630x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '377*8',
    '377x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '377×8',
    '377x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*2',
    '3x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×2',
    '3x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X2',
    '3x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800×2000',
    '800x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*2000',
    '800x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800×800',
    '800x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*800',
    '800x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800X800',
    '800x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600*800',
    '600x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600X800',
    '600x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200×150',
    '200x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200X150',
    '200x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*150',
    '200x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*55',
    '30x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×55',
    '30x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*200',
    '500x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500×200',
    '500x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500X200',
    '500x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*8',
    '18x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18×8',
    '18x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*2',
    '24x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×2',
    '2x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*2',
    '2x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X2',
    '2x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*25',
    '24x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×25',
    '24x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60X3',
    '60x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×3',
    '60x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*3',
    '60x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*85',
    '65x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×85',
    '65x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65X85',
    '65x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '275×310',
    '275x310',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '275*310',
    '275x310',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95X120',
    '95x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95*120',
    '95x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*50',
    '100x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X50',
    '100x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×50',
    '100x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*110',
    '160x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×110',
    '160x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*8',
    '200x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200×8',
    '200x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*80',
    '80x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×80',
    '80x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X80',
    '80x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*16',
    '12x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22×40',
    '22x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*40',
    '22x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×15',
    '45x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*15',
    '45x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*5',
    '20x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×5',
    '20x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X5',
    '20x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2000*2000',
    '2000x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*400',
    '200x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200×400',
    '200x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140×250',
    '140x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140*250',
    '140x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1800*400',
    '1800x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1800×400',
    '1800x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*250',
    '250x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250X250',
    '250x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*4',
    '20x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×4',
    '20x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '21*26',
    '21x26',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '21X26',
    '21x26',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14X18',
    '14x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*18',
    '14x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*300',
    '400x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400X300',
    '400x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400×300',
    '400x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×3',
    '1x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X3',
    '1x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*3',
    '1x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×65',
    '100x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*65',
    '100x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×2',
    '12x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12X2',
    '12x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*2',
    '12x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×2',
    '10x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X2',
    '10x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*2',
    '10x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45X45',
    '45x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*45',
    '45x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120*5',
    '120x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120×5',
    '120x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18X22',
    '18x22',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*22',
    '18x22',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*1000',
    '1000x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000X1000',
    '1000x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000×1000',
    '1000x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×55',
    '45x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*55',
    '45x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*19',
    '24x19',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×19',
    '24x19',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4X4',
    '4x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*4',
    '4x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×4',
    '4x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*8',
    '50x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63×53',
    '63x53',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63*53',
    '63x53',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125X5',
    '125x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*5',
    '125x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*3',
    '133x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125×3',
    '125x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*3',
    '125x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35×4',
    '35x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35*4',
    '35x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70×84',
    '70x84',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*84',
    '70x84',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150X75',
    '150x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*75',
    '150x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150X80',
    '150x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*80',
    '150x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150×80',
    '150x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*7',
    '3x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X7',
    '3x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*3',
    '45x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×3',
    '45x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45X3',
    '45x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×50',
    '50x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50X50',
    '50x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*50',
    '50x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×40',
    '2x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*40',
    '2x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X14',
    '2x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*14',
    '2x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350×350',
    '350x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350X350',
    '350x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350*350',
    '350x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*3',
    '2x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×3',
    '2x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*100',
    '1x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×100',
    '1x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×8',
    '8x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*8',
    '8x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300X110',
    '300x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*110',
    '300x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200X1000',
    '1200x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200*1000',
    '1200x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450×450',
    '450x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450*450',
    '450x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×700',
    '12x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*700',
    '12x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*100',
    '60x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*150',
    '60x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60X150',
    '60x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '185*390',
    '185x390',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '185×390',
    '185x390',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140*4',
    '140x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140X4',
    '140x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140×4',
    '140x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*6',
    '300x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*6',
    '500x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500X6',
    '500x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200×70',
    '200x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*70',
    '200x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*400',
    '300x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300×400',
    '300x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*1',
    '25x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×1',
    '25x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600*450',
    '600x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600×450',
    '600x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*150',
    '100x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X150',
    '100x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000X500',
    '1000x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*500',
    '1000x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*100',
    '3x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×100',
    '3x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1800×3230',
    '1800x3230',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1800*3230',
    '1800x3230',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26*1',
    '26x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26X1',
    '26x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26×1',
    '26x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×2',
    '1x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*2',
    '1x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X2',
    '1x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*1200',
    '800x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*2',
    '22x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22×2',
    '22x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4X1',
    '4x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*1',
    '4x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×1',
    '4x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×1000',
    '12x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*1000',
    '12x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×4',
    '25x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*4',
    '25x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×15',
    '2x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*15',
    '2x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120*120',
    '120x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120X120',
    '120x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*800',
    '16x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×800',
    '16x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X800',
    '16x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30X30',
    '30x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*30',
    '30x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×30',
    '30x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '58*1',
    '58x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '58X1',
    '58x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200×3',
    '200x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*3',
    '200x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35×3',
    '35x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35*3',
    '35x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×3',
    '160x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*3',
    '160x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26*2',
    '26x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26×2',
    '26x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*20',
    '50x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×20',
    '50x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '220×45',
    '220x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '220*45',
    '220x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*18',
    '32x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*8',
    '12x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×8',
    '12x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*9',
    '14x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×9',
    '14x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28*16',
    '28x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28×16',
    '28x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*14',
    '25x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×14',
    '25x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*3',
    '16x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×3',
    '16x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X3',
    '16x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*6',
    '25x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×6',
    '25x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*8',
    '65x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65X8',
    '65x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*10',
    '100x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X10',
    '100x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×10',
    '100x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*10',
    '125x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125×10',
    '125x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*10',
    '200x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1400*1400',
    '1400x1400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*80',
    '160x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×80',
    '160x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '219*6',
    '219x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '219X6',
    '219x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '219×6',
    '219x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28×1',
    '28x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28*1',
    '28x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*2',
    '50x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×2',
    '50x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28*2',
    '28x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28×2',
    '28x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34X2',
    '34x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34*2',
    '34x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34×2',
    '34x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38×2',
    '38x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38X2',
    '38x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*2',
    '38x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×25',
    '2x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X25',
    '2x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*25',
    '2x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '11*2',
    '11x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '11X2',
    '11x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×3',
    '20x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*3',
    '20x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X3',
    '20x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*5',
    '1x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X5',
    '1x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×0',
    '2x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*0',
    '2x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*2',
    '32x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×2',
    '32x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32X2',
    '32x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*82',
    '55x82',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55×82',
    '55x82',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250×150',
    '250x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*150',
    '250x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4X21',
    '4x21',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×38',
    '10x38',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*38',
    '10x38',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*10',
    '38x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38X10',
    '38x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×70',
    '1x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*70',
    '1x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*16',
    '1x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*50',
    '1x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×50',
    '1x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X50',
    '1x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '595*595',
    '595x595',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '595×595',
    '595x595',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×36',
    '1x36',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*36',
    '1x36',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*8',
    '1x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×8',
    '1x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*200',
    '1x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×200',
    '1x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×150',
    '1x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X150',
    '1x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*150',
    '1x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*80',
    '1x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×80',
    '1x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*18',
    '2x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×18',
    '2x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*18',
    '1x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×18',
    '1x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*20',
    '2x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X20',
    '2x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500×110',
    '500x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*110',
    '500x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*20',
    '1x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X40',
    '1x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*40',
    '1x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×40',
    '1x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×5',
    '2x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*5',
    '2x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X5',
    '2x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*600',
    '800x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800X600',
    '800x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800×600',
    '800x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*600',
    '300x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300×600',
    '300x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600*300',
    '600x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600×300',
    '600x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×1',
    '2x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*1',
    '2x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X1',
    '2x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*100',
    '250x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250×100',
    '250x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450*300',
    '450x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '450×300',
    '450x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180X70',
    '180x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180*70',
    '180x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×16',
    '3x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*16',
    '3x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X16',
    '3x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*450',
    '6x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '165*40',
    '165x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×800',
    '8x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*800',
    '8x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×400',
    '6x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*400',
    '6x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '69×2',
    '69x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '69*2',
    '69x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15*3',
    '15x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15×3',
    '15x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15X3',
    '15x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*8400',
    '2x8400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '71*2',
    '71x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '71X2',
    '71x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '71×2',
    '71x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120X10',
    '120x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120×10',
    '120x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120*10',
    '120x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×6',
    '1x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*6',
    '1x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×4',
    '1x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X4',
    '1x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*4',
    '1x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '750×500',
    '750x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '750*500',
    '750x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*80',
    '2x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X80',
    '2x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×50',
    '2x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X50',
    '2x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*50',
    '2x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42*45',
    '42x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*4',
    '40x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×4',
    '40x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*95',
    '3x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×95',
    '3x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X240',
    '3x240',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×240',
    '3x240',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*240',
    '3x240',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '52*6',
    '52x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '52×6',
    '52x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '62×6',
    '62x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '62X6',
    '62x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '62*6',
    '62x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*8',
    '2x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2100*600',
    '2100x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000X600',
    '1000x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*600',
    '1000x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000X1500',
    '1000x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*1500',
    '1000x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800X1500',
    '800x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*1500',
    '800x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400X350',
    '400x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*350',
    '400x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500×600',
    '500x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*600',
    '500x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200*800',
    '1200x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*2200',
    '800x2200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400×500',
    '400x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*500',
    '400x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600*400',
    '600x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*300',
    '200x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200×300',
    '200x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200X1100',
    '1200x1100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*800',
    '1000x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000×800',
    '1000x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000X800',
    '1000x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600*500',
    '600x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600×500',
    '600x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*320',
    '800x320',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800×320',
    '800x320',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*1200',
    '1000x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*500',
    '300x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*850',
    '500x850',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500×850',
    '500x850',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '900*900',
    '900x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*500',
    '250x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600*350',
    '600x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600X350',
    '600x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600×350',
    '600x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*400',
    '400x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400×400',
    '400x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400X400',
    '400x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350*120',
    '350x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350×120',
    '350x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*6',
    '3x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X6',
    '3x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×6',
    '3x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*4',
    '3x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700X600',
    '700x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700*600',
    '700x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*400',
    '800x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*100',
    '160x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×100',
    '160x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700×400',
    '700x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700X400',
    '700x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700*400',
    '700x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700*300',
    '700x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '540*350',
    '540x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '540×350',
    '540x350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600*200',
    '600x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600×200',
    '600x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '550*700',
    '550x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*150',
    '150x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150X150',
    '150x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150×150',
    '150x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*32',
    '20x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×32',
    '20x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*70',
    '2x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×70',
    '2x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*700',
    '800x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800X700',
    '800x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1400*2800',
    '1400x2800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800X500',
    '800x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*500',
    '800x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*160',
    '160x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*60',
    '300x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300X60',
    '300x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300×100',
    '300x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*100',
    '300x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600*100',
    '600x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*0',
    '4x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×0',
    '4x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4X0',
    '4x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200X1200',
    '1200x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200*1200',
    '1200x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2800*1800',
    '2800x1800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '82*670',
    '82x670',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '82X670',
    '82x670',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*120',
    '1x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×120',
    '1x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350×150',
    '350x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350*150',
    '350x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48×6',
    '48x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*6',
    '48x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*5',
    '38x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38×5',
    '38x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15X8',
    '15x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15*8',
    '15x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×4',
    '5x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*4',
    '5x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42*112',
    '42x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42×112',
    '42x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×150',
    '80x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*150',
    '80x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*14',
    '14x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '900*800',
    '900x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '900X800',
    '900x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '900×800',
    '900x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2000*1200',
    '2000x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2000×1200',
    '2000x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*0',
    '6x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*7',
    '6x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×7',
    '6x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75*7',
    '75x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*240',
    '1x240',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×240',
    '1x240',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×400',
    '1x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*400',
    '1x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108×4',
    '108x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108X4',
    '108x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108*4',
    '108x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89X4',
    '89x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89×4',
    '89x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89*4',
    '89x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×120',
    '3x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*120',
    '3x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*7',
    '300x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300×7',
    '300x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×2',
    '4x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*2',
    '4x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4X2',
    '4x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×200',
    '50x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*200',
    '50x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*2',
    '500x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500×2',
    '500x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200×125',
    '200x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*125',
    '200x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200X125',
    '200x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85*40',
    '85x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125×65',
    '125x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*65',
    '125x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125X65',
    '125x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120*60',
    '120x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120×60',
    '120x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*60',
    '40x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40X60',
    '40x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19×1',
    '19x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19*1',
    '19x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7*0',
    '7x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*75',
    '60x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×75',
    '60x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '33*2',
    '33x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '33X2',
    '33x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '33×2',
    '33x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×3',
    '5x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*3',
    '5x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*8',
    '500x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500X8',
    '500x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500×8',
    '500x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*60',
    '80x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×60',
    '80x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*16',
    '20x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*185',
    '3x185',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×185',
    '3x185',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X300',
    '3x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*300',
    '3x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×25',
    '3x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X25',
    '3x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*25',
    '3x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X70',
    '3x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×70',
    '3x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*70',
    '3x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×185',
    '1x185',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*185',
    '1x185',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X185',
    '1x185',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*4',
    '2x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X4',
    '2x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×4',
    '2x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*35',
    '3x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3X35',
    '3x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×35',
    '3x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*60',
    '50x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×70',
    '60x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*70',
    '60x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*25',
    '50x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×25',
    '50x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50X25',
    '50x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40X20',
    '40x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*20',
    '40x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×20',
    '40x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*25',
    '40x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×25',
    '40x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*40',
    '100x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×40',
    '100x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180*302',
    '180x302',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120*202',
    '120x202',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130X252',
    '130x252',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130*252',
    '130x252',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '11X21',
    '11x21',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '11*21',
    '11x21',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*5',
    '8x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×5',
    '8x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159*5',
    '159x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159×5',
    '159x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76X4',
    '76x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76*4',
    '76x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76×4',
    '76x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '820×10',
    '820x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '820*10',
    '820x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200*1500',
    '1200x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200×1500',
    '1200x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×25',
    '65x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65X25',
    '65x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*25',
    '65x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27*4',
    '27x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27×4',
    '27x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60X4',
    '60x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*4',
    '60x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×4',
    '60x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '420*420',
    '420x420',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '600*420',
    '600x420',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38×6',
    '38x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*6',
    '38x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*10',
    '80x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×10',
    '80x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×2',
    '25x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X2',
    '25x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*2',
    '25x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '195*3',
    '195x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '195×3',
    '195x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426×8',
    '426x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426X8',
    '426x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426*8',
    '426x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '530*8',
    '530x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '530×8',
    '530x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×2000',
    '160x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*2000',
    '160x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630×630',
    '630x630',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630*630',
    '630x630',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*1200',
    '40x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×1200',
    '40x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42*5',
    '42x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42×5',
    '42x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125X100',
    '125x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125×100',
    '125x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*100',
    '125x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700×500',
    '700x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700X500',
    '700x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700*500',
    '700x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*6',
    '200x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*6',
    '150x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '325*7',
    '325x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '325X7',
    '325x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273X6',
    '273x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273*6',
    '273x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273×6',
    '273x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '225*3',
    '225x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '225×3',
    '225x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '114*4',
    '114x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '114×4',
    '114x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '114X4',
    '114x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×400',
    '5x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*400',
    '5x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28×3',
    '28x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28X3',
    '28x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28*3',
    '28x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34X3',
    '34x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34×3',
    '34x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34*3',
    '34x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108*8',
    '108x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108×8',
    '108x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '57×5',
    '57x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '57*5',
    '57x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*32',
    '65x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×32',
    '65x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*65',
    '65x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×65',
    '65x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65X65',
    '65x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*10',
    '25x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X10',
    '25x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×10',
    '25x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140*3',
    '140x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140×3',
    '140x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26*3',
    '26x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26×3',
    '26x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '132*3',
    '132x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '132×3',
    '132x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*0',
    '3x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×0',
    '3x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*88',
    '1x88',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×88',
    '1x88',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×4',
    '32x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32X4',
    '32x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*4',
    '32x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60X7',
    '60x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*7',
    '60x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×7',
    '60x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*100',
    '80x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*1200',
    '8x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*1000',
    '8x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8×1000',
    '8x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13*13',
    '13x13',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13X13',
    '13x13',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*180',
    '110x180',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*112',
    '50x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×112',
    '50x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48×112',
    '48x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*112',
    '48x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48X112',
    '48x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35×82',
    '35x82',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35*82',
    '35x82',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60X80',
    '60x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*80',
    '60x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95×172',
    '95x172',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95*172',
    '95x172',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*212',
    '100x212',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×212',
    '100x212',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×150',
    '4x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*150',
    '4x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*6',
    '80x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X6',
    '80x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×6',
    '80x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800X450',
    '800x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*450',
    '800x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X25',
    '1x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*25',
    '1x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×25',
    '1x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7*1',
    '7x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7X1',
    '7x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7×1',
    '7x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*100',
    '500x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500×100',
    '500x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×8',
    '60x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*8',
    '60x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*8',
    '100x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X8',
    '100x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*5',
    '25x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*1400',
    '133x1400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*380',
    '133x380',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150×125',
    '150x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*125',
    '150x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150X125',
    '150x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*465',
    '133x465',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50X6',
    '50x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*6',
    '50x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*212',
    '110x212',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110×212',
    '110x212',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120*212',
    '120x212',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120X212',
    '120x212',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32X20',
    '32x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×20',
    '32x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*20',
    '32x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159*6',
    '159x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159×6',
    '159x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*65',
    '80x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X65',
    '80x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×65',
    '80x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*50',
    '40x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×50',
    '40x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*32',
    '25x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X32',
    '25x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7*3',
    '7x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7×3',
    '7x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7X3',
    '7x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×15',
    '32x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*15',
    '32x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*10',
    '2x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×10',
    '2x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*200',
    '40x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40X200',
    '40x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*100',
    '2x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X100',
    '2x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X4',
    '80x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*4',
    '80x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42X2',
    '42x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42×2',
    '42x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42*2',
    '42x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '52*2',
    '52x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '52X2',
    '52x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '52×2',
    '52x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×80',
    '50x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*80',
    '50x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '57*3',
    '57x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '57X3',
    '57x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '57×3',
    '57x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38×3',
    '38x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*3',
    '38x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18×1',
    '18x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18X1',
    '18x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*1',
    '18x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133×4',
    '133x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*4',
    '133x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159X4',
    '159x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159×4',
    '159x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159*4',
    '159x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76×3',
    '76x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76*3',
    '76x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '325X6',
    '325x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '325×6',
    '325x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '325*6',
    '325x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '71X3',
    '71x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '71×3',
    '71x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '71*3',
    '71x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200×400',
    '1200x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*12',
    '12x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×2',
    '45x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*2',
    '45x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2090×1250',
    '2090x1250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2090*1250',
    '2090x1250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*32',
    '40x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×32',
    '40x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40X32',
    '40x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*80',
    '100x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X80',
    '100x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×80',
    '100x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X1200',
    '5x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*1200',
    '5x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7*16',
    '7x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7X16',
    '7x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X31',
    '5x31',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*31',
    '5x31',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2800*2800',
    '2800x2800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2800×2800',
    '2800x2800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X7',
    '16x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*7',
    '16x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2200*1800',
    '2200x1800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '219X5',
    '219x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '219*5',
    '219x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700X700',
    '700x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700×700',
    '700x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700*700',
    '700x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*32',
    '50x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×32',
    '50x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*16',
    '80x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×16',
    '80x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '560×560',
    '560x560',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '560X560',
    '560x560',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '560*560',
    '560x560',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*8',
    '32x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*4',
    '250x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '330X10',
    '330x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '330*10',
    '330x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000×10',
    '1000x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*10',
    '1000x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*20',
    '1000x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000×20',
    '1000x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*10',
    '110x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110X10',
    '110x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '592*592',
    '592x592',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*80',
    '25x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X80',
    '25x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*20',
    '400x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400X20',
    '400x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*20',
    '160x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160X20',
    '160x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630*10',
    '630x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630×10',
    '630x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250×10',
    '250x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*10',
    '250x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*65',
    '30x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '950×5',
    '950x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '950*5',
    '950x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '950X5',
    '950x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1300*20',
    '1300x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1300×20',
    '1300x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×80',
    '65x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*80',
    '65x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160X10',
    '160x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*10',
    '160x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '980*2',
    '980x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '980X2',
    '980x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180*195',
    '180x195',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180×195',
    '180x195',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*2000',
    '100x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X2000',
    '100x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*1',
    '80x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X1',
    '80x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×2000',
    '50x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*2000',
    '50x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×1500',
    '20x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*1500',
    '20x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*3000',
    '125x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125×3000',
    '125x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*2',
    '40x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×2',
    '40x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76*2',
    '76x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76×2',
    '76x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*2500',
    '50x2500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×2500',
    '50x2500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13×1000',
    '13x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13*1000',
    '13x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*1000',
    '10x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X1000',
    '10x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*1500',
    '10x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×1500',
    '10x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*1500',
    '25x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×1500',
    '25x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*1700',
    '20x1700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×1700',
    '20x1700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×2100',
    '40x2100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*2100',
    '40x2100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×2100',
    '50x2100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*2100',
    '50x2100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*2500',
    '18x2500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18×2500',
    '18x2500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*1300',
    '20x1300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×1300',
    '20x1300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*800',
    '20x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×800',
    '20x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*2000',
    '10x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X2000',
    '10x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×3000',
    '50x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*3000',
    '50x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*1',
    '50x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×1',
    '50x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*5000',
    '25x5000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×5000',
    '25x5000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×2000',
    '25x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*2000',
    '25x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×2200',
    '25x2200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*2200',
    '25x2200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*230',
    '50x230',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×230',
    '50x230',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50X230',
    '50x230',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*1800',
    '50x1800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×1800',
    '50x1800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19*2',
    '19x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19×2',
    '19x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×2500',
    '10x2500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*2500',
    '10x2500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '21*2',
    '21x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '21X2',
    '21x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '21×2',
    '21x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*1100',
    '32x1100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×1100',
    '32x1100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*1200',
    '20x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×1200',
    '20x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*500',
    '5x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×500',
    '5x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*1800',
    '32x1800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×1800',
    '32x1800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×1000',
    '50x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*1000',
    '50x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*3000',
    '40x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×3000',
    '40x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*1500',
    '16x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×1500',
    '16x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13*2',
    '13x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X2',
    '6x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*2',
    '6x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×2',
    '6x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*1',
    '65x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×1',
    '65x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56*2',
    '56x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56×2',
    '56x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56X2',
    '56x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×3000',
    '25x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*3000',
    '25x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*2000',
    '40x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×2000',
    '40x2000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*1800',
    '25x1800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×1800',
    '25x1800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*1200',
    '2x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×1200',
    '2x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X3',
    '100x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×3',
    '100x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*3',
    '100x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×3',
    '65x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*3',
    '65x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×1200',
    '12x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*1200',
    '12x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×2500',
    '25x2500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*2500',
    '25x2500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*6',
    '16x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×6',
    '16x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*500',
    '100x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X500',
    '100x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*3',
    '50x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×3',
    '50x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×1200',
    '50x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*1200',
    '50x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15X10',
    '15x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15*10',
    '15x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*3000',
    '20x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×3000',
    '20x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*900',
    '20x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×900',
    '20x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*800',
    '12x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×800',
    '12x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×20000',
    '16x20000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*20000',
    '16x20000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×1600',
    '25x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*1600',
    '25x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125X500',
    '125x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*500',
    '125x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108*5',
    '108x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108×5',
    '108x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*140',
    '70x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70X140',
    '70x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70×140',
    '70x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90×50',
    '90x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*50',
    '90x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '39*2',
    '39x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '39×2',
    '39x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*75',
    '55x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55X75',
    '55x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55X80',
    '55x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55×80',
    '55x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*80',
    '55x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×10',
    '20x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*10',
    '20x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X14',
    '20x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*14',
    '20x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*3',
    '70x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70X3',
    '70x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70×3',
    '70x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*40',
    '60x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×40',
    '60x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×1000',
    '5x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*1000',
    '5x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×130',
    '80x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*130',
    '80x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*85',
    '45x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×85',
    '45x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150×200',
    '150x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*200',
    '150x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*16',
    '10x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×16',
    '10x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180*2',
    '180x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180×2',
    '180x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110×150',
    '110x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*150',
    '110x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X40',
    '80x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*40',
    '80x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×40',
    '80x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*5',
    '150x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150X5',
    '150x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X16',
    '100x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*16',
    '100x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×180',
    '100x180',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*180',
    '100x180',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×110',
    '60x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*110',
    '60x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*135',
    '90x135',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90×135',
    '90x135',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*25',
    '100x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×25',
    '100x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*25',
    '32x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×25',
    '32x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32X25',
    '32x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150×210',
    '150x210',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*210',
    '150x210',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89×5',
    '89x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89*5',
    '89x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '155*100',
    '155x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*125',
    '300x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300×125',
    '300x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*30',
    '800x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800X30',
    '800x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '315*125',
    '315x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '315×125',
    '315x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7*4000',
    '7x4000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7×4000',
    '7x4000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*80',
    '200x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200×80',
    '200x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X74',
    '2x74',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×74',
    '2x74',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*5',
    '80x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X5',
    '80x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*10',
    '30x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30X10',
    '30x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*15',
    '50x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×15',
    '50x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*9',
    '16x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X9',
    '16x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×9',
    '16x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7*10',
    '7x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7×10',
    '7x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '43×6',
    '43x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '43*6',
    '43x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*4',
    '50x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50X4',
    '50x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70×142',
    '70x142',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70X142',
    '70x142',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*142',
    '70x142',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*10',
    '60x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×10',
    '60x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X50',
    '80x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*50',
    '80x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×50',
    '80x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '9*2',
    '9x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '9X2',
    '9x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '9×2',
    '9x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7X4',
    '7x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7*4',
    '7x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '9*4',
    '9x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '9X4',
    '9x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*16',
    '65x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×16',
    '65x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '165×380',
    '165x380',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '165*380',
    '165x380',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*10',
    '800x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800X10',
    '800x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*10',
    '400x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400×10',
    '400x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*10',
    '40x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40X10',
    '40x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*200',
    '80x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X200',
    '80x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×200',
    '80x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X25',
    '80x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*25',
    '80x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250X20',
    '250x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*20',
    '250x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1196×600',
    '1196x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1196*600',
    '1196x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350×100',
    '350x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350*100',
    '350x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X200',
    '25x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*200',
    '25x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65X140',
    '65x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*140',
    '65x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400X100',
    '400x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*100',
    '400x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400×100',
    '400x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*82',
    '38x82',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38×82',
    '38x82',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*107',
    '60x107',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×107',
    '60x107',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*84',
    '55x84',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55×84',
    '55x84',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '9*85',
    '9x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '9×85',
    '9x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '650*3000',
    '650x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*35',
    '45x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1500×2',
    '1500x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1500*2',
    '1500x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '220×520',
    '220x520',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '220*520',
    '220x520',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '220×1160',
    '220x1160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '220*1160',
    '220x1160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×170',
    '80x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*170',
    '80x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85*130',
    '85x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85×130',
    '85x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*95',
    '70x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*4',
    '14x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×4',
    '14x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36*4',
    '36x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19*4',
    '19x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19×4',
    '19x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*2400',
    '20x2400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×2400',
    '20x2400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×5000',
    '20x5000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*5000',
    '20x5000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×1700',
    '32x1700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*1700',
    '32x1700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*20',
    '100x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X20',
    '100x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×1900',
    '50x1900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*1900',
    '50x1900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38×4',
    '38x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38X4',
    '38x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*4',
    '38x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15*2',
    '15x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15×2',
    '15x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*800',
    '25x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×800',
    '25x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×1500',
    '12x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*1500',
    '12x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*1200',
    '16x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×1200',
    '16x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*1700',
    '40x1700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×1700',
    '40x1700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×1600',
    '40x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*1600',
    '40x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*1600',
    '16x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×1600',
    '16x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*1050',
    '20x1050',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×1050',
    '20x1050',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*1050',
    '25x1050',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×1050',
    '25x1050',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*1200',
    '25x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×1200',
    '25x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×1750',
    '40x1750',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*1750',
    '40x1750',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10X5000',
    '10x5000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*5000',
    '10x5000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*1050',
    '40x1050',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×1050',
    '40x1050',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*1300',
    '32x1300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×1300',
    '32x1300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*1300',
    '16x1300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×1300',
    '16x1300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*1100',
    '16x1100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×1100',
    '16x1100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*1150',
    '32x1150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×1150',
    '32x1150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*5600',
    '25x5600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×5600',
    '25x5600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*5600',
    '40x5600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×5600',
    '40x5600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×1250',
    '16x1250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*1250',
    '16x1250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*900',
    '12x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×900',
    '12x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×750',
    '12x750',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*750',
    '12x750',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×2200',
    '50x2200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*2200',
    '50x2200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*1150',
    '20x1150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×1150',
    '20x1150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*950',
    '20x950',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×950',
    '20x950',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*1600',
    '20x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×1600',
    '20x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×1300',
    '25x1300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*1300',
    '25x1300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×5600',
    '32x5600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*5600',
    '32x5600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×17000',
    '20x17000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*17000',
    '20x17000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*2300',
    '40x2300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×2300',
    '40x2300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*900',
    '16x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×900',
    '16x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '08*600',
    '08x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '08×600',
    '08x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '33×9000',
    '33x9000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '33*9000',
    '33x9000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2500*1600',
    '2500x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700*1600',
    '700x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700×1200',
    '700x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700*1200',
    '700x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1300*800',
    '1300x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2800*600',
    '2800x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2800×600',
    '2800x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '900*700',
    '900x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '900X700',
    '900x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '900×700',
    '900x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1600×500',
    '1600x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1600*500',
    '1600x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1500×1500',
    '1500x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1500*1500',
    '1500x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2000*1800',
    '2000x1800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2000X1800',
    '2000x1800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1300*600',
    '1300x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500*1600',
    '500x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '500×1600',
    '500x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1900*1100',
    '1900x1100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1900×1100',
    '1900x1100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*4',
    '6x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×4',
    '6x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*1500',
    '5x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5X1500',
    '5x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×300',
    '65x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*300',
    '65x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×20',
    '25x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*20',
    '25x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X20',
    '25x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×5',
    '100x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*5',
    '100x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108×6',
    '108x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108*6',
    '108x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*120',
    '40x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×120',
    '40x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*600',
    '200x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*180',
    '70x180',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70×180',
    '70x180',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110×210',
    '110x210',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*210',
    '110x210',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×1300',
    '2x1300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*1300',
    '2x1300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*530',
    '133x530',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*950',
    '200x950',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159*530',
    '159x530',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*1150',
    '133x1150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133×1150',
    '133x1150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '240*363',
    '240x363',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '240*580',
    '240x580',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89×315',
    '89x315',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89*315',
    '89x315',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*12',
    '125x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125×12',
    '125x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*600',
    '14x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14X600',
    '14x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '580*3',
    '580x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '580X3',
    '580x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*70',
    '45x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×70',
    '45x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×19',
    '6x19',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6X19',
    '6x19',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*19',
    '6x19',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '580X13',
    '580x13',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '580*13',
    '580x13',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '240*270',
    '240x270',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*100',
    '70x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70×100',
    '70x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*70',
    '40x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×70',
    '40x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65X90',
    '65x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*90',
    '65x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×90',
    '65x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×53',
    '45x53',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*53',
    '45x53',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X125',
    '100x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*125',
    '100x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*115',
    '90x115',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '290*80',
    '290x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '290X80',
    '290x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120X150',
    '120x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120*150',
    '120x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*172',
    '80x172',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×172',
    '80x172',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75X142',
    '75x142',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75*142',
    '75x142',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*340',
    '300x340',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300X340',
    '300x340',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '220×250',
    '220x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '220*250',
    '220x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X130',
    '100x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*130',
    '100x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*142',
    '65x142',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65X142',
    '65x142',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*112',
    '55x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55×112',
    '55x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55X112',
    '55x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*70',
    '125x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*16',
    '24x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×16',
    '24x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35×55',
    '35x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35*55',
    '35x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140×170',
    '140x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140*170',
    '140x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*65',
    '250x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250×65',
    '250x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63X6',
    '63x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63*6',
    '63x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*65',
    '55x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55X65',
    '55x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*55',
    '60x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×55',
    '60x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95*170',
    '95x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95×170',
    '95x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*400',
    '100x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×400',
    '100x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*80',
    '70x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70×80',
    '70x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130*160',
    '130x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130×160',
    '130x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2020*2020',
    '2020x2020',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1220*10',
    '1220x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1220×10',
    '1220x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1220X10',
    '1220x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5100*991',
    '5100x991',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5100×991',
    '5100x991',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4500×3700',
    '4500x3700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4500*3700',
    '4500x3700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×120',
    '100x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X120',
    '100x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*120',
    '100x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*110',
    '80x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '199×209',
    '199x209',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '199*209',
    '199x209',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*300',
    '160x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×300',
    '160x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*50',
    '110x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110×50',
    '110x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×12',
    '100x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*12',
    '100x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*300',
    '150x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150×300',
    '150x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75×3',
    '75x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75*3',
    '75x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '168*4',
    '168x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*190',
    '160x190',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×190',
    '160x190',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*50',
    '45x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*105',
    '65x105',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×105',
    '65x105',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*16',
    '14x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*72',
    '1x72',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X72',
    '1x72',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95*130',
    '95x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95×130',
    '95x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*80',
    '38x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38×80',
    '38x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*5',
    '50x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×5',
    '50x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*73',
    '2x73',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X73',
    '2x73',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×72',
    '50x72',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*72',
    '50x72',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13*1',
    '13x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×3',
    '40x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*3',
    '40x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28X50',
    '28x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28*50',
    '28x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×52',
    '30x52',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*52',
    '30x52',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '106×2',
    '106x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '106*2',
    '106x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '106*3',
    '106x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '106×3',
    '106x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '320×95',
    '320x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '320*95',
    '320x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*140',
    '110x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60X85',
    '60x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*85',
    '60x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×85',
    '60x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70×5',
    '70x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*5',
    '70x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*3000',
    '1000x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000×3000',
    '1000x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '163×8500',
    '163x8500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '163*8500',
    '163x8500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '163×8000',
    '163x8000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '163*8000',
    '163x8000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45X60',
    '45x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*60',
    '45x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×60',
    '45x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60X120',
    '60x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*120',
    '60x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*6000',
    '30x6000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×6000',
    '30x6000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108×10',
    '108x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108*10',
    '108x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180*50',
    '180x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180×50',
    '180x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*90',
    '125x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125×90',
    '125x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '135*160',
    '135x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '135×160',
    '135x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*120',
    '90x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '112*3',
    '112x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '112×3',
    '112x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56*330',
    '56x330',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56×330',
    '56x330',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*210',
    '100x210',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X210',
    '100x210',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125X450',
    '125x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*450',
    '125x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*95',
    '80x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×95',
    '80x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15×1',
    '15x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15*1',
    '15x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*18',
    '18x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18X18',
    '18x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*47',
    '2x47',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*150',
    '125x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125X150',
    '125x150',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*1',
    '32x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65X100',
    '65x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×100',
    '65x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*100',
    '65x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '105*130',
    '105x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '105X130',
    '105x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*85',
    '70x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70×85',
    '70x85',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*110',
    '48x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48×110',
    '48x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*80',
    '250x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250×80',
    '250x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*172',
    '90x172',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90×172',
    '90x172',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×55',
    '2x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X55',
    '2x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*55',
    '2x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200*2',
    '1200x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200X2',
    '1200x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '240X3',
    '240x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '240*3',
    '240x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63*100',
    '63x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*6',
    '160x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160X6',
    '160x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89×6',
    '89x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89*6',
    '89x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75*83',
    '75x83',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75×83',
    '75x83',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110×165',
    '110x165',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*165',
    '110x165',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '371072*21',
    '371072x21',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '371072X21',
    '371072x21',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*6000',
    '40x6000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×6000',
    '40x6000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*250',
    '160x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×250',
    '160x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X8',
    '20x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*8',
    '20x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '122X3',
    '122x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '122×3',
    '122x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '122*3',
    '122x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×47',
    '25x47',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*47',
    '25x47',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22×32',
    '22x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*32',
    '22x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95*145',
    '95x145',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95×145',
    '95x145',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250×7',
    '250x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*7',
    '250x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*80',
    '45x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×80',
    '45x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*3',
    '18x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18×3',
    '18x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '170*302',
    '170x302',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×95',
    '60x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*95',
    '60x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*105',
    '70x105',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70×105',
    '70x105',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '67×100',
    '67x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '67*100',
    '67x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '62*95',
    '62x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '62×95',
    '62x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '72*105',
    '72x105',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '72×105',
    '72x105',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130×202',
    '130x202',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130*202',
    '130x202',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '51*195',
    '51x195',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '51×195',
    '51x195',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*5',
    '55x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800×20',
    '800x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*20',
    '800x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10*0',
    '10x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '10×0',
    '10x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*1660',
    '800x1660',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*1660',
    '1000x1660',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*2160',
    '1000x2160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×1450',
    '6x1450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1742×141',
    '1742x141',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1742*141',
    '1742x141',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2900*20',
    '2900x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2900×20',
    '2900x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '760*25',
    '760x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '760×25',
    '760x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '700*1500',
    '700x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1100X1000',
    '1100x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1100*1000',
    '1100x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1400*700',
    '1400x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1400×700',
    '1400x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*12',
    '16x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16X12',
    '16x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89*3',
    '89x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89×3',
    '89x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89X3',
    '89x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*15',
    '20x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×15',
    '20x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X15',
    '20x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273*219',
    '273x219',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273×219',
    '273x219',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17*1',
    '17x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17×1',
    '17x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*40',
    '65x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×40',
    '65x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '0×4',
    '0x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '0X4',
    '0x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28×4',
    '28x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28*4',
    '28x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*50',
    '65x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65X50',
    '65x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×50',
    '65x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40X15',
    '40x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*15',
    '40x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×15',
    '40x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34*4',
    '34x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34×4',
    '34x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '51*5',
    '51x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '51×5',
    '51x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27*3',
    '27x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27×3',
    '27x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '21*3',
    '21x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '21X3',
    '21x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76×8',
    '76x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76*8',
    '76x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*125',
    '250x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250×125',
    '250x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '102×10',
    '102x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '102*10',
    '102x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76×6',
    '76x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '76*6',
    '76x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7×6',
    '7x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7*6',
    '7x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7X6',
    '7x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7×2',
    '7x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '7*2',
    '7x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133×8',
    '133x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*8',
    '133x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133×6',
    '133x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*6',
    '133x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '325×8',
    '325x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '325*8',
    '325x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*12',
    '150x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150X12',
    '150x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150×12',
    '150x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '57×4',
    '57x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '57X4',
    '57x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '57*4',
    '57x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '820*12',
    '820x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '820×12',
    '820x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426X9',
    '426x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426*9',
    '426x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426*6',
    '426x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426×6',
    '426x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426X6',
    '426x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159*8',
    '159x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159×8',
    '159x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426×10',
    '426x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426*10',
    '426x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '820*8',
    '820x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '820X8',
    '820x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*10',
    '133x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133×10',
    '133x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56*3',
    '56x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '56×3',
    '56x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*4',
    '200x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200X4',
    '200x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630×12',
    '630x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630*12',
    '630x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '480*10',
    '480x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '377×6',
    '377x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '377*6',
    '377x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '377X6',
    '377x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273×4',
    '273x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273*4',
    '273x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1820X12',
    '1820x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1820*12',
    '1820x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1020X10',
    '1020x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1020*10',
    '1020x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1020×10',
    '1020x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630×6',
    '630x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630*6',
    '630x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630X6',
    '630x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '377*9',
    '377x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '377×9',
    '377x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '245X28',
    '245x28',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '245*28',
    '245x28',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '194*22',
    '194x22',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '194X22',
    '194x22',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '529*10',
    '529x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '529×10',
    '529x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '325*10',
    '325x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2020×14',
    '2020x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2020*14',
    '2020x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2020×12',
    '2020x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2020*12',
    '2020x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2020X12',
    '2020x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '219*4',
    '219x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1420*12',
    '1420x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1420×12',
    '1420x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1220*11',
    '1220x11',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1220×11',
    '1220x11',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '33×3',
    '33x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '33*3',
    '33x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '480×8',
    '480x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '480*8',
    '480x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '478×10',
    '478x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '478*10',
    '478x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1620*10',
    '1620x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1620×10',
    '1620x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '219×8',
    '219x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '219*8',
    '219x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '480X6',
    '480x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '480×6',
    '480x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '480*6',
    '480x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273X3',
    '273x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273×3',
    '273x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273*3',
    '273x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1220×6',
    '1220x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1220*6',
    '1220x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800X5',
    '800x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*5',
    '800x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1120X10',
    '1120x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1120*10',
    '1120x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630X7',
    '630x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630*7',
    '630x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63×2',
    '63x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63*2',
    '63x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '820*9',
    '820x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '820X9',
    '820x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273*7',
    '273x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273×7',
    '273x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '114*3',
    '114x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '114X3',
    '114x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '114×3',
    '114x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '219X3',
    '219x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '219*3',
    '219x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '219×3',
    '219x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '168×3',
    '168x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '168X3',
    '168x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '168*3',
    '168x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '406*3',
    '406x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '406X3',
    '406x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '813*4',
    '813x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '813X4',
    '813x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '324*3',
    '324x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '324X3',
    '324x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '0*3',
    '0x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '0X3',
    '0x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*5',
    '133x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133×5',
    '133x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14X1000',
    '14x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*1000',
    '14x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*12',
    '40x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×12',
    '40x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X35',
    '2x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*35',
    '2x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2×35',
    '2x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1110*600',
    '1110x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1110×600',
    '1110x600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2X65',
    '2x65',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000×6',
    '1000x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*6',
    '1000x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*6',
    '800x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800×6',
    '800x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000×5',
    '1000x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*5',
    '1000x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200*6',
    '1200x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200X6',
    '1200x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1400*6',
    '1400x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1400×6',
    '1400x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*4',
    '300x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*950',
    '250x950',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*1600',
    '400x1600',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*1400',
    '400x1400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400×2500',
    '400x2500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*2500',
    '400x2500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*28',
    '80x28',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X28',
    '80x28',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*36',
    '80x36',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X36',
    '80x36',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×7000',
    '160x7000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*7000',
    '160x7000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2000*5000',
    '2000x5000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2000X5000',
    '2000x5000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*112',
    '40x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40X112',
    '40x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×112',
    '40x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '132X2',
    '132x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '132*2',
    '132x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '132×2',
    '132x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8X24',
    '8x24',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*24',
    '8x24',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*12',
    '1x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×12',
    '1x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*45',
    '80x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×45',
    '80x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90×3200',
    '90x3200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*3200',
    '90x3200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*320',
    '45x320',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×320',
    '45x320',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*300',
    '45x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×300',
    '45x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '78X670',
    '78x670',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '78*670',
    '78x670',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85*172',
    '85x172',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85X172',
    '85x172',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140*252',
    '140x252',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140X252',
    '140x252',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*170',
    '90x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90×170',
    '90x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*115',
    '80x115',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×115',
    '80x115',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*82',
    '30x82',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×82',
    '30x82',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*110',
    '45x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×110',
    '45x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35*60',
    '35x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35×60',
    '35x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*200',
    '110x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110×200',
    '110x200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*167',
    '110x167',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110×167',
    '110x167',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*132',
    '90x132',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90×132',
    '90x132',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95*175',
    '95x175',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95×175',
    '95x175',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32X60',
    '32x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*60',
    '32x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*24',
    '80x24',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×24',
    '80x24',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×167',
    '100x167',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*167',
    '100x167',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×84',
    '45x84',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*84',
    '45x84',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45X84',
    '45x84',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55×110',
    '55x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*110',
    '55x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*1000',
    '1x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×1000',
    '1x1000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*44',
    '25x44',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130*220',
    '130x220',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130×220',
    '130x220',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X170',
    '100x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*170',
    '100x170',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '170×300',
    '170x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '170X300',
    '170x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35*70',
    '35x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35×70',
    '35x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*84',
    '50x84',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*212',
    '125x212',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*125',
    '90x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×165',
    '100x165',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*165',
    '100x165',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35*80',
    '35x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35×80',
    '35x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*210',
    '300x210',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300×210',
    '300x210',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*40',
    '160x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160X40',
    '160x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160X50',
    '160x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*50',
    '160x50',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '170×80',
    '170x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '170*80',
    '170x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*110',
    '40x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×110',
    '40x110',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95*132',
    '95x132',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95×132',
    '95x132',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*215',
    '110x215',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110×215',
    '110x215',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×120',
    '80x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*120',
    '80x120',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45X112',
    '45x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*112',
    '45x112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '190*352',
    '190x352',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '190×240',
    '190x240',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '190*240',
    '190x240',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28*62',
    '28x62',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28×62',
    '28x62',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*60',
    '38x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38×60',
    '38x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '147*230102',
    '147x230102',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '147X230102',
    '147x230102',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140X202',
    '140x202',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140*202',
    '140x202',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*69',
    '200x69',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200X69',
    '200x69',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85×115',
    '85x115',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85*115',
    '85x115',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*107',
    '50x107',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50X107',
    '50x107',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*80',
    '125x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125X80',
    '125x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125×80',
    '125x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80×14',
    '80x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*14',
    '80x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48×55',
    '48x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*55',
    '48x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120X167',
    '120x167',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120*167',
    '120x167',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×215',
    '100x215',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*215',
    '100x215',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180×242',
    '180x242',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180*242',
    '180x242',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*6000',
    '160x6000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×6000',
    '160x6000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120*1980',
    '120x1980',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120×1980',
    '120x1980',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×400',
    '160x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*400',
    '160x400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63*10',
    '63x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63×10',
    '63x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '143*485',
    '143x485',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '143×485',
    '143x485',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63*20',
    '63x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63×20',
    '63x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*30',
    '150x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120*80',
    '120x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120×80',
    '120x80',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63*5',
    '63x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63X5',
    '63x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*95',
    '160x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160X95',
    '160x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*70',
    '150x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150×70',
    '150x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25×45',
    '25x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X45',
    '25x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*45',
    '25x45',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '168*5',
    '168x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '168X5',
    '168x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2820×12',
    '2820x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2820*12',
    '2820x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '377*10',
    '377x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2500*8',
    '2500x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2500×8',
    '2500x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '406X4',
    '406x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '406*4',
    '406x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1620×12',
    '1620x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1620*12',
    '1620x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70*6',
    '70x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '70X6',
    '70x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273X5',
    '273x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273*5',
    '273x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '530X6',
    '530x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '530*6',
    '530x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '720*5',
    '720x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '720×5',
    '720x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75×1',
    '75x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75*1',
    '75x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125*125',
    '125x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '125X125',
    '125x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1420*1020',
    '1420x1020',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1420×1020',
    '1420x1020',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1420*820',
    '1420x820',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1420×820',
    '1420x820',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1020*630',
    '1020x630',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1020×630',
    '1020x630',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '720×630',
    '720x630',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '720*630',
    '720x630',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426*219',
    '426x219',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '426×219',
    '426x219',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630*426',
    '630x426',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '630×426',
    '630x426',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89×10',
    '89x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89*10',
    '89x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*32',
    '110x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110X32',
    '110x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42×6',
    '42x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42*6',
    '42x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*33',
    '3x33',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273*10',
    '273x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '273×10',
    '273x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63*25',
    '63x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63X25',
    '63x25',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150*3',
    '150x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '150×3',
    '150x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000*900',
    '1000x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1000X900',
    '1000x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1220×820',
    '1220x820',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1220*820',
    '1220x820',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1020*720',
    '1020x720',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1020×720',
    '1020x720',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400×125',
    '400x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*125',
    '400x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15*60',
    '15x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '15×60',
    '15x60',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63×3',
    '63x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63*3',
    '63x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '920*8',
    '920x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '920X8',
    '920x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '508X3',
    '508x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '508*3',
    '508x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '610*4',
    '610x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '610X4',
    '610x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '51X235',
    '51x235',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '51*235',
    '51x235',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '530*580',
    '530x580',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '530×580',
    '530x580',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350×320',
    '350x320',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350*320',
    '350x320',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90X10',
    '90x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*10',
    '90x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*3',
    '55x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '400*440',
    '400x440',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65×75',
    '65x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '65*75',
    '65x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75×90',
    '75x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75*90',
    '75x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36×44',
    '36x44',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36*44',
    '36x44',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '650*800',
    '650x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200×550',
    '200x550',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*550',
    '200x550',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1850×900',
    '1850x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1850*900',
    '1850x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2000*900',
    '2000x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2000×900',
    '2000x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24×12',
    '24x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*12',
    '24x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200X700',
    '1200x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1200*700',
    '1200x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '8*0',
    '8x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '9×1',
    '9x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '9X1',
    '9x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '9*1',
    '9x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*16',
    '133x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133×16',
    '133x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '9*16',
    '9x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '950×700',
    '950x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '950*700',
    '950x700',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '194×6',
    '194x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '194*6',
    '194x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '46*3',
    '46x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '46×3',
    '46x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '108*3',
    '108x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*1500',
    '6x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6×1500',
    '6x1500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*2400',
    '16x2400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×2400',
    '16x2400',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140*10',
    '140x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140×10',
    '140x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '11*18',
    '11x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13×21',
    '13x21',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13*21',
    '13x21',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*17',
    '1x17',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×10',
    '1x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*10',
    '1x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X7',
    '1x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*7',
    '1x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*300',
    '5x300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4100*4100',
    '4100x4100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4100×4100',
    '4100x4100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130*8',
    '130x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130×8',
    '130x8',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X9',
    '20x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*9',
    '20x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*55',
    '25x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X55',
    '25x55',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3000×500',
    '3000x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3000*500',
    '3000x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1400*500',
    '1400x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1400×500',
    '1400x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*14',
    '110x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110X14',
    '110x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1820*900',
    '1820x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1820×900',
    '1820x900',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1100X1100',
    '1100x1100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1100*1100',
    '1100x1100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*9',
    '12x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12X9',
    '12x9',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*20',
    '55x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55×20',
    '55x20',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*1300',
    '800x1300',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2460×1370',
    '2460x1370',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2460*1370',
    '2460x1370',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×1',
    '45x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*1',
    '45x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*2',
    '300x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1100X800',
    '1100x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1100*800',
    '1100x800',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '48*0',
    '48x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '29*2',
    '29x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '29×2',
    '29x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*22',
    '22x22',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22X22',
    '22x22',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12×6',
    '12x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*6',
    '12x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*250',
    '100x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X250',
    '100x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*14',
    '12x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19X14',
    '19x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19*14',
    '19x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26*17',
    '26x17',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26×17',
    '26x17',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34*420',
    '34x420',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34×420',
    '34x420',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90X550',
    '90x550',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*550',
    '90x550',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100X550',
    '100x550',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*550',
    '100x550',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '320×428',
    '320x428',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '320*428',
    '320x428',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*5',
    '300x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*75',
    '3x75',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '34*36',
    '34x36',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*34',
    '32x34',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36*41',
    '36x41',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13*16',
    '13x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*27',
    '24x27',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '27*30',
    '27x30',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*32',
    '30x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17*19',
    '17x19',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19*22',
    '19x22',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*17',
    '14x17',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*24',
    '22x24',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '18*21',
    '18x21',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '41*46',
    '41x46',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*18',
    '100x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300X40',
    '300x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '300*40',
    '300x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350*40',
    '350x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12*190',
    '12x190',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '12X190',
    '12x190',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4X3505',
    '4x3505',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*3505',
    '4x3505',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×34',
    '1x34',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*34',
    '1x34',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14X12',
    '14x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*12',
    '14x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1X95',
    '1x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*95',
    '1x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×95',
    '1x95',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*35',
    '1x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×35',
    '1x35',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*62',
    '3x62',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×62',
    '3x62',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '24*0',
    '24x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×42',
    '3x42',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*42',
    '3x42',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4X70',
    '4x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*70',
    '4x70',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*252',
    '3x252',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3×252',
    '3x252',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*0',
    '16x0',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1×62',
    '1x62',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*62',
    '1x62',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*6',
    '14x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '351096*2',
    '351096x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '351096X2',
    '351096x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*238',
    '45x238',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*146',
    '5x146',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '05*111',
    '05x111',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*244',
    '55x244',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '475*193',
    '475x193',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*276',
    '45x276',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '225*222',
    '225x222',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4936X3',
    '4936x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4936*3',
    '4936x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4940X3',
    '4940x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4940*3',
    '4940x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130×230',
    '130x230',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130*230',
    '130x230',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250X68',
    '250x68',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '210X58',
    '210x58',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '210*58',
    '210x58',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180X69',
    '180x69',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180*69',
    '180x69',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32314*3',
    '32314x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32314X3',
    '32314x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32311*2',
    '32311x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32311X2',
    '32311x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30X16',
    '30x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*16',
    '30x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '360*290',
    '360x290',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '360×290',
    '360x290',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '352940X2',
    '352940x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '352940*2',
    '352940x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '352968X2',
    '352968x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '352968*2',
    '352968x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*6612',
    '5x6612',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×6612',
    '5x6612',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×5',
    '160x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160X5',
    '160x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*500',
    '4x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4×500',
    '4x500',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130*7',
    '130x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '130×7',
    '130x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95*3',
    '95x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '95×3',
    '95x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19×3',
    '19x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '19*3',
    '19x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '92X3',
    '92x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '92*3',
    '92x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '92×3',
    '92x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '62*3',
    '62x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '62×3',
    '62x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*3',
    '90x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90×3',
    '90x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '109*5',
    '109x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '109×5',
    '109x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '115×3',
    '115x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '115*3',
    '115x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '44×3',
    '44x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '44*3',
    '44x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '118*3',
    '118x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '118×3',
    '118x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '258*10',
    '258x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '258×10',
    '258x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '29×3',
    '29x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '29*3',
    '29x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '128*3',
    '128x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '128×3',
    '128x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '122*7',
    '122x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '122×7',
    '122x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '54*3',
    '54x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '54×3',
    '54x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '41*3',
    '41x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '41×3',
    '41x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '73*3',
    '73x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '73X3',
    '73x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '73×3',
    '73x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180×3',
    '180x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '180*3',
    '180x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '37×2',
    '37x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '37*2',
    '37x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '58*3',
    '58x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '58×3',
    '58x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '165×3',
    '165x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '165*3',
    '165x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17×3',
    '17x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17*3',
    '17x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85*5',
    '85x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85×5',
    '85x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '155*3',
    '155x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '155×3',
    '155x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '109×3',
    '109x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '109*3',
    '109x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '53*3',
    '53x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '53×3',
    '53x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85×3',
    '85x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85*3',
    '85x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '53*2',
    '53x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '53×2',
    '53x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '145×3',
    '145x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '145*3',
    '145x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '136×3',
    '136x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '136*3',
    '136x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '103×3',
    '103x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '103*3',
    '103x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '67×3',
    '67x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '67*3',
    '67x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '69×3',
    '69x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '69*3',
    '69x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '136×2',
    '136x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '136*2',
    '136x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140*2',
    '140x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140×2',
    '140x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '128×2',
    '128x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '128*2',
    '128x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160×2',
    '160x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*2',
    '160x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '170×2',
    '170x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '170*2',
    '170x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '112*2',
    '112x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '112×2',
    '112x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '118×2',
    '118x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '118*2',
    '118x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85×2',
    '85x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '85*2',
    '85x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '73*2',
    '73x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '73×2',
    '73x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '74*2',
    '74x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '74×2',
    '74x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '58*2',
    '58x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '58×2',
    '58x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '67×2',
    '67x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '67*2',
    '67x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '87×1',
    '87x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '87*1',
    '87x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55*1',
    '55x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '55×1',
    '55x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '71×1',
    '71x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '71*1',
    '71x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '29*1',
    '29x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '29×1',
    '29x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '265*3',
    '265x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '265×3',
    '265x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '280*3',
    '280x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '280×3',
    '280x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '304×3',
    '304x3',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '304*3',
    '304x3',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '345*3',
    '345x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '345×3',
    '345x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '236×3',
    '236x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '236*3',
    '236x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '258*3',
    '258x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '258×3',
    '258x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '260*3',
    '260x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '260×3',
    '260x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '190×3',
    '190x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '190*3',
    '190x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '206*3',
    '206x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '206×3',
    '206x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '175×3',
    '175x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '175*3',
    '175x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '185×3',
    '185x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '185*3',
    '185x3',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '206*5',
    '206x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '206×5',
    '206x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '115×5',
    '115x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '115*5',
    '115x5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '115X140',
    '115x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '115*140',
    '115x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50*90',
    '50x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '50×90',
    '50x90',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120*160',
    '120x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '120X160',
    '120x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75X10',
    '75x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '75*10',
    '75x10',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '53*63',
    '53x63',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '53X63',
    '53x63',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63*47',
    '63x47',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60*68',
    '60x68',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '60×68',
    '60x68',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14×26',
    '14x26',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '14*26',
    '14x26',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '6*3393',
    '6x3393',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40×2200',
    '40x2200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*2200',
    '40x2200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26X26',
    '26x26',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26*26',
    '26x26',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26X21',
    '26x21',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26*21',
    '26x21',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30×34',
    '30x34',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '30*34',
    '30x34',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '47X84',
    '47x84',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '47*84',
    '47x84',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13*1200',
    '13x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13X1200',
    '13x1200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17X1219',
    '17x1219',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17*1219',
    '17x1219',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13X1290',
    '13x1290',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13*1290',
    '13x1290',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17*1245',
    '17x1245',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '17X1245',
    '17x1245',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22*1105',
    '22x1105',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '22X1105',
    '22x1105',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5815863*1112',
    '5815863x1112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5815863X1112',
    '5815863x1112',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350212*2',
    '350212x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350212X2',
    '350212x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36X125',
    '36x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36*125',
    '36x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*125',
    '25x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X125',
    '25x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25X135',
    '25x135',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '25*135',
    '25x135',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '44*125',
    '44x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '44X125',
    '44x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '153*175',
    '153x175',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13*1194',
    '13x1194',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13X1194',
    '13x1194',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5815863*0111',
    '5815863x0111',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5815863X0111',
    '5815863x0111',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*7',
    '20x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X7',
    '20x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '98*130',
    '98x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '98X130',
    '98x130',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160*185',
    '160x185',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '160X185',
    '160x185',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*62',
    '38x62',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38X62',
    '38x62',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '117*127',
    '117x127',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '117X127',
    '117x127',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13053101*0001',
    '13053101x0001',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13053101X0001',
    '13053101x0001',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5×98',
    '5x98',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '5*98',
    '5x98',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*64',
    '20x64',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20X64',
    '20x64',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40X20136',
    '40x20136',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*20136',
    '40x20136',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90X180',
    '90x180',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '90*180',
    '90x180',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '49*100',
    '49x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '49X100',
    '49x100',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13*1555',
    '13x1555',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '13X1555',
    '13x1555',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35X125',
    '35x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '35*125',
    '35x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '43*125',
    '43x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '43X125',
    '43x125',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140X22',
    '140x22',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '140*22',
    '140x22',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '115X160',
    '115x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '115*160',
    '115x160',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38*128',
    '38x128',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '38X128',
    '38x128',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*128',
    '45x128',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45X128',
    '45x128',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26*250',
    '26x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '26X250',
    '26x250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32×1350',
    '32x1350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '32*1350',
    '32x1350',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36*40',
    '36x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '36X40',
    '36x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '377×12',
    '377x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '377*12',
    '377x12',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89*57',
    '89x57',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '89×57',
    '89x57',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '57*32',
    '57x32',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '168×7',
    '168x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '168*7',
    '168x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '121*4',
    '121x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '121×4',
    '121x4',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133×13',
    '133x13',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*13',
    '133x13',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159×18',
    '159x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159*18',
    '159x18',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45×7',
    '45x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '45*7',
    '45x7',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*850',
    '100x850',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×850',
    '100x850',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16*950',
    '16x950',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '16×950',
    '16x950',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2000X6',
    '2000x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2000*6',
    '2000x6',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350×140',
    '350x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '350*140',
    '350x140',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800*3000',
    '800x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '800×3000',
    '800x3000',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63X450',
    '63x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '63*450',
    '63x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80X450',
    '80x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '80*450',
    '80x450',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40X390',
    '40x390',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40*390',
    '40x390',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28*40',
    '28x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28×40',
    '28x40',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28*165',
    '28x165',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '28×165',
    '28x165',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3050*16',
    '3050x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3050X16',
    '3050x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250*255',
    '250x255',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '250×255',
    '250x255',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133*14',
    '133x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '133×14',
    '133x14',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159×16',
    '159x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '159*16',
    '159x16',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20*2250',
    '20x2250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20×2250',
    '20x2250',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '360*138',
    '360x138',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '360×138',
    '360x138',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110*2200',
    '110x2200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '110×2200',
    '110x2200',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*225',
    '100x225',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×225',
    '100x225',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100×560',
    '100x560',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '100*560',
    '100x560',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M20*1.5',
    'M20x1.5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M24*1',
    'M24x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M22*1',
    'M22x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M22*1.5',
    'M22x1.5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M16*1.5',
    'M16x1.5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M42*2',
    'M42x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M27*2',
    'M27x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M36*2',
    'M36x2',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '3*2.5',
    '3x2.5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M18*1',
    'M18x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M27*1.5',
    'M27x1.5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '2*1.5',
    '2x1.5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '1*15',
    '1x15',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M30*1',
    'M30x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'M16*1',
    'M16x1',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '4*1.5',
    '4x1.5',
    'specification',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '304',
    '不锈钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '316',
    '不锈钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '316L',
    '不锈钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'SS',
    '不锈钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'stainless steel',
    '不锈钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'CS',
    '碳钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'carbon steel',
    '碳钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'A105',
    '碳钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '20#',
    '碳钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'alloy steel',
    '合金钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '40Cr',
    '合金钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '42CrMo',
    '合金钢',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'cast iron',
    '铸铁',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'CI',
    '铸铁',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'HT200',
    '铸铁',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'HT250',
    '铸铁',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '黄铜',
    '铜',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Cu',
    '铜',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'copper',
    '铜',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'brass',
    '铜',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '铝合金',
    '铝',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Al',
    '铝',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'aluminum',
    '铝',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'aluminium',
    '铝',
    'material',
    'material',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '毫米',
    'mm',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'MM',
    'mm',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '公斤',
    'kg',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '千克',
    'kg',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'KG',
    'kg',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '兆帕',
    'MPa',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Mpa',
    'MPa',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'mpa',
    'MPa',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '巴',
    'bar',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'Bar',
    'bar',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'BAR',
    'bar',
    'unit',
    'unit',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '公称直径',
    'DN',
    'general',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'dn',
    'DN',
    'general',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '公称压力',
    'PN',
    'general',
    'specification',
    'system'
);

INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    'pn',
    'PN',
    'general',
    'specification',
    'system'
);

-- ========================================
-- 导入类别关键词
-- ========================================

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '原料',
    ARRAY['原料', '热轧卷板'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '合金料',
    ARRAY['钒氮合金', 'mm', '材质', '合金料', 'VN', '铝合金板', '铝合金'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '粘土砖',
    ARRAY['mm', '粘土砖'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '其它材料',
    ARRAY['mm', '其它材料'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '耐火土',
    ARRAY['mm', '耐火土'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '珍珠岩保温砖',
    ARRAY['耐高温', '膨胀珍珠岩砖', '珍珠岩保温砖', '漂珠砖', '耐火'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '轻质砖用泥浆',
    ARRAY['硅质泥浆', 'AHF', 'AGF', '轻质泥浆', '红柱石泥浆', '轻质砖用泥浆', '高铝泥浆'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '轻质高铝砖',
    ARRAY['轻质高铝砖', 'TC', '高铝砖'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '复合综合剂',
    ARRAY['ml', 'DCL', '乙醇汽油添加剂', 'BEC', '粉尘抑制剂', '欣天诚松动剂', '复合综合剂'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '石棉填料',
    ARRAY['石棉填料', '纤维石棉带'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢纤维耐火浇注料',
    ARRAY['钢纤维耐火浇注料', '钢纤维浇注料', '体积密度'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '喷涂料',
    ARRAY['CM', '喷涂料'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高温漆',
    ARRAY['耐高温', '高温漆'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '沙',
    ARRAY['沙', '混凝土'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '耐热混凝土',
    ARRAY['耐热混凝土', '泵送', '混凝土', '自卸'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '结合剂',
    ARRAY['皮带专用', '高温粘结剂', '多功能超级清洗剂', 'CB', '钛合金修补剂', 'LH', 'ZH', '结合剂', 'TS'],
    0.8,
    'general',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '刚玉莫来石砖',
    ARRAY['刚玉莫来石', '挡板砖', '刚玉莫来石砖'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '方砖',
    ARRAY['方砖', 'mm'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '风口',
    ARRAY['风口', '铝合金'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高炉砖',
    ARRAY['刚玉莫来石', '挡板砖', 'CDS', '锚固砖', '高炉砖'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '耐火砖',
    ARRAY['硅砖', '耐火砖'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '耐火沙',
    ARRAY['耐高温', 'KG', '石棉硅藻土粉', 'mm', '引流砂', '精细河沙', '隔热粉', '导热系数', '粒径', '耐火沙'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '粘土泥浆',
    ARRAY['专用泥浆', 'AHDF', '粘土火泥', 'NN', '高强微膨胀泥浆', '粘土泥浆'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '毡类',
    ARRAY['mm', '毡类', '玻璃棉卷毡'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '纤维毯',
    ARRAY['mm', '陶瓷纤维毯', '纤维毯'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '纤维板',
    ARRAY['GB', '波型', 'mm', '材质', 'YX', '机制玻璃纤维聚脂', '透明型', '基板厚度', '长度', '纤维板'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防火泥',
    ARRAY['防火隔断', '无机型', '防火涂料', 'DR', '防火泥'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '硅酸盐结合粘土质耐火泥浆',
    ARRAY['NF', '粘土质耐火泥浆', '高铝质耐火泥浆', '硅酸盐结合粘土质耐火泥浆', '莫来石耐火泥浆', 'MNJ', '刚玉莫来石泥浆', 'GMNJ', '高强度磷酸盐泥浆', 'LF'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '保护渣',
    ARRAY['mm', '方坯保护渣', '保护渣'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '油料',
    ARRAY['火花电蚀机油', 'KG', 'kg', '油料', 'MACRON', '威达', '薄层防锈剂', 'KLGFIF', 'EDM', '好富顿'],
    0.8,
    'electrical',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '齿轮油',
    ARRAY['CKC', 'KG', 'CKD', 'kg', '工业闭式齿轮油', '齿轮油', '昆仑'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '机油',
    ARRAY['KG', 'kg', '汽轮机油', 'TSA', '机油'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '润滑油',
    ARRAY['润滑油', 'kg', 'KG'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '机械油',
    ARRAY['机械油', 'kg', 'KG'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '无烟煤标样',
    ARRAY['无烟煤标样', '烟煤', '无烟煤', 'ZBM'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '木柴',
    ARRAY['烤沟用木头', '木柴', '测试物料'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高强度螺母',
    ARRAY['高强度螺母', '高强螺母'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '活母',
    ARRAY['活母', '旋转接头'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '膨胀螺栓',
    ARRAY['膨胀螺栓', '膨胀螺丝'],
    0.8,
    'fastener',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '各种角钢',
    ARRAY['各种角钢', '角钢'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '地脚螺栓',
    ARRAY['地脚螺丝', '地脚螺栓'],
    0.8,
    'fastener',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢螺栓',
    ARRAY['不锈钢螺丝', '不锈钢螺栓'],
    0.8,
    'fastener',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '镀锌螺栓',
    ARRAY['镀锌螺丝', '镀锌螺栓'],
    0.8,
    'fastener',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '普通螺丝',
    ARRAY['级螺丝', '普通螺丝'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电缆',
    ARRAY['YJV', 'ZR', '电缆', 'KV'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '普通管',
    ARRAY['DN', '普通管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '塑料胀栓',
    ARRAY['mm', '胀栓', '塑料胀栓'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铁胀栓',
    ARRAY['铁胀栓', '膨胀螺栓'],
    0.8,
    'fastener',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高强配合螺丝',
    ARRAY['级螺丝', '高强配合螺丝'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '一字螺栓',
    ARRAY['柱销螺栓', '一字螺栓', '螺栓'],
    0.8,
    'fastener',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '平头螺栓',
    ARRAY['平头螺栓', '螺栓'],
    0.8,
    'fastener',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '园头螺栓',
    ARRAY['园头螺栓', '圆头方颈螺栓'],
    0.8,
    'fastener',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '快丝',
    ARRAY['cm', '快丝'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '过滤芯',
    ARRAY['滤芯', '过滤芯'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '外丝',
    ARRAY['DN', '外丝'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '自攻螺丝',
    ARRAY['自攻螺丝', '十字槽螺丝'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '镀锌丝',
    ARRAY['镀锌铁丝', '镀锌丝'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '保险丝',
    ARRAY['保险丝', '保险'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '短丝',
    ARRAY['六角对丝', 'DN', '短丝', '六角外丝'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '对丝',
    ARRAY['DN', '对丝'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '短节（双丝头）',
    ARRAY['短节', 'DN', '短节（双丝头）'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢丝',
    ARRAY['mm', '铁丝', '钢丝'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '射钉',
    ARRAY['焊钉', '射钉', '电锤钻头', 'MM'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铁钉',
    ARRAY['mm', '铁钉', '鞋钉'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '皮带钉',
    ARRAY['mm', '皮带钉', '双皮带钉', '鞋钉'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '自攻钉',
    ARRAY['mm', '自攻钉'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钻尾钉',
    ARRAY['mm', '钻尾钉'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '干壁钉',
    ARRAY['mm', '干壁钉'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铝铆钉',
    ARRAY['铝铆钉', '平头铝铆钉', '铜铆钉'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卡钉',
    ARRAY['管卡一体塑壳钉', 'mm', '皮带卡子', '射钉管卡钉', '卡钉', '长卡钉'],
    0.8,
    'pipe',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '道钉',
    ARRAY['mm', '轨道钉', '无型号', '道钉', '螺旋道钉'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'U型卡子',
    ARRAY['U型卡子', '型卡', '型管卡', 'DN'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢丝绳卡子',
    ARRAY['钢丝绳卡头', '钢丝绳卡子'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锁',
    ARRAY['BD', '锁'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卡环',
    ARRAY['卡环', '卡箍'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '管卡子',
    ARRAY['型管卡', 'DN', '管卡子'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '立卡',
    ARRAY['立卡', 'PPR', 'de', '加长'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC立卡',
    ARRAY['PVC', 'De', 'PVC立卡', '立卡', '吊卡'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '托卡',
    ARRAY['托卡', 'PPR', 'DE', '加长'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '外卡',
    ARRAY['mm', '轴用卡簧', '外卡', '型滑线吊卡', '轴用弹簧挡圈外卡'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '吊卡',
    ARRAY['吊卡', '吊环', 'PVC'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '挂卡',
    ARRAY['mm', '挂卡', '附图样及台账', '铝板天车车号牌'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '马鞍卡',
    ARRAY['钢卷平均重量', '钢卷最大重量', '马鞍卡', 'max', 'mm', '成品鞍座', '钢卷宽度', '钢卷温度', '常温', '钢卷外径'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卸扣',
    ARRAY['弓形卸扣', '型卸扣', '卸扣'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '皮带扣',
    ARRAY['强力皮带扣', '皮带扣', 'DGK', '平板皮带扣'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '包装材料',
    ARRAY['内径', '宽度', '厚度', 'mm', '包装材料', '直径'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '扣件',
    ARRAY['公斤', '扣件', '型扣头'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '蝴蝶扣',
    ARRAY['蝴蝶扣', '双环扣'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卡扣',
    ARRAY['mm', '钢丝绳卡扣', '卡扣'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '软管扣',
    ARRAY['软管锁头', '软管扣', '消防水带快速接头'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '弹簧垫',
    ARRAY['弹簧垫', '弹性垫圈'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卡簧垫',
    ARRAY['mm', '卡簧垫', '止退垫圈'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '油任垫',
    ARRAY['油任垫', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '法兰垫',
    ARRAY['法兰垫', 'PN', 'DN', '垫片'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '石棉垫',
    ARRAY['mm', '石棉垫'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '方垫',
    ARRAY['方垫片', '方垫'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '胶垫',
    ARRAY['DN', '胶垫'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '脚踏垫',
    ARRAY['PVC', 'mm', '牛油头脚垫', '脚手架踏板', '地毯', '脚踏垫', '防滑地垫'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '复合垫',
    ARRAY['EPDM', 'PN', 'DN', 'PTFE', '组合垫', '复合垫', 'GARF', '复合垫片'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铜垫',
    ARRAY['mm', '铜垫'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铁锁',
    ARRAY['fswg', '型扣锁', '把手锁', '长园共创挂锁', '门禁锁', '万能钥匙老款', '铁锁', 'IC', '五防钥匙'],
    0.8,
    'general',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '门锁',
    ARRAY['mm', '门锁'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '塑钢门锁',
    ARRAY['塑钢门锁', '锁罩', 'ECL', '电气锁具', 'cm'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '球锁',
    ARRAY['球型锁', '球锁', 'DN', '球形锁', '闸阀锁'],
    0.8,
    'valve',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '三环锁',
    ARRAY['mm', '三环锁', '挂锁', '三环挂锁'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电磁锁',
    ARRAY['电磁锁', 'DSN', 'DC', '户内电磁锁', 'BMY', 'VDC'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '开口销',
    ARRAY['开口销', '弹性开口销'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '圆柱销',
    ARRAY['联轴器柱销', 'MM', '圆柱销'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '尼龙销',
    ARRAY['白色尼龙内六角螺母', '白色尼龙内六角螺栓', '尼龙销', '尼龙棒'],
    0.8,
    'fastener',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '丝网',
    ARRAY['mm', '丝网'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '筛网',
    ARRAY['mm', '筛网', 'XB'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '网片',
    ARRAY['mm', '网片', '护栏网'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢丝网',
    ARRAY['mm', '不锈钢丝网', '不锈钢筛网'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防晒网',
    ARRAY['防尘网', '绿防晒网', '防晒网'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '紧线器',
    ARRAY['不锈钢紧线器', '紧线器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '合页',
    ARRAY['mm', '铁合页', '合页'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '开孔器',
    ARRAY['mm', '开孔器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '盖子',
    ARRAY['盖子', '密封盖'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '各帽',
    ARRAY['DN', '管帽', '各帽'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '堵',
    ARRAY['DN', '管帽', '堵'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '镀锌板',
    ARRAY['mm', '材质', '镀锌板'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电机',
    ARRAY['KW', '电机'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢管',
    ARRAY['钢管', '焊接钢管', '无缝钢管'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '输送带',
    ARRAY['EP', '输送带'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铜鼻子',
    ARRAY['DT', '铜鼻子'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '滑轮',
    ARRAY['滑轮', '滑轮片'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '砝码',
    ARRAY['无磁不锈钢', 'kg', '校准砝码', '砝码'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '按钮开关',
    ARRAY['按钮开关', 'ZB'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '转换开关',
    ARRAY['万能转换开关', '转换开关', 'LW'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '脚踏开关',
    ARRAY['EKW', '脚踏开关'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '空气开关',
    ARRAY['DZ', '空气开关', '空开'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '负荷开关',
    ARRAY['Latr', 'NH', '负荷开关'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '头尾轮',
    ARRAY['头尾轮', 'ZS', 'NGT'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '各线',
    ARRAY['BV', '各线'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电磁开关',
    ARRAY['磁性开关', '电磁开关'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '拉线开关',
    ARRAY['拉绳开关', '防爆双向拉绳开关', 'EBBC', 'QZ', '拉线开关', 'XY'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防爆开关',
    ARRAY['防爆开关', 'AC', 'SW', 'BQM'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '辅助开关',
    ARRAY['辅助触点', '辅助开关'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '旋钮开关',
    ARRAY['LA', 'BZ', 'BD', 'ZB', 'XB', '旋钮开关'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '刀开关',
    ARRAY['BX', 'HD', '刀开关'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '选择开关',
    ARRAY['BZ', '选择开关', 'BJ', 'BD', 'ZB'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '真空接触器',
    ARRAY['LC', '真空接触器', 'GSC', '接触器'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '直流接触器',
    ARRAY['RT', '直流接触器', '接触器'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '交流接触器',
    ARRAY['LC', 'AC', '交流接触器', '接触器'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '接触器辅助触头',
    ARRAY['辅助触点', '接触器辅助触头', '辅助触头'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '直流断路器',
    ARRAY['直流检测单元', 'DC', '直流断路器', 'SZ', 'JK', 'DZ', '直流高分断小型断路器'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '万能断路器',
    ARRAY['AC', '万能断路器', '万能式断路器', 'GSW', '抽屉式', 'RMW'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '漏电断路器',
    ARRAY['DZ', '漏电断路器', '漏电保护器', 'LE'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '空气断路器',
    ARRAY['空气断路器', '断路器', '户内高压真空断路器', 'DZ', 'VBG'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '小型中间断路器',
    ARRAY['断路器', '小型中间断路器', 'IC', '小型断路器'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '真空继电器',
    ARRAY['VS', '真空继电器', 'ZN', '真空断路器', 'VBG', '高压真空断路器'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '智能断路器',
    ARRAY['RMW', '智能断路器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '中间继电器',
    ARRAY['RXM', '中间继电器'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '时间继电器',
    ARRAY['AC', '时间继电器'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '过流继电器',
    ARRAY['电流继电器', '过流继电器', 'JL'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '热继电器',
    ARRAY['LRD', '热继电器'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '保险管',
    ARRAY['保险管', 'RT', '保险'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '保险片',
    ARRAY['NT', '方白片', '保险', '保险片'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '熔芯',
    ARRAY['熔芯', 'RS', 'RT'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '熔断器',
    ARRAY['快熔', '熔断器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '灯泡',
    ARRAY['LED', '灯泡'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '滚筒',
    ARRAY['电动滚筒', '滚筒'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '白炽灯',
    ARRAY['紧凑型荧光灯', '方灯', '双管荧光灯', '防水防潮灯', 'DTGC', '带节能电子镇流器式节能荧光灯', 'LED', '白炽灯', '工矿灯'],
    0.8,
    'pipe',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '汞灯',
    ARRAY['自镇汞灯', '汞灯'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防爆灯',
    ARRAY['防爆灯', 'LED'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '节能灯',
    ARRAY['节能灯', 'LED'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '信号灯',
    ARRAY['mm', '信号灯'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '指示灯',
    ARRAY['指示灯', 'AD'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '吸顶灯',
    ARRAY['吸顶灯', 'LED'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '投光灯',
    ARRAY['LED', '投光灯'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '灯管',
    ARRAY['LED', '灯管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '手提灯',
    ARRAY['手把灯', 'AC', '手灯', '手提灯', 'LED'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '工作灯',
    ARRAY['LED', '工作灯'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防炫通路灯',
    ARRAY['防炫通路灯', 'LED', '路灯'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '弯灯',
    ARRAY['工厂弯灯', 'AC', '防爆型工厂弯灯', 'LED', '三防壁弯灯', '三方壁弯灯', '弯灯'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '荧光灯',
    ARRAY['AC', '荧光灯', '双管荧光灯', 'LED'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防水防尘灯',
    ARRAY['AC', '三防灯', '配防爆三通盒', '立杆', 'LED', '防水防尘灯', 'HD', '吸顶灯'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '壁灯',
    ARRAY['DC', '壁灯', '小时', '时间不小于', 'LED', '自带蓄电池'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '应急灯',
    ARRAY['应急灯', 'LED'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '吊顶灯',
    ARRAY['吊顶灯', 'LED'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卤钨灯',
    ARRAY['金卤灯', '金属卤化物灯', '卤钨灯珠', '卤钨灯', 'HQI', '钨灯'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '灯件',
    ARRAY['平板灯', '灯件', 'LED'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '台灯',
    ARRAY['MAH', '新清力护眼台灯', '台灯', 'LED'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '广场灯',
    ARRAY['庭院灯', 'AC', '白光', '景观草坪灯', '广场灯', 'LED', '地埋灯'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '探照灯',
    ARRAY['JSM', '探照灯', 'LED', '照明灯'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高杆灯',
    ARRAY['AC', '立杆三防灯', '三防立杆灯', 'NLC', '工厂三防立杆灯', 'LED', '高杆灯', '杆灯', '防爆双臂路灯'],
    0.8,
    'general',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卤化灯',
    ARRAY['金卤灯泡', '卤化灯', '金卤灯', '金属卤化物灯'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '检修行灯',
    ARRAY['检修行灯', 'LED', '检修灯'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高顶灯',
    ARRAY['OL', '工厂灯', 'GT', 'UFO', 'LED', '高顶灯', '工矿灯'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防爆信号灯',
    ARRAY['防爆声光报警灯', 'BBJ', '多信息复合标志灯', '防爆信号灯'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '泛光灯',
    ARRAY['JSM', '泛光灯', 'LED'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '灯头',
    ARRAY['ES', 'AA', 'SL', '灯头'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '灯架',
    ARRAY['灯架', '双管荧光灯架', '一体化灯架'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '纽扣电池',
    ARRAY['纽扣电池', 'CR', 'LR'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锂电池',
    ARRAY['锂电池', '电池'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铅电池',
    ARRAY['蓄电池', '铅电池'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电池',
    ARRAY['蓄电池', 'AH', '电池'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '地漏',
    ARRAY['PVC', '地漏'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '天车电阻',
    ARRAY['天车电阻', 'KW', '电阻器'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '压敏电阻',
    ARRAY['KPB', 'MYN', '压敏电阻', 'KJ'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '制动电阻',
    ARRAY['KW', '制动电阻'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '热电阻',
    ARRAY['PT', 'mm', '热电阻', 'WZP'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电阻',
    ARRAY['电阻', 'KW'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电阻芯',
    ARRAY['WZPK', 'MM', '铠装热电阻芯', 'mm', 'PT', '温度', '电阻芯'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电阻器',
    ARRAY['KW', 'RT', '电阻器'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '法兰',
    ARRAY['PN', 'DN', '法兰'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '无缝管',
    ARRAY['无缝管', '无缝钢管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '屏蔽电缆',
    ARRAY['屏蔽电缆', 'ZR'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电磁调速控制器',
    ARRAY['调速控制器', '调压调速控制器', '电磁调速控制器', 'QY'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '浮球控制器',
    ARRAY['mm', '浮球液位控制器', '浮球开关', '浮球控制器'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电机调速控制器',
    ARRAY['编码器', '电机调速控制器', 'QY'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '交流凸轮控制器',
    ARRAY['KT', '交流凸轮控制器', '凸轮控制器'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电流控制器',
    ARRAY['LXK', '电流控制器'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '报警控制器',
    ARRAY['火灾报警控制器', 'JB', '报警控制器', 'GST'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '行灯变压器',
    ARRAY['变压器', 'VA', '行灯变压器'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '控制变压器',
    ARRAY['VA', 'BK', '变压器', '控制变压器'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '整流变压器',
    ARRAY['整流变压器', 'KV', 'ZS'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '升压变压器',
    ARRAY['变压器', '点火变压器', '升压变压器', 'KVA', 'SCB'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '隔离变压器',
    ARRAY['隔离变压器', 'VA', 'KVA'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '线圈',
    ARRAY['电磁阀线圈', '线圈'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'S弯',
    ARRAY['大弧弯', 'S弯', 'JDG'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '刚玉热电偶',
    ARRAY['刚玉热电偶', 'mm', 'WRP', '热电偶'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铠装热电偶',
    ARRAY['铠装热电偶', 'WRNK', 'WRKK'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '普通热电偶',
    ARRAY['普通热电偶', 'mm', 'WRN', '热电偶'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '热电偶保护管',
    ARRAY['热电偶保护管', '耐腐蚀', '内径', 'DN', 'mm'],
    0.8,
    'pipe',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电解电容',
    ARRAY['EMKP', 'VDC', '电解电容', 'IA', 'MFD'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '压线鼻',
    ARRAY['压线鼻', '冷压闭口线鼻子', 'OT'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '降压器',
    ARRAY['过电压吸收器', 'KV', 'GL', 'KNQ', '前置放大器', '降压器', 'TV'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '限位器',
    ARRAY['限位器', 'DXZ'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '稳压器',
    ARRAY['UPS', 'TND', 'KVA', '稳压器'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC管',
    ARRAY['PVC管', 'PVC'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '仪表箱',
    ARRAY['KX', '仪表箱'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电源箱',
    ARRAY['开关电源', 'UPS', '电源', '电源箱'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电话箱',
    ARRAY['电话箱', '室外电话线'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '等电位箱',
    ARRAY['等电位箱', '总等电位连接箱', 'LEB', '或成品', '总等电位箱'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '测试箱',
    ARRAY['YSYW', 'Hmm', '紫外光耐气候试验箱', '接地测试箱', '或成品', '总电位测试箱', '测试箱'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '接地箱',
    ARRAY['KV', '接地箱', 'CM', '防爆接线箱', '高压接地棒'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '链类',
    ARRAY['拖链', '链类'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电位箱',
    ARRAY['暗装', '总等电位箱', '电位箱'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '按钮箱',
    ARRAY['DR', '按钮箱'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压柜',
    ARRAY['高压柜', 'KYN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '星点柜',
    ARRAY['星点柜', '空压机星点箱', 'KYN', 'XGNR', '星点互感器箱'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '软起柜',
    ARRAY['软起柜', 'MPS'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '机旁箱',
    ARRAY['机旁箱', 'JXF'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '杂动箱',
    ARRAY['杂动箱', 'mm'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '启动柜',
    ARRAY['KYN', '启动柜'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '开关柜',
    ARRAY['开关柜', 'KYN', 'Hmm'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电阻箱',
    ARRAY['配套', 'RA', 'KW', 'RJ', 'YZR', '波纹电阻箱', '电阻箱'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '开关箱',
    ARRAY['LSB', '吊车电源开关箱', '开关箱'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '终端箱',
    ARRAY['PZ', '终端箱'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PIC柜',
    ARRAY['PIC柜', 'PLC'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '保护箱',
    ARRAY['保护箱', '不锈钢控制箱带防尘箱门'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '弱电箱',
    ARRAY['弱电箱', '监控弱电箱'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动板牙',
    ARRAY['电动板牙', '圆板牙'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '阻垢剂',
    ARRAY['阻垢剂', 'DG'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '模块',
    ARRAY['ES', 'AA', '模块'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '轴流风机',
    ARRAY['轴流风机', 'KW'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电焊机',
    ARRAY['ZX', '电焊机'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '家用电器',
    ARRAY['KW', '家用电器'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '办公电子设备',
    ARRAY['办公电子设备', '电脑'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '截止阀',
    ARRAY['PN', 'DN', '截止阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '球阀',
    ARRAY['球阀', 'DN'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '止回阀',
    ARRAY['DN', '止回阀'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '弯头',
    ARRAY['弯头', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '节流阀',
    ARRAY['节流阀', 'FS', '单向节流阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '插头',
    ARRAY['插头', '航空插头'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '端子、终端头',
    ARRAY['端子、终端头', 'KV'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '金属软管',
    ARRAY['DN', '金属软管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '线槽',
    ARRAY['mm', 'PVC', '线槽'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电笔',
    ARRAY['电笔', '高压验电笔', 'KV'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '滑触线',
    ARRAY['安全滑触线', '滑触线'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钮类',
    ARRAY['按钮', 'ZB', 'BW', '钮类'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '异径管',
    ARRAY['DN', '异径管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '镀锌管',
    ARRAY['镀锌管', 'DN'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '监控系统',
    ARRAY['DS', '监控系统'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '油订',
    ARRAY['mm', '志高', '壁挂式电热器', '电热油汀', '油订', '暖煌壁挂式电暖气片', '减速机油镜'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '座类',
    ARRAY['座类', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '控制电缆',
    ARRAY['KVVR', 'KVVP', 'ZR', '控制电缆'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '护套线',
    ARRAY['护套线', 'RVV'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焊把线',
    ARRAY['焊把线', '铜焊把线'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '线览',
    ARRAY['电缆', '线览', 'ZR'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '阀门',
    ARRAY['阀门', 'DN'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '蝶阀',
    ARRAY['蝶阀', 'DN'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '助燃风机',
    ARRAY['助燃风机', '风机'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '放散阀',
    ARRAY['DN', 'FS', '放散阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '平垫铁',
    ARRAY['平垫铁', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '风叶（电机配件）',
    ARRAY['电机风扇叶', '风叶（电机配件）', 'YE'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PPR管箍',
    ARRAY['PPR管箍', 'DN', '管古', '管箍', 'PPR'],
    0.8,
    'pipe',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '镀锌槽钢',
    ARRAY['镀锌槽钢', '镀锌'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '减压阀',
    ARRAY['YM', '减压阀'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '启动器',
    ARRAY['软启动器', '启动器', 'KW', 'JJR'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '筛类',
    ARRAY['标准筛', '孔径', 'MM', 'mm', '筛类', '直径'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '闸阀',
    ARRAY['PN', 'DN', '闸阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '油封',
    ARRAY['油封', '骨架油封'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '腊管',
    ARRAY['mm', '黄腊管', '腊管'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢制三通',
    ARRAY['不锈钢三通', 'DN', '钢制三通'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '隔离器',
    ARRAY['隔离器', 'mA', 'CZ'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '配电隔离器',
    ARRAY['配电隔离器', 'MA'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '分配器',
    ARRAY['分配器', '油气分配器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '配电器',
    ARRAY['配电器', '隔离配电器', 'CZ'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变送器',
    ARRAY['EJA', '变送器', '压力变送器'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电位器',
    ARRAY['WX', '电位器'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '起动器',
    ARRAY['软起动器', '起动器', 'JJR'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '扩音机',
    ARRAY['SLK', '扩音机', '音响设备'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '扬声器',
    ARRAY['号筒扬声器', 'YH', '扬声器', 'TM'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '整流器',
    ARRAY['可控硅', 'XATD', '整流器'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卡',
    ARRAY['控制卡', '卡'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '溢流阀',
    ARRAY['电磁溢流阀', '溢流阀', 'DBW'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '冲压弯头',
    ARRAY['冲压弯头', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '频敏变阻器',
    ARRAY['BP', '频敏变阻器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电机引线',
    ARRAY['mm', '电机引线', 'MM'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '漆包线',
    ARRAY['漆包线', 'QZY'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '潜水线',
    ARRAY['mm', '接地针', 'YCWB', '米棒', '潜水线', '扁平潜水线', 'JHS', '封地线'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '扁铜线',
    ARRAY['屋顶避雷线', '扁铜线', '镀锡铜排', 'mm', '二次等电位接地线', '静电跨接线'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '塑铜线',
    ARRAY['mm', 'ZR', 'BV', '塑铜线'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '连接线',
    ARRAY['连接线', 'mm'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '接线柱',
    ARRAY['接线柱', '电机接线柱'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '导电嘴',
    ARRAY['流通式电导电极', '导电嘴', '二保焊导电嘴'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '定位器',
    ARRAY['阀门定位器', '定位器'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '加热器',
    ARRAY['加热器', 'KW'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '取样信号板',
    ARRAY['取样信号板', 'KV', 'GGAJ', '信号板', 'SY', '取样小板', '脉冲变压器配套'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '报警器',
    ARRAY['声光报警器', '报警器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '终端',
    ARRAY['终端', '冷缩式户外终端', 'KV'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'C型钢',
    ARRAY['镀锌', 'C型钢', '型钢'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '各种槽钢',
    ARRAY['各种槽钢', '槽钢'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '方管',
    ARRAY['镀锌方管', '方管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '法兰式手动蝶阀',
    ARRAY['PN', 'DN', '法兰式手动蝶阀', '手动法兰蝶阀', '涡轮蜗杆式法兰手动蝶阀'],
    0.8,
    'valve',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '盲板阀',
    ARRAY['盲板阀', 'DN'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '排污阀',
    ARRAY['快速排污阀', 'DN', '排污阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '切断阀',
    ARRAY['DN', '切断阀', '气动切断阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '安全阀',
    ARRAY['弹簧式安全阀', 'DN', '安全阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '调节阀',
    ARRAY['调节阀', 'DN', '电动调节阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '控制阀',
    ARRAY['DN', '控制阀', 'JD'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '旋塞阀',
    ARRAY['旋塞阀', 'DN'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '换向阀',
    ARRAY['EG', 'WE', '换向阀', '电磁换向阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '单向阀',
    ARRAY['液控单向阀', '单向阀'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电磁气动阀',
    ARRAY['DN', '电磁气动阀', '气动阀', '气动电磁换向阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '均压阀',
    ARRAY['JY', 'DN', '均压阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '切换阀',
    ARRAY['温度小于', 'MPa', 'DN', '切换阀', '压力', '通径', '气动快切阀'],
    0.8,
    'valve',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '过滤器',
    ARRAY['过滤器', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压胶管',
    ARRAY['高压胶管', 'DN'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '隔断阀',
    ARRAY['电动敞开式隔断阀', 'DN', '隔断阀', '衬胶隔膜阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '薄膜阀',
    ARRAY['LA', 'PN', 'DN', '气开', '气动薄膜式', '薄膜阀'],
    0.8,
    'valve',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防爆阀',
    ARRAY['防爆阀', '防爆电动调节蝶阀', 'DN', 'PRF', 'mm', '防爆板', 'XB', 'ZAJW', 'MPA'],
    0.8,
    'valve',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '插板阀',
    ARRAY['插板阀', 'DN'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '柱塞阀',
    ARRAY['VS', 'DR', 'VPB', '除磷泵柱塞', '变量柱塞泵', 'IA', '柱塞', '柱塞阀'],
    0.8,
    'valve',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '阻火器',
    ARRAY['PN', 'MPa', '阻火器', 'DN'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '平衡阀',
    ARRAY['PA', '平衡阀', 'DN', 'FD'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '执行器',
    ARRAY['执行器', '电动执行器'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '法兰式电动蝶阀',
    ARRAY['电动蝶阀', 'DN', '法兰式电动蝶阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '脉冲反吹阀',
    ARRAY['脉冲阀', '脉冲反吹阀', 'DMF'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '比例阀',
    ARRAY['比例阀', 'EG'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '放料阀',
    ARRAY['卸料阀', 'DN', '电液动扇形闸门', '数控车刀杠销', 'KW', 'CTMG', '容量', '放油阀', '放料阀', '转速'],
    0.8,
    'valve',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '手动阀',
    ARRAY['DN', 'bar', '角座阀', '内螺纹', '手动阀'],
    0.8,
    'valve',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '水阀',
    ARRAY['水阀', 'PN', 'DN', 'DC', '电磁水阀', 'DF'],
    0.8,
    'valve',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC三通',
    ARRAY['三通', 'PVC', 'DN', 'PVC三通'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '交流电机',
    ARRAY['交流电机', 'KW', '电机'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '直流电机',
    ARRAY['直流电机', 'KW'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '异步电机',
    ARRAY['KW', '异步电机', '三相异步电动机', '电机', 'YE'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '同步电机',
    ARRAY['同步电机', '图号', '效能提升改造', 'YX', 'KW', '电动机', 'TRT', 'MPG', 'KTYZ', '爪极式永磁同步电机'],
    0.8,
    'electrical',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '伺服电机',
    ARRAY['AF', '伺服电机', 'FK', 'DG', 'ZYT'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '等径三通',
    ARRAY['三通', '等径三通', 'DN'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变频电机',
    ARRAY['变频电机', 'KW'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压电机',
    ARRAY['VR', '液压电机', 'MM', 'YT', 'ED', '同步分流马达', '电力液压推动器', 'VTX'],
    0.8,
    'electrical',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '齿轮减速机',
    ARRAY['齿轮减速机', '减速机'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '摆线针轮减速机',
    ARRAY['XWD', 'KW', '摆线针轮减速机'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '涡轮减速机',
    ARRAY['涡轮减速机', 'DC'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '金属软管（氧管）',
    ARRAY['DN', '金属软管', '金属软管（氧管）', '加氟软管', '氧管'],
    0.8,
    'pipe',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '金属软管（水管）',
    ARRAY['DN', '软管总成', '金属软管', '金属软管（水管）'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢金属软管',
    ARRAY['DN', '不锈钢金属软管', '金属软管'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '软紫管',
    ARRAY['软紫管', '节流管', '紫铜筒', '紫铜管'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '斜垫铁',
    ARRAY['金属缠绕垫', '斜垫铁', 'DN', '斜铁'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '其它板',
    ARRAY['GB', 'mm', '波型', 'YX', '其它板', '机制玻璃纤维聚脂', '透明型', '基板厚度', '长度', 'FRP'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '聚四氟乙烯垫',
    ARRAY['mm', '聚四氟乙烯垫', '四氟垫'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '缠绕垫',
    ARRAY['缠绕垫', '金属缠绕垫', 'PN', 'DN'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压垫',
    ARRAY['高压金属垫', '内径', '外径', 'DN', '减温减压器高压垫', '高压垫', '高压密封垫'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '弹性垫',
    ARRAY['弹性垫', '梅花垫'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '石墨垫',
    ARRAY['mm', 'DN', '加强石墨垫', '石墨垫'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '六角胶垫',
    ARRAY['mm', '六角弹性块', '六角垫', '六角胶垫'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢垫',
    ARRAY['不锈钢垫片', 'mm', '金属钢包垫', '钢垫'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '金属垫',
    ARRAY['mm', 'DN', '金属垫'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铜轴瓦',
    ARRAY['铜轴瓦', '铜套'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钨金瓦',
    ARRAY['YSPKK', 'KW', '千瓦', '钨金瓦', '前后', 'TD', '电机轴瓦'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铜箍',
    ARRAY['铜棒', 'mm', '禁锢', '铜箍'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '污水泵',
    ARRAY['污水泵', 'WQ'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '潜水泵',
    ARRAY['潜水泵', 'WQ'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '输油泵',
    ARRAY['输油泵', '油泵'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '灰浆泵',
    ARRAY['灰浆泵', 'LC', 'Cr', '石灰浆液泵', '石灰浆液泵壳'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '柱塞泵',
    ARRAY['VSO', 'DR', '柱塞泵'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '泵零件',
    ARRAY['泵零件', '机械密封'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '提升泵',
    ARRAY['提升泵', 'YWFB'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '试压泵',
    ARRAY['试压泵', '电动试压泵'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '自吸泵',
    ARRAY['WFB', '自吸泵'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '供水泵',
    ARRAY['供水泵', 'KQSN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '深井泵',
    ARRAY['地坑泵', '扬程', 'QJ', 'QJT', '千瓦', '深井泵'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '双吸泵',
    ARRAY['SLOW', '单级双吸泵', '左右旋', 'KQSN', '双吸泵', '带联轴器'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焊接法兰',
    ARRAY['平焊法兰', '焊接法兰', 'PN', 'DN'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '法兰盘',
    ARRAY['DN', 'PN', '法兰盘'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '法兰盖',
    ARRAY['PN', 'DN', '法兰盖'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢法兰',
    ARRAY['不锈钢法兰', 'PN', 'DN'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '凸面法兰',
    ARRAY['RF', 'PN', 'DN', 'GB', '材质', '凸面法兰', 'PL', '凸面板式平焊钢制管法兰'],
    0.8,
    'pipe',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '盲板',
    ARRAY['盲板', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '法兰盲板',
    ARRAY['法兰盲板', 'MPa', 'PN', 'DN'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PPR法兰',
    ARRAY['PN', 'PVC', 'DN', '法兰', 'PPR法兰'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '皮带轮',
    ARRAY['SPB', 'mm', '皮带轮', '风机皮带轮'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '尼龙轮',
    ARRAY['尼龙轮', '尼龙棒'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢丝轮',
    ARRAY['mm', '钢丝轮'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '砂布轮',
    ARRAY['砂布轮', '打磨机专用砂布', '羊毛毡抛光轮', 'mm', '公分', '密度', '砂带'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '平轮',
    ARRAY['CG', 'BLC', '堆焊机送丝轮', '平轮', 'SSL'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '步车轮',
    ARRAY['行走轮', '料车行走轮', '步车轮', 'CA', '料车上行轮'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC出水口',
    ARRAY['PVC', 'PVC出水口', 'mm', '雨水口', '出水口'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PPR三通',
    ARRAY['DN', 'PPR', '三通', 'PPR三通', 'de'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '低压胶管',
    ARRAY['DN', 'mm', 'DKOS', '一端为', '低压胶管', 'SN'],
    0.8,
    'pipe',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压风管',
    ARRAY['镀锌钢板', 'mm', '矩形风管', '高压风管', '异径管'],
    0.8,
    'pipe',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '低压风管',
    ARRAY['镀锌钢板', 'mm', '材质', '矩形风管', '低压风管'],
    0.8,
    'pipe',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢浮球阀',
    ARRAY['不锈钢球阀', 'DN', '不锈钢浮球阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢丝胶管',
    ARRAY['DN', 'MM', 'mm', '钢丝胶管', '高压钢丝编织管'],
    0.8,
    'pipe',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '隔热胶管',
    ARRAY['隔热胶管', '内径', 'DN', '耐高温防火套管', '耐高温软管', 'mm', '铠装陶瓷石棉布高压铠装隔热胶管'],
    0.8,
    'pipe',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '喷煤管',
    ARRAY['高压喷煤软管', '喷煤管', 'DN'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压胶管',
    ARRAY['压力', '钢丝编织液压胶管', 'II', '液压胶管'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '下托辊',
    ARRAY['下托辊', '平下托辊', '下调偏托辊'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '上托辊架',
    ARRAY['上托辊架', '托辊架'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '托辊组',
    ARRAY['皮带辊', '皮带秤托辊组', '三联缓冲托辊组', '托辊组'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'H型钢',
    ARRAY['H型钢', '型钢'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '道轨',
    ARRAY['KG', 'kg', '道轨', 'QU', '钢轨'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '齿辊',
    ARRAY['mm', '齿辊'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '风镐钎',
    ARRAY['风镐钎子', 'mm', '风镐钎', '风镐', '六角柄'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '起动机',
    ARRAY['起动机', 'KW', 'QDJ'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铁料斗',
    ARRAY['斗提机料斗', '铁料斗', 'NE', 'cm'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '管箍',
    ARRAY['管箍', 'DN'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '三通',
    ARRAY['三通', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变径（管）',
    ARRAY['变径（管）', '变径', 'DN'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '二通',
    ARRAY['二通', 'DN', '气源管两通'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电机碳刷',
    ARRAY['电机碳刷', '碳刷'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '刷架压簧',
    ARRAY['压簧', '刷架压簧', 'YZR'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '90°弯头',
    ARRAY['弯头', 'DN', '90°弯头'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '干油分配器',
    ARRAY['分配器', '油气分配器', 'SSPQ', '干油分配器'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '移液管',
    ARRAY['ml', '移液管', '大肚移液管', 'ML'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '异径三通',
    ARRAY['DN', '异径三通'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '直接头',
    ARRAY['DN', '直接头'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '振动筛',
    ARRAY['振动筛', 'XBSFJ'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '给料机',
    ARRAY['振动给料机', '给料机', 'ZG'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卸料车',
    ARRAY['链板机', '卸料车', '拦焦车', '推焦车', '装煤车'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '鼓风机',
    ARRAY['鼓风机', 'min'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '煤气加压机',
    ARRAY['背板密封', 'KV', 'ARMG', '加压机转子轴承盖', 'KW', 'DII', '煤气加压机'],
    0.8,
    'bearing',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '调速离合器',
    ARRAY['调速离合器', '离合器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '起重机',
    ARRAY['LX', 'QD', '起重机'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '破碎机',
    ARRAY['破碎机', 'EP'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '烘烤器',
    ARRAY['烘烤器烧嘴', '烘烤器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压开关柜',
    ARRAY['KYN', '高压开关柜', 'kV'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电容柜',
    ARRAY['电容柜', '低压配电柜', '电容补偿柜', 'PS', '电容出线柜', 'KYN', 'GGD'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '干燥箱',
    ARRAY['鼓风电热恒温干燥箱', 'FT', '电热鼓风干燥箱', '干燥箱'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢坯夹具',
    ARRAY['mm', '钢坯夹具', '夹具'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '制动器',
    ARRAY['YWZ', '制动器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '逆制器',
    ARRAY['逆制器', 'DT', '逆止器', 'SL'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '活接头',
    ARRAY['活接', '活接头', 'DN'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '屋顶风机',
    ARRAY['YDYW', '屋顶风机', 'No', 'YDTW', 'NO'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '皮带机',
    ARRAY['mm', '皮带机', 'JK'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '推动器',
    ARRAY['ED', '电力液压推动器', '推动器'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '直流屏',
    ARRAY['直流屏', 'AH', '触摸屏'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '交流屏',
    ARRAY['嵌入式一体化触摸屏', 'TPC', 'KTP', '西门子触摸屏', '交流屏'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '避雷器',
    ARRAY['避雷器', 'YH', 'KV'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '机床',
    ARRAY['机床', 'MK'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '连接管',
    ARRAY['防爆挠性连接管', '连接管', 'DN'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '操作台',
    ARRAY['实验台', 'QT', '操作台'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '手操器',
    ARRAY['手操器', '智能手操器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气动接头',
    ARRAY['气动接头', 'PC'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动头',
    ARRAY['阀门电动装置', '电动头'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '专用接头',
    ARRAY['DN', '旋转接头', '专用接头'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '管接头',
    ARRAY['管接头', 'DN'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '异径接头',
    ARRAY['同心异径接头', 'DN', 'Sch', '异径接头', 'RC'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC接头',
    ARRAY['PVC', 'PVC接头', 'DN', '接头'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '快接头',
    ARRAY['快接头', '气动快插接头'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '三通接头',
    ARRAY['GB', '材质', 'Cr', '三通接头', 'Ni', '异径三通'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '测温枪头',
    ARRAY['测温枪头', '快速分析仪装置'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '引锭头',
    ARRAY['JDH', 'GBS', '引锭头'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焊接头',
    ARRAY['液压', '锥密封焊接接头带密封圈', '焊接头'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '氧枪喷头',
    ARRAY['氧枪喷头', '出口', '喉口', '扩张角'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢弯头',
    ARRAY['弯头', 'DN', '不锈钢热压弯头', '钢弯头', 'Sch', 'EL'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '热压弯头',
    ARRAY['DN', '热压弯头', 'Sch', 'II', 'EL'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '大小头',
    ARRAY['Sch', '同心大小头', 'DN', '大小头'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '丝头',
    ARRAY['mm', '丝头', '无缝双丝头', 'DN'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卡头',
    ARRAY['钢丝绳卡头', '卡头'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锯条',
    ARRAY['mm', '锯条'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '凝容器',
    ARRAY['PN', 'DN', '凝容器', '分离容器', 'YZF'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '开水器',
    ARRAY['曦雅牌', '热水器', '全自动商用电热开水器', '千瓦开水器', 'KW', 'AK', 'ZK', '熙雅牌全自动电热开水器', '饮用水', '开水器'],
    0.8,
    'electrical',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变速器',
    ARRAY['电量变速器', '变速器'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '料槽',
    ARRAY['料槽', '机头溜槽'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '测压软管',
    ARRAY['HFH', '测压软管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '键坯',
    ARRAY['键坯', '键条'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '搅拌机',
    ARRAY['搅拌机', 'BLD', 'KW'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '对讲系统',
    ARRAY['TBV', '对讲系统', '对讲机'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '调度系统',
    ARRAY['KR', '详见技术协议', '调度系统', '自控系统', '扒渣脱硫系统', '生石灰气力输送系统', 'ME', '调度指挥平台'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '安全栅',
    ARRAY['隔离式安全栅', '格栅板', '安全栅'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '点火炉',
    ARRAY['点火炉烧嘴', 'DH', '点火炉'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '预热炉',
    ARRAY['预热炉', 'Nm', 'XYRQ', '脱硫脱硝加热炉'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '光谱仪',
    ARRAY['光谱仪', '荧光光谱仪', 'QSG', 'XRF', '手持式', '能量色散', '天瑞手持式', '直读光谱仪', 'AES', '射线荧光光谱仪安卓系统成分分析软件'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '凿岩机',
    ARRAY['TFYY', '凿岩机'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '摩擦片',
    ARRAY['YYG', '摩擦片'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电机刷架',
    ARRAY['KW', '电机刷架', 'YZR', '电刷', '刷架'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '碳刷杆',
    ARRAY['碳刷杆', 'KW', 'YZR'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '挡火板',
    ARRAY['侧导板', '挡火板'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '喂丝机',
    ARRAY['喂丝机', 'WX', '四流喂丝机', 'BF', 'DT'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '试验机',
    ARRAY['微机控制电液伺服万能试验机', '试验机', 'WAW'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '粉碎机',
    ARRAY['FW', '镇江丰泰', '粉碎机', 'FTK', '万能粉碎机'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '离心风机',
    ARRAY['离心风机', 'KW'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变频电机风机',
    ARRAY['变频电机风机', '电机散热风机'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '平台',
    ARRAY['WDT', 'DN', '材质', 'LB', '平台', 'DR', '管台', 'MA', 'HGT', 'DSJJGJC'],
    0.8,
    'pipe',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '筛板',
    ARRAY['mm', '筛板'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '滑触片',
    ARRAY['滑触片', 'mm', '取电柱', '高强度高耐磨集电器刷块', 'BPF', 'JGHCUG'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '保护系统',
    ARRAY['mm', '保护系统'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '油雾分离器',
    ARRAY['HR', 'YQJD', '静电式油雾收集器', '油雾器', '油雾分离器'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '搅拌罐',
    ARRAY['源柱铅罐', 'XUNC', 'GD', '搅拌罐', 'XNVSA', 'HN', '助凝投加设备总成', '絮凝投加设备总成'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '振动器',
    ARRAY['仓壁振动器', 'KW', '振动器'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '互感器',
    ARRAY['互感器', '电流互感器', 'VA', 'LZZBJ'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '空气炮',
    ARRAY['空气炮', 'KQP'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '天车称',
    ARRAY['mm', '天车称'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '清洗机',
    ARRAY['清洗机', 'HPW'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变频通风机',
    ARRAY['变频通风机', 'KW'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '45平米带冷机及刮板机设备',
    ARRAY['带冷机', '45平米带冷机及刮板机设备'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电联',
    ARRAY['右箱', '左箱', '联动台', 'QT', 'KQSN', '电联'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '斗式提升机',
    ARRAY['斗式提升机', 'NE'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '单腿吊具',
    ARRAY['单腿吊具', '钢丝绳吊具', '两端吊环'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '各补偿装置',
    ARRAY['PN', 'MPa', 'DN', 'mm', '各补偿装置'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '空气滤筒',
    ARRAY['滤筒', '空气滤筒', '过滤器滤筒', 'FY', 'RFA'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卷筒组',
    ARRAY['电缆卷筒', '钢丝绳卷筒', '卷筒组'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '提升装置',
    ARRAY['提升装置', '轨道提升装置'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '起动装置',
    ARRAY['钢丝绳卷筒', '驱动装置', '需现场核实', '带球铰联轴器', '起动装置', '参图'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '测温装置',
    ARRAY['测温装置', '无线测温装置', 'KNCW'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '送风装置',
    ARRAY['送风装置', 'CT'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '喷咀',
    ARRAY['喷嘴', '喷咀'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '过滤装置',
    ARRAY['mm', '过滤装置'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '挡边皮带',
    ARRAY['高度', 'MM', '裙边皮带', 'NN', '夹袋皮带', '周长', '挡边皮带', 'LCS', '环形挡边皮带'],
    0.8,
    'general',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液体管道',
    ARRAY['液体管道', '玻璃钢管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '转炉炉顶密封装置',
    ARRAY['转炉炉顶密封装置', 'DH', '密封盆', '压盖', 'YCFM', '挡渣环', '过油环', '全金属仿形头部密封装置', '转炉烟道', '密封装置'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '限位装置',
    ARRAY['限位装置', '电动葫芦导杆'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '石英水口',
    ARRAY['石英水口', '中间包水口'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '皮囊',
    ARRAY['皮囊', 'mm', 'NXQ', '蓄能器皮囊'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '热水管',
    ARRAY['PPR', '热水管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '冲击装置',
    ARRAY['HJ', 'FF', '电锤', '冲击装置'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '炮嘴',
    ARRAY['喷嘴', '喷嘴头', '炮嘴', 'DR', 'ME'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '结晶器铜管',
    ARRAY['铜管', '结晶器铜管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '足辊装置',
    ARRAY['足辊装配', '足辊装置', 'JQ', '铸坯规格'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '订扣机',
    ARRAY['气动锁扣机配件', '气动拉紧机配件', '订扣机', 'KZS', 'KZL'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铁瓦',
    ARRAY['铁瓦', '轴瓦', 'KW'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '竖吊',
    ARRAY['竖吊', '竖吊钢板起重钳'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '碳刷架',
    ARRAY['碳刷架', 'YZR'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电液推杆',
    ARRAY['DYTZ', '电液推杆'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '配水盘',
    ARRAY['铸机半径', '二段配水盘', '方坯', '配水盘', '段配水盘', '三段配水盘'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '制动块',
    ARRAY['YWZ', '制动块', '制动瓦', '制动器瓦块'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '尖轨',
    ARRAY['AT', '尖轨'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢标样',
    ARRAY['YSBC', '钢标样'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '传动装置',
    ARRAY['GBS', '传动装置'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '复合弹簧',
    ARRAY['弹簧', '复合弹簧'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锥形套',
    ARRAY['锥形套', '锥套'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '风机转子',
    ARRAY['转子总成', '风机转子'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '造球机刮刀杆',
    ARRAY['米造球机', '铣刀杆', '造球机刮刀杆'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '炉篦条篦子盖板',
    ARRAY['炉篦条篦子盖板', '热镀锌钢格板'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '后台',
    ARRAY['综保后台系统', '综保后台装置', '包含天线', '后台', '多个功能表及智能操控带语音功能六点测温', '建伍', 'KENWOOD', '许继', 'TKR', '对讲机中继台'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '主动轴装配',
    ARRAY['DC', '主动轴装配'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '从动轴装配',
    ARRAY['WAM', '从动轴装配', 'DC'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '限制器',
    ARRAY['限制器', 'QCX', '起重量限制器'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '报闸皮',
    ARRAY['报闸皮', '闸皮'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '刹车皮',
    ARRAY['铁通机车小刹车盘', '吨后', '后刹车盆', '刹车皮', '刹车鼓', '曼桥', 'NY', 'ZQMQ'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '氟板',
    ARRAY['mm', '氟板', '氟胶板', '四氟板'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '硅胶板',
    ARRAY['mm', '硅胶板'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '岩棉板',
    ARRAY['mm', '乳白色双面平面岩棉', '墙板', 'mmx', '岩棉板'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '方斜垫',
    ARRAY['方斜垫', '斜垫板'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '样板',
    ARRAY['mm', '电机铭牌', '样板', 'UV', 'DR', '厚铝板', 'ME'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '蓖板',
    ARRAY['mm', '热镀锌钢格板', '蓖板', '压滤机配板', '钢格板'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '脱锭辊装配',
    ARRAY['脱锭装置', 'mm', '辊子装配', '结合现场', 'DR', '脱锭辊装配', 'ME'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动蜗轮头',
    ARRAY['DN', '电动装置', 'QDX', '电动涡轮头', '电动蜗轮头'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '轴套（含车轮、内环、外环、端盖、连轴器、定位杆）',
    ARRAY['轴套', '轴套（含车轮、内环、外环、端盖、连轴器、定位杆）'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '销轴（配母）',
    ARRAY['销轴（配母）', '销轴'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '孔板',
    ARRAY['内径', '外径', '孔板', '标准孔板', '小孔板'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变径',
    ARRAY['变径', 'DN', '同心变径'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变径弯头',
    ARRAY['变径弯头', '变径', 'DN'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢弯头',
    ARRAY['Sch', '不锈钢弯头', 'GB', 'DN'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC弯头',
    ARRAY['弯头', 'PVC', 'PVC弯头', 'DN'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PPR弯头',
    ARRAY['弯头', 'PPR弯头', 'DN', 'PPR'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '45°弯头',
    ARRAY['弯头', 'DN', '45°弯头'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变径管',
    ARRAY['DN', '变径管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '丝扣弯头',
    ARRAY['丝扣弯头', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '镀锌弯头',
    ARRAY['GB', 'DN', '镀锌', 'Zn', '镀锌弯头', '等径弯头'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焊接弯头',
    ARRAY['焊接弯头', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '30°弯头',
    ARRAY['弯头', '30°弯头', 'DN'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '60°弯头',
    ARRAY['弯头', '60°弯头'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '异径弯头',
    ARRAY['DN', '渐缩异径弯头', '异径弯头'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焊接三通',
    ARRAY['焊接三通', '材质', '焊接式三通', 'DN'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '冲压三通',
    ARRAY['冲压三通', '材质', 'DN', '冲压等径三通'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈刚三通',
    ARRAY['DN', '不锈钢异径三通', 'Sch', '不锈刚三通', '不锈钢三通', '不锈钢等径三通'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '45°三通',
    ARRAY['三通', '45°三通'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '热压等径三通',
    ARRAY['GB', 'DN', '镀锌等径三通', 'Sch', '热压等径三通'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '热压异径三通',
    ARRAY['镀锌变径三通', 'crMOVG', 'DN', 'MPa', '热压异径三通', '材质', '内丝', '热压三通'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '无缝三通',
    ARRAY['DN', '无缝三通', '无缝异径三通', 'Sch', '钢制无缝三通'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变径三通',
    ARRAY['GB', 'DN', '变径三通', '材质', 'TR', 'Sch', '异径三通'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '异形三通',
    ARRAY['不锈钢外内内丝扣三通', '异形三通', '材质', '不锈钢', '外螺纹弯通', 'PL', '异径沟槽三通'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PRR三通',
    ARRAY['DN', 'PRR三通', 'PPR', 'DE', '内牙三通', '给水三通'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '四通',
    ARRAY['四通', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC四通',
    ARRAY['PVC', 'PVC四通', '四通', '立体四通', 'DE', '角四通'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢大小头',
    ARRAY['不锈钢同心大小头', 'DN', '不锈钢大小头', '不锈钢变径'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '偏心大小头',
    ARRAY['偏心变径', 'DN', 'RE', 'Sch', '偏心大小头', 'II'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '金属软管接头',
    ARRAY['软管接头', '金属软管接头', 'DN'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '弯接头',
    ARRAY['内接头', 'DN', '弯接头', '型接头'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '盒接头',
    ARRAY['盒接头', '不锈钢接水盒'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变径接头',
    ARRAY['变径接头', 'GB', 'DN', '材质'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '短接',
    ARRAY['mm', 'cm', 'DN', '短接'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '龙头',
    ARRAY['水龙头', '龙头'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC管箍',
    ARRAY['管箍', 'PVC管箍', 'PVC', 'DN'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PRR管箍',
    ARRAY['PRR管箍', 'DN', '变径管箍', '管箍', 'PPR', 'DE'],
    0.8,
    'pipe',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '进口轴承',
    ARRAY['进口轴承', '轴承'],
    0.8,
    'bearing',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PPR管',
    ARRAY['PPR', 'PPR管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '下水软管',
    ARRAY['下水软管', '软管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '矿石标样',
    ARRAY['矿石标样', 'YSBC', 'GBW', 'ZBK'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '长外丝',
    ARRAY['DN', 'mm', '单头外丝', '双头外丝', '长外丝'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '内丝',
    ARRAY['DN', '内丝'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焊接外丝',
    ARRAY['DN', '单外丝', '焊接外丝', '单头外丝'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '双丝',
    ARRAY['双丝', 'DN', '双头外丝'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '双头丝',
    ARRAY['双头丝', 'DN', '双头扣', 'mm', 'ZG', '直通', '传动轴螺栓'],
    0.8,
    'fastener',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC直接',
    ARRAY['PVC直接', 'PVC', 'DN', '直接'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PPR直接',
    ARRAY['DN', 'PPR', '直接', 'PPR直接'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铁直接',
    ARRAY['PVC', 'DN', '铁直接', 'JDG', '材质', 'DE', '直接'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '外牙直接',
    ARRAY['De', 'PPR', '外牙直接', 'DE', 'PVDF', '直接'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '内牙直接',
    ARRAY['DE', 'DN', 'PPR', '内牙直接'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '内直',
    ARRAY['内直', '铜直接', 'PPR'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '罗接',
    ARRAY['PVC', '加长罗接', 'JDG', '加长内丝罗接', '罗接'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '油任',
    ARRAY['油任', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '外牙油任',
    ARRAY['DN', '材质', 'PPR', '外牙由任', 'DE', '外牙油任'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '补芯',
    ARRAY['补芯', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '疏水器',
    ARRAY['疏水器', 'CS', 'DN'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC存水弯',
    ARRAY['PVC', '存水弯', 'PVC存水弯', 'De', 'DE', '型存水弯'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '存水弯',
    ARRAY['De', 'PVC', '存水弯', '型存水弯'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '角弯',
    ARRAY['内弯', '大弧弯', 'JDG', 'mm', '材质', '角弯', 'De', 'PPR', '转角包件', '厚度'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢制散热器',
    ARRAY['mm', '钢制散热器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC三检',
    ARRAY['PVC三检', 'dn', 'DN', 'PVC', '补心', '检查口', '清扫口'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC变径',
    ARRAY['PVC变径', '变径', 'PVC', 'DN'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '丝扣变径',
    ARRAY['丝扣变径', 'DN', '不锈钢外丝变径'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焊接变径',
    ARRAY['GB', 'DN', '材质', '同心异径管', 'Sch', '焊接变径', 'RC'],
    0.8,
    'pipe',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '冲压变径',
    ARRAY['GB', '材质', '冲压变径', '同心变径', 'RC'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢变径',
    ARRAY['DN', '材质', 'Sch', '不锈钢变径', '同心变径'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PPR变径',
    ARRAY['变径', 'DN', 'PPR变径', 'PPR', 'de'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC清扫口',
    ARRAY['PVC', 'DN', 'De', '清扫口', 'DE', 'PVC清扫口'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '管簧',
    ARRAY['弯簧', '管簧'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '吸水喇叭口',
    ARRAY['吸水喇叭口', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '直通',
    ARRAY['UPVC', 'PN', 'DN', '材质', '变径直通', '直通'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '检查口',
    ARRAY['检查口', 'PVC', 'DE', '立检'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '水斗',
    ARRAY['水斗', 'PVC', 'DN', '雨水斗'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '执行机构',
    ARRAY['电动执行机构', '执行机构'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '密封',
    ARRAY['机械密封', '密封'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压球阀',
    ARRAY['高压球阀', 'KHB'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '疏水阀',
    ARRAY['CS', 'PN', 'DN', '疏水阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '送风阀',
    ARRAY['电动送风阀', 'DN', '关闭', 'SFVD', '方形防火阀', '送风阀', '功能控制', '圆形防火阀'],
    0.8,
    'valve',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '快切阀',
    ARRAY['KD', '气动快切阀', '快切阀', 'DN'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '泄爆阀',
    ARRAY['煤气泄爆阀', '孔中心距', 'DN', 'MM', '铝制', '防爆泄爆板', '泄爆阀', '孔直径', 'XB', '直径'],
    0.8,
    'valve',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '眼镜阀',
    ARRAY['防爆电动眼镜阀', '电动敞开式插板阀', 'PN', 'DN', '转炉煤气', '介质', '眼镜阀', '电动防爆眼镜阀'],
    0.8,
    'valve',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '放气阀',
    ARRAY['放气阀', '自动放气阀', 'DN'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '底阀',
    ARRAY['PVC', 'DN', 'mm', '软管', '底阀', '不锈钢底阀', '计量泵过滤底阀'],
    0.8,
    'valve',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钟阀',
    ARRAY['气动煤粉偏置钟阀', 'DN', 'QPZQ', 'PZQZ', '气动偏置式钟阀', '钟阀', 'MPA'],
    0.8,
    'valve',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '废气阀',
    ARRAY['立式废气阀', '废气阀', 'DN', 'QZ'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '排气阀',
    ARRAY['排气阀', 'DN'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '弹子阀',
    ARRAY['滑到弹子阀', 'DN', '不锈钢保温夹套球阀', '弹子阀', 'BQ', '滑道弹子阀', '卡阀'],
    0.8,
    'valve',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '快排阀',
    ARRAY['快排阀', 'DN'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '袋类',
    ARRAY['mm', '袋类', 'cm', '吨包袋'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '窥视镜',
    ARRAY['油位镜', '窥视镜'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '垫类',
    ARRAY['mm', '垫类', '组合垫'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢板',
    ARRAY['不锈钢板', 'mm'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '蓝',
    ARRAY['蓝', '工作服'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '黄',
    ARRAY['安全帽内衬', '保安棉帽', '安全帽', '黄'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电焊手套',
    ARRAY['长焊工手套', '短焊工手套', '电焊手套'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '绝缘手套',
    ARRAY['绝缘手套', '高压绝缘手套', 'KV'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '布手套',
    ARRAY['帆布手套', '布手套', '加厚帆布手套'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '线手套',
    ARRAY['线手套', '线胶手套'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '大头鞋',
    ARRAY['劳保鞋', '大头鞋'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '绝缘鞋',
    ARRAY['绝缘靴', '绝缘鞋', '高压绝缘靴', 'KV'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '雨鞋',
    ARRAY['高筒', '雨靴', '雨鞋', '拖鞋', '飞鹤雨鞋'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '劳保鞋',
    ARRAY['劳保鞋', 'KV'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '烧杯',
    ARRAY['ml', '烧杯'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '量杯',
    ARRAY['ml', '量杯'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '杯',
    ARRAY['mm', '杯'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '比色管',
    ARRAY['ml', '具塞比色管', '比色管'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '直吸管',
    ARRAY['ml', '直吸管', '塑料吸管', '一次性塑料吸管', 'DN', '材质', '吸量管', '橡胶', '橡胶波纹吸尘管'],
    0.8,
    'pipe',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '刻度吸管',
    ARRAY['ml', '刻度吸管', '色标分度吸液管', '天波'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '滴定管',
    ARRAY['ml', '碱式滴定管', 'ML', '酸式滴定管', '滴定管'],
    0.8,
    'pipe',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '玻璃管',
    ARRAY['试管', 'mm', '玻璃管'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '瓷管',
    ARRAY['XA', 'mm', '套管', '高压瓷瓶', '陶瓷管', '陶瓷填料', '瓷管'],
    0.8,
    'pipe',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '下水管',
    ARRAY['mm', '下水管', 'DN', '下水'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '封头管',
    ARRAY['椭圆封头', '管道封头', '封头管', 'DN'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '容量瓶',
    ARRAY['ml', '容量瓶'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '三角瓶',
    ARRAY['ml', '三角瓶'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '氧气瓶',
    ARRAY['BDP', '氩气罐', '便携式丁烷气瓶', '氧气瓶', '氧气瓶阀组'],
    0.8,
    'valve',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '细口瓶',
    ARRAY['ml', 'ML', '棕细口瓶', '细口瓶'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '广口瓶',
    ARRAY['ml', 'ML', '广口瓶'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '白滴瓶',
    ARRAY['ml', '白滴瓶', '棕滴瓶', '滴瓶', 'ML'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '下口瓶',
    ARRAY['下口瓶', '白色', 'ml', '棕色下口瓶'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '称量瓶',
    ARRAY['mm', '称量瓶'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '洗瓶',
    ARRAY['ml', '洗瓶', '孟氏洗瓶', '多功能泡沫清洗剂', 'ML', '塑料洗瓶'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '塑料瓶',
    ARRAY['塑料瓶', 'ML', 'ml'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '玻璃瓶',
    ARRAY['ml', '玻璃瓶', '采样瓶'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锥形瓶',
    ARRAY['ml', 'mm', 'ML', '锥形瓶', '磨口锥形瓶'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '量筒',
    ARRAY['ml', '量筒'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '表面皿',
    ARRAY['mm', '瓷舟', '表面皿'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '比色皿',
    ARRAY['浊度仪比色皿', 'TW', 'cm', '比色皿'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '灰皿',
    ARRAY['灰皿', '称量瓶', '方舟', '直径'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '滤纸',
    ARRAY['滤纸', '定量滤纸', 'mm', '定性滤纸', 'cm'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '乳化液滤纸',
    ARRAY['mm', '乳化液滤纸', '宽度', '长度'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '试纸',
    ARRAY['PH', '试纸'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '坩埚',
    ARRAY['ml', '坩埚'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铂金埚',
    ARRAY['铂金埚', '铂金皿添料'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '素埚',
    ARRAY['ml', '素埚', '素坩埚', 'ML'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '碳硫埚',
    ARRAY['低碳硫', '碳硫坩埚', '红外碳硫坩埚', '碳硫埚'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '水浴锅',
    ARRAY['水浴锅', 'DZKW', '电热恒温水浴锅', '数显恒温水浴锅', 'HH'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '酸类',
    ARRAY['ml', '酸类'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '氨类',
    ARRAY['氨类', '氨水'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PAM',
    ARRAY['浊环', '阴离子', '分子量', 'PAM', '万以上'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '生铁标样',
    ARRAY['生铁标样', 'YSBC'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锰铁标样',
    ARRAY['硅锰合金标样', 'YSBC', 'GSB', 'ZBT', '锰铁标样'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '硅类标样',
    ARRAY['硅类标样', 'YSBC', 'ZBT', '硅铁标样'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '石灰石标样',
    ARRAY['YSBC', '石灰石', 'ZBK', '石灰石标样'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焦炭标样',
    ARRAY['ZBM', '焦炭标样', '焦炭'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '炉渣标样',
    ARRAY['保护渣标样', '炉渣标样', '高炉渣标样', '转炉渣', 'YSBC'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '莹石标样',
    ARRAY['萤石', '莹石标样', 'YSBC', 'ZBK'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '镁石标样',
    ARRAY['GBW', '镁石标样', '水镁石', 'GSB', '镁砂标样'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '白云石标样',
    ARRAY['QD', 'GBW', '白云石', '标样', 'YSBC', '白云石标样'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '烧结矿标样',
    ARRAY['烧结矿标样', '烧结矿', 'ZBK', 'YSBC'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铁精矿标样',
    ARRAY['QD', 'GBW', 'ZBK', '铁矿石', '磁铁精矿', 'YSBC', '铁精矿', '铁精矿标样'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '粘土标样',
    ARRAY['GBW', '粘土', '膨润土', 'YSBC', '覆盖剂', '粘土标样'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '球团矿标样',
    ARRAY['GBW', '球团矿', 'ZBK', 'CRC', 'YSBC', '球团矿标样'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '赤铁矿标样',
    ARRAY['赤铁矿标样', 'GBW', '磁铁矿', 'ZBK', '赤铁矿'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '光普标样',
    ARRAY['光谱控样', '光谱标样', 'YSBS', '光普标样'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '镍铁标样',
    ARRAY['高铬镍铁矿石', 'GBW', 'YSBC', '高碳铬铁', '标准样品', '镍铁标样'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高炉渣标样',
    ARRAY['GBW', '高炉渣标样', '转炉渣', 'YSBC', '标准样品', '高炉渣'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '化验架',
    ARRAY['mm', '化验架'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钳',
    ARRAY['液压压线钳', 'YQK', '钳'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '漏斗',
    ARRAY['mm', '漏斗'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '胶皮塞',
    ARRAY['胶皮塞', '胶塞', '橡胶塞'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电炉盘',
    ARRAY['电炉子', '单联电炉', 'KW', '电炉子炉盘', '电炉盘'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '托盘',
    ARRAY['mm', '不锈钢托盘', '托盘'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铁盘',
    ARRAY['铁盘', '白铁盘', 'cm', 'mm'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '加液器',
    ARRAY['DN', '微量注射器', 'ul', '齿轮油加注器', '加液器', '管式静态混合器'],
    0.8,
    'pipe',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '干燥器',
    ARRAY['mm', '干燥器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '热电阻传感器',
    ARRAY['埋入式热电阻', '隔爆型铂热电阻', 'mm', '热电阻传感器', 'WZP', 'PT', 'AM', 'MFC', 'SH'],
    0.8,
    'electrical',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电涡流传感器',
    ARRAY['涡流传感器', '电涡流传感器'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '压力传感器',
    ARRAY['压力传感器', '压力变送器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '压力表',
    ARRAY['YN', '压力表', 'MPa', 'MPA'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '万用表',
    ARRAY['UT', '万用表'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '氧气表',
    ARRAY['氧气表', 'YQY'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '乙炔表',
    ARRAY['乙炔表', 'YQE'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '兆欧表',
    ARRAY['兆欧表', 'ZC', '摇表'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '水表',
    ARRAY['DN', 'LXS', '水表'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卡表',
    ARRAY['UT', '卡表', '钳形表', '钳型卡表'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钳形表',
    ARRAY['UT', '钳形表'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '百分表',
    ARRAY['mm', '内径百分表', '百分表'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '减压表',
    ARRAY['氮气减压阀', '氢气减压表', 'Mpa', '减压器', '一氧化碳减压表', 'YQN', 'YC', '氮气减压表', '减压表', 'YQD'],
    0.8,
    'valve',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '功率表',
    ARRAY['PZ', '功率表'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '表弯',
    ARRAY['不锈钢压力表弯', '表弯'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '温度计',
    ARRAY['双金属温度计', 'WSS', '温度计'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '流量计',
    ARRAY['DN', '电磁流量计', '流量计', 'PTB'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液位计',
    ARRAY['磁翻板液位计', '液位计'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '酸度计',
    ARRAY['PH', 'PHS', '酸度计', 'ph', '台式精密酸度计'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '物位计',
    ARRAY['物位计', '雷达料位计'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电位差计',
    ARRAY['电位差计', '电位计', 'SLS', '电子式', 'XJ', '秒表'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '表座类',
    ARRAY['磁力表座', 'CZ', '表座类', '百分表万向型磁力表座'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'O型圈',
    ARRAY['型圈', 'O型圈'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '测电器',
    ARRAY['AH', 'WT', 'GCA', '测电器', '测电笔', '激光测距', 'SP', '电瓶充电器', '充电机'],
    0.8,
    'electrical',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '露点仪',
    ARRAY['PC', 'FT', '露点测试设备', '智能露点仪', 'DP', '露点仪', 'EN', 'CI'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '报警仪',
    ARRAY['报警仪', 'SNG', 'BW'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '操作器',
    ARRAY['手操器', '操作器', '智能手操器'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '示波器',
    ARRAY['示波器', 'UTD'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '色谱仪',
    ARRAY['mm', '色谱仪', '气相色谱柱', 'GC', '气相色谱仪', '色谱分析仪'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '减压器',
    ARRAY['氧气减压器', '减压器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '工业电视系统',
    ARRAY['DS', '工业电视系统'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '保护仪',
    ARRAY['SDJ', '保护仪'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '交换器',
    ARRAY['交换机', '交换器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '表头',
    ARRAY['温度巡检仪', 'WT', 'DO', 'ATMR', '表头', '超声波流量计主机', '电磁流量计主机', 'LU', '智能仪表', 'ATMLDG'],
    0.8,
    'electrical',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '扫描器',
    ARRAY['HMD', 'SM', 'DC', '扫描器', '扫描式热检', 'MH'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '粉尘仪',
    ARRAY['粉尘仪', 'PMM'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '其它管',
    ARRAY['DN', '其它管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锰板',
    ARRAY['mm', '锰板'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铜板',
    ARRAY['DR', '镀锡铜排', '铜板', 'ME'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '彩钢活动板房',
    ARRAY['彩钢活动板房', 'GB', 'mm', '集装箱', '波型', 'YX', '基板厚度', '长度', '采光板', 'FRP'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '普板',
    ARRAY['普板', '开平普板'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '各种扁铁',
    ARRAY['各种扁铁', 'mm', '扁铁', '铁棒', '镀锌扁铁'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '压板',
    ARRAY['压板', '轨道压板'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '鱼尾板',
    ARRAY['kg', 'QU', '鱼尾板'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '垫板',
    ARRAY['垫板', 'mm'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '各种圆钢',
    ARRAY['圆钢', '各种圆钢', 'mmx', '镀锌圆钢'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢轨',
    ARRAY['图号', 'TFC', '钢轨', 'QU', '轨道', '垂直固定轨道'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '角铁',
    ARRAY['镀锌角铁', '角铁'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '柴油',
    ARRAY['柴机油', '柴油', 'CH'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压油',
    ARRAY['HM', '抗磨液压油', 'KG', 'kg', '昆仑', '液压油'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '传动油',
    ARRAY['长城', '传动油', 'KG', 'kg', '号液力传动油'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变压器油',
    ARRAY['变压器油', '长城', 'KG', 'kg', '通用'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '煤油',
    ARRAY['KG', 'kg', '电火花机床工作液', '闪点大于', '煤油'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '黄油',
    ARRAY['冷冻油', '机组', '耐高温黄油', 'KG', '黄油', 'HXC', 'kg', '螺杆机专用冷冻油', '昆仑极压锂基润滑脂'],
    0.8,
    'general',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '洗油',
    ARRAY['清洗剂', '煤焦油清洗剂', '前馏出量', '飞圣达轴承清洗油', 'FW', 'kg', '水分', '洗油', 'SM', 'LP'],
    0.8,
    'bearing',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锂基脂',
    ARRAY['KG', 'kg', '昆仑', '极压锂基脂', '锂基脂'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钙基脂',
    ARRAY['复合磺酸钙基脂', 'KG', 'kg', '钙基脂', '昆仑'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '润滑脂',
    ARRAY['润滑脂', 'kg', 'KG'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '复合锂',
    ARRAY['长城', 'KG', '轧辊脂', '昆仑', '复合锂'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '涂料（生产用）',
    ARRAY['聚酯面漆', '涂料（生产用）', 'DG', '面漆'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防锈漆',
    ARRAY['油漆', 'kg', '防锈漆'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '清漆',
    ARRAY['环氧煤沥青漆', '清漆'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '磁漆',
    ARRAY['大红聚氨酯磁漆', '磁漆', '分装'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '中间漆',
    ARRAY['中灰油漆', '中间漆', '环氧云铁中间漆'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '专用稀料',
    ARRAY['kg', '环氧树脂稀释剂', '专用稀料'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '醇酸稀料',
    ARRAY['醇酸稀释剂', '醇酸漆稀释剂', '醇酸稀料'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '缓蚀剂',
    ARRAY['kg', '缓蚀剂'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '非氧化杀菌剂',
    ARRAY['非氧化杀菌剂', '非氧化性杀菌剂', 'DG'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '聚助凝剂',
    ARRAY['硫磺', '倍浓缩液', '聚凝助剂', '植物型除臭剂', '阴离子型分子量', 'NPE', '聚助凝剂', 'II', '阳离子型离子度'],
    0.8,
    'general',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '二硫化钼',
    ARRAY['二硫化钼', '昆仑', 'KG'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '平整液',
    ARRAY['PTA', 'DH', 'DG', 'BONDERITE', '平整液', '非离子聚丙烯酰胺', 'Kg', 'LF'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钝化液',
    ARRAY['DH', 'SSG', 'PD', '钝化液', 'RC'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锌锭',
    ARRAY['锌锭', 'Kg', '含铝', 'ZAM', '含锑'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '光整液',
    ARRAY['光整液', 'DG', 'BONDERITE', 'TF', 'LF'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '盐酸',
    ARRAY['盐酸', '含量'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防锈油',
    ARRAY['kg', '防锈油', 'KG'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '氧化性杀菌剂',
    ARRAY['杀菌灭藻剂', '净环', '氧化性杀菌剂'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '轧制油',
    ARRAY['CTR', '轧制油', 'DH', 'kg', 'DG', 'Kg', 'QUAKEROL', 'HCR'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '稀料（生产用）',
    ARRAY['THINNER', '稀料（生产用）', '稀释剂', 'FVDF', 'Kg'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '石棉板',
    ARRAY['石棉板', 'mm'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '石棉绳',
    ARRAY['mm', '石棉绳'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '石棉布',
    ARRAY['mm', '石棉布'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铜焊条',
    ARRAY['磷铜焊条', '焊条', '铜焊条'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢焊条',
    ARRAY['不锈钢焊条', 'THA'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '普通焊条',
    ARRAY['普通焊条', '焊条'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焊锡膏',
    ARRAY['mL', '蓝瓶', '焊锡膏', '低温', '助焊膏', 'NC', '无铅锡膏', 'ASM', '浸焊助焊剂'],
    0.8,
    'general',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焊锡',
    ARRAY['锡浆', 'MM', 'mm', '焊锡', '钢轨铝热焊剂', 'QU', 'XGSP'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焊锡条',
    ARRAY['焊锡条', '焊锡丝'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '方向轮',
    ARRAY['力驰洁', '方向轮', '洗地车专用', '吸水耙万向轮', '刮板输送机导向轮', '现场测量', '改向轮'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气类',
    ARRAY['Mpa', '标准气体', '气类', '浓度', 'mg'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '绝缘板',
    ARRAY['图号', 'mm', '环氧树脂板', '绝缘板'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高胶胶板',
    ARRAY['米中板', '米边板', '胶木板', 'mm', '橡胶道口板', '聚氨酯板', '高胶胶板', '平板', 'lll', '型砼枕'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '绝缘胶皮',
    ARRAY['绝缘胶垫', 'MM', 'DMD', 'mm', '绝缘胶皮', '绝缘纸'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '胶带',
    ARRAY['mm', '胶带'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '生料带',
    ARRAY['mm', '生料带'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防水胶布',
    ARRAY['mm', '防水胶布'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压胶布',
    ARRAY['高压自粘胶带', '高压胶布', 'MM', '高压防水胶布', '乙丙自粘带'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '水泥',
    ARRAY['通风道', '水泥', '水泥预制', '规格', '混凝土'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '岩棉',
    ARRAY['岩棉', '玻璃棉卷毡', 'mm', '顶板', '蓝色岩棉', '厚度', '每卷宽'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '岩棉管',
    ARRAY['mm', '橡塑保温管', 'DN', '岩棉管'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '鹅卵石',
    ARRAY['mm', '鹅卵石'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '大理石',
    ARRAY['mm', '大理石'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '地板砖',
    ARRAY['mm', '地板砖'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '珠光砂',
    ARRAY['烟道喷涂', 'TP', '珠光砂', 'mm', 'kg', '水玻璃砂', '厚度'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '美纹纸',
    ARRAY['mm', '美纹纸', '宽度'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '装修材料',
    ARRAY['mm', '装修材料'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '尼龙棒',
    ARRAY['mm', '尼龙棒'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '绳类',
    ARRAY['mm', '绳类'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '笔类',
    ARRAY['mm', '笔类', '石笔'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '木板',
    ARRAY['木方', 'mm', '木板'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '盖板',
    ARRAY['mm', '盖板'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '复合板',
    ARRAY['制度牌', 'mm', '复合板', '基板厚度', '型复合板'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '橡胶板',
    ARRAY['mm', '橡胶板'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卷板',
    ARRAY['mm', '热轧卷板', '卷板', '彩涂卷板'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '保温板',
    ARRAY['保温板', 'mm'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '工业盐',
    ARRAY['磷盐', 'KG', 'HPO', '镁含量', 'MGCL', '镁盐', '纯度', '工业盐', 'NA'],
    0.8,
    'general',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '石墨盘根',
    ARRAY['石墨盘根', '高压石墨盘根'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '盘根',
    ARRAY['碳素纤维盘根', '盘根'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '牛油盘根',
    ARRAY['mm', '牛油盘根'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '拉条',
    ARRAY['镀锌拉条', '拉条', '镀锌斜拉条', '见附图'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '胶条',
    ARRAY['mm', '胶条'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '塑料垫块',
    ARRAY['mm', '塑料垫块'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压石棉垫',
    ARRAY['高压石棉橡胶板', '高压石棉垫', '毫米'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '隔热垫',
    ARRAY['泡沫垫', '隔热垫'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '聚脂垫',
    ARRAY['mm', '尼龙垫圈', '聚脂垫', 'MM'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气源管',
    ARRAY['mm', '气源管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '异型管',
    ARRAY['偏心', 'DN', '异型管', '长度'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '氧气带',
    ARRAY['氧气带', '乙炔带', '医用氧气'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '过滤网',
    ARRAY['过滤网', 'mm'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢丝网',
    ARRAY['mm', '钢丝网'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '槽楔',
    ARRAY['环氧树脂槽楔', '槽楔'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '竹签（肖）',
    ARRAY['竹签', '竹签（肖）'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '裁纸刀片',
    ARRAY['片装', '壁纸刀', '刀片', 'mm', '裁纸刀片', '美工刀片'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '一字螺丝刀',
    ARRAY['一字螺丝刀', '胶柄一字改锥'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '十字螺丝刀',
    ARRAY['十字螺丝刀', '胶柄十字改锥'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '开口扳手',
    ARRAY['敲击开口扳手', '开口扳手'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '套筒扳子',
    ARRAY['mm', '套筒扳子'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '丁字扳手',
    ARRAY['型套筒扳手', 'mm', '型扳手', '扳手', '铍青铜', '丁字扳手'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '板牙扳手',
    ARRAY['板牙', '板牙扳手'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '棘轮扳手',
    ARRAY['棘轮扳手', '尖尾棘轮扳手', 'MM'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '斜咀钳',
    ARRAY['斜咀钳', '斜嘴钳', '偏口钳'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '尖嘴钳',
    ARRAY['防爆尖嘴钳', 'mm', '尖嘴钳', '绝缘尖嘴钳'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '管钳',
    ARRAY['管钳子', '管钳'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '台虎钳',
    ARRAY['台虎钳', '台钳'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '断线钳',
    ARRAY['断线钳头', '断线钳'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '内卡钳',
    ARRAY['卡簧钳', '内卡钳', '内卡簧钳'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '外卡钳',
    ARRAY['卡簧钳', '外卡钳'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '压力钳',
    ARRAY['大力钳', '压力钳'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢丝钳',
    ARRAY['防爆钢丝钳', '卡簧钳', '钢丝钳', '内卡簧'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '偏口钳',
    ARRAY['斜口钳', '偏口钳', '克丝钳'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压钳',
    ARRAY['mm', '液压钳'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '克丝钳',
    ARRAY['寸外直', '寸外弯', '寸内弯', '挡圈钳', '克丝钳', '寸内直'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电脑网线钳',
    ARRAY['网线钳', '电脑网线钳'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '吊钳',
    ARRAY['油桶钳', '吊钳', '钢板钳', '横吊', '竖吊'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '平口钳',
    ARRAY['镊子', 'mm', '塑料', '机用平口钳', '平口钳'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '链条钳',
    ARRAY['YD', '链条钳', '刮板机链条'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '丝锥',
    ARRAY['机用丝锥', '手用丝锥', '丝锥'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '板牙架',
    ARRAY['套丝机板牙架', '板牙架', '板牙架组套'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电工刀',
    ARRAY['AA', 'GK', 'DP', '大号', '电工刀', '钢盾彩木不锈钢折叠刀', '迷你型'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '裁纸刀',
    ARRAY['mm', '美工刀', '裁纸刀'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '刮刀',
    ARRAY['mm', '刮刀'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锉刀',
    ARRAY['mm', '锉刀'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '割刀',
    ARRAY['mm', '割刀', '管子割刀'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '绞刀',
    ARRAY['合金', '绞刀'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '砂轮刀',
    ARRAY['PH', 'ATLANTIC', '油石', 'NK', '石墨砂轮样板刀', '砂轮刀'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铣刀',
    ARRAY['mm', '铣刀'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '内槽刀',
    ARRAY['内槽刀', '锥柄键槽铣刀', '键槽铣刀'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '孔型刀',
    ARRAY['mm', '镗刀', '孔型剪刃上刀片', '孔型刀'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '剪刃刀',
    ARRAY['TSDHCJH', '剪刃刀'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钜片',
    ARRAY['mm', '金刚石锯片', '钜片', '切割锯片'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '角磨片',
    ARRAY['mm', '角磨片'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '砂轮片',
    ARRAY['mm', '砂轮片'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '合金刀片',
    ARRAY['合金刀片', '数控机夹刀片', 'WNMG'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '白钢刀片',
    ARRAY['白钢刀片', '钢盾重型美工刀刀片', '刀片', 'DH', 'DP', '北京中远通', '毛刺机刀片', 'ZYT'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢筋切断机刀片',
    ARRAY['mm', '钢筋切断机刀片', '刀片'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '刀头',
    ARRAY['数控刀头', '刀头'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '割枪',
    ARRAY['割枪', '重型割枪', 'PWZ'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '割把',
    ARRAY['等离子割把', '割把'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '尺',
    ARRAY['mm', '尺'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '称',
    ARRAY['电子秤', '称', 'KG'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动葫芦',
    ARRAY['电动葫芦', 'CD'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '油压千斤顶',
    ARRAY['电动千斤顶', '分体式千斤顶', 'mm', '千斤顶', '油压千斤顶'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钻类',
    ARRAY['钻类', '手电钻'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锤类',
    ARRAY['锤类', '大锤'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钻头',
    ARRAY['mm', '钻头'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '镐类',
    ARRAY['镐类', '电镐', '风镐钎子'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '皮五联',
    ARRAY['电工腰带', 'cm', '皮五联'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢锯弓',
    ARRAY['钢锯弓', 'cm'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '单气喷枪',
    ARRAY['mm', 'SS', '单气喷枪', 'BP'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '打胶枪',
    ARRAY['打胶枪', '胶枪'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '喷漆枪',
    ARRAY['喷漆枪', '喷涂机喷枪'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '喷火枪',
    ARRAY['喷火枪', '汽油', '喷灯'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '加油枪',
    ARRAY['加油枪', 'HCG'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '干油泵油枪',
    ARRAY['干油嘴', '干油泵油枪', '加油枪嘴'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '流枪',
    ARRAY['引流枪', '高压喷枪', 'CJWS', '枪尾接口外丝', '重量', '炉顶打水枪', '流枪'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '夹子',
    ARRAY['EL', '夹子', '夹布器'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '潜污泵',
    ARRAY['WQ', 'KW', '潜污泵'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '排污泵',
    ARRAY['排污泵', '无堵塞潜水式排污泵', 'WQ'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '齿轮泵',
    ARRAY['CB', '齿轮泵'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '渣浆泵',
    ARRAY['YZ', '渣浆泵', '液下渣浆泵'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '手动液压弯管机',
    ARRAY['手动液压弯管机', 'SWG', '液压拉码'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '切断机',
    ARRAY['切断机', '等离子切割机', 'LGK'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '砂轮机',
    ARRAY['砂轮机', 'FF'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '角磨机',
    ARRAY['GWS', 'FF', '角磨机'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '回火器',
    ARRAY['乙炔回火器', 'HF', '回火器'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '磨样机',
    ARRAY['GM', '磨样机'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '分割器',
    ARRAY['切割机', '内置气泵', '等离子切割机', 'LGK', '分割软件', '切割推刀带刻度', '分割器', '石膏板裁板器', 'GDC', '轮定位'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '热熔机',
    ARRAY['光纤熔接机', '配套', '热熔机', '模头'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '扩孔器',
    ARRAY['NHJJ', '冲孔机总成', 'WK', 'FT', 'JP', '偏心扩孔器', 'MHP', '件套', '手提式电动冲孔机', 'HJC'],
    0.8,
    'electrical',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '捣固机',
    ARRAY['YD', '捣固机'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '研磨机',
    ARRAY['EM', '研磨机'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '粉碎制样机',
    ARRAY['压紧装置', '镇江丰泰', '制样粉碎压杆', '制样粉碎机锻盖', '智能快压粉碎机', 'FTK', '粉碎制样机'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '套丝机',
    ARRAY['电动套丝机', '套丝机'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '弯管机',
    ARRAY['液压弯管机', '弯管器', '弯管机'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '横吊',
    ARRAY['横吊', '单轨吊', '横吊钢板起重钳'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '吊环',
    ARRAY['强力环', '吊环'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '风炮套头',
    ARRAY['一寸风炮套筒', 'mm', '风炮套筒', '套头', '风炮套头', '高压风炮管', 'CRV'],
    0.8,
    'pipe',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '油咀类',
    ARRAY['黄油嘴', '油咀类', '黄油咀'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '坠类',
    ARRAY['磁力线坠', '线坠', '坠类', 'kg', '防坠器'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '加油桶',
    ARRAY['mm', '加油桶'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '风炮头',
    ARRAY['风炮头', '风炮'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '地下栓',
    ARRAY['SA', '地下栓', '室外地下式消火栓'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '凿类',
    ARRAY['凿类', '聚氨酯实心防堵球', '带钢丝绳', '铬钒合金', '件套', '样冲', '带弹力', '六角尖凿子', '六角平凿子'],
    0.8,
    'general',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '各铲',
    ARRAY['扁铲', 'mm', '带杆', '各铲', 'CM'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '各划规',
    ARRAY['各划规', '螺纹规', '划规'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '罗纹规',
    ARRAY['公制', '螺纹规', '英制', '罗纹规'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '改锥',
    ARRAY['mm', '改锥', '一字改锥', '十字改锥'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '索具',
    ARRAY['浇筑索具', '单肢链条索具', '两头带套环', '组装型三肢链条索具', '双肢环形链条索具', '索具', '套环长', '链条长', '钢丝绳吊具', '承重'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '滑车',
    ARRAY['滑车', '拖缆滑车'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '托缆小车',
    ARRAY['型钢拖缆小车', '托缆小车', '型钢配套'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '充氮小车',
    ARRAY['充氮小车', 'MPa', 'CQJ', 'JTXCDZ', 'CDZ', '充氮装置', 'MPA'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '活项尖',
    ARRAY['顶尖', '活项尖'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焊枪',
    ARRAY['焊枪', 'KR'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '合金棒',
    ARRAY['黄铜棒', '紫铜棒', '铜棒', 'mm', '合金棒'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '振动棒',
    ARRAY['振动棒', 'mm', '竹扒片', '挑渣棒', '听音棒'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变径套',
    ARRAY['变径套', 'DH', '莫式', '钻头变径套'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '按钮',
    ARRAY['按钮', 'LA'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '耐高温电缆',
    ARRAY['mm', '耐高温电缆'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压电缆',
    ARRAY['YJV', 'KV', '高压动力电缆', '高压电缆', 'ZR'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '低压电缆',
    ARRAY['YJV', 'KV', '低压电缆', '低压动力电缆', 'ZR'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铝线',
    ARRAY['mm', '铝线', '铝线缆', '铝塑线'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢丝绳',
    ARRAY['mm', '钢丝绳', 'WS', 'IWR'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '动力电缆',
    ARRAY['YJV', '动力电缆', 'ZR', 'KV'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铜线',
    ARRAY['mm', '电缆', '铜线', 'BV', '平方'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '导线',
    ARRAY['mm', 'BV', 'BVR', '导线'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电力电缆',
    ARRAY['YJV', '阻燃低压电力电缆', 'KV', '电力电缆', 'kV', 'ZR'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '软电缆',
    ARRAY['ZR', '软电缆'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '双屏蔽同轴电缆',
    ARRAY['同轴电缆', 'SYV', '编码器增量输出电缆', '芯直线型', 'MQDC', '双屏蔽同轴电缆'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '计算机电缆',
    ARRAY['DJYPVP', 'DJYVPR', 'ZR', '计算机电缆'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '扁平电缆',
    ARRAY['扁平电缆', 'YGGB', '电缆', '硅胶耐高温扁电缆', 'ZR'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变频电缆',
    ARRAY['KV', 'TK', 'BPYJVP', '电缆', '阻燃变频电力电缆', '变频电缆', 'ZR'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '绳扣',
    ARRAY['钢丝绳扣', '吊装用钢丝绳', '绳扣'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '绝缘杆封地线',
    ARRAY['黄绿色', 'KV', 'mm', '接电线', 'BVR', '接地棒', '配夹', '绝缘杆封地线', '高压接地线', '接地线'],
    0.8,
    'electrical',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '视频线',
    ARRAY['VGA', 'HDMI', '视频线'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电缘线',
    ARRAY['耐高温电源线', '电缘线', '电缆', 'KVVRP', '电源线', 'BV', '阻燃聚乙烯电线', 'ZR'],
    0.8,
    'electrical',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '滚动轴承',
    ARRAY['滚动轴承', '轴承'],
    0.8,
    'bearing',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '滑动轴承',
    ARRAY['自润滑轴承', '滑动轴承', '轴套', 'DC'],
    0.8,
    'bearing',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '轴承座',
    ARRAY['GBS', '轴承座'],
    0.8,
    'bearing',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '青铜带',
    ARRAY['四氟青铜导向带', '青铜带', '导向带'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '制动闸皮',
    ARRAY['闸皮', '制动闸皮'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '氟胶圈',
    ARRAY['型圈', '氟胶圈', '氟胶'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '缓冲胶圈',
    ARRAY['mm', '缓冲胶圈'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '挡液圈',
    ARRAY['型圈', '挡圈', 'HP', '挡液圈'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '橡胶圈',
    ARRAY['mm', '橡胶圈'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '机油滤芯',
    ARRAY['JX', '机油滤芯'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压油管',
    ARRAY['工程胶管', '高压油管', 'SP'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '低压油管',
    ARRAY['带配套接头', '反向', 'SP', '低压油管', '低压回油管', 'FLAT'],
    0.8,
    'pipe',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压油管',
    ARRAY['HM', '液压软管总成', 'JB', 'LM', '铠装耐高温高压', '液压油管'],
    0.8,
    'pipe',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '刹车油管',
    ARRAY['豪沃', 'mm', '刹车管', '刹车油管', '铁通机车右刹车油管', 'NY', '铁通机车左刹车油管', '气泵钢丝管'],
    0.8,
    'pipe',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铲车销',
    ARRAY['铲车销', '中桥小差速锁锁销', 'STR'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '刹车片',
    ARRAY['mm', '刹车片'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '肖圈',
    ARRAY['型圈', '肖圈'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '专用线',
    ARRAY['专用线', '油门线'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铲齿',
    ARRAY['JS', '锥齿轮', '二轴导套', '变速箱法士特', '太阳轮', '奔驰标', '铲齿'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '齿合器',
    ARRAY['YZ', 'BK', '齿合器'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '齿圈',
    ARRAY['齿圈', '内齿圈'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '灯',
    ARRAY['灯', 'LED'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '灯芯',
    ARRAY['五寸方灯芯', '方灯芯', '灯芯', '灯箱', '灯条', 'LED', 'CM'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '水堵',
    ARRAY['mm', 'FC', '水堵'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '制动液',
    ARRAY['制动液', 'GB', 'KG', '合成制动液', 'DOT', '刹车油'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '同心变径管',
    ARRAY['同心变径', '同心变径管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '同心异径管',
    ARRAY['同心异径管', 'DN'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '偏心异径管',
    ARRAY['DN', '偏心异径管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压软管',
    ARRAY['液压软管总成', 'JB', '软管总成', '钢丝编织', '胶管总成', '液压软管'],
    0.8,
    'pipe',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '斜三通',
    ARRAY['De', '斜三通'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '丝扣三通',
    ARRAY['丝扣三通', '丝扣变径三通', 'DN', '内丝变径三通', '内丝三通'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '堵头',
    ARRAY['堵头', 'DN'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '弯管',
    ARRAY['DN', '弯管'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '丝类',
    ARRAY['对丝', '液压对丝', '丝类'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铁皮',
    ARRAY['屋顶伸缩缝铁皮', '铁字牌', '镀锌铁皮', 'mm', '铁皮', '立式磨机外皮'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '支撑环',
    ARRAY['支撑环', 'HY'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动蝶阀',
    ARRAY['电动蝶阀', 'DN'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '手动蝶阀',
    ARRAY['手动蝶阀', 'DN'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气动蝶阀',
    ARRAY['气动蝶阀', 'PN', 'DN'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '手动截止阀',
    ARRAY['截止阀', 'DN', '手动截止阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动截止阀',
    ARRAY['电动截止阀阀体', 'DN', 'KJ', '电动截止阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气动截止阀',
    ARRAY['ZJHM', '气动截止阀阀体', '气动截止阀', 'DN'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '手动闸阀',
    ARRAY['手动闸阀', 'DN'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动闸阀',
    ARRAY['DN', '电动闸阀'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气动闸阀',
    ARRAY['气动疏水阀', 'DN', 'FD', '气动闸阀', 'ZMQY', 'VT'],
    0.8,
    'valve',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '手动球阀',
    ARRAY['手动球阀', 'PN', 'DN'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动球阀',
    ARRAY['KER', '电动球阀', 'DN', 'GS'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气动球阀',
    ARRAY['DN', '气动球阀'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气源球阀',
    ARRAY['气源球阀', 'PN', 'DN', 'QY', 'SS', '不锈钢卡套球阀', '五通球阀', 'QG', 'GY', 'ZF'],
    0.8,
    'valve',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '手动止回阀',
    ARRAY['DN', '手动止回阀', '止回阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气动止回阀',
    ARRAY['气动止回阀', '气动逆止阀体', 'CKH', 'DN', '气动逆止阀'],
    0.8,
    'valve',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '泄压阀',
    ARRAY['DN', '泄压阀', '风机泄压阀', 'TW', 'SVF'],
    0.8,
    'valve',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防火阀',
    ARRAY['矩形防火阀', '关闭', 'SFVD', '方形防火阀', '功能控制', '防火阀'],
    0.8,
    'valve',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '手动盲板阀',
    ARRAY['PN', 'MPa', 'DN', '手动盲板阀', 'CX'],
    0.8,
    'valve',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动盲板阀',
    ARRAY['MPa', '电动盲板阀', 'DN'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '隔膜阀',
    ARRAY['PN', 'DN', 'MPa', '耐压', '隔膜阀'],
    0.8,
    'valve',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '针型阀',
    ARRAY['针型阀', 'PN', 'DN'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '排污阀、排水器',
    ARRAY['DN', 'DB', '防泄漏煤气排水器', 'CCLP', '排污阀、排水器', 'CC'],
    0.8,
    'valve',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动调节阀',
    ARRAY['DN', '电动调节阀'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气动调节阀',
    ARRAY['PN', '气动调节阀', 'DN'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '自动排气阀',
    ARRAY['自动排气阀', 'MPa', 'DN', '微量自动排气阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '背压阀',
    ARRAY['PN', 'UPVC', '背压阀', 'DN'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '燃气调压器',
    ARRAY['RTJ', '定子调压器', '氮气调压阀', 'DN', 'QY', 'GK', '燃气调压器', '燃气调压阀', '过滤调压器'],
    0.8,
    'valve',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '阀门配件',
    ARRAY['阀门配件', 'DN'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '金属编织软管',
    ARRAY['钢丝管外径', 'mm', '两端带快速接头', '小头', '金属编织软管', '不锈钢编织软管'],
    0.8,
    'pipe',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢波纹管',
    ARRAY['mm', '上下加盖', '钢波纹管', '不锈钢波纹管'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压胶管系列',
    ARRAY['高压胶管', 'DN', '高压胶管系列', 'DKOS', 'SP', 'SH', '铠装高压胶管'],
    0.8,
    'pipe',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '胶管总成',
    ARRAY['JB', '胶管总成', '高压胶管总成'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '测压软管管',
    ARRAY['AC', '测压软管管', 'DN', '测压软管'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    ' PU气管',
    ARRAY['PU', 'mm', '耐高压', '气管', 'PA', '气动软管', ' PU气管'],
    0.8,
    'pipe',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PE管',
    ARRAY['mm', 'PE管', 'PE'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PVC、UPVC管',
    ARRAY['UPVC', 'PVC', 'DN', 'PVC、UPVC管', 'De'],
    0.8,
    'pipe',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢塑复合管',
    ARRAY['工艺模块', '直管', 'DN', '钢塑复合管'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    ' PPR、UPPR管',
    ARRAY['PN', 'DN', '给水管', 'PPR', ' PPR、UPPR管', 'PPH'],
    0.8,
    'pipe',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '涂塑水带',
    ARRAY['涂塑水带', '消防水带', 'cm', '扁放'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动滚筒',
    ARRAY['kw', '电动滚筒', 'KW'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '传动滚筒',
    ARRAY['NGT', '传动滚筒', '滚筒'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '改向滚筒',
    ARRAY['mm', '改向滚筒'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '支架',
    ARRAY['DN', '支架'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '缓冲床',
    ARRAY['缓冲床', 'mm', '皮带缓冲床', '滑轨冷床', 'GS', '带宽'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '立棍',
    ARRAY['立辊', '图号', '导向柱', 'HY', '立棍'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '硫化布',
    ARRAY['硫化布', 'mm', '车辆苫布', '硫化风帆布滤布'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'T型压板',
    ARRAY['T型压板', '聚氨酯清扫器刮板', '压板', '输送带'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢丝输送带',
    ARRAY['输送带', '钢丝输送带', 'ST', '钢芯输送带'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '裙边输送带',
    ARRAY['TC', '铠装除铁器皮带', '裙边输送带', '耐热', 'EP'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'EP输送带',
    ARRAY['EP输送带', 'EP', '输送带'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高温输送带',
    ARRAY['高温输送带', 'mm', '耐热', '输送带', 'EP'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '提升机',
    ARRAY['提升机', 'CD'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '清扫器及其组件',
    ARRAY['HM', 'MM', '合金型', '清扫器及其组件', '耐磨尼龙与不锈钢丝混合刷', '电动滚刷清扫器毛刷辊'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '涡轮蜗杆减速机',
    ARRAY['涡轮蜗杆减速机', 'TPG'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '行星齿轮减速机',
    ARRAY['行星齿轮减速机', '减速机'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '减速电机',
    ARRAY['减速电机', 'MH', 'KW'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '减速机配件',
    ARRAY['减速机配件', 'QY'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '单轨小车',
    ARRAY['单轨小车', '手拉单轨小车'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '主动轮组',
    ARRAY['轴承', '主动轮组', '主动车轮组'],
    0.8,
    'bearing',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '被动轮组',
    ARRAY['被动轮组', '从动车轮组', '轴承'],
    0.8,
    'bearing',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '小车行走轮组',
    ARRAY['现场实测', '小车行走轮组', 'DC'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '温度补偿装置',
    ARRAY['nJGH', 'XEK', 'TNY', '铜插温度补偿', 'GBG', '温度补偿装置', '铜插式温度补偿段', '变频器温控仪', '轴向型内压式波纹补偿器', 'ZH'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '供电端子',
    ARRAY['滑触线接线端子', '供电端子'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'C型轨道',
    ARRAY['轨道', 'kg', 'C型轨道'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电缆夹具',
    ARRAY['电缆夹具', 'mm', '电缆', '电缆牵引线网套'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '软连接',
    ARRAY['PN', 'mm', '软连接', 'DN'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '导绳器',
    ARRAY['导绳器', '电葫芦导绳器'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '楔型接头',
    ARRAY['楔型接头', '楔形铁'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '抓斗',
    ARRAY['mm', '抓斗', '容积', '立方米', '张开尺寸', 'XZ'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动葫芦减速机及配件',
    ARRAY['QY', '电动葫芦减速机及配件', '减速机'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '轨道夹板',
    ARRAY['KG', '轨道夹板', 'QU'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '压轨器',
    ARRAY['mm', '压轨器', 'QU'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '轨道伸缩缝',
    ARRAY['GB', 'KG', '轨道伸缩缝', '弯度轨道', '度轨道互接接头', 'QU'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '夹钳',
    ARRAY['电动卧卷夹钳', 'DDJS', '夹钳', 'DC'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钩头',
    ARRAY['钩头', '翻包钩', '电葫芦钩头'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防脱扣装置',
    ARRAY['防脱扣装置', '吊钩防脱器', '防脱钩'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '滑轮组',
    ARRAY['滑轮组', '定滑轮组'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '吊钩滑车',
    ARRAY['磁吸挂钩', '轮片统一', '轧制轮片', '滑轮组', '吊钩滑车', '煤气柜配重滑道', '全部带轴承', '按图纸加工'],
    0.8,
    'bearing',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '导轮',
    ARRAY['导轮', 'mm'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '滑车轮',
    ARRAY['开口滑车', '滑车轮'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'U型导向轮',
    ARRAY['导向轮装配', '炉盖升降立柱导向轮', '图号', '导向轮', 'GBS', 'U型导向轮'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '缓冲器',
    ARRAY['缓冲器', '聚氨酯缓冲器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卷筒装置',
    ARRAY['卷筒装置', 'MTU', '钢丝绳卷筒', '电缆卷筒'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电动卷筒',
    ARRAY['特制高绝缘', '电缆卷盘', '电缆卷筒', 'MTU', '电动卷筒'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '密封风机',
    ARRAY['防爆排风扇', '含滤芯', 'BFAG', '排气风机', '密封风机', '煤气加压机风机叶轮端气密封端盖'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '冷却风机',
    ARRAY['冷却风机', '电机风机'],
    0.8,
    'electrical',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'DBF风扇',
    ARRAY['DBF风扇', 'mm', 'BFAG', 'HA', '湿电除尘散热风扇', 'SF'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '变频电机通风机',
    ARRAY['变频电机通风机', '电机风机', 'KW'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '联轴器组',
    ARRAY['联轴器组', '带注销', '膜片', '风机联轴器', '联轴器', '缓冲垫'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '圆形自垂百叶',
    ARRAY['防雨自垂百叶风口', 'mm', '圆形自垂式百叶风口', '圆形自垂百叶', '铝合金'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '除污器',
    ARRAY['DN', 'MPa', '吸污器总成', 'XWQ', '不锈钢', '卧式角式除污器', '旋流除污器', '配置高压冲洗喷嘴', '除污器'],
    0.8,
    'general',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '净油机',
    ARRAY['油烟净化器', 'WSNATF', '焊烟净化器', '移动式工业级', 'kw', '净油机', '双臂', '离心式净油机'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '清洗泵',
    ARRAY['一台备用', '扬程', '材质', '立方', 'SQ', '清洗机', '氟塑料', '冲洗系统', '化学清洗泵', '流量'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '换热器',
    ARRAY['板式换热器', '换热器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '冷却塔配件',
    ARRAY['冷却塔配件', 'GFNDP'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '冷却塔喷头',
    ARRAY['喷头石墨垫', '冷却塔喷头', 'GFNDP', 'ABS', '喷头'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '除尘布袋',
    ARRAY['布袋', '除尘布袋'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '布袋骨架',
    ARRAY['mm', '骨架', '布袋骨架'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '星形卸灰阀',
    ARRAY['卸灰阀', '星形卸灰阀', 'RS', '电机功率', 'KW', '除尘卸灰升降装置', 'YCD', 'HX', '星型卸灰阀'],
    0.8,
    'valve',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '卸料器',
    ARRAY['卸料器', 'mm', '星型卸料器', 'KW'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '圆顶阀',
    ARRAY['YDF', '圆顶阀气囊', 'DN', '圆顶阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '分料器',
    ARRAY['分料器', '三通分料器', 'KW', '电液动三通分料器'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '声波清灰器',
    ARRAY['声波吹灰器膜片', 'mm', '声波吹灰器', 'FVN', 'Hz', '材质', '声波清灰器', 'TDQ', '钛合金', 'CH'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '加湿卸灰机',
    ARRAY['YJS', '加湿机', '加湿机轴', '加湿卸灰机'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '螺旋输送机',
    ARRAY['MM', '螺旋输送机', 'mm', '号线返焦螺旋输送机', 'KW', '角度', '长度', 'kW', '号线返矿螺旋输送机', '直径'],
    0.8,
    'general',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '带式输送机',
    ARRAY['mm', '带式输送机', 'DTIIA'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '筛板、筛网',
    ARRAY['mm', '筛板、筛网', 'MM'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '吊挂',
    ARRAY['VR', '橡胶缓冲吊挂', '安全滑线吊挂', '单级安全滑线吊挂', '吊挂', 'KDY', '武汉型', '吊挂总成'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气缸配件',
    ARRAY['SFC', '制动气缸', 'DN', 'MM', 'KD', '气动快切阀气缸端盖', '气缸活塞组合密封圈', '气缸配件', 'SD', '气动大回流阀专用'],
    0.8,
    'valve',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'PU管接头',
    ARRAY['气管外螺纹直通接头', 'PE', '气管三通快速插接头', '气管直通快速插接头', 'PU', '材质', 'PU管接头'],
    0.8,
    'pipe',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '直通接头',
    ARRAY['直通接头', '卡套直通接头', 'GV'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气源三联件',
    ARRAY['气动三联件', 'AC', '气源三联件'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '调压三联件',
    ARRAY['调压三联件', '三联件', 'DN'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '二联件',
    ARRAY['气动二联件', 'AC', '二联件', 'DG'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气缸筒体',
    ARRAY['空气炮缸筒', 'KUP', '容积', 'KQP', '气缸筒体'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气动开关阀',
    ARRAY['气动开关阀', '气路控制开关阀', 'CDJ', 'TUW', '气动吹扫气枪', '气动阀开关', 'LSP', '气动电磁阀'],
    0.8,
    'valve',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气源两联件',
    ARRAY['AC', 'AL', '两联件', '气动两联件', '气源两联件'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '气动调压阀',
    ARRAY['气动调压阀', '调压阀'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压缸',
    ARRAY['GBS', '液压缸'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '风琴防护罩',
    ARRAY['翻车机压车油缸', '法兰式油缸护套', 'JY', '不锈钢', '户外防护罩', 'KF', '耐高温防护套', '拉链伸缩式油缸杆防护罩', '风琴防护罩'],
    0.8,
    'general',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '叠加式减压阀',
    ARRAY['叠加式减压阀', 'YM', 'ZDR', 'DP'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '调速阀',
    ARRAY['AS', '调速阀'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '直流式减压阀',
    ARRAY['FW', '直流式减压阀', 'YM', '液压阀', 'DRVP', 'DR', '减压阀', 'RCT', 'XG'],
    0.8,
    'valve',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '比例减压阀',
    ARRAY['YG', 'DREE', 'DREME', '比例减压阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '溢流安全阀',
    ARRAY['溢流安全阀', 'DBDS', '安全阀'],
    0.8,
    'valve',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '插装阀',
    ARRAY['插装阀', 'LCN', '液压阀', '两通插装阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '伺服阀',
    ARRAY['SV', 'VSX', 'HA', '伺服阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压球阀',
    ARRAY['DN', 'KHB', '球阀', '液压球阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '不锈钢卡套弯头',
    ARRAY['MM', '丝扣尺寸', 'ZG', '卡套接头', '不锈钢卡套弯头', '不锈钢卡套直通接头'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压对丝',
    ARRAY['液压对丝', '不锈钢对丝'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '三通卡套接头',
    ARRAY['卡套', '三通卡套接头', '不锈铜管'],
    0.8,
    'pipe',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '直角卡套接头',
    ARRAY['卡套接头', '直角卡套接头'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '宝塔接头',
    ARRAY['宝塔接头', '焊接宝塔接头'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '接头体',
    ARRAY['接头体', 'BSF', '法兰焊接接头', 'SAE', '焊接接头', '型圈带活动焊接短节'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '油管接头',
    ARRAY['GB', '高压对丝接头', '材质', '小头', '油管接头', '油管焊接接头'],
    0.8,
    'pipe',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '蓄能器',
    ARRAY['蓄能器', 'NXQ'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压锁',
    ARRAY['液压锁', '叠加式液控单向阀'],
    0.8,
    'valve',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压管夹',
    ARRAY['单管夹', '液压管夹'],
    0.8,
    'pipe',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '阻尼器',
    ARRAY['UPVC', '空气式脉冲阻尼器', 'PN', 'DN', '直通式阻尼器', '空气室式脉冲阻尼器', '阻尼器'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '流量显示器',
    ARRAY['流量显示器', '静电除尘显示器', 'GGAJ', 'KV', '显示屏', 'Simatic', 'HIVB', 'FX', '立方米', 'IE'],
    0.8,
    'electrical',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '油杯',
    ARRAY['油杯', '内径', '外径', 'mm', '材质', '油环', 'TDZBS', '黄铜'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '油流指示器',
    ARRAY['给油指示器', 'JB', 'GZQ', '油流指示器', 'DN'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电磁给油器集成',
    ARRAY['ZYZK', 'CD', '电磁给油器集成', 'LN', 'RBKJ', '电磁给油器'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液压拉紧装置',
    ARRAY['液压拉紧装置', 'BE', '减震器', '液压杆'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '缸头',
    ARRAY['缸头', '油缸耳环', '液压缸型号', 'DC'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '压力补偿器',
    ARRAY['mm', '压力补偿器', 'DN'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '轴、曲轴、软轴',
    ARRAY['DSJSB', '轴、曲轴、软轴'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    'T型六角垫',
    ARRAY['六角垫', 'T型六角垫', '梅花型六角垫'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '弹性圆柱销',
    ARRAY['弹性柱销', '内径', '外径', '带聚氨酯套', '弹性柱销螺栓', '弹性圆柱销'],
    0.8,
    'fastener',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '液力偶合器',
    ARRAY['液力偶合器', 'YOXIIZ', '液力耦合器', 'YOXII'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '锁紧盘',
    ARRAY['紧固套', '锁紧盘', '轴承配套', '锁紧板', '轴承配用', 'CAK'],
    0.8,
    'bearing',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '联轴器系列',
    ARRAY['联轴器系列', '联轴器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '万向节',
    ARRAY['万向节', '万向轴接手', 'GBS', '上刷辊万向接轴', 'HDL'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '制动衬垫',
    ARRAY['陶纤维衬垫', '止动垫圈', '制动衬垫', '带槽'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '尼龙轮套',
    ARRAY['内径', '外径', '尼龙轮套', '绝缘套', '尼龙套', 'NL'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '离合器',
    ARRAY['离合器', '超越离合器'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '制动器系列及附件',
    ARRAY['正反拉杆', '鼓式制动器', 'HL', 'YWZ', '制动器系列及附件', 'WC'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '抱闸',
    ARRAY['抱闸轮', '抱闸'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电机电磁制动器',
    ARRAY['电磁失电制动器', '电机电磁制动器', 'DZS', 'DC'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '链接头',
    ARRAY['链接头', '链子活接'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '起重链条',
    ARRAY['起重链条', 'CDS'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '板链',
    ARRAY['刮板机链板', 'FU', '板链', 'NE'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '拖链',
    ARRAY['拖链', 'TL'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '清水泵',
    ARRAY['清水泵', '水泵'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '循环油泵',
    ARRAY['油泵', '循环油泵'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '叶片泵',
    ARRAY['叶片泵', 'SDV', 'PV'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '螺杆泵',
    ARRAY['LRF', 'GR', '螺杆泵', 'SMT'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '恒压变量泵',
    ARRAY['VSO', 'PV', '恒压变量泵', 'VPB', 'KTINMMC', '维修恒压变量泵', 'DRS'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '真空泵类',
    ARRAY['真空泵', '真空泵类'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '真空泵类配件',
    ARRAY['真空泵类配件', 'SK', '分析仪吸气泵膜片', 'kw', '真空泵', '岛津荧光真空泵专用', '真空泵油', 'KTE'],
    0.8,
    'general',
    80,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '空气压缩机',
    ARRAY['空气压缩机', '压缩机'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '储气罐',
    ARRAY['立方', '储气罐', 'MPa'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '立式集气罐',
    ARRAY['侧集箱', 'DN', '立式集气罐', '集气罐'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '起重设备（报检）',
    ARRAY['YZ', 'QD', '起重设备（报检）', '双梁桥式起重机'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    ' 安全阀（报检）',
    ARRAY[' 安全阀（报检）', 'DN', '安全阀', '效验安全阀'],
    0.8,
    'valve',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电接点压力表',
    ARRAY['YX', 'MPa', 'YXC', '电接点压力表'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '振动电机',
    ARRAY['YZS', '振动电机', 'KW'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '起重电机',
    ARRAY['ZDY', '起重电机', 'KW', '电机'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '防爆电机',
    ARRAY['YBX', '防爆电机', 'KW'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高效电机',
    ARRAY['KW', '高效电机', '电机', 'YE'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高压电机',
    ARRAY['YPKK', '高压电机', 'KW', 'KV'],
    0.8,
    'electrical',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电机端盖',
    ARRAY['电机端盖', 'KW', 'YE'],
    0.8,
    'electrical',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电机轴瓦',
    ARRAY['电机型号', 'TDZGS', '轴瓦', 'KW', 'YPKS', '厂家', '上海电气集团上海电机厂', '出品编号', '电机轴瓦', 'YSBPKK'],
    0.8,
    'electrical',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电机减震垫',
    ARRAY['LEN', 'NH', '公斤', '中间孔', 'LN', '风机减震器', '对应减速电机', '风机减震垫', 'KAD', '制动器摩擦片'],
    0.8,
    'electrical',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电机集电总成',
    ARRAY['方形', '绿篱机启动总成', 'mm', 'YX', 'KW', '螺丝孔距约', '电机背包风机总成', '电机集电总成', 'YE'],
    0.8,
    'electrical',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电气滑环',
    ARRAY['电气滑环', '电机滑环', 'mm', 'YZR', '滑环'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电机玻璃钢护罩',
    ARRAY['电机玻璃钢护罩', 'FCF', '玻璃钢防尘罩', '米射雾器俯仰电机护罩', '带宽'],
    0.8,
    'electrical',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铁路专用设备、备件',
    ARRAY['mm', '铁路专用设备、备件'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '瓷砖，瓷砖填缝剂',
    ARRAY['外墙砖', 'mm', '瓷砖，瓷砖填缝剂'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '钢筋',
    ARRAY['直条钢筋', 'HPB', 'HRB', '材质', '钢筋', '螺纹钢'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '直缝管',
    ARRAY['直缝管', '直缝焊接钢管', 'DN', '直管'],
    0.8,
    'pipe',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '铁板',
    ARRAY['mm', '铁板', '带铁', '铸铁底板'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '夹板',
    ARRAY['轴夹', '斜接头夹板', '钢轨用', 'kg', '输送带专用夹板', '夹板'],
    0.8,
    'general',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '线材',
    ARRAY['HPB', 'KV', 'RVB', '电线', '平方', '线材'],
    0.8,
    'electrical',
    60,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '各种螺纹钢',
    ARRAY['螺纹钢', 'HRB', '各种螺纹钢'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '各种碳结',
    ARRAY['碳结', '碳结钢', '各种碳结'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '道渣',
    ARRAY['道渣', 'KG', '轨道'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '1#高炉运行工段',
    ARRAY['BCS', 'GL', '1#高炉运行工段', '和隆优化高炉送风设备优化控制系统', '料车牵引端臂'],
    0.8,
    'general',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '设备工程类',
    ARRAY['设备工程类', 'KW'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '焦化厂',
    ARRAY['mm', 'MPa', '焦化厂'],
    0.8,
    'general',
    30,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '质计部',
    ARRAY['轨道衡', '报告专用', '报告用', '汽车衡引坡修复', '电子汽车衡', '质计部', '关于增加轧钢质检监控摄像头的报告'],
    0.8,
    'electrical',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '炼铁一厂',
    ARRAY['炼铁一厂', '报告用'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '炼铁二厂',
    ARRAY['炼铁二厂', '报告用'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '炼钢二厂',
    ARRAY['炼钢二厂', '报告用'],
    0.8,
    'general',
    20,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '带钢厂',
    ARRAY['带钢厂', '空压机维修申请', '带钢二期', '带钢', '报告用', '线加热炉反吹工程与大修的报告', '线加热炉中修外委报告', '带钢二期除尘管道等安装报告', '线加热炉入炉端炉墙外委报告'],
    0.8,
    'pipe',
    90,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '动力部',
    ARRAY['TRT', '关于动力部', '动力部', '报告用'],
    0.8,
    'general',
    40,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '环境部',
    ARRAY['关于竖炉一', '报告用', '关于在环境部铺设视频监控传输网络的申请报告', '关于竖炉一期脱硫塔做防腐的申请', '关于对全烟气在线监测加装预处理装置的申请报告', '三期消白塔外委检修申请', '环境部'],
    0.8,
    'general',
    70,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '安全部',
    ARRAY['煤气管道壁厚检测申请', '气瓶检验申请', '报警仪检验申请', '报告类', '安全部'],
    0.8,
    'pipe',
    50,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '轴承',
    ARRAY['轴承', 'bearing', '滚动轴承', '滑动轴承', '深沟球', '圆锥滚子'],
    0.95,
    'mechanical',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '螺栓',
    ARRAY['螺栓', '螺钉', '螺丝', 'bolt', 'screw', '内六角', '外六角'],
    0.95,
    'fastener',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '管件',
    ARRAY['管', '管道', '管件', 'pipe', 'tube', '弯头', '三通', '四通'],
    0.95,
    'pipe',
    100,
    'system'
);

INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '电气',
    ARRAY['接触器', '继电器', '断路器', '变频器', 'contactor', 'relay'],
    0.9,
    'electrical',
    90,
    'system'
);

-- ========================================
-- 创建索引
-- ========================================

CREATE INDEX IF NOT EXISTS idx_extraction_rules_category ON extraction_rules (material_category, priority) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_extraction_rules_rule_id ON extraction_rules (rule_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_synonyms_original ON synonyms (original_term) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_synonyms_standard ON synonyms (standard_term) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_synonyms_category_type ON synonyms (category, synonym_type) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_categories_name ON material_categories (category_name) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_categories_keywords ON material_categories USING gin (keywords) WHERE is_active = TRUE;

-- ========================================
-- 验证导入结果
-- ========================================

-- 显示导入统计
SELECT 'extraction_rules' as table_name, COUNT(*) as record_count FROM extraction_rules WHERE is_active = TRUE
UNION ALL
SELECT 'synonyms' as table_name, COUNT(*) as record_count FROM synonyms WHERE is_active = TRUE
UNION ALL
SELECT 'material_categories' as table_name, COUNT(*) as record_count FROM material_categories WHERE is_active = TRUE;

-- 显示规则概览
SELECT rule_id, rule_name, confidence, priority 
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
FROM material_categories 
WHERE is_active = TRUE 
ORDER BY priority DESC 
LIMIT 10;

-- 提交事务
COMMIT;

-- 显示成功消息
\echo '🎉 PostgreSQL规则和词典导入完成！'
\echo '📊 导入统计:'
\echo '  - 基于230,421条Oracle物料数据生成'
\echo '  - 提取规则: 6条 (置信度88%-98%)'
\echo '  - 同义词: 3,000+条'
\echo '  - 类别关键词: 1,000+个'
\echo ''
\echo '🧪 测试查询示例:'
\echo '  SELECT * FROM extraction_rules WHERE material_category = ''general'';'
\echo '  SELECT * FROM synonyms WHERE category = ''material'';'
\echo '  SELECT * FROM material_categories WHERE category_type = ''bearing'';'
