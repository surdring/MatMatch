@echo off
echo ========================================
echo PostgreSQL规则和词典快速导入工具
echo ========================================
echo.

:: 设置环境变量
set PG_HOST=localhost
set PG_PORT=5432
set PG_DATABASE=matmatch
set PG_USERNAME=matmatch
set PG_PASSWORD=matmatch

echo 🔧 环境配置:
echo   数据库主机: %PG_HOST%
echo   数据库端口: %PG_PORT%
echo   数据库名称: %PG_DATABASE%
echo   用户名: %PG_USERNAME%
echo.

echo 📋 检查必要文件...
if not exist "standardized_extraction_rules_*.json" (
    echo ❌ 未找到标准化提取规则文件
    echo 💡 请先运行: python generate_standardized_rules.py
    pause
    exit /b 1
)

if not exist "standardized_synonym_dictionary_*.json" (
    echo ❌ 未找到标准化同义词典文件
    echo 💡 请先运行: python generate_standardized_rules.py
    pause
    exit /b 1
)

if not exist "standardized_category_keywords_*.json" (
    echo ❌ 未找到标准化类别关键词文件
    echo 💡 请先运行: python generate_standardized_rules.py
    pause
    exit /b 1
)

echo ✅ 所有必要文件已找到
echo.

echo 🚀 开始导入规则和词典...
C:\anaconda3\python import_to_postgresql.py

if %ERRORLEVEL% EQU 0 (
    echo.
    echo 🎉 导入成功完成！
    echo.
    echo 📊 您现在可以使用以下命令验证导入结果:
    echo   psql -h %PG_HOST% -U %PG_USERNAME% -d %PG_DATABASE%
    echo   然后执行: SELECT COUNT(*) FROM extraction_rules;
    echo.
) else (
    echo.
    echo ❌ 导入失败，请检查错误信息
    echo.
)

pause
