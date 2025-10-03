"""
分析Oracle真实数据脚本
连接Oracle数据库，查询并分析真实物料数据，生成基于实际数据的类别关键词和提取规则
"""

import logging
from collections import defaultdict, Counter
import re
import json
from datetime import datetime
from typing import Dict, List, Set, Tuple

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def analyze_oracle_data():
    """分析Oracle真实数据"""
    logger.info("🔍 开始分析Oracle真实物料数据...")
    
    # 导入连接器
    from oracledb_connector import OracleDBConnector
    from oracle_config import OracleConfig, MaterialQueries
    
    # 创建连接
    config_params = OracleConfig.get_connection_params()
    # 只传递OracleDBConnector需要的参数
    connector_params = {
        'host': config_params['host'],
        'port': config_params['port'],
        'service_name': config_params['service_name'],
        'username': config_params['username'],
        'password': config_params['password']
    }
    connector = OracleDBConnector(**connector_params)
    
    if not connector.connect():
        logger.error("❌ Oracle数据库连接失败")
        return False
    
    try:
        # 1. 查询物料基本信息样本
        logger.info("📊 查询物料基本信息样本...")
        sample_query = """
        SELECT 
            m.code as erp_code,
            m.name as material_name,
            m.materialspec as specification,
            m.materialtype as material_type,
            m.materialmnecode as mnemonic_code,
            m.materialshortname as short_name,
            m.ename as english_name,
            c.name as category_name,
            c.code as category_code,
            u.name as unit_name,
            m.enablestate,
            m.materialmgt
        FROM DHNC65.bd_material m
        LEFT JOIN DHNC65.bd_marbasclass c ON m.pk_marbasclass = c.pk_marbasclass
        LEFT JOIN DHNC65.bd_measdoc u ON m.pk_measdoc = u.pk_measdoc
        -- 读取所有物料数据（不限制数量）
        ORDER BY m.code
        """
        
        # 使用批量查询获取所有物料数据
        materials_sample = connector.execute_query_batch(sample_query, batch_size=5000)
        logger.info(f"✅ 获取到 {len(materials_sample)} 条物料数据（全量数据）")
        
        # 2. 查询所有物料分类
        logger.info("📂 查询物料分类信息...")
        categories = connector.execute_query(MaterialQueries.MATERIAL_CATEGORIES_QUERY)
        logger.info(f"✅ 获取到 {len(categories)} 个物料分类")
        
        # 3. 查询计量单位
        logger.info("📏 查询计量单位信息...")
        units = connector.execute_query(MaterialQueries.UNIT_QUERY)
        logger.info(f"✅ 获取到 {len(units)} 个计量单位")
        
        # 4. 分析数据并生成结果
        analysis_result = perform_data_analysis(materials_sample, categories, units)
        
        # 5. 保存分析结果
        save_analysis_results(analysis_result)
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 数据分析过程中发生错误: {e}")
        return False
    finally:
        connector.disconnect()

def perform_data_analysis(materials: List[Dict], categories: List[Dict], units: List[Dict]) -> Dict:
    """执行数据分析"""
    logger.info("🧠 开始执行数据分析...")
    
    analysis = {
        'material_patterns': analyze_material_patterns(materials),
        'category_keywords': generate_category_keywords(materials, categories),
        'extraction_rules': generate_extraction_rules_from_data(materials),
        'synonym_mappings': generate_synonym_mappings(materials, units),
        'statistics': generate_statistics(materials, categories, units)
    }
    
    return analysis

