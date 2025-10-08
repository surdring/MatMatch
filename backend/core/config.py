"""
核心配置模块
管理数据库连接、应用设置等核心配置

基于design.md第2.3节数据库设计部分的配置要求
对应 [I.3] - Oracle字段映射逻辑的配置基础
"""

import os
from typing import Optional
from pydantic import Field, ConfigDict
from pydantic_settings import BaseSettings


class DatabaseConfig(BaseSettings):
    """
    数据库配置类
    
    遵循SQLAlchemy 2.1异步最佳实践，支持连接池和查询优化
    对应 [I.1] - SQLAlchemy 2.1异步API配置
    """
    
    # PostgreSQL连接配置
    host: str = Field(default="127.0.0.1", description="数据库主机地址")
    port: int = Field(default=5432, description="数据库端口")
    username: str = Field(default="postgres", description="数据库用户名")
    password: str = Field(default="xqxatcdj", description="数据库密码")
    database: str = Field(default="matmatch", description="数据库名称")
    
    # 连接池配置 - 对应 [I.5] 并发处理机制
    pool_size: int = Field(default=20, description="连接池大小")  # 增加到20（优化并发性能）
    max_overflow: int = Field(default=30, description="连接池最大溢出连接数")  # 增加到30（总计50连接）
    pool_timeout: int = Field(default=60, description="获取连接超时时间(秒)")  # 增加到60秒
    pool_recycle: int = Field(default=3600, description="连接回收时间(秒)")
    
    # 查询优化配置 - 对应 [R.7-8] 性能与内存要求
    echo_sql: bool = Field(default=False, description="是否打印SQL语句")
    query_timeout: int = Field(default=60, description="查询超时时间(秒)")  # 增加到60秒
    
    @property
    def database_url(self) -> str:
        """
        构建异步数据库连接URL
        
        使用postgresql+asyncpg驱动，遵循SQLAlchemy 2.1异步规范
        对应 [I.1] - create_async_engine API要求
        """
        return f"postgresql+asyncpg://{self.username}:{self.password}@{self.host}:{self.port}/{self.database}"
    
    model_config = ConfigDict(
        env_prefix="DB_",
        case_sensitive=False
    )


class ApplicationConfig(BaseSettings):
    """
    应用程序配置类
    
    管理FastAPI应用的核心配置
    对应Task 3.1: FastAPI核心服务框架的配置需求
    """
    
    # 应用基础配置
    app_name: str = Field(default="MatMatch智能物料查重工具", description="应用名称")
    app_version: str = Field(default="1.0.0", description="应用版本")
    debug: bool = Field(default=True, description="调试模式")
    
    # API配置
    api_prefix: str = Field(default="/api/v1", description="API路径前缀")
    cors_origins: list = Field(default=["http://localhost:3000", "http://127.0.0.1:3000"], description="CORS允许的源")
    
    # 安全配置 - 对应 [R.17] 安全性-输入验证
    max_file_size: int = Field(default=10 * 1024 * 1024, description="最大文件上传大小(字节)")
    allowed_file_types: list = Field(default=[".xlsx", ".xls"], description="允许的文件类型")
    
    # 性能配置 - 对应AC 1.2 性能要求
    batch_processing_limit: int = Field(default=1000, description="批量处理记录数限制")
    query_result_limit: int = Field(default=10, description="查询结果数量限制")
    processing_timeout: int = Field(default=600, description="处理超时时间(秒)")  # 增加到600秒（10分钟）
    
    model_config = ConfigDict(
        env_prefix="APP_",
        case_sensitive=False
    )


class OracleConfig(BaseSettings):
    """
    Oracle数据库配置类
    
    基于database/oracle_config.py的配置，集成到backend统一配置管理
    对应 [I.5] - 配置优先级机制：环境变量 > 配置文件 > 默认值
    """
    
    # Oracle连接配置
    host: str = Field(default="192.168.80.90", description="Oracle数据库主机地址")
    port: int = Field(default=1521, description="Oracle数据库端口")
    service_name: str = Field(default="ORCL", description="Oracle服务名")
    username: str = Field(default="matmatch_read", description="Oracle用户名")
    password: str = Field(default="matmatch_read", description="Oracle密码")
    
    # 连接池配置
    pool_min: int = Field(default=1, description="连接池最小连接数")
    pool_max: int = Field(default=10, description="连接池最大连接数")
    pool_increment: int = Field(default=1, description="连接池增长步长")
    
    # 查询配置
    fetch_size: int = Field(default=1000, description="默认批量查询大小")
    query_timeout: int = Field(default=60, description="查询超时时间(秒)")
    connection_timeout: int = Field(default=30, description="连接超时时间(秒)")
    
    @property
    def dsn(self) -> str:
        """
        构建Oracle DSN连接字符串
        
        对应 [I.1] - API预检协议中的oracledb连接要求
        """
        return f"{self.host}:{self.port}/{self.service_name}"
    
    model_config = ConfigDict(
        env_prefix="ORACLE_",
        case_sensitive=False
    )


# 全局配置实例
database_config = DatabaseConfig()
app_config = ApplicationConfig()
oracle_config = OracleConfig()
