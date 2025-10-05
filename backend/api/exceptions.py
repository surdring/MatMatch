"""
API自定义异常

定义所有业务异常类型
"""


class MatMatchAPIException(Exception):
    """MatMatch API基础异常"""
    def __init__(self, message: str, error_code: str = "API_ERROR"):
        self.message = message
        self.error_code = error_code
        super().__init__(self.message)


# 向后兼容的别名
APIException = MatMatchAPIException


class FileTypeError(MatMatchAPIException):
    """文件类型错误"""
    def __init__(self, message: str):
        super().__init__(message, "FILE_TYPE_ERROR")


class FileTooLargeError(MatMatchAPIException):
    """文件过大"""
    def __init__(self, message: str):
        super().__init__(message, "FILE_TOO_LARGE")


class ExcelParseError(MatMatchAPIException):
    """Excel解析错误"""
    def __init__(self, message: str):
        super().__init__(message, "EXCEL_PARSE_ERROR")


class ColumnNotFoundError(MatMatchAPIException):
    """列名未找到"""
    def __init__(self, message: str):
        super().__init__(message, "COLUMN_NOT_FOUND")


class ProcessingError(MatMatchAPIException):
    """处理错误"""
    def __init__(self, message: str):
        super().__init__(message, "PROCESSING_ERROR")


class ServiceUnavailableException(MatMatchAPIException):
    """服务不可用异常"""
    def __init__(self, message: str):
        super().__init__(message, "SERVICE_UNAVAILABLE")


class NotFoundException(MatMatchAPIException):
    """资源未找到异常"""
    def __init__(self, message: str):
        super().__init__(message, "NOT_FOUND")


class ValidationException(MatMatchAPIException):
    """验证异常"""
    def __init__(self, message: str):
        super().__init__(message, "VALIDATION_ERROR")


class DatabaseException(MatMatchAPIException):
    """数据库异常"""
    def __init__(self, message: str):
        super().__init__(message, "DATABASE_ERROR")


class MaterialNotFoundError(MatMatchAPIException):
    """物料未找到异常"""
    def __init__(self, message: str):
        super().__init__(message, "MATERIAL_NOT_FOUND")


class ValidationError(MatMatchAPIException):
    """验证错误异常"""
    def __init__(self, message: str):
        super().__init__(message, "VALIDATION_ERROR")