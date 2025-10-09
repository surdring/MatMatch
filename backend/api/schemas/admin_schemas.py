"""
管理后台API的Pydantic Schema定义

本模块定义管理后台所需的所有请求/响应数据模型，包括：
- 提取规则管理Schema
- 同义词管理Schema
- 物料分类管理Schema
- ETL监控Schema
- 通用分页Schema

关联测试点 (Associated Test Points):
- [T.1.1-T.1.20] - 所有核心功能的Schema支持
- [T.2.1-T.2.18] - 所有边界情况的Schema验证

符合Design.md第2.1.2节 - 动态规则管理接口定义
"""

from typing import Optional, List, Dict, Any, Generic, TypeVar
from datetime import datetime
from pydantic import BaseModel, Field, field_validator, ConfigDict
from enum import Enum
from decimal import Decimal


# ============================================================================
# 通用Schema
# ============================================================================

T = TypeVar('T')


class PaginationParams(BaseModel):
    """分页参数"""
    page: int = Field(1, ge=1, description="页码（从1开始）")
    page_size: int = Field(50, ge=1, le=100, description="每页数量（1-100）")


class PaginatedResponse(BaseModel, Generic[T]):
    """
    通用分页响应
    
    关联测试点:
    - [T.1.2] - 查询规则列表分页
    - [T.1.10] - 查询同义词列表分页
    """
    items: List[T] = Field(..., description="数据列表")
    total: int = Field(..., ge=0, description="总记录数")
    page: int = Field(..., ge=1, description="当前页码")
    page_size: int = Field(..., ge=1, le=100, description="每页数量")
    total_pages: int = Field(..., ge=0, description="总页数")
    
    model_config = ConfigDict(from_attributes=True)


# ============================================================================
# 提取规则Schema
# ============================================================================

class ExtractionRuleBase(BaseModel):
    """提取规则基础Schema"""
    rule_name: str = Field(..., min_length=1, max_length=100, description="规则名称")
    material_category: str = Field(..., min_length=1, max_length=50, description="物料类别")
    attribute_name: str = Field(..., min_length=1, max_length=50, description="属性名称")
    regex_pattern: str = Field(..., min_length=1, max_length=500, description="正则表达式模式")
    priority: Optional[int] = Field(100, ge=0, le=1000, description="优先级（0-1000）")
    is_active: bool = Field(True, description="是否激活")
    description: Optional[str] = Field(None, max_length=1000, description="规则描述")
    example_input: Optional[str] = Field(None, max_length=500, description="示例输入")
    example_output: Optional[str] = Field(None, max_length=500, description="示例输出")


class ExtractionRuleCreate(ExtractionRuleBase):
    """
    创建提取规则请求Schema
    
    关联测试点:
    - [T.1.1] - 创建提取规则（Happy Path）
    - [T.2.1] - 创建重复规则验证
    - [T.2.2] - 无效正则表达式验证
    """
    pass


class ExtractionRuleUpdate(BaseModel):
    """
    更新提取规则请求Schema
    
    关联测试点:
    - [T.1.4] - 更新提取规则
    - [T.2.3] - 更新不存在的规则
    
    注意：所有字段均为可选，支持部分更新
    """
    rule_name: Optional[str] = Field(None, min_length=1, max_length=100)
    material_category: Optional[str] = Field(None, min_length=1, max_length=50)
    attribute_name: Optional[str] = Field(None, min_length=1, max_length=50)
    regex_pattern: Optional[str] = Field(None, min_length=1, max_length=500)
    priority: Optional[int] = Field(None, ge=0, le=1000)
    is_active: Optional[bool] = None
    description: Optional[str] = Field(None, max_length=1000)
    example_input: Optional[str] = Field(None, max_length=500)
    example_output: Optional[str] = Field(None, max_length=500)


class ExtractionRuleResponse(ExtractionRuleBase):
    """
    提取规则响应Schema
    
    关联测试点:
    - [T.1.1] - 创建规则响应验证
    - [T.1.3] - 查询规则详情响应
    """
    id: int = Field(..., description="规则ID")
    confidence: Optional[Decimal] = Field(None, description="置信度")
    version: int = Field(1, ge=1, description="版本号")
    created_by: str = Field("system", description="创建者")
    created_at: datetime = Field(..., description="创建时间")
    updated_at: datetime = Field(..., description="更新时间")
    
    model_config = ConfigDict(from_attributes=True, arbitrary_types_allowed=True)


class RuleTestRequest(BaseModel):
    """
    规则测试请求Schema
    
    关联测试点:
    - [T.1.8] - 测试规则提取效果
    
    验收标准: AC 4.8 - 提供规则测试功能
    """
    test_text: str = Field(..., min_length=1, max_length=500, description="测试文本")


