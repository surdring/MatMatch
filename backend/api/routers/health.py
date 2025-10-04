"""
健康检查路由

提供服务健康状态检查接口
"""

import logging
from datetime import datetime, timezone
from typing import Dict, Any

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, Field

from backend.api.dependencies import verify_dependencies, get_api_version

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="",
    tags=["健康检查"]
)


class HealthResponse(BaseModel):
    """健康检查响应"""
    status: str = Field(..., description="服务状态")
    timestamp: str = Field(..., description="检查时间")
    version: str = Field(..., description="API版本")
    database: str = Field(..., description="数据库状态")
    knowledge_base: str = Field(..., description="知识库状态")


class ReadinessResponse(BaseModel):
    """就绪检查响应"""
    ready: bool = Field(..., description="是否就绪")
    checks: Dict[str, str] = Field(..., description="各组件检查结果")
    timestamp: str = Field(..., description="检查时间")


class RootResponse(BaseModel):
    """根路径响应"""
    message: str = Field(..., description="欢迎消息")
    version: str = Field(..., description="API版本")
    docs: str = Field(..., description="API文档地址")
    redoc: str = Field(..., description="ReDoc文档地址")
    health: str = Field(..., description="健康检查地址")


@router.get(
    "/",
    response_model=RootResponse,
    summary="API根路径",
    description="返回API基本信息和文档链接"
)
async def root(version: str = Depends(get_api_version)) -> RootResponse:
    """
    API根路径
    
    提供API基本信息、版本号和文档链接
    
    Returns:
        RootResponse: 根路径响应
    """
    return RootResponse(
        message="MatMatch - 智能物料查重系统 API",
        version=version,
        docs="/docs",
        redoc="/redoc",
        health="/health"
    )


@router.get(
    "/health",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="健康检查",
    description="检查API服务和各依赖项的健康状态"
)
async def health_check(version: str = Depends(get_api_version)) -> HealthResponse:
    """
    健康检查端点
    
    检查服务的基本健康状态，包括数据库连接和知识库加载状态
    
    Returns:
        HealthResponse: 健康状态响应
    """
    logger.info("Health check requested")
    
    try:
        # 验证依赖项
        dependencies = await verify_dependencies()
        
        # 判断整体健康状态
        overall_status = "healthy"
        if dependencies.get("database") != "ok":
            overall_status = "degraded"
        if dependencies.get("material_processor") != "ok":
            overall_status = "degraded"
        
        response = HealthResponse(
            status=overall_status,
            timestamp=datetime.now(timezone.utc).isoformat(),
            version=version,
            database=dependencies.get("database", "unknown"),
            knowledge_base=dependencies.get("knowledge_base", "unknown")
        )
        
        logger.info(f"Health check completed: {overall_status}")
        return response
        
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}", exc_info=True)
        return HealthResponse(
            status="unhealthy",
            timestamp=datetime.now(timezone.utc).isoformat(),
            version=version,
            database="error",
            knowledge_base="error"
        )


@router.get(
    "/health/readiness",
    response_model=ReadinessResponse,
    status_code=status.HTTP_200_OK,
    summary="就绪检查",
    description="检查服务是否已就绪，可以接受请求"
)
async def readiness_check() -> ReadinessResponse:
    """
    就绪检查端点
    
    用于Kubernetes等容器编排系统检查服务是否已就绪
    
    Returns:
        ReadinessResponse: 就绪状态响应
    """
    logger.info("Readiness check requested")
    
    try:
        # 验证所有依赖项
        checks = await verify_dependencies()
        
        # 判断是否就绪
        ready = all(status == "ok" for status in checks.values())
        
        response = ReadinessResponse(
            ready=ready,
            checks=checks,
            timestamp=datetime.now(timezone.utc).isoformat()
        )
        
        logger.info(f"Readiness check completed: {'ready' if ready else 'not ready'}")
        return response
        
    except Exception as e:
        logger.error(f"Readiness check failed: {str(e)}", exc_info=True)
        return ReadinessResponse(
            ready=False,
            checks={
                "database": "error",
                "material_processor": "error",
                "knowledge_base": "error"
            },
            timestamp=datetime.now(timezone.utc).isoformat()
        )


@router.get(
    "/health/liveness",
    status_code=status.HTTP_200_OK,
    summary="存活检查",
    description="简单的存活检查，确认服务进程正在运行"
)
async def liveness_check() -> Dict[str, Any]:
    """
    存活检查端点
    
    最简单的健康检查，仅确认服务进程存活
    用于Kubernetes liveness probe
    
    Returns:
        dict: 存活状态
    """
    return {
        "alive": True,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

