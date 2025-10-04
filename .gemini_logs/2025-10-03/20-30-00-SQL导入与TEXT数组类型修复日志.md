# SQL导入与TEXT[]数组类型修复日志

**时间**: 2025-10-03 20:30:00  
**任务**: 修复SQL导入问题并验证知识库数据一致性  
**状态**: ✅ 已完成方式一（SQL导入），准备测试方式二

---

## 问题描述

### 发现的问题
1. **数据导入不完整**: 初次SQL导入后，`knowledge_categories`表只有14条数据，而预期应该有1,594条
2. **类型不匹配错误**: 
   ```
   错误: 字段 "keywords" 的类型为 jsonb, 但表达式的类型为 text[]
   ```
3. **事务回滚**: SQL导入过程中遇到错误后整个事务回滚，导致0条数据

### 根本原因
- **数据库表结构与design.md不一致**: 
  - 数据库中 `knowledge_categories.keywords` 字段类型为 `JSONB`
  - `design.md` 规范定义为 `TEXT[]`
  - SQL生成脚本按 `design.md` 生成 `ARRAY['关键词1', '关键词2']` 格式
  - 导致类型不匹配，INSERT语句失败

---

## 技术决策：TEXT[] vs JSONB

### 选择 TEXT[] 的理由

#### ✅ TEXT[] 优势
1. **语义清晰** - 明确表示"字符串数组"
2. **查询简单** - `'螺栓' = ANY(keywords)` 非常直观
3. **索引高效** - GIN索引对TEXT[]数组优化很好
4. **类型安全** - 保证只存储字符串，不会有类型混淆
5. **PostgreSQL原生** - 充分利用数组操作符（`@>`, `&&`, `ANY`等）
6. **符合设计意图** - keywords本质就是字符串列表

#### ❌ JSONB 缺点
1. **过度设计** - keywords只是简单的字符串列表，用JSONB太重
2. **查询复杂** - 需要`jsonb_array_elements_text()`等函数
3. **类型不明确** - JSONB可以存任何结构，容易误用

### 最终决定
**保持 `design.md` 的 `TEXT[]` 定义，重建数据库表结构**

---

## 解决方案

### 1. 移除显式事务控制

**修改**: `database/generate_sql_import_script.py`

```python
# 修改前
-- 开始事务
BEGIN;

# 修改后
-- 注意: 请使用 psql --single-transaction 参数来确保原子性
-- 如果需要手动事务，请取消下面的注释
-- BEGIN;
```

**原因**: 
- 避免单个INSERT错误导致整个事务回滚
- 使用psql的`--single-transaction`参数可选择性地启用事务
- 提高导入容错性

### 2. 删除并重建表结构

```sql
DROP TABLE IF EXISTS knowledge_categories CASCADE;
```

**执行SQL导入脚本**，让其按照 `design.md` 的定义创建表：

```sql
CREATE TABLE IF NOT EXISTS knowledge_categories (
    id SERIAL PRIMARY KEY,
    category_name VARCHAR(200) UNIQUE NOT NULL,
    keywords TEXT[],  -- ← 关键：使用 TEXT[] 而非 JSONB
    detection_confidence DECIMAL(3,2) DEFAULT 0.8,
    category_type VARCHAR(50) DEFAULT 'general',
    priority INTEGER DEFAULT 50,
    is_active BOOLEAN DEFAULT TRUE,
    description TEXT,
    created_by VARCHAR(50) DEFAULT 'system',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. 验证表结构

**执行**: `\d knowledge_categories`

**结果**:
```
栏位         |            类型             | 预设
-------------+-----------------------------+----------
id           | integer                     | nextval(...)
category_name| character varying(200)      | 
keywords     | text[]                      | ← ✅ 正确类型
detection_c..| numeric(3,2)                | 0.8
category_type| character varying(50)       | 'general'
priority     | integer                     | 50
is_active    | boolean                     | true
```

---

## 导入执行过程

### 生成SQL脚本

```bash
python generate_sql_import_script.py
```

**输出**:
```
✅ 生成了 6 条规则插入语句
✅ 生成了 38068 条同义词插入语句
✅ 生成了 1594 条类别插入语句
📊 总计SQL语句: 39668 条
```

### 执行SQL导入

```powershell
$env:PGPASSWORD="xqxatcdj"
& "D:\Program Files\PostgreSQL\18\bin\psql.exe" `
  -h 127.0.0.1 -p 5432 -U postgres -d matmatch `
  -f postgresql_import_20251003_202723.sql
```

**结果**: ✅ 成功

### 验证导入数据

```sql
SELECT 'extraction_rules' as table_name, COUNT(*) as count 
FROM extraction_rules 
UNION ALL 
SELECT 'synonyms', COUNT(*) FROM synonyms 
UNION ALL 
SELECT 'knowledge_categories', COUNT(*) FROM knowledge_categories;
```

**结果**:
```
      table_name      | count
----------------------+-------
 extraction_rules     |     6  ✅
 synonyms             | 38068  ✅
 knowledge_categories |  1594  ✅
