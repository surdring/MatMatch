"""
物料相关数据模型
实现完整的Oracle物料数据表结构和查重系统扩展字段

严格基于design.md第2.3节数据库设计部分的materials_master表结构
对应 [I.3] - Oracle字段映射逻辑的核心实现
"""

from datetime import datetime
from typing import Dict, Any, Optional, List
from sqlalchemy import (
    String, Integer, Text, DECIMAL, TIMESTAMP, Boolean,
    Index, ForeignKey, UniqueConstraint, ARRAY
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, TimestampMixin, SyncStatusMixin


class MaterialsMaster(Base, TimestampMixin, SyncStatusMixin):
    """
    物料主数据表
    
    完全基于Oracle bd_material表结构设计，包含查重系统扩展字段
    对应design.md第2.3节materials_master表定义
    对应 [I.3] - Oracle字段映射逻辑说明
    """
    
    __tablename__ = "materials_master"
    
    # 主键
    id: Mapped[int] = mapped_column(primary_key=True, comment="主键ID")
    
    # === Oracle bd_material核心字段映射 ===
    # 对应 [I.3] - 为什么使用VARCHAR(40)：Oracle ERP_CODE字段长度限制
    erp_code: Mapped[str] = mapped_column(
        String(40), 
        unique=True, 
        nullable=False,
        comment="ERP物料编码 (bd_material.code)"
    )
    
    material_name: Mapped[str] = mapped_column(
        String(200), 
        nullable=False,
        comment="物料名称 (bd_material.name)"
    )
    
    specification: Mapped[Optional[str]] = mapped_column(
        String(400),
        comment="物料规格 (bd_material.materialspec)"
    )
    
    model: Mapped[Optional[str]] = mapped_column(
        String(400),
        comment="物料型号 (bd_material.materialtype)"
    )
    
    english_name: Mapped[Optional[str]] = mapped_column(
        String(200),
        comment="英文名称 (bd_material.ename)"
    )
    
    english_spec: Mapped[Optional[str]] = mapped_column(
        String(400),
        comment="英文规格 (bd_material.ematerialspec)"
    )
    
    short_name: Mapped[Optional[str]] = mapped_column(
        String(200),
        comment="物料简称 (bd_material.materialshortname)"
    )
    
    mnemonic_code: Mapped[Optional[str]] = mapped_column(
        String(50),
        comment="助记码 (bd_material.materialmnecode)"
    )
    
    memo: Mapped[Optional[str]] = mapped_column(
        String(100),
        comment="备注 (bd_material.memo)"
    )
    
    material_barcode: Mapped[Optional[str]] = mapped_column(
        String(30),
        comment="物料条码 (bd_material.materialbarcode)"
    )
    
    graph_id: Mapped[Optional[str]] = mapped_column(
        String(50),
        comment="图形ID (bd_material.graphid)"
    )
    
    # === Oracle关联ID字段 ===
    # 对应 [I.3] - 为什么使用VARCHAR(20)：Oracle主键格式为20位字符串
    oracle_material_id: Mapped[Optional[str]] = mapped_column(
        String(20),
        comment="Oracle物料主键 (bd_material.pk_material)"
    )
    
    oracle_category_id: Mapped[Optional[str]] = mapped_column(
        String(20),
        comment="Oracle分类主键 (bd_material.pk_marbasclass)"
    )
    
    oracle_brand_id: Mapped[Optional[str]] = mapped_column(
        String(20),
        comment="Oracle品牌主键 (bd_material.pk_brand)"
    )
    
    oracle_unit_id: Mapped[Optional[str]] = mapped_column(
        String(20),
        comment="Oracle单位主键 (bd_material.pk_measdoc)"
    )
    
    oracle_org_id: Mapped[Optional[str]] = mapped_column(
        String(20),
        comment="Oracle组织主键 (bd_material.pk_org)"
    )
    
    oracle_group_id: Mapped[Optional[str]] = mapped_column(
        String(20),
        comment="Oracle集团主键 (bd_material.pk_group)"
    )
    
    # === Oracle状态和管理字段 ===
    # 对应 [I.3] - 为什么使用INTEGER：Oracle enablestate字段为数值类型
    enable_state: Mapped[int] = mapped_column(
        Integer,
        default=2,
        comment="启用状态 (1=未启用，2=已启用，3=已停用)"
    )
    
    material_mgt: Mapped[Optional[int]] = mapped_column(
        Integer,
        comment="物料管理类型 (1=周转材料，2=设备)"
    )
    
    feature_class: Mapped[Optional[str]] = mapped_column(
        String(20),
        comment="特征分类 (bd_material.featureclass)"
    )
    
    is_feature: Mapped[Optional[str]] = mapped_column(
        String(1),
        comment="是否特征件 (bd_material.isfeature)"
    )
    
    is_service: Mapped[Optional[str]] = mapped_column(
        String(1),
        comment="是否服务费用 (bd_material.fee)"
    )
    
    version_number: Mapped[Optional[int]] = mapped_column(
        Integer,
        comment="版本号 (bd_material.version)"
    )
    
    # === Oracle时间字段 ===
    oracle_created_time: Mapped[Optional[datetime]] = mapped_column(
        TIMESTAMP,
        comment="Oracle创建时间 (bd_material.creationtime)"
    )
    
    oracle_modified_time: Mapped[Optional[datetime]] = mapped_column(
        TIMESTAMP,
        comment="Oracle修改时间 (bd_material.modifiedtime)"
    )
    
    # === 查重系统扩展字段 ===
    # 对应design.md第2.3节查重系统字段设计
    normalized_name: Mapped[str] = mapped_column(
        String(500),
        nullable=False,
        comment="标准化后的名称（用于查重）"
    )
    
    full_description: Mapped[Optional[str]] = mapped_column(
        Text,
        comment="完整描述（name + spec + model组合）"
    )
    
    # 对应 [I.1] - JSONB类型用于存储结构化属性
    attributes: Mapped[Dict[str, Any]] = mapped_column(
        JSONB,
        nullable=False,
        default=dict,
        comment="提取的结构化属性（JSONB格式）"
    )
    
    detected_category: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        default="general",
        comment="智能检测的类别"
    )
    
    category_confidence: Mapped[float] = mapped_column(
        DECIMAL(3, 2),
        default=0.5,
        comment="类别检测置信度"
    )
    
    # === 处理状态字段 ===
    last_processed_at: Mapped[Optional[datetime]] = mapped_column(
        TIMESTAMP,
        comment="最后处理时间"
    )
    
    # 关联关系 - 延迟到需要时再定义，避免循环导入
    # category: Mapped[Optional["MaterialCategory"]] = relationship(...)
    # unit: Mapped[Optional["MeasurementUnit"]] = relationship(...)
    
    def __repr__(self) -> str:
        return f"<MaterialsMaster(erp_code='{self.erp_code}', name='{self.material_name}')>"


