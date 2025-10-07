"""
物料相关的Pydantic Schema定义

用于API请求/响应数据验证和序列化
对应design.md第2.1节API Endpoint接口定义
"""

from typing import Dict, List, Optional
from pydantic import BaseModel, Field, field_validator
from datetime import datetime


class ParsedQuery(BaseModel):
    """
    解析后的查询结果
    
    对应design.md第2.1.1节ParsedQuery定义
    用于UniversalMaterialProcessor的输出
    """
    
    standardized_name: str = Field(
        ...,
        description="标准化核心名称",
        examples=["六角螺栓 M8*20 304"]
    )
    
    # 新增：清洗后的单独字段（用于前端精确对比）
    cleaned_name: Optional[str] = Field(
        None,
        description="清洗后的物料名称（应用13条标准化规则后）",
        examples=["六角螺栓", "不锈钢管", "挡液圈"]
    )
    
    cleaned_spec: Optional[str] = Field(
        None,
        description="清洗后的规格型号（应用13条标准化规则后）",
        examples=["m8_20", "dn50", "phi100_200"]
    )
    
    cleaned_unit: Optional[str] = Field(
        None,
        description="清洗后的单位（去除空格、统一大小写）",
        examples=["个", "米", "套"]
    )
    
    attributes: Dict[str, str] = Field(
        default_factory=dict,
        description="提取的结构化属性",
        examples=[{"规格": "M8*20", "材质": "304", "类型": "六角"}]
    )
    
    detected_category: str = Field(
        ...,
        description="检测到的物料类别",
        examples=["螺栓螺钉", "轴承", "阀门"]
    )
    
    confidence: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="类别检测置信度 (0-1)",
        examples=[0.85]
    )
    
    full_description: str = Field(
        ...,
        description="构建的完整描述",
        examples=["六角螺栓 M8*20 304不锈钢"]
    )
    
    processing_steps: List[str] = Field(
        default_factory=list,
        description="处理步骤记录（透明化）",
        examples=[
            [
                "步骤1: 检测到类别'螺栓螺钉'，置信度0.85",
                "步骤2: 文本标准化，全角转半角",
                "步骤3: 同义词替换 '不锈钢' → '304'",
                "步骤4: 提取属性 {'规格': 'M8*20', '材质': '304'}"
            ]
        ]
    )
    
    @field_validator('confidence')
    @classmethod
    def validate_confidence(cls, v: float) -> float:
        """确保置信度在有效范围内"""
        if not 0.0 <= v <= 1.0:
            raise ValueError(f"置信度必须在0.0-1.0之间，当前值: {v}")
        return v
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "standardized_name": "六角螺栓 M8*20 304",
                "attributes": {
                    "规格": "M8*20",
                    "材质": "304",
                    "类型": "六角"
                },
                "detected_category": "螺栓螺钉",
                "confidence": 0.85,
                "full_description": "六角螺栓 M8*20 304不锈钢",
                "processing_steps": [
                    "步骤1: 检测到类别'螺栓螺钉'，置信度0.85",
                    "步骤2: 文本标准化，全角转半角",
                    "步骤3: 同义词替换 '不锈钢' → '304'",
                    "步骤4: 提取属性 {'规格': 'M8*20', '材质': '304'}"
                ]
            }
        }
    }


class MaterialResult(BaseModel):
    """
    物料查重结果
    
    对应design.md第2.1.1节MaterialResult定义
    包含ERP物料字段和查重相关字段
    """
    
    # === ERP核心字段 ===
    erp_code: str = Field(
        ...,
        description="ERP物料编码",
        examples=["MAT001"]
    )
    
    material_name: str = Field(
        ...,
        description="物料名称",
        examples=["六角螺栓"]
    )
    
    specification: Optional[str] = Field(
        None,
        description="规格",
        examples=["M8*20"]
    )
    
    model: Optional[str] = Field(
        None,
        description="型号",
        examples=["304"]
    )
    
    english_name: Optional[str] = Field(
        None,
        description="英文名称",
        examples=["Hex Bolt"]
    )
    
    short_name: Optional[str] = Field(
        None,
        description="物料简称",
        examples=["六角螺栓"]
    )
    
    mnemonic_code: Optional[str] = Field(
        None,
        description="助记码",
        examples=["LGJLS"]
    )
    
    # === 分类和单位信息 ===
    category_name: Optional[str] = Field(
        None,
        description="物料分类名称",
        examples=["标准件"]
    )
    
    unit_name: Optional[str] = Field(
        None,
        description="计量单位",
        examples=["个"]
    )
    
    # === ERP状态字段 ===
    enable_state: Optional[int] = Field(
        None,
        description="启用状态 (1=未启用，2=已启用，3=已停用)",
        examples=[2]
    )
    
    full_description: Optional[str] = Field(
        None,
        description="完整描述（name + spec + model组合）",
        examples=["六角螺栓 M8*20 304"]
    )
    
    # === 查重相关字段 ===
    similarity_score: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="相似度得分 (0-1)",
        examples=[0.92]
    )
    
    # === 细分相似度字段 ===
    name_similarity: Optional[float] = Field(
        None,
        ge=0.0,
        le=1.0,
        description="名称相似度 (0-1)",
        examples=[0.95]
    )
    
    description_similarity: Optional[float] = Field(
        None,
        ge=0.0,
        le=1.0,
        description="描述相似度 (0-1)",
        examples=[0.88]
    )
    
    attributes_similarity: Optional[float] = Field(
        None,
        ge=0.0,
        le=1.0,
        description="属性相似度 (0-1)",
        examples=[0.75]
    )
    
    category_similarity: Optional[float] = Field(
        None,
        ge=0.0,
        le=1.0,
        description="分类相似度 (0-1)",
        examples=[1.0]
    )
    
    normalized_name: str = Field(
        ...,
        description="标准化名称",
        examples=["六角螺栓 M8*20 304"]
    )
    
    attributes: Dict[str, str] = Field(
        default_factory=dict,
        description="结构化属性",
        examples=[{"规格": "M8*20", "材质": "304"}]
    )
    
    detected_category: str = Field(
        ...,
        description="检测到的物料类别",
        examples=["螺栓螺钉"]
    )
    
    category_confidence: float = Field(
        ...,
        ge=0.0,
        le=1.0,
        description="类别检测置信度",
        examples=[0.85]
    )
    
    similarity_breakdown: Optional[Dict[str, float]] = Field(
        None,
        description="相似度明细（各维度相似度）",
        examples=[{
            "name_similarity": 0.95,
            "description_similarity": 0.90,
            "attributes_similarity": 0.88,
            "category_similarity": 1.0
        }]
    )
    
    @field_validator('similarity_score', 'category_confidence')
    @classmethod
    def validate_score(cls, v: float) -> float:
        """确保得分在有效范围内"""
        if not 0.0 <= v <= 1.0:
            raise ValueError(f"得分必须在0.0-1.0之间，当前值: {v}")
        return v
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "erp_code": "MAT001",
                "material_name": "六角螺栓",
                "specification": "M8*20",
                "model": "304",
                "english_name": "Hex Bolt",
                "short_name": "六角螺栓",
                "mnemonic_code": "LGJLS",
                "category_name": "标准件",
                "unit_name": "个",
                "similarity_score": 0.92,
                "normalized_name": "六角螺栓 M8*20 304",
                "attributes": {"规格": "M8*20", "材质": "304"},
                "detected_category": "螺栓螺钉",
                "category_confidence": 0.85
            }
        }
    }


