# PostgreSQL导入脚本使用说明

## 生成的文件
- **SQL脚本**: `postgresql_import_20251002_185603.sql`
- **使用说明**: `postgresql_import_usage_20251002_185603.md`

## 使用方法

### 方法1: 直接执行SQL脚本
```bash
# 使用psql执行
psql -h localhost -U matmatch -d matmatch -f postgresql_import_20251002_185603.sql

# 或者连接后执行
psql -h localhost -U matmatch -d matmatch
\i postgresql_import_20251002_185603.sql
```

### 方法2: 分步执行
```bash
# 1. 连接数据库
psql -h localhost -U matmatch -d matmatch

# 2. 执行脚本
\i postgresql_import_20251002_185603.sql

# 3. 验证结果
SELECT COUNT(*) FROM extraction_rules;
SELECT COUNT(*) FROM synonyms;
SELECT COUNT(*) FROM material_categories;
```

## 导入内容

### 提取规则 (6条)
基于真实Oracle数据生成的高质量提取规则，包括：
- 公制尺寸规格提取 (置信度95%)
- 螺纹规格提取 (置信度98%)
- 材质类型提取 (置信度92%)
- 品牌名称提取 (置信度88%)
- 压力等级提取 (置信度90%)
- 公称直径提取 (置信度95%)

### 同义词典 (3347条)
包含以下类型的同义词：
- 材质同义词 (304↔不锈钢等)
- 单位同义词 (mm↔毫米等)
- 规格同义词 (×↔x等)
- 品牌同义词 (基于真实数据)

### 类别关键词 (1243个)
基于1,243个真实物料类别生成的关键词，支持：
- 智能类别检测
- 多层级分类
- 置信度评分

## 验证导入成功

执行以下查询验证导入结果：
```sql
-- 检查记录数
SELECT COUNT(*) FROM extraction_rules;    -- 应该显示 6
SELECT COUNT(*) FROM synonyms;           -- 应该显示 3347
SELECT COUNT(*) FROM material_categories; -- 应该显示 1243

-- 测试规则
SELECT rule_name, confidence FROM extraction_rules ORDER BY priority DESC;

-- 测试同义词
SELECT standard_term FROM synonyms WHERE original_term = '304';

-- 测试类别
SELECT category_name FROM material_categories WHERE '螺栓' = ANY(keywords);
```

## 故障排除

如果遇到问题：
1. 检查PostgreSQL服务是否运行
2. 确认数据库连接参数正确
3. 检查用户权限是否足够
4. 查看错误日志获取详细信息

生成时间: 2025-10-02 18:56:03
数据来源: Oracle ERP系统 (230,421条物料数据)