class MaterialCategory(Base, TimestampMixin, SyncStatusMixin):
    """
    物料分类主数据表
    
    完全基于Oracle bd_marbasclass表结构设计
    对应design.md第2.3节material_categories表定义
    """
    
    __tablename__ = "material_categories"
    
    # 主键
    id: Mapped[int] = mapped_column(primary_key=True, comment="主键ID")
    
    # === Oracle bd_marbasclass字段映射 ===
    oracle_category_id: Mapped[str] = mapped_column(
        String(20),
        unique=True,
        nullable=False,
        comment="Oracle分类主键 (bd_marbasclass.pk_marbasclass)"
    )
    
    category_code: Mapped[str] = mapped_column(
        String(40),
        nullable=False,
        comment="分类编码 (bd_marbasclass.code)"
    )
    
    category_name: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
        comment="分类名称 (bd_marbasclass.name)"
    )
    
    parent_category_id: Mapped[Optional[str]] = mapped_column(
        String(20),
        comment="父分类ID (bd_marbasclass.pk_parent)"
    )
    
    enable_state: Mapped[int] = mapped_column(
        Integer,
        default=2,
        comment="启用状态 (bd_marbasclass.enablestate)"
    )
    
    inner_code: Mapped[Optional[str]] = mapped_column(
        String(200),
        comment="内部编码 (bd_marbasclass.innercode)"
    )
    
    # === Oracle成本和提前期字段 ===
    average_cost: Mapped[Optional[float]] = mapped_column(
        DECIMAL(28, 8),
        comment="平均成本 (bd_marbasclass.averagecost)"
    )
    
    average_mma_ahead: Mapped[Optional[int]] = mapped_column(
        Integer,
        comment="平均MMA提前期 (bd_marbasclass.averagemmahead)"
    )
    
    average_pur_ahead: Mapped[Optional[int]] = mapped_column(
        Integer,
        comment="平均采购提前期 (bd_marbasclass.averagepurahead)"
    )
    
    avg_price: Mapped[Optional[float]] = mapped_column(
        DECIMAL(28, 8),
        comment="平均价格 (bd_marbasclass.avgprice)"
    )
    
    # === Oracle时间字段 ===
    oracle_created_time: Mapped[Optional[datetime]] = mapped_column(
        TIMESTAMP,
        comment="Oracle创建时间 (bd_marbasclass.creationtime)"
    )
    
    oracle_modified_time: Mapped[Optional[datetime]] = mapped_column(
        TIMESTAMP,
        comment="Oracle修改时间 (bd_marbasclass.modifiedtime)"
    )
    
    # === 查重系统扩展字段 ===
    detection_keywords: Mapped[Optional[List[str]]] = mapped_column(
        ARRAY(String),
        comment="智能检测关键词数组"
    )
    
    category_description: Mapped[Optional[str]] = mapped_column(
        Text,
        comment="分类描述"
    )
    
    processing_rules: Mapped[Dict[str, Any]] = mapped_column(
        JSONB,
        default=dict,
        comment="类别特定的处理规则配置"
    )
    
    category_level: Mapped[int] = mapped_column(
        Integer,
        default=1,
        comment="分类层级"
    )
    
    full_path: Mapped[Optional[str]] = mapped_column(
        String(500),
        comment="完整分类路径"
    )
    
    def __repr__(self) -> str:
        return f"<MaterialCategory(code='{self.category_code}', name='{self.category_name}')>"


