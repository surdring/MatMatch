# 添加knowledge_categories表并验证导入对称性

**时间**: 2025-10-03 19:55:00  
**任务**: 区分Oracle ERP分类和AI知识库分类，添加独立的knowledge_categories表

---

## 📋 任务背景

用户要求：
> 添加分类关键词表knowledge_categories区分oracle中的物料分类表material_categories，并导入postgresql数据库

### 核心需求
1. **表分离**: 将Oracle ERP分类（`material_categories`）和AI生成的知识库分类（`knowledge_categories`）分开存储
2. **数据导入**: 将`material_knowledge_generator.py`生成的1594个分类关键词导入新表
3. **对称验证**: 确保SQL导入和Python异步导入两种方式结果一致

---

## 🔧 实施步骤

### 1️⃣ 更新Backend模型 (`backend/models/materials.py`)

**添加KnowledgeCategory模型**:
```python
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
    
    # 数据来源标识
    data_source: Mapped[str] = mapped_column(
        String(50),
        default='oracle_real_data',
        comment="数据来源标识"
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
```

### 2️⃣ 更新数据库迁移脚本 (`backend/database/migrations.py`)

**添加索引创建逻辑**:
```python
# 知识库类别表索引 - 对应 [T.1.6] 类别导入测试
"""
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_knowledge_category_name 
ON knowledge_categories (category_name)
""",

"""
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_knowledge_category_keywords_gin 
ON knowledge_categories USING gin (keywords)
""",

"""
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_knowledge_category_active 
ON knowledge_categories (is_active) WHERE is_active = true
""",
```

**添加表验证**:
```python
"SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'knowledge_categories'",
```

### 3️⃣ 更新Design.md (`specs/main/design.md`)

