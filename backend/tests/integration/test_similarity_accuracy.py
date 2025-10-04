"""
Task 2.2 Phase 8: 相似度计算器准确率验证

测试目标:
1. Top-10准确率 ≥ 90%
2. 不同类别的准确率分析
3. 权重敏感性分析

需要: 真实PostgreSQL连接，测试数据集
"""

import pytest
import asyncio
from typing import List, Dict, Tuple
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from sqlalchemy import text

from backend.core.config import database_config
from backend.core.calculators.similarity_calculator import SimilarityCalculator
from backend.core.processors.material_processor import UniversalMaterialProcessor
from backend.core.schemas.material_schemas import ParsedQuery, MaterialResult


# ==================== Fixtures ====================

@pytest.fixture(scope="module")
def event_loop():
    """创建事件循环"""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="module")
async def db_engine():
    """创建数据库引擎"""
    engine = create_async_engine(
        database_config.database_url,
        echo=False,
        pool_size=10,
        max_overflow=20,
        pool_pre_ping=True
    )
    yield engine
    await engine.dispose()


@pytest.fixture
async def db_session(db_engine):
    """创建数据库会话"""
    async_session = sessionmaker(
        db_engine, 
        class_=AsyncSession, 
        expire_on_commit=False
    )
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


# ==================== 测试用例生成 ====================

async def generate_test_cases(db_session, limit: int = 50) -> List[Tuple[str, str]]:
    """
    从数据库中生成测试用例
    
    策略:
    1. 随机抽取真实物料记录
    2. 使用其标准化描述作为查询
    3. 期望结果应包含该物料本身（erp_code匹配）
    
    Returns:
        List[(query_text, expected_erp_code)]
    """
    sql = """
    SELECT 
        erp_code,
        material_name,
        specification,
        model,
        full_description
    FROM materials_master
    WHERE 
        enable_state = 2
        AND full_description IS NOT NULL
        AND LENGTH(full_description) > 10
    ORDER BY RANDOM()
    LIMIT :limit;
    """
    
    result = await db_session.execute(text(sql), {'limit': limit})
    rows = result.fetchall()
    
    test_cases = []
    for row in rows:
        # 构建查询文本（使用完整描述或组合字段）
        if row.full_description:
            query_text = row.full_description
        else:
            parts = [p for p in [row.material_name, row.specification, row.model] if p]
            query_text = ' '.join(parts)
        
        test_cases.append((query_text, row.erp_code))
    
    return test_cases


# ==================== Phase 8.1: Top-K准确率测试 ====================

@pytest.mark.asyncio
@pytest.mark.integration
async def test_top_k_accuracy(db_session):
    """
    测试Top-K准确率
    
    验收标准:
    - Top-1准确率（最相似的就是自己）
    - Top-3准确率
    - Top-10准确率 ≥ 90%
    """
    calculator = SimilarityCalculator(db_session, cache_ttl_seconds=60)
    processor = UniversalMaterialProcessor(db_session, cache_ttl_seconds=5)
    
    # 生成测试用例
    test_cases = await generate_test_cases(db_session, limit=30)
    
    print(f"\n生成{len(test_cases)}个测试用例")
    
    # 测试各个Top-K
    top_1_correct = 0
    top_3_correct = 0
    top_10_correct = 0
    
    for i, (query_text, expected_erp_code) in enumerate(test_cases, 1):
        # 处理查询
        parsed_query = await processor.process_material_description(query_text)
        
        # 查找相似物料
        results = await calculator.find_similar_materials(parsed_query, limit=10)
        
        if not results:
            print(f"  [{i}] 查询无结果: {query_text[:50]}...")
            continue
        
        # 提取结果的ERP编码
        result_erp_codes = [r.erp_code for r in results]
        
        # 检查Top-K命中
        if expected_erp_code in result_erp_codes[:1]:
            top_1_correct += 1
        if expected_erp_code in result_erp_codes[:3]:
            top_3_correct += 1
        if expected_erp_code in result_erp_codes[:10]:
            top_10_correct += 1
        
        # 打印部分结果
        if i <= 5:
            is_top1 = expected_erp_code == result_erp_codes[0]
            print(f"  [{i}] {'✅' if is_top1 else '❌'} 查询: {query_text[:50]}...")
            print(f"       期望: {expected_erp_code}, 结果Top1: {result_erp_codes[0]}")
    
    # 计算准确率
    total = len(test_cases)
    top_1_acc = top_1_correct / total if total > 0 else 0
    top_3_acc = top_3_correct / total if total > 0 else 0
    top_10_acc = top_10_correct / total if total > 0 else 0
    
    print(f"\n准确率统计:")
    print(f"  Top-1准确率: {top_1_acc*100:.1f}% ({top_1_correct}/{total})")
    print(f"  Top-3准确率: {top_3_acc*100:.1f}% ({top_3_correct}/{total})")
    print(f"  Top-10准确率: {top_10_acc*100:.1f}% ({top_10_correct}/{total})")
    
    # 验收标准：Top-1应该很高（自己查自己）
    assert top_1_acc >= 0.80, f"Top-1准确率{top_1_acc*100:.1f}%应该≥80%"
    assert top_10_acc >= 0.90, f"Top-10准确率{top_10_acc*100:.1f}%应该≥90%"
    
    print(f"\n✅ 准确率验证通过")


