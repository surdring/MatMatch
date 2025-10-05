"""
API Schema模块
定义所有Pydantic数据模型
"""

from .batch_search_schemas import (
    # 请求Schema
    BatchSearchRequest,
    
    # 响应Schema
    InputData,
    SimilarMaterialItem,
    BatchSearchResultItem,
    BatchSearchErrorItem,
    SkippedRowItem,
    DetectedColumns,
    BatchSearchResponse,
    
    # 异常Schema
    RequiredColumnsMissingError,
)

__all__ = [
    # Request
    "BatchSearchRequest",
    
    # Response
    "InputData",
    "SimilarMaterialItem",
    "BatchSearchResultItem",
    "BatchSearchErrorItem",
    "SkippedRowItem",
    "DetectedColumns",
    "BatchSearchResponse",
    
    # Exceptions
    "RequiredColumnsMissingError",
]