def analyze_material_patterns(materials: List[Dict]) -> Dict:
    """分析物料描述模式"""
    logger.info("🔍 分析物料描述模式...")
    
    patterns = {
        'size_patterns': [],
        'brand_patterns': [],
        'material_patterns': [],
        'model_patterns': [],
        'common_words': []
    }
    
    all_descriptions = []
    
    for material in materials:
        # 组合完整描述，处理None值
        name = material.get('MATERIAL_NAME') or ''
        spec = material.get('SPECIFICATION') or ''
        material_type = material.get('MATERIAL_TYPE') or ''
        
        full_desc = f"{name} {spec} {material_type}".strip()
        if full_desc:
            all_descriptions.append(full_desc)
        
        # 提取尺寸模式
        size_matches = re.findall(r'\b(?:M|Φ|φ|DN)?\d+(?:\.\d+)?[×*xX]\d+(?:\.\d+)?(?:[×*xX]\d+(?:\.\d+)?)?\b', full_desc)
        patterns['size_patterns'].extend(size_matches)
        
        # 提取可能的品牌模式（大写字母开头的词）
        brand_matches = re.findall(r'\b[A-Z][A-Z0-9]{2,}\b', full_desc)
        patterns['brand_patterns'].extend(brand_matches)
        
        # 提取材质模式
        material_matches = re.findall(r'\b(?:304|316L?|201|430|不锈钢|碳钢|合金钢|铸铁|铜|铝)\b', full_desc)
        patterns['material_patterns'].extend(material_matches)
        
        # 提取型号模式
        model_matches = re.findall(r'\b[A-Z0-9]{3,}(?:-[A-Z0-9]+)?\b', full_desc)
        patterns['model_patterns'].extend(model_matches)
    
    # 统计常见词汇
    all_text = ' '.join(all_descriptions)
    words = re.findall(r'[\u4e00-\u9fff]+|[A-Za-z0-9]+', all_text)
    word_counter = Counter(words)
    patterns['common_words'] = word_counter.most_common(50)
    
    # 统计各类模式
    for key in ['size_patterns', 'brand_patterns', 'material_patterns', 'model_patterns']:
        patterns[key] = Counter(patterns[key]).most_common(20)
    
    logger.info(f"✅ 分析完成，发现 {len(patterns['common_words'])} 个常见词汇")
    return patterns

def generate_category_keywords(materials: List[Dict], categories: List[Dict]) -> Dict:
    """基于真实数据生成类别关键词"""
    logger.info("🏷️ 基于真实数据生成类别关键词...")
    
    category_keywords = {}
    category_materials = defaultdict(list)
    
    # 按分类组织物料
    for material in materials:
        category_name = material.get('CATEGORY_NAME', '')
        if category_name:
            name = material.get('MATERIAL_NAME', '') or ''
            spec = material.get('SPECIFICATION', '') or ''
            model = material.get('MODEL', '') or ''
            full_desc = f"{name} {spec} {model}".strip()
            category_materials[category_name].append(full_desc)
    
    # 为每个分类提取关键词
    for category_name, descriptions in category_materials.items():
        if len(descriptions) >= 3:  # 至少3个样本才分析
            keywords = extract_category_keywords(category_name, descriptions)
            if keywords:
                category_keywords[category_name] = keywords
    
    logger.info(f"✅ 为 {len(category_keywords)} 个分类生成了关键词")
    return category_keywords

def extract_category_keywords(category_name: str, descriptions: List[str]) -> List[str]:
    """为特定分类提取关键词"""
    keywords = set([category_name])  # 分类名本身
    
    # 提取所有描述中的词汇
    all_words = []
    for desc in descriptions:
        words = re.findall(r'[\u4e00-\u9fff]+|[A-Za-z]+', desc)
        all_words.extend(words)
    
    # 统计词频，选择高频词作为关键词
    word_counter = Counter(all_words)
    
    # 选择出现频率 >= 20% 的词作为关键词
    threshold = max(1, len(descriptions) * 0.2)
    for word, count in word_counter.items():
        if count >= threshold and len(word) >= 2:
            keywords.add(word)
    
    # 限制关键词数量
    return list(keywords)[:10]

