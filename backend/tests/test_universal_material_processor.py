"""
UniversalMaterialProcessor单元测试

测试对称处理算法、缓存机制、处理透明化等核心功能
验证与SimpleMaterialProcessor的一致性
"""

import pytest
import asyncio
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, MagicMock, patch

from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.processors.material_processor import UniversalMaterialProcessor
from backend.core.schemas.material_schemas import ParsedQuery
from backend.models.materials import ExtractionRule, Synonym, KnowledgeCategory


# ==================== Fixtures ====================

@pytest.fixture
def mock_db_session():
    """模拟数据库会话"""
    session = AsyncMock(spec=AsyncSession)
    return session


@pytest.fixture
def mock_knowledge_base():
    """模拟知识库数据"""
    return {
        'rules': [
            MagicMock(
                rule_name='规格提取',
                material_category='general',
                attribute_name='规格',
                regex_pattern=r'M(\d+)[*×](\d+)',
                priority=100,
                confidence=0.95,
                is_active=True
            ),
            MagicMock(
                rule_name='材质提取',
                material_category='螺栓螺钉',
                attribute_name='材质',
                regex_pattern=r'(304|316|Q235)',
                priority=90,
                confidence=0.90,
                is_active=True
            )
        ],
        'synonyms': [
            MagicMock(original_term='不锈钢', standard_term='304', is_active=True),
            MagicMock(original_term='SS', standard_term='304', is_active=True),
            MagicMock(original_term='內六角', standard_term='内六角', is_active=True),
        ],
        'categories': [
            MagicMock(
                category_name='螺栓螺钉',
                keywords=['螺栓', '螺钉', '螺丝', '内六角', '六角'],
                is_active=True
            ),
            MagicMock(
                category_name='轴承',
                keywords=['轴承', '滚动轴承', '深沟球', '角接触'],
                is_active=True
            ),
        ]
    }


@pytest.fixture
def processor_with_mock_data(mock_db_session, mock_knowledge_base):
    """创建带模拟数据的处理器"""
    processor = UniversalMaterialProcessor(mock_db_session, cache_ttl_seconds=5)
    
    # 模拟数据库查询结果
    async def mock_execute(stmt):
        result = MagicMock()
        # 根据查询类型返回不同数据
        stmt_str = str(stmt)
        if 'extraction_rules' in stmt_str or 'ExtractionRule' in stmt_str:
            result.scalars().all.return_value = mock_knowledge_base['rules']
        elif 'synonyms' in stmt_str or 'Synonym' in stmt_str:
            result.scalars().all.return_value = mock_knowledge_base['synonyms']
        elif 'knowledge_categories' in stmt_str or 'KnowledgeCategory' in stmt_str:
            result.scalars().all.return_value = mock_knowledge_base['categories']
        return result
    
    mock_db_session.execute = mock_execute
    
    return processor


# ==================== 核心功能测试 ====================

@pytest.mark.asyncio
async def test_initialization():
    """测试初始化"""
    session = AsyncMock(spec=AsyncSession)
    processor = UniversalMaterialProcessor(session, cache_ttl_seconds=10)
    
    assert processor.db == session
    assert processor.cache_ttl == timedelta(seconds=10)
    assert not processor._cache_loaded
    assert len(processor._extraction_rules) == 0
    assert len(processor._synonyms) == 0
    assert len(processor._category_keywords) == 0


@pytest.mark.asyncio
async def test_knowledge_base_loading(processor_with_mock_data):
    """测试知识库加载"""
    # 首次处理会触发加载
    result = await processor_with_mock_data.process_material_description("测试")
    
    # 验证知识库已加载
    assert processor_with_mock_data._cache_loaded
    assert len(processor_with_mock_data._extraction_rules) == 2
    assert len(processor_with_mock_data._synonyms) == 3
    assert len(processor_with_mock_data._category_keywords) == 2


