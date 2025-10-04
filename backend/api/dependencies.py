"""
FastAPI依赖注入

提供数据库会话、处理器等可复用的依赖项
"""

import logging
from typing import AsyncGenerator, Optional
from functools import lru_cache

from sqlalchemy.ext.asyncio import AsyncSession

from backend.database.session import get_session
from backend.core.processors.material_processor import UniversalMaterialProcessor
from backend.core.calculators.similarity_calculator import SimilarityCalculator
from .exceptions import ServiceUnavailableException

logger = logging.getLogger(__name__)

# 全局缓存的处理器实例（单例模式）
_material_processor_instance: Optional[UniversalMaterialProcessor] = None
_processor_lock = False


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    获取数据库会话（依赖注入）
    
    使用async context manager确保会话正确关闭
    
    Yields:
        AsyncSession: 异步数据库会话
        
    Raises:
        ServiceUnavailableException: 数据库连接失败
    """
    try:
        async for session in get_session():
            yield session
    except Exception as e:
        logger.error(f"Failed to get database session: {str(e)}", exc_info=True)
        raise ServiceUnavailableException(
            detail="数据库连接失败",
            service="database"
        )


async def get_material_processor(
    db: AsyncSession = None
) -> UniversalMaterialProcessor:
    """
    获取物料处理器实例（单例模式）
    
    使用全局缓存确保只创建一个处理器实例，提高性能
    
    Args:
        db: 数据库会话（可选，用于创建新实例）
        
    Returns:
        UniversalMaterialProcessor: 物料处理器实例
        
    Raises:
        ServiceUnavailableException: 处理器初始化失败
    """
    global _material_processor_instance, _processor_lock
    
    # 如果已经有实例，直接返回
    if _material_processor_instance is not None:
        return _material_processor_instance
    
    # 防止并发创建多个实例
    if _processor_lock:
        # 等待其他协程创建完成
        import asyncio
        for _ in range(50):  # 最多等待5秒
            await asyncio.sleep(0.1)
            if _material_processor_instance is not None:
                return _material_processor_instance
        raise ServiceUnavailableException(
            detail="物料处理器初始化超时",
            service="material_processor"
        )
    
    try:
        _processor_lock = True
        logger.info("Initializing UniversalMaterialProcessor...")
        
        # 创建新的数据库会话（如果未提供）
        if db is None:
            async for session in get_session():
                processor = UniversalMaterialProcessor(session)
                await processor.load_knowledge_base()
                _material_processor_instance = processor
                logger.info("UniversalMaterialProcessor initialized successfully")
                return processor
        else:
            processor = UniversalMaterialProcessor(db)
            await processor.load_knowledge_base()
            _material_processor_instance = processor
            logger.info("UniversalMaterialProcessor initialized successfully")
            return processor
            
    except Exception as e:
        logger.error(f"Failed to initialize material processor: {str(e)}", exc_info=True)
        raise ServiceUnavailableException(
            detail="物料处理器初始化失败",
            service="material_processor"
        )
    finally:
        _processor_lock = False


async def get_similarity_calculator(
    db: AsyncSession
) -> SimilarityCalculator:
    """
    获取相似度计算器实例
    
    每个请求创建新的计算器实例，使用独立的数据库会话
    
    Args:
        db: 数据库会话
        
    Returns:
        SimilarityCalculator: 相似度计算器实例
        
    Raises:
        ServiceUnavailableException: 计算器初始化失败
    """
    try:
        calculator = SimilarityCalculator(db)
        return calculator
    except Exception as e:
        logger.error(f"Failed to initialize similarity calculator: {str(e)}", exc_info=True)
        raise ServiceUnavailableException(
            detail="相似度计算器初始化失败",
            service="similarity_calculator"
        )


async def reset_material_processor() -> None:
    """
    重置物料处理器实例
    
    用于测试或需要重新加载知识库时
    """
    global _material_processor_instance
    _material_processor_instance = None
    logger.info("Material processor instance reset")


@lru_cache()
def get_api_version() -> str:
    """
    获取API版本号
    
    使用lru_cache缓存，避免重复读取
    
    Returns:
        str: API版本号
    """
    from backend.api import __version__
    return __version__


async def verify_dependencies() -> dict:
    """
    验证所有依赖项是否正常
    
    用于健康检查和启动验证
    
    Returns:
        dict: 依赖项状态
    """
    status = {
        "database": "unknown",
        "material_processor": "unknown",
        "knowledge_base": "unknown"
    }
    
    # 检查数据库连接
    try:
        async for db in get_session():
            await db.execute("SELECT 1")
            status["database"] = "ok"
            break
    except Exception as e:
        logger.error(f"Database check failed: {str(e)}")
        status["database"] = "error"
    
    # 检查物料处理器
    try:
        processor = await get_material_processor()
        status["material_processor"] = "ok"
        
        # 检查知识库
        if processor._knowledge_base_loaded:
            status["knowledge_base"] = "ok"
        else:
            status["knowledge_base"] = "not_loaded"
    except Exception as e:
        logger.error(f"Material processor check failed: {str(e)}")
        status["material_processor"] = "error"
        status["knowledge_base"] = "error"
    
    return status

