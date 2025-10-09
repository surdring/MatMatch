@echo off
chcp 65001 >nul
cd /d %~dp0
title MatMatch 后端API服务器
echo ================================================================================
echo MatMatch 后端API服务器启动
echo ================================================================================
echo.

REM 检查虚拟环境
if not exist "..\venv\Scripts\python.exe" (
    echo ❌ 虚拟环境不存在，请先创建虚拟环境
    echo.
    echo 💡 创建方法:
    echo    cd D:\develop\python\MatMatch
    echo    python -m venv venv
    echo    venv\Scripts\activate
    echo    pip install -r backend\requirements.txt
    echo.
    pause
    exit /b 1
)

REM 检查 PostgreSQL
echo 🔍 正在检查 PostgreSQL 服务...
netstat -ano | findstr :5432 | findstr LISTENING >nul
if %errorlevel% neq 0 (
    echo ⚠️  PostgreSQL 未运行，请先启动 PostgreSQL 服务
    echo.
    echo 💡 启动方法:
    echo    1. 打开"服务"管理器（services.msc）
    echo    2. 找到 PostgreSQL 服务
    echo    3. 右键 - 启动
    echo.
    pause
    exit /b 1
)
echo ✅ PostgreSQL 运行正常
echo.

REM 检查端口 8000 是否被占用
echo 🔍 正在检查端口 8000...
netstat -ano | findstr :8000 | findstr LISTENING >nul
if %errorlevel% equ 0 (
    echo ⚠️  端口 8000 已被占用
    echo.
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000 ^| findstr LISTENING') do (
        set PID=%%a
        goto :PID_FOUND
    )
    :PID_FOUND
    echo 当前占用进程 PID: %PID%
    echo.
    set /p KILL_PROCESS="是否要停止该进程并重启后端服务？(Y/N): "
    if /i "%KILL_PROCESS%"=="Y" (
        echo 正在停止进程 %PID%...
        taskkill /PID %PID% /F >nul 2>&1
        if %errorlevel% equ 0 (
            echo ✅ 进程已停止
            timeout /t 2 /nobreak >nul
        ) else (
            echo ❌ 停止进程失败，可能需要管理员权限
            pause
            exit /b 1
        )
    ) else (
        echo 已取消启动
        pause
        exit /b 0
    )
)
echo ✅ 端口 8000 空闲
echo.

echo 🚀 正在启动后端API服务器...
echo.
echo 📦 API地址: http://localhost:8000
echo 📦 API文档: http://localhost:8000/docs
echo 📦 ReDoc文档: http://localhost:8000/redoc
echo.
echo 💡 提示:
echo    - 按 Ctrl+C 停止服务器
echo    - 代码更改会自动重载（--reload）
echo    - 关闭此窗口将停止后端服务
echo    - 日志将显示在此窗口中
echo.
echo ================================================================================
echo.

REM 启动 FastAPI 服务器
..\venv\Scripts\python.exe -m uvicorn api.main:app --host 127.0.0.1 --port 8000 --reload

pause