def generate_extraction_rules_from_data(materials: List[Dict]) -> List[Dict]:
    """基于真实数据生成提取规则"""
    logger.info("🔧 基于真实数据生成提取规则...")
    
    rules = []
    
    # 分析所有描述，找出常见模式
    all_descriptions = []
    for material in materials:
        name = material.get('MATERIAL_NAME') or ''
        spec = material.get('SPECIFICATION') or ''
        material_type = material.get('MATERIAL_TYPE') or ''
        full_desc = f"{name} {spec} {material_type}".strip()
        if full_desc:
            all_descriptions.append(full_desc)
    
    # 1. 尺寸规格规则（基于实际数据模式）
    size_patterns = set()
    for desc in all_descriptions:
        # 查找各种尺寸表示
        patterns = re.findall(r'\b(?:M|Φ|φ|DN)?\d+(?:\.\d+)?[×*xX]\d+(?:\.\d+)?(?:[×*xX]\d+(?:\.\d+)?)?\b', desc)
        size_patterns.update(patterns)
    
    if size_patterns:
        rules.append({
            'rule_name': '真实数据_尺寸规格提取',
            'material_category': 'general',
            'attribute_name': 'size_specification',
            'regex_pattern': r'\b(?:M|Φ|φ|DN)?(\d+(?:\.\d+)?[×*xX]\d+(?:\.\d+)?(?:[×*xX]\d+(?:\.\d+)?)?)\b',
            'priority': 100,
            'description': f'基于{len(size_patterns)}个真实尺寸样本生成',
            'data_samples': list(size_patterns)[:5]
        })
    
    # 2. 材质规则（基于实际出现的材质）
    material_patterns = set()
    for desc in all_descriptions:
        patterns = re.findall(r'\b(304L?|316L?|201|430|不锈钢|碳钢|合金钢|铸铁|铸钢|铜|黄铜|青铜|铝|铝合金|钛|钛合金)\b', desc)
        material_patterns.update(patterns)
    
    if material_patterns:
        material_regex = '|'.join(re.escape(m) for m in material_patterns)
        rules.append({
            'rule_name': '真实数据_材质提取',
            'material_category': 'general',
            'attribute_name': 'material_type',
            'regex_pattern': f'\\b({material_regex})\\b',
            'priority': 90,
            'description': f'基于{len(material_patterns)}种真实材质样本生成',
            'data_samples': list(material_patterns)[:5]
        })
    
    # 3. 品牌规则（基于实际出现的品牌）
    brand_patterns = set()
    for desc in all_descriptions:
        # 查找可能的品牌（连续大写字母）
        patterns = re.findall(r'\b[A-Z]{2,}[A-Z0-9]*\b', desc)
        brand_patterns.update(patterns)
    
    # 过滤掉可能不是品牌的词（如单位、规格等）
    exclude_words = {'DN', 'PN', 'MPa', 'BAR', 'MM', 'KG', 'PCS', 'SET'}
    brand_patterns = brand_patterns - exclude_words
    
    if brand_patterns and len(brand_patterns) >= 5:
        brand_regex = '|'.join(re.escape(b) for b in list(brand_patterns)[:20])  # 限制数量
        rules.append({
            'rule_name': '真实数据_品牌提取',
            'material_category': 'general',
            'attribute_name': 'brand_name',
            'regex_pattern': f'\\b({brand_regex})\\b',
            'priority': 85,
            'description': f'基于{len(brand_patterns)}个真实品牌样本生成',
            'data_samples': list(brand_patterns)[:5]
        })
    
    # 4. 型号规则（基于实际型号模式）
    model_patterns = set()
    for desc in all_descriptions:
        # 查找型号模式（字母数字组合）
        patterns = re.findall(r'\b[A-Z0-9]{3,}(?:-[A-Z0-9]+)*\b', desc)
        model_patterns.update(patterns)
    
    # 过滤掉明显不是型号的词
    model_patterns = model_patterns - exclude_words - brand_patterns
    
    if model_patterns and len(model_patterns) >= 10:
        rules.append({
            'rule_name': '真实数据_型号提取',
            'material_category': 'general',
            'attribute_name': 'model_number',
            'regex_pattern': r'\b([A-Z0-9]{3,}(?:-[A-Z0-9]+)*)\b',
            'priority': 80,
            'description': f'基于{len(model_patterns)}个真实型号样本生成',
            'data_samples': list(model_patterns)[:5]
        })
    
    logger.info(f"✅ 基于真实数据生成了 {len(rules)} 条提取规则")
    return rules

def generate_synonym_mappings(materials: List[Dict], units: List[Dict]) -> Dict:
    """基于真实数据生成同义词映射"""
    logger.info("📚 基于真实数据生成同义词映射...")
    
    synonyms = {}
    
    # 1. 基于计量单位数据生成同义词
    for unit in units:
        unit_name = (unit.get('UNIT_NAME') or '').strip()
        unit_code = (unit.get('UNIT_CODE') or '').strip()
        english_name = (unit.get('ENGLISH_NAME') or '').strip()
        
        if unit_name:
            variants = []
            if unit_code and unit_code != unit_name:
                variants.append(unit_code)
            if english_name and english_name != unit_name:
                variants.append(english_name)
            
            if variants:
                synonyms[unit_name] = variants
    
    # 2. 基于物料描述中的变体生成同义词
    description_variants = defaultdict(set)
    
    for material in materials:
        name = material.get('MATERIAL_NAME') or ''
        spec = material.get('SPECIFICATION') or ''
        
        # 查找尺寸表示的变体
        size_matches = re.findall(r'\d+[×*xX]\d+', f"{name} {spec}")
        for match in size_matches:
            # 标准化为x格式
            normalized = re.sub(r'[×*X]', 'x', match)
            description_variants[normalized].add(match)
    
    # 转换为同义词格式
    for standard, variants in description_variants.items():
        if len(variants) > 1:
            synonyms[standard] = list(variants - {standard})
    
    logger.info(f"✅ 生成了 {len(synonyms)} 个同义词映射")
    return synonyms

