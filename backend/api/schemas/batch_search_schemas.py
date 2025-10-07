"""
批量查重API的Pydantic Schema定义

定义Task 3.2所需的所有数据模型
符合specs/main/design.md第2.1.1节的设计
"""

from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from fastapi import UploadFile

from backend.core.schemas.material_schemas import ParsedQuery


# ============================================================================
# 请求Schema
# ============================================================================

class BatchSearchRequest(BaseModel):
    """
    批量查重请求
    
    注意：实际API使用multipart/form-data，此Schema仅用于文档
    """
    file: UploadFile = Field(..., description="Excel文件（必须包含名称、规格型号、单位列）")
    name_column: Optional[str] = Field(
        default=None,
        max_length=100,
        description="物料名称列（None时自动检测）"
    )
    spec_column: Optional[str] = Field(
        default=None,
        max_length=100,
        description="规格型号列（None时自动检测）"
    )
    unit_column: Optional[str] = Field(
        default=None,
        max_length=100,
        description="单位列（None时自动检测）"
    )
    top_k: int = Field(
        default=10,
        ge=1,
        le=50,
        description="返回Top-K相似物料"
    )


# ============================================================================
# 响应Schema - 数据项
# ============================================================================

class InputData(BaseModel):
    """
    输入数据项
    
    包含从Excel读取的必需字段和可选字段
    """
    name: str = Field(..., description="物料名称")
    spec: str = Field(..., description="规格型号")
    unit: Optional[str] = Field(None, description="单位")
    category: Optional[str] = Field(None, description="用户输入的分类（可选）")
    original_row: Dict[str, Any] = Field(
        default_factory=dict,
        description="原始Excel行数据（包含所有列）"
    )


class SimilarMaterialItem(BaseModel):
    """
    相似物料项
    
    查询结果中的单个物料信息
    """
    erp_code: str = Field(..., description="ERP物料编码")
    material_name: str = Field(..., description="物料名称")
    specification: Optional[str] = Field(None, description="规格")
    model: Optional[str] = Field(None, description="型号")
    english_name: Optional[str] = Field(None, description="英文名称")
    short_name: Optional[str] = Field(None, description="物料简称")
    mnemonic_code: Optional[str] = Field(None, description="助记码")
    
    # 分类和单位信息
    category_name: Optional[str] = Field(None, description="物料分类名称")
    unit_name: Optional[str] = Field(None, description="计量单位")
    
    # 查重相关字段
    similarity_score: float = Field(..., ge=0.0, le=1.0, description="相似度得分")
    similarity_breakdown: Optional[Dict[str, float]] = Field(
        None,
        description="相似度分解（name_score, description_score, attribute_score, category_score）"
    )
    normalized_name: str = Field(..., description="标准化名称")
    attributes: Dict[str, Any] = Field(default_factory=dict, description="结构化属性")
    detected_category: str = Field(..., description="检测到的物料类别")
    category_confidence: float = Field(..., ge=0.0, le=1.0, description="类别检测置信度")


class BatchSearchResultItem(BaseModel):
    """
    单条查重结果
    
    对应Excel中的一行数据及其查重结果
    """
    row_number: int = Field(..., ge=1, description="行号（从1开始）")
    input_data: InputData = Field(..., description="原始输入数据（3个必需字段）")
    combined_description: str = Field(..., description="组合后的完整描述（name + spec）")
    parsed_query: ParsedQuery = Field(..., description="解析结果（对称处理输出）")
    similar_materials: List[SimilarMaterialItem] = Field(
        ...,
        description="Top-K相似物料列表"
    )


class BatchSearchErrorItem(BaseModel):
    """
    单条错误记录
    
    处理失败的行信息
    """
    row_number: int = Field(..., ge=1, description="行号")
    input_description: str = Field(..., description="输入描述")
    error_type: str = Field(..., description="错误类型")
    error_message: str = Field(..., description="错误消息")


class SkippedRowItem(BaseModel):
    """
    跳过的行记录
    
    因空值等原因跳过的行
    """
    row_number: int = Field(..., ge=1, description="行号")
    reason: str = Field(..., description="跳过原因（如EMPTY_REQUIRED_FIELD）")
    message: str = Field(..., description="跳过消息")


class DetectedColumns(BaseModel):
    """
    检测到的列名映射
    
    返回实际使用的3个必需列的列名
    """
    name: str = Field(..., description="名称列")
    spec: str = Field(..., description="规格型号列")
    unit: str = Field(..., description="单位列")


# ============================================================================
# 响应Schema - 主响应
# ============================================================================

class BatchSearchResponse(BaseModel):
    """
    批量查重响应
    
    包含处理统计、检测到的列名、查重结果、错误和跳过记录
    """
    # 统计信息
    total_processed: int = Field(..., ge=0, description="成功处理的条数")
    success_count: int = Field(..., ge=0, description="成功查重的条数")
    failed_count: int = Field(..., ge=0, description="处理失败的条数")
    skipped_count: int = Field(..., ge=0, description="跳过的条数（空值等）")
    processing_time_seconds: float = Field(..., ge=0.0, description="处理耗时（秒）")
    
    # 列名信息
    detected_columns: DetectedColumns = Field(..., description="实际使用的列名映射")
    available_columns: List[str] = Field(
        default_factory=list,
        description="文件中所有列名"
    )
    
    # 结果数据
    results: List[BatchSearchResultItem] = Field(
        default_factory=list,
        description="批量查重结果"
    )
    errors: List[BatchSearchErrorItem] = Field(
        default_factory=list,
        description="错误记录"
    )
    skipped_rows: List[SkippedRowItem] = Field(
        default_factory=list,
        description="跳过的行"
    )
    
    class Config:
        json_schema_extra = {
            "example": {
                "total_processed": 100,
                "success_count": 98,
                "failed_count": 0,
                "skipped_count": 2,
                "processing_time_seconds": 12.5,
                "detected_columns": {
                    "name": "物料名称",
                    "spec": "规格型号",
                    "unit": "单位"
                },
                "available_columns": ["序号", "物料编码", "物料名称", "规格型号", "单位", "备注"],
                "results": [
                    {
                        "row_number": 1,
                        "input_data": {
                            "name": "六角螺栓",
                            "spec": "M8*20",
                            "unit": "个"
                        },
                        "combined_description": "六角螺栓 M8*20",
                        "similar_materials": []
                    }
                ]
            }
        }


# ============================================================================
# 异常Schema
# ============================================================================

class RequiredColumnsMissingError(Exception):
    """
    必需列缺失异常
    
    当Excel文件缺少名称、规格型号或单位列时抛出
    """
    def __init__(
        self,
        missing_columns: List[str],
        available_columns: List[str],
        suggestions: Optional[Dict[str, List[str]]] = None
    ):
        self.missing_columns = missing_columns
        self.available_columns = available_columns
        self.suggestions = suggestions or {}
        
        message = f"缺少必需的列: {', '.join(missing_columns)}"
        super().__init__(message)
    
    def to_dict(self) -> Dict[str, Any]:
        """转换为字典格式，用于API响应"""
        return {
            "code": "REQUIRED_COLUMNS_MISSING",
            "message": "缺少必需的列",
            "details": {
                "missing_columns": self.missing_columns,
                "available_columns": self.available_columns,
                "suggestions": self.suggestions
            },
            "help": "Excel文件必须包含以下列：名称、规格型号、单位"
        }

