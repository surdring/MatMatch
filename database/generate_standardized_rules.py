"""
基于Oracle真实数据生成标准化的规则和词典
将分析结果转换为可直接使用的规则和词典文件
"""

import json
import logging
from datetime import datetime
from typing import Dict, List
import re
import glob
import os

# 全角半角字符映射表
FULLWIDTH_TO_HALFWIDTH = {
    # 全角数字 → 半角数字
    '０': '0', '１': '1', '２': '2', '３': '3', '４': '4',
    '５': '5', '６': '6', '７': '7', '８': '8', '９': '9',
    # 全角字母 → 半角字母
    'Ａ': 'A', 'Ｂ': 'B', 'Ｃ': 'C', 'Ｄ': 'D', 'Ｅ': 'E', 'Ｆ': 'F',
    'Ｇ': 'G', 'Ｈ': 'H', 'Ｉ': 'I', 'Ｊ': 'J', 'Ｋ': 'K', 'Ｌ': 'L',
    'Ｍ': 'M', 'Ｎ': 'N', 'Ｏ': 'O', 'Ｐ': 'P', 'Ｑ': 'Q', 'Ｒ': 'R',
    'Ｓ': 'S', 'Ｔ': 'T', 'Ｕ': 'U', 'Ｖ': 'V', 'Ｗ': 'W', 'Ｘ': 'X',
    'Ｙ': 'Y', 'Ｚ': 'Z',
    'ａ': 'a', 'ｂ': 'b', 'ｃ': 'c', 'ｄ': 'd', 'ｅ': 'e', 'ｆ': 'f',
    'ｇ': 'g', 'ｈ': 'h', 'ｉ': 'i', 'ｊ': 'j', 'ｋ': 'k', 'ｌ': 'l',
    'ｍ': 'm', 'ｎ': 'n', 'ｏ': 'o', 'ｐ': 'p', 'ｑ': 'q', 'ｒ': 'r',
    'ｓ': 's', 'ｔ': 't', 'ｕ': 'u', 'ｖ': 'v', 'ｗ': 'w', 'ｘ': 'x',
    'ｙ': 'y', 'ｚ': 'z',
    # 全角符号 → 半角符号
    '×': 'x',      # 全角乘号 → 半角x
    '＊': '*',     # 全角星号 → 半角星号
    '（': '(',     # 全角左括号 → 半角左括号
    '）': ')',     # 全角右括号 → 半角右括号
    '［': '[',     # 全角左方括号 → 半角左方括号
    '］': ']',     # 全角右方括号 → 半角右方括号
    '－': '-',     # 全角减号 → 半角减号
    '＋': '+',     # 全角加号 → 半角加号
    '＝': '=',     # 全角等号 → 半角等号
    '／': '/',     # 全角斜杠 → 半角斜杠
    '：': ':',     # 全角冒号 → 半角冒号
    '；': ';',     # 全角分号 → 半角分号
    '，': ',',     # 全角逗号 → 半角逗号
    '．': '.',     # 全角句号 → 半角句号
    '　': ' ',     # 全角空格 → 半角空格
}

def cleanup_old_files():
    """清理旧的生成文件，保持目录整洁"""
    logger.info("🧹 清理旧的生成文件...")
    
    # 定义要清理的文件模式
    patterns = [
        'standardized_extraction_rules_*.json',
        'standardized_synonym_dictionary_*.json', 
        'standardized_category_keywords_*.json',
        'standardized_rules_usage_*.md'
    ]
    
    cleaned_count = 0
    for pattern in patterns:
        files = glob.glob(pattern)
        logger.info(f"  🔍 找到 {pattern} 匹配的文件: {files}")
        
        # 保留最新的文件（按文件名排序，最后一个是最新的）
        if len(files) > 1:
            files.sort()
            old_files = files[:-1]  # 除了最新的文件外，其他都是旧文件
            logger.info(f"  📋 将保留最新文件: {files[-1]}")
            logger.info(f"  🗑️ 将删除旧文件: {old_files}")
            
            for old_file in old_files:
                try:
                    os.remove(old_file)
                    logger.info(f"  ✅ 删除旧文件: {old_file}")
                    cleaned_count += 1
                except Exception as e:
                    logger.warning(f"  ⚠️ 删除文件失败 {old_file}: {e}")
        elif len(files) == 1:
            logger.info(f"  ✨ 只有一个文件，无需清理: {files[0]}")
        else:
            logger.info(f"  📭 没有找到匹配的文件")
    
    if cleaned_count > 0:
        logger.info(f"🎉 清理完成，删除了 {cleaned_count} 个旧文件")
    else:
        logger.info("✨ 目录已经是最新的，无需清理")