class KnowledgeCategory(Base, TimestampMixin):
    """
    AI知识库分类表
    
    存储基于Oracle真实数据动态生成的分类关键词
    用于物料智能检测和分类
    与material_categories（Oracle ERP分类）区分
    """
    
    __tablename__ = "knowledge_categories"
    
    # 主键
    id: Mapped[int] = mapped_column(primary_key=True, comment="主键ID")
    
    # 分类信息
    category_name: Mapped[str] = mapped_column(
        String(100),
        unique=True,
        nullable=False,
        index=True,
        comment="分类名称（来自Oracle真实数据）"
    )
    
    # 检测关键词（数组类型）
    keywords: Mapped[List[str]] = mapped_column(
        ARRAY(String),
        nullable=False,
        comment="检测关键词列表（基于词频统计生成）"
    )
    
    # 检测配置
    detection_confidence: Mapped[float] = mapped_column(
        DECIMAL(3, 2),
        default=0.8,
        comment="检测置信度阈值"
    )
    
    category_type: Mapped[str] = mapped_column(
        String(50),
        default='general',
        comment="分类类型（general/specific）"
    )
    
    priority: Mapped[int] = mapped_column(
        default=50,
        comment="优先级（用于多分类匹配时的排序）"
    )
    # 激活状态
    is_active: Mapped[bool] = mapped_column(
        default=True,
        index=True,
        comment="是否激活"
    )
    
    # 创建者
    created_by: Mapped[str] = mapped_column(
        String(50),
        default='system',
        comment="创建者"
    )
    
    def __repr__(self) -> str:
        return f"<KnowledgeCategory(name='{self.category_name}', keywords_count={len(self.keywords) if self.keywords else 0})>"