@pytest.mark.asyncio
@pytest.mark.integration
async def test_category_specific_accuracy(db_session):
    """
    测试不同类别的准确率
    
    目标: 验证算法对不同物料类别的适用性
    """
    calculator = SimilarityCalculator(db_session, cache_ttl_seconds=60)
    processor = UniversalMaterialProcessor(db_session, cache_ttl_seconds=5)
    
    # 查询各类别的样本数量
    sql = """
    SELECT 
        detected_category,
        COUNT(*) as count
    FROM materials_master
    WHERE 
        enable_state = 2
        AND detected_category IS NOT NULL
    GROUP BY detected_category
    ORDER BY count DESC
    LIMIT 5;
    """
    
    result = await db_session.execute(text(sql))
    categories = result.fetchall()
    
    print(f"\n测试{len(categories)}个主要类别:")
    
    category_results = {}
    
    for cat_row in categories:
        category = cat_row.detected_category
        count = cat_row.count
        
        # 从该类别抽取测试样本
        sql_samples = """
        SELECT 
            erp_code,
            full_description
        FROM materials_master
        WHERE 
            enable_state = 2
            AND detected_category = :category
            AND full_description IS NOT NULL
        ORDER BY RANDOM()
        LIMIT 10;
        """
        
        result = await db_session.execute(text(sql_samples), {'category': category})
        samples = result.fetchall()
        
        if not samples:
            continue
        
        # 测试该类别样本
        correct = 0
        for sample in samples:
            parsed_query = await processor.process_material_description(sample.full_description)
            results = await calculator.find_similar_materials(parsed_query, limit=10)
            
            result_erp_codes = [r.erp_code for r in results]
            if sample.erp_code in result_erp_codes[:10]:
                correct += 1
        
        accuracy = correct / len(samples) if samples else 0
        category_results[category] = {
            'accuracy': accuracy,
            'tested': len(samples),
            'total_count': count
        }
        
        print(f"  {category}: {accuracy*100:.1f}% ({correct}/{len(samples)}) [总数:{count}]")
    
    print(f"\n✅ 类别准确率分析完成")


# ==================== Phase 8.2: 权重敏感性分析 ====================

@pytest.mark.asyncio
@pytest.mark.integration
async def test_weight_sensitivity_analysis(db_session):
    """
    权重敏感性分析
    
    测试不同权重配置对准确率的影响
    """
    processor = UniversalMaterialProcessor(db_session, cache_ttl_seconds=5)
    
    # 生成测试用例
    test_cases = await generate_test_cases(db_session, limit=20)
    
    # 不同权重配置
    weight_configs = [
        {'name': 0.4, 'description': 0.3, 'attributes': 0.2, 'category': 0.1},  # 当前默认
        {'name': 0.5, 'description': 0.3, 'attributes': 0.1, 'category': 0.1},  # 更重视名称
        {'name': 0.3, 'description': 0.4, 'attributes': 0.2, 'category': 0.1},  # 更重视描述
        {'name': 0.3, 'description': 0.2, 'attributes': 0.4, 'category': 0.1},  # 更重视属性
    ]
    
    print(f"\n测试{len(weight_configs)}种权重配置:")
    
    results = {}
    
    for idx, weights in enumerate(weight_configs, 1):
        calculator = SimilarityCalculator(db_session, weights=weights, cache_ttl_seconds=60)
        
        top_10_correct = 0
        
        for query_text, expected_erp_code in test_cases:
            parsed_query = await processor.process_material_description(query_text)
            similar = await calculator.find_similar_materials(parsed_query, limit=10)
            
            result_erp_codes = [r.erp_code for r in similar]
            if expected_erp_code in result_erp_codes[:10]:
                top_10_correct += 1
        
        accuracy = top_10_correct / len(test_cases) if test_cases else 0
        
        config_name = f"配置{idx}"
        results[config_name] = {
            'weights': weights,
            'accuracy': accuracy,
            'correct': top_10_correct,
            'total': len(test_cases)
        }
        
        print(f"  {config_name}: {accuracy*100:.1f}% - 权重{weights}")
    
    # 找出最佳配置
    best_config = max(results.items(), key=lambda x: x[1]['accuracy'])
    print(f"\n最佳配置: {best_config[0]} ({best_config[1]['accuracy']*100:.1f}%)")
    
    print(f"\n✅ 权重敏感性分析完成")


