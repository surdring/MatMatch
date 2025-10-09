"""
全局异常处理器

为FastAPI应用提供统一的异常处理机制
"""

import logging
import traceback
from datetime import datetime, timezone
from typing import Union

from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from sqlalchemy.exc import SQLAlchemyError

from .exceptions import APIException

logger = logging.getLogger(__name__)


def create_error_response(
    status_code: int,
    error_code: str,
    message: str,
    details: dict = None,
    request: Request = None
) -> JSONResponse:
    """
    创建统一的错误响应
    
    Args:
        status_code: HTTP状态码
        error_code: 错误代码
        message: 错误消息
        details: 错误详情
        request: 请求对象
        
    Returns:
        JSON响应
    """
    error_response = {
        "error": {
            "code": error_code,
            "message": message,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
    }
    
    # 添加详情
    if details:
        error_response["error"]["details"] = details
    
    # 添加请求路径和请求ID（如果存在）
    if request:
        error_response["error"]["path"] = str(request.url.path)
        if hasattr(request.state, "request_id"):
            error_response["error"]["request_id"] = request.state.request_id
    
    return JSONResponse(
        status_code=status_code,
        content=error_response
    )


async def api_exception_handler(request: Request, exc: APIException) -> JSONResponse:
    """
    处理自定义API异常
    
    Args:
        request: 请求对象
        exc: API异常实例
        
    Returns:
        JSON响应
    """
    logger.warning(
        f"API Exception: {exc.error_code} - {exc.detail}",
        extra={
            "error_code": exc.error_code,
            "status_code": exc.status_code,
            "path": request.url.path,
            "method": request.method
        }
    )
    
    return create_error_response(
        status_code=exc.status_code,
        error_code=exc.error_code,
        message=exc.detail,
        details=exc.extra,
        request=request
    )


async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError
) -> JSONResponse:
    """
    处理请求验证异常
    
    Args:
        request: 请求对象
        exc: 验证异常实例
        
    Returns:
        JSON响应
    """
    # 提取验证错误详情
    errors = []
    for error in exc.errors():
        errors.append({
            "field": ".".join(str(loc) for loc in error["loc"]),
            "message": error["msg"],
            "type": error["type"]
        })
    
    logger.warning(
        f"Validation Error: {len(errors)} validation error(s)",
        extra={
            "path": request.url.path,
            "method": request.method,
            "errors": errors
        }
    )
    
    return create_error_response(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        error_code="VALIDATION_ERROR",
        message="请求数据验证失败",
        details={"validation_errors": errors},
        request=request
    )


async def http_exception_handler(
    request: Request,
    exc: StarletteHTTPException
) -> JSONResponse:
    """
    处理HTTP异常
    
    Args:
        request: 请求对象
        exc: HTTP异常实例
        
    Returns:
        JSON响应
    """
    logger.warning(
        f"HTTP Exception: {exc.status_code} - {exc.detail}",
        extra={
            "status_code": exc.status_code,
            "path": request.url.path,
            "method": request.method
        }
    )
    
    # 处理detail参数（可能是字符串或字典）
    if isinstance(exc.detail, dict):
        # 如果detail是字典（来自我们的自定义异常）
        error_code = exc.detail.get("error_code", f"HTTP_{exc.status_code}")
        message = exc.detail.get("message", str(exc.detail))
    else:
        # 如果detail是字符串
        error_codes = {
            400: "BAD_REQUEST",
            401: "UNAUTHORIZED",
            403: "FORBIDDEN",
            404: "NOT_FOUND",
            405: "METHOD_NOT_ALLOWED",
            500: "INTERNAL_SERVER_ERROR"
        }
        error_code = error_codes.get(exc.status_code, f"HTTP_{exc.status_code}")
        message = exc.detail if isinstance(exc.detail, str) else str(exc.detail)
    
    return create_error_response(
        status_code=exc.status_code,
        error_code=error_code,
        message=message,
        request=request
    )


async def sqlalchemy_exception_handler(
    request: Request,
    exc: SQLAlchemyError
) -> JSONResponse:
    """
    处理SQLAlchemy数据库异常
    
    Args:
        request: 请求对象
        exc: SQLAlchemy异常实例
        
    Returns:
        JSON响应
    """
    logger.error(
        f"Database Error: {str(exc)}",
        extra={
            "path": request.url.path,
            "method": request.method,
            "exception_type": type(exc).__name__
        },
        exc_info=True
    )
    
    # 生产环境不暴露详细的数据库错误信息
    return create_error_response(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        error_code="DATABASE_ERROR",
        message="数据库操作失败，请稍后重试",
        request=request
    )


async def generic_exception_handler(
    request: Request,
    exc: Exception
) -> JSONResponse:
    """
    处理未捕获的通用异常
    
    Args:
        request: 请求对象
        exc: 异常实例
        
    Returns:
        JSON响应
    """
    # 记录完整的异常堆栈
    logger.error(
        f"Unhandled Exception: {type(exc).__name__} - {str(exc)}",
        extra={
            "path": request.url.path,
            "method": request.method,
            "exception_type": type(exc).__name__,
            "traceback": traceback.format_exc()
        },
        exc_info=True
    )
    
    # 生产环境返回通用错误信息
    return create_error_response(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        error_code="INTERNAL_SERVER_ERROR",
        message="服务器内部错误，请联系管理员",
        request=request
    )


def register_exception_handlers(app) -> None:
    """
    注册所有异常处理器到FastAPI应用
    
    Args:
        app: FastAPI应用实例
    """
    # 自定义API异常
    app.add_exception_handler(APIException, api_exception_handler)
    
    # FastAPI验证异常
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    
    # Starlette HTTP异常
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)
    
    # SQLAlchemy数据库异常
    app.add_exception_handler(SQLAlchemyError, sqlalchemy_exception_handler)
    
    # 通用异常（捕获所有未处理的异常）
    app.add_exception_handler(Exception, generic_exception_handler)
    
    logger.info("All exception handlers registered successfully")

