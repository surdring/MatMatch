"""
SimilarityCalculator单元测试

测试多字段加权相似度计算、缓存机制、性能等核心功能
"""

import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock

from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.calculators.similarity_calculator import (
    SimilarityCalculator,
    DEFAULT_WEIGHTS
)
from backend.core.schemas.material_schemas import ParsedQuery, MaterialResult


# ==================== Fixtures ====================

@pytest.fixture
def mock_db_session():
    """模拟数据库会话"""
    session = AsyncMock(spec=AsyncSession)
    return session


@pytest.fixture
def sample_parsed_query():
    """示例查询对象"""
    return ParsedQuery(
        standardized_name="六角螺栓 M8*20",
        attributes={"规格": "M8*20", "材质": "304"},
        detected_category="螺栓螺钉",
        confidence=0.95,
        full_description="六角螺栓 M8*20 304不锈钢",
        processing_steps=["步骤1", "步骤2"]
    )


@pytest.fixture
def mock_query_results():
    """模拟查询结果"""
    # 模拟SQLAlchemy Row对象
    row1 = MagicMock()
    row1.erp_code = "MAT001"
    row1.material_name = "六角螺栓"
    row1.specification = "M8*20"
    row1.model = ""
    row1.normalized_name = "六角螺栓 M8*20"
    row1.full_description = "六角螺栓 M8*20 304"
    row1.attributes = {"规格": "M8*20", "材质": "304"}
    row1.detected_category = "螺栓螺钉"
    row1.category_confidence = 0.95
    row1.oracle_category_id = 1001
    row1.oracle_unit_id = 2001
    row1.similarity_score = 0.92
    row1.name_similarity = 0.95
    row1.description_similarity = 0.90
    row1.attributes_similarity = 0.88
    row1.category_similarity = 1.0
    
    row2 = MagicMock()
    row2.erp_code = "MAT002"
    row2.material_name = "内六角螺栓"
    row2.specification = "M8*25"
    row2.model = ""
    row2.normalized_name = "内六角螺栓 M8*25"
    row2.full_description = "内六角螺栓 M8*25 304"
    row2.attributes = {"规格": "M8*25", "材质": "304"}
    row2.detected_category = "螺栓螺钉"
    row2.category_confidence = 0.93
    row2.oracle_category_id = 1001
    row2.oracle_unit_id = 2001
    row2.similarity_score = 0.85
    row2.name_similarity = 0.80
    row2.description_similarity = 0.85
    row2.attributes_similarity = 0.90
    row2.category_similarity = 1.0
    
    return [row1, row2]


@pytest.fixture
def calculator_with_mock_data(mock_db_session, mock_query_results):
    """创建带模拟数据的计算器"""
    calculator = SimilarityCalculator(mock_db_session, cache_ttl_seconds=5)
    
    # 模拟数据库查询
    async def mock_execute(query, params):
        result = MagicMock()
        result.fetchall.return_value = mock_query_results
        return result
    
    mock_db_session.execute = mock_execute
    
    return calculator


# ==================== 初始化和配置测试 ====================

@pytest.mark.asyncio
async def test_initialization_with_defaults():
    """测试默认初始化"""
    session = AsyncMock(spec=AsyncSession)
    calculator = SimilarityCalculator(session)
    
    assert calculator.db == session
    assert calculator.weights == DEFAULT_WEIGHTS
    assert len(calculator._cache) == 0


@pytest.mark.asyncio
async def test_initialization_with_custom_weights():
    """测试自定义权重初始化"""
    session = AsyncMock(spec=AsyncSession)
    custom_weights = {
        'name': 0.5,
        'description': 0.3,
        'attributes': 0.1,
        'category': 0.1
    }
    calculator = SimilarityCalculator(session, weights=custom_weights)
    
    assert calculator.weights == custom_weights


@pytest.mark.asyncio
async def test_invalid_weights_missing_keys():
    """测试无效权重（缺少键）"""
    session = AsyncMock(spec=AsyncSession)
    invalid_weights = {
        'name': 0.5,
        'description': 0.5
        # 缺少 attributes 和 category
    }
    
    with pytest.raises(ValueError, match="Missing required weight keys"):
        SimilarityCalculator(session, weights=invalid_weights)


