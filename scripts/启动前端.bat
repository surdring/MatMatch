@echo off
chcp 65001 >nul
title MatMatch 前端开发服务器
echo ================================================================================
echo MatMatch 前端开发服务器
echo ================================================================================
echo.

cd /d "%~dp0\..\frontend"

REM 检查端口 3000
netstat -ano | findstr :3000 | findstr LISTENING >nul
if %errorlevel% equ 0 (
    echo ⚠️  端口 3000 已被占用，是否要停止并重启？(Y/N)
    set /p KILL_PROCESS=
    if /i "%KILL_PROCESS%"=="Y" (
        for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do taskkill /PID %%a /F >nul 2>&1
        timeout /t 2 /nobreak >nul
    ) else (
        exit /b 0
    )
)

echo 🚀 启动前端服务...
echo 📦 http://localhost:3000
echo.
call npm run dev

