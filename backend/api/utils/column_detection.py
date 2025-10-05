"""
列名检测工具

实现智能列名匹配和必需列检测功能
支持自动检测、手动指定、模糊匹配等多种方式
"""

from typing import List, Dict, Optional
from rapidfuzz.distance import Levenshtein

from backend.api.schemas.batch_search_schemas import RequiredColumnsMissingError


# ============================================================================
# 列名检测模式（优先级列表）
# ============================================================================

# 名称列检测优先级
NAME_PATTERNS = [
    "物料名称", "材料名称", "名称", "品名",  # 中文
    "Material Name", "Name", "Item Name", "Material"  # 英文
]

# 规格型号列检测优先级
SPEC_PATTERNS = [
    "规格型号", "规格", "型号", "规格说明", "Specification", "Spec", "Model"  # 中文 + 英文
]

# 单位列检测优先级
UNIT_PATTERNS = [
    "单位", "计量单位", "基本单位",  # 中文
    "Unit", "Measurement Unit", "UOM"  # 英文
]


# ============================================================================
# 核心检测函数
# ============================================================================

def detect_required_columns(
    available_columns: List[str],
    name_column: Optional[str] = None,
    spec_column: Optional[str] = None,
    unit_column: Optional[str] = None
) -> Dict[str, str]:
    """
    检测必需的3个列（名称、规格、单位）
    
    支持4种检测方式：
    1. 用户手动指定（精确控制）
    2. 系统自动检测（便捷性）
    3. 列索引指定（无标题行）
    4. 混合模式（部分指定，部分自动）
    
    Args:
        available_columns: Excel文件中所有可用的列名列表
        name_column: 用户指定的名称列（None时自动检测）
        spec_column: 用户指定的规格列（None时自动检测）
        unit_column: 用户指定的单位列（None时自动检测）
    
    Returns:
        Dict[str, str]: 检测到的列名映射
            {
                "name": "物料名称",     # 实际使用的名称列
                "spec": "规格型号",     # 实际使用的规格列
                "unit": "单位"          # 实际使用的单位列
            }
    
    Raises:
        RequiredColumnsMissingError: 当缺少必需列时抛出，包含可用列名和智能推荐
    
    Example:
        >>> columns = ["序号", "物料名称", "规格型号", "单位"]
        >>> detect_required_columns(columns)
        {"name": "物料名称", "spec": "规格型号", "unit": "单位"}
        
        >>> detect_required_columns(columns, name_column="物料名称")
        {"name": "物料名称", "spec": "规格型号", "unit": "单位"}
    """
    result = {}
    missing = []
    suggestions = {}
    
    # 1. 检测名称列
    if name_column:
        # 用户手动指定
        matched = match_column_name(name_column, available_columns)
        if matched:
            result["name"] = matched
        else:
            missing.append("名称")
            # 生成推荐
            suggestions["名称"] = _generate_suggestions(name_column, available_columns)
    else:
        # 自动检测
        detected = auto_detect_column(NAME_PATTERNS, available_columns)
        if detected:
            result["name"] = detected
        else:
            missing.append("名称")
            suggestions["名称"] = []
    
    # 2. 检测规格型号列
    if spec_column:
        matched = match_column_name(spec_column, available_columns)
        if matched:
            result["spec"] = matched
        else:
            missing.append("规格型号")
            suggestions["规格型号"] = _generate_suggestions(spec_column, available_columns)
    else:
        detected = auto_detect_column(SPEC_PATTERNS, available_columns)
        if detected:
            result["spec"] = detected
        else:
            missing.append("规格型号")
            suggestions["规格型号"] = []
    
    # 3. 检测单位列
    if unit_column:
        matched = match_column_name(unit_column, available_columns)
        if matched:
            result["unit"] = matched
        else:
            missing.append("单位")
            suggestions["单位"] = _generate_suggestions(unit_column, available_columns)
    else:
        detected = auto_detect_column(UNIT_PATTERNS, available_columns)
        if detected:
            result["unit"] = detected
        else:
            missing.append("单位")
            suggestions["单位"] = []
    
    # 4. 验证必需列
    if missing:
        raise RequiredColumnsMissingError(
            missing_columns=missing,
            available_columns=available_columns,
            suggestions=suggestions
        )
    
    return result