@pytest.mark.asyncio
async def test_invalid_weights_out_of_range():
    """测试无效权重（超出范围）"""
    session = AsyncMock(spec=AsyncSession)
    invalid_weights = {
        'name': 1.5,  # 超出[0, 1]范围
        'description': -0.3,
        'attributes': 0.2,
        'category': 0.1
    }
    
    with pytest.raises(ValueError, match="must be in"):
        SimilarityCalculator(session, weights=invalid_weights)


@pytest.mark.asyncio
async def test_invalid_weights_sum():
    """测试无效权重（总和不为1）"""
    session = AsyncMock(spec=AsyncSession)
    invalid_weights = {
        'name': 0.3,
        'description': 0.3,
        'attributes': 0.3,
        'category': 0.3  # 总和1.2
    }
    
    with pytest.raises(ValueError, match="must sum to 1.0"):
        SimilarityCalculator(session, weights=invalid_weights)


# ==================== 权重管理测试 ====================

@pytest.mark.asyncio
async def test_update_weights():
    """测试更新权重"""
    session = AsyncMock(spec=AsyncSession)
    calculator = SimilarityCalculator(session)
    
    new_weights = {
        'name': 0.5,
        'description': 0.2,
        'attributes': 0.2,
        'category': 0.1
    }
    
    calculator.update_weights(new_weights)
    assert calculator.weights == new_weights


@pytest.mark.asyncio
async def test_update_weights_clears_cache():
    """测试更新权重时清空缓存"""
    session = AsyncMock(spec=AsyncSession)
    calculator = SimilarityCalculator(session)
    
    # 添加缓存项
    calculator._cache['test_key'] = ['test_value']
    assert len(calculator._cache) == 1
    
    # 更新权重
    new_weights = {
        'name': 0.5,
        'description': 0.2,
        'attributes': 0.2,
        'category': 0.1
    }
    calculator.update_weights(new_weights)
    
    # 缓存应该被清空
    assert len(calculator._cache) == 0


@pytest.mark.asyncio
async def test_update_weights_invalid_rollback():
    """测试无效权重更新时回滚"""
    session = AsyncMock(spec=AsyncSession)
    calculator = SimilarityCalculator(session)
    
    old_weights = calculator.weights.copy()
    
    invalid_weights = {
        'name': 0.5,
        'description': 0.5,
        'attributes': 0.5,
        'category': 0.5  # 总和2.0，无效
    }
    
    with pytest.raises(ValueError):
        calculator.update_weights(invalid_weights)
    
    # 权重应该保持不变
    assert calculator.weights == old_weights


@pytest.mark.asyncio
async def test_get_weights():
    """测试获取权重"""
    session = AsyncMock(spec=AsyncSession)
    custom_weights = {
        'name': 0.5,
        'description': 0.3,
        'attributes': 0.1,
        'category': 0.1
    }
    calculator = SimilarityCalculator(session, weights=custom_weights)
    
    weights = calculator.get_weights()
    assert weights == custom_weights
    
    # 确保返回的是副本（不是引用）
    weights['name'] = 0.9
    assert calculator.weights['name'] == 0.5


# ==================== 核心查询功能测试 ====================

@pytest.mark.asyncio
async def test_find_similar_materials(calculator_with_mock_data, sample_parsed_query):
    """测试基本相似度搜索"""
    results = await calculator_with_mock_data.find_similar_materials(
        sample_parsed_query,
        limit=10,
        min_similarity=0.1
    )
    
    assert isinstance(results, list)
    assert len(results) == 2
    assert all(isinstance(r, MaterialResult) for r in results)
    
    # 验证第一个结果
    assert results[0].erp_code == "MAT001"
    assert results[0].similarity_score == 0.92
    assert results[0].similarity_breakdown['name_similarity'] == 0.95


@pytest.mark.asyncio
async def test_find_similar_empty_results(mock_db_session, sample_parsed_query):
    """测试空结果"""
    calculator = SimilarityCalculator(mock_db_session)
    
    # 模拟空结果
    async def mock_execute(query, params):
        result = MagicMock()
        result.fetchall.return_value = []
        return result
    
    mock_db_session.execute = mock_execute
    
    results = await calculator.find_similar_materials(
        sample_parsed_query,
        limit=10
    )
    
    assert results == []


@pytest.mark.asyncio
async def test_find_similar_with_attributes(calculator_with_mock_data):
    """测试带属性的查询"""
    query = ParsedQuery(
        standardized_name="螺栓",
        attributes={"规格": "M10*30", "材质": "316"},
        detected_category="螺栓螺钉",
        confidence=0.9,
        full_description="螺栓 M10*30 316",
        processing_steps=[]
    )
    
    results = await calculator_with_mock_data.find_similar_materials(query)
    
    assert isinstance(results, list)
    assert len(results) > 0


