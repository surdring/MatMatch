"""检查数据库中的数据量"""
import asyncio
import sys
from pathlib import Path

project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from sqlalchemy import text
from backend.database.session import db_manager


async def check_data():
    async with db_manager.get_session() as session:
        # 检查materials_master
        result = await session.execute(text('SELECT COUNT(*) FROM materials_master'))
        materials_count = result.scalar()
        print(f'materials_master表记录数: {materials_count}')
        
        # 检查synonyms
        result = await session.execute(text('SELECT COUNT(*) FROM synonyms'))
        synonyms_count = result.scalar()
        print(f'synonyms表记录数: {synonyms_count}')
        
        # 检查attribute_extraction_rules
        result = await session.execute(text('SELECT COUNT(*) FROM attribute_extraction_rules'))
        rules_count = result.scalar()
        print(f'attribute_extraction_rules表记录数: {rules_count}')
        
        # 检查knowledge_categories
        result = await session.execute(text('SELECT COUNT(*) FROM knowledge_categories'))
        categories_count = result.scalar()
        print(f'knowledge_categories表记录数: {categories_count}')
        
        # 检查materials_master中有normalized_name的记录
        result = await session.execute(text(
            'SELECT COUNT(*) FROM materials_master WHERE normalized_name IS NOT NULL'
        ))
        processed_count = result.scalar()
        print(f'materials_master已处理记录数: {processed_count}')
        
        # 显示materials_master的前3条数据
        print("\nmaterials_master前3条数据:")
        result = await session.execute(text(
            'SELECT id, erp_code, material_name, normalized_name, detected_category FROM materials_master LIMIT 3'
        ))
        for row in result:
            print(f"  ID: {row[0]}, ERP: {row[1]}, 名称: {row[2]}, 标准化: {row[3]}, 分类: {row[4]}")


if __name__ == '__main__':
    asyncio.run(check_data())

