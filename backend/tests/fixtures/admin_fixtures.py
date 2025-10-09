"""
管理后台API测试夹具 (Fixtures)

本模块提供管理后台API测试所需的共享夹具，包括：
- 测试数据库会话
- 认证Token
- 测试数据清理
- 公共测试数据

符合GEMINI.md测试规范
"""

import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from typing import AsyncGenerator

from backend.api.main import app
from backend.database.session import get_db
from backend.models.materials import Base


# ============================================================================
# 测试数据库配置
# ============================================================================

# 使用内存数据库进行测试（更快）
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

# 创建测试引擎
test_engine = create_async_engine(
    TEST_DATABASE_URL,
    echo=False,
    future=True
)

# 创建测试会话工厂
TestSessionLocal = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False
)


# ============================================================================
# 数据库夹具
# ============================================================================

@pytest_asyncio.fixture(scope="function")
async def test_db() -> AsyncGenerator[AsyncSession, None]:
    """
    测试数据库会话夹具
    
    每个测试函数都会获得一个独立的数据库会话，
    测试结束后自动清理。
    
    使用示例:
    ```python
    async def test_example(test_db):
        # test_db 是一个异步数据库会话
        result = await test_db.execute(...)
    ```
    """
    # 创建所有表
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # 创建会话
    async with TestSessionLocal() as session:
        yield session
    
    # 清理：删除所有表
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture(scope="function")
async def override_get_db(test_db: AsyncSession):
    """
    覆盖应用的数据库依赖
    
    将应用的get_db依赖替换为测试数据库会话
    """
    async def _override_get_db():
        yield test_db
    
    app.dependency_overrides[get_db] = _override_get_db
    yield
    app.dependency_overrides.clear()


# ============================================================================
# HTTP客户端夹具
# ============================================================================

@pytest_asyncio.fixture(scope="function")
async def client(override_get_db) -> AsyncGenerator[AsyncClient, None]:
    """
    异步HTTP客户端夹具
    
    提供一个已配置好的测试HTTP客户端，
    包含认证Token和测试数据库依赖。
    
    使用示例:
    ```python
    async def test_api(client):
        response = await client.get("/api/v1/admin/extraction-rules")
        assert response.status_code == 200
    ```
    """
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac


@pytest_asyncio.fixture(scope="function")
async def authenticated_client(override_get_db) -> AsyncGenerator[AsyncClient, None]:
    """
    已认证的HTTP客户端夹具
    
    提供一个已包含管理员Token的HTTP客户端，
    可直接调用需要认证的管理后台API。
    
    使用示例:
    ```python
    async def test_admin_api(authenticated_client):
        # 自动包含认证Token
        response = await authenticated_client.get("/api/v1/admin/extraction-rules")
        assert response.status_code == 200
    ```
    """
    headers = {
        "Authorization": "Bearer admin_dev_token_change_in_production"
    }
    
    async with AsyncClient(app=app, base_url="http://test", headers=headers) as ac:
        yield ac


# ============================================================================
# 认证夹具
# ============================================================================

@pytest.fixture
def admin_headers() -> dict:
    """
    管理员认证头夹具
    
    返回包含管理员Token的请求头字典
    
    使用示例:
    ```python
    async def test_with_auth(client, admin_headers):
        response = await client.get("/api/v1/admin/rules", headers=admin_headers)
    ```
    """
    return {
        "Authorization": "Bearer admin_dev_token_change_in_production"
    }


@pytest.fixture
def invalid_token_headers() -> dict:
    """
    无效Token认证头夹具
    
    用于测试认证失败场景
    """
    return {
        "Authorization": "Bearer invalid_token_12345"
    }


# ============================================================================
# 测试数据夹具
# ============================================================================

@pytest.fixture
def sample_extraction_rule() -> dict:
    """
    示例提取规则数据夹具
    
    返回一个标准的提取规则数据字典，
    可用于创建测试规则。
    """
    return {
        "rule_name": "测试规则-示例",
        "material_category": "general",
        "attribute_name": "属性",
        "regex_pattern": r"\d+",
        "priority": 50,
        "is_active": True,
        "description": "这是一个测试用的提取规则"
    }


@pytest.fixture
def sample_synonym() -> dict:
    """
    示例同义词数据夹具
    
    返回一个标准的同义词数据字典
    """
    return {
        "standard_term": "测试标准词",
        "synonym": "测试同义词",
        "category": "test",
        "confidence": 0.9,
        "is_active": True
    }


@pytest.fixture
def sample_material_category() -> dict:
    """
    示例物料分类数据夹具
    
    返回一个标准的物料分类数据字典
    """
    return {
        "category_name": "测试分类",
        "keywords": ["test", "测试", "样例"],
        "description": "这是一个测试用的物料分类",
        "is_active": True
    }


@pytest.fixture
def batch_extraction_rules(sample_extraction_rule) -> list:
    """
    批量提取规则数据夹具
    
    返回10个测试规则的列表
    """
    return [
        {
            **sample_extraction_rule,
            "rule_name": f"批量规则-{i}",
            "attribute_name": f"属性{i}",
            "priority": i * 10
        }
        for i in range(1, 11)
    ]