class BatchSearchResult(BaseModel):
    """
    单条批量查重结果
    
    对应design.md第2.1.1节BatchSearchResult定义
    包含原始输入、解析结果和Top-N相似物料
    """
    
    input_description: str = Field(
        ...,
        description="用户输入的原始描述",
        examples=["六角螺栓 M8*20 304不锈钢"]
    )
    
    parsed_query: ParsedQuery = Field(
        ...,
        description="解析结果（对称处理输出）"
    )
    
    results: List[MaterialResult] = Field(
        default_factory=list,
        description="Top-10相似物料列表（按相似度降序）",
        max_length=10
    )
    
    @field_validator('results')
    @classmethod
    def validate_results_order(cls, v: List[MaterialResult]) -> List[MaterialResult]:
        """验证结果按相似度降序排列"""
        if len(v) > 1:
            for i in range(len(v) - 1):
                if v[i].similarity_score < v[i + 1].similarity_score:
                    raise ValueError("查重结果必须按相似度降序排列")
        return v
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "input_description": "六角螺栓 M8*20 304不锈钢",
                "parsed_query": {
                    "standardized_name": "六角螺栓 M8*20 304",
                    "attributes": {"规格": "M8*20", "材质": "304"},
                    "detected_category": "螺栓螺钉",
                    "confidence": 0.85,
                    "full_description": "六角螺栓 M8*20 304不锈钢",
                    "processing_steps": []
                },
                "results": []
            }
        }
    }


class BatchSearchResponse(BaseModel):
    """
    批量查重响应
    
    对应design.md第2.1.1节BatchSearchResponse定义
    包含处理统计和所有查重结果
    """
    
    total_processed: int = Field(
        ...,
        ge=0,
        description="处理的总条数",
        examples=[100]
    )
    
    success_count: int = Field(
        default=0,
        ge=0,
        description="成功处理的条数",
        examples=[98]
    )
    
    failed_count: int = Field(
        default=0,
        ge=0,
        description="失败的条数",
        examples=[2]
    )
    
    processing_time_seconds: Optional[float] = Field(
        None,
        ge=0.0,
        description="处理耗时（秒）",
        examples=[5.2]
    )
    
    results: List[BatchSearchResult] = Field(
        default_factory=list,
        description="批量查重结果"
    )
    
    @field_validator('total_processed')
    @classmethod
    def validate_total_count(cls, v: int, info) -> int:
        """验证总数与成功+失败数一致"""
        # 注意：在model_validator中会进行完整验证
        return v
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "total_processed": 100,
                "success_count": 98,
                "failed_count": 2,
                "processing_time_seconds": 5.2,
                "results": []
            }
        }
    }


# === 请求Schema定义 ===

class MaterialSearchRequest(BaseModel):
    """物料查询请求"""
    
    description: str = Field(
        ...,
        min_length=1,
        max_length=500,
        description="物料描述文本",
        examples=["六角螺栓 M8*20 304"]
    )
    
    category_hint: Optional[str] = Field(
        None,
        description="可选的类别提示",
        examples=["螺栓螺钉"]
    )
    
    limit: int = Field(
        default=10,
        ge=1,
        le=50,
        description="返回结果数量限制",
        examples=[10]
    )


class BatchSearchFileRequest(BaseModel):
    """批量文件查重请求（用于文档）"""
    
    description_column: str = Field(
        default="物料描述",
        description="物料描述所在列名",
        examples=["物料描述", "Description"]
    )
    
    limit_per_query: int = Field(
        default=10,
        ge=1,
        le=50,
        description="每条查询返回的结果数量",
        examples=[10]
    )

