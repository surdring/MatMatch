"""
测试批量查重API
"""
import requests

# 测试文件路径（使用最新生成的测试文件）
test_file = r"D:\develop\python\MatMatch\temp\物料查重测试数据_20251007_060659.xlsx"

# API地址
url = "http://localhost:8000/api/v1/materials/batch-search"

# 准备请求
files = {'file': open(test_file, 'rb')}
data = {
    # 留空让后端自动检测
}

try:
    print("正在发送请求...")
    response = requests.post(url, files=files, data=data, timeout=60)
    
    print(f"\n状态码: {response.status_code}")
    print(f"\n响应头: {response.headers}")
    print(f"\n响应内容:")
    
    if response.status_code == 200:
        result = response.json()
        print(f"  - success: {result.get('success')}")
        print(f"  - total_processed: {result.get('total_processed')}")
        print(f"  - results数量: {len(result.get('results', []))}")
        print(f"  - processing_time: {result.get('processing_time')}ms")
        
        if result.get('results'):
            print(f"\n第一条结果示例:")
            first_result = result['results'][0]
            print(f"  - row_number: {first_result.get('row_number')}")
            print(f"  - input_data: {first_result.get('input_data')}")
            
            # 显示parsed_query（AI推荐分类）
            parsed_query = first_result.get('parsed_query', {})
            if parsed_query:
                print(f"  - parsed_query:")
                print(f"    - detected_category（AI推荐分类）: {parsed_query.get('detected_category')}")
                print(f"    - confidence（置信度）: {parsed_query.get('confidence')}")
                print(f"    - standardized_name: {parsed_query.get('standardized_name')}")
            
            print(f"  - similar_materials数量: {len(first_result.get('similar_materials', []))}")
    else:
        print(response.text)
        
except Exception as e:
    print(f"\n错误: {e}")
    import traceback
    traceback.print_exc()

