@echo off
chcp 65001 >nul
title MatMatch 迁移准备 - 导出数据
echo ================================================================================
echo MatMatch 项目迁移 - 数据导出工具
echo ================================================================================
echo.

cd /d "%~dp0\.."

REM 获取当前日期
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set BACKUP_DATE=%datetime:~0,8%
set BACKUP_FILE=matmatch_backup_%BACKUP_DATE%

echo 📦 准备导出数据...
echo 备份文件名: %BACKUP_FILE%
echo.

REM 检查 PostgreSQL
echo 🔍 检查 PostgreSQL 连接...
psql -h 127.0.0.1 -U postgres -d matmatch -c "SELECT version();" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 无法连接到 PostgreSQL
    echo.
    echo 请确认:
    echo   1. PostgreSQL 服务已启动
    echo   2. 数据库名称: matmatch
    echo   3. 用户名: postgres
    echo   4. 密码正确
    echo.
    pause
    exit /b 1
)
echo ✅ PostgreSQL 连接成功
echo.

REM 创建备份目录
if not exist "backup" mkdir backup

echo 🚀 开始导出数据库...
echo.
echo 方式1: 导出为二进制格式 (.dump) - 推荐，速度快
echo 方式2: 导出为SQL文件 (.sql) - 通用，可读性好
echo.
set /p CHOICE="请选择导出方式 (1/2): "

if "%CHOICE%"=="1" goto :EXPORT_DUMP
if "%CHOICE%"=="2" goto :EXPORT_SQL
echo ❌ 无效选择
pause
exit /b 1

:EXPORT_DUMP
echo.
echo 📤 导出为二进制格式...
pg_dump -h 127.0.0.1 -U postgres -d matmatch -F c -b -v -f backup\%BACKUP_FILE%.dump
if %errorlevel% equ 0 (
    echo ✅ 导出成功！
    echo 文件位置: backup\%BACKUP_FILE%.dump
) else (
    echo ❌ 导出失败
    pause
    exit /b 1
)
goto :CHECK_SIZE

:EXPORT_SQL
echo.
echo 📤 导出为SQL文件...
pg_dump -h 127.0.0.1 -U postgres -d matmatch -F p -b -v -f backup\%BACKUP_FILE%.sql
if %errorlevel% equ 0 (
    echo ✅ 导出成功！
    echo 文件位置: backup\%BACKUP_FILE%.sql
) else (
    echo ❌ 导出失败
    pause
    exit /b 1
)
goto :CHECK_SIZE

:CHECK_SIZE
echo.
echo 📊 备份文件信息:
dir backup\%BACKUP_FILE%.* | findstr /v "字节"
echo.

echo ================================================================================
echo.
echo ✅ 数据导出完成！
echo.
echo 📋 下一步操作:
echo   1. 将以下文件复制到新主机:
echo      - backup\%BACKUP_FILE%.*
echo      - 整个项目目录（排除 venv, node_modules）
echo      - backend\.env 文件（如果有）
echo.
echo   2. 在新主机上运行:
echo      scripts\迁移准备-导入数据.bat
echo.
echo 💡 提示:
echo   - 可以使用U盘、网络共享或Git传输
echo   - 项目大小约 300MB（不含依赖）
echo   - 数据库备份大小见上方显示
echo.
echo ================================================================================
pause