**添加表定义**:
```sql
-- AI知识库分类表（区分于Oracle ERP分类）
CREATE TABLE knowledge_categories (
    id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL, -- 分类名称（来自Oracle真实数据动态生成）
    keywords TEXT[] NOT NULL, -- 检测关键词数组（基于词频统计）
    detection_confidence DECIMAL(3,2) DEFAULT 0.8, -- 检测置信度阈值
    category_type VARCHAR(50) DEFAULT 'general', -- 分类类型
    priority INTEGER DEFAULT 50, -- 优先级（用于多分类匹配排序）
    data_source VARCHAR(50) DEFAULT 'oracle_real_data', -- 数据来源标识
    is_active BOOLEAN DEFAULT TRUE, -- 是否激活
    created_by VARCHAR(50) DEFAULT 'system',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**添加索引**:
```sql
-- AI知识库分类索引
CREATE INDEX idx_knowledge_category_name ON knowledge_categories (category_name);
CREATE INDEX idx_knowledge_category_keywords_gin ON knowledge_categories USING gin (keywords);
CREATE INDEX idx_knowledge_category_active ON knowledge_categories (is_active) WHERE is_active = TRUE;
```

### 4️⃣ 更新SQL导入脚本 (`database/generate_sql_import_script.py`)

**全局替换**:
- `INSERT INTO material_categories` → `INSERT INTO knowledge_categories`
- `CREATE TABLE material_categories` → `CREATE TABLE knowledge_categories`
- `DELETE FROM material_categories` → `DELETE FROM knowledge_categories`
- `FROM material_categories` → `FROM knowledge_categories`
- 索引名称更新：`idx_categories_*` → `idx_knowledge_category_*`

**验证查询更新**:
```sql
SELECT 'knowledge_categories' as table_name, COUNT(*) as record_count 
FROM knowledge_categories WHERE is_active = TRUE;
```

### 5️⃣ 更新Python异步导入脚本 (`backend/scripts/import_knowledge_base.py`)

**模型导入更新**:
```python
from backend.models.materials import ExtractionRule, Synonym, KnowledgeCategory
```

**插入语句更新**:
```python
sql = text("""
    INSERT INTO knowledge_categories 
    (category_name, keywords, detection_confidence, category_type, priority, is_active, created_by) 
    VALUES (:name, :keywords, :confidence, :type, :priority, true, 'system')
""")
```

**删除语句更新**:
```python
await session.execute(text("DELETE FROM knowledge_categories"))
```

**验证查询更新**:
```python
categories_result = await session.execute(
    text("SELECT COUNT(*) FROM knowledge_categories WHERE is_active = TRUE")
)
```

### 6️⃣ 更新对称性验证脚本 (`backend/scripts/verify_symmetry.py`)

**模型引用更新**:
```python
from backend.models.materials import ExtractionRule, Synonym, KnowledgeCategory
```

**字段名更新**:
- `MaterialCategory.detection_keywords` → `KnowledgeCategory.keywords`

---

## 📊 数据统计

### 生成的知识库数据
- **提取规则**: 6 条
- **同义词**: 38,068 条
- **分类关键词**: 1,594 个（基于Oracle真实数据动态生成）

### 分类关键词示例
```json
{
  "桥架": ["桥架"],
  "原料": ["热轧卷板", "原料"],
  "合金料": ["材质", "铝合金", "铝合金板", "钒氮合金", "VN", "合金料"]
}
```

---

## 🔍 表结构对比

### material_categories（Oracle ERP分类）
| 字段 | 类型 | 说明 |
|------|------|------|
| oracle_category_id | VARCHAR(20) | Oracle分类主键 |
| category_code | VARCHAR(40) | 分类编码 |
| category_name | VARCHAR(200) | 分类名称 |
| parent_category_id | VARCHAR(20) | 父分类ID |
| enable_state | INTEGER | 启用状态 |

### knowledge_categories（AI知识库分类）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | SERIAL PRIMARY KEY | 主键ID |
| category_name | VARCHAR(100) UNIQUE | 分类名称 |
| keywords | TEXT[] | 检测关键词数组 |
| detection_confidence | DECIMAL(3,2) | 检测置信度 |
| category_type | VARCHAR(50) | 分类类型 |
| priority | INTEGER | 优先级 |
| data_source | VARCHAR(50) | 数据来源标识 |
| is_active | BOOLEAN | 是否激活 |

---

## ✅ 验证检查清单

### SQL导入验证
- [x] 生成的SQL脚本使用`knowledge_categories`表
- [x] CREATE TABLE语句正确
- [x] INSERT语句正确
- [x] 索引创建语句正确
- [x] 验证查询使用正确的表名

### Python导入验证
- [x] 导入`KnowledgeCategory`模型
- [x] 使用`knowledge_categories`表进行插入
- [x] 删除操作使用正确的表名
- [x] 验证查询使用正确的表名

### 对称性验证
- [x] 两种导入方式使用相同的JSON数据源
- [x] 两种导入方式的字段映射一致
- [x] 两种导入方式的索引创建一致

---

## 🚀 下一步操作

### 1. 运行SQL导入（方式一）
```bash
cd database
quick_import_knowledge.bat
```

### 2. 运行Python异步导入（方式二）
```bash
cd backend
python scripts/import_knowledge_base.py --data-dir ../database --clear
```

### 3. 验证对称性
```bash
cd backend
python scripts/verify_symmetry.py
```

---

## 📝 关键改进

### 架构清晰化
1. **职责分离**: Oracle ERP数据（`material_categories`）与AI生成数据（`knowledge_categories`）分离
2. **数据溯源**: 每条知识库分类记录都有`data_source`字段标识来源
3. **灵活扩展**: 支持未来添加更多AI生成的知识库类型

### 数据质量
1. **真实数据驱动**: 1,594个分类关键词全部基于Oracle真实物料数据动态生成
2. **词频统计**: 使用高频关键词确保检测准确性
3. **置信度管理**: 每个分类都有独立的置信度配置

### 对称处理
1. **统一数据源**: SQL和Python两种导入方式使用完全相同的JSON文件
2. **一致性保证**: 字段映射、数据类型、索引创建完全一致
3. **可验证性**: 提供专门的验证脚本确保两种方式结果相同

---

## 🎯 总结

本次更新成功实现了以下目标：

1. ✅ **表分离**: 添加独立的`knowledge_categories`表，与Oracle ERP分类区分
2. ✅ **模型更新**: 在Backend添加`KnowledgeCategory` ORM模型
3. ✅ **SQL导入**: 更新SQL导入脚本以支持新表
4. ✅ **Python导入**: 更新Python异步导入脚本以支持新表
5. ✅ **文档更新**: 更新design.md添加表定义和索引
6. ✅ **验证准备**: 准备好对称性验证流程

**待完成任务**:
- 执行SQL导入测试
- 执行Python异步导入测试
- 运行对称性验证
- 确认两种导入方式结果完全一致

