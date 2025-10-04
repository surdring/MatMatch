"""
数据库会话管理模块

实现SQLAlchemy 2.1异步会话管理和连接池配置
"""

from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import (
    create_async_engine,
    async_sessionmaker,
    AsyncSession,
    AsyncEngine
)
from sqlalchemy.pool import NullPool
import logging

from backend.core.config import database_config

# 配置日志
logger = logging.getLogger(__name__)


class DatabaseManager:
    """
    数据库管理器
    
    负责创建和管理数据库引擎和会话工厂
    """
    
    def __init__(self):
        self._engine: AsyncEngine = None
        self._session_factory: async_sessionmaker = None
    
    @property
    def engine(self) -> AsyncEngine:
        """获取数据库引擎"""
        if self._engine is None:
            raise RuntimeError("Database engine not initialized. Call initialize() first.")
        return self._engine
    
    @property
    def session_factory(self) -> async_sessionmaker:
        """获取会话工厂"""
        if self._session_factory is None:
            raise RuntimeError("Session factory not initialized. Call initialize() first.")
        return self._session_factory
    
    def initialize(
        self,
        echo: bool = False,
        pool_pre_ping: bool = True,
        pool_size: int = 5,
        max_overflow: int = 10
    ) -> None:
        """
        初始化数据库连接
        
        Args:
            echo: 是否打印SQL语句
            pool_pre_ping: 连接池预检查
            pool_size: 连接池大小
            max_overflow: 最大溢出连接数
        """
        # 构建数据库URL（使用database_config）
        database_url = database_config.database_url
        
        # 创建异步引擎
        self._engine = create_async_engine(
            database_url,
            echo=echo,
            pool_pre_ping=pool_pre_ping,
            pool_size=pool_size,
            max_overflow=max_overflow,
            future=True
        )
        
        # 创建会话工厂
        self._session_factory = async_sessionmaker(
            self._engine,
            class_=AsyncSession,
            expire_on_commit=False,
            autocommit=False,
            autoflush=False
        )
        
        logger.info("✓ 异步会话工厂已创建")
    
    async def close(self) -> None:
        """关闭数据库连接"""
        if self._engine:
            await self._engine.dispose()
            logger.info("Database engine disposed")


# 全局数据库管理器实例
db_manager = DatabaseManager()


def initialize_database(
    echo: bool = False,
    pool_pre_ping: bool = True,
    pool_size: int = 5,
    max_overflow: int = 10
) -> None:
    """
    初始化数据库（同步接口）
    
    Args:
        echo: 是否打印SQL语句
        pool_pre_ping: 连接池预检查
        pool_size: 连接池大小
        max_overflow: 最大溢出连接数
    """
    db_manager.initialize(
        echo=echo,
        pool_pre_ping=pool_pre_ping,
        pool_size=pool_size,
        max_overflow=max_overflow
    )


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """
    获取数据库会话（异步生成器）
    
    使用方式:
        async for session in get_session():
            # 使用session
            pass
    
    或者用于FastAPI依赖注入:
        async def endpoint(db: AsyncSession = Depends(get_session)):
            # 使用db
            pass
    
    Yields:
        AsyncSession: 异步数据库会话
    """
    # 确保数据库已初始化
    if db_manager._session_factory is None:
        db_manager.initialize()
    
    async with db_manager.session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


# 为了保持向后兼容，提供get_db别名
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    获取数据库会话（别名）
    
    Yields:
        AsyncSession: 异步数据库会话
    """
    async for session in get_session():
        yield session


# 测试专用会话（使用NullPool避免连接泄漏）
async def get_test_session() -> AsyncGenerator[AsyncSession, None]:
    """
    获取测试专用数据库会话
    
    使用NullPool避免测试时的连接池问题
    
    Yields:
        AsyncSession: 测试用异步数据库会话
    """
    database_url = database_config.database_url
    
    engine = create_async_engine(
        database_url,
        echo=False,
        poolclass=NullPool,
        future=True
    )
    
    session_factory = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    async with session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
            await engine.dispose()
