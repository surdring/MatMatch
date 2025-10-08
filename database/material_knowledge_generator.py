"""
物料知识库生成器 v3.0 - 仅支持PostgreSQL清洗后数据

核心设计原则：
1. **单一数据源**：仅从PostgreSQL加载已清洗的数据
2. **对称处理保证**：生成的规则天然匹配13条清洗规则的输出
3. **Oracle角色明确**：Oracle仅用于ETL初始导入，不参与知识库生成

数据流架构：
Oracle ERP → ETL清洗 → PostgreSQL materials_master → 知识库生成器 → 规则表

自动生成：
1. 属性提取规则（基于清洗后的specification、normalized_name）
2. 同义词词典（基于清洗后的material_name）
3. 分类关键词（基于清洗后的category_name和normalized_name）

这确保了在线API和ETL使用完全一致的数据和规则
"""

import re
import json
import logging
from collections import defaultdict, Counter
from typing import Dict, List, Set, Tuple, Optional
from datetime import datetime
import pandas as pd
import os
import sys

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(__file__))

def normalize_text_comprehensive(text: str) -> str:
    """
    综合文本标准化处理：大小写标准化 + 空格清理
    
    这是项目的核心标准化函数，ETL和API都必须使用此函数
    实现"对称处理"原则
    
    Args:
        text: 输入文本
        
    Returns:
        标准化后的文本
    """
    if not text:
        return text
    
    # 1. 去除首尾空格
    result = text.strip()
    
    # 2. 将多个连续空格替换为单个空格
    result = re.sub(r'\s+', ' ', result)
    
    # 3. 标准化常见的大小写问题（保持品牌名等的正确大小写）
    # 这里不做全局大小写转换，因为品牌名等需要保持原有大小写
    
    return result

def normalize_fullwidth_to_halfwidth(text: str) -> str:
    """
    全角转半角标准化函数
    
    这是项目的核心标准化函数，ETL和API都必须使用此函数
    实现"对称处理"原则
    """
    if not text:
        return text
    
    # 全角到半角的映射表
    FULLWIDTH_TO_HALFWIDTH = {
        '０': '0', '１': '1', '２': '2', '３': '3', '４': '4',
        '５': '5', '６': '6', '７': '7', '８': '8', '９': '9',
        'Ａ': 'A', 'Ｂ': 'B', 'Ｃ': 'C', 'Ｄ': 'D', 'Ｅ': 'E',
        'Ｆ': 'F', 'Ｇ': 'G', 'Ｈ': 'H', 'Ｉ': 'I', 'Ｊ': 'J',
        'Ｋ': 'K', 'Ｌ': 'L', 'Ｍ': 'M', 'Ｎ': 'N', 'Ｏ': 'O',
        'Ｐ': 'P', 'Ｑ': 'Q', 'Ｒ': 'R', 'Ｓ': 'S', 'Ｔ': 'T',
        'Ｕ': 'U', 'Ｖ': 'V', 'Ｗ': 'W', 'Ｘ': 'X', 'Ｙ': 'Y', 'Ｚ': 'Z',
        'ａ': 'a', 'ｂ': 'b', 'ｃ': 'c', 'ｄ': 'd', 'ｅ': 'e',
        'ｆ': 'f', 'ｇ': 'g', 'ｈ': 'h', 'ｉ': 'i', 'ｊ': 'j',
        'ｋ': 'k', 'ｌ': 'l', 'ｍ': 'm', 'ｎ': 'n', 'ｏ': 'o',
        'ｐ': 'p', 'ｑ': 'q', 'ｒ': 'r', 'ｓ': 's', 'ｔ': 't',
        'ｕ': 'u', 'ｖ': 'v', 'ｗ': 'w', 'ｘ': 'x', 'ｙ': 'y', 'ｚ': 'z',
        '×': 'x', '＊': '*', '－': '-', '＋': '+', '＝': '=',
        '（': '(', '）': ')', '［': '[', '］': ']', '｛': '{', '｝': '}',
        '：': ':', '；': ';', '，': ',', '．': '.', '？': '?', '！': '!',
        '　': ' '  # 全角空格转半角空格
    }
    
    result = text
    for fullwidth, halfwidth in FULLWIDTH_TO_HALFWIDTH.items():
        result = result.replace(fullwidth, halfwidth)
    
    return result

def generate_case_variants(text: str) -> List[str]:
    """
    生成文本的大小写变体
    
    这是项目的核心标准化函数，用于生成同义词词典
    
    Args:
        text: 输入文本
        
    Returns:
        大小写变体列表
    """
    if not text:
        return []
    
    variants = [text]  # 原文本
    
    # 全小写
    lower_text = text.lower()
    if lower_text != text:
        variants.append(lower_text)
    
    # 全大写
    upper_text = text.upper()
    if upper_text != text:
        variants.append(upper_text)
    
    # 首字母大写
    title_text = text.title()
    if title_text != text and title_text not in variants:
        variants.append(title_text)
    
    return variants

