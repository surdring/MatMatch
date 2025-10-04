@echo off
chcp 65001 >nul
echo ========================================
echo PostgreSQL 知识库数据导入脚本
echo ========================================
echo.

REM 设置PostgreSQL连接参数（与backend/core/config.py保持一致）
set PGHOST=127.0.0.1
set PGPORT=5432
set PGUSER=postgres
set PGDATABASE=matmatch
set PGPASSWORD=xqxatcdj

echo 📊 开始导入知识库数据...
echo.

REM 查找最新的SQL导入文件
for /f "delims=" %%i in ('dir /b /o-d postgresql_import_*.sql 2^>nul ^| findstr /v /c:"usage"') do (
    set SQL_FILE=%%i
    goto :found
)

:found
if not defined SQL_FILE (
    echo ❌ 错误: 未找到SQL导入文件
    echo 请先运行 python generate_sql_import_script.py 生成导入脚本
    pause
    exit /b 1
)

echo 🔍 使用SQL文件: %SQL_FILE%
echo.

REM 执行SQL导入
echo 正在导入数据到PostgreSQL...
psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -f %SQL_FILE%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✅ 导入成功！
    echo ========================================
    echo.
    echo 📊 验证导入结果...
    echo.
    
    REM 验证导入结果
    psql -h %PGHOST% -p %PGPORT% -U %PGUSER% -d %PGDATABASE% -c "SELECT 'extraction_rules' as table_name, COUNT(*) as count FROM extraction_rules UNION ALL SELECT 'synonyms', COUNT(*) FROM synonyms UNION ALL SELECT 'knowledge_categories', COUNT(*) FROM knowledge_categories;"
    
    echo.
    echo ========================================
) else (
    echo.
    echo ❌ 导入失败！错误代码: %ERRORLEVEL%
    echo.
)

pause