def normalize_fullwidth_to_halfwidth(text: str) -> str:
    """
    将文本中的全角字符转换为半角字符
    
    Args:
        text: 输入文本
        
    Returns:
        转换后的文本
    """
    if not text:
        return text
        
    result = text
    for fullwidth, halfwidth in FULLWIDTH_TO_HALFWIDTH.items():
        result = result.replace(fullwidth, halfwidth)
    
    return result

def normalize_text_standard(text: str) -> str:
    """
    标准文本标准化处理：全角半角转换 + 空格清理 + 大小写处理
    
    Args:
        text: 输入文本
        
    Returns:
        标准化后的文本
    """
    if not text:
        return text
    
    # 1. 全角半角转换
    result = normalize_fullwidth_to_halfwidth(text)
    
    # 2. 去除首尾空格
    result = result.strip()
    
    # 3. 将多个连续空格替换为单个空格
    result = re.sub(r'\s+', ' ', result)
    
    return result

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def generate_standardized_rules():
    """生成标准化的规则和词典（增强版：支持全角半角字符处理）"""
    logger.info("🔧 开始生成标准化规则和词典（全角半角增强版）...")
    
    # 读取最新的分析结果
    analysis_file = "oracle_data_analysis_20251002_184248.json"
    
    with open(analysis_file, 'r', encoding='utf-8') as f:
        analysis_data = json.load(f)
    
    logger.info(f"✅ 已加载分析数据: {analysis_file}")
    logger.info("🈶 启用全角半角字符标准化处理...")
    
    # 1. 生成标准化提取规则
    extraction_rules = generate_extraction_rules(analysis_data)
    
    # 2. 生成标准化同义词典
    synonym_dictionary = generate_synonym_dictionary(analysis_data)
    
    # 3. 生成物料类别关键词
    category_keywords = generate_category_keywords(analysis_data)
    
    # 4. 保存标准化文件
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    # 保存提取规则
    rules_file = f"standardized_extraction_rules_{timestamp}.json"
    with open(rules_file, 'w', encoding='utf-8') as f:
        json.dump(extraction_rules, f, ensure_ascii=False, indent=2)
    logger.info(f"💾 提取规则已保存: {rules_file}")
    
    # 保存同义词典
    dict_file = f"standardized_synonym_dictionary_{timestamp}.json"
    with open(dict_file, 'w', encoding='utf-8') as f:
        json.dump(synonym_dictionary, f, ensure_ascii=False, indent=2)
    logger.info(f"💾 同义词典已保存: {dict_file}")
    
    # 保存类别关键词
    keywords_file = f"standardized_category_keywords_{timestamp}.json"
    with open(keywords_file, 'w', encoding='utf-8') as f:
        json.dump(category_keywords, f, ensure_ascii=False, indent=2)
    logger.info(f"💾 类别关键词已保存: {keywords_file}")
    
    # 生成使用说明文档
    generate_usage_documentation(extraction_rules, synonym_dictionary, category_keywords, timestamp)
    
    return {
        'rules_file': rules_file,
        'dictionary_file': dict_file,
        'keywords_file': keywords_file,
        'total_rules': len(extraction_rules),
        'total_synonyms': sum(len(variants) for variants in synonym_dictionary.values()),
        'total_categories': len(category_keywords)
    }

