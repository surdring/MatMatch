"""
Task 3.3 - 其他API端点测试

测试范围：
1. 单个物料查询 (GET /api/v1/materials/{erp_code})
2. 物料完整详情 (GET /api/v1/materials/{erp_code}/details)
3. 相似物料查询 (GET /api/v1/materials/{erp_code}/similar)
4. 分类列表 (GET /api/v1/categories)
5. 物料搜索 (GET /api/v1/materials/search)
"""

import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime

from backend.api.main import app
from backend.models.materials import (
    MaterialsMaster,
    MaterialCategory,
    MeasurementUnit
)


# ========== Fixtures ==========

@pytest.fixture
async def sample_material(db_session: AsyncSession):
    """创建测试物料"""
    material = MaterialsMaster(
        erp_code="TEST001",
        material_name="测试轴承",
        specification="6205",
        model="深沟球轴承",
        english_name="Test Bearing",
        short_name="轴承",
        mnemonic_code="ZCTEST001",
        oracle_category_id="CAT001",
        category_name="轴承",
        oracle_unit_id="UNIT001",
        unit_name="个",
        normalized_name="测试轴承 6205 深沟球轴承",
        full_description="测试轴承 6205 深沟球轴承",
        attributes={"型号": "6205", "类型": "深沟球轴承"},
        detected_category="bearing",
        category_confidence=0.95,
        enable_state=2,
        oracle_material_id="MAT001",
        oracle_org_id="ORG001",
        oracle_created_time=datetime.now(),
        oracle_modified_time=datetime.now()
    )
    db_session.add(material)
    await db_session.commit()
    await db_session.refresh(material)
    return material


@pytest.fixture
async def sample_category(db_session: AsyncSession):
    """创建测试分类"""
    category = MaterialCategory(
        oracle_category_id="CAT001",
        category_code="BEARING",
        category_name="轴承",
        parent_category_id=None,
        category_level=1,
        enable_state=2,
        detection_keywords=["轴承", "bearing"]
    )
    db_session.add(category)
    await db_session.commit()
    await db_session.refresh(category)
    return category


@pytest.fixture
async def sample_unit(db_session: AsyncSession):
    """创建测试单位"""
    unit = MeasurementUnit(
        oracle_unit_id="UNIT001",
        unit_code="PCS",
        unit_name="个",
        english_name="Piece",
        scale_factor=1.0,
        is_base_unit="Y"
    )
    db_session.add(unit)
    await db_session.commit()
    await db_session.refresh(unit)
    return unit


@pytest.fixture
async def multiple_materials(db_session: AsyncSession):
    """创建多个测试物料"""
    materials = []
    for i in range(5):
        material = MaterialsMaster(
            erp_code=f"TEST{i:03d}",
            material_name=f"测试物料{i}",
            specification=f"规格{i}",
            model=f"型号{i}",
            oracle_category_id="CAT001",
            category_name="测试分类",
            oracle_unit_id="UNIT001",
            unit_name="个",
            normalized_name=f"测试物料{i} 规格{i} 型号{i}",
            full_description=f"测试物料{i} 规格{i} 型号{i}",
            attributes={"序号": str(i)},
            detected_category="general",
            category_confidence=0.8,
            enable_state=2
        )
        db_session.add(material)
        materials.append(material)
    
    await db_session.commit()
    for material in materials:
        await db_session.refresh(material)
    
    return materials


@pytest.fixture
async def client():
    """创建测试客户端"""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


# ========== 测试1: 单个物料查询 ==========

class TestGetMaterialByCode:
    """测试单个物料查询"""
    
    @pytest.mark.asyncio
    async def test_get_existing_material(self, client, sample_material):
        """测试查询存在的物料"""
        response = await client.get(f"/api/v1/materials/{sample_material.erp_code}")
        assert response.status_code == 200
        
        data = response.json()
        assert data["erp_code"] == sample_material.erp_code
        assert data["material_name"] == sample_material.material_name
        assert "normalized_name" in data
        assert "attributes" in data
        assert "detected_category" in data
    
    @pytest.mark.asyncio
    async def test_get_nonexistent_material(self, client):
        """测试查询不存在的物料"""
        response = await client.get("/api/v1/materials/NONEXISTENT")
        assert response.status_code == 404
        
        data = response.json()
        assert "error" in data
        assert data["error"]["code"] == "MATERIAL_NOT_FOUND"
    
    @pytest.mark.asyncio
    async def test_response_structure(self, client, sample_material):
        """测试响应结构完整性"""
        response = await client.get(f"/api/v1/materials/{sample_material.erp_code}")
        assert response.status_code == 200
        
        data = response.json()
        required_fields = [
            "erp_code", "material_name", "normalized_name",
            "attributes", "detected_category", "category_confidence",
            "enable_state", "created_at", "updated_at"
        ]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
    
    @pytest.mark.asyncio
    async def test_query_performance(self, client, sample_material):
        """测试查询性能（≤200ms）"""
        import time
        start = time.time()
        response = await client.get(f"/api/v1/materials/{sample_material.erp_code}")
        elapsed = (time.time() - start) * 1000
        
        assert response.status_code == 200
        assert elapsed <= 200, f"Query took {elapsed}ms, expected ≤200ms"


