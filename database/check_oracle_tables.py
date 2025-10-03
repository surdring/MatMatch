"""
检查Oracle数据库中的表结构
"""

import logging
from oracledb_connector import OracleDBConnector
from oracle_config import OracleConfig

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def check_oracle_tables():
    """检查Oracle数据库中的表"""
    logger.info("🔍 检查Oracle数据库中的表结构...")
    
    # 创建连接
    config_params = OracleConfig.get_connection_params()
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
        # 1. 查看当前用户可访问的所有表
        logger.info("📋 查询当前用户可访问的表...")
        tables_query = """
        SELECT table_name, owner 
        FROM all_tables 
        WHERE owner IN (USER, 'PUBLIC') 
           OR table_name LIKE '%MATERIAL%' 
           OR table_name LIKE '%BD_%'
        ORDER BY owner, table_name
        """
        
        tables = connector.execute_query(tables_query)
        logger.info(f"✅ 找到 {len(tables)} 个表")
        
        for table in tables[:20]:  # 显示前20个
            logger.info(f"  📄 {table['OWNER']}.{table['TABLE_NAME']}")
        
        # 2. 专门查找物料相关的表
        logger.info("\n🔍 查找物料相关的表...")
        material_tables_query = """
        SELECT table_name, owner 
        FROM all_tables 
        WHERE UPPER(table_name) LIKE '%MATERIAL%' 
           OR UPPER(table_name) LIKE '%BD_MAR%'
           OR UPPER(table_name) LIKE '%BD_MEAS%'
        ORDER BY table_name
        """
        
        material_tables = connector.execute_query(material_tables_query)
        logger.info(f"✅ 找到 {len(material_tables)} 个物料相关表")
        
        for table in material_tables:
            logger.info(f"  🏷️ {table['OWNER']}.{table['TABLE_NAME']}")
        
        # 3. 查看具体表的结构（如果存在）
        test_tables = ['BD_MATERIAL', 'BD_MARBASCLASS', 'BD_MEASDOC']
        
        for table_name in test_tables:
            logger.info(f"\n🔍 检查表 {table_name} 的结构...")
            
            # 查看表结构
            desc_query = f"""
            SELECT column_name, data_type, data_length, nullable
            FROM all_tab_columns 
            WHERE table_name = UPPER('{table_name}')
            ORDER BY column_id
            """
            
            columns = connector.execute_query(desc_query)
            if columns:
                logger.info(f"✅ 表 {table_name} 存在，包含 {len(columns)} 个字段:")
                for col in columns[:10]:  # 显示前10个字段
                    nullable = "NULL" if col['NULLABLE'] == 'Y' else "NOT NULL"
                    logger.info(f"    {col['COLUMN_NAME']}: {col['DATA_TYPE']}({col['DATA_LENGTH']}) {nullable}")
                
                # 查询少量数据样本
                sample_query = f"SELECT * FROM {table_name} WHERE ROWNUM <= 3"
                samples = connector.execute_query(sample_query)
                if samples:
                    logger.info(f"  📊 样本数据: {len(samples)} 条")
                    for i, sample in enumerate(samples, 1):
                        logger.info(f"    样本{i}: {dict(list(sample.items())[:3])}")  # 显示前3个字段
            else:
                logger.warning(f"⚠️ 表 {table_name} 不存在或无访问权限")
        
        # 4. 查看当前用户权限
        logger.info("\n🔐 检查当前用户权限...")
        user_query = "SELECT USER FROM DUAL"
        current_user = connector.execute_query(user_query)
        if current_user:
            logger.info(f"当前用户: {current_user[0]['USER']}")
        
        # 查看用户拥有的权限
        privileges_query = """
        SELECT privilege, grantee 
        FROM user_tab_privs 
        WHERE table_name LIKE '%MATERIAL%' OR table_name LIKE '%BD_%'
        """
        privileges = connector.execute_query(privileges_query)
        logger.info(f"用户权限: {len(privileges)} 个相关权限")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 检查过程中发生错误: {e}")
        return False
    finally:
        connector.disconnect()

if __name__ == "__main__":
    check_oracle_tables()
