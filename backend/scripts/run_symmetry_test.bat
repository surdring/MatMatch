@echo off
REM Backend对称性测试脚本
REM 
REM 执行流程:
REM 1. 清空数据库
REM 2. 使用Python异步导入知识库
REM 3. 验证对称性

echo ================================================================================
echo Backend 对称性测试
echo ================================================================================
echo.

REM 切换到backend目录
cd /d %~dp0..

echo [步骤 1/3] 设置Python环境...
REM 使用anaconda3的Python（与database脚本保持一致）
set PYTHON_EXE=C:\anaconda3\python.exe

if exist "%PYTHON_EXE%" (
    echo   ✓ 使用 %PYTHON_EXE%
) else (
    echo   ✗ 未找到 %PYTHON_EXE%，请检查安装路径
    pause
    exit /b 1
)

echo.
echo [步骤 2/3] 执行Python异步导入...
python scripts\import_knowledge_base.py --data-dir ../database --clear
if %ERRORLEVEL% neq 0 (
    echo   ✗ 导入失败！
    pause
    exit /b 1
)

echo.
echo [步骤 3/3] 验证对称性...
python scripts\verify_symmetry.py
if %ERRORLEVEL% neq 0 (
    echo   ✗ 对称性验证失败！
    pause
    exit /b 1
)

echo.
echo ================================================================================
echo ✓ 对称性测试完成！
echo ================================================================================
pause