def generate_extraction_rules(analysis_data: Dict) -> List[Dict]:
    """生成标准化的提取规则"""
    logger.info("🔧 生成标准化提取规则...")
    
    rules = []
    
    # 基于真实数据的尺寸模式
    size_patterns = analysis_data['material_patterns']['size_patterns']
    if size_patterns:
        # 分析最常见的尺寸格式
        common_sizes = [pattern[0] for pattern in size_patterns[:100]]  # 取前100个
        
        rules.append({
            'id': 'size_spec_metric',
            'name': '公制尺寸规格提取',
            'category': 'general',
            'attribute': 'size_specification',
            'pattern': r'(?:M|Φ|φ|DN|Ｍ|ＤＮ)?(\d+(?:\.\d+)?[×*xX×＊ｘＸ]\d+(?:\.\d+)?(?:[×*xX×＊ｘＸ]\d+(?:\.\d+)?)?)',
            'priority': 100,
            'description': f'基于{len(size_patterns)}个真实尺寸样本，支持全角半角字符的公制尺寸规格提取',
            'examples': common_sizes[:5],
            'data_source': 'oracle_real_data',
            'confidence': 0.95
        })
        
        rules.append({
            'id': 'thread_spec',
            'name': '螺纹规格提取',
            'category': 'fastener',
            'attribute': 'thread_specification',
            'pattern': r'(M|Ｍ)(\d+(?:\.\d+)?)[×*xX×＊ｘＸ](\d+(?:\.\d+)?)',
            'priority': 95,
            'description': '提取螺纹规格如M20*1.5，支持全角半角字符',
            'examples': [p[0] for p in size_patterns if p[0].startswith('M')][:5],
            'data_source': 'oracle_real_data',
            'confidence': 0.98
        })
    
    # 基于真实数据的材质模式
    material_patterns = analysis_data['material_patterns']['material_patterns']
    if material_patterns:
        common_materials = [pattern[0] for pattern in material_patterns[:50]]
        material_regex = '|'.join(re.escape(m) for m in common_materials)
        
        rules.append({
            'id': 'material_type',
            'name': '材质类型提取',
            'category': 'general',
            'attribute': 'material_type',
            'pattern': f'({material_regex})',
            'priority': 90,
            'description': f'基于{len(material_patterns)}种真实材质样本',
            'examples': common_materials[:5],
            'data_source': 'oracle_real_data',
            'confidence': 0.92
        })
    
    # 基于真实数据的品牌模式
    brand_patterns = analysis_data['material_patterns']['brand_patterns']
    if brand_patterns:
        # 过滤掉明显不是品牌的词（如DN、PN等规格标识）
        exclude_words = {'DN', 'PN', 'MPa', 'BAR', 'MM', 'KG', 'PCS', 'SET', 'GB', 'JB', 'HG'}
        real_brands = [p[0] for p in brand_patterns if p[0] not in exclude_words and len(p[0]) >= 3][:100]
        
        if real_brands:
            brand_regex = '|'.join(re.escape(b) for b in real_brands)
            rules.append({
                'id': 'brand_name',
                'name': '品牌名称提取',
                'category': 'general',
                'attribute': 'brand_name',
                'pattern': f'\\b({brand_regex})\\b',
                'priority': 85,
                'description': f'基于{len(real_brands)}个真实品牌样本',
                'examples': real_brands[:5],
                'data_source': 'oracle_real_data',
                'confidence': 0.88
            })
    
    # 压力等级提取规则
    rules.append({
        'id': 'pressure_rating',
        'name': '压力等级提取',
        'category': 'valve',
        'attribute': 'pressure_rating',
        'pattern': r'(PN\d+|(?:\d+(?:\.\d+)?(?:MPa|bar|公斤|kg)))',
        'priority': 88,
        'description': '提取压力等级如PN16, 1.6MPa',
        'examples': ['PN16', '1.6MPa', '10bar'],
        'data_source': 'pattern_analysis',
        'confidence': 0.90
    })
    
    # 公称直径提取规则
    rules.append({
        'id': 'nominal_diameter',
        'name': '公称直径提取',
        'category': 'pipe',
        'attribute': 'nominal_diameter',
        'pattern': r'(DN\d+|Φ\d+)',
        'priority': 87,
        'description': '提取公称直径如DN50, Φ100',
        'examples': ['DN50', 'DN100', 'Φ50'],
        'data_source': 'pattern_analysis',
        'confidence': 0.95
    })
    
    logger.info(f"✅ 生成了 {len(rules)} 条标准化提取规则")
    return rules