# ========== 测试2: 物料完整详情 ==========

class TestGetMaterialDetails:
    """测试物料完整详情查询"""
    
    @pytest.mark.asyncio
    async def test_get_full_details(self, client, sample_material, sample_category, sample_unit):
        """测试获取完整详情"""
        response = await client.get(
            f"/api/v1/materials/{sample_material.erp_code}/details"
        )
        assert response.status_code == 200
        
        data = response.json()
        assert "category_info" in data
        assert "unit_info" in data
        assert "oracle_metadata" in data
    
    @pytest.mark.asyncio
    async def test_category_info_structure(self, client, sample_material, sample_category):
        """测试分类信息结构"""
        response = await client.get(
            f"/api/v1/materials/{sample_material.erp_code}/details"
        )
        assert response.status_code == 200
        
        category_info = response.json()["category_info"]
        assert category_info is not None
        assert "category_code" in category_info
        assert "category_name" in category_info
        assert category_info["category_name"] == "轴承"
    
    @pytest.mark.asyncio
    async def test_unit_info_structure(self, client, sample_material, sample_unit):
        """测试单位信息结构"""
        response = await client.get(
            f"/api/v1/materials/{sample_material.erp_code}/details"
        )
        assert response.status_code == 200
        
        unit_info = response.json()["unit_info"]
        assert unit_info is not None
        assert "unit_code" in unit_info
        assert "unit_name" in unit_info
        assert unit_info["unit_name"] == "个"
    
    @pytest.mark.asyncio
    async def test_oracle_metadata_structure(self, client, sample_material):
        """测试Oracle元数据结构"""
        response = await client.get(
            f"/api/v1/materials/{sample_material.erp_code}/details"
        )
        assert response.status_code == 200
        
        oracle_metadata = response.json()["oracle_metadata"]
        assert oracle_metadata is not None
        assert "oracle_material_id" in oracle_metadata
        assert "oracle_org_id" in oracle_metadata


# ========== 测试3: 相似物料查询 ==========

class TestGetSimilarMaterials:
    """测试相似物料查询"""
    
    @pytest.mark.asyncio
    async def test_find_similar_materials(self, client, multiple_materials):
        """测试查找相似物料"""
        source_material = multiple_materials[0]
        response = await client.get(
            f"/api/v1/materials/{source_material.erp_code}/similar?limit=10"
        )
        assert response.status_code == 200
        
        data = response.json()
        assert "source_material" in data
        assert "similar_materials" in data
        assert len(data["similar_materials"]) <= 10
    
    @pytest.mark.asyncio
    async def test_similarity_scores(self, client, multiple_materials):
        """测试相似度分数"""
        source_material = multiple_materials[0]
        response = await client.get(
            f"/api/v1/materials/{source_material.erp_code}/similar"
        )
        assert response.status_code == 200
        
        similar_materials = response.json()["similar_materials"]
        for item in similar_materials:
            assert 0 <= item["similarity_score"] <= 1
            assert "similarity_breakdown" in item
            
            # 检查相似度细分
            breakdown = item["similarity_breakdown"]
            assert "name_similarity" in breakdown
            assert "description_similarity" in breakdown
            assert "attributes_similarity" in breakdown
            assert "category_match" in breakdown
    
    @pytest.mark.asyncio
    async def test_limit_parameter(self, client, multiple_materials):
        """测试limit参数"""
        source_material = multiple_materials[0]
        response = await client.get(
            f"/api/v1/materials/{source_material.erp_code}/similar?limit=3"
        )
        assert response.status_code == 200
        
        data = response.json()
        assert len(data["similar_materials"]) <= 3
    
    @pytest.mark.asyncio
    async def test_excludes_self(self, client, sample_material):
        """测试排除自身"""
        response = await client.get(
            f"/api/v1/materials/{sample_material.erp_code}/similar?limit=10"
        )
        assert response.status_code == 200
        
        similar_materials = response.json()["similar_materials"]
        for item in similar_materials:
            assert item["erp_code"] != sample_material.erp_code


# ========== 测试4: 分类列表 ==========

class TestGetCategories:
    """测试分类列表"""
    
    @pytest.mark.asyncio
    async def test_get_all_categories(self, client, sample_category):
        """测试获取所有分类"""
        response = await client.get("/api/v1/categories")
        assert response.status_code == 200
        
        data = response.json()
        assert "categories" in data
        assert "pagination" in data
    
    @pytest.mark.asyncio
    async def test_pagination(self, client, sample_category):
        """测试分页功能"""
        response = await client.get("/api/v1/categories?page=1&page_size=10")
        assert response.status_code == 200
        
        data = response.json()
        assert data["pagination"]["page"] == 1
        assert data["pagination"]["page_size"] == 10
        assert len(data["categories"]) <= 10
    
    @pytest.mark.asyncio
    async def test_category_structure(self, client, sample_category):
        """测试分类结构"""
        response = await client.get("/api/v1/categories")
        assert response.status_code == 200
        
        categories = response.json()["categories"]
        if len(categories) > 0:
            category = categories[0]
            assert "oracle_category_id" in category
            assert "category_code" in category
            assert "category_name" in category
            assert "material_count" in category
            assert "detection_keywords" in category
    
    @pytest.mark.asyncio
    async def test_invalid_page_parameters(self, client):
        """测试无效的分页参数"""
        response = await client.get("/api/v1/categories?page=0")
        assert response.status_code == 422  # Validation error


