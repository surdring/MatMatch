"""
检查BD_MATERIAL表的实际字段
"""

import logging
from oracledb_connector import OracleDBConnector
from oracle_config import OracleConfig

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def check_material_fields():
    """检查BD_MATERIAL表的字段"""
    logger.info("🔍 检查BD_MATERIAL表的字段...")
    
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
        # 查看BD_MATERIAL表的所有字段
        logger.info("📋 查询BD_MATERIAL表的所有字段...")
        fields_query = """
        SELECT column_name, data_type, data_length, nullable
        FROM all_tab_columns 
        WHERE table_name = 'BD_MATERIAL' AND owner = 'DHNC65'
        ORDER BY column_id
        """
        
        fields = connector.execute_query(fields_query)
        logger.info(f"✅ BD_MATERIAL表包含 {len(fields)} 个字段:")
        
        for field in fields:
            nullable = "NULL" if field['NULLABLE'] == 'Y' else "NOT NULL"
            logger.info(f"  {field['COLUMN_NAME']}: {field['DATA_TYPE']}({field['DATA_LENGTH']}) {nullable}")
        
        # 查询几条样本数据
        logger.info("\n📊 查询样本数据...")
        sample_query = """
        SELECT * FROM DHNC65.bd_material 
        WHERE ROWNUM <= 3
        """
        
        samples = connector.execute_query(sample_query)
        if samples:
            logger.info(f"✅ 获取到 {len(samples)} 条样本数据")
            for i, sample in enumerate(samples, 1):
                logger.info(f"\n样本 {i}:")
                for key, value in sample.items():
                    if value is not None:
                        logger.info(f"  {key}: {str(value)[:50]}...")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 检查过程中发生错误: {e}")
        return False
    finally:
        connector.disconnect()

if __name__ == "__main__":
    check_material_fields()
