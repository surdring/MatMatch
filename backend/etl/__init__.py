"""
ETL数据管道模块

本模块实现Oracle到PostgreSQL的ETL数据同步管道
包含对称处理算法的完整实现

主要组件:
- ETLPipeline: ETL管道主类
- SimpleMaterialProcessor: 简化版物料处理器（对称处理算法）
- ETLConfig: ETL配置管理
"""

from .etl_pipeline import ETLPipeline
from .material_processor import SimpleMaterialProcessor
from .exceptions import (
    ETLError,
    ExtractError,
    TransformError,
    LoadError,
    ProcessingError
)

__all__ = [
    'ETLPipeline',
    'SimpleMaterialProcessor',
    'ETLError',
    'ExtractError',
    'TransformError',
    'LoadError',
    'ProcessingError',
]

__version__ = '1.0.0'