def generate_synonym_dictionary(analysis_data: Dict) -> Dict[str, List[str]]:
    """生成标准化同义词典"""
    logger.info("📚 生成标准化同义词典...")
    
    synonyms = {}
    
    # 从分析数据中提取同义词映射（应用文本标准化）
    if 'synonym_mappings' in analysis_data:
        base_synonyms = analysis_data['synonym_mappings']
        # 对同义词进行标准化处理
        normalized_synonyms = {}
        for key, values in base_synonyms.items():
            normalized_key = normalize_text_standard(key)
            normalized_values = [normalize_text_standard(v) for v in values if normalize_text_standard(v)]
            if normalized_key and normalized_values:
                normalized_synonyms[normalized_key] = normalized_values
        synonyms.update(normalized_synonyms)
    
    # 添加基于尺寸模式的同义词
    size_patterns = analysis_data['material_patterns']['size_patterns']
    size_synonyms = {}
    
    for pattern, count in size_patterns:
        if count >= 10:  # 只处理出现频率较高的模式
            # 标准化尺寸表示（支持全角半角）
            normalized = re.sub(r'[×*XxＸｘ＊]', 'x', pattern)
            variants = []
            
            # 生成变体（包括全角字符）
            if 'x' in normalized:
                variants.append(pattern.replace('x', '×'))  # 全角乘号
                variants.append(pattern.replace('x', '*'))  # 半角星号
                variants.append(pattern.replace('x', 'X'))  # 半角大写X
                variants.append(pattern.replace('x', '＊')) # 全角星号
                variants.append(pattern.replace('x', 'Ｘ')) # 全角大写X
                variants.append(pattern.replace('x', 'ｘ')) # 全角小写x
            
            if variants:
                size_synonyms[normalized] = list(set(variants))
    
    synonyms.update(size_synonyms)
    
    # 添加全角半角字符同义词
    fullwidth_halfwidth_synonyms = {}
    for fullwidth, halfwidth in FULLWIDTH_TO_HALFWIDTH.items():
        fullwidth_halfwidth_synonyms[halfwidth] = [fullwidth]
    
    synonyms.update(fullwidth_halfwidth_synonyms)
    
    # 添加常见的材质同义词（包含大小写变体）
    material_synonyms = {
        '不锈钢': ['304', '316', '316L', 'SS', 'ss', 'stainless steel', 'Stainless Steel', 'STAINLESS STEEL'],
        '碳钢': ['CS', 'cs', 'carbon steel', 'Carbon Steel', 'CARBON STEEL', 'A105', '20#'],
        '合金钢': ['alloy steel', 'Alloy Steel', 'ALLOY STEEL', '40Cr', '40cr', '42CrMo', '42crmo'],
        '铸铁': ['cast iron', 'Cast Iron', 'CAST IRON', 'CI', 'ci', 'HT200', 'ht200', 'HT250', 'ht250'],
        '铜': ['黄铜', 'Cu', 'cu', 'CU', 'copper', 'Copper', 'COPPER', 'brass', 'Brass', 'BRASS'],
        '铝': ['铝合金', 'Al', 'al', 'AL', 'aluminum', 'Aluminum', 'ALUMINUM', 'aluminium', 'Aluminium', 'ALUMINIUM']
    }
    synonyms.update(material_synonyms)
    
    # 添加品牌名称大小写变体同义词
    brand_case_synonyms = {}
    common_brands = ['SKF', 'NSK', 'FAG', 'NTN', 'TIMKEN', 'INA', 'KOYO', 'NACHI', 'THK', 'IKO']
    for brand in common_brands:
        variants = []
        if brand.lower() != brand:
            variants.append(brand.lower())
        if brand.title() != brand:
            variants.append(brand.title())
        if variants:
            brand_case_synonyms[brand] = variants
    
    synonyms.update(brand_case_synonyms)
    
    # 添加单位同义词（包括全角半角变体）
    unit_synonyms = {
        'mm': ['毫米', 'MM', 'ｍｍ', 'ＭＭ'],
        'kg': ['公斤', '千克', 'KG', 'ｋｇ', 'ＫＧ'],
        'MPa': ['兆帕', 'Mpa', 'mpa', 'ＭＰａ', 'ｍｐａ'],
        'bar': ['巴', 'Bar', 'BAR', 'ｂａｒ', 'ＢＡＲ'],
        '个': ['只', '件', '套', 'pcs', 'PCS', 'ｐｃｓ', 'ＰＣＳ'],
        'DN': ['公称直径', 'dn', 'ＤＮ', 'ｄｎ'],
        'PN': ['公称压力', 'pn', 'ＰＮ', 'ｐｎ']
    }
    synonyms.update(unit_synonyms)
    
    # 统计全角半角同义词数量
    fullwidth_count = sum(1 for v in synonyms.values() if any(char in FULLWIDTH_TO_HALFWIDTH for char in str(v)))
    
    logger.info(f"✅ 生成了 {len(synonyms)} 个同义词组")
    logger.info(f"🈶 其中包含 {len(fullwidth_halfwidth_synonyms)} 个全角半角字符映射")
    return synonyms

