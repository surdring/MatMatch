"""
FastAPI中间件

提供请求日志、CORS、错误处理等中间件功能
"""

import time
import uuid
import logging
from typing import Callable

from fastapi import Request, Response
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    请求日志中间件
    
    记录每个请求的详细信息，包括:
    - 请求ID
    - 请求方法和路径
    - 处理时间
    - 响应状态码
    """
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        处理请求并记录日志
        
        Args:
            request: 请求对象
            call_next: 下一个中间件或路由处理器
            
        Returns:
            Response: 响应对象
        """
        # 生成唯一的请求ID
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        
        # 记录请求开始
        start_time = time.time()
        
        # 获取客户端信息
        client_host = request.client.host if request.client else "unknown"
        
        logger.info(
            f"Request started: {request.method} {request.url.path}",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "client": client_host,
                "user_agent": request.headers.get("user-agent", "unknown")
            }
        )
        
        # 处理请求
        try:
            response = await call_next(request)
            
            # 计算处理时间
            process_time = (time.time() - start_time) * 1000  # 转换为毫秒
            
            # 添加自定义响应头
            response.headers["X-Request-ID"] = request_id
            response.headers["X-Process-Time"] = f"{process_time:.2f}ms"
            
            # 记录请求完成
            logger.info(
                f"Request completed: {request.method} {request.url.path} - {response.status_code}",
                extra={
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": response.status_code,
                    "process_time_ms": process_time
                }
            )
            
            return response
            
        except Exception as e:
            # 计算处理时间
            process_time = (time.time() - start_time) * 1000
            
            # 记录错误
            logger.error(
                f"Request failed: {request.method} {request.url.path} - {str(e)}",
                extra={
                    "request_id": request_id,
                    "method": request.method,
                    "path": request.url.path,
                    "process_time_ms": process_time,
                    "error": str(e)
                },
                exc_info=True
            )
            
            # 重新抛出异常，让异常处理器处理
            raise


class RequestSizeLimitMiddleware(BaseHTTPMiddleware):
    """
    请求大小限制中间件
    
    限制请求体的大小，防止恶意攻击
    """
    
    def __init__(self, app, max_size: int = 10 * 1024 * 1024):  # 默认10MB
        """
        初始化中间件
        
        Args:
            app: FastAPI应用实例
            max_size: 最大请求体大小（字节）
        """
        super().__init__(app)
        self.max_size = max_size
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        检查请求大小
        
        Args:
            request: 请求对象
            call_next: 下一个中间件或路由处理器
            
        Returns:
            Response: 响应对象
        """
        # 检查Content-Length头
        content_length = request.headers.get("content-length")
        if content_length:
            if int(content_length) > self.max_size:
                from fastapi.responses import JSONResponse
                logger.warning(
                    f"Request body too large: {content_length} bytes (max: {self.max_size})",
                    extra={
                        "path": request.url.path,
                        "content_length": content_length,
                        "max_size": self.max_size
                    }
                )
                return JSONResponse(
                    status_code=413,
                    content={
                        "error": {
                            "code": "REQUEST_TOO_LARGE",
                            "message": f"请求体过大，最大允许 {self.max_size / 1024 / 1024:.1f}MB"
                        }
                    }
                )
        
        return await call_next(request)


def setup_cors_middleware(app, origins: list = None) -> None:
    """
    配置CORS中间件
    
    Args:
        app: FastAPI应用实例
        origins: 允许的源列表
    """
    if origins is None:
        origins = [
            "http://localhost:3000",  # Vue开发服务器
            "http://localhost:8080",  # 备用端口
            "http://127.0.0.1:3000",
            "http://127.0.0.1:8080"
        ]
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        allow_headers=["*"],
        expose_headers=["X-Request-ID", "X-Process-Time"]
    )
    
    logger.info(f"CORS middleware configured with origins: {origins}")


def register_middlewares(app, cors_origins: list = None, max_request_size: int = 10 * 1024 * 1024) -> None:
    """
    注册所有中间件到FastAPI应用
    
    Args:
        app: FastAPI应用实例
        cors_origins: CORS允许的源列表
        max_request_size: 最大请求大小（字节）
    """
    # 1. 请求大小限制（最先执行）
    app.add_middleware(RequestSizeLimitMiddleware, max_size=max_request_size)
    
    # 2. 请求日志记录
    app.add_middleware(RequestLoggingMiddleware)
    
    # 3. CORS配置（最后执行，最先响应OPTIONS请求）
    setup_cors_middleware(app, cors_origins)
    
    logger.info("All middlewares registered successfully")