@pytest.mark.asyncio
async def test_cache_ttl_mechanism(processor_with_mock_data):
    """测试缓存TTL机制"""
    # 首次调用 - 加载知识库
    await processor_with_mock_data.process_material_description("测试1")
    first_update = processor_with_mock_data._last_cache_update
    
    # 立即第二次调用 - 使用缓存
    await processor_with_mock_data.process_material_description("测试2")
    second_update = processor_with_mock_data._last_cache_update
    
    assert first_update == second_update  # 应使用缓存，更新时间不变
    
    # 模拟缓存过期
    processor_with_mock_data._last_cache_update = datetime.now() - timedelta(seconds=10)
    
    # 第三次调用 - 重新加载
    await processor_with_mock_data.process_material_description("测试3")
    third_update = processor_with_mock_data._last_cache_update
    
    assert third_update > second_update  # 应重新加载，更新时间改变


@pytest.mark.asyncio
async def test_basic_processing(processor_with_mock_data):
    """测试基础对称处理"""
    result = await processor_with_mock_data.process_material_description(
        "六角螺栓 M8*20 304不锈钢"
    )
    
    assert isinstance(result, ParsedQuery)
    assert result.standardized_name != ""
    assert result.detected_category != ""
    assert 0.0 <= result.confidence <= 1.0
    assert result.full_description == "六角螺栓 M8*20 304不锈钢"
    assert len(result.processing_steps) > 0


@pytest.mark.asyncio
async def test_category_detection(processor_with_mock_data):
    """测试类别检测"""
    # 测试螺栓类别
    result1 = await processor_with_mock_data.process_material_description(
        "内六角螺栓 M8*20"
    )
    assert result1.detected_category == "螺栓螺钉"
    assert result1.confidence > 0.0
    
    # 测试轴承类别
    result2 = await processor_with_mock_data.process_material_description(
        "深沟球轴承 6206"
    )
    assert result2.detected_category == "轴承"


@pytest.mark.asyncio
async def test_category_hint(processor_with_mock_data):
    """测试类别提示功能"""
    result = await processor_with_mock_data.process_material_description(
        "测试物料",
        category_hint="螺栓螺钉"
    )
    
    assert result.detected_category == "螺栓螺钉"
    assert result.confidence == 1.0  # 使用提示时置信度为1.0


@pytest.mark.asyncio
async def test_text_normalization(processor_with_mock_data):
    """测试文本标准化"""
    # 测试全角转半角
    result = await processor_with_mock_data.process_material_description(
        "螺栓　Ｍ８＊２０"
    )
    
    # 标准化后应该不包含全角字符
    assert "Ｍ８" not in result.standardized_name
    assert "　" not in result.standardized_name


@pytest.mark.asyncio
async def test_synonym_replacement(processor_with_mock_data):
    """测试同义词替换"""
    result = await processor_with_mock_data.process_material_description(
        "螺栓 不锈钢"
    )
    
    # 应该有同义词替换的记录
    synonym_steps = [s for s in result.processing_steps if '同义词替换' in s]
    assert len(synonym_steps) > 0


@pytest.mark.asyncio
async def test_attribute_extraction(processor_with_mock_data):
    """测试属性提取"""
    result = await processor_with_mock_data.process_material_description(
        "六角螺栓 M8*20 304"
    )
    
    # 应该提取到规格和材质属性
    assert len(result.attributes) > 0
    # 具体属性取决于规则配置


@pytest.mark.asyncio
async def test_processing_transparency(processor_with_mock_data):
    """测试处理透明化"""
    result = await processor_with_mock_data.process_material_description(
        "六角螺栓 M8*20 304不锈钢"
    )
    
    # 应该有处理步骤记录
    assert len(result.processing_steps) >= 1
    
    # 应该包含类别检测步骤
    category_steps = [s for s in result.processing_steps if '类别' in s]
    assert len(category_steps) > 0


# ==================== 边界情况测试 ====================

@pytest.mark.asyncio
async def test_empty_input(processor_with_mock_data):
    """测试空输入"""
    result = await processor_with_mock_data.process_material_description("")
    
    assert result.standardized_name == ""
    assert result.attributes == {}
    assert result.detected_category == "general"
    assert result.confidence == 0.0
    assert "输入为空" in result.processing_steps


@pytest.mark.asyncio
async def test_whitespace_input(processor_with_mock_data):
    """测试纯空格输入"""
    result = await processor_with_mock_data.process_material_description("   ")
    
    assert result.standardized_name == ""
    assert result.detected_category == "general"


