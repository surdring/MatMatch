"""
Oracle数据库连接测试脚本
测试与Oracle数据库的连接和基本功能
"""

import os
import sys
import logging
from datetime import datetime

# 添加当前目录到Python路径
sys.path.append(os.path.dirname(__file__))

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('database_connection_test.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def test_oracle_connection():
    """测试Oracle数据库连接"""
    
    logger.info("🚀 开始Oracle数据库连接测试")
    logger.info(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 环境检查
    logger.info("📋 环境检查:")
    logger.info(f"Python路径: {sys.executable}")
    logger.info(f"Python版本: {sys.version}")
    
    # 检查oracledb模块
    try:
        import oracledb
        logger.info(f"✅ oracledb模块已安装，版本: {oracledb.__version__}")
    except ImportError as e:
        logger.error(f"❌ oracledb模块导入失败: {e}")
        return False
    
    # 检查环境变量
    oracle_password = os.getenv('ORACLE_READONLY_PASSWORD', 'matmatch_read')
    if oracle_password == 'matmatch_read':
        logger.warning("⚠️  使用默认密码，建议设置ORACLE_READONLY_PASSWORD环境变量")
    else:
        logger.info("✅ 使用环境变量中的密码")
    
    # 导入连接器
    try:
        from oracledb_connector import OracleDBConnector
        logger.info("✅ OracleDBConnector导入成功")
    except ImportError as e:
        logger.error(f"❌ OracleDBConnector导入失败: {e}")
        return False
    
    # 创建连接器实例
    connector = OracleDBConnector(
        host="192.168.80.90",
        port=1521,
        service_name="ORCL",
        username="matmatch_read",
        password=oracle_password
    )
    
    logger.info("📊 连接配置信息:")
    logger.info(f"  主机: {connector.host}")
    logger.info(f"  端口: {connector.port}")
    logger.info(f"  服务名: {connector.service_name}")
    logger.info(f"  用户名: {connector.username}")
    logger.info(f"  密码: {'*' * len(connector.password)}")
    
    # 测试连接
    logger.info("🔗 开始连接测试...")
    
    try:
        if connector.test_connection():
            logger.info("✅ 数据库连接测试成功")
            
            # 测试基本查询
            logger.info("📊 测试基本查询功能...")
            
            # 查询DUAL表
            results = connector.execute_query("SELECT 1 as test_value, SYSDATE as current_time FROM DUAL")
            if results:
                logger.info(f"✅ DUAL表查询成功: {results[0]}")
            else:
                logger.error("❌ DUAL表查询失败")
                return False
            
            # 测试断开连接
            connector.disconnect()
            logger.info("✅ 连接断开测试成功")
            
            return True
            
        else:
            logger.error("❌ 数据库连接测试失败")
            return False
            
    except Exception as e:
        logger.error(f"❌ 连接测试过程中发生异常: {e}")
        return False

def main():
    """主函数"""
    logger.info("=" * 60)
    logger.info("📋 Oracle数据库连接测试报告")
    logger.info("=" * 60)
    
    success = test_oracle_connection()
    
    logger.info("=" * 60)
    if success:
        logger.info("🎉 所有测试通过！数据库连接配置正确。")
    else:
        logger.error("💥 测试失败！请检查数据库连接配置。")
    logger.info("=" * 60)
    
    return success

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)