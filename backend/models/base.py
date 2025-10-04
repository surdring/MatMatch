"""
SQLAlchemy基础模型定义
实现异步ORM基础类和通用字段

基于design.md第2.3节数据库设计，对应 [I.1] DeclarativeBase和AsyncAttrs使用
"""

from datetime import datetime
from typing import Any, Dict, Optional
from sqlalchemy import DateTime, func
from sqlalchemy.ext.asyncio import AsyncAttrs
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(AsyncAttrs, DeclarativeBase):
    """
    异步ORM基础类
    
    集成AsyncAttrs支持异步属性访问，使用DeclarativeBase作为元类
    对应 [I.1] - SQLAlchemy 2.1异步API规范
    对应 [I.3] - 为什么使用AsyncAttrs：支持延迟加载的异步访问
    """
    
    # 类型注解映射，确保类型安全
    type_annotation_map = {
        Dict[str, Any]: "JSONB"  # JSONB类型映射，对应attributes字段
    }


class TimestampMixin:
    """
    时间戳混合类
    
    为模型提供标准的创建时间和更新时间字段
    对应design.md中的系统管理字段规范
    """
    
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        comment="创建时间"
    )
    
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        comment="更新时间"
    )


class SyncStatusMixin:
    """
    同步状态混合类
    
    为从Oracle同步的数据提供同步状态管理
    对应design.md第2.3节中的ETL管道设计
    """
    
    sync_status: Mapped[str] = mapped_column(
        default="synced",
        comment="同步状态: synced, pending, failed"
    )
    
    source_system: Mapped[str] = mapped_column(
        default="oracle_erp",
        comment="数据源系统"
    )
    
    last_sync_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        comment="最后同步时间"
    )