def generate_statistics(materials: List[Dict], categories: List[Dict], units: List[Dict]) -> Dict:
    """生成统计信息"""
    logger.info("📊 生成统计信息...")
    
    stats = {
        'total_materials': len(materials),
        'total_categories': len(categories),
        'total_units': len(units),
        'category_distribution': {},
        'enable_state_distribution': {},
        'material_mgt_distribution': {}
    }
    
    # 分类分布
    category_counter = Counter()
    enable_state_counter = Counter()
    material_mgt_counter = Counter()
    
    for material in materials:
        category_name = material.get('CATEGORY_NAME', '未分类')
        enable_state = material.get('ENABLESTATE', 0)
        material_mgt = material.get('MATERIALMGT', 0)
        
        category_counter[category_name] += 1
        enable_state_counter[enable_state] += 1
        material_mgt_counter[material_mgt] += 1
    
    stats['category_distribution'] = dict(category_counter.most_common(10))
    stats['enable_state_distribution'] = dict(enable_state_counter)
    stats['material_mgt_distribution'] = dict(material_mgt_counter)
    
    return stats

def save_analysis_results(analysis: Dict):
    """保存分析结果"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    # 保存完整分析结果
    analysis_file = f"oracle_data_analysis_{timestamp}.json"
    with open(analysis_file, 'w', encoding='utf-8') as f:
        json.dump(analysis, f, ensure_ascii=False, indent=2, default=str)
    
    logger.info(f"💾 完整分析结果已保存: {analysis_file}")
    
    # 保存可读报告
    report_file = f"oracle_data_analysis_report_{timestamp}.md"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("# Oracle真实数据分析报告\n\n")
        f.write(f"**分析时间:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        
        # 统计信息
        stats = analysis['statistics']
        f.write("## 📊 数据统计\n\n")
        f.write(f"- **物料总数:** {stats['total_materials']:,}\n")
        f.write(f"- **分类总数:** {stats['total_categories']:,}\n")
        f.write(f"- **单位总数:** {stats['total_units']:,}\n\n")
        
        # 分类分布
        f.write("### 主要分类分布\n\n")
        for category, count in stats['category_distribution'].items():
            f.write(f"- {category}: {count:,} 条\n")
        f.write("\n")
        
        # 生成的关键词
        f.write("## 🏷️ 生成的类别关键词\n\n")
        for category, keywords in analysis['category_keywords'].items():
            f.write(f"### {category}\n")
            f.write(f"关键词: {', '.join(keywords)}\n\n")
        
        # 生成的规则
        f.write("## 🔧 生成的提取规则\n\n")
        for rule in analysis['extraction_rules']:
            f.write(f"### {rule['rule_name']}\n")
            f.write(f"- **属性:** {rule['attribute_name']}\n")
            f.write(f"- **正则:** `{rule['regex_pattern']}`\n")
            f.write(f"- **描述:** {rule['description']}\n")
            if 'data_samples' in rule:
                f.write(f"- **样本:** {', '.join(rule['data_samples'])}\n")
            f.write("\n")
        
        # 物料模式
        f.write("## 🔍 发现的物料模式\n\n")
        patterns = analysis['material_patterns']
        
        f.write("### 尺寸模式 (前10个)\n")
        for pattern, count in patterns['size_patterns'][:10]:
            f.write(f"- {pattern}: {count} 次\n")
        f.write("\n")
        
        f.write("### 品牌模式 (前10个)\n")
        for pattern, count in patterns['brand_patterns'][:10]:
            f.write(f"- {pattern}: {count} 次\n")
        f.write("\n")
        
        f.write("### 材质模式 (前10个)\n")
        for pattern, count in patterns['material_patterns'][:10]:
            f.write(f"- {pattern}: {count} 次\n")
        f.write("\n")
    
    logger.info(f"📄 可读分析报告已保存: {report_file}")
    
    return analysis_file, report_file

if __name__ == "__main__":
    logger.info("🚀 开始Oracle真实数据分析")
    success = analyze_oracle_data()
    
    if success:
        logger.info("🎉 Oracle数据分析完成！")
    else:
        logger.error("💥 Oracle数据分析失败！")