# ========== 测试5: 物料搜索 ==========

class TestSearchMaterials:
    """测试物料搜索"""
    
    @pytest.mark.asyncio
    async def test_basic_search(self, client, multiple_materials):
        """测试基本搜索"""
        response = await client.get("/api/v1/materials/search?keyword=测试")
        assert response.status_code == 200
        
        data = response.json()
        assert "materials" in data
        assert "pagination" in data
        assert "search_stats" in data
        
        # 检查搜索统计
        assert "search_time_ms" in data["search_stats"]
        assert "keyword" in data["search_stats"]
        assert data["search_stats"]["keyword"] == "测试"
    
    @pytest.mark.asyncio
    async def test_search_with_enable_state_filter(self, client, multiple_materials):
        """测试带状态筛选的搜索"""
        response = await client.get(
            "/api/v1/materials/search?keyword=测试&enable_state=2"
        )
        assert response.status_code == 200
        
        data = response.json()
        for material in data["materials"]:
            assert material["enable_state"] == 2
    
    @pytest.mark.asyncio
    async def test_search_with_category_filter(self, client, multiple_materials):
        """测试带分类筛选的搜索"""
        response = await client.get(
            "/api/v1/materials/search?keyword=测试&category_id=CAT001"
        )
        assert response.status_code == 200
        
        # 搜索应该成功执行
        data = response.json()
        assert "materials" in data
    
    @pytest.mark.asyncio
    async def test_search_pagination(self, client, multiple_materials):
        """测试搜索分页"""
        response = await client.get(
            "/api/v1/materials/search?keyword=测试&page=1&page_size=2"
        )
        assert response.status_code == 200
        
        data = response.json()
        assert data["pagination"]["page"] == 1
        assert data["pagination"]["page_size"] == 2
        assert len(data["materials"]) <= 2
    
    @pytest.mark.asyncio
    async def test_search_performance(self, client, multiple_materials):
        """测试搜索性能（≤500ms）"""
        response = await client.get("/api/v1/materials/search?keyword=测试")
        assert response.status_code == 200
        
        data = response.json()
        search_time = data["search_stats"]["search_time_ms"]
        assert search_time <= 500, f"Search took {search_time}ms, expected ≤500ms"
    
    @pytest.mark.asyncio
    async def test_empty_keyword_error(self, client):
        """测试空关键词错误"""
        response = await client.get("/api/v1/materials/search?keyword=")
        assert response.status_code == 422  # Validation error
    
    @pytest.mark.asyncio
    async def test_search_no_results(self, client):
        """测试无结果搜索"""
        response = await client.get("/api/v1/materials/search?keyword=不存在的物料名称xyz123")
        assert response.status_code == 200
        
        data = response.json()
        assert len(data["materials"]) == 0
        assert data["pagination"]["total_items"] == 0


# ========== 边界情况测试 ==========

class TestEdgeCases:
    """边界情况测试"""
    
    @pytest.mark.asyncio
    async def test_special_characters_in_erp_code(self, client):
        """测试ERP编码中的特殊字符"""
        response = await client.get("/api/v1/materials/TEST-001%2F")
        assert response.status_code in [404, 422]  # 不存在或验证错误
    
    @pytest.mark.asyncio
    async def test_very_long_erp_code(self, client):
        """测试超长ERP编码"""
        long_code = "A" * 100
        response = await client.get(f"/api/v1/materials/{long_code}")
        assert response.status_code in [404, 422]
    
    @pytest.mark.asyncio
    async def test_search_with_special_characters(self, client):
        """测试搜索关键词中的特殊字符"""
        response = await client.get("/api/v1/materials/search?keyword=%25*%28%29")
        assert response.status_code == 200
    
    @pytest.mark.asyncio
    async def test_similar_limit_boundary(self, client, sample_material):
        """测试相似物料limit边界值"""
        # 测试最小值
        response = await client.get(
            f"/api/v1/materials/{sample_material.erp_code}/similar?limit=1"
        )
        assert response.status_code == 200
        
        # 测试最大值
        response = await client.get(
            f"/api/v1/materials/{sample_material.erp_code}/similar?limit=50"
        )
        assert response.status_code == 200
        
        # 测试超出范围
        response = await client.get(
            f"/api/v1/materials/{sample_material.erp_code}/similar?limit=100"
        )
        assert response.status_code == 422  # Validation error
    
    @pytest.mark.asyncio
    async def test_pagination_out_of_range(self, client):
        """测试超出范围的分页"""
        response = await client.get("/api/v1/categories?page=9999&page_size=20")
        assert response.status_code == 200
        
        data = response.json()
        assert len(data["categories"]) == 0  # 应该返回空列表

