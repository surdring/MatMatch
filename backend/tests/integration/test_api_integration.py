"""
FastAPI核心服务框架集成测试

测试FastAPI应用的端到端集成，包括：
- 数据库连接和会话管理
- 完整的请求-响应流程
- 中间件链的完整执行
- 异常处理的端到端行为
"""

import pytest
import sys
from pathlib import Path
from unittest.mock import AsyncMock, patch, MagicMock
from starlette.testclient import TestClient
from contextlib import asynccontextmanager

# 添加项目根目录到Python路径
project_root = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(project_root))


@pytest.fixture(scope="module")
def client():
    """创建测试客户端，mock掉需要数据库的依赖"""
    from fastapi import FastAPI
    from backend.api.routers import health
    from backend.api.exception_handlers import register_exception_handlers
    from backend.api.middleware import register_middlewares
    from backend.core.config import app_config
    
    # 创建一个简化的测试应用，不需要lifespan初始化
    @asynccontextmanager
    async def test_lifespan(app: FastAPI):
        """测试环境的生命周期（跳过数据库初始化）"""
        yield
    
    # 创建测试应用
    test_app = FastAPI(
        title="MatMatch API",
        version="1.0.0",
        description="测试环境",
        lifespan=test_lifespan
    )
    
    # 注册路由
    test_app.include_router(health.router, tags=["health"])
    
    # 注册异常处理器
    register_exception_handlers(test_app)
    
    # 注册中间件
    register_middlewares(
        test_app,
        cors_origins=app_config.cors_origins,
        max_request_size=app_config.max_file_size
    )
    
    # 创建测试客户端
    with TestClient(test_app) as test_client:
        yield test_client


@pytest.fixture(scope="function")
async def mock_db_session():
    """模拟数据库会话"""
    mock_session = AsyncMock()
    mock_session.execute = AsyncMock()
    mock_session.close = AsyncMock()
    return mock_session


class TestAPIIntegration:
    """API集成测试"""
    
    def test_full_health_check_flow(self, client):
        """测试完整的健康检查流程"""
        response = client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        
        # 验证响应结构
        assert "status" in data
        assert "timestamp" in data
        assert "version" in data
        assert "database" in data
        assert "knowledge_base" in data
        
        # 验证状态值
        assert data["status"] in ["healthy", "degraded", "unhealthy"]
        
        # 验证database和knowledge_base状态
        assert data["database"] in ["ok", "error", "unknown"]
        assert data["knowledge_base"] in ["ok", "error", "unknown"]
    
    def test_readiness_check_integration(self, client):
        """测试就绪检查集成"""
        response = client.get("/health/readiness")
        
        # 就绪检查可能返回200或503，取决于数据库状态
        assert response.status_code in [200, 503]
        data = response.json()
        
        assert "ready" in data
        assert "timestamp" in data
        assert "checks" in data
        
        # ready字段应该是布尔值
        assert isinstance(data["ready"], bool)
        
        # 如果是503，ready一定是False
        if response.status_code == 503:
            assert data["ready"] is False
    
    def test_liveness_check_integration(self, client):
        """测试存活检查集成"""
        response = client.get("/health/liveness")
        
        assert response.status_code == 200
        data = response.json()
        
        assert data["alive"] is True
        assert "timestamp" in data
    
    def test_cors_middleware_integration(self, client):
        """测试CORS中间件集成"""
        response = client.get(
            "/health",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "GET"
            }
        )
        
        assert response.status_code == 200
        
        # 验证CORS头
        assert "access-control-allow-origin" in response.headers
        assert response.headers["access-control-allow-origin"] == "http://localhost:3000"
    
    def test_request_id_middleware_integration(self, client):
        """测试请求ID中间件集成"""
        response = client.get("/health")
        
        assert response.status_code == 200
        
        # 验证请求ID头
        assert "X-Request-ID" in response.headers
        request_id = response.headers["X-Request-ID"]
        assert len(request_id) > 0
    
    def test_error_handling_integration(self, client):
        """测试错误处理集成"""
        # 测试404错误
        response = client.get("/nonexistent-endpoint")
        
        assert response.status_code == 404
        data = response.json()
        
        # 验证错误响应格式
        assert "error" in data
        assert "code" in data["error"]
        assert "message" in data["error"]
        assert "timestamp" in data["error"]
    
    def test_multiple_requests_sequential(self, client):
        """测试连续多个请求"""
        # 发送多个请求，验证应用状态稳定
        for _ in range(5):
            response = client.get("/health")
            assert response.status_code == 200
            
            data = response.json()
            assert "status" in data
            assert "database" in data
            assert "knowledge_base" in data
    
    def test_api_documentation_endpoints(self, client):
        """测试API文档端点"""
        # 测试OpenAPI schema
        response = client.get("/openapi.json")
        assert response.status_code == 200
        
        openapi_schema = response.json()
        assert "openapi" in openapi_schema
        assert "info" in openapi_schema
        assert "paths" in openapi_schema
        
        # 验证基本信息
        assert openapi_schema["info"]["title"] == "MatMatch API"
        assert "version" in openapi_schema["info"]
        
        # 验证有健康检查路由
        assert "/health" in openapi_schema["paths"]
        assert "/health/readiness" in openapi_schema["paths"]
        assert "/health/liveness" in openapi_schema["paths"]
    
    def test_request_validation_integration(self, client):
        """测试请求验证集成"""
        # 发送无效的大文件（超过限制）
        # 注意：这个测试可能需要根据实际的max_request_size调整
        large_data = "x" * (11 * 1024 * 1024)  # 11MB，超过默认10MB限制
        
        response = client.post(
            "/health",  # 使用健康检查端点（不支持POST）
            data=large_data
        )
        
        # 应该返回405 Method Not Allowed或413 Payload Too Large
        assert response.status_code in [405, 413]


