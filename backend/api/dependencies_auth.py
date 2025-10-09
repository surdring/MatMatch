"""
认证与授权依赖

本模块实现管理后台的安全认证机制，防止未授权访问。

安全策略：
- 基于API Token的认证（可扩展为JWT）
- 管理员权限验证
- 请求来源IP白名单（可选）
- 操作日志记录

关联规范: [R.17] 安全性-输入验证, [R.18] 安全性-依赖管理
"""

from typing import Optional
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException, status, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import structlog
import hashlib
import secrets

from backend.core.config import app_config

logger = structlog.get_logger()

# ============================================================================
# 认证配置
# ============================================================================

# 管理员API Token（生产环境应从环境变量读取）
# 生成方式: secrets.token_urlsafe(32)
ADMIN_API_TOKENS = {
    # 默认管理员Token（仅用于开发，生产环境必须更换）
    "admin_dev_token_change_in_production": {
        "username": "admin",
        "role": "admin",
        "created_at": "2025-10-08",
        "description": "默认管理员Token（开发用）"
    }
}

# IP白名单（可选，空列表表示不限制）
ALLOWED_IPS = [
    # "127.0.0.1",
    # "::1",
    # "192.168.1.0/24"  # 支持CIDR格式
]

# 安全配置
ENABLE_IP_WHITELIST = False  # 是否启用IP白名单
ENABLE_RATE_LIMIT = True     # 是否启用访问频率限制
MAX_REQUESTS_PER_MINUTE = 60  # 每分钟最大请求数

# ============================================================================
# HTTP Bearer Token认证
# ============================================================================

security = HTTPBearer(
    scheme_name="AdminAPIToken",
    description="管理后台API Token认证",
    auto_error=False
)


async def verify_admin_token(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    x_api_key: Optional[str] = Header(None, description="API密钥（备用认证方式）")
) -> dict:
    """
    验证管理员API Token
    
    支持两种认证方式：
    1. Authorization: Bearer <token>  （推荐）
    2. X-API-Key: <token>  （备用）
    
    参数:
    - credentials: HTTPAuthorizationCredentials - Bearer Token
    - x_api_key: Optional[str] - API密钥（Header方式）
    
    返回:
    - dict - 认证用户信息
    
    异常:
    - HTTPException 401: Token缺失或无效
    - HTTPException 403: 权限不足
    """
    # 提取Token
    token = None
    if credentials:
        token = credentials.credentials
    elif x_api_key:
        token = x_api_key
    
    # Token缺失
    if not token:
        logger.warning("admin_auth_failed_no_token")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "error_code": "AUTH_TOKEN_MISSING",
                "message": "未提供认证Token",
                "hint": "请在请求头中添加 'Authorization: Bearer <token>' 或 'X-API-Key: <token>'"
            },
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    # 验证Token
    token_info = ADMIN_API_TOKENS.get(token)
    if not token_info:
        logger.warning("admin_auth_failed_invalid_token", token_hash=_hash_token(token))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={
                "error_code": "AUTH_TOKEN_INVALID",
                "message": "无效的认证Token"
            },
            headers={"WWW-Authenticate": "Bearer"}
        )
    
    # 验证角色权限
    if token_info.get("role") != "admin":
        logger.warning(
            "admin_auth_failed_insufficient_permissions",
            username=token_info.get("username"),
            role=token_info.get("role")
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={
                "error_code": "AUTH_INSUFFICIENT_PERMISSIONS",
                "message": "权限不足，需要管理员权限"
            }
        )
    
    # 认证成功
    logger.info(
        "admin_auth_success",
        username=token_info.get("username"),
        role=token_info.get("role")
    )
    
    return {
        "username": token_info.get("username"),
        "role": token_info.get("role"),
        "token_created_at": token_info.get("created_at")
    }


async def verify_ip_whitelist(
    request_ip: str = Header(None, alias="X-Forwarded-For")
) -> bool:
    """
    验证请求来源IP是否在白名单中
    
    参数:
    - request_ip: str - 请求来源IP（从Header获取）
    
    返回:
    - bool - 是否允许访问
    
    异常:
    - HTTPException 403: IP不在白名单中
    """
    # 如果未启用IP白名单，直接通过
    if not ENABLE_IP_WHITELIST or not ALLOWED_IPS:
        return True
    
    # 提取真实IP（可能经过代理）
    client_ip = request_ip or "unknown"
    
    # 简单的IP匹配（生产环境建议使用ipaddress模块）
    if client_ip in ALLOWED_IPS or "0.0.0.0" in ALLOWED_IPS:
        logger.info("ip_whitelist_check_passed", client_ip=client_ip)
        return True
    
    # IP不在白名单
    logger.warning("ip_whitelist_check_failed", client_ip=client_ip)
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail={
            "error_code": "IP_NOT_ALLOWED",
            "message": f"IP地址 {client_ip} 不在白名单中"
        }
    )


