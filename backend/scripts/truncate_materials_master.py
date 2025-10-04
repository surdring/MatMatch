"""
清空materials_master表，准备重新同步全部数据
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


async def truncate_table():
    """清空materials_master表"""
    
    # 创建数据库引擎
    engine = create_async_engine(database_config.database_url, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as session:
        try:
            # 查询当前记录数
            result = await session.execute(text('SELECT COUNT(*) as cnt FROM materials_master'))
            current_count = result.scalar()
            print(f"📊 当前materials_master表记录数: {current_count:,}条")
            
            if current_count == 0:
                print("✅ 表已为空，无需清空")
                return
            
            # 确认清空操作
            print(f"\n⚠️  即将清空materials_master表的所有{current_count:,}条记录")
            print("   （这是为了重新导入Oracle中的全部物料基础数据）")
            response = input("   确认继续？(yes/no): ")
            
            if response.lower() not in ['yes', 'y']:
                print("❌ 操作已取消")
                return
            
            # 清空表
            await session.execute(text('TRUNCATE TABLE materials_master RESTART IDENTITY CASCADE'))
            await session.commit()
            
            print(f"✅ materials_master表已清空")
            print(f"   准备同步Oracle中的全部物料基础数据（包含所有状态）")
            
        except Exception as e:
            await session.rollback()
            print(f"❌ 清空表失败: {e}")
            raise


if __name__ == "__main__":
    asyncio.run(truncate_table())

