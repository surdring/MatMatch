@echo off
SET PGPASSWORD=xqxatcdj
echo 列出matmatch数据库中的所有表...
echo.
"D:\Program Files\PostgreSQL\18\bin\psql.exe" -h 127.0.0.1 -p 5432 -U postgres -d matmatch -c "\dt"
echo.
echo 检查每个表的记录数...
"D:\Program Files\PostgreSQL\18\bin\psql.exe" -h 127.0.0.1 -p 5432 -U postgres -d matmatch -c "SELECT schemaname,tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;"
SET PGPASSWORD=