class MeasurementUnit(Base, TimestampMixin, SyncStatusMixin):
    """
    计量单位主数据表
    
    完全基于Oracle bd_measdoc表结构设计
    对应design.md第2.3节measurement_units表定义
    """
    
    __tablename__ = "measurement_units"
    
    # 主键
    id: Mapped[int] = mapped_column(primary_key=True, comment="主键ID")
    
    # === Oracle bd_measdoc字段映射 ===
    oracle_unit_id: Mapped[str] = mapped_column(
        String(20),
        unique=True,
        nullable=False,
        comment="Oracle单位主键 (bd_measdoc.pk_measdoc)"
    )
    
    unit_code: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        comment="单位编码 (bd_measdoc.code)"
    )
    
    unit_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        comment="单位名称 (bd_measdoc.name)"
    )
    
    english_name: Mapped[Optional[str]] = mapped_column(
        String(100),
        comment="英文名称 (bd_measdoc.ename)"
    )
    
    enable_state: Mapped[int] = mapped_column(
        Integer,
        default=2,
        comment="启用状态 (bd_measdoc.enablestate)"
    )
    
    # === Oracle时间字段 ===
    oracle_created_time: Mapped[Optional[datetime]] = mapped_column(
        TIMESTAMP,
        comment="Oracle创建时间 (bd_measdoc.creationtime)"
    )
    
    oracle_modified_time: Mapped[Optional[datetime]] = mapped_column(
        TIMESTAMP,
        comment="Oracle修改时间 (bd_measdoc.modifiedtime)"
    )
    
    # === 查重系统扩展字段 ===
    unit_type: Mapped[Optional[str]] = mapped_column(
        String(50),
        comment="单位类型（重量、长度、体积等）"
    )
    
    conversion_factor: Mapped[Optional[float]] = mapped_column(
        DECIMAL(10, 6),
        comment="换算系数（相对于基础单位）"
    )
    
    def __repr__(self) -> str:
        return f"<MeasurementUnit(code='{self.unit_code}', name='{self.unit_name}')>"


# === 数据库索引定义 ===
# 对应 [I.3] - pg_trgm并发创建策略的索引设计

# 物料查询性能索引 - 对应 [T.3] 性能测试≤500ms要求
Index('idx_materials_normalized_name_trgm', MaterialsMaster.normalized_name, postgresql_using='gin', postgresql_ops={'normalized_name': 'gin_trgm_ops'})
Index('idx_materials_full_description_trgm', MaterialsMaster.full_description, postgresql_using='gin', postgresql_ops={'full_description': 'gin_trgm_ops'})
Index('idx_materials_attributes_gin', MaterialsMaster.attributes, postgresql_using='gin')
Index('idx_materials_erp_code', MaterialsMaster.erp_code)
Index('idx_materials_category_confidence', MaterialsMaster.detected_category, MaterialsMaster.category_confidence.desc())
Index('idx_materials_enable_state', MaterialsMaster.enable_state)

# 分类查询索引
Index('idx_categories_code', MaterialCategory.category_code)
Index('idx_categories_oracle_id', MaterialCategory.oracle_category_id)
Index('idx_categories_enable_state', MaterialCategory.enable_state)

# 单位查询索引
Index('idx_units_code', MeasurementUnit.unit_code)
Index('idx_units_oracle_id', MeasurementUnit.oracle_unit_id)
Index('idx_units_enable_state', MeasurementUnit.enable_state)


# ==================================================================================
# 知识库管理表 (Knowledge Base Tables)
# 对应 Task 1.1重构 - 用于存储从database/生成的规则和词典数据
# 
# 注意: material_categories表已经包含detection_keywords字段用于AI检测
# 不需要单独的knowledge_categories表
# ==================================================================================


