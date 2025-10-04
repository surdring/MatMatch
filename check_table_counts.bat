@echo off
SET PGPASSWORD=xqxatcdj
echo 检查各表的数据量...
echo.
"D:\Program Files\PostgreSQL\18\bin\psql.exe" -h 127.0.0.1 -p 5432 -U postgres -d matmatch -c "SELECT 'synonyms' as table_name, COUNT(*) as record_count FROM synonyms UNION ALL SELECT 'extraction_rules', COUNT(*) FROM extraction_rules UNION ALL SELECT 'knowledge_categories', COUNT(*) FROM knowledge_categories UNION ALL SELECT 'materials_master', COUNT(*) FROM materials_master UNION ALL SELECT 'material_categories', COUNT(*) FROM material_categories UNION ALL SELECT 'measurement_units', COUNT(*) FROM measurement_units ORDER BY table_name;"
SET PGPASSWORD=

