"""
数据库初始化脚本
用于首次部署时的数据库初始化

对应 [I.2] 编码策略中的数据库初始化脚本实现
"""

import asyncio
import sys
import logging
from pathlib import Path

# 添加backend目录到Python路径
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

from database.migrations import run_full_migration
from tests.test_database import run_all_tests

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def main():
    """
    主初始化流程
    
    执行数据库迁移和基础测试
    对应 [I.2] - 数据库初始化和验证流程
    """
    logger.info("🚀 开始数据库初始化...")
    
    try:
        # 1. 运行数据库迁移
        logger.info("📋 执行数据库迁移...")
        migration_success = await run_full_migration()
        
        if not migration_success:
            logger.error("❌ 数据库迁移失败")
            return False
        
        # 2. 运行基础测试验证
        logger.info("🧪 运行验证测试...")
        test_success = await run_all_tests()
        
        if not test_success:
            logger.error("❌ 数据库验证测试失败")
            return False
        
        logger.info("🎉 数据库初始化完成！")
        logger.info("💡 现在可以开始API开发工作")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ 初始化过程中发生错误: {e}")
        return False


if __name__ == "__main__":
    """
    命令行执行数据库初始化
    """
    success = asyncio.run(main())
    
    if success:
        print("\n✅ 数据库初始化成功！")
        print("📋 Task 1.1: PostgreSQL数据库设计与实现 - 已完成")
        print("🔄 准备进入 [R] Review 阶段")
        sys.exit(0)
    else:
        print("\n❌ 数据库初始化失败！")
        print("🔍 请检查配置和错误日志")
        sys.exit(1)