# 配置日志
import os
# 创建日志目录
log_dir = 'logs'
os.makedirs(log_dir, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'{log_dir}/material_knowledge_generation_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class MaterialKnowledgeGenerator:
    """
    物料知识库生成器 (统一版本)
    
    这是项目的核心数据处理类，负责：
    1. 连接Oracle数据库
    2. 分析物料数据模式
    3. 生成提取规则
    4. 生成同义词词典
    5. 生成分类关键词
    
    实现"对称处理"原则，确保所有数据处理使用统一标准
    """
    
    def __init__(self, pg_session):
        """
        初始化知识库生成器（仅支持PostgreSQL清洗后数据）
        
        Args:
            pg_session: PostgreSQL异步会话（用于加载清洗后的数据）
            
        设计原则：
            知识库生成必须基于PostgreSQL中已清洗的数据，确保：
            1. 生成的规则天然匹配13条清洗规则的输出
            2. 单一数据源，避免不一致
            3. Oracle仅用于ETL初始导入，不参与知识库生成
        """
        if pg_session is None:
            raise ValueError("必须提供PostgreSQL会话，知识库生成器只支持清洗后的数据")
        
        self.pg_session = pg_session
        self.materials_data = []
        self.categories_data = []
        self.units_data = []
        
        # 动态生成的物料类别关键词（基于清洗后数据）
        # 这将在 load_all_data() 中通过分析真实物料数据生成
        self.category_keywords = {}
    
    async def load_all_data(self):
        """加载PostgreSQL清洗后的数据"""
        logger.info("=" * 80)
        logger.info("🚀 物料知识库生成器启动（基于PostgreSQL清洗后数据）")
        logger.info("=" * 80)
        logger.info("🔄 开始从PostgreSQL加载清洗后的数据...")
        await self._load_from_postgresql()
    
    async def _load_from_postgresql(self):
        """从PostgreSQL加载清洗后的数据（推荐模式）"""
        from sqlalchemy import text
        
        try:
            # 加载物料数据（使用清洗后的字段）
            logger.info("📊 从materials_master表加载清洗后的物料数据...")
            result = await self.pg_session.execute(text("""
                SELECT 
                    erp_code,
                    material_name,
                    specification,
                    normalized_name,        -- 清洗后的名称
                    full_description,       -- 清洗后的完整描述
                    detected_category,
                    category_name,
                    unit_name
                FROM materials_master
                WHERE specification IS NOT NULL 
                  AND specification != ''
            """))
            
            rows = result.fetchall()
            self.materials_data = [
                {
                    'erp_code': row[0],
                    'material_name': row[1],
                    'specification': row[2],          # 已清洗
                    'normalized_name': row[3],        # 已清洗
                    'full_description': row[4],       # 已清洗
                    'detected_category': row[5],
                    'category_name': row[6],
                    'unit_name': row[7]
                }
                for row in rows
            ]
            logger.info(f"✅ 已加载 {len(self.materials_data):,} 条清洗后的物料数据")
            
            # 加载分类数据
            logger.info("📂 加载分类数据...")
            result = await self.pg_session.execute(text("""
                SELECT DISTINCT category_name
                FROM materials_master
                WHERE category_name IS NOT NULL
            """))
            self.categories_data = [{'name': row[0]} for row in result.fetchall()]
            logger.info(f"✅ 已加载 {len(self.categories_data):,} 个物料分类")
            
            # 加载单位数据
            logger.info("📏 加载计量单位数据...")
            result = await self.pg_session.execute(text("""
                SELECT DISTINCT unit_name
                FROM materials_master
                WHERE unit_name IS NOT NULL
            """))
            self.units_data = [{'name': row[0]} for row in result.fetchall()]
            logger.info(f"✅ 已加载 {len(self.units_data):,} 个计量单位")
            
            # 生成基于清洗后数据的分类关键词
            logger.info("🏷️ 基于清洗后数据生成分类关键词...")
            self.category_keywords = self._generate_category_keywords_from_data()
            logger.info(f"✅ 已生成 {len(self.category_keywords):,} 个分类的关键词")
            
        except Exception as e:
            logger.error(f"❌ 从PostgreSQL加载数据失败: {e}")
            raise
    
    
    def generate_extraction_rules(self) -> List[Dict]:
        """
        基于真实数据生成属性提取规则
        
        这些规则将被ETL和API共同使用，实现"对称处理"
        """
        logger.info("🔧 开始基于真实数据生成属性提取规则...")
        
        rules = []
        
        if not self.materials_data:
            logger.warning("⚠️ 没有物料数据，无法生成规则")
            return rules
        
        # 分析物料描述模式
        patterns = self._analyze_description_patterns()
        
        # 1. 基于数据分析生成通用规则
        general_rules = self._generate_general_rules_from_data()
        rules.extend(general_rules)
        
        # 2. 基于分类数据生成类别特定规则
        category_rules = self._generate_category_specific_rules()
        rules.extend(category_rules)
        
        # 3. 基于物料数据生成品牌提取规则
        brand_rules = self._generate_brand_rules()
        rules.extend(brand_rules)
        
        # 4. 基于物料数据生成材质提取规则
        material_rules = self._generate_material_rules()
        rules.extend(material_rules)
        
        # 注意：不再为规则添加ID字段，数据库导入时会自动生成自增ID
        # 符合Design.md中 extraction_rules 表的 id SERIAL PRIMARY KEY 定义
        
        logger.info(f"✅ 基于真实数据生成了 {len(rules)} 条属性提取规则")
        return rules
    
    def generate_synonym_dictionary(self) -> Dict[str, List[str]]:
        """
        基于真实数据生成同义词典
        
        这个词典将被ETL和API共同使用，实现"对称处理"
        返回格式：{标准词: [同义词列表]}
        """
        logger.info("📚 开始基于真实数据生成同义词典...")
        
        synonym_dict = {}
        
        if not self.materials_data:
            logger.warning("⚠️ 没有物料数据，无法生成同义词典")
            return synonym_dict
        
        # 1. 全角半角映射
        fullwidth_synonyms = self._generate_fullwidth_synonyms()
        synonym_dict.update(fullwidth_synonyms)
        
        # 2. 基于物料名称分析生成同义词
        name_variations = self._analyze_name_variations()
        synonym_dict.update(name_variations)
        
        # 3. 基于单位数据生成单位同义词
        unit_synonyms = self._generate_unit_synonyms()
        synonym_dict.update(unit_synonyms)
        
        # 4. 基于规格数据生成规格表示同义词
        spec_synonyms = self._analyze_spec_variations()
        synonym_dict.update(spec_synonyms)
        
        # 5. 基于品牌数据生成品牌同义词
        brand_synonyms = self._generate_brand_synonyms()
        synonym_dict.update(brand_synonyms)
        
        # 6. 基于材质数据生成材质同义词
        material_synonyms = self._generate_material_synonyms()
        synonym_dict.update(material_synonyms)
        
        logger.info(f"✅ 基于真实数据生成了 {len(synonym_dict)} 个同义词组")
        return synonym_dict
    
    def generate_synonym_records(self) -> List[Dict]:
        """
        生成扁平的同义词记录列表，适合直接导入数据库
        
        将嵌套的同义词字典转换为扁平的记录列表
        符合Design.md中 synonyms 表的结构定义
        
        Returns:
            List[Dict]: 同义词记录列表，每条记录包含：
                - original_term: 原始词汇（同义词）
                - standard_term: 标准词汇
                - category: 词汇类别
                - synonym_type: 同义词类型
                - confidence: 映射置信度
        """
        logger.info("🔄 将同义词字典转换为数据库记录格式...")
        
        synonym_dict = self.generate_synonym_dictionary()
        records = []
        
        for standard_term, synonym_list in synonym_dict.items():
            for original_term in synonym_list:
                # 判断同义词类型
                synonym_type = 'general'
                if any(unit in standard_term.lower() for unit in ['mm', '米', '克', '斤', 'kg']):
                    synonym_type = 'unit'
                elif any(mat in standard_term for mat in ['304', '316', '不锈钢', '碳钢', '铜', '铝']):
                    synonym_type = 'material'
                elif standard_term.isupper() and len(standard_term) >= 2:
                    synonym_type = 'brand'
                elif any(char in standard_term for char in ['×', 'x', '*']):
                    synonym_type = 'specification'
                
                records.append({
                    'original_term': original_term,
                    'standard_term': standard_term,
                    'category': 'general',  # 默认类别
                    'synonym_type': synonym_type,
                    'confidence': 1.0
                })
        
        logger.info(f"✅ 生成了 {len(records)} 条同义词记录")
        return records
    
    def _generate_fullwidth_synonyms(self) -> Dict[str, List[str]]:
        """生成全角半角同义词映射"""
        fullwidth_synonyms = {}
        
        # 基于FULLWIDTH_TO_HALFWIDTH映射生成同义词
        FULLWIDTH_TO_HALFWIDTH = {
            '０': '0', '１': '1', '２': '2', '３': '3', '４': '4',
            '５': '5', '６': '6', '７': '7', '８': '8', '９': '9',
            'Ａ': 'A', 'Ｂ': 'B', 'Ｃ': 'C', 'Ｄ': 'D', 'Ｅ': 'E',
            'Ｆ': 'F', 'Ｇ': 'G', 'Ｈ': 'H', 'Ｉ': 'I', 'Ｊ': 'J',
            'Ｋ': 'K', 'Ｌ': 'L', 'Ｍ': 'M', 'Ｎ': 'N', 'Ｏ': 'O',
            'Ｐ': 'P', 'Ｑ': 'Q', 'Ｒ': 'R', 'Ｓ': 'S', 'Ｔ': 'T',
            'Ｕ': 'U', 'Ｖ': 'V', 'Ｗ': 'W', 'Ｘ': 'X', 'Ｙ': 'Y', 'Ｚ': 'Z',
            'ａ': 'a', 'ｂ': 'b', 'ｃ': 'c', 'ｄ': 'd', 'ｅ': 'e',
            'ｆ': 'f', 'ｇ': 'g', 'ｈ': 'h', 'ｉ': 'i', 'ｊ': 'j',
            'ｋ': 'k', 'ｌ': 'l', 'ｍ': 'm', 'ｎ': 'n', 'ｏ': 'o',
            'ｐ': 'p', 'ｑ': 'q', 'ｒ': 'r', 'ｓ': 's', 'ｔ': 't',
            'ｕ': 'u', 'ｖ': 'v', 'ｗ': 'w', 'ｘ': 'x', 'ｙ': 'y', 'ｚ': 'z',
            '×': 'x', '＊': '*', '－': '-', '＋': '+', '＝': '=',
        }
        
        for fullwidth, halfwidth in FULLWIDTH_TO_HALFWIDTH.items():
            fullwidth_synonyms[halfwidth] = [fullwidth]
        
        return fullwidth_synonyms
    
    def _analyze_description_patterns(self) -> Dict[str, List[str]]:
        """分析物料描述中的常见模式"""
        patterns = defaultdict(list)
        
        for material in self.materials_data:
            name = material.get('MATERIAL_NAME', '')
            spec = material.get('SPECIFICATION', '')
            model = material.get('MODEL', '')
            
            # 应用标准化处理
            name = normalize_fullwidth_to_halfwidth(normalize_text_comprehensive(name))
            spec = normalize_fullwidth_to_halfwidth(normalize_text_comprehensive(spec))
            model = normalize_fullwidth_to_halfwidth(normalize_text_comprehensive(model))
            
            # 分析完整描述
            full_desc = f"{name} {spec} {model}".strip()
            
            # 提取数字+字母的模式（可能是型号）
            model_patterns = re.findall(r'\b[A-Z0-9]{3,}(?:-[A-Z0-9]+)?\b', full_desc.upper())
            patterns['models'].extend(model_patterns)
            
            # 提取尺寸模式（支持全角半角）
            size_patterns = re.findall(r'\b\d+(?:\.\d+)?[×*xX×＊ｘＸ]\d+(?:\.\d+)?(?:[×*xX×＊ｘＸ]\d+(?:\.\d+)?)?\b', full_desc)
            patterns['sizes'].extend(size_patterns)
            
            # 提取材质模式
            material_patterns = re.findall(r'\b(304|316L?|201|430|不锈钢|碳钢|合金钢|铸铁|铜|铝)\b', full_desc)
            patterns['materials'].extend(material_patterns)
        
        return dict(patterns)
    
    def _analyze_name_variations(self) -> Dict[str, List[str]]:
        """分析物料名称变体（包含大小写和空格标准化）"""
        variations = {}
        
        # 按相似名称分组
        name_groups = defaultdict(list)
        
        for material in self.materials_data:
            name = normalize_text_comprehensive(material.get('MATERIAL_NAME', ''))
            short_name = normalize_text_comprehensive(material.get('SHORT_NAME', ''))
            english_name = normalize_text_comprehensive(material.get('ENGLISH_NAME', ''))
            
            if name:
                # 提取核心关键词
                core_keywords = self._extract_core_keywords(name)
                for keyword in core_keywords:
                    # 添加原始名称及其大小写变体
                    name_variants = generate_case_variants(name)
                    name_groups[keyword].extend(name_variants)
                    
                    if short_name and short_name != name:
                        short_variants = generate_case_variants(short_name)
                        name_groups[keyword].extend(short_variants)
                    
                    if english_name:
                        english_variants = generate_case_variants(english_name)
                        name_groups[keyword].extend(english_variants)
        
        # 生成同义词组
        for keyword, names in name_groups.items():
            if len(names) > 1:
                unique_names = list(set(names))
                if len(unique_names) > 1:
                    # 选择最常见的形式作为标准形式
                    standard_name = max(unique_names, key=len)  # 选择最长的作为标准
                    variants = [n for n in unique_names if n != standard_name]
                    if variants:
                        variations[standard_name] = variants
        
        return variations
    
    def _generate_unit_synonyms(self) -> Dict[str, List[str]]:
        """基于bd_measdoc生成单位同义词（包含大小写变体）"""
        unit_synonyms = {}
        
        for unit in self.units_data:
            unit_name = normalize_text_comprehensive(unit.get('UNIT_NAME', ''))
            english_name = normalize_text_comprehensive(unit.get('ENGLISH_NAME', ''))
            unit_code = normalize_text_comprehensive(unit.get('UNIT_CODE', ''))
            
            if unit_name:
                synonyms = []
                
                # 添加单位名称的大小写变体
                synonyms.extend(generate_case_variants(unit_name))
                
                if english_name and english_name != unit_name:
                    synonyms.extend(generate_case_variants(english_name))
                
                if unit_code and unit_code != unit_name:
                    synonyms.extend(generate_case_variants(unit_code))
                
                # 去重并过滤掉标准名称本身
                unique_synonyms = list(set(synonyms))
                variants = [s for s in unique_synonyms if s != unit_name]
                
                if variants:
                    unit_synonyms[unit_name] = variants
        
        return unit_synonyms
    
    def _analyze_spec_variations(self) -> Dict[str, List[str]]:
        """分析规格表示的变体（包含标准化处理）"""
        variations = {}
        
        # 分析规格表示的变体
        spec_variations = defaultdict(set)
        
        for material in self.materials_data:
            spec = material.get('SPECIFICATION', '')
            if spec:
                # 应用标准化处理
                spec = normalize_fullwidth_to_halfwidth(normalize_text_comprehensive(spec))
                
                # 查找尺寸规格的不同表示方法
                size_matches = re.findall(r'\d+(?:\.\d+)?[×*xX]\d+(?:\.\d+)?', spec)
                for match in size_matches:
                    # 标准化为x格式
                    normalized = re.sub(r'[×*X]', 'x', match)
                    spec_variations[normalized].add(match)
        
        # 生成规格变体同义词
        for normalized, variants in spec_variations.items():
            if len(variants) > 1:
                variations[normalized] = list(variants - {normalized})
        
        return variations
    
    def _generate_brand_synonyms(self) -> Dict[str, List[str]]:
        """生成品牌同义词（包含大小写变体）"""
        brand_synonyms = {}
        
        # 从物料数据中提取品牌信息
        brand_patterns = defaultdict(int)
        
        for material in self.materials_data:
            name = normalize_text_comprehensive(material.get('MATERIAL_NAME', ''))
            # 提取可能的品牌名（通常是大写字母组合）
            brands = re.findall(r'\b[A-Z]{2,}\b', name)
            for brand in brands:
                brand_patterns[brand] += 1
        
        # 为常见品牌生成大小写变体
        common_brands = [brand for brand, count in brand_patterns.items() if count >= 5]
        
        for brand in common_brands:
            variants = generate_case_variants(brand)
            if len(variants) > 1:
                brand_synonyms[brand] = [v for v in variants if v != brand]
        
        return brand_synonyms
    
    def _generate_material_synonyms(self) -> Dict[str, List[str]]:
        """生成材质同义词（包含大小写变体）"""
        material_synonyms = {}
        
        # 常见材质及其变体
        common_materials = {
            '不锈钢': ['304', '316', '316L', 'SS', 'stainless steel'],
            '碳钢': ['CS', 'carbon steel', 'A105'],
            '合金钢': ['alloy steel', '40Cr', '42CrMo'],
            '铸铁': ['cast iron', 'CI', 'HT200', 'HT250'],
            '铜': ['Cu', 'copper', 'brass'],
            '铝': ['Al', 'aluminum', 'aluminium']
        }
        
        for standard, variants in common_materials.items():
            all_variants = []
            for variant in variants:
                all_variants.extend(generate_case_variants(variant))
            
            # 去重
            unique_variants = list(set(all_variants))
            if unique_variants:
                material_synonyms[standard] = unique_variants
        
        return material_synonyms
    
    def _generate_general_rules_from_data(self) -> List[Dict]:
        """基于数据分析生成通用规则"""
        rules = []
        
        # 基于物料描述模式生成规则
        patterns = self._analyze_description_patterns()
        
        # 生成尺寸规格提取规则（清洗规则适配版）
        # 关键改进：适配13条清洗规则的输出格式
        if patterns.get('sizes'):
            rules.append({
                'rule_name': '尺寸规格提取（清洗适配）',
                'material_category': 'general',
                'attribute_name': 'size_specification',
                'regex_pattern': r'(\d+(?:\.\d+)?[_×*x]\d+(?:\.\d+)?(?:[_×*x]\d+(?:\.\d+)?)?)',  # 关键：增加_支持
                'priority': 90,
                'confidence': 0.95,
                'is_active': True,
                'version': 2,  # 版本升级
                'description': '提取尺寸规格，适配清洗规则输出（支持下划线分隔符）',
                'example_input': '不锈钢管 ５０×１００×２',
                'example_input_cleaned': '不锈钢管 50_100_2',  # 新增：清洗后格式
                'example_output': '50×100×2',
                'created_by': 'system'
            })
        
        return rules
    
    def _generate_category_specific_rules(self) -> List[Dict]:
        """生成类别特定规则"""
        rules = []
        
        # 螺纹规格提取规则（清洗规则适配版）
        # 关键改进：适配13条清洗规则的输出格式
        # - 支持下划线分隔符（清洗规则将×*转为_）
        # - 支持小写匹配（清洗规则统一转小写）
        # - 同时保留对原始格式的支持
        rules.append({
            'rule_name': '螺纹规格提取（清洗适配）',
            'material_category': 'fastener',
            'attribute_name': 'thread_specification',
            'regex_pattern': r'([Mm]\d+(?:\.\d+)?[_×*xX]\d+(?:\.\d+)?)',  # 关键：增加_和小写支持
            'priority': 95,
            'confidence': 0.98,
            'is_active': True,
            'version': 2,  # 版本升级
            'description': '提取螺纹规格，适配清洗规则输出（支持下划线、小写）',
            'example_input': '内六角螺栓 Ｍ８×１．２５×２０',
            'example_input_cleaned': '内六角螺栓 m8_1.25_20',  # 新增：清洗后格式
            'example_output': 'M8×1.25',
            'created_by': 'system'
        })
        
        # 压力等级提取规则
        rules.append({
            'rule_name': '压力等级提取',
            'material_category': 'valve',
            'attribute_name': 'pressure_rating',
            'regex_pattern': r'(PN\d+|(?:\d+(?:\.\d+)?(?:MPa|bar|公斤|kg)))',
            'priority': 88,
            'confidence': 0.90,
            'is_active': True,
            'version': 1,
            'description': '提取压力等级如PN16, 1.6MPa',
            'example_input': '球阀 PN16 DN50',
            'example_output': 'PN16',
            'created_by': 'system'
        })
        
        # 公称直径提取规则（清洗规则适配版）
        # 关键改进：适配希腊字母标准化（φ/Φ → phi/PHI）
        rules.append({
            'rule_name': '公称直径提取（清洗适配）',
            'material_category': 'pipe',
            'attribute_name': 'nominal_diameter',
            'regex_pattern': r'([Dd][Nn]\d+|[Pp][Hh][Ii]\d+|φ\d+|Φ\d+)',  # 关键：增加phi/PHI支持
            'priority': 87,
            'confidence': 0.95,
            'is_active': True,
            'version': 2,  # 版本升级
            'description': '提取公称直径，适配清洗规则输出（支持phi/PHI标准化）',
            'example_input': '不锈钢管 ＤＮ５０ φ100',
            'example_input_cleaned': '不锈钢管 dn50 phi100',  # 新增：清洗后格式
            'example_output': 'DN50',
            'created_by': 'system'
        })
        
        return rules
    
    def _generate_brand_rules(self) -> List[Dict]:
        """生成品牌提取规则"""
        rules = []
        
        # 从数据中提取常见品牌
        brand_patterns = defaultdict(int)
        for material in self.materials_data:
            name = material.get('MATERIAL_NAME', '')
            brands = re.findall(r'\b[A-Z]{2,}\b', name)
            for brand in brands:
                brand_patterns[brand] += 1
        
        common_brands = [brand for brand, count in brand_patterns.items() if count >= 10]
        
        if common_brands:
            brand_regex = '|'.join(re.escape(brand) for brand in common_brands)
            rules.append({
                'rule_name': '品牌名称提取',
                'material_category': 'general',
                'attribute_name': 'brand_name',
                'regex_pattern': f'\\b({brand_regex})\\b',
                'priority': 85,
                'confidence': 0.92,
                'is_active': True,
                'version': 1,
                'description': f'提取品牌名称，支持{len(common_brands)}个常见品牌',
                'example_input': 'SKF深沟球轴承 6206',
                'example_output': 'SKF',
                'created_by': 'system'
            })
        
        return rules
    
    def _generate_material_rules(self) -> List[Dict]:
        """生成材质提取规则"""
        rules = []
        
        # 材质提取规则
        rules.append({
            'rule_name': '材质类型提取',
            'material_category': 'general',
            'attribute_name': 'material_type',
            'regex_pattern': r'(304|316L?|201|430|不锈钢|碳钢|合金钢|铸铁|铜|铝)',
            'priority': 88,
            'confidence': 0.90,
            'is_active': True,
            'version': 1,
            'description': '提取材质类型',
            'example_input': '304不锈钢管',
            'example_output': '304',
            'created_by': 'system'
        })
        
        return rules
    
    def _extract_core_keywords(self, text: str) -> List[str]:
        """提取文本中的核心关键词"""
        # 去除常见的修饰词
        stop_words = {'的', '用', '型', '式', '种', '个', '只', '件', '套', '根', '条', '片'}
        
        # 分词（简单的基于空格和标点的分词）
        words = re.findall(r'[\u4e00-\u9fff]+|[A-Za-z0-9]+', text)
        
        # 过滤停用词和短词
        keywords = [word for word in words if len(word) >= 2 and word not in stop_words]
        
        return keywords
    
    def _generate_category_keywords_from_data(self) -> Dict[str, List[str]]:
        """
        基于Oracle真实物料数据生成分类关键词
        
        这个方法分析每个分类下的所有物料描述，提取高频词作为该分类的检测关键词
        
        Returns:
            Dict[str, List[str]]: {分类名: [关键词列表]}
        """
        logger.info("🔍 分析物料数据，生成分类关键词...")
        
        category_keywords = {}
        category_materials = defaultdict(list)
        
        # 按分类组织物料描述
        for material in self.materials_data:
            # 兼容Oracle（大写）和PostgreSQL（小写）字段名
            category_name = material.get('CATEGORY_NAME') or material.get('category_name') or ''
            if category_name:
                # 组合完整描述（兼容两种数据源）
                name = material.get('MATERIAL_NAME') or material.get('material_name') or ''
                spec = material.get('SPECIFICATION') or material.get('specification') or ''
                material_type = material.get('MATERIAL_TYPE') or material.get('material_type') or ''
                # 如果有normalized_name（PostgreSQL清洗后数据），优先使用
                normalized = material.get('normalized_name') or ''
                full_desc = normalized if normalized else f"{name} {spec} {material_type}".strip()
                
                if full_desc:
                    category_materials[category_name].append(full_desc)
        
        # 为每个分类提取关键词
        for category_name, descriptions in category_materials.items():
            if len(descriptions) >= 3:  # 至少3个样本才分析
                keywords = self._extract_category_keywords(category_name, descriptions)
                if keywords:
                    category_keywords[category_name] = keywords
        
        logger.info(f"✅ 为 {len(category_keywords)} 个分类生成了关键词")
        return category_keywords
    
    def _extract_category_keywords(self, category_name: str, descriptions: List[str]) -> List[str]:
        """
        为特定分类提取关键词（改进版v2.0）
        
        改进点：
        1. 拆分分类名，提取有意义的词根（如"维修类"→["维修","类"]）
        2. 降低词频阈值到15%，包含更多特征词
        3. 增加特殊分类的手动关键词补充
        
        Args:
            category_name: 分类名称
            descriptions: 该分类下的所有物料描述
            
        Returns:
            List[str]: 关键词列表（最多15个）
        """
        keywords = set()
        
        # 1. 添加分类名本身
        keywords.add(category_name)
        
        # 2. 拆分分类名，提取词根（去除"类"等后缀）
        # 例如："维修类" → ["维修", "维修类"]
        #      "功率单元" → ["功率", "单元", "功率单元"]
        category_words = re.findall(r'[\u4e00-\u9fff]+', category_name)
        for word in category_words:
            if len(word) >= 2:
                keywords.add(word)
                # 去除"类"后缀
                if word.endswith('类') and len(word) > 2:
                    keywords.add(word[:-1])
        
        # 3. 特殊分类的手动关键词补充（基于业务知识）
        special_keywords = {
            '维修类': ['维修', '功率单元', '功率模块', '控制单元', '驱动单元', '电控单元', '变频单元', '整流单元', '逆变单元'],
            '电气类': ['电气', '电机', '变频器', '接触器', '断路器', '继电器'],
            '液压类': ['液压', '油泵', '油缸', '液压阀', '溢流阀'],
            '气动类': ['气动', '气缸', '气动阀', '电磁阀'],
            '轴承类': ['轴承', '滚动轴承', '滑动轴承', '深沟球'],
            '密封类': ['密封', '密封圈', 'O型圈', '骨架油封'],
        }
        
        if category_name in special_keywords:
            keywords.update(special_keywords[category_name])
        
        # 4. 从物料描述中提取高频词
        all_words = []
        for desc in descriptions:
            words = re.findall(r'[\u4e00-\u9fff]+|[A-Za-z]+', desc)
            all_words.extend(words)
        
        # 统计词频
        word_counter = Counter(all_words)
        
        # 5. 选择出现频率 >= 15% 的词作为关键词（降低阈值）
        threshold = max(1, len(descriptions) * 0.15)
        for word, count in word_counter.items():
            if count >= threshold and len(word) >= 2:
                # 过滤掉太常见的通用词和单位
                if word not in {'mm', 'MM', 'kg', 'KG', 'm', 'M', 'g', 'G', 'cm', 'CM', 'L', 'l', 'mpa', 'MPa'}:
                    keywords.add(word)
        
        # 6. 限制关键词数量，返回最高频的15个（增加到15个）
        sorted_keywords = sorted(keywords, 
                                key=lambda w: word_counter.get(w, 0), 
                                reverse=True)
        return sorted_keywords[:15]
    
    def detect_material_category(self, description: str) -> Tuple[str, float]:
        """检测物料类别"""
        description_lower = description.lower()
        category_scores = {}
        
        for category, keywords in self.category_keywords.items():
            score = sum(1 for keyword in keywords if keyword in description_lower)
            if score > 0:
                category_scores[category] = score / len(keywords)
        
        if category_scores:
            best_category = max(category_scores, key=category_scores.get)
            confidence = category_scores[best_category]
            return best_category, confidence
        
        return 'general', 0.1
    
    def generate_category_statistics(self) -> Dict[str, any]:
        """生成类别统计信息"""
        logger.info("📈 生成类别统计信息...")
        
        category_stats = defaultdict(int)
        detection_results = []
        
        for material in self.materials_data:
            name = material.get('MATERIAL_NAME', '')
            spec = material.get('SPECIFICATION', '')
            model = material.get('MODEL', '')
            
            full_desc = f"{name} {spec} {model}".strip()
            category, confidence = self.detect_material_category(full_desc)
            
            category_stats[category] += 1
            detection_results.append({
                'erp_code': material.get('ERP_CODE'),
                'description': full_desc,
                'detected_category': category,
                'confidence': confidence
            })
        
        return {
            'category_distribution': dict(category_stats),
            'total_materials': len(self.materials_data),
            'detection_results': detection_results,
            'coverage_rate': len([r for r in detection_results if r['confidence'] > 0.3]) / len(detection_results)
        }
    
    def save_knowledge_base(self, output_dir: str = '.'):
        """
        保存生成的知识库
        
        这是项目的核心输出，包含：
        1. 提取规则
        2. 同义词词典
        3. 分类关键词
        4. 统计报告
        """
        import os
        # 不创建子目录，直接在当前目录生成
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # 生成并保存提取规则
        logger.info("🔧 生成提取规则...")
        rules = self.generate_extraction_rules()
        rules_file = f"{output_dir}/standardized_extraction_rules_{timestamp}.json"
        with open(rules_file, 'w', encoding='utf-8') as f:
            json.dump(rules, f, ensure_ascii=False, indent=2)
        logger.info(f"💾 提取规则已保存到: {rules_file}")
        
        # 生成并保存同义词典（字典格式，供API使用）
        logger.info("📚 生成同义词典...")
        synonyms = self.generate_synonym_dictionary()
        dict_file = f"{output_dir}/standardized_synonym_dictionary_{timestamp}.json"
        with open(dict_file, 'w', encoding='utf-8') as f:
            json.dump(synonyms, f, ensure_ascii=False, indent=2)
        logger.info(f"💾 同义词典已保存到: {dict_file}")
        
        # 生成并保存同义词记录（扁平格式，供数据库导入）
        logger.info("🔄 生成同义词记录...")
        synonym_records = self.generate_synonym_records()
        records_file = f"{output_dir}/standardized_synonym_records_{timestamp}.json"
        with open(records_file, 'w', encoding='utf-8') as f:
            json.dump(synonym_records, f, ensure_ascii=False, indent=2)
        logger.info(f"💾 同义词记录已保存到: {records_file}")
        
        # 生成并保存分类关键词
        logger.info("🏷️ 生成分类关键词...")
        category_keywords_file = f"{output_dir}/standardized_category_keywords_{timestamp}.json"
        with open(category_keywords_file, 'w', encoding='utf-8') as f:
            json.dump(self.category_keywords, f, ensure_ascii=False, indent=2)
        logger.info(f"💾 分类关键词已保存到: {category_keywords_file}")
        
        # 生成并保存统计报告
        logger.info("📊 生成统计报告...")
        stats = self.generate_category_statistics()
        stats_file = f"{output_dir}/category_statistics_{timestamp}.json"
        with open(stats_file, 'w', encoding='utf-8') as f:
            json.dump(stats, f, ensure_ascii=False, indent=2)
        logger.info(f"💾 统计报告已保存到: {stats_file}")
        
        # 生成可读的规则文档
        self._generate_rules_documentation(rules, f"{output_dir}/rules_documentation_{timestamp}.md")
        
        # 清理旧文件
        self._cleanup_old_files(output_dir)
        
        return {
            'rules_file': rules_file,
            'dictionary_file': dict_file,
            'synonym_records_file': records_file,  # 新增：数据库导入用
            'category_keywords_file': category_keywords_file,
            'statistics_file': stats_file,
            'total_rules': len(rules),
            'total_synonyms': len(synonyms),
            'total_synonym_records': len(synonym_records),  # 新增
            'total_materials_analyzed': len(self.materials_data)
        }
    
    def _cleanup_old_files(self, output_dir: str):
        """清理旧的生成文件，只保留最新版本"""
        import glob
        import os
        
        file_patterns = [
            'standardized_extraction_rules_*.json',
            'standardized_synonym_dictionary_*.json',
            'standardized_synonym_records_*.json',  # 新增：同义词记录文件
            'standardized_category_keywords_*.json',
            'category_statistics_*.json',
            'rules_documentation_*.md'
        ]
        
        for pattern in file_patterns:
            files = glob.glob(os.path.join(output_dir, pattern))
            if len(files) > 1:
                # 按修改时间排序，删除除最新文件外的所有文件
                files.sort(key=os.path.getmtime)
                for old_file in files[:-1]:
                    try:
                        os.remove(old_file)
                        logger.info(f"🗑️ 已删除旧文件: {old_file}")
                    except Exception as e:
                        logger.warning(f"⚠️ 删除旧文件失败 {old_file}: {e}")
    
    def _generate_rules_documentation(self, rules: List[Dict], output_file: str):
        """生成规则文档"""
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("# 物料属性提取规则文档\n\n")
            f.write(f"**生成时间:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**数据来源:** Oracle ERP系统\n")
            f.write(f"**规则总数:** {len(rules)}\n")
            f.write(f"**数据处理标准:** 统一标准化处理（全角转半角、空格清理、大小写变体）\n\n")
            
            # 按类别分组
            category_rules = defaultdict(list)
            for rule in rules:
                category_rules[rule['material_category']].append(rule)
            
            for category, cat_rules in category_rules.items():
                f.write(f"## {category.upper()} 类别规则\n\n")
                
                for rule in sorted(cat_rules, key=lambda x: x['priority'], reverse=True):
                    f.write(f"### {rule['rule_name']}\n")
                    f.write(f"- **属性名称:** {rule['attribute_name']}\n")
                    f.write(f"- **正则表达式:** `{rule['regex_pattern']}`\n")
                    f.write(f"- **优先级:** {rule['priority']}\n")
                    f.write(f"- **置信度:** {rule.get('confidence', 'N/A')}\n")
                    f.write(f"- **描述:** {rule['description']}\n")
                    if rule.get('example_input'):
                        f.write(f"- **示例输入:** {rule['example_input']}\n")
                        f.write(f"- **示例输出:** {rule['example_output']}\n")
                    f.write("\n")


async def main():
    """
    主函数 - 执行完整的知识库生成流程
    
    这是项目数据基础设施的统一入口
    """
    logger.info("🚀 启动物料知识库生成器 (统一版本)")
    
    try:
        # 检查依赖
        logger.info("🔍 检查依赖模块...")
        
        try:
            import oracledb
            logger.info(f"✅ oracledb模块已安装，版本: {oracledb.__version__}")
        except ImportError:
            logger.error("❌ oracledb模块未安装，请运行: pip install oracledb")
            return False
        
        # 创建生成器
        generator = MaterialKnowledgeGenerator()
        
        # 检查Oracle连接
        logger.info("🔗 测试Oracle数据库连接...")
        if not generator.oracle.test_connection():
            logger.error("❌ Oracle数据库连接失败，请检查配置")
            return False
        
        logger.info("✅ Oracle数据库连接成功")
        
        # 加载数据
        await generator.load_all_data()
        
        # 生成并保存知识库
        logger.info("💾 保存知识库...")
        result = generator.save_knowledge_base()
        
        # 输出结果摘要
        logger.info("=" * 80)
        logger.info("🎉 知识库生成完成！结果摘要:")
        logger.info("=" * 80)
        logger.info(f"📊 数据分析:")
        logger.info(f"  - 物料总数: {result['total_materials_analyzed']:,}")
        logger.info(f"  - 分类总数: {len(generator.categories_data)}")
        logger.info(f"  - 单位总数: {len(generator.units_data)}")
        
        logger.info(f"🔧 知识库生成:")
        logger.info(f"  - 提取规则: {result['total_rules']} 条")
        logger.info(f"  - 同义词组: {result['total_synonyms']} 组")
        
        logger.info(f"📁 输出文件:")
        logger.info(f"  - 提取规则: {result['rules_file']}")
        logger.info(f"  - 同义词典: {result['dictionary_file']}")
        logger.info(f"  - 分类关键词: {result['category_keywords_file']}")
        logger.info(f"  - 统计报告: {result['statistics_file']}")
        
        # 生成类别统计
        stats = generator.generate_category_statistics()
        logger.info(f"📈 类别检测统计:")
        logger.info(f"  - 检测覆盖率: {stats['coverage_rate']:.1%}")
        
        top_categories = sorted(stats['category_distribution'].items(), 
                               key=lambda x: x[1], reverse=True)[:10]
        logger.info(f"  - 前10大类别:")
        for category, count in top_categories:
            logger.info(f"    * {category}: {count:,} 条")
        
        logger.info("=" * 80)
        logger.info("✅ 物料知识库生成完成！")
        logger.info("📋 下一步操作建议:")
        logger.info("  1. 查看生成的规则文档，了解提取规则详情")
        logger.info("  2. 检查同义词典，根据需要进行微调")
        logger.info("  3. 运行测试脚本验证规则效果")
        logger.info("  4. 将知识库导入到查重系统数据库")
        logger.info("=" * 80)
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 生成过程中发生错误: {e}")
        logger.exception("详细错误信息:")
        return False


def quick_generate():
    """快速生成接口（同步版本）"""
    return asyncio.run(main())


if __name__ == "__main__":
    import asyncio
    success = asyncio.run(main())
    
    if success:
        print("\n🎊 恭喜！物料知识库生成成功！")
    else:
        print("\n💥 生成失败！请检查日志文件了解详细错误信息。")
    
    sys.exit(0 if success else 1)
