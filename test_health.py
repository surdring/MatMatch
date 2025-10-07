#!/usr/bin/env python
"""测试API健康状态"""
import requests
import json

try:
    response = requests.get('http://127.0.0.1:8000/health', timeout=5)
    data = response.json()
    print("=" * 60)
    print("API健康检查结果:")
    print("=" * 60)
    print(json.dumps(data, indent=2, ensure_ascii=False))
    print("=" * 60)
    print(f"\n整体状态: {data.get('status', 'unknown')}")
    print(f"数据库: {data.get('database', 'unknown')}")
    print(f"知识库: {data.get('knowledge_base', 'unknown')}")
    
    if data.get('status') == 'healthy':
        print("\n✅ 系统状态正常！")
    else:
        print(f"\n⚠️ 系统状态异常: {data.get('status')}")
        
except requests.exceptions.ConnectionError:
    print("❌ 无法连接到API服务器，请确认服务是否已启动")
except Exception as e:
    print(f"❌ 测试失败: {str(e)}")

