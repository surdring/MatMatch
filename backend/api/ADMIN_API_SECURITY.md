# 管理后台API安全认证指南

## 🔐 安全机制概述

管理后台API实现了多层安全防护机制，防止未授权访问和恶意操作。

### 安全特性

1. ✅ **API Token认证** - 基于Bearer Token的认证机制
2. ✅ **管理员权限验证** - 仅允许admin角色访问
3. ✅ **操作审计日志** - 记录所有敏感操作
4. ✅ **访问频率限制** - 防止暴力破解（60次/分钟）
5. ⚠️ **IP白名单**（可选）- 限制允许访问的IP地址

---

## 🔑 认证方式

### 方式1：Authorization Header（推荐）

```bash
curl -X POST "http://localhost:8000/api/v1/admin/extraction-rules" \
  -H "Authorization: Bearer <YOUR_ADMIN_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{...}'
```

### 方式2：X-API-Key Header（备用）

```bash
curl -X POST "http://localhost:8000/api/v1/admin/extraction-rules" \
  -H "X-API-Key: <YOUR_ADMIN_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{...}'
```

---

## 🚀 快速开始

### 1. 获取管理员Token

**开发环境（默认Token）：**
```
admin_dev_token_change_in_production
```

⚠️ **警告**：此Token仅用于开发测试，生产环境必须更换！

**生产环境（生成新Token）：**

```python
# 方法1：使用Python生成
python -c "import secrets; print(secrets.token_urlsafe(32))"

# 方法2：使用内置函数
from backend.api.dependencies_auth import generate_admin_token
token = generate_admin_token("production_admin", "生产环境管理员Token")
print(f"新Token: {token}")
```

### 2. 配置Token

编辑 `backend/api/dependencies_auth.py`：

```python
ADMIN_API_TOKENS = {
    "your_secure_token_here": {
        "username": "admin",
        "role": "admin",
        "created_at": "2025-10-08",
        "description": "生产环境管理员"
    }
}
```

### 3. 使用Token访问API

**Swagger UI测试：**

1. 访问 http://localhost:8000/docs
2. 点击右上角🔒 "Authorize"按钮
3. 输入Token: `admin_dev_token_change_in_production`
4. 点击"Authorize"
5. 现在可以测试所有管理后台API

**Python代码示例：**

```python
import requests

# 配置
BASE_URL = "http://localhost:8000"
ADMIN_TOKEN = "admin_dev_token_change_in_production"

# 请求头
headers = {
    "Authorization": f"Bearer {ADMIN_TOKEN}",
    "Content-Type": "application/json"
}

# 创建提取规则
response = requests.post(
    f"{BASE_URL}/api/v1/admin/extraction-rules",
    headers=headers,
    json={
        "rule_name": "规格提取-轴承",
        "material_category": "bearing",
        "attribute_name": "规格",
        "regex_pattern": r"Φ(\d+)×(\d+)×(\d+)",
        "priority": 100,
        "is_active": True,
        "description": "提取轴承规格"
    }
)

print(response.json())
```

---

## 🛡️ 安全配置选项

### 1. 启用IP白名单

编辑 `backend/api/dependencies_auth.py`：

```python
# 启用IP白名单
ENABLE_IP_WHITELIST = True

# 允许的IP地址
ALLOWED_IPS = [
    "127.0.0.1",      # 本地
    "::1",            # IPv6本地
    "192.168.1.0/24", # 局域网（支持CIDR）
    "10.0.0.100"      # 特定服务器
]
```

### 2. 调整访问频率限制

```python
# 启用频率限制
ENABLE_RATE_LIMIT = True

# 每分钟最大请求数
MAX_REQUESTS_PER_MINUTE = 60  # 调整为30/60/120等
```

### 3. 禁用认证（仅开发环境）

⚠️ **不推荐**：生产环境必须启用认证！

如需临时禁用（仅开发调试）：

```python
# 在 admin.py 中注释掉全局认证依赖
router = APIRouter(
    prefix="/api/v1/admin",
    tags=["Admin Management"],
    # dependencies=[Depends(require_admin_auth)],  # ← 注释此行
    ...
)
```

---

## 📊 操作审计日志

所有管理后台操作都会自动记录审计日志。

**日志内容：**
```json
{
  "level": "info",
  "event": "admin_action_audit",
  "admin_username": "admin",
  "admin_role": "admin",
  "action": "create",
  "resource_type": "extraction_rule",
  "resource_id": 123,
  "details": {"rule_name": "规格提取-轴承"},
  "timestamp": "2025-10-08T10:30:00"
}
```

**查看日志：**
```bash
# 实时查看
tail -f backend/logs/app.log | grep admin_action_audit

# 搜索特定操作
grep "admin_action_audit" backend/logs/app.log | grep "delete"
```

---

## ⚠️ 错误码说明

| HTTP状态码 | 错误码 | 说明 | 解决方案 |
|-----------|--------|------|---------|
| 401 | AUTH_TOKEN_MISSING | 未提供Token | 添加Authorization或X-API-Key头 |
| 401 | AUTH_TOKEN_INVALID | Token无效 | 检查Token是否正确 |
| 403 | AUTH_INSUFFICIENT_PERMISSIONS | 权限不足 | 确保使用admin角色的Token |
| 403 | IP_NOT_ALLOWED | IP不在白名单 | 将IP添加到ALLOWED_IPS |
| 429 | RATE_LIMIT_EXCEEDED | 请求过于频繁 | 等待60秒后重试 |

---

## 🔧 故障排查

### 问题1：Token认证失败

**症状**：
```json
{
  "error_code": "AUTH_TOKEN_INVALID",
  "message": "无效的认证Token"
}
```

**解决方案**：
1. 检查Token是否正确复制（无多余空格）
2. 确认Token已添加到 `ADMIN_API_TOKENS` 配置
3. 检查Token的role是否为"admin"

### 问题2：IP被阻止

**症状**：
```json
{
  "error_code": "IP_NOT_ALLOWED",
  "message": "IP地址 xxx.xxx.xxx.xxx 不在白名单中"
}
```

**解决方案**：
1. 将IP添加到 `ALLOWED_IPS`
2. 或临时禁用IP白名单：`ENABLE_IP_WHITELIST = False`

### 问题3：请求过于频繁

**症状**：
```json
{
  "error_code": "RATE_LIMIT_EXCEEDED",
  "message": "请求过于频繁，每分钟最多 60 次请求"
}
```

**解决方案**：
1. 等待60秒后重试
2. 或调整 `MAX_REQUESTS_PER_MINUTE` 限制
3. 或临时禁用频率限制：`ENABLE_RATE_LIMIT = False`

---

## 🔒 生产环境部署检查清单

部署到生产环境前，请确保：

- [ ] ✅ 已更换默认的开发Token
- [ ] ✅ Token使用了强随机字符串（32字节以上）
- [ ] ✅ Token存储在环境变量或密钥管理服务中（不要硬编码）
- [ ] ✅ 启用了IP白名单（如适用）
- [ ] ✅ 启用了访问频率限制
- [ ] ✅ 配置了审计日志持久化存储
- [ ] ✅ 定期轮换Token
- [ ] ✅ 监控异常认证失败次数（防暴力破解）

---

## 📚 相关文档

- **认证实现**: `backend/api/dependencies_auth.py`
- **路由定义**: `backend/api/routers/admin.py`
- **审计日志**: `backend/logs/app.log`
- **API文档**: http://localhost:8000/docs

---

**维护者**: AI-DEV  
**最后更新**: 2025-10-08

