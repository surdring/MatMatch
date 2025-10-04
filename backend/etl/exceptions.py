"""
ETL模块自定义异常类

定义ETL数据管道相关的异常类型
"""


class ETLError(Exception):
    """ETL处理基础异常"""
    pass


class ExtractError(ETLError):
    """数据提取阶段异常"""
    pass


class TransformError(ETLError):
    """数据转换阶段异常"""
    pass


class LoadError(ETLError):
    """数据加载阶段异常"""
    pass


class ProcessingError(ETLError):
    """对称处理算法异常"""
    pass


class ConfigError(ETLError):
    """配置错误异常"""
    pass


class ValidationError(ETLError):
    """数据验证异常"""
    pass