class ExtractionRule(Base, TimestampMixin):
    """
    属性提取规则表
    
    存储从database/material_knowledge_generator.py生成的标准化提取规则
    对应文件: database/standardized_extraction_rules_*.json
    对应 [Task 1.1重构] - 规则管理表补充
    符合Design.md的表结构定义
    """
    
    __tablename__ = "extraction_rules"
    
    # 主键 - 使用SERIAL自增主键
    # 符合Design.md: id SERIAL PRIMARY KEY
    id: Mapped[int] = mapped_column(
        primary_key=True,
        autoincrement=True,
        comment="主键ID"
    )
    
    # === 从JSON文件映射的字段 ===
    # 严格对应database/material_knowledge_generator.py的输出格式
    rule_name: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        comment="规则名称 (如: 尺寸规格提取)"
    )
    
    material_category: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True,
        comment="物料类别 (如: GENERAL, FASTENER)"
    )
    
    attribute_name: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        index=True,
        comment="属性名称 (如: size_specification)"
    )
    
    regex_pattern: Mapped[str] = mapped_column(
        Text,
        nullable=False,
        comment="正则表达式模式 (支持全角半角)"
    )
    
    priority: Mapped[Optional[int]] = mapped_column(
        Integer,
        comment="优先级 (数值越大优先级越高)"
    )
    
    confidence: Mapped[Optional[float]] = mapped_column(
        DECIMAL(10, 2),
        comment="置信度 (0.0-1.0)"
    )
    
    # 新增字段 - 符合Design.md
    is_active: Mapped[Optional[bool]] = mapped_column(
        Boolean,
        default=True,
        comment="是否激活"
    )
    
    version: Mapped[Optional[int]] = mapped_column(
        Integer,
        default=1,
        comment="版本号"
    )
    
    description: Mapped[Optional[str]] = mapped_column(
        Text,
        comment="规则描述"
    )
    
    example_input: Mapped[Optional[str]] = mapped_column(
        Text,
        comment="示例输入"
    )
    
    example_output: Mapped[Optional[str]] = mapped_column(
        Text,
        comment="示例输出"
    )
    
    created_by: Mapped[Optional[str]] = mapped_column(
        String(50),
        default='system',
        comment="创建者"
    )
    
    def __repr__(self) -> str:
        return f"<ExtractionRule(id={self.id}, name='{self.rule_name}')>"


class Synonym(Base, TimestampMixin):
    """
    同义词词典表
    
    存储从database/material_knowledge_generator.py生成的标准化同义词词典
    对应文件: database/standardized_synonym_records_*.json
    对应 [Task 1.1重构] - 同义词管理表补充
    符合Design.md的表结构定义
    
    关联测试点 (Associated Test Points):
    - [T.1.5] - 本模型实现双向同义词映射逻辑
    - [T.2.5] - 本模型支持特殊字符处理
    """
    
    __tablename__ = "synonyms"
    
    # 主键 - 使用自增ID
    # 符合Design.md: id SERIAL PRIMARY KEY
    id: Mapped[int] = mapped_column(
        primary_key=True,
        autoincrement=True,
        comment="主键ID"
    )
    
    # === 同义词映射字段 ===
    # 注意：字段名从synonym_term改为original_term以符合Design.md
    original_term: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
        index=True,
        comment="原始词汇（同义词）"
    )
    
    standard_term: Mapped[str] = mapped_column(
        String(200),
        nullable=False,
        index=True,
        comment="标准词汇"
    )
    
    category: Mapped[Optional[str]] = mapped_column(
        String(50),
        index=True,
        comment="词汇类别"
    )
    
    synonym_type: Mapped[Optional[str]] = mapped_column(
        String(50),
        default='general',
        comment="同义词类型 (brand/material/size/unit等)"
    )
    
    confidence: Mapped[Optional[float]] = mapped_column(
        DECIMAL(10, 2),
        default=1.0,
        comment="映射置信度"
    )
    
    # 新增字段 - 符合Design.md
    is_active: Mapped[Optional[bool]] = mapped_column(
        Boolean,
        default=True,
        comment="是否激活"
    )
    
    created_by: Mapped[str] = mapped_column(
        String(50),
        default='system',
        comment="创建者"
    )
    
    def __repr__(self) -> str:
        return f"<Synonym('{self.original_term}' -> '{self.standard_term}')>"


# === 知识库表索引定义 ===
# 对应 [T.1] - 核心功能路径测试的索引需求

# 提取规则查询索引
Index('idx_extraction_rules_category', ExtractionRule.material_category)
Index('idx_extraction_rules_attribute', ExtractionRule.attribute_name)
Index('idx_extraction_rules_priority', ExtractionRule.priority.desc())

# 同义词查询优化索引 - 对应 [I.3] 为什么需要组合索引：
# 同义词查找是高频操作，需要支持 (original_term, standard_term) 的快速查找
Index('idx_synonym_lookup', Synonym.original_term, Synonym.standard_term)
Index('idx_synonym_standard', Synonym.standard_term)
Index('idx_synonym_category', Synonym.category)
