"""
ETL配置管理

管理ETL管道的配置参数
"""

from typing import Optional
from pydantic import BaseModel, Field


class ETLConfig(BaseModel):
    """ETL管道配置"""
    
    # 批量处理配置
    batch_size: int = Field(
        default=1000,
        ge=100,
        le=10000,
        description="每批处理的记录数量"
    )
    
    # 写入配置
    load_batch_size: int = Field(
        default=500,
        ge=100,
        le=5000,
        description="每批写入PostgreSQL的记录数量"
    )
    
    # 性能配置
    max_workers: int = Field(
        default=4,
        ge=1,
        le=16,
        description="最大并发工作线程数"
    )
    
    # 错误处理
    max_retry_attempts: int = Field(
        default=3,
        ge=1,
        le=10,
        description="失败重试最大次数"
    )
    
    fail_fast: bool = Field(
        default=False,
        description="是否在首次错误时快速失败"
    )
    
    skip_failed_records: bool = Field(
        default=True,
        description="是否跳过失败的记录继续处理"
    )
    
    # 日志和监控
    enable_progress_log: bool = Field(
        default=True,
        description="是否启用进度日志"
    )
    
    log_interval: int = Field(
        default=100,
        ge=10,
        le=10000,
        description="日志输出间隔（记录数）"
    )
    
    # 缓存配置
    enable_knowledge_cache: bool = Field(
        default=True,
        description="是否启用知识库缓存"
    )
    
    cache_ttl: int = Field(
        default=3600,
        ge=60,
        le=86400,
        description="缓存过期时间（秒）"
    )
    
    class Config:
        """Pydantic配置"""
        validate_assignment = True
        extra = 'forbid'