def generate_category_keywords(analysis_data: Dict) -> Dict[str, Dict]:
    """生成标准化类别关键词"""
    logger.info("🏷️ 生成标准化类别关键词...")
    
    category_keywords = {}
    
    # 从分析数据中提取类别关键词
    if 'category_keywords' in analysis_data:
        raw_keywords = analysis_data['category_keywords']
        
        for category, keywords in raw_keywords.items():
            if len(keywords) >= 2:  # 至少有2个关键词的分类
                category_keywords[category] = {
                    'keywords': keywords,
                    'detection_confidence': 0.8,
                    'category_type': detect_category_type(category, keywords),
                    'priority': calculate_category_priority(category, keywords)
                }
    
    # 添加标准的物料类别
    standard_categories = {
        '轴承': {
            'keywords': ['轴承', 'bearing', '滚动轴承', '滑动轴承', '深沟球', '圆锥滚子'],
            'detection_confidence': 0.95,
            'category_type': 'mechanical',
            'priority': 100
        },
        '螺栓': {
            'keywords': ['螺栓', '螺钉', '螺丝', 'bolt', 'screw', '内六角', '外六角'],
            'detection_confidence': 0.95,
            'category_type': 'fastener',
            'priority': 100
        },
        '阀门': {
            'keywords': ['阀', '阀门', 'valve', '球阀', '闸阀', '截止阀', '蝶阀'],
            'detection_confidence': 0.95,
            'category_type': 'valve',
            'priority': 100
        },
        '管件': {
            'keywords': ['管', '管道', '管件', 'pipe', 'tube', '弯头', '三通', '四通'],
            'detection_confidence': 0.95,
            'category_type': 'pipe',
            'priority': 100
        },
        '电气': {
            'keywords': ['接触器', '继电器', '断路器', '变频器', 'contactor', 'relay'],
            'detection_confidence': 0.90,
            'category_type': 'electrical',
            'priority': 90
        }
    }
    
    # 合并标准类别
    for category, info in standard_categories.items():
        if category not in category_keywords:
            category_keywords[category] = info
    
    logger.info(f"✅ 生成了 {len(category_keywords)} 个类别关键词组")
    return category_keywords

def detect_category_type(category: str, keywords: List[str]) -> str:
    """检测类别类型"""
    category_lower = category.lower()
    keywords_str = ' '.join(keywords).lower()
    
    if any(word in category_lower or word in keywords_str for word in ['轴承', 'bearing']):
        return 'bearing'
    elif any(word in category_lower or word in keywords_str for word in ['螺栓', '螺钉', 'bolt', 'screw']):
        return 'fastener'
    elif any(word in category_lower or word in keywords_str for word in ['阀', 'valve']):
        return 'valve'
    elif any(word in category_lower or word in keywords_str for word in ['管', 'pipe', 'tube']):
        return 'pipe'
    elif any(word in category_lower or word in keywords_str for word in ['电', 'electrical']):
        return 'electrical'
    else:
        return 'general'

def calculate_category_priority(category: str, keywords: List[str]) -> int:
    """计算类别优先级"""
    # 基于关键词数量和类别重要性
    base_priority = len(keywords) * 10
    
    # 重要类别加权
    important_categories = ['轴承', '螺栓', '阀门', '管件', '电气']
    if any(imp in category for imp in important_categories):
        base_priority += 20
    
    return min(base_priority, 100)