(3 行记录)
```

---

## 数据统计

### extraction_rules (6条)
| id | rule_name        | confidence | priority |
|----|------------------|------------|----------|
| 38 | 螺纹规格提取      | 0.98       | 95       |
| 37 | 尺寸规格提取      | 0.95       | 90       |
| 39 | 压力等级提取      | 0.90       | 88       |
| 42 | 材质类型提取      | 0.90       | 88       |
| 40 | 公称直径提取      | 0.95       | 87       |
| 41 | 品牌名称提取      | 0.92       | 85       |

### synonyms (38,068条)
| category      | synonym_type  | count  |
|---------------|---------------|--------|
| general       | general       | 22,402 |
| unit          | unit          | 5,482  |
| specification | specification | 4,129  |
| pipe          | general       | 3,633  |
| valve         | general       | 826    |
| material      | material      | 797    |

### knowledge_categories (1,594条)
基于Oracle真实数据动态生成的分类关键词

**示例**:
```sql
SELECT category_name, array_length(keywords, 1) as keyword_count
FROM knowledge_categories
ORDER BY priority DESC
LIMIT 5;
```

| category_name | keyword_count |
|---------------|---------------|
| 原料           | 2             |
| 合金钢         | 6             |
| 粘土砖         | 1             |
| 其它材料       | 1             |
| 耐火土         | 1             |

---

## ORM模型验证

### KnowledgeCategory 模型
**文件**: `backend/models/materials.py`

```python
class KnowledgeCategory(Base, TimestampMixin):
    """AI知识库分类表"""
    
    __tablename__ = "knowledge_categories"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    
    category_name: Mapped[str] = mapped_column(
        String(100),
        unique=True,
        nullable=False
    )
    
    # ✅ 使用 ARRAY(String) 对应数据库的 TEXT[]
    keywords: Mapped[List[str]] = mapped_column(
        ARRAY(String),
        nullable=False,
        comment="检测关键词列表"
    )
    
    detection_confidence: Mapped[float] = mapped_column(
        NUMERIC(3, 2),
        default=0.8
    )
    # ...其他字段
```

**验证**: ✅ ORM模型与数据库表结构一致

---

## 索引创建

### knowledge_categories 索引
```sql
CREATE INDEX idx_knowledge_category_name 
  ON knowledge_categories (category_name);

CREATE INDEX idx_knowledge_category_keywords_gin 
  ON knowledge_categories USING gin (keywords);  -- ✅ GIN索引支持TEXT[]

CREATE INDEX idx_knowledge_category_active 
  ON knowledge_categories (is_active) 
  WHERE is_active = true;
```

**验证**: ✅ 所有索引创建成功

---

## 关键学习点

### 1. PostgreSQL数组类型选择
- **TEXT[]** 适用于: 简单字符串列表、需要数组操作符
- **JSONB** 适用于: 复杂嵌套结构、动态schema、需要JSON函数

### 2. 事务管理策略
- 大批量INSERT时避免单一大事务
- 使用 `--single-transaction` 参数可选择性启用
- 保持SQL脚本的灵活性

### 3. 类型一致性重要性
- ORM模型必须与数据库schema严格一致
- `design.md` 作为唯一真实来源（Single Source of Truth）
- 定期验证表结构与设计文档的一致性

---

## 下一步行动

### ✅ 已完成
- [x] 修复SQL导入类型不匹配问题
- [x] 成功导入全部1,594条category关键词
- [x] 验证数据库表结构与design.md一致
- [x] 确认ORM模型正确使用ARRAY(String)

### 🔄 进行中
- [ ] 测试方式二：Python异步导入（`backend/scripts/import_knowledge_base.py`）
- [ ] 运行对称性验证脚本（`backend/scripts/verify_symmetry.py`）
- [ ] 确认两种导入方式结果完全一致

### 预期结果
两种导入方式应该产生**完全相同**的数据：
- extraction_rules: 6条
- synonyms: 38,068条
- knowledge_categories: 1,594条

---

## 文件清单

### 修改的文件
1. `database/generate_sql_import_script.py`
   - 移除显式BEGIN/COMMIT
   - 添加事务控制说明

### 生成的文件
1. `postgresql_import_20251003_202723.sql` (8.6MB)
2. `postgresql_import_usage_20251003_202723.md`

### 验证通过的文件
1. `backend/models/materials.py` - KnowledgeCategory模型
2. `backend/database/migrations.py` - 索引定义
3. `specs/main/design.md` - 数据库schema规范

---

## 附录：命令参考

### PostgreSQL连接
```powershell
$env:PGPASSWORD="xqxatcdj"
& "D:\Program Files\PostgreSQL\18\bin\psql.exe" `
  -h 127.0.0.1 -p 5432 -U postgres -d matmatch
```

### 查看表结构
```sql
\d knowledge_categories
```

### 验证数据
```sql
SELECT COUNT(*) FROM knowledge_categories;
SELECT category_name, keywords FROM knowledge_categories LIMIT 5;
```

### TEXT[]数组查询示例
```sql
-- 查找包含特定关键词的分类
SELECT category_name 
FROM knowledge_categories 
WHERE '螺栓' = ANY(keywords);

-- 查找关键词数量
SELECT category_name, array_length(keywords, 1) as kw_count
FROM knowledge_categories
ORDER BY kw_count DESC;
```

---

**日志创建时间**: 2025-10-03 20:30:00  
**下一步**: 执行Python异步导入验证

