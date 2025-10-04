@echo off
SET PGPASSWORD=xqxatcdj
"D:\Program Files\PostgreSQL\18\bin\psql.exe" -h 127.0.0.1 -p 5432 -U postgres -d matmatch -c "SELECT COUNT(*) as materials_count FROM materials_master;"
"D:\Program Files\PostgreSQL\18\bin\psql.exe" -h 127.0.0.1 -p 5432 -U postgres -d matmatch -c "SELECT COUNT(*) as processed_count FROM materials_master WHERE normalized_name IS NOT NULL;"
"D:\Program Files\PostgreSQL\18\bin\psql.exe" -h 127.0.0.1 -p 5432 -U postgres -d matmatch -c "SELECT id, erp_code, material_name, normalized_name, detected_category FROM materials_master LIMIT 5;"
SET PGPASSWORD=

