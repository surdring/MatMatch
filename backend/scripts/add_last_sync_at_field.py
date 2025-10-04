"""
添加last_sync_at字段到materials_master表
"""

import asyncio
import sys
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from backend.core.config import database_config


async def add_field():
    """添加last_sync_at字段"""
    
    # 创建数据库引擎
    engine = create_async_engine(database_config.database_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        # 检查字段是否已存在
        check_sql = """
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'materials_master' 
        AND column_name = 'last_sync_at'
        """
        result = await session.execute(text(check_sql))
        exists = result.fetchone() is not None
        
        if exists:
            print("✅ 字段 last_sync_at 已存在")
            return
        
        # 添加字段
        alter_sql = """
        ALTER TABLE materials_master 
        ADD COLUMN last_sync_at TIMESTAMP WITH TIME ZONE
        """
        
        try:
            await session.execute(text(alter_sql))
            await session.commit()
            print("✅ 成功添加字段 last_sync_at 到 materials_master 表")
        except Exception as e:
            await session.rollback()
            print(f"❌ 添加字段失败: {e}")
            raise


if __name__ == "__main__":
    asyncio.run(add_field())

