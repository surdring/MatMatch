"""
自定义API异常类

定义项目中使用的所有自定义异常，提供统一的异常处理机制
"""

from typing import Optional, Dict, Any


class APIException(Exception):
    """
    API基础异常类
    
    所有自定义异常的基类，提供统一的异常接口
    """
    
    def __init__(
        self,
        status_code: int,
        detail: str,
        error_code: Optional[str] = None,
        extra: Optional[Dict[str, Any]] = None
    ):
        """
        初始化API异常
        
        Args:
            status_code: HTTP状态码
            detail: 错误详细描述
            error_code: 错误代码（用于前端识别）
            extra: 额外的错误信息
        """
        self.status_code = status_code
        self.detail = detail
        self.error_code = error_code or f"ERROR_{status_code}"
        self.extra = extra or {}
        super().__init__(self.detail)
    
    def to_dict(self) -> Dict[str, Any]:
        """
        转换为字典格式
        
        Returns:
            错误信息字典
        """
        return {
            "code": self.error_code,
            "message": self.detail,
            "details": self.extra
        }


class NotFoundException(APIException):
    """
    资源未找到异常 (HTTP 404)
    
    当请求的资源不存在时抛出
    """
    
    def __init__(self, detail: str = "资源未找到", resource: Optional[str] = None):
        extra = {"resource": resource} if resource else {}
        super().__init__(
            status_code=404,
            detail=detail,
            error_code="RESOURCE_NOT_FOUND",
            extra=extra
        )


class ValidationException(APIException):
    """
    数据验证异常 (HTTP 422)
    
    当请求数据验证失败时抛出
    """
    
    def __init__(
        self,
        detail: str = "数据验证失败",
        field: Optional[str] = None,
        errors: Optional[Dict[str, Any]] = None
    ):
        extra = {}
        if field:
            extra["field"] = field
        if errors:
            extra["validation_errors"] = errors
        
        super().__init__(
            status_code=422,
            detail=detail,
            error_code="VALIDATION_ERROR",
            extra=extra
        )


class DatabaseException(APIException):
    """
    数据库异常 (HTTP 500)
    
    当数据库操作失败时抛出
    """
    
    def __init__(self, detail: str = "数据库操作失败", operation: Optional[str] = None):
        extra = {"operation": operation} if operation else {}
        super().__init__(
            status_code=500,
            detail=detail,
            error_code="DATABASE_ERROR",
            extra=extra
        )


class ProcessingException(APIException):
    """
    处理异常 (HTTP 500)
    
    当物料处理或相似度计算失败时抛出
    """
    
    def __init__(
        self,
        detail: str = "数据处理失败",
        stage: Optional[str] = None,
        item: Optional[str] = None
    ):
        extra = {}
        if stage:
            extra["stage"] = stage
        if item:
            extra["item"] = item
        
        super().__init__(
            status_code=500,
            detail=detail,
            error_code="PROCESSING_ERROR",
            extra=extra
        )


class FileUploadException(APIException):
    """
    文件上传异常 (HTTP 400)
    
    当文件上传失败或文件格式不正确时抛出
    """
    
    def __init__(
        self,
        detail: str = "文件上传失败",
        filename: Optional[str] = None,
        reason: Optional[str] = None
    ):
        extra = {}
        if filename:
            extra["filename"] = filename
        if reason:
            extra["reason"] = reason
        
        super().__init__(
            status_code=400,
            detail=detail,
            error_code="FILE_UPLOAD_ERROR",
            extra=extra
        )


class RateLimitException(APIException):
    """
    限流异常 (HTTP 429)
    
    当请求频率超过限制时抛出
    """
    
    def __init__(
        self,
        detail: str = "请求过于频繁，请稍后再试",
        retry_after: Optional[int] = None
    ):
        extra = {"retry_after": retry_after} if retry_after else {}
        super().__init__(
            status_code=429,
            detail=detail,
            error_code="RATE_LIMIT_EXCEEDED",
            extra=extra
        )


class ServiceUnavailableException(APIException):
    """
    服务不可用异常 (HTTP 503)
    
    当服务暂时不可用时抛出
    """
    
    def __init__(
        self,
        detail: str = "服务暂时不可用",
        service: Optional[str] = None
    ):
        extra = {"service": service} if service else {}
        super().__init__(
            status_code=503,
            detail=detail,
            error_code="SERVICE_UNAVAILABLE",
            extra=extra
        )

