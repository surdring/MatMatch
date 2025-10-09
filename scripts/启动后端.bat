@echo off
chcp 65001 >nul
title MatMatch 后端API服务器
echo ================================================================================
echo MatMatch 后端API服务器
echo ================================================================================
echo.

cd /d "%~dp0\..\backend"

REM 检查 PostgreSQL
netstat -ano | findstr :5432 | findstr LISTENING >nul
if %errorlevel% neq 0 (
    echo ❌ PostgreSQL 未运行，请先启动 PostgreSQL 服务
    pause
    exit /b 1
)

REM 检查端口 8000
netstat -ano | findstr :8000 | findstr LISTENING >nul
if %errorlevel% equ 0 (
    echo ⚠️  端口 8000 已被占用，是否要停止并重启？(Y/N)
    set /p KILL_PROCESS=
    if /i "%KILL_PROCESS%"=="Y" (
        for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000 ^| findstr LISTENING') do taskkill /PID %%a /F >nul 2>&1
        timeout /t 2 /nobreak >nul
    ) else (
        exit /b 0
    )
)

echo 🚀 启动后端服务...
echo 📦 API: http://localhost:8000
echo 📦 文档: http://localhost:8000/docs
echo.
..\venv\Scripts\python.exe -m uvicorn api.main:app --host 127.0.0.1 --port 8000 --reload