# ============================================================================
# 组合依赖：完整的管理员认证
# ============================================================================

async def require_admin_auth(
    auth_info: dict = Depends(verify_admin_token),
    ip_check: bool = Depends(verify_ip_whitelist)
) -> dict:
    """
    完整的管理员认证依赖（组合Token验证 + IP白名单）
    
    在管理后台路由中使用此依赖，确保请求已通过认证和授权。
    
    使用示例:
    ```python
    @router.post("/admin/extraction-rules")
    async def create_rule(
        rule_data: RuleCreate,
        admin: dict = Depends(require_admin_auth),
        service: AdminService = Depends(get_admin_service)
    ):
        # admin包含认证用户信息：{"username": "admin", "role": "admin", ...}
        return await service.create_extraction_rule(rule_data)
    ```
    
    参数:
    - auth_info: dict - Token验证结果
    - ip_check: bool - IP白名单验证结果
    
    返回:
    - dict - 认证用户信息
    """
    return auth_info


# ============================================================================
# 辅助函数
# ============================================================================

def _hash_token(token: str) -> str:
    """
    对Token进行哈希处理（用于日志记录，避免泄露原始Token）
    
    参数:
    - token: str - 原始Token
    
    返回:
    - str - Token的SHA256哈希值（前16位）
    """
    return hashlib.sha256(token.encode()).hexdigest()[:16]


def generate_admin_token(username: str, description: str = "") -> str:
    """
    生成新的管理员API Token
    
    参数:
    - username: str - 管理员用户名
    - description: str - Token描述
    
    返回:
    - str - 新生成的Token
    
    使用示例:
    ```python
    # 生成新Token
    new_token = generate_admin_token("admin_user", "用于生产环境")
    print(f"新Token: {new_token}")
    
    # 将Token添加到ADMIN_API_TOKENS配置中
    ADMIN_API_TOKENS[new_token] = {
        "username": "admin_user",
        "role": "admin",
        "created_at": datetime.now().isoformat(),
        "description": "用于生产环境"
    }
    ```
    """
    token = secrets.token_urlsafe(32)
    logger.info(
        "admin_token_generated",
        username=username,
        token_hash=_hash_token(token),
        description=description
    )
    return token


# ============================================================================
# 操作审计日志
# ============================================================================

class AuditLogger:
    """
    操作审计日志记录器
    
    记录所有管理后台的敏感操作，用于安全审计和问题追踪。
    """
    
    @staticmethod
    async def log_admin_action(
        admin_user: dict,
        action: str,
        resource_type: str,
        resource_id: any,
        details: dict = None
    ):
        """
        记录管理员操作
        
        参数:
        - admin_user: dict - 管理员用户信息
        - action: str - 操作类型（create/update/delete/batch_import等）
        - resource_type: str - 资源类型（extraction_rule/synonym/category等）
        - resource_id: any - 资源ID
        - details: dict - 操作详情
        """
        logger.info(
            "admin_action_audit",
            admin_username=admin_user.get("username"),
            admin_role=admin_user.get("role"),
            action=action,
            resource_type=resource_type,
            resource_id=resource_id,
            details=details,
            timestamp=datetime.now().isoformat()
        )


# ============================================================================
# 访问频率限制（简单实现，生产环境建议使用Redis）
# ============================================================================

_request_count_cache = {}  # {username: [(timestamp, count), ...]}


async def check_rate_limit(
    admin_user: dict = Depends(verify_admin_token)
) -> bool:
    """
    检查访问频率限制
    
    参数:
    - admin_user: dict - 管理员用户信息
    
    返回:
    - bool - 是否允许访问
    
    异常:
    - HTTPException 429: 请求过于频繁
    """
    if not ENABLE_RATE_LIMIT:
        return True
    
    username = admin_user.get("username")
    now = datetime.now()
    
    # 清理过期的计数记录（1分钟前）
    if username in _request_count_cache:
        _request_count_cache[username] = [
            (ts, count) for ts, count in _request_count_cache[username]
            if now - ts < timedelta(minutes=1)
        ]
    else:
        _request_count_cache[username] = []
    
    # 计算当前分钟内的请求数
    current_minute_requests = sum(
        count for ts, count in _request_count_cache[username]
    )
    
    # 检查是否超过限制
    if current_minute_requests >= MAX_REQUESTS_PER_MINUTE:
        logger.warning(
            "rate_limit_exceeded",
            username=username,
            requests_count=current_minute_requests,
            limit=MAX_REQUESTS_PER_MINUTE
        )
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "error_code": "RATE_LIMIT_EXCEEDED",
                "message": f"请求过于频繁，每分钟最多 {MAX_REQUESTS_PER_MINUTE} 次请求",
                "retry_after": 60
            },
            headers={"Retry-After": "60"}
        )
    
    # 记录本次请求
    _request_count_cache[username].append((now, 1))
    
    return True