class RuleTestResult(BaseModel):
    """规则测试结果Schema"""
    matched: bool = Field(..., description="是否匹配成功")
    extracted_value: Optional[str] = Field(None, description="提取的值")
    match_groups: Optional[List[str]] = Field(None, description="匹配的分组")
    error_message: Optional[str] = Field(None, description="错误信息")


# ============================================================================
# 同义词Schema
# ============================================================================

class SynonymTypeEnum(str, Enum):
    """同义词类型枚举"""
    GENERAL = "general"
    BRAND = "brand"
    SPECIFICATION = "specification"
    MATERIAL = "material"
    UNIT = "unit"


class SynonymBase(BaseModel):
    """同义词基础Schema"""
    original_term: str = Field(..., min_length=1, max_length=200, description="原始词汇")
    standard_term: str = Field(..., min_length=1, max_length=200, description="标准词汇")
    category: Optional[str] = Field("general", min_length=1, max_length=50, description="词汇类别")
    synonym_type: SynonymTypeEnum = Field(SynonymTypeEnum.GENERAL, description="同义词类型")
    is_active: bool = Field(True, description="是否激活")
    confidence: Optional[Decimal] = Field(1.0, description="置信度（0.0-1.0）")
    description: Optional[str] = Field(None, max_length=500, description="描述")
    
    model_config = ConfigDict(arbitrary_types_allowed=True)
    
    @field_validator('confidence')
    @classmethod
    def validate_confidence(cls, v):
        """
        验证置信度范围
        
        关联测试点: [T.2.12] - 同义词置信度边界值
        """
        if v is not None and not (0.0 <= v <= 1.0):
            raise ValueError("置信度必须在0.0-1.0之间")
        return v


class SynonymCreate(SynonymBase):
    """
    创建同义词请求Schema
    
    关联测试点:
    - [T.1.9] - 创建同义词（Happy Path）
    - [T.2.8] - 创建重复同义词验证
    - [T.2.13] - 特殊字符处理
    """
    pass


class SynonymUpdate(BaseModel):
    """
    更新同义词请求Schema
    
    关联测试点:
    - [T.1.12] - 更新同义词
    
    注意：所有字段均为可选，支持部分更新
    """
    original_term: Optional[str] = Field(None, min_length=1, max_length=200)
    standard_term: Optional[str] = Field(None, min_length=1, max_length=200)
    category: Optional[str] = Field(None, min_length=1, max_length=50)
    synonym_type: Optional[SynonymTypeEnum] = None
    is_active: Optional[bool] = None
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    description: Optional[str] = Field(None, max_length=500)


class SynonymResponse(SynonymBase):
    """
    同义词响应Schema
    
    关联测试点:
    - [T.1.9] - 创建同义词响应验证
    - [T.1.11] - 查询同义词详情响应
    """
    id: int = Field(..., description="同义词ID")
    created_by: str = Field("system", description="创建者")
    created_at: datetime = Field(..., description="创建时间")
    updated_at: datetime = Field(..., description="更新时间")
    
    model_config = ConfigDict(from_attributes=True)


class BatchSynonymImportRequest(BaseModel):
    """
    批量导入同义词请求Schema
    
    关联测试点:
    - [T.2.9] - 批量导入边界测试
    
    验收标准: AC 4.9 - 支持批量导入（≤1000条）
    """
    items: List[SynonymCreate] = Field(..., min_length=1, max_length=1000, description="同义词列表（≤1000条）")
    
    @field_validator('items')
    @classmethod
    def validate_batch_size(cls, v):
        """验证批量导入数量限制"""
        if len(v) > 1000:
            raise ValueError("单次导入不能超过1000条记录")
        return v


class BatchImportResult(BaseModel):
    """批量导入结果Schema"""
    total: int = Field(..., ge=0, description="总数")
    success: int = Field(..., ge=0, description="成功数")
    failed: int = Field(..., ge=0, description="失败数")
    errors: List[Dict[str, Any]] = Field(default_factory=list, description="错误详情")


# ============================================================================
# 物料分类Schema
# ============================================================================

class MaterialCategoryBase(BaseModel):
    """物料分类基础Schema"""
    category_name: str = Field(..., min_length=1, max_length=100, description="分类名称")
    keywords: List[str] = Field(default_factory=list, description="检测关键词数组")
    detection_confidence: Optional[Decimal] = Field(0.8, description="检测置信度阈值")
    category_type: str = Field("general", max_length=50, description="分类类型")
    priority: int = Field(50, ge=0, le=100, description="优先级")
    is_active: bool = Field(True, description="是否激活")

    model_config = ConfigDict(arbitrary_types_allowed=True)


