@echo off
REM ========================================
REM 完整的知识库导入和验证脚本（Windows批处理版本）
REM ========================================
REM 
REM 功能：
REM 1. 激活Python虚拟环境
REM 2. 运行完整的导入验证流程
REM 3. 生成测试报告
REM 
REM 使用方法：
REM     双击运行，或在命令行执行: run_full_verification.bat
REM 
REM ========================================

echo.
echo ========================================
echo   MatMatch 知识库完整导入验证
echo ========================================
echo.

REM 切换到database目录
cd /d "%~dp0"

REM 检查虚拟环境
if not exist "..\venv\Scripts\python.exe" (
    echo [错误] 未找到虚拟环境，请先运行: python -m venv venv
    pause
    exit /b 1
)

echo [信息] 激活虚拟环境...
call ..\venv\Scripts\activate.bat

echo [信息] 开始运行完整验证流程...
echo.

REM 运行Python验证脚本
python run_full_import_verification.py

REM 检查退出代码
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo   ✅ 验证完成！所有测试通过！
    echo ========================================
) else (
    echo.
    echo ========================================
    echo   ❌ 验证失败，请检查日志文件
    echo ========================================
)

echo.
echo 日志文件位置: database\logs\
echo.

pause

