"""
手动测试批量查重API的核心功能
测试列名检测和模糊匹配
"""

from backend.api.utils.column_detection import (
    detect_required_columns,
    match_column_name,
    auto_detect_column,
    NAME_PATTERNS,
    SPEC_PATTERNS,
    UNIT_PATTERNS
)

def test_column_detection():
    """测试列名检测功能"""
    print("="*80)
    print("测试1: 标准列名检测")
    print("="*80)
    
    available_columns = ["序号", "物料名称", "规格型号", "单位", "备注"]
    
    try:
        result = detect_required_columns(available_columns)
        print(f"✅ 检测成功:")
        print(f"   名称列: {result['name']}")
        print(f"   规格列: {result['spec']}")
        print(f"   单位列: {result['unit']}")
    except Exception as e:
        print(f"❌ 检测失败: {e}")
    
    print("\n" + "="*80)
    print("测试2: 不同列名自动检测")
    print("="*80)
    
    available_columns2 = ["ID", "材料名称", "规格", "计量单位", "说明"]
    
    try:
        result2 = detect_required_columns(available_columns2)
        print(f"✅ 检测成功:")
        print(f"   名称列: {result2['name']}")
        print(f"   规格列: {result2['spec']}")
        print(f"   单位列: {result2['unit']}")
    except Exception as e:
        print(f"❌ 检测失败: {e}")
    
    print("\n" + "="*80)
    print("测试3: 模糊匹配（错别字）")
    print("="*80)
    
    available_columns3 = ["序号", "物料名称", "规格型号", "单位"]
    
    # 测试模糊匹配：物料明称 -> 物料名称 (Levenshtein距离=1)
    matched = match_column_name("物料明称", available_columns3)
    if matched:
        print(f"✅ 模糊匹配成功: '物料明称' -> '{matched}'")
    else:
        print(f"❌ 模糊匹配失败: '物料明称' 未找到匹配")
    
    # 测试模糊匹配：规格行号 -> 规格型号 (Levenshtein距离=2)
    matched2 = match_column_name("规格行号", available_columns3)
    if matched2:
        print(f"✅ 模糊匹配成功: '规格行号' -> '{matched2}'")
    else:
        print(f"❌ 模糊匹配失败: '规格行号' 未找到匹配")
    
    print("\n" + "="*80)
    print("测试4: 缺少必需列")
    print("="*80)
    
    available_columns4 = ["序号", "物料名称", "备注"]  # 缺少规格和单位
    
    try:
        result4 = detect_required_columns(available_columns4)
        print(f"❌ 应该失败但成功了: {result4}")
    except Exception as e:
        print(f"✅ 正确抛出异常: {type(e).__name__}")
        if hasattr(e, 'missing_columns'):
            print(f"   缺少的列: {e.missing_columns}")
            print(f"   可用的列: {e.available_columns}")
    
    print("\n" + "="*80)
    print("测试5: 英文列名")
    print("="*80)
    
    available_columns5 = ["ID", "Material Name", "Specification", "Unit"]
    
    try:
        result5 = detect_required_columns(available_columns5)
        print(f"✅ 检测成功:")
        print(f"   名称列: {result5['name']}")
        print(f"   规格列: {result5['spec']}")
        print(f"   单位列: {result5['unit']}")
    except Exception as e:
        print(f"❌ 检测失败: {e}")
    
    print("\n" + "="*80)
    print("测试6: 手动指定列名")
    print("="*80)
    
    available_columns6 = ["A", "B", "C", "D"]
    
    try:
        # 手动指定列名（使用索引风格）
        result6 = detect_required_columns(
            available_columns6,
            name_column="B",
            spec_column="C",
            unit_column="D"
        )
        print(f"✅ 手动指定成功:")
        print(f"   名称列: {result6['name']}")
        print(f"   规格列: {result6['spec']}")
        print(f"   单位列: {result6['unit']}")
    except Exception as e:
        print(f"❌ 手动指定失败: {e}")

if __name__ == "__main__":
    print("\n🚀 开始测试批量查重API的列名检测功能\n")
    test_column_detection()
    print("\n✅ 所有测试完成！\n")