@pytest.mark.asyncio
async def test_find_similar_with_no_attributes(calculator_with_mock_data):
    """测试无属性查询"""
    query = ParsedQuery(
        standardized_name="螺栓",
        attributes={},  # 无属性
        detected_category="general",
        confidence=0.5,
        full_description="螺栓",
        processing_steps=[]
    )
    
    results = await calculator_with_mock_data.find_similar_materials(query)
    
    assert isinstance(results, list)


# ==================== 缓存机制测试 ====================

@pytest.mark.asyncio
async def test_cache_hit(calculator_with_mock_data, sample_parsed_query):
    """测试缓存命中"""
    # 第一次查询 - 缓存未命中
    results1 = await calculator_with_mock_data.find_similar_materials(
        sample_parsed_query
    )
    assert calculator_with_mock_data._cache_misses == 1
    assert calculator_with_mock_data._cache_hits == 0
    
    # 第二次查询 - 缓存命中
    results2 = await calculator_with_mock_data.find_similar_materials(
        sample_parsed_query
    )
    assert calculator_with_mock_data._cache_misses == 1
    assert calculator_with_mock_data._cache_hits == 1
    
    # 结果应该相同
    assert len(results1) == len(results2)


@pytest.mark.asyncio
async def test_cache_miss_different_query(calculator_with_mock_data):
    """测试不同查询缓存未命中"""
    query1 = ParsedQuery(
        standardized_name="螺栓1",
        attributes={},
        detected_category="螺栓螺钉",
        confidence=0.9,
        full_description="螺栓1",
        processing_steps=[]
    )
    
    query2 = ParsedQuery(
        standardized_name="螺栓2",
        attributes={},
        detected_category="螺栓螺钉",
        confidence=0.9,
        full_description="螺栓2",
        processing_steps=[]
    )
    
    await calculator_with_mock_data.find_similar_materials(query1)
    await calculator_with_mock_data.find_similar_materials(query2)
    
    # 两次都应该是缓存未命中
    assert calculator_with_mock_data._cache_misses == 2
    assert calculator_with_mock_data._cache_hits == 0


@pytest.mark.asyncio
async def test_get_cache_stats(calculator_with_mock_data, sample_parsed_query):
    """测试获取缓存统计"""
    await calculator_with_mock_data.find_similar_materials(sample_parsed_query)
    await calculator_with_mock_data.find_similar_materials(sample_parsed_query)
    
    stats = calculator_with_mock_data.get_cache_stats()
    
    assert stats['cache_hits'] == 1
    assert stats['cache_misses'] == 1
    assert stats['hit_rate'] == 0.5
    assert stats['cache_size'] >= 0


@pytest.mark.asyncio
async def test_clear_cache(calculator_with_mock_data, sample_parsed_query):
    """测试清空缓存"""
    await calculator_with_mock_data.find_similar_materials(sample_parsed_query)
    assert len(calculator_with_mock_data._cache) > 0
    
    await calculator_with_mock_data.clear_cache()
    
    assert len(calculator_with_mock_data._cache) == 0
    assert calculator_with_mock_data._cache_hits == 0
    assert calculator_with_mock_data._cache_misses == 0


# ==================== 批量查询测试 ====================

@pytest.mark.asyncio
async def test_batch_find_similar(calculator_with_mock_data):
    """测试批量查询"""
    queries = [
        ParsedQuery(
            standardized_name=f"螺栓{i}",
            attributes={},
            detected_category="螺栓螺钉",
            confidence=0.9,
            full_description=f"螺栓{i}",
            processing_steps=[]
        )
        for i in range(3)
    ]
    
    results = await calculator_with_mock_data.batch_find_similar(queries)
    
    assert len(results) == 3
    assert all(isinstance(r, list) for r in results)


@pytest.mark.asyncio
async def test_batch_find_similar_empty():
    """测试空批量查询"""
    session = AsyncMock(spec=AsyncSession)
    calculator = SimilarityCalculator(session)
    
    results = await calculator.batch_find_similar([])
    
    assert results == []


# ==================== SQL构建测试 ====================

