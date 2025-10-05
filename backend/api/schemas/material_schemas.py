"""
物料查询相关的Pydantic Schema定义

提供以下功能：
1. 物料基本信息响应
2. 物料完整详情响应（含关联信息）
3. 相似物料查询响应
4. 分类列表响应
5. 物料搜索响应
"""

from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime


# ========== 基础响应模型 ==========

class MaterialBasicInfo(BaseModel):
    """物料基本信息"""
    model_config = ConfigDict(from_attributes=True)
    
    erp_code: str = Field(..., description="ERP物料编码")
    material_name: str = Field(..., description="物料名称")
    specification: Optional[str] = Field(None, description="规格")
    model: Optional[str] = Field(None, description="型号")
    category_name: Optional[str] = Field(None, description="分类名称")
    unit_name: Optional[str] = Field(None, description="单位名称")
    enable_state: int = Field(2, description="启用状态")


class MaterialDetailResponse(BaseModel):
    """物料详情响应"""
    model_config = ConfigDict(from_attributes=True)
    
    # 基本信息
    erp_code: str = Field(..., description="ERP物料编码")
    material_name: str = Field(..., description="物料名称")
    specification: Optional[str] = Field(None, description="规格")
    model: Optional[str] = Field(None, description="型号")
    english_name: Optional[str] = Field(None, description="英文名称")
    short_name: Optional[str] = Field(None, description="物料简称")
    mnemonic_code: Optional[str] = Field(None, description="助记码")
    
    # 关联信息
    category_name: Optional[str] = Field(None, description="分类名称")
    unit_name: Optional[str] = Field(None, description="单位名称")
    
    # 智能处理结果
    normalized_name: str = Field(..., description="标准化名称")
    full_description: Optional[str] = Field(None, description="完整描述")
    attributes: Dict[str, Any] = Field(default_factory=dict, description="结构化属性")
    detected_category: str = Field(..., description="检测到的类别")
    category_confidence: float = Field(..., description="类别检测置信度")
    
    # 状态和时间
    enable_state: int = Field(..., description="启用状态")
    created_at: datetime = Field(..., description="创建时间")
    updated_at: datetime = Field(..., description="更新时间")


# ========== 扩展详情模型 ==========

class CategoryInfo(BaseModel):
    """分类信息"""
    oracle_category_id: Optional[str] = Field(None, description="Oracle分类ID")
    category_code: Optional[str] = Field(None, description="分类编码")
    category_name: Optional[str] = Field(None, description="分类名称")
    parent_category_id: Optional[str] = Field(None, description="父分类ID")


class UnitInfo(BaseModel):
    """单位信息"""
    oracle_unit_id: Optional[str] = Field(None, description="Oracle单位ID")
    unit_code: Optional[str] = Field(None, description="单位编码")
    unit_name: Optional[str] = Field(None, description="单位名称")
    english_name: Optional[str] = Field(None, description="英文名称")
    scale_factor: Optional[float] = Field(None, description="换算因子")


class OracleMetadata(BaseModel):
    """Oracle元数据"""
    oracle_material_id: Optional[str] = Field(None, description="Oracle物料ID")
    oracle_org_id: Optional[str] = Field(None, description="Oracle组织ID")
    oracle_created_time: Optional[datetime] = Field(None, description="Oracle创建时间")
    oracle_modified_time: Optional[datetime] = Field(None, description="Oracle修改时间")


class MaterialFullDetailResponse(MaterialDetailResponse):
    """物料完整详情（含关联信息）"""
    category_info: Optional[CategoryInfo] = Field(None, description="分类详情")
    unit_info: Optional[UnitInfo] = Field(None, description="单位详情")
    oracle_metadata: Optional[OracleMetadata] = Field(None, description="Oracle元数据")


# ========== 相似物料模型 ==========

class SimilarityBreakdown(BaseModel):
    """相似度细分"""
    name_similarity: float = Field(..., description="名称相似度")
    description_similarity: float = Field(..., description="描述相似度")
    attributes_similarity: float = Field(..., description="属性相似度")
    category_match: float = Field(..., description="类别匹配度")


class SimilarMaterialItem(BaseModel):
    """相似物料项"""
    erp_code: str = Field(..., description="ERP物料编码")
    material_name: str = Field(..., description="物料名称")
    specification: Optional[str] = Field(None, description="规格")
    category_name: Optional[str] = Field(None, description="分类名称")
    similarity_score: float = Field(..., description="综合相似度得分")
    similarity_breakdown: SimilarityBreakdown = Field(..., description="相似度细分")


class SimilarMaterialsResponse(BaseModel):
    """相似物料响应"""
    source_material: MaterialBasicInfo = Field(..., description="源物料信息")
    similar_materials: List[SimilarMaterialItem] = Field(..., description="相似物料列表")
    total_found: int = Field(..., description="找到的相似物料总数")


# ========== 分类模型 ==========

class CategoryItem(BaseModel):
    """分类项"""
    model_config = ConfigDict(from_attributes=True)
    
    oracle_category_id: str = Field(..., description="Oracle分类ID")
    category_code: str = Field(..., description="分类编码")
    category_name: str = Field(..., description="分类名称")
    parent_category_id: Optional[str] = Field(None, description="父分类ID")
    category_level: int = Field(1, description="分类层级")
    material_count: int = Field(0, description="物料数量")
    detection_keywords: List[str] = Field(default_factory=list, description="检测关键词")
    enable_state: int = Field(2, description="启用状态")


class PaginationInfo(BaseModel):
    """分页信息"""
    page: int = Field(..., description="当前页码")
    page_size: int = Field(..., description="每页数量")
    total_items: int = Field(..., description="总记录数")
    total_pages: int = Field(..., description="总页数")


class CategoriesListResponse(BaseModel):
    """分类列表响应"""
    categories: List[CategoryItem] = Field(..., description="分类列表")
    pagination: PaginationInfo = Field(..., description="分页信息")


# ========== 搜索模型 ==========

class MaterialSearchItem(BaseModel):
    """搜索结果项"""
    erp_code: str = Field(..., description="ERP物料编码")
    material_name: str = Field(..., description="物料名称")
    specification: Optional[str] = Field(None, description="规格")
    model: Optional[str] = Field(None, description="型号")
    category_name: Optional[str] = Field(None, description="分类名称")
    unit_name: Optional[str] = Field(None, description="单位名称")
    enable_state: int = Field(..., description="启用状态")


class SearchStats(BaseModel):
    """搜索统计"""
    search_time_ms: int = Field(..., description="搜索耗时(毫秒)")
    keyword: str = Field(..., description="搜索关键词")
    total_results: int = Field(..., description="总结果数")


class MaterialSearchResponse(BaseModel):
    """物料搜索响应"""
    materials: List[MaterialSearchItem] = Field(..., description="搜索结果列表")
    pagination: PaginationInfo = Field(..., description="分页信息")
    search_stats: SearchStats = Field(..., description="搜索统计")

