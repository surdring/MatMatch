#!/usr/bin/env python3
"""
管理后台修复自动验证脚本
快速验证数据库和后端API状态
"""

import asyncio
import asyncpg
import httpx

# 配置
DB_CONFIG = {
    'host': '127.0.0.1',
    'port': 5432,
    'user': 'postgres',
    'password': 'xqxatcdj',
    'database': 'matmatch'
}

API_BASE = 'http://localhost:8000'
ADMIN_TOKEN = 'admin_dev_token_change_in_production'

async def main():
    print('=' * 60)
    print('  管理后台修复验证')
    print('=' * 60)
    print()
    
    # 1. 验证数据库
    print('📊 验证数据库...')
    try:
        conn = await asyncpg.connect(**DB_CONFIG)
        
        tables = [
            ('extraction_rules', 6),
            ('synonyms', 124),
            ('knowledge_categories', 1568),
            ('etl_job_logs', 0)
        ]
        
        for table, expected in tables:
            count = await conn.fetchval(f'SELECT COUNT(*) FROM {table}')
            status = '✅' if count >= expected else '❌'
            print(f'  {status} {table}: {count}条 (预期≥{expected})')
        
        await conn.close()
    except Exception as e:
        print(f'  ❌ 数据库连接失败: {e}')
        return
    
    print()
    
    # 2. 验证后端API
    print('🌐 验证后端API...')
    
    headers = {'Authorization': f'Bearer {ADMIN_TOKEN}'}
    
    apis = [
        '/api/v1/admin/extraction-rules?page=1&page_size=20',
        '/api/v1/admin/synonyms?page=1&page_size=20',
        '/api/v1/admin/categories?page=1&page_size=20',
        '/api/v1/admin/etl/jobs?page=1&page_size=20'
    ]
    
    async with httpx.AsyncClient() as client:
        for api in apis:
            try:
                response = await client.get(API_BASE + api, headers=headers, timeout=5.0)
                if response.status_code == 200:
                    data = response.json()
                    items = data.get('data', {}).get('items', []) if 'data' in data else data.get('items', [])
                    print(f'  ✅ {api.split("?")[0]}: {len(items)}条数据')
                else:
                    print(f'  ❌ {api.split("?")[0]}: {response.status_code}')
            except Exception as e:
                print(f'  ❌ {api.split("?")[0]}: {str(e)}')
    
    print()
    print('=' * 60)
    print('✅ 后端验证完成！')
    print()
    print('📋 前端验证步骤（需要手动）：')
    print('  1. 打开浏览器控制台（F12）')
    print('  2. 执行: localStorage.clear(); location.reload()')
    print('  3. 访问: http://localhost:3000/admin')
    print('  4. 输入密码: admin123')
    print('  5. 验证4个Tab是否有数据')
    print('=' * 60)

if __name__ == '__main__':
    asyncio.run(main())