# ==================== Phase 8.3: 边界情况测试 ====================

@pytest.mark.asyncio
@pytest.mark.integration
async def test_edge_cases(db_session):
    """
    测试边界情况和异常查询
    """
    calculator = SimilarityCalculator(db_session, cache_ttl_seconds=60)
    processor = UniversalMaterialProcessor(db_session, cache_ttl_seconds=5)
    
    edge_cases = [
        ("螺栓", "极短查询"),
        ("M8螺栓 304不锈钢 六角头 半牙 国标 A级", "极长查询"),
        ("螺栓 螺栓 螺栓 螺栓", "重复词查询"),
        ("ABCXYZ123", "无意义字符"),
        ("球阀DN50", "无空格紧凑"),
    ]
    
    print(f"\n测试{len(edge_cases)}种边界情况:")
    
    for query_text, case_name in edge_cases:
        try:
            parsed_query = await processor.process_material_description(query_text)
            results = await calculator.find_similar_materials(parsed_query, limit=5)
            
            print(f"  ✅ {case_name}: 返回{len(results)}个结果")
            
            if results and len(results) > 0:
                top_result = results[0]
                print(f"     Top-1: {top_result.material_name[:30]}... (相似度:{top_result.similarity_score:.2f})")
        
        except Exception as e:
            print(f"  ❌ {case_name}: 异常 - {str(e)}")
            raise
    
    print(f"\n✅ 边界情况测试完成")


# ==================== 准确率测试报告生成 ====================

@pytest.mark.asyncio
@pytest.mark.integration
async def test_generate_accuracy_report(db_session):
    """
    生成完整的准确率测试报告
    """
    calculator = SimilarityCalculator(db_session, cache_ttl_seconds=60)
    processor = UniversalMaterialProcessor(db_session, cache_ttl_seconds=5)
    
    # 生成更多测试用例
    test_cases = await generate_test_cases(db_session, limit=100)
    
    print(f"\n" + "="*60)
    print("Phase 8 准确率验证报告")
    print("="*60)
    print(f"测试用例数: {len(test_cases)}")
    
    # 统计结果
    top_1_correct = 0
    top_3_correct = 0
    top_10_correct = 0
    no_results = 0
    
    for query_text, expected_erp_code in test_cases:
        parsed_query = await processor.process_material_description(query_text)
        results = await calculator.find_similar_materials(parsed_query, limit=10)
        
        if not results:
            no_results += 1
            continue
        
        result_erp_codes = [r.erp_code for r in results]
        
        if expected_erp_code in result_erp_codes[:1]:
            top_1_correct += 1
        if expected_erp_code in result_erp_codes[:3]:
            top_3_correct += 1
        if expected_erp_code in result_erp_codes[:10]:
            top_10_correct += 1
    
    total_valid = len(test_cases) - no_results
    
    print(f"\n准确率统计:")
    print(f"  Top-1准确率: {top_1_correct/total_valid*100:.1f}% ({top_1_correct}/{total_valid})")
    print(f"  Top-3准确率: {top_3_correct/total_valid*100:.1f}% ({top_3_correct}/{total_valid})")
    print(f"  Top-10准确率: {top_10_correct/total_valid*100:.1f}% ({top_10_correct}/{total_valid})")
    print(f"  无结果查询: {no_results}")
    
    # 缓存统计
    cache_stats = calculator.get_cache_stats()
    print(f"\n缓存统计:")
    print(f"  缓存命中率: {cache_stats['hit_rate']*100:.1f}%")
    print(f"  缓存大小: {cache_stats['cache_size']}/{cache_stats['cache_max_size']}")
    
    # 验收结论
    top_10_acc = top_10_correct / total_valid if total_valid > 0 else 0
    
    print(f"\n验收结论:")
    print(f"  Top-10准确率 ≥ 90%: {'✅ 通过' if top_10_acc >= 0.90 else '❌ 未通过'} ({top_10_acc*100:.1f}%)")
    print("="*60)
    
    assert top_10_acc >= 0.85, f"Top-10准确率{top_10_acc*100:.1f}%应该≥85%"

