@echo off
chcp 65001 >nul
echo ================================================================================
echo MatMatch 定时数据同步任务
echo 执行时间: %date% %time%
echo ================================================================================
echo.

cd /d "%~dp0"

echo 📥 步骤1: 同步Oracle数据到PostgreSQL...
venv\Scripts\python.exe backend\scripts\run_etl_full_sync.py --batch-size 1000
if %errorlevel% neq 0 (
    echo ❌ 数据同步失败！
    exit /b 1
)
echo ✅ 数据同步完成
echo.

echo 🔧 步骤2: 重新生成知识库...
cd database
..\venv\Scripts\python.exe material_knowledge_generator.py
if %errorlevel% neq 0 (
    echo ❌ 知识库生成失败！
    cd ..
    exit /b 1
)
cd ..
echo ✅ 知识库生成完成
echo.

echo 📥 步骤3: 导入知识库到PostgreSQL...
venv\Scripts\python.exe quick_import_knowledge.py
if %errorlevel% neq 0 (
    echo ❌ 知识库导入失败！
    exit /b 1
)
echo ✅ 知识库导入完成
echo.

echo ================================================================================
echo 🎉 定时同步任务完成！
echo 完成时间: %date% %time%
echo ================================================================================
echo.

REM 记录日志
echo [%date% %time%] 定时同步任务完成 >> logs\sync_task.log


