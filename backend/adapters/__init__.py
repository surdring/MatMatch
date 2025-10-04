"""
数据源适配器模块

提供各种数据源的统一适配器接口，支持Oracle、PostgreSQL等数据库的数据提取和处理。
对应 [I.2] - 编码策略中的适配器层实现
"""

from .oracle_adapter import OracleDataSourceAdapter

__all__ = [
    "OracleDataSourceAdapter",
]