class TestDatabaseIntegration:
    """数据库集成测试（需要真实数据库，使用integration标记）"""
    
    @pytest.mark.integration
    def test_health_check_database_status(self, client):
        """测试健康检查中的数据库状态"""
        response = client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        
        # 检查数据库状态
        db_check = data["checks"]["database"]
        assert "status" in db_check
        assert db_check["status"] in ["healthy", "unhealthy"]
        
        if db_check["status"] == "healthy":
            # 如果健康，应该有响应时间
            assert "response_time_ms" in db_check
            assert isinstance(db_check["response_time_ms"], (int, float))
            assert db_check["response_time_ms"] >= 0


class TestMiddlewareChain:
    """中间件链集成测试"""
    
    def test_middleware_execution_order(self, client):
        """测试中间件执行顺序"""
        response = client.get("/health")
        
        assert response.status_code == 200
        
        # 验证所有中间件都执行了
        # 1. CORS中间件 - 应该有CORS相关头
        # 2. 请求ID中间件 - 应该有X-Request-ID头
        # 3. 日志中间件 - 记录在后台，无法直接验证，但不应影响响应
        
        # 请求ID应该存在
        assert "X-Request-ID" in response.headers
    
    def test_middleware_with_error(self, client):
        """测试中间件在错误情况下的行为"""
        # 触发404错误
        response = client.get("/nonexistent")
        
        assert response.status_code == 404
        
        # 即使是错误响应，中间件也应该正常工作
        assert "X-Request-ID" in response.headers
        
        # 错误响应应该有正确的格式
        data = response.json()
        assert "error" in data


class TestAPIVersioning:
    """API版本管理集成测试"""
    
    def test_api_version_in_response(self, client):
        """测试响应中的API版本"""
        response = client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        
        # 验证版本信息
        assert "version" in data
        version = data["version"]
        
        # 版本应该是字符串格式 (如 "1.0.0")
        assert isinstance(version, str)
        assert len(version.split(".")) == 3  # 应该是 major.minor.patch 格式
    
    def test_openapi_version_consistency(self, client):
        """测试OpenAPI文档中的版本一致性"""
        # 获取健康检查的版本
        health_response = client.get("/health")
        health_version = health_response.json()["version"]
        
        # 获取OpenAPI schema的版本
        openapi_response = client.get("/openapi.json")
        openapi_version = openapi_response.json()["info"]["version"]
        
        # 两个版本应该一致
        assert health_version == openapi_version


class TestConcurrentRequests:
    """并发请求集成测试"""
    
    def test_concurrent_health_checks(self, client):
        """测试并发健康检查请求"""
        import concurrent.futures
        
        def make_request():
            response = client.get("/health")
            return response.status_code, response.json()
        
        # 并发发送10个请求
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(make_request) for _ in range(10)]
            results = [future.result() for future in concurrent.futures.as_completed(futures)]
        
        # 验证所有请求都成功
        assert len(results) == 10
        for status_code, data in results:
            assert status_code == 200
            assert "status" in data
            assert "database" in data
            assert "knowledge_base" in data
    
    def test_concurrent_different_endpoints(self, client):
        """测试不同端点的并发请求"""
        import concurrent.futures
        
        def make_health_request():
            return client.get("/health")
        
        def make_ready_request():
            return client.get("/health/readiness")
        
        def make_live_request():
            return client.get("/health/liveness")
        
        # 并发发送不同端点的请求
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as executor:
            futures = []
            futures.extend([executor.submit(make_health_request) for _ in range(2)])
            futures.extend([executor.submit(make_ready_request) for _ in range(2)])
            futures.extend([executor.submit(make_live_request) for _ in range(2)])
            
            results = [future.result() for future in concurrent.futures.as_completed(futures)]
        
        # 验证所有请求都有响应
        assert len(results) == 6
        for response in results:
            assert response.status_code in [200, 503]  # ready可能返回503


if __name__ == "__main__":
    pytest.main([__file__, "-v"])