def generate_usage_documentation(rules: List[Dict], synonyms: Dict, categories: Dict, timestamp: str):
    """生成使用说明文档"""
    doc_file = f"standardized_rules_usage_{timestamp}.md"
    
    with open(doc_file, 'w', encoding='utf-8') as f:
        f.write("# 标准化规则和词典使用说明\n\n")
        f.write(f"**生成时间:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"**数据来源:** Oracle ERP系统 (230,421条物料数据)\n\n")
        
        f.write("## 📊 生成统计\n\n")
        f.write(f"- **提取规则**: {len(rules)} 条\n")
        f.write(f"- **同义词组**: {len(synonyms)} 组\n")
        f.write(f"- **类别关键词**: {len(categories)} 个类别\n\n")
        
        f.write("## 🔧 提取规则说明\n\n")
        for rule in rules:
            f.write(f"### {rule['name']}\n")
            f.write(f"- **ID**: `{rule['id']}`\n")
            f.write(f"- **类别**: {rule['category']}\n")
            f.write(f"- **属性**: {rule['attribute']}\n")
            f.write(f"- **正则表达式**: `{rule['pattern']}`\n")
            f.write(f"- **优先级**: {rule['priority']}\n")
            f.write(f"- **置信度**: {rule['confidence']}\n")
            f.write(f"- **描述**: {rule['description']}\n")
            if 'examples' in rule:
                f.write(f"- **示例**: {', '.join(rule['examples'])}\n")
            f.write("\n")
        
        f.write("## 📚 同义词典使用\n\n")
        f.write("同义词典按类型组织，支持以下转换：\n\n")
        
        # 按类型分组显示同义词
        size_synonyms = {k: v for k, v in synonyms.items() if 'x' in k or '×' in k or '*' in k}
        material_synonyms = {k: v for k, v in synonyms.items() if k in ['不锈钢', '碳钢', '合金钢', '铸铁', '铜', '铝']}
        unit_synonyms = {k: v for k, v in synonyms.items() if k in ['mm', 'kg', 'MPa', 'bar', '个', 'DN', 'PN']}
        
        if size_synonyms:
            f.write("### 尺寸规格同义词\n")
            for standard, variants in list(size_synonyms.items())[:10]:
                f.write(f"- `{standard}` ← {', '.join(variants)}\n")
            f.write("\n")
        
        if material_synonyms:
            f.write("### 材质同义词\n")
            for standard, variants in material_synonyms.items():
                f.write(f"- `{standard}` ← {', '.join(variants)}\n")
            f.write("\n")
        
        if unit_synonyms:
            f.write("### 单位同义词\n")
            for standard, variants in unit_synonyms.items():
                f.write(f"- `{standard}` ← {', '.join(variants)}\n")
            f.write("\n")
        
        f.write("## 🏷️ 类别检测使用\n\n")
        high_priority_categories = {k: v for k, v in categories.items() if v['priority'] >= 90}
        
        for category, info in high_priority_categories.items():
            f.write(f"### {category}\n")
            f.write(f"- **关键词**: {', '.join(info['keywords'])}\n")
            f.write(f"- **类型**: {info['category_type']}\n")
            f.write(f"- **置信度**: {info['detection_confidence']}\n")
            f.write(f"- **优先级**: {info['priority']}\n")
            f.write("\n")
    
    logger.info(f"📄 使用说明文档已保存: {doc_file}")

if __name__ == "__main__":
    logger.info("🚀 开始生成标准化规则和词典")
    
    # 清理旧文件
    cleanup_old_files()
    
    result = generate_standardized_rules()
    
    logger.info("🎉 标准化规则和词典生成完成！")
    logger.info(f"📊 生成统计:")
    logger.info(f"  - 提取规则: {result['total_rules']} 条")
    logger.info(f"  - 同义词: {result['total_synonyms']} 个")
    logger.info(f"  - 类别: {result['total_categories']} 个")
    logger.info(f"📁 输出文件:")
    logger.info(f"  - 规则文件: {result['rules_file']}")
    logger.info(f"  - 词典文件: {result['dictionary_file']}")
    logger.info(f"  - 关键词文件: {result['keywords_file']}")
