@echo off
chcp 65001 >nul
title MatMatch 迁移准备 - 导入数据
echo ================================================================================
echo MatMatch 项目迁移 - 数据导入工具
echo ================================================================================
echo.

cd /d "%~dp0\.."

echo 📋 导入前检查清单:
echo   [ ] PostgreSQL 已安装并启动
echo   [ ] 已创建数据库 'matmatch'
echo   [ ] 备份文件已复制到 backup\ 目录
echo   [ ] Python 虚拟环境已创建
echo   [ ] 前后端依赖已安装
echo.
set /p CONFIRM="确认以上条件都已满足？(Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo.
    echo 请先完成准备工作，参考文档：
    echo   docs\项目迁移指南-172.16.100.211.md
    pause
    exit /b 1
)

echo.
echo 🔍 检查 PostgreSQL 连接...
psql -h 127.0.0.1 -U postgres -l >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 无法连接到 PostgreSQL
    echo.
    echo 请确认:
    echo   1. PostgreSQL 服务已启动（services.msc）
    echo   2. 用户名: postgres
    echo   3. 密码正确
    echo.
    pause
    exit /b 1
)
echo ✅ PostgreSQL 连接成功
echo.

echo 🔍 检查数据库 'matmatch' 是否存在...
psql -h 127.0.0.1 -U postgres -lqt | findstr matmatch >nul
if %errorlevel% neq 0 (
    echo ⚠️  数据库 'matmatch' 不存在，是否创建？(Y/N)
    set /p CREATE_DB=
    if /i "%CREATE_DB%"=="Y" (
        echo 📦 创建数据库...
        psql -h 127.0.0.1 -U postgres -c "CREATE DATABASE matmatch;"
        if %errorlevel% equ 0 (
            echo ✅ 数据库创建成功
        ) else (
            echo ❌ 数据库创建失败
            pause
            exit /b 1
        )
    ) else (
        echo 已取消导入
        pause
        exit /b 0
    )
)
echo ✅ 数据库 'matmatch' 已存在
echo.

echo 🔍 查找备份文件...
if not exist "backup\*.dump" if not exist "backup\*.sql" (
    echo ❌ 在 backup\ 目录下找不到备份文件
    echo.
    echo 请确认:
    echo   1. 备份文件已从旧主机复制到此目录
    echo   2. 文件位于: D:\develop\python\MatMatch\backup\
    echo   3. 文件扩展名: .dump 或 .sql
    echo.
    pause
    exit /b 1
)

echo.
echo 📂 找到以下备份文件:
dir /b backup\*.dump backup\*.sql 2>nul
echo.
echo 请输入要导入的备份文件名（不含路径）:
set /p BACKUP_FILE=
if not exist "backup\%BACKUP_FILE%" (
    echo ❌ 文件不存在: backup\%BACKUP_FILE%
    pause
    exit /b 1
)

echo.
echo 📤 开始导入数据库...
echo 文件: %BACKUP_FILE%
echo.

REM 判断文件类型
echo %BACKUP_FILE% | findstr /i "\.dump$" >nul
if %errorlevel% equ 0 (
    echo 使用 pg_restore 导入二进制格式...
    pg_restore -h 127.0.0.1 -U postgres -d matmatch -v backup\%BACKUP_FILE%
) else (
    echo 使用 psql 导入SQL文件...
    psql -h 127.0.0.1 -U postgres -d matmatch -f backup\%BACKUP_FILE%
)

if %errorlevel% equ 0 (
    echo.
    echo ✅ 数据导入成功！
) else (
    echo.
    echo ❌ 数据导入失败
    echo.
    echo 可能原因:
    echo   1. 数据库已有数据（需要先清空）
    echo   2. 备份文件损坏
    echo   3. PostgreSQL 版本不兼容
    echo.
    pause
    exit /b 1
)

echo.
echo 🔍 验证数据...
psql -h 127.0.0.1 -U postgres -d matmatch -c "SELECT COUNT(*) as 物料数量 FROM materials_master;"
psql -h 127.0.0.1 -U postgres -d matmatch -c "SELECT COUNT(*) as 同义词数量 FROM synonyms;"
psql -h 127.0.0.1 -U postgres -d matmatch -c "SELECT COUNT(*) as 规则数量 FROM extraction_rules;"
psql -h 127.0.0.1 -U postgres -d matmatch -c "SELECT COUNT(*) as 分类数量 FROM knowledge_categories;"

echo.
echo ================================================================================
echo ✅ 数据导入完成！
echo.
echo 📋 下一步操作:
echo   1. 修改配置文件（参考迁移指南 Step 5）
echo      - backend\core\config.py
echo      - backend\api\middleware.py
echo      - frontend\vite.config.ts
echo.
echo   2. 启动服务:
echo      .\智能启动.bat
echo.
echo   3. 验证功能:
echo      http://172.16.100.211:8000/docs
echo      http://172.16.100.211:3000
echo.
echo ================================================================================
pause

