"""
FastAPI框架核心功能测试

测试FastAPI应用的基础框架功能，包括:
- 应用创建和配置
- 路由注册
- 依赖注入
- 中间件
- 异常处理
"""

import pytest
import sys
import warnings
from pathlib import Path
from unittest.mock import Mock, AsyncMock, patch, MagicMock
from starlette.testclient import TestClient

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

# 过滤httpx的TestClient弃用警告（这是库内部问题，不是我们的代码）
warnings.filterwarnings("ignore", message="The 'app' shortcut is now deprecated", category=DeprecationWarning)

from backend.api.main import app
from backend.api.exceptions import (
    APIException,
    NotFoundException,
    ValidationException,
    DatabaseException
)


# ==================== 测试客户端 ====================

@pytest.fixture
def client():
    """创建测试客户端"""
    return TestClient(app)


# ==================== 应用启动测试 ====================

def test_app_creation():
    """
    测试1: FastAPI应用创建
    
    验证FastAPI应用实例正确创建
    """
    assert app is not None
    assert app.title == "MatMatch API"
    assert "1.0.0" in app.version
    print("✅ 测试1通过: FastAPI应用创建成功")


def test_app_metadata():
    """
    测试2: 应用元数据
    
    验证应用的基本信息配置正确
    """
    assert app.docs_url == "/docs"
    assert app.redoc_url == "/redoc"
    assert app.openapi_url == "/openapi.json"
    print("✅ 测试2通过: 应用元数据配置正确")


# ==================== 路由测试 ====================

def test_root_endpoint(client):
    """
    测试3: 根路径端点
    
    验证根路径返回正确的API信息
    """
    response = client.get("/")
    
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "version" in data
    assert "docs" in data
    assert data["docs"] == "/docs"
    print("✅ 测试3通过: 根路径端点正常")


def test_health_check_endpoint(client):
    """
    测试4: 健康检查端点
    
    验证健康检查接口返回正确的状态信息
    """
    response = client.get("/health")
    
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "timestamp" in data
    assert "version" in data
    assert "database" in data
    assert "knowledge_base" in data
    print("✅ 测试4通过: 健康检查端点正常")


def test_readiness_check_endpoint(client):
    """
    测试5: 就绪检查端点
    
    验证就绪检查接口返回正确的检查结果
    """
    response = client.get("/health/readiness")
    
    assert response.status_code == 200
    data = response.json()
    assert "ready" in data
    assert "checks" in data
    assert "timestamp" in data
    assert isinstance(data["checks"], dict)
    print("✅ 测试5通过: 就绪检查端点正常")


def test_liveness_check_endpoint(client):
    """
    测试6: 存活检查端点
    
    验证存活检查接口返回正确状态
    """
    response = client.get("/health/liveness")
    
    assert response.status_code == 200
    data = response.json()
    assert "alive" in data
    assert data["alive"] is True
    assert "timestamp" in data
    print("✅ 测试6通过: 存活检查端点正常")


def test_ping_endpoint(client):
    """
    测试7: Ping端点
    
    验证ping端点快速响应
    """
    response = client.get("/ping")
    
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "pong"
    print("✅ 测试7通过: Ping端点正常")


# ==================== 中间件测试 ====================

def test_request_id_header(client):
    """
    测试8: 请求ID中间件
    
    验证每个请求都会添加请求ID
    """
    response = client.get("/health/liveness")
    
    assert response.status_code == 200
    assert "X-Request-ID" in response.headers
    assert "X-Process-Time" in response.headers
    
    # 验证请求ID是UUID格式
    request_id = response.headers["X-Request-ID"]
    assert len(request_id) == 36  # UUID长度
    assert request_id.count("-") == 4  # UUID有4个连字符
    
    print("✅ 测试8通过: 请求ID中间件正常")


def test_cors_headers(client):
    """
    测试9: CORS中间件
    
    验证CORS头正确配置
    """
    # 使用GET请求测试CORS（OPTIONS可能不被支持）
    response = client.get(
        "/health",
        headers={"Origin": "http://localhost:3000"}
    )
    
    # GET请求应该返回200
    assert response.status_code == 200
    
    # 验证CORS头存在
    assert "access-control-allow-origin" in response.headers or "Access-Control-Allow-Origin" in response.headers
    
    print("✅ 测试9通过: CORS中间件正常")


# ==================== 异常处理测试 ====================

def test_not_found_exception():
    """
    测试10: 404异常
    
    验证访问不存在的路径返回404
    """
    client_test = TestClient(app)
    response = client_test.get("/nonexistent-path")
    
    assert response.status_code == 404
    data = response.json()
    assert "error" in data
    assert data["error"]["code"] == "NOT_FOUND"
    print("✅ 测试10通过: 404异常处理正常")


def test_custom_exception_structure():
    """
    测试11: 自定义异常结构
    
    验证自定义异常类的结构正确（简化版）
    """
    from backend.api.exceptions import MatMatchAPIException
    
    exc = MatMatchAPIException(
        message="测试错误",
        error_code="TEST_ERROR"
    )
    
    assert exc.message == "测试错误"
    assert exc.error_code == "TEST_ERROR"
    print("✅ 测试11通过: 自定义异常结构正确")


