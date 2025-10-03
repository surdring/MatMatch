"""
测试生成的规则和词典效果
验证智能规则生成器的输出质量
"""

import json
import re
import logging
from datetime import datetime
from typing import Dict, List

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class RuleTester:
    """规则测试器"""
    
    def __init__(self, rules_file: str, dictionary_file: str):
        self.rules_file = rules_file
        self.dictionary_file = dictionary_file
        self.rules = []
        self.synonyms = {}
        
        self.load_rules_and_dictionary()
    
    def load_rules_and_dictionary(self):
        """加载规则和词典"""
        try:
            # 加载提取规则
            with open(self.rules_file, 'r', encoding='utf-8') as f:
                self.rules = json.load(f)
            logger.info(f"✅ 加载了 {len(self.rules)} 条提取规则")
            
            # 加载同义词典
            with open(self.dictionary_file, 'r', encoding='utf-8') as f:
                self.synonyms = json.load(f)
            logger.info(f"✅ 加载了 {len(self.synonyms)} 个同义词组")
            
        except Exception as e:
            logger.error(f"❌ 加载规则和词典失败: {e}")
            raise
    
    def test_material_processing(self, test_materials: List[str]) -> List[Dict]:
        """测试物料处理效果"""
        logger.info("🧪 开始测试物料处理效果...")
        
        results = []
        
        for material in test_materials:
            logger.info(f"\n🔍 测试物料: {material}")
            
            # 1. 应用同义词标准化
            standardized = self.apply_synonyms(material)
            logger.info(f"  📝 标准化结果: {standardized}")
            
            # 2. 检测类别
            category, confidence = self.detect_category(standardized)
            logger.info(f"  🏷️ 检测类别: {category} (置信度: {confidence:.2f})")
            
            # 3. 提取属性
            attributes = self.extract_attributes(standardized, category)
            logger.info(f"  🔧 提取属性: {attributes}")
            
            results.append({
                'original': material,
                'standardized': standardized,
                'category': category,
                'confidence': confidence,
                'attributes': attributes
            })
        
        return results
    
    def apply_synonyms(self, text: str) -> str:
        """应用同义词标准化"""
        standardized = text
        
        for standard_term, variants in self.synonyms.items():
            for variant in variants:
                # 使用词边界匹配，避免部分匹配
                pattern = rf'\b{re.escape(variant)}\b'
                standardized = re.sub(pattern, standard_term, standardized, flags=re.IGNORECASE)
        
        return standardized
    
    def detect_category(self, description: str) -> tuple:
        """检测物料类别"""
        category_keywords = {
            'bearing': ['轴承', '軸承', 'bearing'],
            'bolt': ['螺栓', '螺钉', '螺丝', 'bolt', 'screw', '内六角', '外六角'],
            'valve': ['阀', '阀门', '閥門', 'valve', '球阀', '闸阀'],
            'pipe': ['管', '管道', '管件', 'pipe', 'tube'],
            'electrical': ['接触器', '继电器', '断路器', '变频器', 'contactor', 'relay'],
            'pump': ['泵', '水泵', '油泵', 'pump'],
            'motor': ['电机', '马达', '电动机', 'motor'],
            'sensor': ['传感器', '感应器', 'sensor'],
            'cable': ['电缆', '线缆', 'cable', 'wire'],
            'filter': ['过滤器', '滤芯', 'filter']
        }
        
        description_lower = description.lower()
        category_scores = {}
        
        for category, keywords in category_keywords.items():
            score = sum(1 for keyword in keywords if keyword in description_lower)
            if score > 0:
                category_scores[category] = score / len(keywords)
        
        if category_scores:
            best_category = max(category_scores, key=category_scores.get)
            confidence = category_scores[best_category]
            return best_category, confidence
        
        return 'general', 0.1
    
    def extract_attributes(self, text: str, category: str) -> Dict[str, str]:
        """
        提取属性 - 使用②结构化算法：正则表达式有限状态自动机
        
        算法原理：
        - 使用预编译的正则表达式模式进行属性提取
        - 基于有限状态自动机的模式匹配
        - 按优先级排序执行规则，避免冲突
        """
        attributes = {}
        
        # 获取适用的规则
        applicable_rules = [
            rule for rule in self.rules 
            if rule['material_category'] in [category, 'general'] and rule.get('is_active', True)
        ]
        
        # 按优先级排序 - 高优先级规则优先执行
        applicable_rules.sort(key=lambda x: x['priority'], reverse=True)
        
        for rule in applicable_rules:
            try:
                pattern = rule['regex_pattern']
                # 正则表达式有限状态自动机匹配
                match = re.search(pattern, text, re.IGNORECASE)
                if match:
                    value = match.group(1) if match.groups() else match.group(0)
                    attributes[rule['attribute_name']] = value
            except Exception as e:
                logger.warning(f"规则执行失败 {rule['rule_name']}: {e}")
        
        return attributes
    
    def generate_test_report(self, test_results: List[Dict], output_file: str):
        """生成测试报告"""
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write("# 规则和词典测试报告\n\n")
            f.write(f"**测试时间:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"**测试样本数:** {len(test_results)}\n\n")
            
            for i, result in enumerate(test_results, 1):
                f.write(f"## 测试样本 {i}\n\n")
                f.write(f"**原始描述:** {result['original']}\n")
                f.write(f"**标准化结果:** {result['standardized']}\n")
                f.write(f"**检测类别:** {result['category']} (置信度: {result['confidence']:.2f})\n")
                f.write(f"**提取属性:**\n")
                
                if result['attributes']:
                    for attr, value in result['attributes'].items():
                        f.write(f"  - {attr}: {value}\n")
                else:
                    f.write("  - 无属性提取\n")
                
                f.write("\n")
        
        logger.info(f"📄 测试报告已保存: {output_file}")


def main():
    """主函数"""
    logger.info("🧪 规则和词典测试程序")
    
    # 查找最新的规则和词典文件
    output_dir = './output'
    if not os.path.exists(output_dir):
        logger.error("❌ 输出目录不存在，请先运行生成程序")
        return False
    
    rule_files = [f for f in os.listdir(output_dir) if f.startswith('extraction_rules_') and f.endswith('.json')]
    dict_files = [f for f in os.listdir(output_dir) if f.startswith('synonym_dictionary_') and f.endswith('.json')]
    
    if not rule_files or not dict_files:
        logger.error("❌ 未找到规则或词典文件，请先运行生成程序")
        return False
    
    latest_rules_file = os.path.join(output_dir, sorted(rule_files)[-1])
    latest_dict_file = os.path.join(output_dir, sorted(dict_files)[-1])
    
    logger.info(f"📁 使用规则文件: {latest_rules_file}")
    logger.info(f"📁 使用词典文件: {latest_dict_file}")
    
    # 创建测试器
    tester = RuleTester(latest_rules_file, latest_dict_file)
    
    # 测试样本
    test_materials = [
        "SKF深沟球轴承6201ZZ",
        "M10x30内六角螺栓304不锈钢",
        "DN50不锈钢球阀1.6MPa",
        "西门子3TF接触器220V",
        "Φ50无缝钢管20#",
        "离心泵50m³/h 32m扬程",
        "三相异步电机7.5kW 1450rpm",
        "压力传感器0-10bar 4-20mA",
        "YJV 3x25+1x16 0.6/1kV电力电缆",
        "液压滤芯10μm 精度",
        "不锈钢球阀DN25 PN16",
        "FAG圆锥滚子轴承32308",
        "M8*20平头螺钉",
        "ABB变频器ACS550-01-012A-4",
        "Parker球阀1/2英寸"
    ]
    
    # 执行测试
    results = tester.test_material_processing(test_materials)
    
    # 生成测试报告
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    report_file = f"{output_dir}/test_report_{timestamp}.md"
    tester.generate_test_report(results, report_file)
    
    # 统计测试结果
    successful_detections = len([r for r in results if r['confidence'] > 0.3])
    successful_extractions = len([r for r in results if r['attributes']])
    
    logger.info("=" * 60)
    logger.info("📊 测试结果统计:")
    logger.info(f"  - 测试样本总数: {len(results)}")
    logger.info(f"  - 成功检测类别: {successful_detections} ({successful_detections/len(results):.1%})")
    logger.info(f"  - 成功提取属性: {successful_extractions} ({successful_extractions/len(results):.1%})")
    logger.info(f"  - 测试报告: {report_file}")
    logger.info("=" * 60)
    
    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
