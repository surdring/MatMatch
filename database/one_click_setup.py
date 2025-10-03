"""
一键设置脚本
从Oracle数据库分析物料信息 → 生成规则和词典 → 导入PostgreSQL
"""

import os
import sys
import asyncio
import logging
from datetime import datetime

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'one_click_setup_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


async def one_click_setup():
    """一键完成所有设置"""
    
    logger.info("=" * 100)
    logger.info("🚀 智能物料查重工具 - 一键设置程序")
    logger.info("=" * 100)
    logger.info(f"开始时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("")
    
    try:
        # 步骤1: 检查环境
        logger.info("🔍 步骤1: 环境检查")
        logger.info("-" * 50)
        
        # 检查Python模块
        required_modules = ['oracledb', 'asyncpg', 'pandas', 'numpy']
        missing_modules = []
        
        for module in required_modules:
            try:
                __import__(module)
                logger.info(f"✅ {module} 模块已安装")
            except ImportError:
                missing_modules.append(module)
                logger.error(f"❌ {module} 模块未安装")
        
        if missing_modules:
            logger.error(f"💡 请安装缺失模块: pip install {' '.join(missing_modules)}")
            return False
        
        # 步骤2: Oracle数据分析和规则生成
        logger.info("\n📊 步骤2: Oracle数据分析和规则生成")
        logger.info("-" * 50)
        
        from oracledb_connector import OracleDBConnector
        from oracle_config import OracleConfig
        from intelligent_rule_generator import IntelligentRuleGenerator
        
        # 测试Oracle连接
        oracle_connector = OracleDBConnector(**OracleConfig.get_connection_params())
        if not oracle_connector.test_connection():
            logger.error("❌ Oracle数据库连接失败")
            return False
        
        logger.info("✅ Oracle数据库连接成功")
        
        # 生成规则和词典
        generator = IntelligentRuleGenerator(oracle_connector)
        await generator.load_all_data()
        
        generation_result = generator.save_rules_and_dictionary()
        
        logger.info("✅ 规则和词典生成完成")
        logger.info(f"  - 分析物料: {generation_result['total_materials_analyzed']:,} 条")
        logger.info(f"  - 生成规则: {generation_result['total_rules']} 条")
        logger.info(f"  - 生成同义词: {generation_result['total_synonyms']} 组")
        
        # 步骤3: PostgreSQL数据库初始化
        logger.info("\n🗄️ 步骤3: PostgreSQL数据库初始化")
        logger.info("-" * 50)
        
        from init_postgresql_rules import PostgreSQLRuleInitializer
        
        # PostgreSQL配置
        pg_config = {
            'host': os.getenv('PG_HOST', 'localhost'),
            'port': int(os.getenv('PG_PORT', 5432)),
            'database': os.getenv('PG_DATABASE', 'matmatch'),
            'username': os.getenv('PG_USERNAME', 'matmatch'),
            'password': os.getenv('PG_PASSWORD', 'matmatch')
        }
        
        initializer = PostgreSQLRuleInitializer(pg_config)
        
        if not await initializer.connect():
            logger.error("❌ PostgreSQL数据库连接失败")
            return False
        
        logger.info("✅ PostgreSQL数据库连接成功")
        
        # 创建表结构
        if not await initializer.create_tables():
            return False
        
        # 导入规则和词典
        rules_count = await initializer.import_extraction_rules(generation_result['rules_file'])
        synonyms_count = await initializer.import_synonym_dictionary(generation_result['dictionary_file'])
        categories_count = await initializer.import_material_categories(generator.categories_data)
        
        await initializer.disconnect()
        
        # 步骤4: 验证设置结果
        logger.info("\n✅ 步骤4: 设置完成验证")
        logger.info("-" * 50)
        
        logger.info("🎊 一键设置完成！")
        logger.info("")
        logger.info("📊 设置结果摘要:")
        logger.info(f"  ✅ Oracle物料数据: {generation_result['total_materials_analyzed']:,} 条")
        logger.info(f"  ✅ 物料分类: {categories_count} 个")
        logger.info(f"  ✅ 提取规则: {rules_count} 条")
        logger.info(f"  ✅ 同义词: {synonyms_count} 条")
        logger.info("")
        logger.info("📁 生成文件:")
        logger.info(f"  📄 规则文件: {generation_result['rules_file']}")
        logger.info(f"  📄 词典文件: {generation_result['dictionary_file']}")
        logger.info(f"  📄 统计报告: {generation_result['statistics_file']}")
        logger.info("")
        logger.info("🚀 下一步操作:")
        logger.info("  1. 启动FastAPI后端服务")
        logger.info("  2. 启动Vue.js前端应用")
        logger.info("  3. 上传Excel文件测试查重功能")
        logger.info("  4. 在管理后台调优规则和词典")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 一键设置过程中发生错误: {e}")
        logger.exception("详细错误信息:")
        return False


def print_usage():
    """打印使用说明"""
    print("""
🔧 智能物料查重工具 - 一键设置程序

📋 功能说明:
  本程序将自动完成以下操作：
  1. 连接Oracle数据库，分析所有物料信息
  2. 基于真实数据生成属性提取规则和同义词典
  3. 初始化PostgreSQL数据库并导入规则和词典
  4. 创建必要的索引和约束

⚙️ 环境要求:
  - Python 3.10+
  - oracledb, asyncpg, pandas, numpy 模块
  - Oracle数据库访问权限
  - PostgreSQL数据库访问权限

🔧 环境变量配置:
  Oracle连接 (在oracle_config.py中配置):
    - ORACLE_READONLY_PASSWORD: Oracle数据库密码
  
  PostgreSQL连接:
    - PG_HOST: PostgreSQL主机 (默认: localhost)
    - PG_PORT: PostgreSQL端口 (默认: 5432)
    - PG_DATABASE: 数据库名 (默认: matmatch)
    - PG_USERNAME: 用户名 (默认: matmatch)
    - PG_PASSWORD: 密码 (默认: matmatch)

🚀 使用方法:
  python one_click_setup.py

📊 预期结果:
  - 分析数万条物料数据
  - 生成数百条提取规则
  - 生成数千个同义词组
  - 完成PostgreSQL数据库初始化
    """)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] in ['-h', '--help', 'help']:
        print_usage()
        sys.exit(0)
    
    print("🎯 准备启动一键设置程序...")
    print("💡 如需查看详细说明，请运行: python one_click_setup.py --help")
    print("")
    
    input("按回车键继续，或Ctrl+C取消...")
    
    success = asyncio.run(one_click_setup())
    sys.exit(0 if success else 1)