@pytest.mark.asyncio
async def test_build_similarity_query(mock_db_session, sample_parsed_query):
    """测试SQL查询构建"""
    calculator = SimilarityCalculator(mock_db_session)
    
    sql = calculator._build_similarity_query(
        sample_parsed_query,
        limit=10,
        min_similarity=0.1
    )
    
    # 验证SQL包含关键元素
    assert "similarity" in sql.lower()
    assert "normalized_name" in sql
    assert "full_description" in sql
    assert "attributes" in sql
    assert "detected_category" in sql
    assert "LIMIT" in sql.upper()


@pytest.mark.asyncio
async def test_build_attribute_similarity_sql(mock_db_session):
    """测试属性相似度SQL构建"""
    calculator = SimilarityCalculator(mock_db_session)
    
    # 有属性的查询
    query_with_attrs = ParsedQuery(
        standardized_name="测试",
        attributes={"规格": "M8", "材质": "304"},
        detected_category="general",
        confidence=0.8,
        full_description="测试",
        processing_steps=[]
    )
    
    sql = calculator._build_attribute_similarity_sql(query_with_attrs)
    assert "CASE" in sql
    assert "attributes" in sql
    
    # 无属性的查询
    query_no_attrs = ParsedQuery(
        standardized_name="测试",
        attributes={},
        detected_category="general",
        confidence=0.8,
        full_description="测试",
        processing_steps=[]
    )
    
    sql_empty = calculator._build_attribute_similarity_sql(query_no_attrs)
    assert sql_empty == "0.0"


@pytest.mark.asyncio
async def test_prepare_query_params(mock_db_session, sample_parsed_query):
    """测试查询参数准备"""
    calculator = SimilarityCalculator(mock_db_session)
    
    params = calculator._prepare_query_params(
        sample_parsed_query,
        limit=10,
        min_similarity=0.1
    )
    
    assert params['query_name'] == sample_parsed_query.standardized_name
    assert params['query_desc'] == sample_parsed_query.full_description
    assert params['query_category'] == sample_parsed_query.detected_category
    assert params['limit'] == 10
    assert params['min_similarity'] == 0.1
    
    # 验证属性参数
    assert 'query_attrs_规格' in params
    assert 'query_attrs_材质' in params


# ==================== 结果解析测试 ====================

@pytest.mark.asyncio
async def test_parse_result_row(mock_db_session, sample_parsed_query, mock_query_results):
    """测试结果行解析"""
    calculator = SimilarityCalculator(mock_db_session)
    
    row = mock_query_results[0]
    material = calculator._parse_result_row(row, sample_parsed_query)
    
    assert isinstance(material, MaterialResult)
    assert material.erp_code == "MAT001"
    assert material.similarity_score == 0.92
    assert 'name_similarity' in material.similarity_breakdown
    assert 'description_similarity' in material.similarity_breakdown
    assert 'attributes_similarity' in material.similarity_breakdown
    assert 'category_similarity' in material.similarity_breakdown


# ==================== 错误处理测试 ====================

@pytest.mark.asyncio
async def test_find_similar_database_error(mock_db_session, sample_parsed_query):
    """测试数据库错误处理"""
    calculator = SimilarityCalculator(mock_db_session)
    
    # 模拟数据库错误
    async def mock_execute_error(query, params):
        raise Exception("Database connection error")
    
    mock_db_session.execute = mock_execute_error
    
    with pytest.raises(RuntimeError, match="Failed to find similar materials"):
        await calculator.find_similar_materials(sample_parsed_query)


# ==================== 性能测试 ====================

@pytest.mark.asyncio
async def test_cache_key_generation_performance(mock_db_session):
    """测试缓存键生成性能"""
    import time
    
    calculator = SimilarityCalculator(mock_db_session)
    
    query = ParsedQuery(
        standardized_name="测试物料",
        attributes={"attr1": "value1", "attr2": "value2"},
        detected_category="general",
        confidence=0.8,
        full_description="测试物料描述",
        processing_steps=[]
    )
    
    start = time.time()
    for _ in range(1000):
        calculator._generate_cache_key(query, 10, 0.1)
    duration = time.time() - start
    
    # 生成1000个缓存键应该很快（<100ms）
    assert duration < 0.1


# ==================== 表示测试 ====================

@pytest.mark.asyncio
async def test_repr(mock_db_session):
    """测试字符串表示"""
    calculator = SimilarityCalculator(mock_db_session)
    
    repr_str = repr(calculator)
    
    assert "SimilarityCalculator" in repr_str
    assert "weights" in repr_str
    assert "cache_size" in repr_str

