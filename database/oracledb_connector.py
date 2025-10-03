"""
Oracle数据库连接器
提供与Oracle数据库的连接和查询功能
"""

import oracledb
from typing import List, Dict, Any, Optional
import logging
import os

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class OracleDBConnector:
    """Oracle数据库连接器类"""
    
    def __init__(self, host: str, port: int, service_name: str, 
                 username: str, password: str):
        """
        初始化数据库连接器
        
        Args:
            host: 数据库主机地址
            port: 数据库端口
            service_name: 服务名
            username: 用户名
            password: 密码
        """
        self.host = host
        self.port = port
        self.service_name = service_name
        self.username = username
        self.password = password
        self.connection = None
        
    def connect(self) -> bool:
        """建立数据库连接"""
        try:
            # 尝试使用thick模式（需要Oracle客户端）
            # 如果系统中有Oracle客户端，oracledb会自动使用thick模式
            # 如果没有客户端，会回退到thin模式
            
            # 设置thick模式（如果可用）
            try:
                oracledb.init_oracle_client()
                logger.info("🔧 使用Oracle thick模式连接")
            except Exception:
                logger.info("🔧 使用Oracle thin模式连接（无客户端）")
            
            dsn = oracledb.makedsn(self.host, self.port, service_name=self.service_name)
            self.connection = oracledb.connect(
                user=self.username,
                password=self.password,
                dsn=dsn
            )
            logger.info("✅ Oracle数据库连接成功")
            return True
        except Exception as e:
            logger.error(f"❌ 数据库连接失败: {e}")
            return False
    
    def disconnect(self):
        """断开数据库连接"""
        if self.connection:
            self.connection.close()
            logger.info("🔌 数据库连接已断开")
    
    def execute_query(self, query: str, params: Optional[Dict] = None) -> List[Dict[str, Any]]:
        """
        执行查询并返回结果
        
        Args:
            query: SQL查询语句
            params: 查询参数
            
        Returns:
            查询结果列表
        """
        if not self.connection:
            logger.error("❌ 数据库未连接")
            return []
            
        try:
            cursor = self.connection.cursor()
            
            # 执行查询
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            # 获取列名
            columns = [col[0] for col in cursor.description]
            
            # 获取所有结果
            results = []
            for row in cursor:
                results.append(dict(zip(columns, row)))
            
            cursor.close()
            logger.info(f"📊 查询成功，返回 {len(results)} 条记录")
            return results
            
        except Exception as e:
            logger.error(f"❌ 查询执行失败: {e}")
            return []
    
    def execute_query_batch(self, query: str, batch_size: int = 1000) -> List[Dict[str, Any]]:
        """
        分批执行查询，避免内存溢出
        
        Args:
            query: SQL查询语句
            batch_size: 每批大小
            
        Returns:
            所有查询结果
        """
        if not self.connection:
            logger.error("❌ 数据库未连接")
            return []
            
        try:
            cursor = self.connection.cursor()
            cursor.execute(query)
            
            # 获取列名
            columns = [col[0] for col in cursor.description]
            
            all_results = []
            batch_count = 0
            
            while True:
                # 获取一批数据
                rows = cursor.fetchmany(batch_size)
                if not rows:
                    break
                    
                # 转换为字典格式
                batch_results = [dict(zip(columns, row)) for row in rows]
                all_results.extend(batch_results)
                batch_count += 1
                
                logger.info(f"📦 已处理第 {batch_count} 批数据，当前总数: {len(all_results)}")
            
            cursor.close()
            logger.info(f"✅ 分批查询完成，共 {len(all_results)} 条记录")
            return all_results
            
        except Exception as e:
            logger.error(f"❌ 分批查询失败: {e}")
            return []
    
    def test_connection(self) -> bool:
        """测试数据库连接"""
        try:
            if self.connect():
                # 执行简单查询测试
                cursor = self.connection.cursor()
                cursor.execute("SELECT 1 FROM DUAL")
                result = cursor.fetchone()
                cursor.close()
                
                if result and result[0] == 1:
                    logger.info("✅ 数据库连接测试通过")
                    return True
            return False
        except Exception as e:
            logger.error(f"❌ 连接测试失败: {e}")
            return False


if __name__ == "__main__":
    # 测试代码 - 使用您提供的配置
    import os
    connector = OracleDBConnector(
        host="192.168.80.90",
        port=1521,
        service_name="ORCL",
        username="matmatch_read",
        password=os.getenv('ORACLE_READONLY_PASSWORD', 'matmatch_read')
    )
    
    if connector.test_connection():
        print("连接测试成功")
    else:
        print("连接测试失败")