def test_not_found_exception_creation():
    """
    测试12: NotFoundException
    
    验证NotFoundException正确创建（简化版）
    """
    exc = NotFoundException(message="物料未找到")
    
    assert exc.error_code == "NOT_FOUND"
    assert exc.message == "物料未找到"
    print("✅ 测试12通过: NotFoundException正确")


def test_validation_exception_creation():
    """
    测试13: ValidationException
    
    验证ValidationException正确创建（简化版）
    """
    exc = ValidationException(message="字段验证失败")
    
    assert exc.error_code == "VALIDATION_ERROR"
    assert exc.message == "字段验证失败"
    print("✅ 测试13通过: ValidationException正确")


def test_database_exception_creation():
    """
    测试14: DatabaseException
    
    验证DatabaseException正确创建（简化版）
    """
    exc = DatabaseException(message="查询失败")
    
    assert exc.error_code == "DATABASE_ERROR"
    assert exc.message == "查询失败"
    print("✅ 测试14通过: DatabaseException正确")


# ==================== API文档测试 ====================

def test_swagger_docs_available(client):
    """
    测试15: Swagger文档可访问
    
    验证Swagger UI文档正常加载
    """
    response = client.get("/docs")
    
    assert response.status_code == 200
    assert "swagger" in response.text.lower() or "openapi" in response.text.lower()
    print("✅ 测试15通过: Swagger文档可访问")


def test_redoc_docs_available(client):
    """
    测试16: ReDoc文档可访问
    
    验证ReDoc文档正常加载
    """
    response = client.get("/redoc")
    
    assert response.status_code == 200
    assert "redoc" in response.text.lower()
    print("✅ 测试16通过: ReDoc文档可访问")


def test_openapi_json_available(client):
    """
    测试17: OpenAPI JSON可访问
    
    验证OpenAPI规范JSON文件可访问
    """
    response = client.get("/openapi.json")
    
    assert response.status_code == 200
    data = response.json()
    assert "openapi" in data
    assert "info" in data
    assert data["info"]["title"] == "MatMatch API"
    print("✅ 测试17通过: OpenAPI JSON可访问")


# ==================== 响应格式测试 ====================

def test_error_response_format(client):
    """
    测试18: 错误响应格式统一
    
    验证所有错误响应使用统一格式
    """
    response = client.get("/nonexistent")
    
    assert response.status_code == 404
    data = response.json()
    
    # 验证错误响应结构
    assert "error" in data
    error = data["error"]
    assert "code" in error
    assert "message" in error
    assert "timestamp" in error
    assert "path" in error
    
    print("✅ 测试18通过: 错误响应格式统一")


def test_success_response_format(client):
    """
    测试19: 成功响应格式
    
    验证成功响应包含必要字段
    """
    response = client.get("/health/liveness")
    
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, dict)
    assert "alive" in data or "status" in data
    print("✅ 测试19通过: 成功响应格式正确")


# ==================== 运行所有测试 ====================

if __name__ == '__main__':
    import asyncio
    
    def run_all_tests():
        """运行所有测试"""
        client_instance = TestClient(app)
        
        tests = [
            ("FastAPI应用创建", lambda: test_app_creation()),
            ("应用元数据", lambda: test_app_metadata()),
            ("根路径端点", lambda: test_root_endpoint(client_instance)),
            ("健康检查端点", lambda: test_health_check_endpoint(client_instance)),
            ("就绪检查端点", lambda: test_readiness_check_endpoint(client_instance)),
            ("存活检查端点", lambda: test_liveness_check_endpoint(client_instance)),
            ("Ping端点", lambda: test_ping_endpoint(client_instance)),
            ("请求ID中间件", lambda: test_request_id_header(client_instance)),
            ("CORS中间件", lambda: test_cors_headers(client_instance)),
            ("404异常处理", lambda: test_not_found_exception()),
            ("自定义异常结构", lambda: test_custom_exception_structure()),
            ("NotFoundException", lambda: test_not_found_exception_creation()),
            ("ValidationException", lambda: test_validation_exception_creation()),
            ("DatabaseException", lambda: test_database_exception_creation()),
            ("Swagger文档可访问", lambda: test_swagger_docs_available(client_instance)),
            ("ReDoc文档可访问", lambda: test_redoc_docs_available(client_instance)),
            ("OpenAPI JSON可访问", lambda: test_openapi_json_available(client_instance)),
            ("错误响应格式", lambda: test_error_response_format(client_instance)),
            ("成功响应格式", lambda: test_success_response_format(client_instance)),
        ]
        
        print("\n" + "="*80)
        print("开始运行FastAPI框架测试")
        print("="*80 + "\n")
        
        passed = 0
        failed = 0
        
        for name, test_func in tests:
            try:
                print(f"\n运行测试: {name}")
                print("-"*80)
                test_func()
                passed += 1
            except AssertionError as e:
                print(f"❌ 测试失败: {name}")
                print(f"   错误: {str(e)}")
                failed += 1
            except Exception as e:
                print(f"❌ 测试异常: {name}")
                print(f"   异常: {str(e)}")
                import traceback
                traceback.print_exc()
                failed += 1
        
        print("\n" + "="*80)
        print(f"测试完成: {passed} 通过, {failed} 失败")
        print("="*80 + "\n")
        
        return failed == 0
    
    success = run_all_tests()
    sys.exit(0 if success else 1)

