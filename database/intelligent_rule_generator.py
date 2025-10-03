"""
智能规则和同义词典生成器
基于Oracle数据库中的真实物料数据，自动生成提取规则和同义词典
"""

import re
import json
import logging
from collections import defaultdict, Counter
from typing import Dict, List, Set, Tuple, Optional
from datetime import datetime
import pandas as pd

def normalize_text_comprehensive(text: str) -> str:
    """
    综合文本标准化处理：大小写标准化 + 空格清理
    
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

def generate_case_variants(text: str) -> List[str]:
    """
    生成文本的大小写变体
    
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
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class IntelligentRuleGenerator:
    """智能规则和同义词典生成器"""
    
    def __init__(self, oracle_connector):
        self.oracle = oracle_connector
        self.materials_data = []
        self.categories_data = []
        self.units_data = []
        
        # 预定义的物料类别关键词
        self.category_keywords = {
            'bearing': ['轴承', '軸承', 'bearing', '滚动轴承', '滑动轴承'],
            'bolt': ['螺栓', '螺钉', '螺丝', 'bolt', 'screw', '内六角', '外六角', '平头', '沉头'],
            'valve': ['阀', '阀门', '閥門', 'valve', '球阀', '闸阀', '截止阀', '蝶阀', '止回阀'],
            'pipe': ['管', '管道', '管件', 'pipe', 'tube', '弯头', '三通', '四通', '异径管'],
            'electrical': ['接触器', '继电器', '断路器', '变频器', 'contactor', 'relay', '开关', '熔断器'],
            'pump': ['泵', '水泵', '油泵', 'pump', '离心泵', '齿轮泵', '柱塞泵'],
            'motor': ['电机', '马达', '电动机', 'motor', '异步电机', '同步电机', '伺服电机'],
            'sensor': ['传感器', '感应器', 'sensor', '压力传感器', '温度传感器', '流量传感器'],
            'cable': ['电缆', '线缆', 'cable', 'wire', '控制电缆', '电力电缆', '通信电缆'],
            'filter': ['过滤器', '滤芯', 'filter', '空气滤清器', '机油滤清器', '液压滤芯'],
            'seal': ['密封', '密封件', 'seal', 'gasket', 'o-ring', '密封圈', '垫片'],
            'fastener': ['紧固件', 'fastener', '垫圈', '挡圈', '销', '键'],
            'tool': ['工具', 'tool', '刀具', '量具', '夹具', '模具'],
            'instrument': ['仪表', '仪器', 'instrument', 'gauge', '压力表', '温度表', '流量表']
        }
    
    async def load_all_data(self):
        """加载所有Oracle数据"""
        logger.info("🔄 开始加载Oracle数据...")
        
        if not self.oracle.connect():
            raise Exception("Oracle数据库连接失败")
        
        try:
            # 加载物料数据
            from oracle_config import MaterialQueries
            logger.info("📊 加载物料数据...")
            self.materials_data = self.oracle.execute_query_batch(
                MaterialQueries.BASIC_MATERIAL_QUERY, 
                batch_size=5000
            )
            logger.info(f"✅ 已加载 {len(self.materials_data)} 条物料数据")
            
            # 加载分类数据
            logger.info("📂 加载分类数据...")
            self.categories_data = self.oracle.execute_query(
                MaterialQueries.MATERIAL_CATEGORIES_QUERY
            )
            logger.info(f"✅ 已加载 {len(self.categories_data)} 个物料分类")
            
            # 加载单位数据
            logger.info("📏 加载计量单位数据...")
            self.units_data = self.oracle.execute_query(
                MaterialQueries.UNIT_QUERY
            )
            logger.info(f"✅ 已加载 {len(self.units_data)} 个计量单位")
            
        finally:
            self.oracle.disconnect()
    
    def generate_extraction_rules(self) -> List[Dict]:
        """基于真实数据生成属性提取规则"""
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
        
        logger.info(f"✅ 基于真实数据生成了 {len(rules)} 条属性提取规则")
        return rules
    
    def generate_synonym_dictionary(self) -> Dict[str, List[str]]:
        """基于真实数据生成同义词典"""
        logger.info("📚 开始基于真实数据生成同义词典...")
        
        synonym_dict = {}
        
        if not self.materials_data:
            logger.warning("⚠️ 没有物料数据，无法生成同义词典")
            return synonym_dict
        
        # 1. 基于物料名称分析生成同义词
        name_variations = self._analyze_name_variations()
        synonym_dict.update(name_variations)
        
        # 2. 基于单位数据生成单位同义词
        unit_synonyms = self._generate_unit_synonyms()
        synonym_dict.update(unit_synonyms)
        
        # 3. 基于规格数据生成规格表示同义词
        spec_synonyms = self._analyze_spec_variations()
        synonym_dict.update(spec_synonyms)
        
        # 4. 基于品牌数据生成品牌同义词
        brand_synonyms = self._generate_brand_synonyms()
        synonym_dict.update(brand_synonyms)
        
        # 5. 基于材质数据生成材质同义词
        material_synonyms = self._generate_material_synonyms()
        synonym_dict.update(material_synonyms)
        
        logger.info(f"✅ 基于真实数据生成了 {len(synonym_dict)} 个同义词组")
        return synonym_dict
    
    def _analyze_description_patterns(self) -> Dict[str, List[str]]:
        """分析物料描述中的常见模式"""
        patterns = defaultdict(list)
        
        for material in self.materials_data:
            name = material.get('MATERIAL_NAME', '')
            spec = material.get('SPECIFICATION', '')
            model = material.get('MODEL', '')
            
            # 分析完整描述
            full_desc = f"{name} {spec} {model}".strip()
            
            # 提取数字+字母的模式（可能是型号）
            model_patterns = re.findall(r'\b[A-Z0-9]{3,}(?:-[A-Z0-9]+)?\b', full_desc.upper())
            patterns['models'].extend(model_patterns)
            
            # 提取尺寸模式
            size_patterns = re.findall(r'\b\d+(?:\.\d+)?[×*xX]\d+(?:\.\d+)?(?:[×*xX]\d+(?:\.\d+)?)?\b', full_desc)
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
    
    def _analyze_data_variations(self) -> Dict[str, List[str]]:
        """基于真实数据分析变体"""
        variations = {}
        
        # 分析规格表示的变体
        spec_variations = defaultdict(set)
        
        for material in self.materials_data:
            spec = material.get('SPECIFICATION', '')
            if spec:
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
    
    def _analyze_spec_variations(self) -> Dict[str, List[str]]:
        """分析规格表示的变体（包含标准化处理）"""
        return self._analyze_data_variations()
    
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
        
        # 生成尺寸规格提取规则
        if patterns.get('sizes'):
            rules.append({
                'rule_name': '尺寸规格提取',
                'material_category': 'general',
                'attribute_name': 'size_specification',
                'regex_pattern': r'(\d+(?:\.\d+)?[×*xX]\d+(?:\.\d+)?(?:[×*xX]\d+(?:\.\d+)?)?)',
                'priority': 90,
                'description': '提取尺寸规格如20x30, 50×100等',
                'example_input': '不锈钢管 50×100×2',
                'example_output': '50×100×2'
            })
        
        return rules
    
    def _generate_category_specific_rules(self) -> List[Dict]:
        """生成类别特定规则"""
        rules = []
        
        # 螺纹规格提取规则
        rules.append({
            'rule_name': '螺纹规格提取',
            'material_category': 'fastener',
            'attribute_name': 'thread_specification',
            'regex_pattern': r'(M\d+(?:\.\d+)?[×*xX]\d+(?:\.\d+)?)',
            'priority': 95,
            'description': '提取螺纹规格如M8×1.25',
            'example_input': '内六角螺栓 M8×1.25×20',
            'example_output': 'M8×1.25'
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
                'description': f'提取品牌名称，支持{len(common_brands)}个常见品牌',
                'example_input': 'SKF深沟球轴承 6206',
                'example_output': 'SKF'
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
            'description': '提取材质类型',
            'example_input': '304不锈钢管',
            'example_output': '304'
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
    
    def save_rules_and_dictionary(self, output_dir: str = './output'):
        """保存生成的规则和词典"""
        import os
        os.makedirs(output_dir, exist_ok=True)
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # 生成并保存提取规则
        rules = self.generate_extraction_rules()
        rules_file = f"{output_dir}/extraction_rules_{timestamp}.json"
        with open(rules_file, 'w', encoding='utf-8') as f:
            json.dump(rules, f, ensure_ascii=False, indent=2)
        logger.info(f"💾 提取规则已保存到: {rules_file}")
        
        # 生成并保存同义词典
        synonyms = self.generate_synonym_dictionary()
        dict_file = f"{output_dir}/synonym_dictionary_{timestamp}.json"
        with open(dict_file, 'w', encoding='utf-8') as f:
            json.dump(synonyms, f, ensure_ascii=False, indent=2)
        logger.info(f"💾 同义词典已保存到: {dict_file}")
        
        # 生成并保存统计报告
        stats = self.generate_category_statistics()
        stats_file = f"{output_dir}/category_statistics_{timestamp}.json"
        with open(stats_file, 'w', encoding='utf-8') as f:
            json.dump(stats, f, ensure_ascii=False, indent=2)
        logger.info(f"💾 统计报告已保存到: {stats_file}")
        
        # 生成可读的规则文档
        self._generate_rules_documentation(rules, f"{output_dir}/rules_documentation_{timestamp}.md")
        
        return {
            'rules_file': rules_file,
            'dictionary_file': dict_file,
            'statistics_file': stats_file,
            'total_rules': len(rules),
            'total_synonyms': len(synonyms),
            'total_materials_analyzed': len(self.materials_data)
        }
    
    def _generate_rules_documentation(self, rules: List[Dict], output_file: str):
        """生成规则文档"""
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("# 物料属性提取规则文档\n\n")
            f.write(f"**生成时间:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**数据来源:** Oracle ERP系统\n")
            f.write(f"**规则总数:** {len(rules)}\n\n")
            
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
                    f.write(f"- **描述:** {rule['description']}\n")
                    if rule.get('example_input'):
                        f.write(f"- **示例输入:** {rule['example_input']}\n")
                        f.write(f"- **示例输出:** {rule['example_output']}\n")
                    f.write("\n")


async def main():
    """主函数 - 执行规则和词典生成"""
    logger.info("🚀 启动智能规则和同义词典生成器")
    
    # 导入Oracle连接器
    from oracledb_connector import OracleDBConnector
    from oracle_config import OracleConfig
    
    # 创建连接器
    connector = OracleDBConnector(**OracleConfig.get_connection_params())
    
    # 创建生成器
    generator = IntelligentRuleGenerator(connector)
    
    try:
        # 加载数据
        await generator.load_all_data()
        
        # 生成并保存规则和词典
        result = generator.save_rules_and_dictionary()
        
        logger.info("🎉 生成完成！")
        logger.info(f"📊 处理统计:")
        logger.info(f"  - 分析物料数量: {result['total_materials_analyzed']}")
        logger.info(f"  - 生成规则数量: {result['total_rules']}")
        logger.info(f"  - 生成同义词组: {result['total_synonyms']}")
        logger.info(f"📁 输出文件:")
        logger.info(f"  - 提取规则: {result['rules_file']}")
        logger.info(f"  - 同义词典: {result['dictionary_file']}")
        logger.info(f"  - 统计报告: {result['statistics_file']}")
        
        return result
        
    except Exception as e:
        logger.error(f"❌ 生成过程中发生错误: {e}")
        raise


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
