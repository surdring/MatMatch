"""
核心Schema定义模块

包含所有Pydantic模型定义，用于API请求/响应和数据验证
"""

from .material_schemas import (
    ParsedQuery,
    MaterialResult,
    BatchSearchResult,
    BatchSearchResponse
)

__all__ = [
    'ParsedQuery',
    'MaterialResult',
    'BatchSearchResult',
    'BatchSearchResponse',
]

