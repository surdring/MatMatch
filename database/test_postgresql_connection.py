"""
PostgreSQL数据库连接测试脚本
测试与远程PostgreSQL服务器的连接并创建matmatch数据库和基础表结构
"""

import asyncio
import asyncpg
import logging
import sys

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class PostgreSQLTester:
    """PostgreSQL连接测试器"""
    
    def __init__(self):
        # 数据库配置
        self.pg_config = {
            'host': '127.0.0.1',
            'port': 5432,
            'user': 'postgres',
            'password': 'xqxatcdj'
        }
        self.connection = None
    
    async def test_connection(self):
        """测试基本连接"""
        logger.info("🔍 测试PostgreSQL连接...")
        try:
            # 连接到默认的postgres数据库
            config = self.pg_config.copy()
            config['database'] = 'postgres'
            
            self.connection = await asyncpg.connect(**config)
            logger.info("✅ PostgreSQL连接成功")
            
            # 获取版本信息
            version = await self.connection.fetchval("SELECT version()")
            logger.info(f"📊 数据库版本: {version}")
            
            return True
        except Exception as e:
            logger.error(f"❌ PostgreSQL连接失败: {e}")
            return False
    
    async def check_database_exists(self, database_name: str):
        """检查数据库是否存在"""
        logger.info(f"🔍 检查数据库 '{database_name}' 是否存在...")
        try:
            result = await self.connection.fetchval(
                "SELECT 1 FROM pg_database WHERE datname = $1", 
                database_name
            )
            exists = result is not None
            logger.info(f"📊 数据库 '{database_name}' {'存在' if exists else '不存在'}")
            return exists
        except Exception as e:
            logger.error(f"❌ 检查数据库失败: {e}")
            return False
    
    async def create_database(self, database_name: str):
        """创建数据库"""
        logger.info(f"🏗️ 创建数据库 '{database_name}'...")
        try:
            # 检查是否已存在
            if await self.check_database_exists(database_name):
                logger.info(f"ℹ️ 数据库 '{database_name}' 已存在，跳过创建")
                return True
            
            # 创建数据库
            await self.connection.execute(f'CREATE DATABASE "{database_name}"')
            logger.info(f"✅ 数据库 '{database_name}' 创建成功")
            return True
        except Exception as e:
            logger.error(f"❌ 创建数据库失败: {e}")
            return False
    
    async def test_matmatch_connection(self):
        """测试连接到matmatch数据库"""
        logger.info("🔍 测试matmatch数据库连接...")
        try:
            # 断开当前连接
            if self.connection:
                await self.connection.close()
            
            # 连接到matmatch数据库
            config = self.pg_config.copy()
            config['database'] = 'matmatch'
            
            self.connection = await asyncpg.connect(**config)
            logger.info("✅ matmatch数据库连接成功")
            return True
        except Exception as e:
            logger.error(f"❌ matmatch数据库连接失败: {e}")
            return False
    
    async def create_extensions(self):
        """创建必要的扩展"""
        logger.info("🔧 创建PostgreSQL扩展...")
        try:
            # 创建pg_trgm扩展（用于相似度搜索）
            await self.connection.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
            logger.info("✅ pg_trgm扩展创建成功")
            
            # 创建unaccent扩展（用于去重音符号）
            await self.connection.execute("CREATE EXTENSION IF NOT EXISTS unaccent")
            logger.info("✅ unaccent扩展创建成功")
            
            return True
        except Exception as e:
            logger.error(f"❌ 创建扩展失败: {e}")
            return False
    
    async def test_basic_operations(self):
        """测试基本数据库操作"""
        logger.info("🧪 测试基本数据库操作...")
        try:
            # 创建测试表
            await self.connection.execute("""
                CREATE TABLE IF NOT EXISTS test_table (
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # 插入测试数据
            await self.connection.execute(
                "INSERT INTO test_table (name) VALUES ($1)", 
                "测试数据"
            )
            
            # 查询测试数据
            result = await self.connection.fetchval(
                "SELECT name FROM test_table WHERE name = $1", 
                "测试数据"
            )
            
            # 删除测试表
            await self.connection.execute("DROP TABLE IF EXISTS test_table")
            
            if result == "测试数据":
                logger.info("✅ 基本数据库操作测试成功")
                return True
            else:
                logger.error("❌ 基本数据库操作测试失败")
                return False
                
        except Exception as e:
            logger.error(f"❌ 基本数据库操作测试失败: {e}")
            return False
    
    async def disconnect(self):
        """断开连接"""
        if self.connection:
            await self.connection.close()
            logger.info("🔌 数据库连接已断开")


async def main():
    """主函数"""
    logger.info("🚀 开始PostgreSQL数据库连接测试")
    
    tester = PostgreSQLTester()
    
    try:
        # 1. 测试基本连接
        if not await tester.test_connection():
            logger.error("❌ 基本连接失败，退出测试")
            return False
        
        # 2. 创建matmatch数据库
        if not await tester.create_database('matmatch'):
            logger.error("❌ 创建数据库失败，退出测试")
            return False
        
        # 3. 测试matmatch数据库连接
        if not await tester.test_matmatch_connection():
            logger.error("❌ matmatch数据库连接失败，退出测试")
            return False
        
        # 4. 创建扩展
        if not await tester.create_extensions():
            logger.error("❌ 创建扩展失败，退出测试")
            return False
        
        # 5. 测试基本操作
        if not await tester.test_basic_operations():
            logger.error("❌ 基本操作测试失败，退出测试")
            return False
        
        logger.info("🎉 PostgreSQL数据库连接测试完成！")
        logger.info("💡 数据库已准备就绪，可以开始导入规则和词典")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 测试过程中发生错误: {e}")
        return False
    finally:
        await tester.disconnect()


if __name__ == "__main__":
    success = asyncio.run(main())
    if success:
        print("\n✅ 所有测试通过！数据库准备就绪。")
        sys.exit(0)
    else:
        print("\n❌ 测试失败！请检查数据库配置。")
        sys.exit(1)