@pytest.fixture
def batch_synonyms(sample_synonym) -> list:
    """
    批量同义词数据夹具
    
    返回10个测试同义词的列表
    """
    return [
        {
            **sample_synonym,
            "synonym": f"同义词{i}",
            "confidence": 0.8 + i * 0.01
        }
        for i in range(1, 11)
    ]


# ============================================================================
# 数据清理夹具
# ============================================================================

@pytest_asyncio.fixture(scope="function")
async def clean_extraction_rules(test_db: AsyncSession):
    """
    清理提取规则数据夹具
    
    在测试前后自动清理提取规则表
    """
    # 测试前清理
    from backend.models.materials import ExtractionRule
    await test_db.execute(delete(ExtractionRule))
    await test_db.commit()
    
    yield
    
    # 测试后清理
    await test_db.execute(delete(ExtractionRule))
    await test_db.commit()


@pytest_asyncio.fixture(scope="function")
async def clean_synonyms(test_db: AsyncSession):
    """
    清理同义词数据夹具
    
    在测试前后自动清理同义词表
    """
    # 测试前清理
    from backend.models.materials import Synonym
    from sqlalchemy import delete
    
    await test_db.execute(delete(Synonym))
    await test_db.commit()
    
    yield
    
    # 测试后清理
    await test_db.execute(delete(Synonym))
    await test_db.commit()


# ============================================================================
# 性能测试夹具
# ============================================================================

@pytest.fixture
def performance_threshold() -> dict:
    """
    性能阈值配置夹具
    
    定义各种操作的性能阈值，
    用于性能测试的断言。
    """
    return {
        "api_response_time_ms": 200,  # API响应时间 ≤ 200ms
        "batch_import_100_rules_seconds": 1.0,  # 100条规则导入 ≤ 1秒
        "batch_import_500_synonyms_seconds": 2.0,  # 500条同义词导入 ≤ 2秒
        "cache_refresh_ms": 500,  # 缓存刷新 ≤ 500ms
        "concurrent_requests_avg_ms": 500  # 并发请求平均响应 ≤ 500ms
    }


# ============================================================================
# Mock数据夹具
# ============================================================================

@pytest.fixture
def mock_etl_jobs() -> list:
    """
    Mock ETL任务数据夹具
    
    返回模拟的ETL任务列表，
    用于测试ETL监控功能。
    """
    from datetime import datetime, timedelta
    
    jobs = []
    for i in range(1, 6):
        jobs.append({
            "id": i,
            "job_type": "full_sync" if i % 2 == 0 else "incremental_sync",
            "status": "success" if i % 3 != 0 else "failed",
            "started_at": (datetime.now() - timedelta(days=i)).isoformat(),
            "ended_at": (datetime.now() - timedelta(days=i, hours=-1)).isoformat(),
            "processed_records": 1000 * i,
            "failed_records": 0 if i % 3 != 0 else 10,
            "error_message": None if i % 3 != 0 else "测试错误"
        })
    
    return jobs


@pytest.fixture
def mock_etl_statistics() -> dict:
    """
    Mock ETL统计数据夹具
    
    返回模拟的ETL统计信息
    """
    return {
        "total_jobs": 100,
        "success_jobs": 95,
        "failed_jobs": 5,
        "success_rate": 95.0,
        "avg_duration_seconds": 120.5
    }


# ============================================================================
# 辅助函数夹具
# ============================================================================

@pytest.fixture
def create_test_rule(authenticated_client):
    """
    创建测试规则的辅助函数夹具
    
    返回一个async函数，可用于快速创建测试规则
    
    使用示例:
    ```python
    async def test_example(create_test_rule):
        rule = await create_test_rule("测试规则", "bearing")
        assert rule["id"] is not None
    ```
    """
    async def _create_rule(rule_name: str, category: str = "general"):
        rule_data = {
            "rule_name": rule_name,
            "material_category": category,
            "attribute_name": "属性",
            "regex_pattern": r"\d+",
            "priority": 50
        }
        
        response = await authenticated_client.post(
            "/api/v1/admin/extraction-rules",
            json=rule_data
        )
        
        if response.status_code == 201:
            return response.json()
        else:
            raise Exception(f"创建规则失败: {response.text}")
    
    return _create_rule


@pytest.fixture
def create_test_synonym(authenticated_client):
    """
    创建测试同义词的辅助函数夹具
    
    返回一个async函数，可用于快速创建测试同义词
    """
    async def _create_synonym(standard_term: str, synonym: str, category: str = "test"):
        synonym_data = {
            "standard_term": standard_term,
            "synonym": synonym,
            "category": category,
            "confidence": 0.9
        }
        
        response = await authenticated_client.post(
            "/api/v1/admin/synonyms",
            json=synonym_data
        )
        
        if response.status_code == 201:
            return response.json()
        else:
            raise Exception(f"创建同义词失败: {response.text}")
    
    return _create_synonym