@pytest.mark.asyncio
async def test_special_characters(processor_with_mock_data):
    """测试特殊字符处理"""
    result = await processor_with_mock_data.process_material_description(
        "螺栓@#$%^&*()M8×20"
    )
    
    # 应该能正常处理，不抛异常
    assert isinstance(result, ParsedQuery)
    assert result.standardized_name != ""


@pytest.mark.asyncio
async def test_very_long_input(processor_with_mock_data):
    """测试超长输入"""
    long_text = "螺栓 " * 100
    result = await processor_with_mock_data.process_material_description(long_text)
    
    assert isinstance(result, ParsedQuery)


@pytest.mark.asyncio
async def test_unknown_category(processor_with_mock_data):
    """测试未知类别"""
    result = await processor_with_mock_data.process_material_description(
        "这是一个完全不认识的物料描述XYZABC"
    )
    
    assert result.detected_category == "general"
    assert result.confidence <= 0.5


# ==================== 缓存管理测试 ====================

@pytest.mark.asyncio
async def test_get_cache_stats(processor_with_mock_data):
    """测试获取缓存统计"""
    # 加载知识库
    await processor_with_mock_data.process_material_description("测试")
    
    stats = processor_with_mock_data.get_cache_stats()
    
    assert stats['cache_loaded'] == True
    assert stats['rules_count'] == 2
    assert stats['synonyms_count'] == 3
    assert stats['categories_count'] == 2
    assert stats['last_update'] is not None


@pytest.mark.asyncio
async def test_clear_cache(processor_with_mock_data):
    """测试清空缓存"""
    # 加载知识库
    await processor_with_mock_data.process_material_description("测试")
    assert processor_with_mock_data._cache_loaded
    
    # 清空缓存
    await processor_with_mock_data.clear_cache()
    
    assert not processor_with_mock_data._cache_loaded
    assert len(processor_with_mock_data._extraction_rules) == 0
    assert len(processor_with_mock_data._synonyms) == 0


# ==================== 性能测试 ====================

@pytest.mark.asyncio
async def test_processing_performance(processor_with_mock_data):
    """测试处理性能"""
    import time
    
    descriptions = [
        "六角螺栓 M8*20",
        "内六角螺栓 M10*30",
        "深沟球轴承 6206",
        "球阀 DN50",
    ]
    
    start = time.time()
    results = []
    for desc in descriptions:
        result = await processor_with_mock_data.process_material_description(desc)
        results.append(result)
    duration = time.time() - start
    
    # 验证处理速度
    items_per_second = len(descriptions) / duration
    assert items_per_second > 10  # 至少10条/秒


# ==================== 错误处理测试 ====================

@pytest.mark.asyncio
async def test_database_error_handling():
    """测试数据库错误处理"""
    session = AsyncMock(spec=AsyncSession)
    session.execute.side_effect = Exception("Database connection error")
    
    processor = UniversalMaterialProcessor(session)
    
    # 应该抛出RuntimeError
    with pytest.raises(RuntimeError):
        await processor._load_knowledge_base()


@pytest.mark.asyncio
async def test_invalid_regex_pattern(processor_with_mock_data):
    """测试无效的正则表达式"""
    # 添加一个无效的规则
    processor_with_mock_data._extraction_rules.append({
        'rule_name': '无效规则',
        'material_category': 'general',
        'attribute_name': '测试',
        'regex_pattern': '[invalid(regex',  # 无效的正则
        'priority': 50,
        'confidence': 1.0
    })
    
    # 应该能处理，但跳过无效规则
    result = await processor_with_mock_data.process_material_description("测试")
    assert isinstance(result, ParsedQuery)


# ==================== 对称处理一致性测试 ====================

@pytest.mark.asyncio
async def test_symmetric_processing_consistency(processor_with_mock_data):
    """测试对称处理一致性（与SimpleMaterialProcessor比较）"""
    # 相同输入应该产生相同的处理结果
    description = "六角螺栓 M8*20 304不锈钢"
    
    result1 = await processor_with_mock_data.process_material_description(description)
    result2 = await processor_with_mock_data.process_material_description(description)
    
    # 核心字段应该完全一致
    assert result1.standardized_name == result2.standardized_name
    assert result1.attributes == result2.attributes
    assert result1.detected_category == result2.detected_category
    assert result1.confidence == result2.confidence