class MaterialCategoryCreate(MaterialCategoryBase):
    """物料分类创建Schema"""
    pass


class MaterialCategoryUpdate(BaseModel):
    """物料分类更新Schema"""
    category_name: Optional[str] = Field(None, min_length=1, max_length=100, description="分类名称")
    keywords: Optional[List[str]] = Field(None, description="检测关键词数组")
    detection_confidence: Optional[float] = Field(None, ge=0.0, le=1.0, description="检测置信度阈值")
    category_type: Optional[str] = Field(None, max_length=50, description="分类类型")
    priority: Optional[int] = Field(None, ge=0, le=100, description="优先级")
    is_active: Optional[bool] = Field(None, description="是否激活")


class MaterialCategoryResponse(MaterialCategoryBase):
    """
    物料分类响应Schema
    
    关联测试点:
    - [T.1.17] - 查询分类列表
    - [T.1.18] - 查询分类详情
    """
    id: int = Field(..., description="分类ID")
    material_count: Optional[int] = Field(0, ge=0, description="关联物料数量（统计信息）")
    created_at: datetime = Field(..., description="创建时间")
    updated_at: datetime = Field(..., description="更新时间")
    
    model_config = ConfigDict(from_attributes=True)


# 兼容旧代码的别名
CategoryResponse = MaterialCategoryResponse


# ============================================================================
# ETL监控Schema
# ============================================================================

class ETLJobStatusEnum(str, Enum):
    """ETL任务状态枚举"""
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


class ETLJobTypeEnum(str, Enum):
    """ETL任务类型枚举"""
    FULL_SYNC = "full_sync"
    INCREMENTAL_SYNC = "incremental_sync"


class ETLJobLogResponse(BaseModel):
    """
    ETL任务响应Schema
    
    关联测试点:
    - [T.1.19] - 查询ETL任务列表
    - [T.1.20] - 查询ETL任务详情
    """
    id: int = Field(..., description="任务ID")
    job_type: ETLJobTypeEnum = Field(..., description="任务类型")
    status: ETLJobStatusEnum = Field(..., description="任务状态")
    total_records: int = Field(0, ge=0, description="总记录数")
    processed_records: int = Field(0, ge=0, description="已处理记录数")
    failed_records: int = Field(0, ge=0, description="失败记录数")
    success_rate: Optional[Decimal] = Field(None, description="成功率（%）")
    duration_seconds: Optional[int] = Field(None, ge=0, description="执行时长（秒）")
    error_message: Optional[str] = Field(None, description="错误信息")
    started_at: datetime = Field(..., description="开始时间")
    completed_at: Optional[datetime] = Field(None, description="完成时间")
    
    model_config = ConfigDict(from_attributes=True, arbitrary_types_allowed=True)


# 兼容旧代码的别名
ETLJobResponse = ETLJobLogResponse


class ETLJobStatistics(BaseModel):
    """ETL任务统计信息Schema"""
    total_jobs: int = Field(0, ge=0, description="总任务数")
    success_jobs: int = Field(0, ge=0, description="成功任务数")
    failed_jobs: int = Field(0, ge=0, description="失败任务数")
    success_rate: float = Field(0.0, ge=0.0, le=100.0, description="成功率（%）")
    avg_duration_seconds: float = Field(0.0, ge=0.0, description="平均执行时长（秒）")


# ============================================================================
# 缓存管理Schema
# ============================================================================

class CacheType(str, Enum):
    """缓存类型枚举"""
    ALL = "all"
    EXTRACTION_RULES = "extraction_rules"
    SYNONYMS = "synonyms"
    CATEGORIES = "categories"


class CacheClearRequest(BaseModel):
    """
    缓存清空请求Schema
    
    关联测试点:
    - [T.3.4] - 手动清空缓存API
    """
    cache_type: CacheType = Field(CacheType.ALL, description="缓存类型")


class CacheClearResponse(BaseModel):
    """缓存清空响应Schema"""
    message: str = Field(..., description="响应消息")
    cleared_types: List[str] = Field(..., description="已清空的缓存类型")


# ============================================================================
# 通用响应Schema
# ============================================================================

class MessageResponse(BaseModel):
    """通用消息响应Schema"""
    message: str = Field(..., description="响应消息")


class ErrorDetail(BaseModel):
    """错误详情Schema"""
    field: Optional[str] = Field(None, description="错误字段")
    message: str = Field(..., description="错误消息")
    code: Optional[str] = Field(None, description="错误代码")

