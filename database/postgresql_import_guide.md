# PostgreSQL规则和词典导入指南

## 📋 前提条件

### 1. 确认PostgreSQL服务状态
```bash
# Windows
net start postgresql-x64-14

# 或检查服务状态
sc query postgresql-x64-14

# Linux/Mac
sudo systemctl status postgresql
```

### 2. 测试PostgreSQL连接
```bash
# 使用psql连接测试
psql -h localhost -U postgres -d postgres

# 或者使用项目配置测试
psql -h localhost -U matmatch -d matmatch
```

### 3. 创建项目数据库和用户（如果尚未创建）
```sql
-- 连接到PostgreSQL后执行
CREATE DATABASE matmatch;
CREATE USER matmatch WITH PASSWORD 'matmatch';
GRANT ALL PRIVILEGES ON DATABASE matmatch TO matmatch;
```

## 🚀 快速导入方法

### 方法1: 使用现有的初始化脚本（推荐）

```bash
# 进入database目录
cd database

# 设置环境变量
set PG_HOST=localhost
set PG_PORT=5432
set PG_DATABASE=matmatch
set PG_USERNAME=matmatch
set PG_PASSWORD=matmatch

# 运行初始化脚本
C:\anaconda3\python init_postgresql_rules.py
```

### 方法2: 使用一键设置脚本

```bash
# 运行一键设置（包含PostgreSQL初始化）
C:\anaconda3\python one_click_setup.py
```

## 🔧 动态SQL导入方法（推荐）

### 步骤1: 生成基于真实数据的SQL脚本

```bash
# 生成动态SQL导入脚本
C:\anaconda3\python generate_sql_import_script.py
```

这将生成：
- `postgresql_import_YYYYMMDD_HHMMSS.sql` - 完整的SQL导入脚本
- `postgresql_import_usage_YYYYMMDD_HHMMSS.md` - 详细使用说明

### 步骤2: 执行生成的SQL脚本

```bash
# 方法1: 直接执行SQL文件
psql -h localhost -U matmatch -d matmatch -f postgresql_import_YYYYMMDD_HHMMSS.sql

# 方法2: 连接后执行
psql -h localhost -U matmatch -d matmatch
\i postgresql_import_YYYYMMDD_HHMMSS.sql
```

### 生成的SQL脚本特点

✅ **完全基于真实数据**: 从标准化JSON文件动态生成  
✅ **包含所有数据**: 6条规则 + 3,347条同义词 + 1,243个类别  
✅ **事务安全**: 使用BEGIN/COMMIT确保数据一致性  
✅ **自动验证**: 内置验证查询检查导入结果  
✅ **完整索引**: 自动创建性能优化索引  

### 示例生成的SQL内容

```sql
-- 真实的提取规则（基于Oracle数据）
INSERT INTO extraction_rules (rule_id, rule_name, material_category, attribute_name, regex_pattern, priority, confidence, description, examples, data_source, created_by) VALUES (
    'size_spec_metric',
    '公制尺寸规格提取',
    'general',
    'size_specification',
    '(?:M|Φ|φ|DN)?(\d+(?:\.\d+)?[×*xX]\d+(?:\.\d+)?(?:[×*xX]\d+(?:\.\d+)?)?)',
    100,
    0.95,
    '基于20个真实尺寸样本，提取公制尺寸规格',
    ARRAY['1*20', 'M20*1.5', 'M24*1', 'M22*1', 'M22*1.5'],
    'oracle_real_data',
    'system'
);

-- 真实的同义词（基于Oracle数据变体分析）
INSERT INTO synonyms (original_term, standard_term, category, synonym_type, created_by) VALUES (
    '200*100',
    '200x100',
    'specification',
    'specification',
    'system'
);

-- 真实的类别关键词（基于1,243个Oracle分类）
INSERT INTO material_categories (category_name, keywords, detection_confidence, category_type, priority, created_by) VALUES (
    '高强度螺栓',
    ARRAY['高强螺丝', '级高强螺丝', '高强度螺栓', '高强螺丝'],
    0.8,
    'fastener',
    70,
    'system'
);
```

## 🔍 验证导入结果

```sql
-- 检查导入的数据
SELECT COUNT(*) as rule_count FROM extraction_rules WHERE is_active = TRUE;
SELECT COUNT(*) as synonym_count FROM synonyms WHERE is_active = TRUE;
SELECT COUNT(*) as category_count FROM material_categories WHERE is_active = TRUE;

-- 查看具体数据
SELECT rule_id, rule_name, confidence FROM extraction_rules ORDER BY priority DESC;
SELECT category, COUNT(*) as count FROM synonyms GROUP BY category;
SELECT category_name, array_length(keywords, 1) as keyword_count FROM material_categories ORDER BY priority DESC;
```

## 🧪 测试规则效果

```sql
-- 测试提取规则
SELECT rule_name, 
       regexp_matches('M20*1.5内六角螺栓304不锈钢', regex_pattern) as matches
FROM extraction_rules 
WHERE is_active = TRUE 
ORDER BY priority DESC;

-- 测试同义词查找
SELECT standard_term 
FROM synonyms 
WHERE original_term = '304' AND is_active = TRUE;

-- 测试类别检测
SELECT category_name, keywords 
FROM material_categories 
WHERE '螺栓' = ANY(keywords) AND is_active = TRUE;
```

## 📊 预期结果

成功导入后，您应该看到：
- ✅ **提取规则**: 6条 (置信度88%-98%)
- ✅ **同义词**: 数百个核心同义词
- ✅ **类别关键词**: 主要物料类别覆盖

## 🔧 故障排除

### 问题1: 连接失败
```bash
# 检查PostgreSQL服务
net start postgresql-x64-14

# 检查端口
netstat -an | findstr 5432
```

### 问题2: 权限不足
```sql
-- 授予权限
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO matmatch;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO matmatch;
```

### 问题3: 编码问题
```sql
-- 设置客户端编码
SET client_encoding = 'UTF8';
```

## 🎉 完成标志

当看到以下结果时，表示导入成功：
```sql
matmatch=# SELECT COUNT(*) FROM extraction_rules;
 count 
-------
     6

matmatch=# SELECT COUNT(*) FROM synonyms;
 count 
-------
   XXX

matmatch=# SELECT COUNT(*) FROM material_categories;
 count 
-------
    XX
```

现在您的PostgreSQL数据库已经包含了基于230,421条真实Oracle数据生成的高质量规则和词典！🚀
