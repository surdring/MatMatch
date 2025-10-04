"""
检查Oracle数据库中的物料总数
"""

import asyncio
import sys
from pathlib import Path

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from backend.adapters.oracle_adapter import OracleConnectionAdapter
from backend.core.config import oracle_config


async def check_counts():
    """检查Oracle数据库中的物料数量"""
    
    adapter = OracleConnectionAdapter(oracle_config)
    
    try:
        # 连接Oracle
        await adapter.connect()
        print("✅ Oracle连接成功\n")
        
        # 查询总记录数
        result = await adapter.execute_query(
            'SELECT COUNT(*) as total FROM DHNC65.bd_material'
        )
        # Oracle返回的列名可能是大写或小写
        total_count = result[0].get('TOTAL') or result[0].get('total') or list(result[0].values())[0]
        print(f"📊 物料总记录数: {total_count:,}条\n")
        
        # 按启用状态分组统计
        result2 = await adapter.execute_query(
            '''SELECT enablestate, COUNT(*) as cnt 
               FROM DHNC65.bd_material 
               GROUP BY enablestate 
               ORDER BY enablestate'''
        )
        
        print("📊 按启用状态分组:")
        for row in result2:
            state = row.get('ENABLESTATE') or row.get('enablestate')
            count = row.get('CNT') or row.get('cnt')
            state_name = {
                1: '未启用',
                2: '已启用',
                3: '已停用'
            }.get(state, f'未知({state})')
            print(f"  enablestate={state} ({state_name}): {count:,}条")
        
        print(f"\n💡 建议:")
        print(f"   - ETL查询不应设置enablestate过滤条件")
        print(f"   - 应导入所有状态的物料基础数据")
        print(f"   - 业务逻辑层可根据需要过滤状态")
        
    finally:
        await adapter.disconnect()
        print("\n✅ Oracle连接已关闭")


if __name__ == "__main__":
    asyncio.run(check_counts())

