"""
快速生成规则和词典脚本
基于Oracle数据库中的所有物料信息，一键生成提取规则和同义词典
"""

import os
import sys
import asyncio
import logging
from datetime import datetime

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(__file__))

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'rule_generation_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


async def quick_generate():
    """快速生成规则和词典"""
    
    logger.info("=" * 80)
    logger.info("🚀 智能物料规则和词典生成器")
    logger.info("=" * 80)
    logger.info(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    try:
        # 检查依赖
        logger.info("🔍 检查依赖模块...")
        
        try:
            import oracledb
            logger.info(f"✅ oracledb模块已安装，版本: {oracledb.__version__}")
        except ImportError:
            logger.error("❌ oracledb模块未安装，请运行: pip install oracledb")
            return False
        
        # 导入模块
        from oracledb_connector import OracleDBConnector
        from oracle_config import OracleConfig
        from intelligent_rule_generator import IntelligentRuleGenerator
        
        logger.info("✅ 所有依赖模块导入成功")
        
        # 检查Oracle连接
        logger.info("🔗 测试Oracle数据库连接...")
        connector = OracleDBConnector(**OracleConfig.get_connection_params())
        
        if not connector.test_connection():
            logger.error("❌ Oracle数据库连接失败，请检查配置")
            return False
        
        logger.info("✅ Oracle数据库连接成功")
        
        # 创建生成器
        logger.info("🔧 初始化规则生成器...")
        generator = IntelligentRuleGenerator(connector)
        
        # 执行生成
        logger.info("📊 开始数据分析和规则生成...")
        result = await generator.load_all_data()
        
        logger.info("💾 保存生成结果...")
        output_result = generator.save_rules_and_dictionary()
        
        # 输出结果摘要
        logger.info("=" * 80)
        logger.info("🎉 生成完成！结果摘要:")
        logger.info("=" * 80)
        logger.info(f"📊 数据分析:")
        logger.info(f"  - 物料总数: {output_result['total_materials_analyzed']:,}")
        logger.info(f"  - 分类总数: {len(generator.categories_data)}")
        logger.info(f"  - 单位总数: {len(generator.units_data)}")
        
        logger.info(f"🔧 规则生成:")
        logger.info(f"  - 提取规则: {output_result['total_rules']} 条")
        logger.info(f"  - 同义词组: {output_result['total_synonyms']} 组")
        
        logger.info(f"📁 输出文件:")
        logger.info(f"  - 提取规则: {output_result['rules_file']}")
        logger.info(f"  - 同义词典: {output_result['dictionary_file']}")
        logger.info(f"  - 统计报告: {output_result['statistics_file']}")
        logger.info(f"  - 规则文档: {output_result['rules_file'].replace('.json', '_documentation.md')}")
        
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
        logger.info("✅ 所有任务完成！可以开始使用生成的规则和词典进行物料查重。")
        logger.info("=" * 80)
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 生成过程中发生错误: {e}")
        logger.exception("详细错误信息:")
        return False


def main():
    """主入口函数"""
    success = asyncio.run(quick_generate())
    
    if success:
        print("\n🎊 恭喜！规则和词典生成成功！")
        print("📋 下一步操作建议:")
        print("  1. 查看生成的规则文档，了解提取规则详情")
        print("  2. 检查同义词典，根据需要进行微调")
        print("  3. 运行测试脚本验证规则效果")
        print("  4. 将规则和词典导入到查重系统数据库")
    else:
        print("\n💥 生成失败！请检查日志文件了解详细错误信息。")
    
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
