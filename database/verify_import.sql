-- ========================================
-- 验证PostgreSQL数据导入结果
-- ========================================

-- 1. 检查表是否存在
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('extraction_rules', 'synonyms', 'material_categories')
ORDER BY table_name;

-- 2. 统计各表记录数
SELECT 'extraction_rules' as table_name, COUNT(*) as record_count 
FROM extraction_rules WHERE is_active = TRUE
UNION ALL
SELECT 'synonyms' as table_name, COUNT(*) as record_count 
FROM synonyms WHERE is_active = TRUE
UNION ALL
SELECT 'material_categories' as table_name, COUNT(*) as record_count 
FROM material_categories WHERE is_active = TRUE;

-- 3. 检查extraction_rules表结构和数据样例
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'extraction_rules'
ORDER BY ordinal_position;

-- 查看提取规则样例（前5条）
SELECT id, rule_name, material_category, attribute_name, priority, confidence, is_active
FROM extraction_rules
WHERE is_active = TRUE
ORDER BY priority DESC
LIMIT 5;

-- 4. 检查synonyms表结构和数据样例
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'synonyms'
ORDER BY ordinal_position;

-- 查看同义词样例（前10条）
SELECT id, original_term, standard_term, synonym_type, confidence
FROM synonyms
WHERE is_active = TRUE
LIMIT 10;

-- 按类型统计同义词
SELECT synonym_type, COUNT(*) as count
FROM synonyms
WHERE is_active = TRUE
GROUP BY synonym_type
ORDER BY count DESC;

-- 5. 检查material_categories表结构和数据样例
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'material_categories'
ORDER BY ordinal_position;

-- 查看分类关键词样例
SELECT category_name, category_type, priority, 
       jsonb_array_length(keywords) as keyword_count,
       keywords
FROM material_categories
WHERE is_active = TRUE
ORDER BY priority DESC;

-- 6. 验证索引是否创建成功
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename IN ('extraction_rules', 'synonyms', 'material_categories')
ORDER BY tablename, indexname;