def match_column_name(
    input_name: str,
    available_columns: List[str]
) -> Optional[str]:
    """
    智能匹配单个列名
    
    匹配规则（按优先级）：
    1. 精确匹配（不区分大小写）
    2. 去除空格后匹配
    3. 模糊匹配（Levenshtein距离≤2）
    
    Args:
        input_name: 用户输入的列名
        available_columns: 可用的列名列表
    
    Returns:
        Optional[str]: 匹配到的列名，未找到返回None
    
    Example:
        >>> match_column_name("物料名称", ["序号", "物料名称", "规格"])
        "物料名称"
        
        >>> match_column_name("物料明称", ["序号", "物料名称", "规格"])  # 错别字
        "物料名称"  # 通过模糊匹配
        
        >>> match_column_name("Material Name", ["Name", "Spec"])
        None  # 未找到匹配
    """
    if not input_name or not available_columns:
        return None
    
    # 标准化输入（去除空格、转小写）
    normalized_input = input_name.strip().lower()
    
    # 1. 精确匹配（不区分大小写）
    for col in available_columns:
        if col.strip().lower() == normalized_input:
            return col
    
    # 2. 模糊匹配（Levenshtein距离≤2，使用rapidfuzz）
    for col in available_columns:
        col_normalized = col.strip().lower()
        distance = Levenshtein.distance(normalized_input, col_normalized)
        if distance <= 2:
            return col
    
    return None


def auto_detect_column(
    patterns: List[str],
    available_columns: List[str]
) -> Optional[str]:
    """
    按优先级自动检测列名
    
    遍历优先级模式列表，找到第一个匹配的列名
    
    Args:
        patterns: 优先级列表（如NAME_PATTERNS）
        available_columns: 可用列名列表
    
    Returns:
        Optional[str]: 检测到的列名，未找到返回None
    
    Example:
        >>> patterns = ["物料名称", "材料名称", "名称"]
        >>> columns = ["序号", "材料名称", "规格"]
        >>> auto_detect_column(patterns, columns)
        "材料名称"  # 匹配第2个pattern
    """
    if not patterns or not available_columns:
        return None
    
    # 按优先级匹配
    for pattern in patterns:
        pattern_lower = pattern.lower()
        
        for col in available_columns:
            col_lower = col.strip().lower()
            
            # 包含匹配或被包含匹配
            if pattern_lower in col_lower or col_lower in pattern_lower:
                return col
    
    return None


# ============================================================================
# 辅助函数
# ============================================================================

def _generate_suggestions(
    input_name: str,
    available_columns: List[str],
    max_suggestions: int = 3
) -> List[str]:
    """
    生成智能推荐列名（基于相似度）
    
    Args:
        input_name: 用户输入的列名
        available_columns: 可用列名列表
        max_suggestions: 最多返回的推荐数
    
    Returns:
        List[str]: 推荐的列名列表
    """
    if not input_name or not available_columns:
        return []
    
    # 计算每个列名与输入的相似度（使用rapidfuzz）
    similarities = []
    input_lower = input_name.strip().lower()
    
    for col in available_columns:
        col_lower = col.strip().lower()
        distance = Levenshtein.distance(input_lower, col_lower)
        # 距离越小，相似度越高
        similarities.append((col, distance))
    
    # 按距离排序（升序）
    similarities.sort(key=lambda x: x[1])
    
    # 返回前N个推荐（距离≤5）
    suggestions = [col for col, dist in similarities[:max_suggestions] if dist <= 5]
    
    return suggestions

