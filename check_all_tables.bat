@echo off
echo 检查所有表的数据量...
echo.
SET PGPASSWORD=xqxatcdj

echo ========================================
echo 知识库表（Task 1.1导入的）
echo ========================================
"D:\Program Files\PostgreSQL\18\bin\psql.exe" -h 127.0.0.1 -p 5432 -U postgres -d matmatch -c "SELECT 'synonyms' as table_name, COUNT(*) as count FROM synonyms UNION ALL SELECT 'attribute_extraction_rules', COUNT(*) FROM attribute_extraction_rules UNION ALL SELECT 'knowledge_categories', COUNT(*) FROM knowledge_categories;"

echo.
echo ========================================
echo 物料主数据表（Task 1.3需要ETL导入的）
echo ========================================
"D:\Program Files\PostgreSQL\18\bin\psql.exe" -h 127.0.0.1 -p 5432 -U postgres -d matmatch -c "SELECT 'materials_master' as table_name, COUNT(*) as count FROM materials_master;"

echo.
echo ========================================
echo ETL任务日志表
echo ========================================
"D:\Program Files\PostgreSQL\18\bin\psql.exe" -h 127.0.0.1 -p 5432 -U postgres -d matmatch -c "SELECT 'etl_job_logs' as table_name, COUNT(*) as count FROM etl_job_logs;"

SET PGPASSWORD=

